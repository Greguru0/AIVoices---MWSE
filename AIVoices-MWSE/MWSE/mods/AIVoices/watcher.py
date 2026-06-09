#==================
# REQUIREMENTS
#==================

import hashlib
import json
import msvcrt
import os
import subprocess
import sys
import threading
import time
import urllib.error
import urllib.parse
import urllib.request
import warnings
import winsound
from pathlib import Path

# pysbd (a Coqui TTS dependency) uses deprecated escape sequences in regex
# strings that generate SyntaxWarnings in Python 3.12+. Suppress them here
# since pysbd is not actively maintained and the warnings are harmless.
warnings.filterwarnings("ignore", category=SyntaxWarning, module="pysbd")

#==================
# PATHS
#==================

SCRIPT_DIR = Path(__file__).resolve().parent
DATA_FILES_DIR = SCRIPT_DIR.parents[2]
BACKEND_DIR = DATA_FILES_DIR / "AIVoicesBackend"

RUNTIME_DIR = BACKEND_DIR / "runtime"
SETTINGS_DIR = BACKEND_DIR / "settings"
PIPER_DIR = BACKEND_DIR / "Piper"
XTTS_DIR = BACKEND_DIR / "XTTS"
ELEVENLABS_DIR = BACKEND_DIR / "ElevenLabs"
DEPENDENCIES_DIR = BACKEND_DIR / "dependencies"
INSTALL_MARKERS_DIR = BACKEND_DIR / "install_markers"

DIALOGUE_FILE = RUNTIME_DIR / "dialogue.txt"
VOICE_FILE = RUNTIME_DIR / "voice.txt"
STOP_FILE = RUNTIME_DIR / "stop.txt"
STATUS_FILE = RUNTIME_DIR / "status.txt"
HEARTBEAT_FILE = RUNTIME_DIR / "heartbeat.txt"
WATCHER_HEARTBEAT_FILE = RUNTIME_DIR / "watcher_heartbeat.txt"
WATCHER_LOG_FILE = RUNTIME_DIR / "watcher_log.txt"
LOCK_FILE = RUNTIME_DIR / "watcher.lock"
OUTPUT_WAV = RUNTIME_DIR / "current_voice.wav"

TTS_ENGINE_FILE = SETTINGS_DIR / "tts_engine.txt"
PRONUNCIATION_FILE = SETTINGS_DIR / "pronunciation.txt"
VOICE_VOLUME_FILE = SETTINGS_DIR / "voice_volume.txt"
SPEECH_SPEED_FILE = SETTINGS_DIR / "speech_speed.txt"

PIPER_VOICES_DIR = PIPER_DIR / "voices"
PIPER_VOICE_MAP_FILE = PIPER_DIR / "piper_voice_map.txt"
PIPER_SETTINGS_FILE = PIPER_DIR / "piper_settings.txt"
PIPER_CACHE_DIR = PIPER_DIR / "cache"
PIPER_GENERATED_CACHE_DIR = PIPER_CACHE_DIR / "generated_lines"
PIPER_EXE = DEPENDENCIES_DIR / "aivoices-venv" / "Scripts" / "piper.exe"

XTTS_REFERENCE_MAP_FILE = XTTS_DIR / "xtts_reference_map.txt"
XTTS_CACHE_DIR = XTTS_DIR / "cache"
XTTS_GENERATED_CACHE_DIR = XTTS_CACHE_DIR / "generated_lines"
XTTS_SETTINGS_FILE = SETTINGS_DIR / "xtts_settings.txt"

ELEVENLABS_API_KEY_FILE = ELEVENLABS_DIR / "elevenlabs_api_key.txt"
ELEVENLABS_VOICE_MAP_FILE = ELEVENLABS_DIR / "elevenlabs_voice_map.txt"
ELEVENLABS_MODEL_ID_FILE = ELEVENLABS_DIR / "elevenlabs_model_id.txt"
ELEVENLABS_OUTPUT_FORMAT_FILE = ELEVENLABS_DIR / "elevenlabs_output_format.txt"
ELEVENLABS_SETTINGS_FILE = ELEVENLABS_DIR / "elevenlabs_settings.txt"
ELEVENLABS_CACHE_DIR = ELEVENLABS_DIR / "cache"
ELEVENLABS_GENERATED_CACHE_DIR = ELEVENLABS_CACHE_DIR / "generated_lines"

PRIVATE_FFMPEG_BIN = DEPENDENCIES_DIR / "ffmpeg" / "bin"

#==================
# CONTAIN RUNTIME ENVIRONMENT
#==================

AIVOICES_CACHE_DIR = DEPENDENCIES_DIR / "cache"
AIVOICES_TEMP_DIR = DEPENDENCIES_DIR / "temp"

AIVOICES_HF_DIR = AIVOICES_CACHE_DIR / "huggingface"
AIVOICES_TTS_DIR = AIVOICES_CACHE_DIR / "coqui-tts"
AIVOICES_TORCH_DIR = AIVOICES_CACHE_DIR / "torch"
AIVOICES_XDG_CACHE_DIR = AIVOICES_CACHE_DIR / "xdg-cache"
AIVOICES_XDG_DATA_DIR = AIVOICES_CACHE_DIR / "xdg-data"
AIVOICES_XDG_CONFIG_DIR = AIVOICES_CACHE_DIR / "xdg-config"
AIVOICES_PYTHONPYCACHE_DIR = AIVOICES_CACHE_DIR / "python-pycache"
AIVOICES_PYTHONUSERBASE_DIR = AIVOICES_CACHE_DIR / "python-userbase"

for folder in (
    AIVOICES_CACHE_DIR,
    AIVOICES_TEMP_DIR,
    AIVOICES_HF_DIR,
    AIVOICES_HF_DIR / "hub",
    AIVOICES_HF_DIR / "xet",
    AIVOICES_HF_DIR / "assets",
    AIVOICES_TTS_DIR,
    AIVOICES_TORCH_DIR,
    AIVOICES_XDG_CACHE_DIR,
    AIVOICES_XDG_DATA_DIR,
    AIVOICES_XDG_CONFIG_DIR,
    AIVOICES_PYTHONPYCACHE_DIR,
    AIVOICES_PYTHONUSERBASE_DIR,
):
    folder.mkdir(parents=True, exist_ok=True)

if PRIVATE_FFMPEG_BIN.exists():
    os.environ["PATH"] = str(PRIVATE_FFMPEG_BIN) + os.pathsep + os.environ.get("PATH", "")

os.environ["TEMP"] = str(AIVOICES_TEMP_DIR)
os.environ["TMP"] = str(AIVOICES_TEMP_DIR)

os.environ["HF_HOME"] = str(AIVOICES_HF_DIR)
os.environ["HF_HUB_CACHE"] = str(AIVOICES_HF_DIR / "hub")
os.environ["HF_XET_CACHE"] = str(AIVOICES_HF_DIR / "xet")
os.environ["HF_ASSETS_CACHE"] = str(AIVOICES_HF_DIR / "assets")
os.environ["HF_TOKEN_PATH"] = str(AIVOICES_HF_DIR / "token")
os.environ["HUGGINGFACE_HUB_CACHE"] = str(AIVOICES_HF_DIR / "hub")

os.environ["TTS_HOME"] = str(AIVOICES_TTS_DIR)
os.environ["TORCH_HOME"] = str(AIVOICES_TORCH_DIR)

os.environ["XDG_CACHE_HOME"] = str(AIVOICES_XDG_CACHE_DIR)
os.environ["XDG_DATA_HOME"] = str(AIVOICES_XDG_DATA_DIR)
os.environ["XDG_CONFIG_HOME"] = str(AIVOICES_XDG_CONFIG_DIR)

os.environ["PYTHONPYCACHEPREFIX"] = str(AIVOICES_PYTHONPYCACHE_DIR)
os.environ["PYTHONUSERBASE"] = str(AIVOICES_PYTHONUSERBASE_DIR)

XTTS_MODEL_NAME = "tts_models/multilingual/multi-dataset/xtts_v2"

INSTALL_MARKER_FILE = INSTALL_MARKERS_DIR / "aivoices_installed.txt"

if not INSTALL_MARKER_FILE.exists():
    print("AI Voices is not installed. Please run install_aivoices.bat from Data Files\\MWSE\\mods\\AIVoices first.")
    sys.exit(1)

#==================
# XTTS LICENSE CONFIRMATION
#==================

XTTS_LICENSE_MARKER = INSTALL_MARKERS_DIR / "xtts_license_accepted_by_user.txt"

if XTTS_LICENSE_MARKER.exists():
    os.environ["COQUI_TOS_AGREED"] = "1"

#==================
# STARTUP FOLDER CHECK
#==================

def ensure_core_folders() -> None:
    folders = [
        BACKEND_DIR,
        RUNTIME_DIR,
        SETTINGS_DIR,
        DEPENDENCIES_DIR,
        INSTALL_MARKERS_DIR,
    ]

    for folder in folders:
        folder.mkdir(parents=True, exist_ok=True)


ensure_core_folders()


#==================
# PROCESS LOCK
#==================

lock_handle = None


def acquire_process_lock() -> bool:
    global lock_handle

    try:
        lock_handle = LOCK_FILE.open("w")
        msvcrt.locking(lock_handle.fileno(), msvcrt.LK_NBLCK, 1)
        lock_handle.write(str(time.time()))
        lock_handle.flush()
        return True

    except OSError:
        print("AI Voices watcher is already running.")
        return False


def release_process_lock() -> None:
    global lock_handle

    if not lock_handle:
        return

    try:
        msvcrt.locking(lock_handle.fileno(), msvcrt.LK_UNLCK, 1)
        lock_handle.close()
        LOCK_FILE.unlink(missing_ok=True)

    except Exception:
        pass


#==================
# SINGLE INSTANCE CHECK
#==================

if not acquire_process_lock():
    sys.exit(0)


#==================
# SETTINGS
#==================

HEARTBEAT_TIMEOUT_SECONDS = 15
STARTUP_GRACE_SECONDS = 30
CHECK_INTERVAL_SECONDS = 0.25


#==================
# STATE
#==================

last_dialogue_modified_time = 0.0
last_stop_modified_time = 0.0
watcher_start_time = time.time()
last_seen_heartbeat_modified_time = 0.0
has_seen_active_heartbeat = False
current_piper_process = None
xtts_model = None
xtts_reference_cache = {}
watcher_is_running = True

#==================
# LOGGING
#==================

def log(message: str) -> None:
    line = f"{time.strftime('%Y-%m-%d %H:%M:%S')} - {message}"
    print(line)

    try:
        with WATCHER_LOG_FILE.open("a", encoding="utf-8") as file:
            file.write(line + "\n")
    except Exception:
        pass


def write_status(message: str) -> None:
    message = str(message or "").strip()

    if not message:
        return

    log(message)

    try:
        STATUS_FILE.write_text(f"{time.time()}|{message}", encoding="utf-8")

    except Exception as error:
        log(f"Failed to write status file: {error}")


#==================
# FILE HELPERS
#==================

def read_text_file(path: Path) -> str:
    try:
        if not path.exists():
            return ""

        return path.read_text(encoding="utf-8").strip()

    except Exception as error:
        log(f"Failed to read {path}: {error}")
        return ""


def get_modified_time(path: Path) -> float:
    try:
        if not path.exists():
            return 0.0

        return path.stat().st_mtime

    except Exception as error:
        log(f"Failed to get modified time for {path}: {error}")
        return 0.0


def write_text_file_if_missing(path: Path, content: str) -> None:
    try:
        if path.exists():
            return

        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(content, encoding="utf-8")

    except Exception as error:
        log(f"Failed to create {path}: {error}")


#==================
# DEFAULT FILE CREATION
#==================

def create_default_files_if_missing() -> None:
    write_text_file_if_missing(DIALOGUE_FILE, "")
    write_text_file_if_missing(VOICE_FILE, "")
    write_text_file_if_missing(STOP_FILE, "")
    write_text_file_if_missing(STATUS_FILE, "")
    write_text_file_if_missing(HEARTBEAT_FILE, "")
    write_text_file_if_missing(WATCHER_HEARTBEAT_FILE, "")

#==================
# KEY VALUE MAPS
#==================

def read_key_value_map(path: Path) -> dict[str, str]:
    values = {}

    try:
        if not path.exists():
            return values

        for raw_line in path.read_text(encoding="utf-8").splitlines():
            line = raw_line.strip()

            if not line or line.startswith("#"):
                continue

            if "=" not in line:
                continue

            key, value = line.split("=", 1)
            key = key.strip()
            value = value.strip()

            if key:
                values[key] = value

    except Exception as error:
        log(f"Failed to read map {path}: {error}")

    return values


#==================
# HEARTBEAT
#==================

def heartbeat_is_alive() -> bool:
    global last_seen_heartbeat_modified_time
    global has_seen_active_heartbeat

    if not HEARTBEAT_FILE.exists():
        return True

    try:
        current_heartbeat_modified_time = HEARTBEAT_FILE.stat().st_mtime

        if current_heartbeat_modified_time > last_seen_heartbeat_modified_time:
            last_seen_heartbeat_modified_time = current_heartbeat_modified_time
            has_seen_active_heartbeat = True
            return True

        if not has_seen_active_heartbeat:
            if time.time() - watcher_start_time < STARTUP_GRACE_SECONDS:
                return True

        age = time.time() - current_heartbeat_modified_time
        
        if age <= HEARTBEAT_TIMEOUT_SECONDS:
            return True
        
        if morrowind_is_running():
            log("Heartbeat timed out, but Morrowind.exe is still running. Keeping watcher alive.")
            return True
        
        log("Heartbeat timed out and Morrowind.exe is not running.")
        return False

    except Exception as error:
        log(f"Heartbeat check error: {error}")
        return True

#==================
# WATCHER HEARTBEAT
#==================

def write_watcher_heartbeat() -> None:
    try:
        WATCHER_HEARTBEAT_FILE.write_text(str(time.time()), encoding="utf-8")
    except Exception as error:
        log(f"Failed to write watcher heartbeat: {error}")


def watcher_heartbeat_loop() -> None:
    while watcher_is_running:
        write_watcher_heartbeat()
        time.sleep(2)


#==================
# MORROWIND PROCESS CHECK
#==================

def morrowind_is_running() -> bool:
    try:
        result = subprocess.run(
            ["tasklist", "/FI", "IMAGENAME eq Morrowind.exe"],
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            creationflags=subprocess.CREATE_NO_WINDOW,
        )

        return "Morrowind.exe" in result.stdout

    except Exception as error:
        log(f"Failed to check Morrowind.exe process: {error}")
        return True

#==================
# PRONUNCIATION
#==================

_pronunciation_cache: dict[str, str] = {}
_pronunciation_cache_sorted_keys: list[str] = []
_pronunciation_cache_mtime: float = 0.0


def load_pronunciation_replacements() -> tuple[dict[str, str], list[str]]:
    global _pronunciation_cache, _pronunciation_cache_sorted_keys, _pronunciation_cache_mtime

    current_mtime = get_modified_time(PRONUNCIATION_FILE)

    if current_mtime == _pronunciation_cache_mtime:
        return _pronunciation_cache, _pronunciation_cache_sorted_keys

    _pronunciation_cache = read_key_value_map(PRONUNCIATION_FILE)
    _pronunciation_cache_sorted_keys = sorted(_pronunciation_cache.keys(), key=len, reverse=True)
    _pronunciation_cache_mtime = current_mtime
    log("Pronunciation dictionary reloaded.")

    return _pronunciation_cache, _pronunciation_cache_sorted_keys


def apply_pronunciation_dictionary(text: str) -> str:
    replacements, sorted_keys = load_pronunciation_replacements()

    for original in sorted_keys:
        text = text.replace(original, replacements[original])

    return text


#==================
# TTS TEXT CLEANUP
#==================

def clean_text_for_tts(text: str) -> str:
    text = str(text or "")

    protected_tokens = {
        "M.W.S.E.": "__AI_VOICES_MWSE__",
        "X.T.T.S.": "__AI_VOICES_XTTS__",
    }

    for original, token in protected_tokens.items():
        text = text.replace(original, token)

    text = text.replace("...", ".")
    text = text.replace("..", ".")
    text = text.replace(" .", ".")
    text = text.replace(" ,", ",")

    if text.endswith("."):
        text = text[:-1]

    for original, token in protected_tokens.items():
        text = text.replace(token, original)

    return text.strip()

#==================
# TTS ENGINE
#==================

def get_tts_engine() -> str:
    engine = read_text_file(TTS_ENGINE_FILE).strip().lower()

    if engine not in ["piper", "elevenlabs", "xtts"]:
        return "xtts"

    return engine


#==================
# VOICE KEY PARSING
#==================

def parse_voice_key(prefix: str, voice_text: str) -> str:
    if not voice_text:
        return ""

    expected_prefix = prefix + ":"

    if voice_text.startswith(expected_prefix):
        return voice_text.split(":", 1)[1].strip()

    return ""

#==================
# PLAYBACK HELPERS
#==================

def get_voice_volume() -> float:
    value_text = read_text_file(VOICE_VOLUME_FILE).strip()

    try:
        volume = float(value_text)
    except Exception:
        volume = 50.0

    volume = max(0.0, min(100.0, volume))

    return volume / 100.0


def apply_wav_volume(path: Path) -> bool:
    volume = get_voice_volume()

    if volume >= 0.999:
        return True

    ffmpeg_exe = PRIVATE_FFMPEG_BIN / "ffmpeg.exe"

    if not ffmpeg_exe.exists():
        log("Portable FFmpeg not found — skipping volume adjustment.")
        return True

    temp_path = path.with_name(path.stem + "_vol.wav")

    try:
        result = subprocess.run(
            [
                str(ffmpeg_exe),
                "-y",
                "-hide_banner",
                "-loglevel", "error",
                "-i", str(path),
                "-filter:a", f"volume={volume:.3f}",
                str(temp_path),
            ],
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            creationflags=subprocess.CREATE_NO_WINDOW,
        )

        if result.returncode != 0:
            log(f"FFmpeg volume adjustment failed: {result.stderr.strip()}")
            return False

        path.write_bytes(temp_path.read_bytes())
        log(f"Applied playback volume: {int(volume * 100)}%")
        return True

    except Exception as error:
        log(f"Failed to apply playback volume: {error}")
        return False

    finally:
        try:
            temp_path.unlink(missing_ok=True)
        except Exception:
            pass

def get_speech_speed() -> float:
    value_text = read_text_file(SPEECH_SPEED_FILE).strip()

    try:
        speed = float(value_text)
    except Exception:
        speed = 1.00

    return max(0.75, min(2.00, speed))

#==================
# PIPER VOICE RESOLUTION
#==================

def resolve_piper_voice_path(voice_key: str) -> str:
    voice_key = voice_key or ""
    voice_map = read_key_value_map(PIPER_VOICE_MAP_FILE)

    if not voice_key:
        write_status("Piper skipped: no voice key was provided.")
        return ""

    candidate_text = voice_map.get(voice_key, "")

    if not candidate_text:
        write_status(f"Piper skipped: no voice path is set for {voice_key}.")
        return ""

    candidate = Path(candidate_text)

    if candidate.is_absolute():
        path = candidate
    else:
        path = DATA_FILES_DIR / candidate

    if path.exists():
        return str(path.resolve())

    write_status(f"Piper skipped: voice file missing for {voice_key}.")
    log(f"Expected Piper voice path: {path}")
    return ""


#==================
# ELEVENLABS SETTINGS
#==================

def parse_bool(value: str, default: bool = False) -> bool:
    value = str(value or "").strip().lower()

    if value in ["true", "1", "yes", "y", "on"]:
        return True

    if value in ["false", "0", "no", "n", "off"]:
        return False

    return default


def parse_float(value: str, default: float) -> float:
    try:
        return float(value)
    except Exception:
        return default


#==================
# GENERATED LINE CACHE HELPERS
#==================

def clamp_cache_max_mb(value: str, default: int = 500) -> int:
    try:
        max_mb = int(parse_float(value, default))
    except Exception:
        max_mb = default

    if max_mb < 0:
        max_mb = 0

    return max_mb


def get_basic_cache_settings(path: Path, default_enabled: bool) -> dict:
    settings = read_key_value_map(path)

    return {
        "cache_generated_lines": parse_bool(
            settings.get("cache_generated_lines", str(default_enabled).lower()),
            default_enabled,
        ),
        "generated_cache_max_mb": clamp_cache_max_mb(settings.get("generated_cache_max_mb", "500"), 500),
    }


def get_generated_cache_path(cache_dir: Path, voice_key: str, cache_input: str) -> Path:
    voice_key = str(voice_key or "").strip() or "unknown"

    cache_dir.mkdir(parents=True, exist_ok=True)

    cache_hash = hashlib.sha256(cache_input.encode("utf-8")).hexdigest()

    voice_cache_dir = cache_dir / voice_key
    voice_cache_dir.mkdir(parents=True, exist_ok=True)

    return voice_cache_dir / f"{cache_hash}.wav"


def prune_generated_cache(cache_dir: Path, max_mb: int, label: str) -> None:
    if max_mb <= 0:
        return

    if not cache_dir.exists():
        return

    max_bytes = max_mb * 1024 * 1024
    cache_files = []
    total_bytes = 0

    try:
        for path in cache_dir.rglob("*.wav"):
            try:
                if not path.is_file():
                    continue

                stat = path.stat()
                total_bytes += stat.st_size
                cache_files.append((stat.st_mtime, stat.st_size, path))

            except Exception:
                continue

        if total_bytes <= max_bytes:
            return

        cache_files.sort(key=lambda item: item[0])

        for _mtime, size, path in cache_files:
            if total_bytes <= max_bytes:
                break

            try:
                path.unlink()
                total_bytes -= size
                log(f"Deleted old {label} cached line: {path}")

            except Exception as error:
                log(f"Failed to delete old {label} cached line {path}: {error}")

    except Exception as error:
        log(f"Failed to prune {label} generated line cache: {error}")


def get_piper_settings() -> dict:
    settings = get_basic_cache_settings(PIPER_SETTINGS_FILE, default_enabled=False)
    loaded_settings = read_key_value_map(PIPER_SETTINGS_FILE)

    noise_scale = parse_float(loaded_settings.get("noise_scale", "0.667"), 0.667)
    noise_w = parse_float(loaded_settings.get("noise_w", "0.333"), 0.333)
    sentence_silence = parse_float(loaded_settings.get("sentence_silence", "0.20"), 0.20)

    settings["noise_scale"] = max(0.0, min(1.0, noise_scale))
    settings["noise_w"] = max(0.0, min(1.0, noise_w))
    settings["sentence_silence"] = max(0.0, min(2.0, sentence_silence))

    return settings


def get_elevenlabs_cache_settings() -> dict:
    return get_basic_cache_settings(ELEVENLABS_SETTINGS_FILE, default_enabled=True)


def load_elevenlabs_settings() -> dict:
    settings = {
        "stability": 0.50,
        "similarity_boost": 0.75,
        "style": 0.00,
        "use_speaker_boost": True,
    }

    loaded_settings = read_key_value_map(ELEVENLABS_SETTINGS_FILE)

    for key, value in loaded_settings.items():
        if key in ["stability", "similarity_boost", "style"]:
            settings[key] = parse_float(value, settings[key])

        elif key == "use_speaker_boost":
            settings[key] = parse_bool(value, settings[key])

    settings["stability"] = max(0.0, min(1.0, settings["stability"]))
    settings["similarity_boost"] = max(0.0, min(1.0, settings["similarity_boost"]))
    settings["style"] = max(0.0, min(1.0, settings["style"]))

    return settings


def get_elevenlabs_api_key() -> str:
    try:
        if not ELEVENLABS_API_KEY_FILE.exists():
            return ""

        lines = ELEVENLABS_API_KEY_FILE.read_text(encoding="utf-8").splitlines()

        for line in lines:
            line = line.strip()

            if not line or line.startswith("#"):
                continue

            return line

    except Exception as error:
        log(f"Failed to read ElevenLabs API key file: {error}")

    return ""


def get_elevenlabs_voice_id(voice_key: str) -> str:
    voice_map = read_key_value_map(ELEVENLABS_VOICE_MAP_FILE)

    voice_id = voice_map.get(voice_key, "")

    if not voice_id:
        log(f"ElevenLabs voice ID missing for voice key: {voice_key}")

    return voice_id

#==================
# SPEECH STOPPING
#==================

def stop_current_speech() -> None:
    global current_piper_process

    if current_piper_process and current_piper_process.poll() is None:
        log("Stopping active Piper generation process.")

        try:
            current_piper_process.terminate()
            current_piper_process.wait(timeout=2)

        except Exception as error:
            log(f"Terminate failed, killing Piper process: {error}")

            try:
                current_piper_process.kill()
            except Exception:
                pass

    current_piper_process = None

    try:
        winsound.PlaySound(None, winsound.SND_ASYNC)
        log("Stopped active WAV playback.")

    except Exception as error:
        log(f"Failed to stop WAV playback: {error}")


#==================
# PIPER SPEECH
#==================

def generate_wav_with_piper(text: str, voice_key: str, voice_path: str, is_test_voice: bool = False) -> bool:
    global current_piper_process

    voice_key = voice_key or ""
    text = text or ""
    voice_path = voice_path or ""

    if not text.strip():
        write_status("Piper skipped: empty text.")
        return False

    piper_settings = get_piper_settings()
    cache_enabled = piper_settings["cache_generated_lines"] and not is_test_voice
    cache_max_mb = piper_settings["generated_cache_max_mb"]
    speed = get_speech_speed()
    noise_scale = piper_settings["noise_scale"]
    noise_w = piper_settings["noise_w"]
    sentence_silence = piper_settings["sentence_silence"]

    if is_test_voice:
        log("Test voice not cached.")
    
    cache_input = (
        f"piper|{voice_key}|{voice_path}|{text}|"
        f"speed={speed}|noise_scale={noise_scale}|noise_w={noise_w}|sentence_silence={sentence_silence}"
    )
    cache_path = get_generated_cache_path(PIPER_GENERATED_CACHE_DIR, voice_key, cache_input) if cache_enabled else None

    if cache_enabled and cache_path and cache_path.exists():
        log(f"Piper cached line used: {cache_path}")
        OUTPUT_WAV.write_bytes(cache_path.read_bytes())
        return True

    if not PIPER_EXE.exists():
        write_status("Piper skipped: piper.exe was not found.")
        log(f"Piper executable path: {PIPER_EXE}")
        return False

    try:
        if OUTPUT_WAV.exists():
            try:
                OUTPUT_WAV.unlink()
            except Exception:
                pass

        piper_command = [
            str(PIPER_EXE),
            "-m", voice_path,
            "-f", str(OUTPUT_WAV),
            "--noise-scale", str(noise_scale),
            "--noise-w", str(noise_w),
            "--sentence-silence", str(sentence_silence),
        ]

        log(f"Piper settings: noise_scale={noise_scale}, noise_w={noise_w}, sentence_silence={sentence_silence}")

        current_piper_process = subprocess.Popen(
            piper_command,
            stdin=subprocess.PIPE,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            creationflags=subprocess.CREATE_NO_WINDOW,
        )

        _stdout, stderr = current_piper_process.communicate(input=text)

        if current_piper_process.returncode != 0:
            write_status(f"Piper failed with return code {current_piper_process.returncode}.")

            if stderr:
                log(f"Piper stderr: {stderr.strip()}")

            return False

        if not OUTPUT_WAV.exists():
            write_status("Piper failed: output WAV was not created.")
            return False

        if not adjust_wav_speed(OUTPUT_WAV, speed):
            log("Piper warning: speech speed adjustment failed. Using normal speed.")

        if cache_enabled and cache_path:
            cache_path.write_bytes(OUTPUT_WAV.read_bytes())
            prune_generated_cache(PIPER_GENERATED_CACHE_DIR, cache_max_mb, "Piper")
            log(f"Piper generated and cached: {cache_path}")
        else:
            log("Piper generated without saving a cached dialogue line.")

        return True

    except Exception as error:
        write_status(f"Piper generation failed: {error}")
        return False

    finally:
        current_piper_process = None


#==================
# ELEVENLABS SPEECH
#==================

def generate_wav_with_elevenlabs(text: str, voice_key: str, is_test_voice: bool = False) -> bool:
    voice_key = voice_key or ""
    text = text or ""

    if not text.strip():
        write_status("ElevenLabs skipped: empty text.")
        return False

    voice_id = get_elevenlabs_voice_id(voice_key)
    model_id = read_text_file(ELEVENLABS_MODEL_ID_FILE).strip() or "eleven_multilingual_v2"
    output_format = read_text_file(ELEVENLABS_OUTPUT_FORMAT_FILE).strip() or "wav_22050"
    voice_settings = load_elevenlabs_settings()

    elevenlabs_speed = max(0.7, min(1.2, get_speech_speed()))
    voice_settings["speed"] = elevenlabs_speed

    if not voice_id:
        write_status(f"ElevenLabs skipped: voice ID is missing for {voice_key}.")
        return False

    cache_settings = get_elevenlabs_cache_settings()
    cache_enabled = cache_settings["cache_generated_lines"] and not is_test_voice
    cache_max_mb = cache_settings["generated_cache_max_mb"]

    if is_test_voice:
        log("Test voice not cached.")

    cache_settings_blob = json.dumps(
        {
            "voice_id": voice_id,
            "model_id": model_id,
            "output_format": output_format,
            "voice_settings": voice_settings,
        },
        sort_keys=True,
    )

    cache_input = f"elevenlabs|{voice_key}|{text}|{cache_settings_blob}"
    cache_path = get_generated_cache_path(ELEVENLABS_GENERATED_CACHE_DIR, voice_key, cache_input) if cache_enabled else None

    if cache_enabled and cache_path and cache_path.exists():
        log(f"ElevenLabs cached line used: {cache_path}")
        OUTPUT_WAV.write_bytes(cache_path.read_bytes())
        return True

    api_key = get_elevenlabs_api_key()

    if not api_key:
        write_status("ElevenLabs skipped: API key is missing.")
        return False

    try:
        if OUTPUT_WAV.exists():
            try:
                OUTPUT_WAV.unlink()
            except Exception:
                pass

        query = urllib.parse.urlencode({
            "output_format": output_format,
        })

        url = f"https://api.elevenlabs.io/v1/text-to-speech/{voice_id}?{query}"

        payload = {
            "text": text,
            "model_id": model_id,
            "voice_settings": voice_settings,
        }

        request = urllib.request.Request(
            url,
            data=json.dumps(payload).encode("utf-8"),
            headers={
                "xi-api-key": api_key,
                "Content-Type": "application/json",
                "Accept": "audio/wav",
            },
            method="POST",
        )

        log(f"ElevenLabs request voice key: {voice_key}")
        log(f"ElevenLabs model_id: {model_id}")
        log(f"ElevenLabs output_format: {output_format}")
        log(f"ElevenLabs settings: {voice_settings}")
        log(f"ElevenLabs line cache enabled: {cache_enabled}")

        with urllib.request.urlopen(request, timeout=60) as response:
            audio_bytes = response.read()

        if not audio_bytes:
            write_status("ElevenLabs failed: empty audio returned.")
            return False

        OUTPUT_WAV.write_bytes(audio_bytes)

        if not OUTPUT_WAV.exists():
            log("ElevenLabs completed but output WAV was not created.")
            return False

        if cache_enabled and cache_path:
            cache_path.write_bytes(audio_bytes)
            prune_generated_cache(ELEVENLABS_GENERATED_CACHE_DIR, cache_max_mb, "ElevenLabs")
            log(f"ElevenLabs generated and cached: {cache_path}")
        else:
            log("ElevenLabs generated without saving a cached dialogue line.")

        return True

    except urllib.error.HTTPError as error:
        body = error.read().decode("utf-8", errors="replace")
        write_status(f"ElevenLabs HTTP error {error.code}. Check watcher_log.txt.")
        log(f"ElevenLabs HTTP error body: {body}")
        return False

    except Exception as error:
        write_status(f"ElevenLabs generation failed: {error}")
        return False


#==================
# XTTS PATH RESOLUTION
#==================

def resolve_data_files_relative_path(path_text: str) -> Path:
    raw_path = Path(path_text)

    if raw_path.is_absolute():
        return raw_path

    return DATA_FILES_DIR / raw_path

#==================
# XTTS REFERENCE AUDIO SELECTION
#==================

XTTS_REFERENCE_AUDIO_EXTENSIONS = {
    ".wav",
    ".mp3",
    ".ogg",
    ".flac",
}


def get_reference_audio_file(reference_path: Path) -> Path | None:
    if not reference_path.exists():
        log(f"XTTS reference path does not exist: {reference_path}")
        return None

    if not reference_path.is_file():
        log(f"XTTS reference path is not a file: {reference_path}")
        return None

    if reference_path.suffix.lower() not in XTTS_REFERENCE_AUDIO_EXTENSIONS:
        log(f"XTTS reference path is not a supported audio file: {reference_path}")
        return None

    return reference_path


#==================
# XTTS HELPERS
#==================

def get_xtts_model():
    global xtts_model

    if xtts_model is not None:
        return xtts_model

    if not XTTS_LICENSE_MARKER.exists():
        write_status("XTTS skipped: license marker is missing. Run install_aivoices.bat from Data Files\\MWSE\\mods\\AIVoices and accept the XTTS/Coqui prompt.")
        return None

    os.environ["COQUI_TOS_AGREED"] = "1"

    write_status("XTTS model is loading...")
    log("Loading XTTS model...")

    try:
        XTTS_CACHE_DIR.mkdir(parents=True, exist_ok=True)
        XTTS_GENERATED_CACHE_DIR.mkdir(parents=True, exist_ok=True)
    
        from TTS.api import TTS
        import torch

        device = "cpu"

        if torch.cuda.is_available():
            device = "cuda"

        log(f"Using XTTS device: {device}")

        xtts_model = TTS(XTTS_MODEL_NAME).to(device)

        log("XTTS model loaded.")
        return xtts_model

    except Exception as ex:
        write_status(f"XTTS failed to load model: {ex}")
        return None


def read_xtts_reference_map() -> dict[str, Path]:
    references = {}

    if not XTTS_REFERENCE_MAP_FILE.exists():
        log(f"XTTS reference map missing: {XTTS_REFERENCE_MAP_FILE}")
        return references

    try:
        for raw_line in XTTS_REFERENCE_MAP_FILE.read_text(encoding="utf-8").splitlines():
            line = raw_line.strip()

            if not line:
                continue

            if line.startswith("#"):
                continue

            if "=" not in line:
                continue

            voice_key, path_text = line.split("=", 1)
            voice_key = voice_key.strip()
            path_text = path_text.strip()

            if voice_key and path_text:
                references[voice_key] = resolve_data_files_relative_path(path_text)

    except Exception as error:
        log(f"Failed to read XTTS reference map: {error}")

    return references


def get_xtts_reference_wav(voice_key: str) -> Path | None:
    global xtts_reference_cache

    voice_key = voice_key or ""

    if not voice_key:
        write_status("XTTS skipped: no voice key was provided.")
        return None

    if voice_key in xtts_reference_cache:
        cached_path = xtts_reference_cache[voice_key]

        if cached_path.exists():
            return cached_path

    references = read_xtts_reference_map()

    if voice_key not in references:
        write_status(f"XTTS skipped: no reference audio is set for {voice_key}.")
        return None

    selected_wav = get_reference_audio_file(references[voice_key])

    if selected_wav:
        xtts_reference_cache[voice_key] = selected_wav
        return selected_wav

    write_status(f"XTTS skipped: reference audio missing for {voice_key}.")
    return None


def get_xtts_settings() -> dict:
    settings = read_key_value_map(XTTS_SETTINGS_FILE)

    max_mb = int(parse_float(settings.get("generated_cache_max_mb", "500"), 500))

    if max_mb < 0:
        max_mb = 0

    temperature = parse_float(settings.get("temperature", "0.65"), 0.65)
    repetition_penalty = parse_float(settings.get("repetition_penalty", "2.0"), 2.0)
    top_k = int(parse_float(settings.get("top_k", "50"), 50))
    top_p = parse_float(settings.get("top_p", "0.85"), 0.85)

    temperature = max(0.1, min(2.0, temperature))
    repetition_penalty = max(0.5, min(5.0, repetition_penalty))
    top_k = max(1, min(150, top_k))
    top_p = max(0.1, min(1.0, top_p))

    return {
        "cache_generated_lines": parse_bool(settings.get("cache_generated_lines", "false"), False),
        "generated_cache_max_mb": max_mb,
        "temperature": temperature,
        "repetition_penalty": repetition_penalty,
        "top_k": top_k,
        "top_p": top_p,
    }


def get_xtts_cache_paths(
    voice_key: str,
    text: str,
    reference_wav: Path,
    xtts_settings: dict,
    speech_speed: float,
) -> tuple[Path, Path]:
    voice_key = str(voice_key or "").strip() or "unknown"
    text = str(text or "")

    XTTS_GENERATED_CACHE_DIR.mkdir(parents=True, exist_ok=True)

    voice_cache_dir = XTTS_GENERATED_CACHE_DIR / voice_key
    voice_cache_dir.mkdir(parents=True, exist_ok=True)

    # Legacy V1.01 cache key.
    # Keep this for compatibility with already-generated XTTS caches / PowerCache.
    legacy_cache_input = f"xtts|{voice_key}|{text}"
    legacy_cache_hash = hashlib.sha256(legacy_cache_input.encode("utf-8")).hexdigest()
    legacy_cache_path = voice_cache_dir / f"{legacy_cache_hash}.wav"

    # New stronger cache key.
    # Includes the things that actually affect XTTS output.
    cache_settings_blob = json.dumps(
        {
            "version": "xtts-cache-v2",
            "voice_key": voice_key,
            "reference_wav": str(reference_wav),
            "text": text,
            "speech_speed": speech_speed,
            "temperature": xtts_settings["temperature"],
            "repetition_penalty": xtts_settings["repetition_penalty"],
            "top_k": xtts_settings["top_k"],
            "top_p": xtts_settings["top_p"],
        },
        sort_keys=True,
    )

    new_cache_hash = hashlib.sha256(cache_settings_blob.encode("utf-8")).hexdigest()
    new_cache_path = voice_cache_dir / f"{new_cache_hash}.wav"

    return legacy_cache_path, new_cache_path


def prune_xtts_generated_cache(max_mb: int) -> None:
    if max_mb <= 0:
        return

    if not XTTS_GENERATED_CACHE_DIR.exists():
        return

    max_bytes = max_mb * 1024 * 1024
    cache_files = []
    total_bytes = 0

    try:
        for path in XTTS_GENERATED_CACHE_DIR.rglob("*.wav"):
            try:
                if not path.is_file():
                    continue

                stat = path.stat()
                total_bytes += stat.st_size
                cache_files.append((stat.st_mtime, stat.st_size, path))

            except Exception:
                continue

        if total_bytes <= max_bytes:
            return

        cache_files.sort(key=lambda item: item[0])

        for _mtime, size, path in cache_files:
            if total_bytes <= max_bytes:
                break

            try:
                path.unlink()
                total_bytes -= size
                log(f"Deleted old XTTS cached line: {path}")

            except Exception as error:
                log(f"Failed to delete old XTTS cached line {path}: {error}")

    except Exception as error:
        log(f"Failed to prune XTTS generated line cache: {error}")


def generate_wav_with_xtts(text: str, voice_key: str, is_test_voice: bool = False) -> bool:
    
    voice_key = voice_key or ""
    text = text or ""

    if not text.strip():
        write_status("XTTS skipped: empty text.")
        return False

    reference_wav = get_xtts_reference_wav(voice_key)

    if not reference_wav:
        return False

    xtts_settings = get_xtts_settings()
    cache_enabled = xtts_settings["cache_generated_lines"] and not is_test_voice
    cache_max_mb = xtts_settings["generated_cache_max_mb"]

    if is_test_voice:
        log("Test voice not cached.")

    speech_speed = get_speech_speed()
    
    legacy_cache_path = None
    cache_path = None
    
    if cache_enabled:
        legacy_cache_path, cache_path = get_xtts_cache_paths(
            voice_key=voice_key,
            text=text,
            reference_wav=reference_wav,
            xtts_settings=xtts_settings,
            speech_speed=speech_speed,
        )
    
        if legacy_cache_path.exists():
            log(f"XTTS legacy cached line used: {legacy_cache_path}")
            OUTPUT_WAV.write_bytes(legacy_cache_path.read_bytes())
            return True
    
        if cache_path.exists():
            log(f"XTTS cached line used: {cache_path}")
            OUTPUT_WAV.write_bytes(cache_path.read_bytes())
            return True

    try:
        if OUTPUT_WAV.exists():
            try:
                OUTPUT_WAV.unlink()
            except Exception:
                pass

        log(f"Generating XTTS voice: {voice_key}")
        log(f"XTTS reference: {reference_wav}")
        log(f"XTTS line cache enabled: {cache_enabled}")

        model = get_xtts_model()

        if model is None:
            return False

        output_path = cache_path if cache_enabled and cache_path else OUTPUT_WAV
        chunk_base_path = output_path

        text_chunks = split_text_for_tts(text, 240)

        if not text_chunks:
            log("XTTS skipped empty text after splitting.")
            return False

        chunk_paths = []

        for index, chunk in enumerate(text_chunks):
            chunk_path = chunk_base_path.with_name(chunk_base_path.stem + f"_part_{index + 1}.wav")
        
            log(f"Generating XTTS chunk {index + 1}/{len(text_chunks)}.")
            log(f"XTTS chunk text: {chunk}")

            xtts_chunk = chunk.replace(". ", ";\n") # Workaround for XTTS. Sometimes the speech will pronounce a period as "dot". Known issue with XTTS. This replaces all "." with ";\n".
            if xtts_chunk.endswith("."):
                xtts_chunk = xtts_chunk[:-1]
        
            model.tts_to_file(
                text=xtts_chunk,
                speaker_wav=str(reference_wav),
                language="en",
                file_path=str(chunk_path),
                temperature=xtts_settings["temperature"],
                repetition_penalty=xtts_settings["repetition_penalty"],
                top_k=xtts_settings["top_k"],
                top_p=xtts_settings["top_p"],
            )

            if not chunk_path.exists():
                log(f"XTTS chunk failed: {chunk_path}")
                for p in chunk_paths:
                    p.unlink(missing_ok=True)
                return False

            chunk_paths.append(chunk_path)

        
        if not concat_wav_files(chunk_paths, output_path):
            write_status("XTTS failed: could not combine generated chunks.")
            for p in chunk_paths:
                p.unlink(missing_ok=True)
            return False
        
        if not output_path.exists():
            write_status("XTTS failed: output WAV was not created.")
            for p in chunk_paths:
                p.unlink(missing_ok=True)
            return False
        
        if not adjust_wav_speed(output_path, speech_speed):
            write_status("XTTS warning: speech speed adjustment failed. Using normal speed.")

        if cache_enabled and cache_path:
            OUTPUT_WAV.write_bytes(cache_path.read_bytes())
            prune_xtts_generated_cache(cache_max_mb)
            log(f"XTTS generated and cached: {cache_path}")
        else:
            log("XTTS generated without saving a cached dialogue line.")

        for chunk_path in chunk_paths:
            try:
                chunk_path.unlink(missing_ok=True)
            except Exception:
                pass

        return True

    except Exception as error:
        write_status(f"XTTS generation failed: {error}")
        return False

#==================
# TTS TEXT SPLITTING
#==================

def split_text_for_tts(text: str, max_length: int = 240) -> list[str]:
    text = str(text or "").strip()

    if not text:
        return []

    if len(text) <= max_length:
        return [text]

    chunks = []
    current = ""

    sentences = text.replace("? ", "?. ").replace("! ", "!. ").split(". ")

    for sentence in sentences:
        sentence = sentence.strip()

        if not sentence:
            continue

        if len(sentence) > max_length:
            parts = sentence.split(", ")
        else:
            parts = [sentence]

        for part in parts:
            part = part.strip()

            if not part:
                continue

            test = part if not current else current + ", " + part

            if len(test) <= max_length:
                current = test
            else:
                if current:
                    chunks.append(current)

                current = part

    if current:
        chunks.append(current)

    result = []

    for chunk in chunks:
        chunk = chunk.strip()

        if chunk and chunk[-1] not in ".!?":
            chunk += "."

        result.append(chunk)

    return result

#==================
# CONCATENATE CHUNKS
#==================

def concat_wav_files(input_paths: list[Path], output_path: Path) -> bool:
    if not input_paths:
        return False

    if len(input_paths) == 1:
        output_path.write_bytes(input_paths[0].read_bytes())
        return True

    list_path = output_path.with_suffix(".concat.txt")

    try:
        lines = [f"file '{path.as_posix()}'" for path in input_paths]
        list_path.write_text("\n".join(lines), encoding="utf-8")

        ffmpeg_exe = PRIVATE_FFMPEG_BIN / "ffmpeg.exe"
        
        if not ffmpeg_exe.exists():
            log("Portable FFmpeg not found. Run install_aivoices.bat and install XTTS or Piper support.")
            return False

        result = subprocess.run(
            [
                str(ffmpeg_exe),
                "-y",
                "-hide_banner",
                "-loglevel",
                "error",
                "-f",
                "concat",
                "-safe",
                "0",
                "-i",
                str(list_path),
                str(output_path),
            ],
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            creationflags=subprocess.CREATE_NO_WINDOW,
        )

        if result.returncode != 0:
            log(f"FFmpeg concat failed: {result.stderr.strip()}")
            return False

        return output_path.exists()

    except Exception as error:
        log(f"Failed to concat WAV files: {error}")
        return False

    finally:
        try:
            list_path.unlink(missing_ok=True)
        except Exception:
            pass

#==================
# XTTS SPEECH SPEED
#==================

def build_atempo_filter(speed: float) -> str:
    speed = max(0.75, min(3.00, float(speed or 1.0)))

    filters = []
    remaining_speed = speed

    while remaining_speed > 2.0:
        filters.append("atempo=2.0")
        remaining_speed = remaining_speed / 2.0

    while remaining_speed < 0.5:
        filters.append("atempo=0.5")
        remaining_speed = remaining_speed / 0.5

    filters.append(f"atempo={remaining_speed:.2f}")

    return ",".join(filters)


def adjust_wav_speed(input_path: Path, speed: float) -> bool:
    speed = max(0.75, min(3.00, float(speed or 1.0)))

    if abs(speed - 1.0) < 0.001:
        return True

    ffmpeg_exe = PRIVATE_FFMPEG_BIN / "ffmpeg.exe"
    
    if not ffmpeg_exe.exists():
        log("Portable FFmpeg not found. Run install_aivoices.bat and install XTTS or Piper support.")
        return False

    temp_path = input_path.with_name(input_path.stem + "_speed.wav")
    atempo_filter = build_atempo_filter(speed)

    try:
        result = subprocess.run(
            [
                str(ffmpeg_exe),
                "-y",
                "-hide_banner",
                "-loglevel",
                "error",
                "-i",
                str(input_path),
                "-filter:a",
                atempo_filter,
                str(temp_path),
            ],
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            creationflags=subprocess.CREATE_NO_WINDOW,
        )

        if result.returncode != 0:
            log(f"FFmpeg speed adjustment failed: {result.stderr.strip()}")
            return False

        if not temp_path.exists():
            log("FFmpeg speed adjustment failed: output file missing.")
            return False

        input_path.write_bytes(temp_path.read_bytes())
        return True

    except Exception as error:
        log(f"Failed to adjust WAV speed: {error}")
        return False

    finally:
        try:
            temp_path.unlink(missing_ok=True)
        except Exception:
            pass



#==================
# WAV PLAYBACK
#==================

def play_wav(async_play: bool = True) -> None:
    try:
        flags = winsound.SND_FILENAME

        if async_play:
            flags = flags | winsound.SND_ASYNC

        apply_wav_volume(OUTPUT_WAV)

        played_mtime = OUTPUT_WAV.stat().st_mtime if OUTPUT_WAV.exists() else 0.0

        winsound.PlaySound(str(OUTPUT_WAV), flags)

        if async_play:
            def cleanup_playback_wav():
                for _ in range(120):
                    time.sleep(1)

                    try:
                        if OUTPUT_WAV.exists():
                            current_mtime = OUTPUT_WAV.stat().st_mtime

                            if current_mtime != played_mtime:
                                log("Skipped playback WAV cleanup because a newer WAV exists.")
                                return

                        OUTPUT_WAV.unlink(missing_ok=True)

                        if not OUTPUT_WAV.exists():
                            log("Deleted temporary playback WAV.")
                            return

                        log("Temporary playback WAV still exists after delete attempt.")

                    except Exception as error:
                        log(f"Could not delete temporary playback WAV yet: {error}")

                log("Gave up deleting temporary playback WAV.")

            threading.Thread(target=cleanup_playback_wav, daemon=True).start()
        else:
            try:
                if OUTPUT_WAV.exists():
                    current_mtime = OUTPUT_WAV.stat().st_mtime

                    if current_mtime != played_mtime:
                        log("Skipped playback WAV cleanup because a newer WAV exists.")
                        return

                OUTPUT_WAV.unlink(missing_ok=True)

                if not OUTPUT_WAV.exists():
                    log("Deleted temporary playback WAV.")
                else:
                    log("Temporary playback WAV still exists after delete attempt.")

            except Exception as error:
                log(f"Failed to delete temporary playback WAV: {error}")

    except Exception as error:
        log(f"WAV playback failed: {error}")


#==================
# SPEECH ROUTER
#==================

def speak(text: str, async_play: bool = True) -> None:
    if not text:
        return

    text = apply_pronunciation_dictionary(text)
    log(f"Text after pronunciation: {text}")

    text = clean_text_for_tts(text)
    log(f"Text sent to TTS: {text}")

    stop_current_speech()

    engine = get_tts_engine()
    voice_text = read_text_file(VOICE_FILE)

    log(f"TTS engine: {engine}")
    log(f"Speaking: {text}")

    if engine == "xtts":
        is_test_voice = False
        voice_key = parse_voice_key("xtts", voice_text)
    
        if not voice_key:
            voice_key = parse_voice_key("xtts-test", voice_text)
    
            if voice_key:
                is_test_voice = True
    
        log(f"XTTS voice key: {voice_key}")
        log(f"XTTS test voice: {is_test_voice}")
    
        if generate_wav_with_xtts(text, voice_key, is_test_voice):
            play_wav(async_play=async_play)
    
        return

    if engine == "elevenlabs":
        is_test_voice = False
        voice_key = parse_voice_key("elevenlabs", voice_text)

        if not voice_key:
            voice_key = parse_voice_key("elevenlabs-test", voice_text)

            if voice_key:
                is_test_voice = True

        log(f"ElevenLabs voice key: {voice_key}")
        log(f"ElevenLabs test voice: {is_test_voice}")

        if generate_wav_with_elevenlabs(text, voice_key, is_test_voice):
            play_wav(async_play=async_play)

        return

    if engine == "piper":
        is_test_voice = False
        voice_key = parse_voice_key("piper", voice_text)

        if not voice_key:
            voice_key = parse_voice_key("piper-test", voice_text)

            if voice_key:
                is_test_voice = True

        log(f"Piper voice key: {voice_key}")
        log(f"Piper test voice: {is_test_voice}")
    
        voice_path = resolve_piper_voice_path(voice_key)
    
        if not voice_path:
            return
    
        log(f"Piper voice: {voice_path}")
    
        if generate_wav_with_piper(text, voice_key, voice_path, is_test_voice):
            play_wav(async_play=async_play)
    
        return

    write_status(f"Unknown TTS engine: {engine}.")


#==================
# XTTS PRELOAD
#==================

def preload_xtts_if_selected() -> None:

    engine = get_tts_engine()

    if engine != "xtts":
        log(f"XTTS preload skipped because selected engine is '{engine}'.")
        return

    if not XTTS_LICENSE_MARKER.exists():
        log("NOTICE: XTTS preload skipped because XTTS is not installed or the license marker is missing.")
        write_status("XTTS is selected, but XTTS is not installed. Run install_aivoices.bat if you want to use XTTS.")
        return

    if not XTTS_REFERENCE_MAP_FILE.exists():
        log("NOTICE: XTTS preload skipped because xtts_reference_map.txt is missing.")
        write_status("XTTS is selected, but the XTTS reference map is missing.")
        return

    log("XTTS preload starting.")

    model = get_xtts_model()


    if model is None:
        log("NOTICE: XTTS preload did not complete.")
        write_status("XTTS is selected, but the model did not load. Check watcher_log.txt.")
        return

    write_status("XTTS model loaded.")
    log("XTTS preload complete.")

#==================
# LOG PATH DISPLAY
#==================

def short_path(path) -> str:
    try:
        path = Path(path)

        if path == SCRIPT_DIR:
            return "/AIVoices"

        return "/AIVoices/" + path.relative_to(SCRIPT_DIR).as_posix()

    except Exception:
        return str(path)

#==================
# INITIALIZATION
#==================

try:
    WATCHER_LOG_FILE.parent.mkdir(parents=True, exist_ok=True)
    WATCHER_LOG_FILE.write_text("", encoding="utf-8")

    log("AI Voices watcher started.")
    
    create_default_files_if_missing()
    
    threading.Thread(
        target=watcher_heartbeat_loop,
        daemon=True,
    ).start()
    
    log(f"Script folder: {short_path(SCRIPT_DIR)}")
    log(f"Data Files folder: {DATA_FILES_DIR}")
    log(f"Backend folder: {BACKEND_DIR}")
    log(f"Runtime folder: {short_path(RUNTIME_DIR)}")
    log(f"Settings folder: {short_path(SETTINGS_DIR)}")
    log(f"Piper folder: {short_path(PIPER_DIR)}")
    log(f"XTTS folder: {short_path(XTTS_DIR)}")
    log(f"ElevenLabs folder: {short_path(ELEVENLABS_DIR)}")
    log(f"Dependencies folder: {short_path(DEPENDENCIES_DIR)}")
    log(f"Dialogue file: {short_path(DIALOGUE_FILE)}")
    log(f"Voice file: {short_path(VOICE_FILE)}")
    log(f"Stop file: {short_path(STOP_FILE)}")
    log(f"Heartbeat file: {short_path(HEARTBEAT_FILE)}")
    log(f"TTS engine file: {short_path(TTS_ENGINE_FILE)}")
    log(f"XTTS reference map file: {short_path(XTTS_REFERENCE_MAP_FILE)}")
    log(f"XTTS cache dir: {short_path(XTTS_CACHE_DIR)}")
    engine = get_tts_engine()
    
    if engine == "xtts":
        log(f"XTTS generated line cache dir: {XTTS_GENERATED_CACHE_DIR}")
    
        xtts_settings = get_xtts_settings()
        cache_enabled = xtts_settings["cache_generated_lines"]
        cache_max_mb = xtts_settings["generated_cache_max_mb"]
    
        log(f"XTTS generated line cache enabled: {cache_enabled}")
        log(f"XTTS generated line cache limit MB: {cache_max_mb}")

    last_stop_modified_time = get_modified_time(STOP_FILE)
    last_seen_heartbeat_modified_time = get_modified_time(HEARTBEAT_FILE)

    log("Watcher initialized.")
    log("")
    write_status("Ready.")
    
    log("AI Voices: Ready")
    log("")
    log("")
    log("Watcher listening for dialogue...")
    
    write_watcher_heartbeat()
    preload_xtts_if_selected()
    last_dialogue_modified_time = get_modified_time(DIALOGUE_FILE)

    #==================
    # MAIN LOOP
    #==================

    shutdown_reason = "Watcher ended."

    while True:
        try:
            if not heartbeat_is_alive():
                log("Morrowind heartbeat stopped. Stopping speech and exiting watcher.")
                stop_current_speech()
                break

            current_stop_modified_time = get_modified_time(STOP_FILE)

            if current_stop_modified_time > last_stop_modified_time:
                last_stop_modified_time = current_stop_modified_time
                log("Stop signal received.")
                stop_current_speech()

            current_modified_time = get_modified_time(DIALOGUE_FILE)

            if current_modified_time > last_dialogue_modified_time:
                last_dialogue_modified_time = current_modified_time

                text = read_text_file(DIALOGUE_FILE)

                if text:
                    speak(text, async_play=True)
                else:
                    log("Dialogue file changed, but it was empty.")

        except KeyboardInterrupt:
            log("Watcher stopped manually.")
            break

        except Exception as error:
            log(f"Watcher error: {error}")

        time.sleep(CHECK_INTERVAL_SECONDS)


    #==================
    # SHUTDOWN
    #==================

    stop_current_speech()
    log(shutdown_reason)


finally:
    #==================
    # CLEANUP
    #==================
    watcher_is_running = False
    release_process_lock()
