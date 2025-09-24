@echo off
chcp 65001 >nul

goto :Preparing
:Zapusk
echo                         ______                ____            _____                         __ 
echo                        / ____/___  ____  ____/ / /_  __  ____/__  /  ____ _____  ________  / /_
echo                       / / __/ __ \/ __ \/ __  / __ \/ / / / _ \/ /  / __ `/ __ \/ ___/ _ \/ __/
echo                      / /_/ / /_/ / /_/ / /_/ / /_/ / /_/ /  __/ /__/ /_/ / /_/ / /  /  __/ /_ 
echo                      \____/\____/\____/\__,_/_.___/\__, /\___/____/\__,_/ .___/_/   \___/\__/ 
echo                                                   /____/               /_/

set currentDir=%~dp0
set currentDir=%currentDir:~0,-1%
for %%i in ("%currentDir%") do set parentDir=%%~dpi
for %%i in ("%parentDir:~0,-1%") do set ProjectDir=%%~dpi
set "GoodbyeZapret_LastStartConfig=%~nx0"

if not defined GoodbyeZapret_LastStartConfig (
  echo ERROR: GoodbyeZapret_LastStartConfig is not set
  pause
)
reg add "HKCU\Software\ALFiX inc.\GoodbyeZapret" /t REG_SZ /v "GoodbyeZapret_LastStartConfig" /d "%GoodbyeZapret_LastStartConfig%" /f >nul

set "CONFIG_NAME=UltimateFix Amaizing 2"
set "FAKE=%ProjectDir%bin\fake\"
set "BIN=%ProjectDir%bin\"
set "LISTS=%ProjectDir%lists\"
cd /d "%BIN%"

echo Config: %CONFIG_NAME%
title GoodbyeZapret:  %CONFIG_NAME%
echo.
echo Winws:

:: НЕ ВКЛЮЧАТЬ без надобности - приводит к тормозам соединения или полному отключению обхода! Включить - дебаг-лог убрав rem и выключить, добавив rem ::
REM set log=--debug=@%~dp0log_debug.txt

start "GoodbyeZapret: %CONFIG_NAME%" /b "%BIN%winws.exe" %log% ^
--wf-tcp=80,443 --wf-udp=443,50000-50099 ^
--filter-tcp=80,443 --ipset="%LISTS%netrogat_ip.txt" --new ^
--filter-tcp=80,443 --hostlist="%LISTS%netrogat.txt" --new ^
--filter-tcp=80,443 --ipset="%LISTS%netrogat_ip_custom.txt" --new ^
--filter-tcp=80,443 --hostlist="%LISTS%netrogat_custom.txt" --new ^
--filter-udp=50000-50099 --filter-l7=discord,stun --dpi-desync=fake,fakedsplit --dpi-desync-ttl=3 --dpi-desync-split-pos=midsld --dpi-desync-fake-tls=0x00000000 --new ^
--filter-udp=443 --hostlist="%LISTS%russia-discord.txt" --dpi-desync=fake --dpi-desync-fooling=badseq --dpi-desync-fake-tls="%FAKE%tls_clienthello_7.bin" --dpi-desync-fake-tls-mod=rnd --new ^
--filter-udp=443 --hostlist="%LISTS%russia-discord.txt" --dpi-desync=fake,udplen --dpi-desync-udplen-increment=5 --dpi-desync-udplen-pattern=0xDEADBEEF --dpi-desync-fake-quic="%FAKE%quic_3.bin" --dpi-desync-repeats=7 --dpi-desync-cutoff=n2 --new ^
--filter-tcp=443 --hostlist="%LISTS%list-facebook_instagram.txt" --dpi-desync=fake --dpi-desync-ttl=1 --dpi-desync-autottl=1 --dpi-desync-fake-http=0x00000000 --new ^
--filter-tcp=443 --hostlist="%LISTS%mycdnlist.txt" --hostlist="%LISTS%russia-blacklist.txt" --hostlist="%LISTS%custom-hostlist.txt" --dpi-desync=fake --dpi-desync-fooling=badseq --dpi-desync-fake-tls="%FAKE%tls_clienthello_7.bin" --dpi-desync-fake-tls-mod=rnd --new ^
--filter-tcp=443 --hostlist="%LISTS%list-youtube.txt" --dpi-desync=fakedsplit --dpi-desync-ttl=1 --dpi-desync-autottl=2 --dpi-desync-split-pos=method+2 --new ^
--filter-tcp=443 --ipset="%LISTS%ipset-cloudflare3.txt" --dpi-desync=fake,split2 --dpi-desync-repeats=6 --dpi-desync-fooling=md5sig --dpi-desync-fake-tls="%FAKE%tls_clienthello_www_google_com.bin" --hostlist-exclude="%LISTS%exclude.txt" --new ^
--filter-tcp=443 --hostlist-auto="%LISTS%autohostlist.txt" --hostlist-exclude="%LISTS%exclude-autohostlist.txt" --hostlist-auto-fail-threshold=2 --dpi-desync=fake --dpi-desync-fooling=badseq --dpi-desync-fake-tls="%FAKE%tls_clienthello_7.bin" --dpi-desync-fake-tls-mod=rnd

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