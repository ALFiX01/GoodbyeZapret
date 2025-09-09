@echo off
setlocal EnableDelayedExpansion

echo [INFO] Starting GoodbyeZapret service...
echo.

REM --- Check for administrator privileges ---
echo [INFO] Checking for administrator privileges...
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [WARNING] Administrator privileges required!
    echo [INFO] Requesting administrator privileges...
    powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs -ArgumentList '--elevated'" >nul 2>&1
    exit /b
) else (
    echo [INFO] Administrator privileges confirmed.
)

echo.

echo [INFO] Checking if GoodbyeZapret service exists...
sc query "GoodbyeZapret" >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] GoodbyeZapret service not found in the system.
    echo [INFO] Please ensure the service is properly installed.
    echo.
    echo [INFO] Script execution completed.
    timeout /t 2 >nul
    exit /b
) else (
    echo [INFO] GoodbyeZapret service found.
)

echo.

echo [INFO] Attempting to start GoodbyeZapret service...
sc start "GoodbyeZapret" >nul

powershell -Command "Write-Host '[SUCCESS] GoodbyeZapret service started successfully.' -ForegroundColor Green"
echo.
powershell -Command "Write-Host '[INFO] Script execution completed.' -ForegroundColor Green"
timeout /t 1 >nul