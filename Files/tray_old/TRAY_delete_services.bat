@echo off
setlocal EnableDelayedExpansion

echo [INFO] Starting service deletion script...
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

REM --- Stop and delete GoodbyeZapret service if it exists ---
echo [INFO] Checking if GoodbyeZapret service exists...
sc query "GoodbyeZapret" >nul 2>&1
if !errorlevel! equ 0 (
    echo [INFO] GoodbyeZapret service found. Stopping...
    sc stop "GoodbyeZapret" >nul 2>&1
    if !errorlevel! neq 0 (
        echo [WARNING] Failed to stop GoodbyeZapret service or it was already stopped.
    ) else (
        echo [INFO] GoodbyeZapret service stopped successfully.
    )
    ping -n 3 127.0.0.1 >nul
    echo [INFO] Deleting GoodbyeZapret service...
    sc delete "GoodbyeZapret" >nul 2>&1
    if !errorlevel! neq 0 (
        echo [ERROR] Failed to delete GoodbyeZapret service.
    ) else (
        echo [SUCCESS] GoodbyeZapret service deleted successfully.
    )
) else (
    echo [INFO] GoodbyeZapret service not found - nothing to delete.
)

echo.

REM --- Kill winws.exe process if running ---
echo [INFO] Checking if winws.exe process is running...
tasklist /FI "IMAGENAME eq winws.exe" 2>NUL | find /I /N "winws.exe" >NUL
if "!ERRORLEVEL!"=="0" (
    echo [INFO] winws.exe process found. Terminating...
    taskkill /F /IM winws.exe >nul 2>&1
    if !errorlevel! neq 0 (
        echo [ERROR] Failed to terminate winws.exe process.
    ) else (
        echo [SUCCESS] winws.exe process terminated successfully.
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
        echo [ERROR] Failed to terminate winws2.exe process.
    ) else (
        echo [SUCCESS] winws2.exe process terminated successfully.
    )
) else (
    echo [INFO] winws2.exe process not found - nothing to terminate.
)

echo.

REM --- Stop and delete WinDivert service if it exists ---
echo [INFO] Checking WinDivert and monkey services...
for %%S in (WinDivert monkey) do (
    echo [INFO] Checking %%S service...
    sc query "%%S" >nul 2>&1
    if !errorlevel! equ 0 (
        echo [INFO] %%S service found. Stopping...
        sc stop "%%S" >nul 2>&1
        if !errorlevel! neq 0 (
            echo [WARNING] Failed to stop %%S service or it was already stopped.
        ) else (
            echo [INFO] %%S service stopped successfully.
        )
        ping -n 3 127.0.0.1 >nul
        echo [INFO] Deleting %%S service...
        sc delete "%%S" >nul 2>&1
        if !errorlevel! neq 0 (
            echo [ERROR] Failed to delete %%S service.
        ) else (
            powershell -Command "Write-Host '[SUCCESS] %%S service deleted successfully.' -ForegroundColor Green"
        )
    ) else (
        echo [INFO] %%S service not found - nothing to delete.
    )
    echo.
)

powershell -Command "Write-Host '[INFO] All operations completed!' -ForegroundColor Green"
timeout /t 2 >nul
endlocal