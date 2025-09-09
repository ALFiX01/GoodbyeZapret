@ECHO OFF
setlocal EnableDelayedExpansion
set currentDir=%~dp0
set currentDir=%currentDir:~0,-1%
for %%i in ("%currentDir%") do set parentDir=%%~dpi

cd /d "%parentDir%"
set "FAKE=%parentDir%bin\"
set errorFlag=0

net session >nul 2>&1
if %errorlevel% neq 0 (
    echo  Requesting administrator privileges...
    powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs -ArgumentList '--elevated'" >nul 2>&1
    exit /b
)


if exist "%currentDir%\payloadGen" (
    del /Q "%currentDir%\payloadGen"
)

if exist "%currentDir%\zapret-blockcheck" (
    del /Q "%currentDir%\zapret-blockcheck"
)

if exist "%parentDir%tools\curl\curl.exe" (
     set CURL="%parentDir%tools\curl\curl.exe"
) else (
    set CURL=curl
)
%CURL% -g -L -# -o "%currentDir%\Helpers.zip" "https://github.com/ALFiX01/GoodbyeZapret/raw/refs/heads/main/Files/Helpers/Helpers.zip" >nul 2>&1

for %%I in ("%currentDir%\Helpers.zip") do set "FileSize=%%~zI"
if %FileSize% LSS 100 (
    echo       %COL%[91m ^[*^] Error - Файл GoodbyeZapret.zip поврежден или URL не доступен ^(Size %FileSize%^) %COL%[90m
    pause
    del /Q "%currentDir%\Helpers.zip"
    exit
)

chcp 850 >nul 2>&1
powershell -NoProfile Expand-Archive '%currentDir%\Helpers.zip' -DestinationPath '%currentDir%' >nul 2>&1
chcp 65001 >nul 2>&1

del /Q "%currentDir%\Helpers.zip"

if exist "%currentDir%\payloadGen" (
    powershell -Command "Write-Host 'payloadGen: OK' -ForegroundColor Green"
) else (
    powershell -Command "Write-Host 'payloadGen: NOT FOUND' -ForegroundColor Red"
)

if exist "%currentDir%\zapret-blockcheck" (
    powershell -Command "Write-Host 'zapret-blockcheck: OK' -ForegroundColor Green"
) else (
    powershell -Command "Write-Host 'zapret-blockcheck: NOT FOUND' -ForegroundColor Red"
)
pause