@echo off
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo  Requesting administrative privileges...
    REM start "" /wait /I /min powershell -NoProfile -Command "Start-Process -FilePath '%~s0' -Verb RunAs"
    powershell -Command "Start-Process 'cmd.exe' -ArgumentList '/c \"\"%~f0\" admin\"' -Verb RunAs"
    exit /b
)
echo.
echo  Clearing local DNS cache.
ipconfig /flushdns
echo.
echo  Release the current IP address assigned via DHCP..
ipconfig /release
echo.
echo  Request from DHCP server for new IP addresses...
ipconfig /renew
echo.
powershell -Command "Write-Host 'Operation completed successfully!' -ForegroundColor Green"
pause