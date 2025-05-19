@echo off
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo  Requesting administrative privileges...
    REM start "" /wait /I /min powershell -NoProfile -Command "Start-Process -FilePath '%~s0' -Verb RunAs"
    powershell -Command "Start-Process 'cmd.exe' -ArgumentList '/c \"\"%~f0\" admin\"' -Verb RunAs"
    exit /b
)
echo stop "GoodbyeZapret"
net stop "GoodbyeZapret"

echo delete "GoodbyeZapret"
sc delete "GoodbyeZapret"

echo taskkill "winws.exe"
taskkill /F /IM winws.exe

echo stop "WinDivert"
net stop "WinDivert"
sc stop windivert

echo delete "WinDivert"
sc delete "WinDivert"

echo delete "WinDivert14"
sc delete "WinDivert14"
echo.
powershell -Command "Write-Host 'Operation completed successfully!' -ForegroundColor Green"
pause
