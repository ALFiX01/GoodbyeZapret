@echo off
setlocal EnableDelayedExpansion

echo [INFO] Starting winws.exe termination script...
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

REM --- Kill winws.exe process if running ---
echo [INFO] Checking if winws.exe process is running...
tasklist /FI "IMAGENAME eq winws.exe" 2>NUL | find /I /N "winws.exe" >NUL
if "!ERRORLEVEL!"=="0" (
    echo [INFO] winws.exe process found. Terminating...
    taskkill /F /IM winws.exe >nul 2>&1
    if !errorlevel! neq 0 (
        echo [ERROR] Failed to terminate "winws.exe" or process not found.
    ) else (
        powershell -Command "Write-Host '[SUCCESS] winws.exe process terminated successfully.' -ForegroundColor Green"
    )
) else (
    echo [INFO] winws.exe process not found - nothing to terminate.
)
REM --- Kill winws2.exe process if running ---
echo [INFO] Checking if winws2.exe process is running...
tasklist /FI "IMAGENAME eq winws2.exe" 2>NUL | find /I /N "winws2.exe" >NUL
if "!ERRORLEVEL!"=="0" (
    echo [INFO] winws2.exe process found. Terminating...
    taskkill /F /IM winws2.exe >nul 2>&1
    if !errorlevel! neq 0 (
        echo [ERROR] Failed to terminate "winws2.exe" or process not found.
    ) else (
        powershell -Command "Write-Host '[SUCCESS] winws2.exe process terminated successfully.' -ForegroundColor Green"
    )
) else (
    echo [INFO] winws2.exe process not found - nothing to terminate.
)
echo.
powershell -Command "Write-Host '[INFO] Script execution completed.' -ForegroundColor Green"
timeout /t 1 >nul