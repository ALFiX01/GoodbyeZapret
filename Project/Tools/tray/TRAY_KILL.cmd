@echo off

echo [INFO] Starting GoodbyeZapretTray termination script...
echo.

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

echo [INFO] Terminating GoodbyeZapretTray.exe process...
TASKKILL /IM GoodbyeZapretTray.exe /f
if %errorlevel% neq 0 (
    echo [ERROR] Failed to terminate GoodbyeZapretTray.exe or process not found.
) else (
    powershell -Command "Write-Host '[SUCCESS] GoodbyeZapretTray.exe process terminated successfully.' -ForegroundColor Green"
)

echo.
powershell -Command "Write-Host '[INFO] Script execution completed.' -ForegroundColor Green"
timeout /t 2 >nul
