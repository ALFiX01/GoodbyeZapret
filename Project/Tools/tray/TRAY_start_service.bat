@echo off
setlocal EnableDelayedExpansion

REM --- Check for administrator privileges ---
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo  Requesting administrator privileges...
    powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs -ArgumentList '--elevated'" >nul 2>&1
    exit /b
)

sc start "GoodbyeZapret" >nul

endlocal