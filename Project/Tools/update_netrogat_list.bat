::[Bat To Exe Converter]
::
::YAwzoRdxOk+EWAnk
::fBw5plQjdG8=
::YAwzuBVtJxjWCl3EqQJgSA==
::ZR4luwNxJguZRRnk
::Yhs/ulQjdF65
::cxAkpRVqdFKZSzk=
::cBs/ulQjdF+5
::ZR41oxFsdFKZSDk=
::eBoioBt6dFKZSDk=
::cRo6pxp7LAbNWATEpCI=
::egkzugNsPRvcWATEpCI=
::dAsiuh18IRvcCxnZtBJQ
::cRYluBh/LU+EWAnk
::YxY4rhs+aU+JeA==
::cxY6rQJ7JhzQF1fEqQJQ
::ZQ05rAF9IBncCkqN+0xwdVs0
::ZQ05rAF9IAHYFVzEqQJQ
::eg0/rx1wNQPfEVWB+kM9LVsJDGQ=
::fBEirQZwNQPfEVWB+kM9LVsJDGQ=
::cRolqwZ3JBvQF1fEqQJQ
::dhA7uBVwLU+EWDk=
::YQ03rBFzNR3SWATElA==
::dhAmsQZ3MwfNWATElA==
::ZQ0/vhVqMQ3MEVWAtB9wSA==
::Zg8zqx1/OA3MEVWAtB9wSA==
::dhA7pRFwIByZRRnk
::Zh4grVQjdCyDJGyX8VAjFD9VQg2LMFeeCbYJ5e31+/m7hUQJfPc9RKjU1bCMOeUp61X2cIIR8HNWndgwOQtcfwaufCM9unpss3CXOMCdpzP0WkyI8k4PFWBglWzXjT8EbNp7jo0GyyXe
::YB416Ek+ZG8=
::
::
::978f952a14a936cc963da21a135fa983
@ECHO OFF
set currentDir=%~dp0
set currentDir=%currentDir:~0,-1%
for %%i in ("%currentDir%") do set parentDir=%%~dpi

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

if exist "%parentDir%tools\curl\curl.exe" (
    set CURL="%parentDir%tools\curl\curl.exe"
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