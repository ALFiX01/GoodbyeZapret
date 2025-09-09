@echo off
chcp 65001 >nul

goto :Preparing
:Zapusk
cls
echo                         ______                ____            _____                         __ 
echo                        / ____/___  ____  ____/ / /_  __  ____/__  /  ____ _____  ________  / /_
echo                       / / __/ __ \/ __ \/ __  / __ \/ / / / _ \/ /  / __ `/ __ \/ ___/ _ \/ __/
echo                      / /_/ / /_/ / /_/ / /_/ / /_/ / /_/ /  __/ /__/ /_/ / /_/ / /  /  __/ /_ 
echo                      \____/\____/\____/\__,_/_.___/\__, /\___/____/\__,_/ .___/_/   \___/\__/ 
echo                                                   /____/               /_/

set "currentDir=%~dp0"
set "currentDir=%currentDir:~0,-1%"
for %%i in ("%currentDir%") do set "parentDir=%%~dpi"
for %%i in ("%parentDir:~0,-1%") do set "ProjectDir=%%~dpi"
set "GoodbyeZapret_LastStartConfig=%~nx0"

if not defined GoodbyeZapret_LastStartConfig (
  echo ERROR: GoodbyeZapret_LastStartConfig is not set
  pause
)

reg add "HKCU\Software\ALFiX inc.\GoodbyeZapret" /t REG_SZ /v "GoodbyeZapret_LastStartConfig" /d "%GoodbyeZapret_LastStartConfig%" /f >nul

set "CONFIG_NAME=WARP"

REM Основана на Bolvan
set "FAKE=%ProjectDir%bin\fake\"
set "BIN=%ProjectDir%bin\"
set "LISTS=%ProjectDir%lists\"
cd /d "%BIN%"

echo Config: %CONFIG_NAME%
title GoodbyeZapret:  %CONFIG_NAME%
echo.
echo Winws:

:: Здесь нужно указать IP вашей конечной точки [endpoint] WARP для маскировки трафика ::
set YTDB_WARP_IP=104.28.198.245

:: Здесь нужно указать порт вашей конечной точки [endpoint] WARP для маскировки трафика ::
set YTDB_WARP_PORT=443

start "GoodbyeZapret: %CONFIG_NAME%" /b "%BIN%winws.exe" %log% ^
--wf-tcp=80,443 --wf-udp=%YTDB_WARP_PORT% ^
--filter-tcp=80,443 --ipset="%LISTS%netrogat_ip.txt" --new ^
--filter-tcp=80,443 --hostlist="%LISTS%netrogat.txt" --new ^
--filter-tcp=80 --hostlist-domains=cloudflareportal.com,cloudflareok.com,cloudflareclient.com,cloudflarecp.com,cloudflareportal.com --dpi-desync=fake,multisplit --dpi-desync-split-seqovl=2 --dpi-desync-split-pos=sld+1 --dpi-desync-fake-http="%FAKE%http_fake_MS.bin" --dpi-desync-fooling=md5sig --dup=2 --dup-fooling=md5sig --dup-cutoff=n3 --new ^
--filter-tcp=443 --hostlist-domains=cloudflare-ech.com,cloudflare-dns.com,cloudflareok.com,cloudflareclient.com,cloudflareportal.com,cloudflarecp.com --dpi-desync=multisplit --dpi-desync-split-seqovl=211 --dpi-desync-split-seqovl-pattern="%FAKE%tls_clienthello_5.bin" --dup=2 --dup-cutoff=n3 --new ^
--filter-udp=%YTDB_WARP_PORT% --ipset-ip=%YTDB_WARP_IP% --dpi-desync=fake --dpi-desync-fake-quic="%FAKE%quic_7.bin" --dpi-desync-repeats=2 --dpi-desync-autottl --dpi-desync-cutoff=n5 --dup=2 --dup-autottl --dup-cutoff=n5 --new ^
--filter-tcp=80 --hostlist-auto="%LISTS%autohostlist.txt" --hostlist-exclude="%LISTS%netrogat.txt" --dpi-desync=fake,multisplit --dpi-desync-split-seqovl=2 --dpi-desync-split-pos=sld+1 --dpi-desync-fake-http=0x0E0E0F0E --dpi-desync-fooling=md5sig --new ^
--filter-tcp=443 --hostlist-auto="%LISTS%autohostlist.txt" --hostlist-exclude="%LISTS%netrogat.txt" --dpi-desync=fake,fakedsplit --dpi-desync-split-pos=1 --dpi-desync-fake-tls="%FAKE%tls_clienthello_9.bin" --dpi-desync-fooling=badseq --dpi-desync-autottl


REM Проверяем, существует ли GoodbyeZapretTray.exe перед запуском
if exist "%ProjectDir%tools\tray\GoodbyeZapretTray.exe" (
    tasklist /FI "IMAGENAME eq GoodbyeZapretTray.exe" 2>NUL | find /I /N "GoodbyeZapretTray.exe" >NUL
    if errorlevel 1 (
        start "" "%ProjectDir%tools\tray\GoodbyeZapretTray.exe"
    )
)

goto :EOF

:Preparing
if not "%1"=="am_admin" (
  powershell -Command "Start-Process -FilePath '%~f0' -ArgumentList 'am_admin' -Verb RunAs"
  exit /b
)
Echo Preparing...

REM Stop & delete zapret service if it exists
sc query "zapret" >nul 2>&1
if %errorlevel% equ 0 (
  sc stop zapret >nul 2>&1
  sc delete zapret >nul 2>&1
)

REM Check if winws.exe is running and terminate it if found
tasklist /FI "IMAGENAME eq winws.exe" 2>NUL | find /I /N "winws.exe" >NUL
if "%ERRORLEVEL%"=="0" (
  REM Forcefully kill winws.exe process
  taskkill /F /IM winws.exe >nul 2>&1
)

REM Stop WinDivert service if it exists and running (no delete because this is a shared driver)
REM sc query "WinDivert" >nul 2>&1
REM if %errorlevel% equ 0 (
  REM sc stop WinDivert >nul 2>&1
  REM REM give the driver a moment to unload
  REM ping -n 3 127.0.0.1 > nul
REM )

REM Flush DNS cache
ipconfig /flushdns > nul
cls
goto :Zapusk
