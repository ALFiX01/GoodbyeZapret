@echo off

set currentDir=%~dp0
set currentDir=%currentDir:~0,-1%
for %%i in ("%currentDir%") do set parentDir=%%~dpi
set parentDir=%parentDir:~0,-1%

if exist "%parentDir%\GoodbyeZapret_latest.zip" (
    powershell -NoProfile Expand-Archive '%parentDir%\GoodbyeZapret_latest.zip' -DestinationPath '%parentDir%\GoodbyeZapret_latest' >nul 2>&1
) else (
    Echo Error: File not found: %parentDir%\GoodbyeZapret_latest.zip
    timeout /t 5 >nul
    exit
)
exit