@echo off
setlocal EnableExtensions
cd /d "%~dp0"

set "ProjectDir=%~dp0.."
for %%I in ("%ProjectDir%") do set "ProjectDir=%%~fI"

set "ServiceMode="
if /i "%~1"=="--service" (
    set "ServiceMode=1"
    shift
)
set "PresetFile=%~1"

if not defined PresetFile (
    echo Preset file is not specified.
    exit /b 1
)

if not exist "%PresetFile%" (
    echo Preset file not found: "%PresetFile%"
    exit /b 1
)

taskkill /F /IM winws.exe /T >nul 2>&1
taskkill /F /IM winws2.exe /T >nul 2>&1
ipconfig /flushdns >nul 2>&1

if defined ServiceMode (
    powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0Start_Config_Preset.ps1" -PresetFile "%PresetFile%" -ProjectDir "%ProjectDir%" -ServiceMode
) else (
    powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0Start_Config_Preset.ps1" -PresetFile "%PresetFile%" -ProjectDir "%ProjectDir%"
)
exit /b %errorlevel%
