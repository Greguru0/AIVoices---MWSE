#==================
# AI VOICES XTTS REFERENCE SAMPLE BUILDER
#==================

from __future__ import annotations

import argparse
import subprocess
import sys
from pathlib import Path


#==================
# DEFAULTS
#==================

TARGET_SECONDS_DEFAULT = 8.0
MIN_CLIP_SECONDS_DEFAULT = 0.5
OUTPUT_SAMPLE_RATE_DEFAULT = 22050
OUTPUT_CHANNELS_DEFAULT = 1

VANILLA_VOICES = [
    ("argonianMale", "a/m", "argonianMale.wav"),
    ("argonianFemale", "a/f", "argonianFemale.wav"),
    ("bretonMale", "b/m", "bretonMale.wav"),
    ("bretonFemale", "b/f", "bretonFemale.wav"),
    ("darkElfMale", "d/m", "darkElfMale.wav"),
    ("darkElfFemale", "d/f", "darkElfFemale.wav"),
    ("highElfMale", "h/m", "highElfMale.wav"),
    ("highElfFemale", "h/f", "highElfFemale.wav"),
    ("imperialMale", "i/m", "imperialMale.wav"),
    ("imperialFemale", "i/f", "imperialFemale.wav"),
    ("khajiitMale", "k/m", "khajiitMale.wav"),
    ("khajiitFemale", "k/f", "khajiitFemale.wav"),
    ("nordMale", "n/m", "nordMale.wav"),
    ("nordFemale", "n/f", "nordFemale.wav"),
    ("orcMale", "o/m", "orcMale.wav"),
    ("orcFemale", "o/f", "orcFemale.wav"),
    ("redguardMale", "r/m", "redguardMale.wav"),
    ("redguardFemale", "r/f", "redguardFemale.wav"),
    ("woodElfMale", "w/m", "woodElfMale.wav"),
    ("woodElfFemale", "w/f", "woodElfFemale.wav"),
]

SPECIAL_VOICES = [
    ("dagoth ur", "uniqueDagothUr.wav", ["Dagoth Ur Welcome*.mp3", "Dagoth Ur Taunt*.mp3", "dagoth_*.mp3"]),
    ("vivec", "uniqueVivec.wav", ["viv_hlo*.mp3", "viv_idl*.mp3", "viv_alm*.mp3"]),
    ("almalexia", "uniqueAlmalexia.wav", ["tr_almgreet*.mp3", "tr_almaend*.mp3"]),
    ("yagrum bagarn", "uniqueYagrumBagarn.wav", ["Yagrum_*.mp3"]),
]


#==================
# LOGGING
#==================

def log(message: str) -> None:
    print(message)

def fail(message: str) -> None:
    print(f"ERROR: {message}", file=sys.stderr)
    raise SystemExit(1)

#==================
# PATH HELPERS
#==================

def resolve_data_files_from_script() -> Path:
    script_dir = Path(__file__).resolve().parent

    if script_dir.name.lower() == "aivoicesbackend":
        return script_dir.parent.resolve()

    return script_dir.parent.parent.parent.resolve()


def resolve_ffmpeg_tools(ffmpeg_bin: str | None, prompt_for_missing: bool = False, require_ffprobe: bool = True) -> tuple[Path, Path | None]:
    candidates: list[Path] = []

    if ffmpeg_bin:
        candidates.append(Path(ffmpeg_bin))

    candidates.append(Path(__file__).resolve().parent / "dependencies" / "ffmpeg" / "bin")

    def check_candidates() -> tuple[Path, Path | None] | None:
        for bin_dir in candidates:
            ffmpeg = bin_dir / "ffmpeg.exe"
            ffprobe = bin_dir / "ffprobe.exe"

            if require_ffprobe and ffmpeg.exists() and ffprobe.exists():
                return ffmpeg.resolve(), ffprobe.resolve()

            if not require_ffprobe and ffmpeg.exists():
                return ffmpeg.resolve(), ffprobe.resolve() if ffprobe.exists() else None

        return None

    found = check_candidates()
    if found:
        return found

    if prompt_for_missing:
        prompt = "FFmpeg folder path containing ffmpeg.exe and ffprobe.exe: " if require_ffprobe else "FFmpeg folder path containing ffmpeg.exe: "
        entered = input(prompt).strip().strip('"')
        if entered:
            candidates.append(Path(entered))

        found = check_candidates()
        if found:
            return found

    if require_ffprobe:
        fail("Could not find ffmpeg.exe and ffprobe.exe in AIVoicesBackend\\dependencies\\ffmpeg\\bin. This could be because install_aivoices.bat has not been run yet, or FFmpeg did not install correctly. Please run install_aivoices.bat first.")

    fail("Could not find ffmpeg.exe in AIVoicesBackend\\dependencies\\ffmpeg\\bin. This could be because install_aivoices.bat has not been run yet, or FFmpeg did not install correctly. Please run install_aivoices.bat first.")

def ffmpeg_concat_escape(path: Path) -> str:
    text = path.resolve().as_posix()
    text = text.replace("'", r"'\''")
    return f"file '{text}'"


#==================
# AUDIO HELPERS
#==================

def get_duration_seconds(ffprobe: Path, audio_file: Path) -> float:
    command = [
        str(ffprobe),
        "-v",
        "error",
        "-show_entries",
        "format=duration",
        "-of",
        "default=noprint_wrappers=1:nokey=1",
        str(audio_file),
    ]

    result = subprocess.run(
        command,
        capture_output=True,
        text=True,
        check=False,
    )

    if result.returncode != 0:
        return 0.0

    try:
        return float(result.stdout.strip())
    except ValueError:
        return 0.0


def collect_clip_info(
    folder: Path,
    patterns: list[str],
    ffprobe: Path,
    min_clip_seconds: float,
) -> list[dict]:
    clips: list[dict] = []
    seen: set[Path] = set()

    for priority, pattern in enumerate(patterns):
        for audio_file in folder.glob(pattern):
            if not audio_file.is_file():
                continue

            resolved = audio_file.resolve()

            if resolved in seen:
                continue

            seen.add(resolved)

            duration = get_duration_seconds(ffprobe, resolved)

            if duration > min_clip_seconds:
                clips.append(
                    {
                        "file": resolved,
                        "duration": duration,
                        "priority": priority,
                        "name": resolved.name.lower(),
                    }
                )

    return clips


def select_clips(
    clips: list[dict],
    target_seconds: float,
    prefer_hlo: bool = True,
) -> tuple[list[Path], float]:
    if prefer_hlo:
        sorted_clips = sorted(
            clips,
            key=lambda clip: (
                0 if clip["name"].startswith("hlo_") or clip["name"].startswith("hlo") else 1,
                clip["priority"],
                -clip["duration"],
            ),
        )
    else:
        sorted_clips = sorted(
            clips,
            key=lambda clip: (
                clip["priority"],
                -clip["duration"],
            ),
        )

    selected: list[Path] = []
    total_duration = 0.0

    for clip in sorted_clips:
        if total_duration >= target_seconds:
            break

        selected.append(clip["file"])
        total_duration += clip["duration"]

    return selected, total_duration


def build_wav_from_clips(
    ffmpeg: Path,
    clips: list[Path],
    output_wav: Path,
    sample_rate: int,
    channels: int,
) -> None:
    output_wav.parent.mkdir(parents=True, exist_ok=True)

    list_file = output_wav.with_name(output_wav.stem + "_concat.txt")

    try:
        list_lines = [ffmpeg_concat_escape(clip) for clip in clips]
        list_file.write_text("\n".join(list_lines) + "\n", encoding="ascii", errors="ignore")

        command = [
            str(ffmpeg),
            "-y",
            "-hide_banner",
            "-loglevel",
            "error",
            "-f",
            "concat",
            "-safe",
            "0",
            "-i",
            str(list_file),
            "-ar",
            str(sample_rate),
            "-ac",
            str(channels),
            str(output_wav),
        ]

        result = subprocess.run(command, check=False)

        if result.returncode != 0:
            fail(f"FFmpeg failed while building {output_wav.name}.")

    finally:
        try:
            list_file.unlink(missing_ok=True)
        except Exception:
            pass


#==================
# MAP HELPERS
#==================

def read_existing_custom_map_entries(map_path: Path, generated_keys: set[str]) -> list[str]:
    if not map_path.exists():
        return []

    preserved: list[str] = []

    for raw_line in map_path.read_text(encoding="utf-8", errors="ignore").splitlines():
        line = raw_line.strip()

        if not line:
            continue

        if line.startswith("#"):
            continue

        if "=" not in line:
            continue

        key = line.split("=", 1)[0].strip()

        if not key:
            continue

        if key not in generated_keys:
            preserved.append(raw_line)

    return preserved


def write_reference_map(
    map_path: Path,
    generated_entries: list[str],
    generated_keys: set[str],
    preserve_existing_custom_entries: bool,
) -> None:
    map_path.parent.mkdir(parents=True, exist_ok=True)

    preserved_entries: list[str] = []

    if preserve_existing_custom_entries:
        preserved_entries = read_existing_custom_map_entries(map_path, generated_keys)

        if map_path.exists():
            backup_path = map_path.with_suffix(map_path.suffix + ".backup-before-reference-build.txt")
            backup_path.write_text(map_path.read_text(encoding="utf-8", errors="ignore"), encoding="utf-8")

    lines = [
        "# AI Voices XTTS reference audio map",
        "# Generated locally by AI Voices.",
        "# Do not redistribute generated reference_samples files.",
        "# Paths are relative to Morrowind Data Files.",
        "",
    ]

    lines.extend(generated_entries)

    if preserved_entries:
        lines.append("")
        lines.append("# Preserved custom entries from previous map")
        lines.extend(preserved_entries)

    map_path.write_text("\n".join(lines) + "\n", encoding="utf-8")


#==================
# INSTALLER MODE
#==================

def build_installer_references(args: argparse.Namespace) -> None:
    data_files = Path(args.data_files).resolve() if args.data_files else resolve_data_files_from_script()
    backend_dir = data_files / "AIVoicesBackend"
    sound_vo = data_files / "Sound" / "Vo"
    special_sound_vo = sound_vo / "Misc"
    output_dir = backend_dir / "XTTS" / "reference_samples"
    map_path = backend_dir / "XTTS" / "xtts_reference_map.txt"
    marker_path = backend_dir / "install_markers" / "reference_samples_built_by_aivoices.txt"

    ffmpeg, ffprobe = resolve_ffmpeg_tools(args.ffmpeg_bin, prompt_for_missing=False, require_ffprobe=True)

    if not sound_vo.exists():
        fail(f"Could not find Morrowind voice folder: {sound_vo}")

    output_dir.mkdir(parents=True, exist_ok=True)

    generated_entries: list[str] = []
    generated_keys: set[str] = set()

    log("Building vanilla race/gender XTTS reference samples...")

    for voice_key, folder, output_name in VANILLA_VOICES:
        input_folder = sound_vo / Path(folder)
        output_wav = output_dir / output_name

        log(f"Building {voice_key} from {input_folder}")

        if not input_folder.exists():
            log("  Missing folder, skipping.")
            continue

        clips = collect_clip_info(
            folder=input_folder,
            patterns=["Hlo*.mp3", "*.mp3"],
            ffprobe=ffprobe,
            min_clip_seconds=MIN_CLIP_SECONDS_DEFAULT,
        )

        if not clips:
            log("  No usable MP3 files found, skipping.")
            continue

        selected, total_duration = select_clips(
            clips=clips,
            target_seconds=TARGET_SECONDS_DEFAULT,
            prefer_hlo=True,
        )

        if not selected:
            log("  No usable MP3 files found, skipping.")
            continue

        log(f"  Selected {len(selected)} clips, about {total_duration:.1f} seconds.")

        build_wav_from_clips(
            ffmpeg=ffmpeg,
            clips=selected,
            output_wav=output_wav,
            sample_rate=OUTPUT_SAMPLE_RATE_DEFAULT,
            channels=OUTPUT_CHANNELS_DEFAULT,
        )

        generated_keys.add(voice_key)
        generated_entries.append(
            f"{voice_key}=AIVoicesBackend\\XTTS\\reference_samples\\{output_name}"
        )

    log("Building special actor XTTS reference samples...")

    if not special_sound_vo.exists():
        log(f"Special voice folder not found: {special_sound_vo}")
    else:
        for voice_key, output_name, patterns in SPECIAL_VOICES:
            output_wav = output_dir / output_name

            log(f"Building special voice {voice_key}")

            clips = collect_clip_info(
                folder=special_sound_vo,
                patterns=patterns,
                ffprobe=ffprobe,
                min_clip_seconds=MIN_CLIP_SECONDS_DEFAULT,
            )

            if not clips:
                log("  No matching MP3 files found, skipping.")
                continue

            selected, total_duration = select_clips(
                clips=clips,
                target_seconds=TARGET_SECONDS_DEFAULT,
                prefer_hlo=False,
            )

            if not selected:
                log("  No usable MP3 files found, skipping.")
                continue

            log(f"  Selected {len(selected)} clips, about {total_duration:.1f} seconds.")

            build_wav_from_clips(
                ffmpeg=ffmpeg,
                clips=selected,
                output_wav=output_wav,
                sample_rate=OUTPUT_SAMPLE_RATE_DEFAULT,
                channels=OUTPUT_CHANNELS_DEFAULT,
            )

            generated_keys.add(voice_key)
            generated_entries.append(
                f"{voice_key}=AIVoicesBackend\\XTTS\\reference_samples\\{output_name}"
            )

    write_reference_map(
        map_path=map_path,
        generated_entries=generated_entries,
        generated_keys=generated_keys,
        preserve_existing_custom_entries=True,
    )

    marker_path.parent.mkdir(parents=True, exist_ok=True)
    marker_path.write_text(
        "AI Voices built local reference samples from the user's installed Morrowind MP3 files.\n",
        encoding="utf-8",
    )

    log("Reference sample build complete.")


#==================
# CUSTOM USER MODE
#==================

def prompt_if_missing(value: str | None, prompt: str) -> str:
    if value:
        return value

    entered = input(prompt).strip().strip('"')

    if not entered:
        fail("Required value was not provided.")

    return entered

def build_custom_reference(args: argparse.Namespace) -> None:
    print("==================")
    print("CUSTOM USER MODE")
    print("==================")
    print()
    print("This tool builds one XTTS reference WAV from a folder of MP3 files.")
    print("If you are trying to install AI Voices, run install_aivoices.bat instead.")
    print()
    print("The installer handles the default Morrowind voice samples automatically.")
    print("Use this tool only if you want to create your own custom XTTS reference sample.")
    print()

    input_folder_text = prompt_if_missing(args.input_folder, "MP3 folder path: ")
    output_wav_text = prompt_if_missing(args.output_wav, "Output WAV path/name: ")
    if not output_wav_text.lower().endswith(".wav"):
        output_wav_text += ".wav"

    input_folder = Path(input_folder_text).resolve()
    output_wav = Path(output_wav_text).resolve()

    if not input_folder.exists():
        fail(f"Input folder does not exist: {input_folder}")

    if not input_folder.is_dir():
        fail(f"Input path is not a folder: {input_folder}")

    ffmpeg, _ffprobe = resolve_ffmpeg_tools(args.ffmpeg_bin, prompt_for_missing=True, require_ffprobe=False)

    mp3_files = sorted(input_folder.glob("*.mp3"))

    if not mp3_files:
        fail(f"No MP3 files found in: {input_folder}")

    log(f"Using FFmpeg: {ffmpeg}")
    log(f"Input folder: {input_folder}")
    log(f"Output WAV: {output_wav}")
    log(f"Found {len(mp3_files)} MP3 files.")

    build_wav_from_clips(
        ffmpeg=ffmpeg,
        clips=mp3_files,
        output_wav=output_wav,
        sample_rate=OUTPUT_SAMPLE_RATE_DEFAULT,
        channels=OUTPUT_CHANNELS_DEFAULT,
    )

    log(f"Created: {output_wav}")

    if args.voice_key:
        log("")
        log("After placing the WAV in AIVoicesBackend\\XTTS\\reference_samples, add this to xtts_reference_map.txt:")
        log(f"{args.voice_key}=AIVoicesBackend\\XTTS\\reference_samples\\{output_wav.name}")


#==================
# ARGUMENTS
#==================

def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Build one custom XTTS reference WAV sample for AI Voices - MWSE. This will concatenate the mp3 files into a single wav file.",
        epilog=(
            "Example commands:\n"
            "  python build_reference_samples.py\n"
            "  python build_reference_samples.py --input-folder \"C:\\MyMP3s\" --output-wav \"customRace.wav\"\n"
            "  python build_reference_samples.py --input-folder \"C:\\MyMP3s\" --output-wav \"customRace.wav\" --voice-key \"keptu-queyMale\"\n"
        ),
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )

    parser.add_argument("--input-folder", help="Folder containing MP3 files.")
    parser.add_argument("--output-wav", help="Output WAV file path.")
    parser.add_argument("--voice-key", help="Optional voice key to print a suggested xtts_reference_map.txt entry.")

    parser.add_argument("--installer", action="store_true", help=argparse.SUPPRESS)
    parser.add_argument("--data-files", help=argparse.SUPPRESS)
    parser.add_argument("--ffmpeg-bin", help=argparse.SUPPRESS)

    return parser.parse_args()


#==================
# MAIN
#==================

def pause() -> None:
    try:
        input("Press Enter to exit...")
    except EOFError:
        pass

def main() -> None:
    args = parse_args()

    if args.installer:
        build_installer_references(args)
        return

    try:
        build_custom_reference(args)
    finally:
        pause()


if __name__ == "__main__":
    main()