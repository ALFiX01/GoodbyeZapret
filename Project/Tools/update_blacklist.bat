@ECHO OFF
set currentDir=%~dp0
set currentDir=%currentDir:~0,-1%
for %%i in ("%currentDir%") do set parentDir=%%~dpi

cd /d "%parentDir%"
set "LISTS=%parentDir%lists"
set errorFlag=0

for %%f in (reestr_hostname.txt reestr_hostname_resolvable.txt) do (
    echo.
    echo  Updating %%f...
    curl -g -L -# -o "%LISTS%\%%f" "https://raw.githubusercontent.com/bol-van/rulist/refs/heads/main/%%f" >nul 2>&1
    if exist "%LISTS%\%%f" (
        echo  %%f Updated successfully.
    ) else (
        echo  Failed to update %%f.
        set errorFlag=1
    )
)

echo.
echo  Updating russia-blacklist.txt...
curl -g -L -# -o "%LISTS%\russia-blacklist.txt" "https://p.thenewone.lol/domains-export.txt" >nul 2>&1
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