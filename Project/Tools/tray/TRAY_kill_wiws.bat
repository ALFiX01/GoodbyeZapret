@echo off
setlocal EnableDelayedExpansion

REM --- Check for administrator privileges ---
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo  Requesting administrator privileges...
    powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs -ArgumentList '--elevated'" >nul 2>&1
    exit /b
)

REM --- Kill winws.exe process if running ---
tasklist /FI "IMAGENAME eq winws.exe" 2>NUL | find /I /N "winws.exe" >NUL
if "!ERRORLEVEL!"=="0" (
    echo Terminating "winws.exe" process...
    taskkill /F /IM winws.exe >nul 2>&1
    if !errorlevel! neq 0 (
        echo   Failed to terminate "winws.exe" or process not found.
    )
) else (
    echo "winws.exe" process not found.
)

endlocal