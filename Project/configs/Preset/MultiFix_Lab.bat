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

set "CONFIG_NAME=UltimateFix Lab"
set "FAKE=%ProjectDir%bin\fake\"
set "BIN=%ProjectDir%bin\"
set "LISTS=%ProjectDir%lists\"
cd /d "%BIN%"

:: YT (Вы можете выбрать один из вариантов просто закомментировав остальные) (REM в начале строки - значит стратегия не используется) 586.bin
set YTGV=--dpi-desync=multisplit --dpi-desync-split-seqovl=228 --dpi-desync-split-seqovl-pattern="%FAKE%tls_clienthello_312.bin"
REM set YTGV=--dpi-desync=multisplit --dpi-desync-split-pos=10,midsld --dpi-desync-split-seqovl=1
REM set YTGV=--dpi-desync=fake --dpi-desync-fooling=badseq --dpi-desync-fake-tls="%FAKE%tls_ClientHello_Edge-85_google.com.bin" --dpi-desync-fake-tls-mod=rnd
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
set YTCHP=--dpi-desync=fake,multisplit --dpi-desync-split-pos=sld+1 --dpi-desync-fake-tls=0x0F0F0E0F --dpi-desync-fake-tls="%FAKE%tls_ClientHello_Edge-106_google.com.bin" --dpi-desync-fake-tls-mod=rnd,dupsid --dpi-desync-fooling=md5sig --dpi-desync-autottl --dup=2 --dup-fooling=md5sig --dup-autottl --dup-cutoff=n3

REM --filter-udp=443 --hostlist="%LISTS%russia-youtubeQ.txt" --dpi-desync=fake,udplen --dpi-desync-udplen-increment=8 --dpi-desync-udplen-pattern=0xFEA82025 --dpi-desync-fake-quic="%FAKE%quic_Initial_fonts_google_com.bin" --dpi-desync-cutoff=n4 --dpi-desync-repeats=2 --new ^

echo Config: %CONFIG_NAME%
title GoodbyeZapret:  %CONFIG_NAME%
echo.
echo Winws:

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
--filter-tcp=443 --ipset="%LISTS%russia-youtube-rtmps.txt" --dpi-desync=syndata --dpi-desync-fake-syndata="%FAKE%syn_packet.bin" --dup=2 --dup-cutoff=n3 --new ^
--filter-tcp=443 --hostlist="%LISTS%list-facebook_instagram.txt" --dpi-desync=fake,multisplit --dpi-desync-fake-tls=0x0F0F0E0F --dpi-desync-fake-tls="%FAKE%tls_clienthello_16.bin" --dpi-desync-fake-tls-mod=rnd,dupsid --dpi-desync-fooling=md5sig --dpi-desync-split-pos=sld+1 --dpi-desync-autottl --dup=2 --dup-fooling=md5sig --dup-autottl --dup-cutoff=n3 --new ^
--filter-tcp=443 --hostlist="%LISTS%russia-blacklist.txt" --hostlist="%LISTS%custom-hostlist.txt" --hostlist="%LISTS%mycdnlist.txt" --dpi-desync=fake,multidisorder --dpi-desync-split-pos=sld+1 --dpi-desync-fake-tls=0x0F0F0E0F --dpi-desync-fake-tls="%FAKE%tls_clienthello_16.bin" --dpi-desync-fake-tls-mod=rnd,dupsid --dpi-desync-fooling=md5sig --dpi-desync-autottl --dup=2 --dup-fooling=md5sig --dup-autottl --dup-cutoff=n3 --new ^
--filter-tcp=80 --hostlist="%LISTS%russia-blacklist.txt" --hostlist="%LISTS%custom-hostlist.txt" --hostlist="%LISTS%mycdnlist.txt" --dpi-desync=fake,multisplit --dpi-desync-split-seqovl=2 --dpi-desync-split-pos=sld+1 --dpi-desync-fake-http="%FAKE%http_fake_MS.bin" --dpi-desync-fooling=md5sig --dup=2 --dup-fooling=md5sig --dup-cutoff=n3 --new ^
--filter-tcp=80,443,2053,2083,2087,2096,8443 --hostlist="%LISTS%list-discord.txt" --dpi-desync=multisplit --dpi-desync-split-seqovl=293 --dpi-desync-split-seqovl-pattern="%FAKE%tls_clienthello_12.bin" --new ^
--filter-l7=discord,stun --dpi-desync-any-protocol=1 --dpi-desync=fake --dpi-desync-repeats=5 --dpi-desync-cutoff=n4
--filter-tcp=443 --hostlist-domains=googlevideo.com --hostlist="%LISTS%russia-youtube.txt" %YTGV% --new ^
--filter-tcp=443 --hostlist-domains=googlevideo.com --hostlist="%LISTS%youtube_video-chanel-preview.txt" %YTCHP% --new ^
--filter-tcp=443,444-65535 --hostlist-domains=awsglobalaccelerator.com,cloudfront.net,amazon.com,amazonaws.com,awsstatic.com,epicgames.com --dpi-desync=multisplit --dpi-desync-split-seqovl=681 --dpi-desync-split-pos=1 --dpi-desync-fooling=badseq,hopbyhop2 --dpi-desync-split-seqovl-pattern="%FAKE%tls_clienthello_www_google_com.bin" --new ^
--filter-tcp=80,443-65535 --ipset="%LISTS%ipset-cloudflare-%CDN_BypassLevel%.txt" --ipset-exclude="%LISTS%ipset-dns.txt" --dpi-desync=multisplit --dpi-desync-split-seqovl=286 --dpi-desync-split-seqovl-pattern="%FAKE%tls_clienthello_11.bin" --dup=2 --dup-cutoff=n3 --new ^
--filter-udp=443,444-65535 --ipset="%LISTS%ipset-cloudflare-%CDN_BypassLevel%.txt" --dpi-desync=fake --dpi-desync-repeats=6 --dpi-desync-fake-quic="%FAKE%quic_initial_www_google_com.bin" --new ^
--filter-tcp=80 --hostlist-auto="%LISTS%autohostlist.txt" --hostlist-exclude="%LISTS%exclude-autohostlist.txt" --hostlist-auto-fail-threshold=2 --dpi-desync=fake,multisplit --dpi-desync-split-seqovl=2 --dpi-desync-split-pos=host+1 --dpi-desync-fake-http=0x0E0E0F0E --dpi-desync-fooling=md5sig --new ^
--filter-tcp=443 --hostlist-auto="%LISTS%autohostlist.txt" --hostlist-exclude="%LISTS%exclude-autohostlist.txt" --hostlist-auto-fail-threshold=2 --dpi-desync=fake,fakedsplit --dpi-desync-split-pos=1 --dpi-desync-fake-tls="%FAKE%tls_clienthello_9.bin" --dpi-desync-fooling=badseq --dpi-desync-autottl

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
