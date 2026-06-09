@echo off
setlocal EnableExtensions EnableDelayedExpansion

cd /d "%~dp0"

set "MOD_DIR=%CD%"
for %%I in ("%MOD_DIR%\..\..\..") do set "DATA_FILES_DIR=%%~fI"
set "BACKEND_DIR=%DATA_FILES_DIR%\AIVoicesBackend"
set "AIVOICES_INSTALLER_VERSION=V1.01a"
set "INSTALL_MARKER_FILE=%BACKEND_DIR%\install_markers\aivoices_installed.txt"
set "EXISTING_AIVOICES_VERSION="

rem ==============================
rem COLORED MESSAGE HELPERS
rem ==============================

goto after_color_helpers

:SayRed
set "AIVOICES_COLOR_MESSAGE=%~1"
powershell -NoProfile -Command "Write-Host $env:AIVOICES_COLOR_MESSAGE -ForegroundColor Red"
exit /b 0

:SayYellow
set "AIVOICES_COLOR_MESSAGE=%~1"
powershell -NoProfile -Command "Write-Host $env:AIVOICES_COLOR_MESSAGE -ForegroundColor Yellow"
exit /b 0

:SayCyan
set "AIVOICES_COLOR_MESSAGE=%~1"
powershell -NoProfile -Command "Write-Host $env:AIVOICES_COLOR_MESSAGE -ForegroundColor Cyan"
exit /b 0

:SayBlue
set "AIVOICES_COLOR_MESSAGE=%~1"
powershell -NoProfile -Command "Write-Host $env:AIVOICES_COLOR_MESSAGE -ForegroundColor Blue"
exit /b 0

:SayGreen
set "AIVOICES_COLOR_MESSAGE=%~1"
powershell -NoProfile -Command "Write-Host $env:AIVOICES_COLOR_MESSAGE -ForegroundColor Green"
exit /b 0

:SayWhite
set "AIVOICES_COLOR_MESSAGE=%~1"
powershell -NoProfile -Command "Write-Host $env:AIVOICES_COLOR_MESSAGE -ForegroundColor White"
exit /b 0

:after_color_helpers

echo.
echo ==============================
call :SayCyan "AI Voices MWSE - Installer" V1.01a
echo ==============================
call :SayBlue " - Created by Greguru (Nexus Mods: Diablo0987)"
echo.

rem This installer must be in the correct directory. Mod Managers are unavailable, right now.

if not exist "!DATA_FILES_DIR!\..\Morrowind.exe" (
    echo.
    call :SayRed "ERROR: Could not find Morrowind.exe near the resolved install path."
    echo.
    echo Resolved path:
    echo !DATA_FILES_DIR!
    echo.
    call :SayRed "If you are using a mod manager, this installer must be run from the real"
    call :SayRed "Morrowind Data Files folder, not from a mod manager's staging folder."
    echo.
    echo Extract the mod manually into your Morrowind Data Files folder and run
    echo install_aivoices.bat from there.
    echo.
	echo The folder structure should be:
	echo.
	echo   Data Files\
	echo     MWSE\
	echo       mods\
	echo         AIVoices\
	echo           main.lua
	echo           mcm.lua
	echo           config.lua
	echo           watcher.py
	echo           install_aivoices.bat
	echo           uninstall_aivoices.bat
    echo.
    call :cleanup_environment
    pause
    exit /b 1
)

set "EXISTING_AIVOICES_VERSION="

if exist "!INSTALL_MARKER_FILE!" (
    for /f "tokens=1,* delims=:" %%A in ('findstr /B /C:"AI Voices version" "!INSTALL_MARKER_FILE!" 2^>nul') do (
        set "EXISTING_AIVOICES_VERSION=%%B"
    )

    set "EXISTING_AIVOICES_VERSION=!EXISTING_AIVOICES_VERSION: =!"

    if "!EXISTING_AIVOICES_VERSION:~0,1!"=="=" (
        set "EXISTING_AIVOICES_VERSION=!EXISTING_AIVOICES_VERSION:~1!"
    )

    set "EXISTING_AIVOICES_VERSION=!EXISTING_AIVOICES_VERSION: =!"

    if "!EXISTING_AIVOICES_VERSION!"=="" (
        set "EXISTING_AIVOICES_VERSION=V1.00 or older"
    )

    if "!EXISTING_AIVOICES_VERSION!"=="=" (
        set "EXISTING_AIVOICES_VERSION=V1.00 or older"
    )

    echo.
    echo ==============================
    call :SayYellow "Existing AI Voices install detected"
    echo ==============================
    echo.
    echo Backend folder:
    echo !BACKEND_DIR!
    echo.
    echo Installed version:
    echo !EXISTING_AIVOICES_VERSION!
    echo.
    echo Installer version:
    echo !AIVOICES_INSTALLER_VERSION!
    echo.

    if /I "!EXISTING_AIVOICES_VERSION!"=="!AIVOICES_INSTALLER_VERSION!" (
        call :SayGreen "You already have the current AI Voices installer version."
        echo.
        echo You do not need to run the installer again unless you want to:
        echo - Add another voice engine
        echo - Repair or recreate the Python environment
        echo - Reinstall XTTS, Piper, or ElevenLabs support files
        echo.
        choice /C YN /N /M "Existing AI Voices install detected. Continue anyway to add/repair voice engines? [Y/N] "

        if errorlevel 2 (
            echo.
            call :SayYellow "Installer cancelled. Existing install was left unchanged."
            pause
            exit /b 0
        )
    ) else (
        call :SayYellow "This looks like an different AI Voices install."
        echo.
        echo If you are updating from V1.00 to V1.01a, you usually do not need to run this installer again.
        echo New V1.01a settings and folders are created automatically when the mod loads. 
        echo V1.01a features are available without using this installer.
		echo.
        echo You may still continue if you want to:
        echo - Add another voice engine
        echo - Repair or recreate the Python environment
        echo - Reinstall XTTS, Piper, or ElevenLabs support files
        echo.
        choice /C YN /N /M "Existing AI Voices install detected. Continue installer anyway? [Y/N] "

        if errorlevel 2 (
            echo.
            call :SayYellow "Installer cancelled. Existing install was left unchanged."
            pause
            exit /b 0
        )
    )
)

call :SayCyan "Requirements:"
echo - Windows
echo - Morrowind
echo - MGE XE / MWSE
echo - Python 3.10, 3.11, or 3.12, 64-bit recommended
echo - Internet connection for downloads during install
echo - Internet connection during gameplay only if using ElevenLabs
echo - Enough free drive space for the selected voice engines
echo.

call :SayCyan "What this installer does:"
echo Sets up AI Voices using this mod folder and Data Files\AIVoicesBackend.
echo Creates runtime files, settings files, a local Python virtual environment,
echo and support files for the voice engines you choose.
echo.
echo You can install one voice engine or multiple voice engines.
echo The active voice engine is selected later in the MCM.
echo.

call :SayCyan "Install containment:"
echo AI Voices keeps its runtime files, virtual environment, voice engine files,
echo FFmpeg, model cache, and generated dialogue caches inside:
echo Data Files\AIVoicesBackend
echo.
echo pip caching is disabled, and pip temp files are redirected into the backend folder.
echo Small system temp files may still be created by Windows, Python, PowerShell, or curl.
echo.

call :SayCyan "Voice engines:"
echo.

call :SayCyan " - XTTS"
echo   Local AI voice cloning using Coqui XTTS.
call :SayBlue "  Uses NVIDIA CUDA when available, otherwise CPU."
call :SayBlue "  Builds local reference samples from your installed Morrowind voice files."
call :SayBlue "  Generated dialogue lines can be cached if enabled in the MCM."
call :SayYellow "  Recommended for local AI voice cloning, but it is the largest and slowest option."
echo.

call :SayCyan " - Piper"
echo   Local text-to-speech using .onnx voice files.
call :SayBlue "  Fast and local. No internet required during gameplay."
call :SayBlue "  Can use a generic sample voice for testing."
call :SayBlue "  Custom voices require your own .onnx and .onnx.json files."
call :SayBlue "  Generated dialogue lines can be cached if enabled in the MCM."
echo.

call :SayCyan " - ElevenLabs"
echo   Online text-to-speech using your own ElevenLabs account.
call :SayBlue "  Small local install. Fast and high-quality."
call :SayBlue "  Speech generation uses ElevenLabs credits."
call :SayBlue "  Generated dialogue lines are cached by default to avoid repeating the same API request."
call :SayCyan "    ElevenLabs API key permissions:"
call :SayBlue "   - Text to Speech: Access - used to generate voice audio"
call :SayBlue "   - Voices: Read - used by this installer to list available voices (Optional)"
echo.

call :SayYellow "Generated-line cache defaults:"
echo - XTTS cache: Off
echo - Piper cache: Off
echo - ElevenLabs cache: On
echo - Cache limits can be changed in the MCM
echo - Test voices are not saved to generated-line caches
echo.

call :SayYellow "This installer will NOT:"
echo - Overwrite or change your original Morrowind files
echo - Include Bethesda audio
echo - Upload Bethesda audio
echo - Generate ElevenLabs speech or use ElevenLabs credits during install
echo.

call :SayYellow "Install folder:"
echo Mod folder:
echo !MOD_DIR!
echo Backend folder:
echo !BACKEND_DIR!
echo.

call :SayRed "Review the notes above before continuing."
echo.

choice /C YN /N /M "Continue install? [Y/N] "

if errorlevel 2 (
    echo.
    call :SayYellow "Install cancelled."
    call :cleanup_environment
    pause
    exit /b 1
)

echo.
call :SayGreen "Beginning installation..."
echo.

set "RUNTIME_DIR=!BACKEND_DIR!\runtime"
set "SETTINGS_DIR=!BACKEND_DIR!\settings"
set "PIPER_DIR=!BACKEND_DIR!\Piper"
set "XTTS_DIR=!BACKEND_DIR!\XTTS"
set "ELEVENLABS_DIR=!BACKEND_DIR!\ElevenLabs"
set "DEPENDENCIES_DIR=!BACKEND_DIR!\dependencies"
set "MARKERS_DIR=!BACKEND_DIR!\install_markers"
set "VENV_DIR=!DEPENDENCIES_DIR!\aivoices-venv"
set "PRIVATE_FFMPEG_BIN=!DEPENDENCIES_DIR!\ffmpeg\bin"
set "FFMPEG_SHARED_BIN="
set "XTTS_CACHE_DIR=!XTTS_DIR!\cache"
set "XTTS_GENERATED_CACHE_DIR=!XTTS_CACHE_DIR!\generated_lines"

rem ==============================
rem CONTAIN AI VOICES INSTALL PATHS
rem ==============================

set "AIVOICES_CACHE_DIR=!DEPENDENCIES_DIR!\cache"
set "AIVOICES_TEMP_DIR=!DEPENDENCIES_DIR!\temp"
set "AIVOICES_PIP_CACHE_DIR=!AIVOICES_CACHE_DIR!\pip"
set "AIVOICES_PYTHONPYCACHE_DIR=!AIVOICES_CACHE_DIR!\python-pycache"
set "AIVOICES_PYTHONUSERBASE_DIR=!AIVOICES_CACHE_DIR!\python-userbase"

if not exist "!DEPENDENCIES_DIR!" mkdir "!DEPENDENCIES_DIR!"
if not exist "!AIVOICES_CACHE_DIR!" mkdir "!AIVOICES_CACHE_DIR!"

if exist "!AIVOICES_TEMP_DIR!" rmdir /s /q "!AIVOICES_TEMP_DIR!"

if not exist "!AIVOICES_TEMP_DIR!" mkdir "!AIVOICES_TEMP_DIR!"
if not exist "!AIVOICES_PYTHONPYCACHE_DIR!" mkdir "!AIVOICES_PYTHONPYCACHE_DIR!"
if not exist "!AIVOICES_PYTHONUSERBASE_DIR!" mkdir "!AIVOICES_PYTHONUSERBASE_DIR!"

rem Python/pip temp files.
set "TEMP=!AIVOICES_TEMP_DIR!"
set "TMP=!AIVOICES_TEMP_DIR!"

rem pip behavior.
set "PIP_NO_CACHE_DIR=1"
set "PIP_CONFIG_FILE=NUL"
set "PIP_DISABLE_PIP_VERSION_CHECK=1"
set "PIP_NO_INPUT=1"

rem Python cache/user files.
set "PYTHONPYCACHEPREFIX=!AIVOICES_PYTHONPYCACHE_DIR!"
set "PYTHONUSERBASE=!AIVOICES_PYTHONUSERBASE_DIR!"

call :SayYellow "Python and pip temp/cache paths are redirected into the mod folder."
echo.

echo ==============================
echo Checking Python
echo ==============================
echo.

where python >nul 2>nul
if errorlevel 1 (
    echo.
    call :SayRed "ERROR: Python was not found."
    echo.
    echo AI Voices requires Python because the background watcher is a Python script.
    echo The watcher reads Morrowind dialogue from MWSE, sends it to the selected TTS voice engine,
    echo creates the voice audio, and plays it in-game.
    echo.
    echo AI Voices does not install Python for you.
    echo.
    echo Install Python and make sure it is available as:
    echo python
    echo.
    echo Recommended:
    echo - Python 3.10, 3.11, or 3.12
    echo - 64-bit Python
    echo - Add Python to PATH enabled during install
    echo.
    call :cleanup_environment
    pause
    exit /b 1
)

set "PYTHON_VERSION="

for /f "delims=" %%P in ('python -c "import sys, platform; print(f'{sys.version_info.major}.{sys.version_info.minor}.{sys.version_info.micro} {platform.architecture()[0]}')"') do (
    set "PYTHON_VERSION=%%P"
)

python -c "import sys, platform; major, minor = sys.version_info[:2]; arch = platform.architecture()[0]; raise SystemExit(0 if major == 3 and minor >= 10 and arch == '64bit' else 1)"

if errorlevel 1 (
    echo.
    call :SayRed "ERROR: Unsupported Python version."
    echo.
    echo Detected Python: !PYTHON_VERSION!
    echo.
    echo AI Voices requires:
    echo - Python 3.10 or newer
    echo - 64-bit Python
    echo.
    echo Recommended:
    echo - Python 3.10, 3.11, or 3.12
    echo.
    call :cleanup_environment
    pause
    exit /b 1
)

python -c "import sys; major, minor = sys.version_info[:2]; raise SystemExit(0 if major == 3 and minor <= 12 else 1)"

if errorlevel 1 (
    echo.
    call :SayYellow "WARNING: This mod was tested with Python 3.10, 3.11, and 3.12."
    call :SayYellow "Detected Python: !PYTHON_VERSION!"
    call :SayYellow "This version may still work, but it is newer than the tested range."
    call :SayYellow "If errors occur during installation or runtime, Python 3.12 is recommended."
    echo.
    choice /C YN /N /M "Proceed with this Python version anyway? [Y/N] "

    if errorlevel 2 (
        echo.
        call :SayYellow "Install cancelled."
		call :cleanup_environment
        pause
        exit /b 1
    )
)

call :SayGreen "SUCCESS: Python check passed."
echo Detected Python: !PYTHON_VERSION!

echo.
echo ==============================
echo Voice Engine selection
echo ==============================
echo.

call :SayCyan "Choose which TTS voice engines to set up."
echo.
echo - You can install more than one voice engine.
echo - Only the selected voice engine is used during speech generation.
echo - Voice engine selection is done in the MCM.
echo - If the selected voice engine cannot generate speech, AI Voices will log the reason.
echo.
call :SayCyan "Package note:"
echo - ElevenLabs uses no extra pip packages.
echo - Piper installs Piper plus the ONNX runtime needed to run Piper voice models.
echo - XTTS installs PyTorch, Coqui TTS, TorchCodec, portable FFmpeg Shared, and required audio/model libraries.
echo - pip cache is disabled. Temporary pip files are kept inside the mod folder during install, then removed.
echo.

call :SayCyan "XTTS"
call :SayBlue "  Local AI voice cloning."
echo - Uses your own CPU/GPU.
echo - Uses local reference WAVs built from your installed Morrowind MP3 voice files.
echo - Generated dialogue WAVs can be cached locally and limited by size in the MCM.
echo - XTTS cache is OFF by default.
echo - If XTTS generation is slow, consider enabling cache in the MCM.
call :SayYellow " - Total local size after setup: About 7GB."
call :SayYellow " - Can be slow during runtime, especially on weaker hardware or CPU-only installs."
echo.

call :SayCyan "Piper"
echo - Local text-to-speech using .onnx voice files.
echo - Fast, local, and does not require internet during gameplay.
echo - AI Voices can download a generic sample voice for quick testing.
echo - You can provide custom Piper voices for each race/gender.
echo - The generic sample voice is usable, but not Morrowind-specific.
echo - Piper supports generation settings in the MCM: Noise Scale, Noise W, and Sentence Silence.
echo - Generated dialogue WAVs can be cached locally and limited by size in the MCM.
echo - Piper cache is OFF by default.
call :SayYellow " - Local install size with generic sample voice: About 214MB."
call :SayYellow " - Faster than XTTS, but quality depends on the .onnx voices you provide."
echo.

call :SayCyan "ElevenLabs"
echo - Online text-to-speech using your own ElevenLabs account.
echo - Small local install. Fast and high-quality.
echo - Speech generation uses ElevenLabs credits.
echo - Generated dialogue WAVs are cached by default.
echo - ElevenLabs cache is ON by default.
echo - Repeated cached lines do not make another ElevenLabs API request.
echo - ElevenLabs cache can be disabled, limited by size, or cleared in the MCM.
call :SayCyan "    ElevenLabs API key permissions:"
call :SayYellow "   - Text to Speech: Access - used to generate voice audio"
call :SayYellow "   - Voices: Read - used by this installer to list available voices (Optional)"
echo.


choice /C YN /N /M "Install XTTS local voice cloning? Large download. About 7GB. (Recommended) [Y/N] "
if errorlevel 2 (
    set "INSTALL_XTTS=NO"
) else (
    set "INSTALL_XTTS=YES"
)

choice /C YN /N /M "Install Piper local TTS support? [Y/N] "
if errorlevel 2 (
    set "INSTALL_PIPER=NO"
) else (
    set "INSTALL_PIPER=YES"
)

choice /C YN /N /M "Create ElevenLabs config files? Requires your own API key. Runtime speech uses credits. [Y/N] "
if errorlevel 2 (
    set "INSTALL_ELEVENLABS=NO"
) else (
    set "INSTALL_ELEVENLABS=YES"
)

echo.

if /I "!INSTALL_XTTS!"=="YES" (
    call :SayBlue "XTTS was selected."
    call :SayYellow "NOTICE: XTTS uses your own CPU/GPU and may be slow on older devices."
    call :SayBlue "XTTS generated-line cache can be enabled later in the MCM."
    echo.
)

if /I "!INSTALL_PIPER!"=="YES" (
    call :SayBlue "Piper was selected."
    echo - Piper can use custom race/gender .onnx voices.
    echo - Piper generation settings and cache options can be changed later in the MCM.
    echo.
)

if /I "!INSTALL_ELEVENLABS!"=="YES" (
    call :SayBlue "ElevenLabs was selected."
    call :SayYellow "NOTICE: ElevenLabs API key permissions must allow:"
    call :SayYellow "- Text to Speech: Access - used to generate voice audio"
    call :SayBlue "ElevenLabs generated-line cache is enabled by default to reduce repeated API requests."
    echo.
)

if /I not "!INSTALL_ELEVENLABS!"=="YES" if /I not "!INSTALL_PIPER!"=="YES" if /I not "!INSTALL_XTTS!"=="YES" (
    call :SayYellow "Nothing was selected. Install cancelled."
    call :cleanup_environment
    pause
    exit /b 1
)

echo.
echo ==============================
echo Creating files and folders
echo ==============================
echo.

if not exist "!BACKEND_DIR!" mkdir "!BACKEND_DIR!"
if not exist "!RUNTIME_DIR!" mkdir "!RUNTIME_DIR!"
if not exist "!SETTINGS_DIR!" mkdir "!SETTINGS_DIR!"
if not exist "!DEPENDENCIES_DIR!" mkdir "!DEPENDENCIES_DIR!"
if not exist "!MARKERS_DIR!" mkdir "!MARKERS_DIR!"

if /I "!INSTALL_PIPER!"=="YES" (
    if not exist "!PIPER_DIR!" mkdir "!PIPER_DIR!"
    if not exist "!PIPER_DIR!\voices" mkdir "!PIPER_DIR!\voices"
)

if /I "!INSTALL_XTTS!"=="YES" (
    set "AIVOICES_HF_DIR=!AIVOICES_CACHE_DIR!\huggingface"
    set "AIVOICES_TTS_DIR=!AIVOICES_CACHE_DIR!\coqui-tts"
    set "AIVOICES_TORCH_DIR=!AIVOICES_CACHE_DIR!\torch"
    set "AIVOICES_XDG_CACHE_DIR=!AIVOICES_CACHE_DIR!\xdg-cache"
    set "AIVOICES_XDG_DATA_DIR=!AIVOICES_CACHE_DIR!\xdg-data"
    set "AIVOICES_XDG_CONFIG_DIR=!AIVOICES_CACHE_DIR!\xdg-config"

    if not exist "!XTTS_DIR!" mkdir "!XTTS_DIR!"
    if not exist "!XTTS_DIR!\cache" mkdir "!XTTS_DIR!\cache"
    if not exist "!XTTS_GENERATED_CACHE_DIR!" mkdir "!XTTS_GENERATED_CACHE_DIR!"
    if not exist "!XTTS_DIR!\reference_samples" mkdir "!XTTS_DIR!\reference_samples"

    if not exist "!AIVOICES_HF_DIR!" mkdir "!AIVOICES_HF_DIR!"
    if not exist "!AIVOICES_HF_DIR!\hub" mkdir "!AIVOICES_HF_DIR!\hub"
    if not exist "!AIVOICES_HF_DIR!\xet" mkdir "!AIVOICES_HF_DIR!\xet"
    if not exist "!AIVOICES_HF_DIR!\assets" mkdir "!AIVOICES_HF_DIR!\assets"
    if not exist "!AIVOICES_TTS_DIR!" mkdir "!AIVOICES_TTS_DIR!"
    if not exist "!AIVOICES_TORCH_DIR!" mkdir "!AIVOICES_TORCH_DIR!"
    if not exist "!AIVOICES_XDG_CACHE_DIR!" mkdir "!AIVOICES_XDG_CACHE_DIR!"
    if not exist "!AIVOICES_XDG_DATA_DIR!" mkdir "!AIVOICES_XDG_DATA_DIR!"
    if not exist "!AIVOICES_XDG_CONFIG_DIR!" mkdir "!AIVOICES_XDG_CONFIG_DIR!"

    rem Hugging Face cache/model files.
    set "HF_HOME=!AIVOICES_HF_DIR!"
    set "HF_HUB_CACHE=!AIVOICES_HF_DIR!\hub"
    set "HF_XET_CACHE=!AIVOICES_HF_DIR!\xet"
    set "HF_ASSETS_CACHE=!AIVOICES_HF_DIR!\assets"
    set "HF_TOKEN_PATH=!AIVOICES_HF_DIR!\token"
    set "HUGGINGFACE_HUB_CACHE=!AIVOICES_HF_DIR!\hub"

    rem Coqui TTS model/cache files.
    set "TTS_HOME=!AIVOICES_TTS_DIR!"

    rem Torch cache files.
    set "TORCH_HOME=!AIVOICES_TORCH_DIR!"

    rem XDG-style cache/data/config files.
    set "XDG_CACHE_HOME=!AIVOICES_XDG_CACHE_DIR!"
    set "XDG_DATA_HOME=!AIVOICES_XDG_DATA_DIR!"
    set "XDG_CONFIG_HOME=!AIVOICES_XDG_CONFIG_DIR!"

    call :SayYellow "XTTS, Coqui TTS, Hugging Face, Torch, and model cache paths are redirected into the mod folder."
    echo.
)

if /I "!INSTALL_ELEVENLABS!"=="YES" (
    if not exist "!ELEVENLABS_DIR!" mkdir "!ELEVENLABS_DIR!"
)
if not exist "!RUNTIME_DIR!\dialogue.txt" type nul > "!RUNTIME_DIR!\dialogue.txt"

if not exist "!RUNTIME_DIR!\voice.txt" (
    if /I "!INSTALL_XTTS!"=="YES" (
        echo xtts:darkElfMale> "!RUNTIME_DIR!\voice.txt"
    ) else if /I "!INSTALL_ELEVENLABS!"=="YES" (
        echo elevenlabs:darkElfMale> "!RUNTIME_DIR!\voice.txt"
    ) else (
        echo piper:darkElfMale> "!RUNTIME_DIR!\voice.txt"
    )
)

if not exist "!RUNTIME_DIR!\stop.txt" type nul > "!RUNTIME_DIR!\stop.txt"
if not exist "!RUNTIME_DIR!\status.txt" type nul > "!RUNTIME_DIR!\status.txt"
if not exist "!RUNTIME_DIR!\heartbeat.txt" type nul > "!RUNTIME_DIR!\heartbeat.txt"
if not exist "!RUNTIME_DIR!\watcher_heartbeat.txt" type nul > "!RUNTIME_DIR!\watcher_heartbeat.txt"
if not exist "!SETTINGS_DIR!\voice_volume.txt" ( > "!SETTINGS_DIR!\voice_volume.txt" echo 50 )
if not exist "!SETTINGS_DIR!\speech_speed.txt" ( > "!SETTINGS_DIR!\speech_speed.txt" echo 1.00 )

if not exist "!SETTINGS_DIR!\tts_engine.txt" (
    if /I "!INSTALL_XTTS!"=="YES" (
        echo xtts> "!SETTINGS_DIR!\tts_engine.txt"
    ) else if /I "!INSTALL_ELEVENLABS!"=="YES" (
        echo elevenlabs> "!SETTINGS_DIR!\tts_engine.txt"
    ) else (
        echo piper> "!SETTINGS_DIR!\tts_engine.txt"
    )
)

if not exist "!SETTINGS_DIR!\xtts_settings.txt" (
    > "!SETTINGS_DIR!\xtts_settings.txt" echo cache_generated_lines=false
    >> "!SETTINGS_DIR!\xtts_settings.txt" echo generated_cache_max_mb=500
    >> "!SETTINGS_DIR!\xtts_settings.txt" echo temperature=0.65
    >> "!SETTINGS_DIR!\xtts_settings.txt" echo repetition_penalty=2.0
    >> "!SETTINGS_DIR!\xtts_settings.txt" echo top_k=50
    >> "!SETTINGS_DIR!\xtts_settings.txt" echo top_p=0.85
)

if not exist "!SETTINGS_DIR!\pronunciation.txt" (
    > "!SETTINGS_DIR!\pronunciation.txt" echo # AI Voices pronunciation replacements
    >> "!SETTINGS_DIR!\pronunciation.txt" echo # Format: original=replacement
    >> "!SETTINGS_DIR!\pronunciation.txt" echo # Edit this file to change how words are spoken.
    >> "!SETTINGS_DIR!\pronunciation.txt" echo.
    >> "!SETTINGS_DIR!\pronunciation.txt" echo n'wah=n wah
    >> "!SETTINGS_DIR!\pronunciation.txt" echo Vvardenfell=Vardenfell
    >> "!SETTINGS_DIR!\pronunciation.txt" echo Hlaalu=Lah loo
)

if /I "!INSTALL_PIPER!"=="YES" (
    if not exist "!PIPER_DIR!\piper_voice_map.txt" (
        > "!PIPER_DIR!\piper_voice_map.txt" echo # AI Voices Piper voice map
        >> "!PIPER_DIR!\piper_voice_map.txt" echo # Place .onnx and matching .onnx.json files in AIVoicesBackend\Piper\voices.
        >> "!PIPER_DIR!\piper_voice_map.txt" echo # Format: voiceKey=relative path from Morrowind Data Files.
        >> "!PIPER_DIR!\piper_voice_map.txt" echo.
        >> "!PIPER_DIR!\piper_voice_map.txt" echo argonianMale=
        >> "!PIPER_DIR!\piper_voice_map.txt" echo argonianFemale=
        >> "!PIPER_DIR!\piper_voice_map.txt" echo bretonMale=
        >> "!PIPER_DIR!\piper_voice_map.txt" echo bretonFemale=
        >> "!PIPER_DIR!\piper_voice_map.txt" echo darkElfMale=
        >> "!PIPER_DIR!\piper_voice_map.txt" echo darkElfFemale=
        >> "!PIPER_DIR!\piper_voice_map.txt" echo highElfMale=
        >> "!PIPER_DIR!\piper_voice_map.txt" echo highElfFemale=
        >> "!PIPER_DIR!\piper_voice_map.txt" echo imperialMale=
        >> "!PIPER_DIR!\piper_voice_map.txt" echo imperialFemale=
        >> "!PIPER_DIR!\piper_voice_map.txt" echo khajiitMale=
        >> "!PIPER_DIR!\piper_voice_map.txt" echo khajiitFemale=
        >> "!PIPER_DIR!\piper_voice_map.txt" echo nordMale=
        >> "!PIPER_DIR!\piper_voice_map.txt" echo nordFemale=
        >> "!PIPER_DIR!\piper_voice_map.txt" echo orcMale=
        >> "!PIPER_DIR!\piper_voice_map.txt" echo orcFemale=
        >> "!PIPER_DIR!\piper_voice_map.txt" echo redguardMale=
        >> "!PIPER_DIR!\piper_voice_map.txt" echo redguardFemale=
        >> "!PIPER_DIR!\piper_voice_map.txt" echo woodElfMale=
        >> "!PIPER_DIR!\piper_voice_map.txt" echo woodElfFemale=
        >> "!PIPER_DIR!\piper_voice_map.txt" echo vivec=
        >> "!PIPER_DIR!\piper_voice_map.txt" echo dagoth ur=
        >> "!PIPER_DIR!\piper_voice_map.txt" echo almalexia=
        >> "!PIPER_DIR!\piper_voice_map.txt" echo yagrum bagarn=
    )
)

if /I "!INSTALL_XTTS!"=="YES" (
    if not exist "!XTTS_DIR!\xtts_reference_map.txt" (
        > "!XTTS_DIR!\xtts_reference_map.txt" echo # AI Voices XTTS reference audio map
        >> "!XTTS_DIR!\xtts_reference_map.txt" echo # Format: voiceKey=reference audio file
        >> "!XTTS_DIR!\xtts_reference_map.txt" echo # Paths are relative to Morrowind Data Files.
        >> "!XTTS_DIR!\xtts_reference_map.txt" echo # Race/gender entries use the original installed Morrowind voice folders.
        >> "!XTTS_DIR!\xtts_reference_map.txt" echo # Special NPC entries use actor id/name keys.
        >> "!XTTS_DIR!\xtts_reference_map.txt" echo # The reference builder can replace this file with generated local WAV references.
        >> "!XTTS_DIR!\xtts_reference_map.txt" echo.
        >> "!XTTS_DIR!\xtts_reference_map.txt" echo argonianMale=Sound\Vo\a\m
        >> "!XTTS_DIR!\xtts_reference_map.txt" echo argonianFemale=Sound\Vo\a\f
        >> "!XTTS_DIR!\xtts_reference_map.txt" echo bretonMale=Sound\Vo\b\m
        >> "!XTTS_DIR!\xtts_reference_map.txt" echo bretonFemale=Sound\Vo\b\f
        >> "!XTTS_DIR!\xtts_reference_map.txt" echo darkElfMale=Sound\Vo\d\m
        >> "!XTTS_DIR!\xtts_reference_map.txt" echo darkElfFemale=Sound\Vo\d\f
        >> "!XTTS_DIR!\xtts_reference_map.txt" echo highElfMale=Sound\Vo\h\m
        >> "!XTTS_DIR!\xtts_reference_map.txt" echo highElfFemale=Sound\Vo\h\f
        >> "!XTTS_DIR!\xtts_reference_map.txt" echo imperialMale=Sound\Vo\i\m
        >> "!XTTS_DIR!\xtts_reference_map.txt" echo imperialFemale=Sound\Vo\i\f
        >> "!XTTS_DIR!\xtts_reference_map.txt" echo khajiitMale=Sound\Vo\k\m
        >> "!XTTS_DIR!\xtts_reference_map.txt" echo khajiitFemale=Sound\Vo\k\f
        >> "!XTTS_DIR!\xtts_reference_map.txt" echo nordMale=Sound\Vo\n\m
        >> "!XTTS_DIR!\xtts_reference_map.txt" echo nordFemale=Sound\Vo\n\f
        >> "!XTTS_DIR!\xtts_reference_map.txt" echo orcMale=Sound\Vo\o\m
        >> "!XTTS_DIR!\xtts_reference_map.txt" echo orcFemale=Sound\Vo\o\f
        >> "!XTTS_DIR!\xtts_reference_map.txt" echo redguardMale=Sound\Vo\r\m
        >> "!XTTS_DIR!\xtts_reference_map.txt" echo redguardFemale=Sound\Vo\r\f
        >> "!XTTS_DIR!\xtts_reference_map.txt" echo woodElfMale=Sound\Vo\w\m
        >> "!XTTS_DIR!\xtts_reference_map.txt" echo woodElfFemale=Sound\Vo\w\f
    )
)

if /I "!INSTALL_ELEVENLABS!"=="YES" (
    if not exist "!ELEVENLABS_DIR!\elevenlabs_api_key.txt" (
        > "!ELEVENLABS_DIR!\elevenlabs_api_key.txt" echo # Paste your ElevenLabs API key below this line.
        >> "!ELEVENLABS_DIR!\elevenlabs_api_key.txt" echo # Expected: an ElevenLabs API key starting with sk_.
        >> "!ELEVENLABS_DIR!\elevenlabs_api_key.txt" echo # Leave blank if you are not using ElevenLabs.
    )

    if not exist "!ELEVENLABS_DIR!\elevenlabs_voice_map.txt" (
        > "!ELEVENLABS_DIR!\elevenlabs_voice_map.txt" echo # AI Voices ElevenLabs voice map
        >> "!ELEVENLABS_DIR!\elevenlabs_voice_map.txt" echo # Paste ElevenLabs voice IDs after the equals sign.
        >> "!ELEVENLABS_DIR!\elevenlabs_voice_map.txt" echo.
        >> "!ELEVENLABS_DIR!\elevenlabs_voice_map.txt" echo argonianMale=
        >> "!ELEVENLABS_DIR!\elevenlabs_voice_map.txt" echo argonianFemale=
        >> "!ELEVENLABS_DIR!\elevenlabs_voice_map.txt" echo bretonMale=
        >> "!ELEVENLABS_DIR!\elevenlabs_voice_map.txt" echo bretonFemale=
        >> "!ELEVENLABS_DIR!\elevenlabs_voice_map.txt" echo darkElfMale=
        >> "!ELEVENLABS_DIR!\elevenlabs_voice_map.txt" echo darkElfFemale=
        >> "!ELEVENLABS_DIR!\elevenlabs_voice_map.txt" echo highElfMale=
        >> "!ELEVENLABS_DIR!\elevenlabs_voice_map.txt" echo highElfFemale=
        >> "!ELEVENLABS_DIR!\elevenlabs_voice_map.txt" echo imperialMale=
        >> "!ELEVENLABS_DIR!\elevenlabs_voice_map.txt" echo imperialFemale=
        >> "!ELEVENLABS_DIR!\elevenlabs_voice_map.txt" echo khajiitMale=
        >> "!ELEVENLABS_DIR!\elevenlabs_voice_map.txt" echo khajiitFemale=
        >> "!ELEVENLABS_DIR!\elevenlabs_voice_map.txt" echo nordMale=
        >> "!ELEVENLABS_DIR!\elevenlabs_voice_map.txt" echo nordFemale=
        >> "!ELEVENLABS_DIR!\elevenlabs_voice_map.txt" echo orcMale=
        >> "!ELEVENLABS_DIR!\elevenlabs_voice_map.txt" echo orcFemale=
        >> "!ELEVENLABS_DIR!\elevenlabs_voice_map.txt" echo redguardMale=
        >> "!ELEVENLABS_DIR!\elevenlabs_voice_map.txt" echo redguardFemale=
        >> "!ELEVENLABS_DIR!\elevenlabs_voice_map.txt" echo woodElfMale=
        >> "!ELEVENLABS_DIR!\elevenlabs_voice_map.txt" echo woodElfFemale=
    )

    if not exist "!ELEVENLABS_DIR!\elevenlabs_model_id.txt" echo eleven_multilingual_v2> "!ELEVENLABS_DIR!\elevenlabs_model_id.txt"
    if not exist "!ELEVENLABS_DIR!\elevenlabs_output_format.txt" echo wav_22050> "!ELEVENLABS_DIR!\elevenlabs_output_format.txt"

    if not exist "!ELEVENLABS_DIR!\elevenlabs_settings.txt" (
        > "!ELEVENLABS_DIR!\elevenlabs_settings.txt" echo stability=0.50
        >> "!ELEVENLABS_DIR!\elevenlabs_settings.txt" echo similarity_boost=0.75
        >> "!ELEVENLABS_DIR!\elevenlabs_settings.txt" echo style=0.00
        >> "!ELEVENLABS_DIR!\elevenlabs_settings.txt" echo use_speaker_boost=true
        >> "!ELEVENLABS_DIR!\elevenlabs_settings.txt" echo cache_generated_lines=true
        >> "!ELEVENLABS_DIR!\elevenlabs_settings.txt" echo generated_cache_max_mb=500
    )
)

call :SayGreen "SUCCESS: Files and folders ready."

echo.
echo ==============================
echo Creating local virtual environment
echo ==============================
echo.

if exist "!VENV_DIR!" (
    call :SayYellow "Existing aivoices-venv found. It will be reused."
) else (
    echo Creating !VENV_DIR!...
    python -m venv "!VENV_DIR!"

    if errorlevel 1 (
        echo.
        call :SayRed "ERROR: Failed to create virtual environment."
		call :cleanup_environment
        pause
        exit /b 1
    )
)
call :SayGreen "SUCCESS: Python virtual environment ready."
if /I "!INSTALL_PIPER!"=="YES" goto upgrade_pip_tools
if /I "!INSTALL_XTTS!"=="YES" goto upgrade_pip_tools
goto skip_upgrade_pip_tools

:upgrade_pip_tools
echo.
echo ==============================
echo Upgrading pip tools
echo ==============================
echo.

call :SayYellow "pip may be downloading, unpacking, or installing Python packages."
call :SayYellow "If the console looks quiet, the install may still be working."
echo.
call :SayYellow "This may take several minutes. Please wait..."
echo.

"!VENV_DIR!\Scripts\python.exe" -m pip install --disable-pip-version-check --no-input --no-cache-dir --prefer-binary --progress-bar on --timeout 60 --retries 2 --upgrade pip "setuptools<82" wheel

if errorlevel 1 (
    echo.
    call :SayRed "ERROR: Failed to upgrade pip/setuptools/wheel."
    call :cleanup_environment
    pause
    exit /b 1
)
echo.
call :SayGreen "SUCCESS: Python pip tools ready."
goto after_upgrade_pip_tools

:skip_upgrade_pip_tools

:after_upgrade_pip_tools

set "XTTS_INSTALLED=NO"

if /I not "!INSTALL_XTTS!"=="YES" if /I not "!INSTALL_PIPER!"=="YES" goto ffmpeg_done

	echo.
	echo ==============================
	call :SayCyan "Installing portable FFmpeg Shared"
	echo ==============================
	echo.
	call :SayYellow "FFmpeg is required by XTTS and Piper for audio processing."
	echo.
	
	rem Reuse existing bundled FFmpeg if it is already installed.
	if exist "!PRIVATE_FFMPEG_BIN!\ffmpeg.exe" if exist "!PRIVATE_FFMPEG_BIN!\ffprobe.exe" (
		set "FFMPEG_SHARED_BIN=!PRIVATE_FFMPEG_BIN!"
		call :SayGreen "Existing portable FFmpeg found. Skipping FFmpeg download."
		echo !FFMPEG_SHARED_BIN!
		goto ffmpeg_done
	)
	
	if exist "!MARKERS_DIR!\ffmpeg-download" rmdir /s /q "!MARKERS_DIR!\ffmpeg-download"
    if exist "!DEPENDENCIES_DIR!\ffmpeg" rmdir /s /q "!DEPENDENCIES_DIR!\ffmpeg"

    mkdir "!MARKERS_DIR!\ffmpeg-download"

    powershell -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference = 'Stop'; $release = Invoke-RestMethod 'https://api.github.com/repos/GyanD/codexffmpeg/releases/latest'; $asset = $release.assets | Where-Object { $_.name -like '*full_build-shared.zip' } | Select-Object -First 1; if (-not $asset) { throw 'Could not find full_build-shared.zip asset.' }; $asset.browser_download_url | Set-Content '!MARKERS_DIR!\ffmpeg-download\ffmpeg_url.txt'; $asset.name | Set-Content '!MARKERS_DIR!\ffmpeg-download\ffmpeg_name.txt'; $asset.size | Set-Content '!MARKERS_DIR!\ffmpeg-download\ffmpeg_size.txt';"

    if errorlevel 1 (
        echo.
        call :SayRed "ERROR: Failed to find latest FFmpeg Shared download."
		call :cleanup_environment
        pause
        exit /b 1
    )

    set /p FFMPEG_URL=<"!MARKERS_DIR!\ffmpeg-download\ffmpeg_url.txt"
    set /p FFMPEG_NAME=<"!MARKERS_DIR!\ffmpeg-download\ffmpeg_name.txt"
    set /p FFMPEG_SIZE=<"!MARKERS_DIR!\ffmpeg-download\ffmpeg_size.txt"

    echo Download:
    echo !FFMPEG_NAME!
    echo.
    echo Size in bytes:
    echo !FFMPEG_SIZE!
    echo.
    echo Downloading now...
    echo.

    where curl >nul 2>nul
    if errorlevel 1 (
        call :SayYellow "curl was not found. Using PowerShell download instead. This may look frozen."
        powershell -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference = 'Stop'; Invoke-WebRequest -Uri '!FFMPEG_URL!' -OutFile '!MARKERS_DIR!\ffmpeg-download\ffmpeg-shared.zip';"
    ) else (
        curl -L --progress-bar "!FFMPEG_URL!" -o "!MARKERS_DIR!\ffmpeg-download\ffmpeg-shared.zip"
    )

    if errorlevel 1 (
        echo.
        call :SayRed "ERROR: Failed to download FFmpeg Shared."
		call :cleanup_environment
        pause
        exit /b 1
    )

    call :SayGreen "SUCCESS: FFmpeg download complete."

    echo.
    echo Extracting FFmpeg Shared...
    echo.

    powershell -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference = 'Stop'; Expand-Archive -Path '!MARKERS_DIR!\ffmpeg-download\ffmpeg-shared.zip' -DestinationPath '!MARKERS_DIR!\ffmpeg-download\extracted' -Force;"

    if errorlevel 1 (
        echo.
        call :SayRed "ERROR: Failed to extract FFmpeg Shared zip."
		call :cleanup_environment
        pause
        exit /b 1
    )

    powershell -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference = 'Stop'; $bin = Get-ChildItem -Path '!MARKERS_DIR!\ffmpeg-download\extracted' -Recurse -Directory | Where-Object { $_.Name -eq 'bin' -and (Test-Path (Join-Path $_.FullName 'ffmpeg.exe')) } | Select-Object -First 1; if (-not $bin) { throw 'Could not find extracted FFmpeg bin folder.' }; New-Item -ItemType Directory -Path '!PRIVATE_FFMPEG_BIN!' -Force | Out-Null; Copy-Item -Path (Join-Path $bin.FullName '*') -Destination '!PRIVATE_FFMPEG_BIN!' -Recurse -Force; if (-not (Test-Path '!PRIVATE_FFMPEG_BIN!\ffmpeg.exe')) { throw 'Portable FFmpeg install failed.' };"

    if errorlevel 1 (
        echo.
        call :SayRed "ERROR: Failed to install portable FFmpeg Shared."
		call :cleanup_environment
        pause
        exit /b 1
    )

    rmdir /s /q "!MARKERS_DIR!\ffmpeg-download"

    set "FFMPEG_SHARED_BIN=!PRIVATE_FFMPEG_BIN!"

    echo.
    echo Checking portable FFmpeg...
    echo !FFMPEG_SHARED_BIN!

    "!PRIVATE_FFMPEG_BIN!\ffmpeg.exe" -version

    if errorlevel 1 (
        echo.
        call :SayRed "ERROR: Portable FFmpeg could not run."
		call :cleanup_environment
        pause
        exit /b 1
    )

    "!PRIVATE_FFMPEG_BIN!\ffmpeg.exe" -version | findstr /C:"--enable-shared" >nul 2>nul
    if errorlevel 1 (
        echo.
        call :SayRed "ERROR: Portable FFmpeg does not appear to be a shared build."
		call :cleanup_environment
        pause
        exit /b 1
    )
    echo.
    call :SayGreen "SUCCESS: Portable FFmpeg Shared is ready."
    echo.
:ffmpeg_done

if /I not "!INSTALL_XTTS!"=="YES" goto xtts_done

	echo.
	echo ==============================
	call :SayCyan "Installing XTTS local voice stack"
	echo ==============================
	echo.
	call :SayYellow "XTTS is the local AI voice-cloning option."
	echo.
	echo This installs:
	echo - PyTorch so XTTS can run on your GPU or CPU.
	echo - Coqui TTS / XTTS for local voice generation.
	echo - TorchCodec and support libraries needed by the voice stack.
	echo.
	call :SayYellow "This is the largest install and can take several minutes."
	call :SayYellow "If the console looks quiet, it may still be working."
	echo.
	rem ==============================
	rem DETECT CUDA VERSION
	rem ==============================

    set "HAS_NVIDIA=NO"
    set "CUDA_MAJOR=0"
    set "CUDA_MINOR=0"
    set "TORCH_INDEX_URL=https://download.pytorch.org/whl/cpu"
    set "TORCH_VARIANT=CPU only"

    where nvidia-smi >nul 2>nul
    if not errorlevel 1 (
        nvidia-smi >nul 2>nul
        if not errorlevel 1 (
            set "HAS_NVIDIA=YES"
        )
    )

    if /I "!HAS_NVIDIA!"=="YES" (
        rem Parse CUDA version from nvidia-smi output.
        rem nvidia-smi prints a line like: | CUDA Version: 12.6 |
        for /f "tokens=*" %%A in ('nvidia-smi 2^>nul ^| findstr /C:"CUDA Version"') do (
            set "NVIDIA_SMI_LINE=%%A"
        )

        for /f "tokens=3 delims=: " %%A in ("!NVIDIA_SMI_LINE!") do (
            for /f "tokens=1,2 delims=." %%B in ("%%A") do (
                set "CUDA_MAJOR=%%B"
                set "CUDA_MINOR=%%C"
            )
        )

        rem Map CUDA version to the highest supported PyTorch build.
        rem Each condition overwrites the previous so the last true condition wins.
        rem PyTorch index URLs last verified: June 2026.
        rem Check https://pytorch.org/get-started/locally/ before updating this mod.
        rem
        rem Note: cu118 is the lowest available build. CUDA 11.x users will fall
        rem through to CPU since PyTorch no longer publishes cu117 or lower.

        if !CUDA_MAJOR! GEQ 12 (
            set "TORCH_INDEX_URL=https://download.pytorch.org/whl/cu118"
            set "TORCH_VARIANT=CUDA 12.0+ (cu118 compat build)"
        )
        if !CUDA_MAJOR! GEQ 12 if !CUDA_MINOR! GEQ 1 (
            set "TORCH_INDEX_URL=https://download.pytorch.org/whl/cu121"
            set "TORCH_VARIANT=CUDA 12.1"
        )
        if !CUDA_MAJOR! GEQ 12 if !CUDA_MINOR! GEQ 4 (
            set "TORCH_INDEX_URL=https://download.pytorch.org/whl/cu124"
            set "TORCH_VARIANT=CUDA 12.4"
        )
        if !CUDA_MAJOR! GEQ 12 if !CUDA_MINOR! GEQ 6 (
            set "TORCH_INDEX_URL=https://download.pytorch.org/whl/cu126"
            set "TORCH_VARIANT=CUDA 12.6"
        )
        if !CUDA_MAJOR! GEQ 12 if !CUDA_MINOR! GEQ 8 (
            set "TORCH_INDEX_URL=https://download.pytorch.org/whl/cu128"
            set "TORCH_VARIANT=CUDA 12.8"
        )
    )

    rem ==============================
    rem INSTALL PYTORCH
    rem ==============================

    call :SayCyan "Checking PyTorch install type"
    echo.

    if /I "!HAS_NVIDIA!"=="YES" (
        call :SayGreen "NVIDIA GPU detected."
        call :SayBlue "Detected CUDA version: !CUDA_MAJOR!.!CUDA_MINOR!"
        call :SayBlue "Selected PyTorch build: !TORCH_VARIANT!"

        if "!TORCH_VARIANT!"=="CPU only" (
            call :SayYellow "WARNING: NVIDIA GPU found but CUDA version could not be determined."
            call :SayYellow "Falling back to CPU-only PyTorch. XTTS will work but may be slow."
        )
    ) else (
        call :SayRed "No NVIDIA GPU detected."
        call :SayBlue "Selected PyTorch build: !TORCH_VARIANT!"
        call :SayYellow "XTTS should still work on CPU, but it may be slow."
    )
    echo.

    if /I "!HAS_NVIDIA!"=="YES" (
        "!VENV_DIR!\Scripts\python.exe" -m pip install --disable-pip-version-check --no-input --no-cache-dir --prefer-binary --progress-bar on --timeout 60 --retries 2 --index-url !TORCH_INDEX_URL! torch torchaudio
    ) else (
        "!VENV_DIR!\Scripts\python.exe" -m pip install --disable-pip-version-check --no-input --no-cache-dir --prefer-binary --progress-bar on --timeout 60 --retries 2 --index-url https://download.pytorch.org/whl/cpu torch torchaudio
    )

    if errorlevel 1 (
        echo.
        call :SayRed "ERROR: PyTorch install failed."
		call :cleanup_environment
        pause
        exit /b 1
    )

    echo.
    call :SayGreen "SUCCESS: PyTorch installed. Build: !TORCH_VARIANT!"
	
	echo.
	call :SayCyan "Checking installed PyTorch CUDA status..."
	echo.

	"!VENV_DIR!\Scripts\python.exe" -c "import torch; print('XTTS PyTorch backend: ' + ('CUDA / GPU' if torch.cuda.is_available() else 'CPU only')); print('PyTorch version: ' + torch.__version__); print('CUDA build: ' + str(torch.version.cuda)); print('CUDA available: ' + str(torch.cuda.is_available())); print('GPU: ' + (torch.cuda.get_device_name(0) if torch.cuda.is_available() else 'None'))"

	if not exist "!MARKERS_DIR!" mkdir "!MARKERS_DIR!"

    echo.
    call :SayCyan "Installing Coqui TTS and XTTS"
    echo.

    call :SayYellow "If the console looks quiet, pip may still be downloading or unpacking."
    call :SayYellow "This may take several minutes. Please wait..."
    echo.
    
    rem transformers pinned to 4.x - Coqui TTS compatibility with 5.x is untested
    "!VENV_DIR!\Scripts\python.exe" -m pip install --disable-pip-version-check --no-input --no-cache-dir --prefer-binary --progress-bar on --timeout 60 --retries 2 "coqui-tts[codec]" "transformers>=4.57,<5"

    if errorlevel 1 (
        echo.
        call :SayRed "ERROR: Coqui TTS install failed."
		call :cleanup_environment
        pause
        exit /b 1
    )
    echo.
    call :SayCyan "Starting Coqui TTS and loading the XTTS-v2 model."
    echo.
    call :SayYellow "Model page:"
    echo https://huggingface.co/coqui/XTTS-v2
    call :SayYellow "License file:"
    echo https://huggingface.co/coqui/XTTS-v2/blob/main/LICENSE.txt
    echo.
    call :SayYellow "Read the license prompt carefully."
    call :SayYellow "If you accept the XTTS-v2 license, type y when Coqui TTS asks."
    echo.
    echo The console may appear to pause before showing the license prompt.
    echo This can happen while Python, PyTorch, TorchCodec, and Coqui TTS initialize.
    call :SayYellow "This can take a long time. Please wait..."
    echo.
	if exist "!MARKERS_DIR!\xtts_license_accepted_by_user.txt" (
		call :SayYellow "Existing XTTS license/model marker found. XTTS may not show the license prompt again."
	)
    set "COQUI_TOS_AGREED="
    set "PATH=!FFMPEG_SHARED_BIN!;!PATH!"
    
    "!VENV_DIR!\Scripts\python.exe" -c "from TTS.api import TTS; import torch; import torchcodec; print('TTS import OK'); print('Torch:', torch.__version__); print('CUDA available:', torch.cuda.is_available()); print('GPU:', torch.cuda.get_device_name(0) if torch.cuda.is_available() else 'CPU'); print('Loading XTTS model now...'); TTS('tts_models/multilingual/multi-dataset/xtts_v2'); print('XTTS model load OK')"

    if errorlevel 1 (
        echo.
		call :SayRed "ERROR: XTTS model check failed."
		echo.
		echo This can happen if:
		echo - The Coqui/XTTS license prompt was not accepted
		echo - The XTTS model download was interrupted
		echo - Hugging Face, your internet connection, VPN, firewall, or antivirus interrupted the download
		echo.
		echo XTTS was installed, but the model did not finish downloading or loading.
		echo.
		echo You can usually fix this by running the installer again.
		echo.
		echo If it fails repeatedly, delete this folder and try again:
		echo !AIVOICES_TTS_DIR!\tts\tts_models--multilingual--multi-dataset--xtts_v2
		echo.
        echo.
		call :cleanup_environment
        pause
        exit /b 1
    )

	> "!MARKERS_DIR!\xtts_license_accepted_by_user.txt" echo XTTS model loaded successfully during install.
	>> "!MARKERS_DIR!\xtts_license_accepted_by_user.txt" echo If no license prompt appeared, XTTS was likely already accepted or cached from a previous install.

    set "XTTS_INSTALLED=YES"

    call :SayGreen "SUCCESS: XTTS model check complete."

:xtts_done

if /I not "!XTTS_INSTALLED!"=="YES" goto reference_samples_done
echo.
call :SayCyan "Building reference samples"
echo.
call :SayYellow "This may take a few minutes..."
echo.

rem ==============================
rem BUILD REFERENCE SAMPLES
rem ==============================
rem In V1.01a, This section has been rewritten to use build_reference_samples.py. Instead of generating a .ps1 file to create reference samples. The build_reference_samples.py file is now included in the download, and can be run independently of this installer.

set "REFERENCE_BUILDER=!BACKEND_DIR!\build_reference_samples.py"

if not exist "!REFERENCE_BUILDER!" (
    call :SayRed "ERROR: build_reference_samples.py was not found."
    call :cleanup_environment
    pause
    exit /b 1
)

"!VENV_DIR!\Scripts\python.exe" "!REFERENCE_BUILDER!" --installer --data-files "!DATA_FILES_DIR!" --ffmpeg-bin "!FFMPEG_SHARED_BIN!"

if errorlevel 1 (
    echo.
    call :SayRed "ERROR: Failed to build local reference samples."
    echo.
    echo The install can continue, but XTTS needs valid entries in xtts_reference_map.txt to speak.
    echo.
    pause
)


echo.
call :SayYellow "IMPORTANT: Do not redistribute the generated reference_samples folder."
call :SayGreen "XTTS Voice Engine installation complete."
echo.
:reference_samples_done

if /I not "!INSTALL_PIPER!"=="YES" goto after_piper_install

    echo.
    echo ==============================
    call :SayCyan "Installing Piper"
    echo ==============================
    echo.

    call :SayYellow "pip may be downloading, unpacking, or installing Python packages."
    call :SayYellow "If the console looks quiet, the install may still be working."
    echo.
    call :SayYellow "This may take several minutes. Please wait..."
        echo.

    "!VENV_DIR!\Scripts\python.exe" -m pip install --disable-pip-version-check --no-input --no-cache-dir --prefer-binary --progress-bar on --timeout 60 --retries 2 piper-tts

    if errorlevel 1 (
        echo.
        call :SayRed "ERROR: Piper install failed."
		call :cleanup_environment
        pause
        exit /b 1
    )
    if not exist "!PIPER_DIR!\piper_settings.txt" (
        > "!PIPER_DIR!\piper_settings.txt" echo cache_generated_lines=false
        >> "!PIPER_DIR!\piper_settings.txt" echo generated_cache_max_mb=500
        >> "!PIPER_DIR!\piper_settings.txt" echo noise_scale=0.667
        >> "!PIPER_DIR!\piper_settings.txt" echo noise_w=0.333
        >> "!PIPER_DIR!\piper_settings.txt" echo sentence_silence=0.20
    )
    call :SayGreen "Piper Voice Engine installation complete."

    echo.
    echo ==============================
    call :SayCyan "Piper voices"
    echo ==============================
    echo.

	rem Skip generic Kristin download prompt if any valid Piper voice already exists.
	set "PIPER_EXISTING_VOICE_MODEL="

	for %%F in ("!PIPER_DIR!\voices\*.onnx") do (
		if exist "%%~fF.json" (
			set "PIPER_EXISTING_VOICE_MODEL=%%~fF"
			goto piper_existing_voice_found
		)
	)

	goto piper_no_existing_voice_found

	:piper_existing_voice_found
	echo.
	call :SayGreen "Existing Piper voice found:"
	echo !PIPER_EXISTING_VOICE_MODEL!
	goto after_piper_install

	:piper_no_existing_voice_found

    call :SayYellow "Piper needs at least one .onnx voice file before it can speak."
    echo.
    echo Piper is a local TTS engine.
    echo You can use Piper by providing .onnx voice files and matching .onnx.json files.
    echo.
    echo You can provide Piper voices for each race/gender here:
    echo !PIPER_DIR!\voices
    echo.
    echo Piper voice assignments are managed here:
    echo !PIPER_DIR!\piper_voice_map.txt
    echo.

    call :SayYellow "AI Voices can optionally download the free en_US-kristin-medium Piper voice from the official rhasspy/piper-voices repository."
    echo.

    echo  - This gives Piper a usable generic voice immediately.
    echo  - The downloaded Kristin voice is generic.
    echo  - It is not Morrowind-specific, lore-friendly, or intended to match any race, gender, or character.
    echo  - The installer assigns this voice to darkElfMale for quick testing.
    call :SayYellow " - To use Piper properly, add your own .onnx voices and update the Piper voice map."
    echo.

    choice /C YN /N /M "Download generic Piper voice? [Y/N] "

    if not errorlevel 2 (
        echo.
        call :SayYellow "Downloading generic Piper rhasspy/piper-voices/en/en_US/kristin/medium sample voice..."

        set "PIPER_SAMPLE_ONNX_URL=https://huggingface.co/rhasspy/piper-voices/resolve/main/en/en_US/kristin/medium/en_US-kristin-medium.onnx"
        set "PIPER_SAMPLE_JSON_URL=https://huggingface.co/rhasspy/piper-voices/resolve/main/en/en_US/kristin/medium/en_US-kristin-medium.onnx.json"
        set "PIPER_SAMPLE_ONNX=!PIPER_DIR!\voices\en_US-kristin-medium.onnx"
        set "PIPER_SAMPLE_JSON=!PIPER_DIR!\voices\en_US-kristin-medium.onnx.json"

		where curl >nul 2>nul
        if errorlevel 1 (
            call :SayYellow "NOTICE: curl was not found. Using PowerShell download instead. This may look frozen."
            powershell -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop'; Invoke-WebRequest -Uri $env:PIPER_SAMPLE_ONNX_URL -OutFile $env:PIPER_SAMPLE_ONNX; Invoke-WebRequest -Uri $env:PIPER_SAMPLE_JSON_URL -OutFile $env:PIPER_SAMPLE_JSON;"
        ) else (
            curl -L --progress-bar --ssl-no-revoke "!PIPER_SAMPLE_ONNX_URL!" -o "!PIPER_SAMPLE_ONNX!"
            if not errorlevel 1 (
                curl -L --progress-bar --ssl-no-revoke "!PIPER_SAMPLE_JSON_URL!" -o "!PIPER_SAMPLE_JSON!"
            )
        )

        if errorlevel 1 (
            echo.
            call :SayRed "Failed to download the en_US-kristin-medium Piper sample voice."
            echo.
            pause
        ) else if not exist "!PIPER_SAMPLE_ONNX!" (
            echo.
            call :SayRed "en_US-kristin-medium.onnx was not created."
            echo.
            pause
        ) else if not exist "!PIPER_SAMPLE_JSON!" (
            echo.
            call :SayRed "en_US-kristin-medium.onnx.json was not created."
            echo.
            pause
        ) else (
            > "!PIPER_DIR!\voices\en_US-kristin-medium_SOURCE.txt" echo AI Voices downloaded this generic sample Piper voice.
            >> "!PIPER_DIR!\voices\en_US-kristin-medium_SOURCE.txt" echo.
            >> "!PIPER_DIR!\voices\en_US-kristin-medium_SOURCE.txt" echo Repository: rhasspy/piper-voices
            >> "!PIPER_DIR!\voices\en_US-kristin-medium_SOURCE.txt" echo Voice: en_US-kristin-medium
            >> "!PIPER_DIR!\voices\en_US-kristin-medium_SOURCE.txt" echo Source: Hugging Face rhasspy/piper-voices
            >> "!PIPER_DIR!\voices\en_US-kristin-medium_SOURCE.txt" echo ONNX URL: !PIPER_SAMPLE_ONNX_URL!
            >> "!PIPER_DIR!\voices\en_US-kristin-medium_SOURCE.txt" echo JSON URL: !PIPER_SAMPLE_JSON_URL!
            >> "!PIPER_DIR!\voices\en_US-kristin-medium_SOURCE.txt" echo Repository license shown by Hugging Face: MIT
            >> "!PIPER_DIR!\voices\en_US-kristin-medium_SOURCE.txt" echo Dataset source listed by model card: LibriVox
            >> "!PIPER_DIR!\voices\en_US-kristin-medium_SOURCE.txt" echo Dataset license listed by model card: public domain
            >> "!PIPER_DIR!\voices\en_US-kristin-medium_SOURCE.txt" echo.
            >> "!PIPER_DIR!\voices\en_US-kristin-medium_SOURCE.txt" echo AI Voices downloaded this voice directly from the official source into the user's local install.
            >> "!PIPER_DIR!\voices\en_US-kristin-medium_SOURCE.txt" echo AI Voices does not bundle, reupload, or redistribute this voice.
            >> "!PIPER_DIR!\voices\en_US-kristin-medium_SOURCE.txt" echo.
            >> "!PIPER_DIR!\voices\en_US-kristin-medium_SOURCE.txt" echo Note: This is a generic sample voice. It is not Morrowind-specific, not lore-friendly, and not intended to match any race, gender, or character.

            > "!MARKERS_DIR!\piper_sample_downloaded_by_aivoices.txt" echo AI Voices downloaded the generic Piper sample voice.
            >> "!MARKERS_DIR!\piper_sample_downloaded_by_aivoices.txt" echo Voice: en_US-kristin-medium
            >> "!MARKERS_DIR!\piper_sample_downloaded_by_aivoices.txt" echo Files: AIVoicesBackend\Piper\voices\en_US-kristin-medium.onnx and AIVoicesBackend\Piper\voices\en_US-kristin-medium.onnx.json
            powershell -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop'; $path='!PIPER_DIR!\piper_voice_map.txt'; $text=Get-Content -Path $path -Raw; $text=$text -replace '(?m)^darkElfMale=.*$', 'darkElfMale=AIVoicesBackend\Piper\voices\en_US-kristin-medium.onnx'; Set-Content -Path $path -Value $text -Encoding UTF8;"
            call :SayGreen "SUCCESS: Generic Piper sample voice downloaded."
        )
    ) else (
        echo Generic Piper sample voice download skipped.
        call :SayYellow "Piper was installed, but it will not speak until a .onnx and .onnx.json file exist."
    )
:after_piper_install


if /I "!INSTALL_ELEVENLABS!"=="YES" (
    echo.
    echo ==============================
    call :SayCyan "ElevenLabs API key"
    echo ==============================
    echo.
    call :SayYellow "NOTICE: You can paste your ElevenLabs API key now, or leave this blank and add it later."
    echo.
    set /p ELEVEN_KEY="Paste ElevenLabs API key now, or press Enter to skip: "

    if not "!ELEVEN_KEY!"=="" (
        > "!ELEVENLABS_DIR!\elevenlabs_api_key.txt" echo !ELEVEN_KEY!
        call :SayGreen "SUCCESS: API key written to elevenlabs_api_key.txt."
        call :SayRed "Do not share this key with anyone."
    ) else (
        call :SayYellow "NOTICE: No API key entered. You can add it later."
    )
)
echo.
echo.
echo ==============================
call :SayCyan "SUMMARY"
echo ==============================
echo.

> "!MARKERS_DIR!\aivoices_installed.txt" echo AI Voices local environment installed.
>> "!MARKERS_DIR!\aivoices_installed.txt" echo AI Voices version: !AIVOICES_INSTALLER_VERSION!
>> "!MARKERS_DIR!\aivoices_installed.txt" echo Installer completed: %DATE% %TIME%
>> "!MARKERS_DIR!\aivoices_installed.txt" echo Python command: Data Files\AIVoicesBackend\dependencies\aivoices-venv\Scripts\python.exe
>> "!MARKERS_DIR!\aivoices_installed.txt" echo Installed folder: !VENV_DIR!
>> "!MARKERS_DIR!\aivoices_installed.txt" echo Piper requested: !INSTALL_PIPER!
>> "!MARKERS_DIR!\aivoices_installed.txt" echo XTTS requested: !INSTALL_XTTS!
>> "!MARKERS_DIR!\aivoices_installed.txt" echo XTTS installed: !XTTS_INSTALLED!
>> "!MARKERS_DIR!\aivoices_installed.txt" echo ElevenLabs config requested: !INSTALL_ELEVENLABS!

if /I "!INSTALL_XTTS!"=="YES" (
    >> "!MARKERS_DIR!\aivoices_installed.txt" echo.
    >> "!MARKERS_DIR!\aivoices_installed.txt" echo XTTS PyTorch install selection:
    >> "!MARKERS_DIR!\aivoices_installed.txt" echo Detected NVIDIA GPU: !HAS_NVIDIA!
    >> "!MARKERS_DIR!\aivoices_installed.txt" echo Detected CUDA version: !CUDA_MAJOR!.!CUDA_MINOR!
    >> "!MARKERS_DIR!\aivoices_installed.txt" echo Selected PyTorch build: !TORCH_VARIANT!
    >> "!MARKERS_DIR!\aivoices_installed.txt" echo Selected PyTorch index URL: !TORCH_INDEX_URL!
    >> "!MARKERS_DIR!\aivoices_installed.txt" echo.
    >> "!MARKERS_DIR!\aivoices_installed.txt" echo Installed PyTorch CUDA status:
    "!VENV_DIR!\Scripts\python.exe" -c "import torch; print('XTTS PyTorch backend: ' + ('CUDA / GPU' if torch.cuda.is_available() else 'CPU only')); print('PyTorch version: ' + torch.__version__); print('CUDA build: ' + str(torch.version.cuda)); print('CUDA available: ' + str(torch.cuda.is_available())); print('GPU: ' + (torch.cuda.get_device_name(0) if torch.cuda.is_available() else 'None'))" >> "!MARKERS_DIR!\aivoices_installed.txt" 2>&1
)

set "INSTALL_COMPLETE_WAV=!RUNTIME_DIR!\install_complete.wav"
set "INSTALL_COMPLETE_TEXT=AI Voices Piper installation complete."

if /I not "!XTTS_INSTALLED!"=="YES" goto after_xtts_summary

    echo ==============================
    call :SayCyan "XTTS completion"
    echo ==============================
    echo.
    >> "!MARKERS_DIR!\aivoices_installed.txt" echo Portable FFmpeg bin: !FFMPEG_SHARED_BIN!
    if not exist "!XTTS_DIR!\xtts_reference_map.txt" (
        call :SayRed "WARNING: XTTS reference map was not found."
    )

    if not exist "!MARKERS_DIR!\reference_samples_built_by_aivoices.txt" (
        call :SayYellow "Local XTTS reference samples were not built."
        echo XTTS will use whatever paths are listed in:
        echo !XTTS_DIR!\xtts_reference_map.txt
        echo.
    )
    
    call :SayGreen "SUCCESS: XTTS setup complete."
    if not exist "!XTTS_DIR!\reference_samples\darkElfMale.wav" goto xtts_summary_sound_test_skipped

    call :SayYellow "Creating XTTS voice line. This may take a moment."
    set "XTTS_TEST_START=%TIME%"

    if exist "!INSTALL_COMPLETE_WAV!" del /q "!INSTALL_COMPLETE_WAV!" >nul 2>nul

    "!VENV_DIR!\Scripts\python.exe" -c "from pathlib import Path; from TTS.api import TTS; import torch; backend=Path(r'!BACKEND_DIR!'); out=backend / 'runtime' / 'install_complete.wav'; ref=backend / 'XTTS' / 'reference_samples' / 'darkElfMale.wav'; device='cuda' if torch.cuda.is_available() else 'cpu'; print('Using device:', device); tts=TTS('tts_models/multilingual/multi-dataset/xtts_v2').to(device); tts.tts_to_file(text='A.I. Voices X.T.T.S. install complete.', speaker_wav=str(ref), language='en', file_path=str(out)); print(out)"

    set "XTTS_TEST_END=%TIME%"

    for /f %%A in ('powershell -NoProfile -Command "$s=[TimeSpan]::Parse('%XTTS_TEST_START%'); $e=[TimeSpan]::Parse('%XTTS_TEST_END%'); if($e -lt $s){$e=$e.Add([TimeSpan]::FromDays(1))}; [int]($e-$s).TotalSeconds"') do set "XTTS_TEST_SECONDS=%%A"

    call :SayYellow "XTTS install voice test took !XTTS_TEST_SECONDS! seconds."

    if !XTTS_TEST_SECONDS! LSS 20 (
        call :SayBlue "XTTS performance: Good. Speech should be reasonable."
    ) else if !XTTS_TEST_SECONDS! LSS 40 (
        call :SayYellow "XTTS performance: Usable. First-time lines may take a while."
    ) else if !XTTS_TEST_SECONDS! LSS 60 (
        call :SayRed "XTTS performance warning: Slow. Uncached XTTS dialogue may feel delayed in-game."
    ) else (
        call :SayRed "XTTS performance warning: Very slow. Consider Piper or ElevenLabs for a better in-game experience."
    )

    if not exist "!INSTALL_COMPLETE_WAV!" goto xtts_summary_voice_line_missing
    echo.
    call :SayRed "SOUND WARNING -- Press any key to test XTTS voice line. -- SOUND WARNING"
    pause >nul
    

    if exist "!INSTALL_COMPLETE_WAV!" (
        "!PRIVATE_FFMPEG_BIN!\ffmpeg.exe" -y -hide_banner -loglevel error -i "!INSTALL_COMPLETE_WAV!" -filter:a "volume=0.5" "!INSTALL_COMPLETE_WAV!_vol.wav"
        move /y "!INSTALL_COMPLETE_WAV!_vol.wav" "!INSTALL_COMPLETE_WAV!" >nul
        "!VENV_DIR!\Scripts\python.exe" -c "import winsound; winsound.PlaySound(r'!INSTALL_COMPLETE_WAV!', winsound.SND_FILENAME)"
    ) else (
        call :SayYellow "WARNING: XTTS test WAV was not found, skipping sound playback."
        echo Expected:
        echo !INSTALL_COMPLETE_WAV!
    )

    goto after_xtts_summary_sound_test

:xtts_summary_voice_line_missing
    call :SayRed "WARNING: XTTS voice line was not created."
    goto after_xtts_summary_sound_test

:xtts_summary_sound_test_skipped
    call :SayYellow "XTTS sound test skipped because darkElfMale reference sample was not found."
    call :SayYellow "XTTS can still work if xtts_reference_map.txt points to valid audio."

:after_xtts_summary_sound_test
:after_xtts_summary

if /I not "!INSTALL_PIPER!"=="YES" goto after_piper_summary

    echo ==============================
    call :SayCyan "Piper completion"
    echo ==============================
    echo.

    if not exist "!VENV_DIR!\Scripts\piper.exe" (
        call :SayRed "WARNING: Piper executable was not found."
    )

    if not exist "!PIPER_DIR!\piper_voice_map.txt" (
        call :SayRed "WARNING: Piper voice map was not found."
    )
	rem Find any Piper .onnx voice with a matching .onnx.json file.
	set "PIPER_TEST_MODEL="

	for %%F in ("!PIPER_DIR!\voices\*.onnx") do (
		if exist "%%~fF.json" (
			set "PIPER_TEST_MODEL=%%~fF"
			goto piper_sample_voice_present
		)
	)

	call :SayYellow "No Piper voices were found."
	call :SayYellow "Piper needs assigned .onnx and matching .onnx.json files before it can speak."
	echo.
	goto piper_summary_sound_test_skipped

	if not exist "!VENV_DIR!\Scripts\piper.exe" goto piper_summary_sound_test_skipped
	if not defined PIPER_TEST_MODEL goto piper_summary_sound_test_skipped

    call :SayYellow "No Piper voices were found."
    call :SayYellow "Piper needs assigned .onnx and .onnx.json files before it can speak."
    echo.

:piper_sample_voice_present

    if not exist "!VENV_DIR!\Scripts\piper.exe" goto piper_summary_sound_test_skipped
    if not exist "!PIPER_DIR!\voices\en_US-kristin-medium.onnx" goto piper_summary_sound_test_skipped
    if not exist "!PIPER_DIR!\voices\en_US-kristin-medium.onnx.json" goto piper_summary_sound_test_skipped

    call :SayYellow "Creating Piper voice line."
    set "PIPER_TEST_START=%TIME%"

    if exist "!INSTALL_COMPLETE_WAV!" del /q "!INSTALL_COMPLETE_WAV!" >nul 2>nul

    echo !INSTALL_COMPLETE_TEXT! | "!VENV_DIR!\Scripts\piper.exe" -m "!PIPER_TEST_MODEL!" -f "!INSTALL_COMPLETE_WAV!"

    set "PIPER_TEST_END=%TIME%"

    for /f %%A in ('powershell -NoProfile -Command "$s=[TimeSpan]::Parse('%PIPER_TEST_START%'); $e=[TimeSpan]::Parse('%PIPER_TEST_END%'); if($e -lt $s){$e=$e.Add([TimeSpan]::FromDays(1))}; [math]::Round(($e-$s).TotalSeconds, 1)"') do set "PIPER_TEST_SECONDS=%%A"

    call :SayYellow "Piper install voice test took !PIPER_TEST_SECONDS! seconds."

    powershell -NoProfile -Command "if ([double]'!PIPER_TEST_SECONDS!' -lt 2) { exit 0 } elseif ([double]'!PIPER_TEST_SECONDS!' -lt 5) { exit 1 } else { exit 2 }"

    if !ERRORLEVEL! EQU 0 (
        call :SayCyan "Piper performance: Good."
    ) else if !ERRORLEVEL! EQU 1 (
        call :SayYellow "Piper performance: Usable, but slower than expected."
    ) else (
        call :SayRed "Piper performance warning: Slow. Something may be wrong with the Piper setup or system performance."
    )

    if not exist "!INSTALL_COMPLETE_WAV!" goto piper_summary_voice_line_missing

    call :SayGreen "SUCCESS: Piper voice line created."
    echo.
    call :SayRed "SOUND WARNING -- Press any key to test Piper voice line. -- SOUND WARNING"
    pause >nul

    if exist "!INSTALL_COMPLETE_WAV!" (
        "!PRIVATE_FFMPEG_BIN!\ffmpeg.exe" -y -hide_banner -loglevel error -i "!INSTALL_COMPLETE_WAV!" -filter:a "volume=0.5" "!INSTALL_COMPLETE_WAV!_vol.wav"
        move /y "!INSTALL_COMPLETE_WAV!_vol.wav" "!INSTALL_COMPLETE_WAV!" >nul
        "!VENV_DIR!\Scripts\python.exe" -c "import winsound; winsound.PlaySound(r'!INSTALL_COMPLETE_WAV!', winsound.SND_FILENAME)"
    ) else (
        call :SayYellow "WARNING: Piper test WAV was not found, skipping sound playback."
        echo Expected:
        echo !INSTALL_COMPLETE_WAV!
    )

    goto after_piper_summary_sound_test

:piper_summary_voice_line_missing
    call :SayRed "WARNING: Piper voice line was not created."
    goto after_piper_summary_sound_test

:piper_summary_sound_test_skipped
    call :SayYellow "NOTICE: Piper sound test skipped because piper.exe or a valid .onnx/.onnx.json voice pair was missing."

:after_piper_summary_sound_test
    call :SayGreen "SUCCESS: Piper setup complete."
:after_piper_summary

if /I not "!INSTALL_ELEVENLABS!"=="YES" goto after_elevenlabs_completion

echo ==============================
call :SayCyan "ElevenLabs completion"
echo ==============================
echo.

set "ELEVENLABS_API_KEY="
set "ELEVENLABS_CAN_CHECK_API=NO"
set "ELEVENLABS_KEY_READ_FILE=!ELEVENLABS_DIR!\aivoices_elevenlabs_key_read.txt"
set "ELEVENLABS_JSON_FILE=!ELEVENLABS_DIR!\aivoices_elevenlabs_voices.json"
set "ELEVENLABS_LIST_FILE=!ELEVENLABS_DIR!\aivoices_elevenlabs_availablevoices.txt"
set "ELEVENLABS_COUNT_FILE=!ELEVENLABS_DIR!\aivoices_elevenlabs_voice_count.txt"
set "ELEVENLABS_STATUS_FILE=!ELEVENLABS_DIR!\aivoices_elevenlabs_status.txt"

if exist "!ELEVENLABS_KEY_READ_FILE!" del "!ELEVENLABS_KEY_READ_FILE!" >nul 2>nul

if exist "!ELEVENLABS_DIR!\elevenlabs_api_key.txt" goto elevenlabs_read_key_file

call :SayYellow "NOTICE: ElevenLabs API key file was not found."
call :SayYellow "Add your API key here:"
echo !ELEVENLABS_DIR!\elevenlabs_api_key.txt
goto elevenlabs_after_key_check

:elevenlabs_read_key_file
powershell -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop'; $path='!ELEVENLABS_DIR!\elevenlabs_api_key.txt'; $out='!ELEVENLABS_KEY_READ_FILE!'; $line=Get-Content -LiteralPath $path | ForEach-Object { $_.Trim() } | Where-Object { $_ -and -not $_.StartsWith('#') } | Select-Object -First 1; if (-not $line) { exit 3 }; Set-Content -LiteralPath $out -Value $line -NoNewline -Encoding ASCII"

if errorlevel 3 goto elevenlabs_key_empty
if errorlevel 1 goto elevenlabs_key_read_error

set /p ELEVENLABS_API_KEY=<"!ELEVENLABS_KEY_READ_FILE!"
del "!ELEVENLABS_KEY_READ_FILE!" >nul 2>nul

if "!ELEVENLABS_API_KEY!"=="" goto elevenlabs_key_empty
if /I "!ELEVENLABS_API_KEY:~0,3!"=="sk_" goto elevenlabs_key_valid
goto elevenlabs_key_bad_structure

:elevenlabs_key_empty
call :SayYellow "NOTICE: ElevenLabs API key file is empty."
call :SayYellow "Add your API key here:"
echo !ELEVENLABS_DIR!\elevenlabs_api_key.txt
goto elevenlabs_after_key_check

:elevenlabs_key_read_error
call :SayRed "WARNING: ElevenLabs API key could not be read."
call :SayRed "Check this file:"
echo !ELEVENLABS_DIR!\elevenlabs_api_key.txt
goto elevenlabs_after_key_check

:elevenlabs_key_bad_structure
call :SayRed "WARNING: ElevenLabs API key does not look correctly structured."
call :SayRed "Expected the first non-comment line to start with sk_."
call :SayRed "Put your ElevenLabs API key in this file:"
echo !ELEVENLABS_DIR!\elevenlabs_api_key.txt
echo.

set "ELEVENLABS_API_KEY="
set /p ELEVENLABS_API_KEY=Paste ElevenLabs API key now, or press Enter to skip: 

if "!ELEVENLABS_API_KEY!"=="" goto elevenlabs_key_prompt_skipped
if /I "!ELEVENLABS_API_KEY:~0,3!"=="sk_" goto elevenlabs_key_prompt_valid

call :SayRed "WARNING: Entered ElevenLabs API key still does not look correctly structured."
call :SayRed "Expected it to start with sk_."
goto elevenlabs_after_key_check

:elevenlabs_key_prompt_skipped
call :SayYellow "NOTICE: No ElevenLabs API key entered."
goto elevenlabs_after_key_check

:elevenlabs_key_prompt_valid
> "!ELEVENLABS_DIR!\elevenlabs_api_key.txt" echo !ELEVENLABS_API_KEY!
goto elevenlabs_key_valid

:elevenlabs_key_valid
set "ELEVENLABS_CAN_CHECK_API=YES"

:elevenlabs_after_key_check
if /I not "!ELEVENLABS_CAN_CHECK_API!"=="YES" goto elevenlabs_skip_api_check

call :SayBlue "Checking ElevenLabs API key and voice read permission..."
call :SayYellow "NOTICE: This contacts ElevenLabs, but does not generate speech or use credits."

curl -s -L ^
    -H "xi-api-key: !ELEVENLABS_API_KEY!" ^
    -o "!ELEVENLABS_JSON_FILE!" ^
    -w "%%{http_code}" ^
    "https://api.elevenlabs.io/v1/voices?page_size=100" > "!ELEVENLABS_STATUS_FILE!"

set /p ELEVENLABS_HTTP_STATUS=<"!ELEVENLABS_STATUS_FILE!"

if "!ELEVENLABS_HTTP_STATUS!"=="200" goto elevenlabs_api_success
if "!ELEVENLABS_HTTP_STATUS!"=="401" goto elevenlabs_api_401
if "!ELEVENLABS_HTTP_STATUS!"=="000" goto elevenlabs_api_000
goto elevenlabs_api_other

:elevenlabs_api_success
call :SayGreen "SUCCESS: ElevenLabs API key check completed."
call :SayGreen "SUCCESS: Voice read permission appears to be working."

powershell -NoProfile -ExecutionPolicy Bypass -Command "$data=Get-Content -LiteralPath '!ELEVENLABS_JSON_FILE!' -Raw | ConvertFrom-Json; $voices=@($data.voices); $lines=@('THESE ARE YOUR AVAILABLE ELEVENLABS VOICES:', '', 'Format:', 'Voice Name=voice_id', '', 'Copy the voice_id part into elevenlabs_voice_map.txt.', 'Example:', 'darkElfMale=voice_id_here', '', 'Available voices:', ''); foreach ($voice in $voices) { if ($voice.name -and $voice.voice_id) { $lines += ([string]$voice.name + '=' + [string]$voice.voice_id) } }; Set-Content -LiteralPath '!ELEVENLABS_LIST_FILE!' -Value $lines -Encoding UTF8; Set-Content -LiteralPath '!ELEVENLABS_COUNT_FILE!' -Value $voices.Count -Encoding ASCII"

if errorlevel 1 goto elevenlabs_voice_list_failed

set "ELEVENLABS_VOICE_COUNT=0"
if exist "!ELEVENLABS_COUNT_FILE!" set /p ELEVENLABS_VOICE_COUNT=<"!ELEVENLABS_COUNT_FILE!"

echo.
call :SayYellow "You appear to have !ELEVENLABS_VOICE_COUNT! voices available in ElevenLabs."
call :SayYellow "These may not be Morrowind related."
call :SayYellow "Available voice list saved here:"
echo !ELEVENLABS_LIST_FILE!
echo.
goto elevenlabs_after_api_check

:elevenlabs_voice_list_failed
call :SayRed "WARNING: ElevenLabs voice list could not be created."
goto elevenlabs_after_api_check

:elevenlabs_api_401
call :SayRed "WARNING: ElevenLabs API check failed: HTTP 401 Unauthorized."
call :SayRed "This usually means the API key is invalid or cannot read voices."
call :SayRed "In ElevenLabs API settings, make sure Voices is set to Read."
call :SayRed "Also confirm the key was copied correctly into elevenlabs_api_key.txt."
goto elevenlabs_after_api_check

:elevenlabs_api_000
call :SayRed "WARNING: ElevenLabs API check failed."
call :SayRed "Could not connect to ElevenLabs. Check your internet connection."
goto elevenlabs_after_api_check

:elevenlabs_api_other
call :SayRed "WARNING: ElevenLabs API check failed. HTTP status: !ELEVENLABS_HTTP_STATUS!"
call :SayRed "Check your internet connection, API key, and ElevenLabs permissions."
goto elevenlabs_after_api_check

:elevenlabs_skip_api_check

:elevenlabs_after_api_check
del "!ELEVENLABS_KEY_READ_FILE!" >nul 2>nul
del "!ELEVENLABS_STATUS_FILE!" >nul 2>nul
del "!ELEVENLABS_COUNT_FILE!" >nul 2>nul
del "!ELEVENLABS_JSON_FILE!" >nul 2>nul

if exist "!ELEVENLABS_DIR!\elevenlabs_voice_map.txt" goto elevenlabs_voice_map_ok
call :SayRed "WARNING: ElevenLabs voice map was not found."

:elevenlabs_voice_map_ok
echo.
call :SayYellow "Before AI Voices can use ElevenLabs, add your ElevenLabs voice IDs here:"
echo !ELEVENLABS_DIR!\elevenlabs_voice_map.txt
echo.
call :SayYellow "Test ElevenLabs in-game after adding your API key and voice IDs."
echo.
call :SayGreen "SUCCESS: ElevenLabs setup complete."

:after_elevenlabs_completion

rem ==============================
rem CLEAN TEMP INSTALL FILES
rem ==============================

if exist "!AIVOICES_TEMP_DIR!" rmdir /s /q "!AIVOICES_TEMP_DIR!"

call :cleanup_environment

call :SayGreen "SUCCESS: AI Voices install complete."
pause
exit /b 0

:cleanup_environment
rem Clear AI Voices installer environment overrides.
set "COQUI_TOS_AGREED="
set "HF_HOME="
set "HF_HUB_CACHE="
set "HF_XET_CACHE="
set "HF_ASSETS_CACHE="
set "HF_TOKEN_PATH="
set "HUGGINGFACE_HUB_CACHE="
set "TTS_HOME="
set "TORCH_HOME="
set "XDG_CACHE_HOME="
set "XDG_DATA_HOME="
set "XDG_CONFIG_HOME="
set "PYTHONPYCACHEPREFIX="
set "PYTHONUSERBASE="
set "PIP_NO_CACHE_DIR="
set "PIP_CONFIG_FILE="
set "PIP_DISABLE_PIP_VERSION_CHECK="
set "PIP_NO_INPUT="
goto :eof