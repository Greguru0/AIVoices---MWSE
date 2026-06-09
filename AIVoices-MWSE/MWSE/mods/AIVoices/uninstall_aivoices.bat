@echo off
setlocal EnableExtensions EnableDelayedExpansion

cd /d "%~dp0"

set "MOD_DIR=%CD%"
for %%I in ("%MOD_DIR%\..\..\..") do set "DATA_FILES_DIR=%%~fI"
set "BACKEND_DIR=%DATA_FILES_DIR%\AIVoicesBackend"
set "RUNTIME_DIR=!BACKEND_DIR!\runtime"
set "SETTINGS_DIR=!BACKEND_DIR!\settings"
set "PIPER_DIR=!BACKEND_DIR!\Piper"
set "XTTS_DIR=!BACKEND_DIR!\XTTS"
set "ELEVENLABS_DIR=!BACKEND_DIR!\ElevenLabs"
set "DEPENDENCIES_DIR=!BACKEND_DIR!\dependencies"
set "MARKERS_DIR=!BACKEND_DIR!\install_markers"
set "INSTALL_MARKER_FILE=!MARKERS_DIR!\aivoices_installed.txt"
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
call :SayCyan "AI Voices Uninstaller"
echo ==============================
call :SayBlue " - Created by Greguru (Nexus Mods: Diablo0987)"
echo.

if exist "!INSTALL_MARKER_FILE!" (
    for /f "tokens=2 delims=:" %%V in ('findstr /B /C:"AI Voices version:" "!INSTALL_MARKER_FILE!" 2^>nul') do (
        set "EXISTING_AIVOICES_VERSION=%%V"
    )

    set "EXISTING_AIVOICES_VERSION=!EXISTING_AIVOICES_VERSION: =!"

    if "!EXISTING_AIVOICES_VERSION!"=="" (
        set "EXISTING_AIVOICES_VERSION=V1.00 or older / unknown"
    )

    echo Installed version:
    echo !EXISTING_AIVOICES_VERSION!
    echo.
) else (
    call :SayYellow "No AI Voices install marker was found."
    echo The backend folder may already be partially removed, manually edited, or from an older install.
    echo.
)

call :SayYellow "Before uninstalling:"
echo - Close Morrowind
echo - Close the AI Voices watcher console, if it is open
echo - Wait a few seconds for Python/watcher.py to exit
echo.
call :SayYellow "If Morrowind or watcher.py is still running, some files may fail to delete."
echo.

call :SayYellow "This removes files created in the AI Voices backend folder."
echo.
echo It will remove:
echo - AIVoicesBackend\dependencies folder
echo   This includes the local Python virtual environment, FFmpeg, package caches, temp files, and model caches.
echo - AIVoicesBackend\runtime folder
echo   This includes dialogue, voice, stop, status, heartbeat, watcher log, and temporary WAV files.
echo - AIVoicesBackend\settings folder
echo   This includes TTS engine selection, volume, speech speed, pronunciation, and XTTS settings.
echo - AIVoicesBackend\XTTS folder
echo   This includes XTTS reference samples, XTTS reference map, and XTTS generated-line cache.
echo - AIVoicesBackend\install_markers
echo   This includes installer markers, version info, CUDA/PyTorch install info, and generated reference sample notes.
echo.
echo It may also remove:
echo - AIVoicesBackend\ElevenLabs folder, if you choose to remove it
echo   This may include your ElevenLabs API key, voice map, settings, and generated-line cache.
echo - AIVoicesBackend\Piper folder, if you choose to remove it
echo   This may include your Piper voice map, Piper settings, generated-line cache, and custom .onnx voices.
echo.
echo It will NOT remove:
echo - the AI Voices MWSE mod files from Data Files\MWSE\mods\AIVoices
echo - main.lua
echo - mcm.lua
echo - config.lua
echo - watcher.py
echo - install_aivoices.bat
echo - uninstall_aivoices.bat
echo - readme or changelog files
echo - original Morrowind files
echo - original Morrowind voice files
echo - system Python
echo - system FFmpeg
echo - anything outside Data Files\AIVoicesBackend
echo.
echo Mod folder:
echo !MOD_DIR!
echo Backend folder:
echo !BACKEND_DIR!
echo.

call :SayRed "Review the notes above before continuing."
echo.

choice /C YN /N /M "Continue uninstall? [Y/N] "

if errorlevel 2 (
	echo.
	call :SayYellow "Uninstall cancelled."
	pause
	exit /b 1
)

echo.
call :SayCyan "Removing local backend environment"
echo.

if exist "!DEPENDENCIES_DIR!\aivoices-venv" (
    echo Removing !DEPENDENCIES_DIR!\aivoices-venv...
    rmdir /s /q "!DEPENDENCIES_DIR!\aivoices-venv"

    if exist "!DEPENDENCIES_DIR!\aivoices-venv" (
        call :SayYellow "WARNING: aivoices-venv could not be fully removed."
    ) else (
        call :SayGreen "SUCCESS: Removed aivoices-venv."
    )
) else (
    echo !DEPENDENCIES_DIR!\aivoices-venv not found. Skipping.
)

if exist "!RUNTIME_DIR!" (
    echo Removing runtime folder...
    rmdir /s /q "!RUNTIME_DIR!"

    if exist "!RUNTIME_DIR!" (
        call :SayYellow "WARNING: runtime folder could not be fully removed."
    ) else (
        call :SayGreen "SUCCESS: Removed runtime folder."
    )
) else (
    echo runtime folder not found. Skipping.
)

if exist "!SETTINGS_DIR!" (
    echo Removing settings folder...
    rmdir /s /q "!SETTINGS_DIR!"

    if exist "!SETTINGS_DIR!" (
        call :SayYellow "WARNING: settings folder could not be fully removed."
    ) else (
        call :SayGreen "SUCCESS: Removed settings folder."
    )
) else (
    echo settings folder not found. Skipping.
)

if exist "!XTTS_DIR!" (
    echo Removing XTTS folder...
    rmdir /s /q "!XTTS_DIR!"

    if exist "!XTTS_DIR!" (
        call :SayYellow "WARNING: XTTS folder could not be fully removed."
    ) else (
        call :SayGreen "SUCCESS: Removed XTTS folder."
    )
) else (
    echo XTTS folder not found. Skipping.
)

if exist "!ELEVENLABS_DIR!" (
	call :SayRed "IMPORTANT: ElevenLabs may contain your API key, voice map, settings, and cached generated dialogue."
	choice /C YN /N /M "Remove ElevenLabs folder too? [Y/N] "

    if errorlevel 2 (
        echo.
        echo Keeping ElevenLabs folder.
    ) else (
        echo.
        echo Removing ElevenLabs folder...
        rmdir /s /q "!ELEVENLABS_DIR!"

        if exist "!ELEVENLABS_DIR!" (
            call :SayYellow "WARNING: ElevenLabs folder could not be fully removed."
        ) else (
            call :SayGreen "SUCCESS: Removed ElevenLabs folder."
        )
    )
) else (
    echo ElevenLabs folder not found. Skipping.
)

if exist "!PIPER_DIR!" (
	call :SayRed "IMPORTANT: Piper may contain user-provided .onnx voices, voice maps, settings, and cached generated dialogue."
	choice /C YN /N /M "Remove Piper folder too? [Y/N] "

    if errorlevel 2 (
        echo.
        echo Keeping Piper folder.
    ) else (
        echo.
        echo Removing Piper folder...
        rmdir /s /q "!PIPER_DIR!"

        if exist "!PIPER_DIR!" (
            call :SayYellow "WARNING: Piper folder could not be fully removed."
        ) else (
            call :SayGreen "SUCCESS: Removed Piper folder."
        )
    )
) else (
    echo Piper folder not found. Skipping.
)

if exist "!DEPENDENCIES_DIR!" (
    echo Removing dependencies folder...
    rmdir /s /q "!DEPENDENCIES_DIR!"

    if exist "!DEPENDENCIES_DIR!" (
        call :SayYellow "WARNING: dependencies folder could not be fully removed."
    ) else (
        call :SayGreen "SUCCESS: Removed dependencies folder."
    )
) else (
    echo dependencies folder not found. Skipping.
)

if exist "!MARKERS_DIR!" (
    echo Removing install_markers folder...
    rmdir /s /q "!MARKERS_DIR!"

    if exist "!MARKERS_DIR!" (
        call :SayYellow "WARNING: install_markers folder could not be fully removed."
    ) else (
        call :SayGreen "SUCCESS: Removed install_markers folder."
    )
) else (
    echo install_markers folder not found. Skipping.
)
if exist "!BACKEND_DIR!" (
    echo Removing empty backend folder if possible...
    rmdir "!BACKEND_DIR!" >nul 2>nul
)

echo.
echo.
call :SayYellow "Note:"
echo If you chose to keep the Piper or ElevenLabs folders, those files remain in:
echo !BACKEND_DIR!
echo.
echo You can delete them manually later if you are sure you no longer need them.
echo.

call :SayGreen "SUCCESS: AI Voices uninstall complete."
echo.
pause