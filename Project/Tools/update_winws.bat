@ECHO OFF
setlocal EnableDelayedExpansion
set currentDir=%~dp0
set currentDir=%currentDir:~0,-1%
for %%i in ("%currentDir%") do set parentDir=%%~dpi

cd /d "%parentDir%"
set "FAKE=%parentDir%bin\"
set errorFlag=0

REM Check Winws process status
tasklist | find /i "Winws" >nul
if %errorlevel% equ 0 (
    echo Winws is running.
    pause
)

net session >nul 2>&1
if %errorlevel% neq 0 (
    echo  Requesting administrator privileges...
    powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs -ArgumentList '--elevated'" >nul 2>&1
    exit /b
)

for %%f in (winws.exe WinDivert.dll WinDivert64.sys cygwin1.dll) do (
    del "%FAKE%%%f" >nul 2>&1
    echo.
    echo  Downloading %%f...
    if exist "%parentDir%tools\curl\curl.exe" (
        set CURL="%parentDir%tools\curl\curl.exe"
    ) else (
        set CURL=curl
    )
    !CURL! -g -L -# -o "%FAKE%%%f" "https://github.com/bol-van/zapret-win-bundle/raw/refs/heads/master/zapret-winws/%%f" >nul 2>&1
    if exist "%FAKE%\%%f" (
        echo  %%f downloaded successfully.
    ) else (
        echo  Failed to download %%f.
        set errorFlag=1
    )
)
echo.
if %errorFlag% equ 0 (
    powershell -Command "Write-Host 'All files downloaded successfully!' -ForegroundColor Green"
) else (
    powershell -Command "Write-Host 'Error: Some files failed to download!' -ForegroundColor Red"
)
pause