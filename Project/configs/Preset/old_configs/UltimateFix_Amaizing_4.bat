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

set "CONFIG_NAME=UltimateFix Amaizing 4"
set "FAKE=%ProjectDir%bin\fake\"
set "BIN=%ProjectDir%bin\"
set "LISTS=%ProjectDir%lists\"
cd /d "%BIN%"

REM МОЖНО ИЗМЕНИТЬ ЭТО ЧИСЛО
set "Dup=2"

echo Config: %CONFIG_NAME%
title GoodbyeZapret:  %CONFIG_NAME%
echo.
echo Winws:



start "GoodbyeZapret: %CONFIG_NAME%" /b "%BIN%winws.exe" %log% ^
--wf-tcp=80,443 --wf-udp=443,50000-50099 ^
--filter-tcp=80,443 --ipset="%LISTS%netrogat_ip.txt" --new ^
--filter-tcp=80,443 --hostlist="%LISTS%netrogat.txt" --new ^
--filter-tcp=80,443 --ipset="%LISTS%netrogat_ip_custom.txt" --new ^
--filter-tcp=80,443 --hostlist="%LISTS%netrogat_custom.txt" --new ^
--filter-udp=50000-50099 --filter-l7=discord,stun --dpi-desync=fake --new ^
--filter-tcp=80 --hostlist="%LISTS%russia-discord.txt" --dpi-desync=fakedsplit --dpi-desync-split-pos=1 --dpi-desync-fooling=badseq --dpi-desync-repeats=10 --dpi-desync-autottl --new ^
--filter-tcp=443 --hostlist="%LISTS%youtubeQ.txt" --hostlist="%LISTS%list-youtube.txt" --filter-l7=tls --dup=%Dup% --dup-autottl=+1:3-64 --dpi-desync=fake,multidisorder --dpi-desync-repeats=20 --dpi-desync-split-pos=1,midsld --dpi-desync-fooling=md5sig --dpi-desync-fake-tls-mod=rnd,dupsid,sni=www.google.com --new ^
--filter-udp=443 --hostlist="%LISTS%youtubeQ.txt" --filter-l7=tls --dup=%Dup% --dup-autottl=+1:3-64 --dpi-desync=fake,multidisorder --dpi-desync-repeats=10 --dpi-desync-split-pos=1,midsld --dpi-desync-fooling=md5sig --dpi-desync-fake-tls-mod=rnd,dupsid,sni=www.google.com --new ^
--filter-tcp=443 --hostlist="%LISTS%list-youtube.txt" --filter-l7=quic --dup=%Dup% --dup-autottl=+1:3-64 --dpi-desync=fake --dpi-desync-repeats=20 --dpi-desync-fake-quic="%FAKE%quic_initial_www_google_com.bin" --new ^
--filter-tcp=443 --hostlist="%LISTS%custom-hostlist.txt" --filter-l7=quic --dup=%Dup% --dup-autottl=+1:3-64 --dpi-desync=fake --dpi-desync-repeats=20 --dpi-desync-fake-quic="%FAKE%quic_initial_www_google_com.bin" --new ^
--filter-tcp=443 --hostlist="%LISTS%custom-hostlist.txt" --filter-l7=tls --dup=%Dup% --dup-autottl=+1:3-64 --dpi-desync=fake,multidisorder --dpi-desync-repeats=10 --dpi-desync-split-pos=1,midsld --dpi-desync-fooling=md5sig --dpi-desync-fake-tls-mod=rnd,dupsid,sni=www.google.com --new ^
--filter-udp=443 --ipset="%LISTS%russia-youtube-rtmps.txt" --hostlist="%LISTS%youtubeQ.txt" --filter-l7=quic --dup=%Dup% --dup-autottl=+1:3-64 --dpi-desync=fake --dpi-desync-repeats=20 --dpi-desync-fake-quic="%FAKE%quic_initial_www_google_com.bin" --new ^
--filter-tcp=443 --hostlist="%LISTS%list-facebook_instagram.txt" --filter-l7=quic --dup=%Dup% --dup-autottl=+1:3-64 --dpi-desync=fake --dpi-desync-repeats=20 --dpi-desync-fake-quic="%FAKE%quic_initial_www_google_com.bin" --new ^
--filter-tcp=443 --ipset="%LISTS%ipset-cloudflare3.txt" --dpi-desync=split --dpi-desync-split-pos=1 --dpi-desync-autottl --dpi-desync-fooling=badseq --dpi-desync-repeats=8 --hostlist-exclude="%LISTS%exclude.txt" --new ^
--filter-tcp=443 --hostlist-auto="%LISTS%autohostlist.txt" --hostlist-exclude="%LISTS%exclude-autohostlist.txt" --hostlist-auto-fail-threshold=2 --filter-l7=quic --dup=%Dup% --dup-autottl=+1:3-64 --dpi-desync=fake --dpi-desync-repeats=20 --dpi-desync-fake-quic="%FAKE%quic_initial_www_google_com.bin" --new ^
--filter-tcp=443 --hostlist-auto="%LISTS%autohostlist.txt" --hostlist-exclude="%LISTS%exclude-autohostlist.txt" --hostlist-auto-fail-threshold=2 --filter-l7=tls --dup=%Dup% --dup-autottl=+1:3-64 --dpi-desync=fake,multidisorder --dpi-desync-repeats=20 --dpi-desync-split-pos=1,midsld --dpi-desync-fooling=md5sig --dpi-desync-fake-tls-mod=rnd,dupsid,sni=www.google.com

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