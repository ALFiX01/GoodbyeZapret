@echo off
setlocal EnableDelayedExpansion

REM --- Check for administrator privileges ---
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo  Requesting administrator privileges...
    powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs -ArgumentList '--elevated'" >nul 2>&1
    exit /b
)

REM --- Stop and delete GoodbyeZapret service if it exists ---
sc query "GoodbyeZapret" >nul 2>&1
if !errorlevel! equ 0 (
    echo Stopping "GoodbyeZapret" service...
    sc stop "GoodbyeZapret" >nul 2>&1
    ping -n 3 127.0.0.1 >nul
    echo Deleting "GoodbyeZapret" service...
    sc delete "GoodbyeZapret" >nul 2>&1
) else (
    echo "GoodbyeZapret" service not found.
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

REM --- Stop and delete WinDivert service if it exists ---
for %%S in (WinDivert monkey) do (
    sc query "%%S" >nul 2>&1
    if !errorlevel! equ 0 (
        echo Stopping "%%S" service...
        sc stop "%%S" >nul 2>&1
        ping -n 3 127.0.0.1 >nul
        echo Deleting "%%S" service...
        sc delete "%%S" >nul 2>&1
        if !errorlevel! neq 0 (
            echo   Failed to delete "%%S" service or it was already removed.
        )
    ) else (
        echo "%%S" service not found.
    )
)

taskkill /F /IM GoodbyeZapretTray.exe >nul 2>&1

echo.
powershell -Command "Write-Host 'Operation completed successfully!' -ForegroundColor Green"
endlocal