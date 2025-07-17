@echo off
chcp 65001 >nul

goto :Preparing
:Zapusk
echo                ______                ____            _____                         __ 
echo               / ____/___  ____  ____/ / /_  __  ____/__  /  ____ _____  ________  / /_
echo              / / __/ __ \/ __ \/ __  / __ \/ / / / _ \/ /  / __ `/ __ \/ ___/ _ \/ __/
echo             / /_/ / /_/ / /_/ / /_/ / /_/ / /_/ /  __/ /__/ /_/ / /_/ / /  /  __/ /_ 
echo             \____/\____/\____/\__,_/_.___/\__, /\___/____/\__,_/ .___/_/   \___/\__/ 
echo                                          /____/               /_/
set "currentDir=%~dp0"
set "currentDir=%currentDir:~0,-1%"
for %%i in ("%currentDir%") do set "parentDir=%%~dpi"
for %%i in ("%parentDir:~0,-1%") do set "ProjectDir=%%~dpi"
reg add "HKCU\Software\ALFiX inc.\GoodbyeZapret" /t REG_SZ /v "GoodbyeZapret_LastStartConfig" /d "%~nx0" /f >nul

set "CONFIG_NAME=GoodbyeZapret: UltimateFix Lab"
set "FAKE=%ProjectDir%bin\fake\"
set "BIN=%ProjectDir%bin\"
set "LISTS=%ProjectDir%lists\"
cd /d "%BIN%"

:: YT (Вы можете выбрать один из вариантов просто закомментировав остальные) (REM в начале строки - значит стратегия не используется)
set YTGV=--dpi-desync=multisplit --dpi-desync-split-pos=10,midsld --dpi-desync-split-seqovl=1
REM set YTGV=--dpi-desync=fake --dpi-desync-fooling=badseq --dpi-desync-fake-tls="%FAKE%TLS_ClientHello_Edge-85_google.com.bin" --dpi-desync-fake-tls-mod=rnd
REM set YTGV=--dpi-desync=fakedsplit --dpi-desync-ttl=2 --dpi-desync-split-pos=1
REM set YTGV=--dpi-desync=multisplit --dpi-desync-split-pos=10 --dpi-desync-split-seqovl=1
REM set YTGV=--dpi-desync=multisplit --dpi-desync-split-pos=10,sniext+1 --dpi-desync-split-seqovl=1
REM set YTGV=--dpi-desync=syndata,multisplit --dpi-desync-split-pos=1
REM set YTGV=--dpi-desync=fake --dpi-desync-ttl=1 --dpi-desync-autottl=-1 --dpi-desync-fake-tls=0x00000000 --dpi-desync-fake-tls=! --dpi-desync-fake-tls-mod=rnd,rndsni,dupsid
REM set YTGV=--dpi-desync=fake --dpi-desync-ttl=1 --dpi-desync-autottl=-1 --dpi-desync-fake-tls=0x00000000 --dpi-desync-fake-tls="%FAKE%tls_clienthello_12.bin" --dpi-desync-fake-tls-mod=rnd,rndsni,dupsid
REM set YTGV=--dpi-desync=fake --dpi-desync-fooling=badseq --dpi-desync-fake-tls=0x00000000 --dpi-desync-fake-tls="%FAKE%tls_clienthello_12.bin" --dpi-desync-fake-tls-mod=rnd,rndsni,dupsid
REM set YTGV=--dpi-desync=fake --dpi-desync-ttl=2 --dpi-desync-fake-tls=0x00000000 --dpi-desync-fake-tls=! --dpi-desync-fake-tls-mod=rnd,rndsni,dupsid
REM set YTGV=--ipcache-hostname --dpi-desync=syndata,fake,multisplit --dpi-desync-split-pos=sld+1 --dpi-desync-fake-syndata="%FAKE%tls_clienthello_7.bin" --dpi-desync-fake-tls=0x0F0F0E0F --dpi-desync-fake-tls="%FAKE%tls_clienthello_9.bin" --dpi-desync-fake-tls-mod=rnd,dupsid --dpi-desync-fooling=md5sig --dpi-desync-autottl --dup=2 --dup-fooling=md5sig --dup-autottl --dup-cutoff=n3

:: YTCHP (Вы можете выбрать один из вариантов просто закомментировав остальные) (REM в начале строки - значит стратегия не используется)
set YTCHP=--dpi-desync=fake,multisplit --dpi-desync-split-pos=sld+1 --dpi-desync-fake-tls=0x0F0F0E0F --dpi-desync-fake-tls="%FAKE%TLS_ClientHello_Edge-106_google.com.bin" --dpi-desync-fake-tls-mod=rnd,dupsid --dpi-desync-fooling=md5sig --dpi-desync-autottl --dup=2 --dup-fooling=md5sig --dup-autottl --dup-cutoff=n3

REM --filter-udp=443 --hostlist="%LISTS%youtubeQ.txt" --dpi-desync=fake,udplen --dpi-desync-udplen-increment=8 --dpi-desync-udplen-pattern=0xFEA82025 --dpi-desync-fake-quic="%FAKE%QUIC_Initial_fonts_google_com_2025-07-10_19-03-42.bin" --dpi-desync-cutoff=n4 --dpi-desync-repeats=2 --new ^

echo %CONFIG_NAME%
echo.
echo.
echo Winws:

:: Здесь можно включить дебаг-лог убрав rem и выключить, добавив rem ::
REM set YTDB_prog_log=--debug=@"%~dp0log_debug.txt" 
REM --wf-tcp=80,443,1024-65535 --wf-udp=443,50000-50099,1024-65535 ^

start "%CONFIG_NAME%" /b "%BIN%winws.exe" %YTDB_prog_log%^
--wf-tcp=80,443,1024-65535 --wf-udp=443,50000-50099,1024-65535 ^
--filter-l3=ipv4 --filter-tcp=80,443 --hostlist="%LISTS%netrogat.txt" --new ^
--filter-l3=ipv4 --filter-udp=50000-50099 --filter-l7=discord,stun --dpi-desync=fake,fakeddisorder --dpi-desync-fooling=datanoack --dpi-desync-autottl --dup=2 --dup-autottl --dup-cutoff=n3 --new ^
--filter-tcp=443 --ipset="%LISTS%russia-youtube-rtmps.txt" --dpi-desync=syndata --dpi-desync-fake-syndata="%FAKE%syn_packet.bin" --dup=2 --dup-cutoff=n3 --new ^
--filter-tcp=443 --hostlist="%LISTS%faceinsta.txt" --dpi-desync=fake,multisplit --dpi-desync-fake-tls=0x0F0F0E0F --dpi-desync-fake-tls="%FAKE%tls_clienthello_16.bin" --dpi-desync-fake-tls-mod=rnd,dupsid --dpi-desync-fooling=md5sig --dpi-desync-split-pos=sld+1 --dpi-desync-autottl --dup=2 --dup-fooling=md5sig --dup-autottl --dup-cutoff=n3 --new ^
--filter-tcp=443 --hostlist="%LISTS%russia-blacklist.txt" --hostlist="%LISTS%custom-hostlist.txt" --hostlist="%LISTS%mycdnlist.txt" --dpi-desync=fake,multidisorder --dpi-desync-split-pos=sld+1 --dpi-desync-fake-tls=0x0F0F0E0F --dpi-desync-fake-tls="%FAKE%tls_clienthello_16.bin" --dpi-desync-fake-tls-mod=rnd,dupsid --dpi-desync-fooling=md5sig --dpi-desync-autottl --dup=2 --dup-fooling=md5sig --dup-autottl --dup-cutoff=n3 --new ^
--filter-tcp=80 --hostlist="%LISTS%russia-blacklist.txt" --hostlist="%LISTS%custom-hostlist.txt" --hostlist="%LISTS%mycdnlist.txt" --dpi-desync=fake,multisplit --dpi-desync-split-seqovl=2 --dpi-desync-split-pos=sld+1 --dpi-desync-fake-http="%FAKE%http_fake_MS.bin" --dpi-desync-fooling=md5sig --dup=2 --dup-fooling=md5sig --dup-cutoff=n3 --new ^
--filter-tcp=443 --hostlist-domains=updates.discord.com, stable.dl2.discordapp.net, getchu.com, rutracker.org, static.rutracker.cc, cdn77.com --dpi-desync=multisplit --dpi-desync-split-seqovl=293 --dpi-desync-split-seqovl-pattern="%FAKE%tls_clienthello_12.bin" --new ^
--filter-tcp=443 --hostlist-domains=googlevideo.com --hostlist="%LISTS%russia-youtube2.txt" %YTGV% --new ^
--filter-tcp=443 --hostlist-domains=googlevideo.com --hostlist="%LISTS%youtube_video-chanel-preview.txt" %YTCHP% --new ^
--filter-l3=ipv4 --filter-tcp=443 --ipset="%LISTS%ipset-cloudflare2.txt" --ipset-exclude-ip=1.1.1.1,1.0.0.1,212.109.195.93,83.220.169.155,141.105.71.21,18.244.96.0/19,18.244.128.0/19 --dpi-desync=multisplit --dpi-desync-split-seqovl=286 --dpi-desync-split-seqovl-pattern="%FAKE%tls_clienthello_11.bin" --dup=2 --dup-cutoff=n3 --new ^
--filter-tcp=80 --hostlist-auto="%LISTS%autohostlist.txt" --hostlist-exclude="%LISTS%exclude-autohostlist.txt" --hostlist-auto-fail-threshold=2 --dpi-desync=fake,multisplit --dpi-desync-split-seqovl=2 --dpi-desync-split-pos=host+1 --dpi-desync-fake-http=0x0E0E0F0E --dpi-desync-fooling=md5sig --new ^
--filter-tcp=443 --hostlist-auto="%LISTS%autohostlist.txt" --hostlist-exclude="%LISTS%exclude-autohostlist.txt" --hostlist-auto-fail-threshold=2 --dpi-desync=fake,fakedsplit --dpi-desync-split-pos=1 --dpi-desync-fake-tls="%FAKE%tls_clienthello_9.bin" --dpi-desync-fooling=badseq --dpi-desync-autottl

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
