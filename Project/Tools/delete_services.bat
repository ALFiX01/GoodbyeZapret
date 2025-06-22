@echo off
setlocal enabledelayedexpansion

REM Check for administrator privileges
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Requesting administrative privileges...
    powershell -Command "Start-Process 'cmd.exe' -ArgumentList '/c \"\"%~f0\" admin\"' -Verb RunAs"
    exit /b
)

REM Stop and delete GoodbyeZapret service
echo Stopping "GoodbyeZapret" service...
net stop "GoodbyeZapret" >nul 2>&1
if %errorlevel% neq 0 echo   "GoodbyeZapret" service was not running or could not be stopped.

echo Deleting "GoodbyeZapret" service...
sc delete "GoodbyeZapret" >nul 2>&1
if %errorlevel% neq 0 echo   Failed to delete "GoodbyeZapret" service or it was already removed.

REM Kill winws.exe process
echo Terminating "winws.exe" process...
taskkill /F /IM winws.exe >nul 2>&1
if %errorlevel% neq 0 echo   Failed to terminate "winws.exe" or process not found.

REM Stop and delete WinDivert service
echo Stopping "WinDivert" service...
net stop "WinDivert" >nul 2>&1
sc stop windivert >nul 2>&1

echo Deleting "WinDivert" service...
sc delete "WinDivert" >nul 2>&1
if %errorlevel% neq 0 echo   Failed to delete "WinDivert" service or it was already removed.

echo Deleting "WinDivert14" service...
sc delete "WinDivert14" >nul 2>&1
if %errorlevel% neq 0 echo   Failed to delete "WinDivert14" service or it was already removed.

echo.
powershell -Command "Write-Host 'Operation completed successfully!' -ForegroundColor Green"
pause
endlocal