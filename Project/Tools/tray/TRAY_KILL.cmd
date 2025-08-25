@echo off
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo  Requesting administrator privileges...
    powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs -ArgumentList '--elevated'" >nul 2>&1
    exit /b
)
TASKKILL /IM GoodbyeZapretTray.exe /f
echo OK
timeout /t 2 >nul