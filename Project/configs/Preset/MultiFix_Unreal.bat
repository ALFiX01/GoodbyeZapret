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
set "currentDir=%~dp0"
set "currentDir=%currentDir:~0,-1%"
for %%i in ("%currentDir%") do set "parentDir=%%~dpi"
for %%i in ("%parentDir:~0,-1%") do set "ProjectDir=%%~dpi"
set "GoodbyeZapret_LastStartConfig=%~nx0"

if not defined GoodbyeZapret_LastStartConfig (
  echo ERROR: GoodbyeZapret_LastStartConfig is not set
  pause
)

set "CONFIG_NAME=UltimateFix Unreal"

REM Основана YTDSBystro 3.5.1
set "FAKE=%ProjectDir%bin\fake\"
set "BIN=%ProjectDir%bin\"
set "LISTS=%ProjectDir%lists\"
cd /d "%BIN%"

echo Config: %CONFIG_NAME%
title GoodbyeZapret:  %CONFIG_NAME%
echo.
echo Winws:

set YTDB_Games_TCP=443,444-65535
set YTDB_Games_UDP=443,444-65535
set YTDB_UDP_Repeats=2
set YTDB_Cutoff_Limit=3
set YTDB_TTL_Limit=7

set YTDB_AUTOTTL= --dpi-desync-autottl
rem set YTDB_TTL= --dpi-desync-ttl=5

:: Сюда скопируйте стратегию для сайтов, которая у вас работает ::
REM set "YTDB_TLS_MAIN=--dpi-desync=multisplit --dpi-desync-split-seqovl=228 --dpi-desync-split-seqovl-pattern="%FAKE%fake_tls_2.bin""
set "YTDB_TLS_MAIN=--dpi-desync=multisplit --dpi-desync-split-seqovl=1 --dpi-desync-split-pos=1 --dpi-desync-split-seqovl-pattern="%FAKE%fake_tls_4.bin""

:: Сюда скопируйте стратегию для дискорда, которая работает у вас. Может быть копией YTDB_TLS_MAIN ::
REM set "YTDB_TLS_MAIN2=--dpi-desync=fakedsplit --dpi-desync-split-pos=2,host+1 --dpi-desync-fakedsplit-pattern="%FAKE%fake_tls_4.bin" --dpi-desync-repeats=2 --dpi-desync-fooling=md5sig%YTDB_AUTOTTL%%YTDB_TTL%"
REM set "YTDB_TLS_MAIN2=--dpi-desync=fake,multisplit --dpi-desync-split-seqovl=225 --dpi-desync-split-seqovl-pattern="%FAKE%fake_tls_1.bin""
REM set "YTDB_TLS_MAIN2=--dpi-desync=fake,multidisorder --dpi-desync-split-pos=sld+1 --dpi-desync-fake-tls=0x0F0F0E0F --dpi-desync-fake-tls="%FAKE%tls_clienthello_16.bin" --dpi-desync-fake-tls-mod=rnd,dupsid --dpi-desync-fooling=md5sig --dpi-desync-autottl --dup=2 --dup-fooling=md5sig --dup-autottl --dup-cutoff=n3"
REM set "YTDB_TLS_MAIN2=--hostlist="%LISTS%list-discord.txt" --dpi-desync-any-protocol=1 --dpi-desync=multisplit --dpi-desync-split-seqovl=228 --dpi-desync-split-seqovl-pattern="%FAKE%fake_tls_2.bin" --dpi-desync-cutoff=n5"
set "YTDB_TLS_MAIN2=--hostlist="%LISTS%list-discord.txt" --dpi-desync=fake,fakedsplit --dpi-desync-repeats=6 --dpi-desync-fooling=ts --dpi-desync-fakedsplit-pattern=0x00 --dpi-desync-fake-tls="%FAKE%tls_clienthello_www_google_com.bin""

:: Сюда скопируйте стратегию для квика ютуба, которая у вас работает  ::
REM set "YTDB_QUIC_MAIN=--dpi-desync=ipfrag2 --dpi-desync-repeats=3 --dpi-desync-ttl=5"
set "YTDB_QUIC_MAIN=--dpi-desync=fake,udplen --dpi-desync-udplen-pattern=0x0F0F0E0F --dpi-desync-fake-quic="%FAKE%fake_quic_3.bin" --dpi-desync-repeats=2"


:: НЕ ВКЛЮЧАТЬ без надобности - приводит к тормозам соединения или полному отключению обхода! Включить - дебаг-лог убрав rem и выключить, добавив rem ::
REM set log=--debug=@%~dp0log_debug.txt

:: Уровень обхода для CDN (Cloudflare, Fastly, Amazon и др.): off / min / base / full / full_ext
:: Режимы отличаются количеством обрабатываемых IP-адресов (чем выше уровень, тем шире список).
if not defined CDN_BypassLevel set "CDN_BypassLevel=base"

start "GoodbyeZapret: %CONFIG_NAME%" /min "%BIN%winws.exe" %log% ^
--wf-tcp=80,443,2053,2083,2087,2096,8443 --wf-udp=443,444-65535 ^
--wf-raw-part=@"%BIN%windivert.filter\windivert_part.stun.txt" ^
--wf-raw-part=@"%BIN%windivert.filter\windivert_part.discord_media.txt" ^
--filter-tcp=80,443 --ipset="%LISTS%netrogat_ip.txt" --ipset="%LISTS%netrogat_ip_custom.txt"  --new ^
--filter-tcp=80,443 --hostlist="%LISTS%netrogat.txt" --hostlist="%LISTS%netrogat_custom.txt" --new ^
--filter-udp=443 --ipset-ip=162.159.198.1,162.159.198.2,162.159.36.1,162.159.46.1,2606:4700:103::1,2606:4700:103::2 %YTDB_QUIC_MAIN% --dpi-desync-cutoff=n3 --new ^
--filter-udp=443 --hostlist-exclude="%LISTS%list-discord.txt" %YTDB_QUIC_MAIN% --dpi-desync-cutoff=n3 --new ^
--filter-tcp=443 --dpi-desync-any-protocol=1 --hostlist="%LISTS%list-discord.txt" %YTDB_TLS_MAIN2% --new ^
--filter-l7=discord,stun --dpi-desync-any-protocol=1 --dpi-desync=fake --dpi-desync-repeats=6 --dpi-desync-cutoff=n4
--filter-tcp=443 --dpi-desync-any-protocol=1 --hostlist="%LISTS%russia-blacklist.txt" --hostlist="%LISTS%custom-hostlist.txt" --hostlist="%LISTS%mycdnlist.txt" --dpi-desync=fake,multidisorder --dpi-desync-split-pos=sld+1 --dpi-desync-fake-tls=0x0F0F0E0F --dpi-desync-fake-tls="%FAKE%tls_clienthello_16.bin" --dpi-desync-fake-tls-mod=rnd,dupsid --dpi-desync-fooling=md5sig --dpi-desync-autottl --dup=2 --dup-fooling=md5sig --dup-autottl --dup-cutoff=n3 --new ^
--filter-tcp=80 --dpi-desync-any-protocol=1 --hostlist="%LISTS%russia-blacklist.txt" --hostlist="%LISTS%custom-hostlist.txt" --hostlist="%LISTS%mycdnlist.txt" --dpi-desync=fake,multisplit --dpi-desync-split-seqovl=2 --dpi-desync-split-pos=sld+1 --dpi-desync-fake-http="%FAKE%http_fake_MS.bin" --dpi-desync-fooling=md5sig --dup=2 --dup-fooling=md5sig --dup-cutoff=n3 --new ^
--filter-tcp=443 --hostlist-domains=updates.discord.com, stable.dl2.discordapp.net, rutracker.org, static.rutracker.cc, cdn77.com --dpi-desync=multisplit --dpi-desync-split-seqovl=293 --dpi-desync-split-seqovl-pattern="%FAKE%tls_clienthello_12.bin" --new ^
--filter-tcp=80,443-65535 --ipset="%LISTS%ipset-cloudflare-%CDN_BypassLevel%.txt" --ipset-exclude="%LISTS%ipset-dns.txt" --dpi-desync-any-protocol=1 --dpi-desync=fake,multisplit --dpi-desync-split-pos=1,sld+1 --dpi-desync-fake-tls=0x0F0F0F0F --dpi-desync-fake-tls="%FAKE%fake_tls_3.bin" --dpi-desync-fake-tls-mod=rnd,dupsid,rndsni --dpi-desync-fooling=ts,badseq --dpi-desync-cutoff=n5 --new ^
--filter-udp=443,444-65535 --ipset="%LISTS%ipset-cloudflare-%CDN_BypassLevel%.txt" --dpi-desync=fake --dpi-desync-repeats=6 --dpi-desync-fake-quic="%FAKE%quic_initial_www_google_com.bin" --new ^
--filter-tcp=80 --dpi-desync=syndata,multisplit --dpi-desync-split-seqovl=4 --dpi-desync-split-pos=host+2 --dpi-desync-cutoff=n4 --new ^
--filter-tcp=443,444-65535 --filter-l7=tls --ipset-exclude-ip=18.244.96.0/19,18.244.128.0/19 %YTDB_TLS_MAIN% --dpi-desync-cutoff=n5 --new ^
--filter-tcp=444-65535 --filter-l7=unknown --ipset-exclude-ip=18.244.96.0/19,18.244.128.0/19 --dpi-desync-any-protocol=1 --dpi-desync=syndata --synack-split=synack --dpi-desync-fake-syndata="%FAKE%fake_syndata.bin" --dpi-desync-cutoff=n5 --new ^
--filter-udp=444-65535 --dpi-desync=fake,udplen --dpi-desync-any-protocol=1 --dpi-desync-fake-unknown-udp="%FAKE%fake_quic_3.bin" --dpi-desync-repeats=%YTDB_UDP_Repeats% --dpi-desync-cutoff=n%YTDB_Cutoff_Limit% --dpi-desync-ttl=%YTDB_TTL_Limit% --new ^
--filter-tcp=2053,2083,2087,2096,8443 --hostlist-domains=discord.media --dpi-desync=fake --dpi-desync-split-pos=3 --dpi-desync-fake-tls-mod=dupsid,sni=video.cdn.bsky.app --ip-id=rnd --dpi-desync-fooling=ts --dpi-desync-cutoff=n5 --new ^
--filter-udp=5056,27002 --dpi-desync-any-protocol=1 --dpi-desync=fake --dpi-desync-repeats=6 --dpi-desync-cutoff=n15 --dpi-desync-fake-unknown-udp="%FAKE%quic_initial_www_google_com.bin"

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

REM Check if winws2.exe is running and terminate it if found
tasklist /FI "IMAGENAME eq winws2.exe" 2>NUL | find /I /N "winws2.exe" >NUL
if "%ERRORLEVEL%"=="0" (
  REM Forcefully kill winws2.exe process
  taskkill /F /IM winws2.exe >nul 2>&1
)

REM Flush DNS cache
ipconfig /flushdns > nul
cls
goto :Zapusk
