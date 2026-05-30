@ECHO OFF
set currentDir=%~dp0
set currentDir=%currentDir:~0,-1%
for %%i in ("%currentDir%") do set parentDir=%%~dpi
for %%i in ("%parentDir:~0,-1%") do set parentParentDir=%%~dpi

echo %currentDir% | findstr /i "Project" >nul
if %errorlevel%==0 (
    echo Find "Project", exit...
    exit /b
)

cd /d "%parentDir%"
set "LISTS=%parentDir%lists"
set errorFlag=0

echo.
echo  Updating netrogat_ip.txt...

if exist "%parentParentDir%tools\curl\curl.exe" (
    set CURL="%parentParentDir%tools\curl\curl.exe"
) else (
    set CURL=curl
)

%CURL% -g -L -# -o "%LISTS%\netrogat_ip.txt" "https://raw.githubusercontent.com/ALFiX01/GoodbyeZapret/refs/heads/main/Project/lists/netrogat_ip.txt" >nul 2>&1
if exist "%LISTS%\netrogat_ip.txt" (
    echo  netrogat_ip.txt Updated successfully.
) else (
    echo  Failed to update netrogat_ip.txt.
    set errorFlag=1
)

echo  Updating netrogat.txt...
%CURL% -g -L -# -o "%LISTS%\netrogat.txt" "https://raw.githubusercontent.com/ALFiX01/GoodbyeZapret/refs/heads/main/Project/lists/netrogat.txt" >nul 2>&1
if exist "%LISTS%\netrogat.txt" (
    echo  netrogat.txt Updated successfully.
) else (
    echo  Failed to update netrogat.txt.
    set errorFlag=1
)

echo.
if %errorFlag% equ 0 (
    powershell -Command "Write-Host 'All files updated successfully!' -ForegroundColor Green"
) else (
    powershell -Command "Write-Host 'Error: Some files failed to update!' -ForegroundColor Red"
)
pause
