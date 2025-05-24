@ECHO OFF
set currentDir=%~dp0
set currentDir=%currentDir:~0,-1%
for %%i in ("%currentDir%") do set parentDir=%%~dpi

cd /d "%parentDir%"
set "BIN=%parentDir%bin\"
set errorFlag=0

for %%f in (winws.exe WinDivert.dll WinDivert64.sys cygwin1.dll) do (
    echo.
    echo  Downloading %%f...
    curl -g -L -# -o "%BIN%%%f" "https://github.com/bol-van/zapret-win-bundle/raw/refs/heads/master/zapret-winws/%%f" >nul 2>&1
    if exist "%BIN%\%%f" (
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