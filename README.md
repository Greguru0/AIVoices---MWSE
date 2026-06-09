# AI Voices - V1.01a

AI Voices is an MWSE mod for Morrowind that generates spoken dialogue for NPCs in real time using local or online text-to-speech engines.

Supports **XTTS**, **Piper**, and **ElevenLabs**.

## Features

* Real-time TTS voice generation triggered by NPC dialogue
* Three supported voice engines: XTTS, Piper, and ElevenLabs
* Race and gender fallback voice mapping for unassigned NPCs
* Pronunciation dictionary for customizing how specific words and names are spoken
* Watcher heartbeat system: the background process monitors the game and shuts down automatically when Morrowind closes
* In-game MCM settings for all voice engines, volume, and pronunciation
* All generated files, model caches, and dependencies are contained within the mod's backend folder

## Requirements

* The Elder Scrolls III: Morrowind
* MGE XE with MWSE 2.1 or newer
* Python 3.10, 3.11, or 3.12, 64-bit, added to PATH
* An NVIDIA GPU is recommended for XTTS. CPU-only is supported but will be significantly slower.
* An internet connection is required during installation for downloading dependencies, and during runtime if using ElevenLabs.

## Voice Engines

### XTTS Recommended

Local AI voice cloning using Coqui XTTS v2. Generates voices by cloning from reference audio samples built from your installed Morrowind MP3 voice files.

* Uses your own CPU or NVIDIA GPU
* Reference samples are built locally from your game's existing voice files during install
* Generated dialogue can be cached to speed up repeated lines, disabled by default
* Install size: approximately 7 GB including the model and dependencies
* Performance depends heavily on hardware. See the FAQ.

XTTS loads on first use. If you switch to XTTS after starting the game, use **Test Voice** once to preload the model before talking to NPCs.

Once loaded, it stays loaded until `watcher.py` exits.

### Piper

Local TTS using `.onnx` voice model files. Fast even on CPU, but requires you to provide your own `.onnx` and `.onnx.json` voice files for each race and gender.

* No internet required at runtime
* A generic sample voice can be downloaded during install for quick testing
* Install size: approximately 214 MB with the generic sample voice

### ElevenLabs

Online TTS using your own ElevenLabs account. High quality and fast, but requires an API key and uses ElevenLabs credits per generated line.

* Requires an ElevenLabs account and API key
* Text to Speech and optionally Voices Read permissions are needed on the API key
* No large local install
* Speech generation uses your ElevenLabs credits

## Installation

1. Extract the contents of this zip folder into the Morrowind `Data Files` folder so that this folder exists:

   ```text
   Data Files\MWSE\mods\AIVoices\
   ```

2. Run:

   ```text
   Data Files\MWSE\mods\AIVoices\install_aivoices.bat
   ```

3. Follow the installer prompts to select which voice engines to set up. You can set up more than one.

4. Launch Morrowind. AI Voices will start automatically.

XTTS will take a moment to start because it loads the model when first initialized. There will be an on-screen message when it is ready.

The installer creates a local Python virtual environment, downloads required dependencies, builds XTTS reference samples from your installed voice files, and writes all runtime and settings files into:

```text
Data Files\AIVoicesBackend\
```

The installer does not modify any original Morrowind files.

## Uninstallation

Run:

```text
Data Files\MWSE\mods\AIVoices\uninstall_aivoices.bat
```

This removes the virtual environment, runtime files, settings, and engine-specific folders.

It does **not** remove the mod's Lua files, the installer, or your Morrowind voice files.

You will be prompted before the ElevenLabs and Piper folders are removed, as these may contain your API key or custom voice files.

## Voice Mapping

AI Voices assigns voices to NPCs using a two-level lookup.

1. **Actor-specific:** if the actor's ID or name matches a key in the voice map file, that voice is used.
2. **Race and gender fallback:** if no actor-specific match is found, the race and gender combination is used, such as `darkElfMale` or `nordFemale`.

Some special NPCs will not fall back to race and gender because they are technically creatures. Vivec is one example.

Voice map files are plain text and can be edited directly or managed through the MCM. Each engine has its own map file in the backend folder.

## Pronunciation

A pronunciation dictionary at:

```text
AIVoicesBackend\settings\pronunciation.txt
```

allows you to control how specific words are spoken.

Entries use this format:

```text
original=replacement
```

Longer entries are matched before shorter ones to avoid partial substitutions.

Entries can be added directly in the file or through the MCM. The file is re-read automatically when it changes, so edits take effect without restarting.

## MCM Settings

The in-game Mod Configuration Menu provides access to:

* Enable or disable the mod
* Select the active TTS engine
* Adjust voice volume
* Test the selected voice engine
* Manage pronunciation entries
* Configure XTTS generation parameters: temperature, repetition penalty, top K, and top P
* Adjust speech speed, applies to all engines, with ElevenLabs capped at 1.2 by API
* Configure ElevenLabs model, output format, and voice settings
* Manage voice map entries for all three engines
* Clear generated-line caches for XTTS, Piper, and ElevenLabs
* Configure Piper generation settings: Noise Scale, Noise W, and Sentence Silence
* Configure generated-line cache settings for XTTS, Piper, and ElevenLabs
* Reset generation settings to defaults for XTTS, Piper, and ElevenLabs
* Configure watcher process settings, including console visibility, Python path, and heartbeat interval

## File Structure

```text
Data Files\
  MWSE\mods\AIVoices\
    main.lua                    - main MWSE mod script
    mcm.lua                     - Mod Config Menu settings
    config.lua                  - default AI Voices config
    watcher.py                  - backend watcher that sends dialogue to the selected TTS engine
    install_aivoices.bat        - installer for Python, voice engines, FFmpeg, and backend setup
    uninstall_aivoices.bat      - optional uninstaller for AI Voices files

  AIVoicesBackend\
    runtime\                    - dialogue, voice, stop, status, and heartbeat files
    settings\                   - TTS engine, volume, pronunciation, and shared engine settings
    XTTS\                       - XTTS reference map, reference samples, settings, and generated-line cache
    Piper\                      - Piper voice map, settings, .onnx voice files, and generated-line cache
    ElevenLabs\                 - ElevenLabs API key, voice map, model/output settings, and generated-line cache
    dependencies\               - Python virtual environment, FFmpeg, Piper executable files, and dependency cache
    install_markers\            - installer completion markers, logs, and diagnostic files
    build_reference_samples.py  - helper tool for creating XTTS reference samples
```

## build_reference_samples.py

AI Voices includes a helper tool at:

```text
Data Files\AIVoicesBackend\build_reference_samples.py
```

The installer uses this tool to build XTTS reference samples from your installed Morrowind voice files. Most users do not need to run it manually.

Advanced users can also run it directly to create a custom XTTS reference WAV from a folder of MP3 files.

The tool will ask for:

* an MP3 folder path
* an output WAV path/name

After creating a custom WAV, place it into the reference sample folder:

```text
Data Files\AIVoicesBackend\XTTS\reference_samples\
```

Then map the RaceID to the WAV file in:

```text
Data Files\AIVoicesBackend\XTTS\xtts_reference_map.txt
```

Example:

```text
keptu-queyMale=AIVoicesBackend\XTTS\reference_samples\keptu-queyMale.wav
```

## Known Issues and Limitations

### XTTS can be slow on weak hardware

Generation time depends on CPU/GPU performance. On CPU-only systems, a single line may take 30 seconds or more. Piper or ElevenLabs are recommended for users without a capable NVIDIA GPU.

### XTTS line caching has limited benefit

Because Morrowind dialogue is large and varied, the same line is rarely repeated outside of common greetings. Caching is available but disabled by default.

### Piper requires user-provided voice files

The generic sample voice downloaded during install is not Morrowind-specific. Morrowind-appropriate voices require sourcing compatible `.onnx` files separately.

### ElevenLabs uses credits per line

Every uncached dialogue line sent to ElevenLabs consumes API credits. This is noted during install and in the MCM.

### Python is required

The watcher process requires Python to be installed system-wide. The mod uses a local virtual environment for packages, but Python itself must be installed and available on PATH before running the installer.

### SyntaxWarnings from pysbd may appear

SyntaxWarnings from `pysbd` may appear in the watcher console or during the installer when using XTTS. These come from a Coqui TTS dependency and are harmless.

## FAQ

### XTTS is generating speech very slowly. What can I do?

XTTS performance depends on your hardware. An NVIDIA GPU is strongly recommended. On a modern NVIDIA card, short lines typically generate in a few seconds. On CPU, generation can take significantly longer.

If XTTS is too slow for comfortable play, switching to Piper or ElevenLabs in the MCM is the recommended alternative. Piper is fast even on CPU.

### No voice is playing. What should I check?

Open the watcher console with **Show Watcher Console** in the MCM Watcher page and check for error messages.

Common causes are:

* a missing or invalid voice map entry for the current NPC's race and gender
* a missing reference audio file for XTTS
* a missing or invalid ElevenLabs API key

### A specific NPC has no voice. What should I check?

Check whether the NPC's race and gender have an entry in the active engine's voice map file.

If using XTTS, also confirm the reference audio path in `xtts_reference_map.txt` is valid.

Actor-specific entries can be added to the voice map using the actor's ID or name as the key.

### Can I use this with Tamriel Rebuilt or other mods that add NPCs?

Yes. NPCs added by other mods will use the race and gender fallback voice if their actor ID or name is not in the voice map.

You can add actor-specific entries manually for any NPC.

### Does this mod work without an NVIDIA GPU?

Yes. XTTS will run on CPU, but generation will be much slower. Piper is the recommended engine for CPU-only systems. ElevenLabs has no local performance requirement.

### Will this work with OpenMW?

No. AI Voices requires MWSE, which is not compatible with OpenMW.

### Is Bethesda audio uploaded or redistributed?

No. XTTS reference samples are built locally from your own installed Morrowind voice files during install and are never uploaded, shared, or distributed.

## Credits

Created by **Greguru**
Nexus Mods: **Diablo0987**

Uses the following open source projects:

* Coqui TTS / XTTS v2 - local AI voice cloning
* Piper TTS - local neural TTS
* FFmpeg - audio processing, portable build via GyanD/codexffmpeg
* PyTorch - deep learning backend for XTTS

## License

AI Voices - MWSE is licensed under the **GNU General Public License v3.0 or later**.

Copyright (C) 2026 Greguru / Diablo0987

This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or, at your option, any later version.

This repository does not include Bethesda game files, Morrowind voice files, generated voice samples, ElevenLabs voices, XTTS voices, Piper voices, or generated dialogue audio.

Users are responsible for complying with the licenses and terms of any external tools, models, or services they choose to install or use, including FFmpeg, Piper, Coqui/XTTS, PyTorch, and ElevenLabs.

## Links

* Nexus Mods: https://www.nexusmods.com/morrowind/mods/59250
* GitHub: https://github.com/Greguru0/AIVoices---MWSE/tree/main

## Contact

Email: [GreguruGames@protonmail.me](mailto:GreguruGames@protonmail.me)
