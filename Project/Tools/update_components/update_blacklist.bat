@ECHO OFF
set currentDir=%~dp0
set currentDir=%currentDir:~0,-1%
for %%i in ("%currentDir%") do set parentDir=%%~dpi

rem ParentParentDir = родитель от parentDir
for %%i in ("%parentDir:~0,-1%") do set parentParentDir=%%~dpi

cd /d "%parentParentDir%"
set "LISTS=%parentParentDir%lists"
set errorFlag=0

echo.
echo  Updating russia-blacklist.txt...

if exist "%parentParentDir%tools\curl\curl.exe" (
    set CURL="%parentParentDir%tools\curl\curl.exe"
) else (
    set CURL=curl
)

%CURL% -g -L -# -o "%LISTS%\russia-blacklist.txt" "https://p.thenewone.lol/domains-export.txt" >nul 2>&1
if exist "%LISTS%\russia-blacklist.txt" (
    echo  russia-blacklist.txt Updated successfully.
) else (
    echo  Failed to update russia-blacklist.txt.
    set errorFlag=1
)

echo.
if %errorFlag% equ 0 (
    powershell -Command "Write-Host 'All files updated successfully!' -ForegroundColor Green"
) else (
    powershell -Command "Write-Host 'Error: Some files failed to update!' -ForegroundColor Red"
)
pause