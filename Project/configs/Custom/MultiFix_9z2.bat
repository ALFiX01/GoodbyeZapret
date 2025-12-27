@echo off
chcp 65001 >nul

goto :Preparing
:Zapusk
cls

for /f %%a in ('echo prompt $E^| cmd') do set "ESC=%%a"

echo                         %ESC%[96m______                ____            _____                         __ 
echo                        / ____/___  ____  ____/ / /_  __  ____/__  /  ____ _____  ________  / /_
echo                       / / __/ __ \/ __ \/ __  / __ \/ / / / _ \/ /  / __ `/ __ \/ ___/ _ \/ __/
echo                      / /_/ / /_/ / /_/ / /_/ / /_/ / /_/ /  __/ /__/ /_/ / /_/ / /  /  __/ /_ 
echo                      \____/\____/\____/\__,_/_.___/\__, /\___/____/\__,_/ .___/_/   \___/\__/
echo                                                   /____/               /_/


set "currentDir=%~dp0"
set "currentDir=%currentDir:~0,-1%"
for %%i in ("%currentDir%") do set "parentDir=%%~dpi"
for %%i in ("%parentDir:~0,-1%") do set "ProjectDir=%%~dpi"
REM set "GoodbyeZapret_LastStartConfig=%~nx0"

set "CONFIG_NAME=MultiFix 9 z2"

set "FAKE=%ProjectDir%bin\fake\"
set "BIN=%ProjectDir%bin\"
set "LISTS=%ProjectDir%lists\"
cd /d "%BIN%"


echo Config: %CONFIG_NAME%
title GoodbyeZapret:  %CONFIG_NAME%
echo.
echo Winws: %ESC%[90m

:: НЕ ВКЛЮЧАТЬ без надобности - приводит к тормозам соединения или полному отключению обхода! Включить - дебаг-лог убрав rem и выключить, добавив rem ::
REM set log=--debug=@%~dp0log_debug.txt

:: Уровень обхода для CDN (Cloudflare, Fastly, Amazon и др.): off / min / base / full / full_ext
:: Режимы отличаются количеством обрабатываемых IP-адресов (чем выше уровень, тем шире список).
if not defined CDN_BypassLevel set "CDN_BypassLevel=base"

start "GoodbyeZapret: %CONFIG_NAME%" /b "%BIN%winws2.exe" ^
--wf-tcp-out=80,443,2053,2083,2087,2096,6568,8443 ^
--wf-udp-out=443,1024-65535 ^
--wf-raw-part=@"%BIN%windivert.filter\windivert_part.discord_media.txt" ^
--wf-raw-part=@"%BIN%windivert.filter\windivert_part.stun.txt" ^
--lua-init=@"%BIN%lua\zapret-lib.lua" ^
--lua-init=@"%BIN%lua\zapret-auto.lua" ^
--lua-init=@"%BIN%lua\zapret-antidpi.lua" ^
--blob=tls_clienthello_312:@"%FAKE%tls_clienthello_312.bin" ^
--blob=fake_tls_2:@"%FAKE%fake_tls_2.bin" ^
--blob=fake_tls_3:@"%FAKE%fake_tls_3.bin" ^
--blob=fake_tls_4:@"%FAKE%fake_tls_4.bin" ^
--blob=tls_clienthello_max_ru:@"%FAKE%tls_clienthello_max_ru.bin" ^
--blob=fake_quic_1:@"%FAKE%fake_quic_1.bin" ^
--blob=fake_quic_3:@"%FAKE%fake_quic_3.bin" ^
--blob=quic_initial_www_google_com:@"%FAKE%quic_initial_www_google_com.bin" ^
--blob=tls_www_google:@"%FAKE%tls_clienthello_www_google_com.bin" --new ^
--blob=tls_clienthello_5:@"%FAKE%tls_clienthello_5.bin" ^
--filter-tcp=80,443 --ipset="%LISTS%netrogat_ip.txt" --ipset="%LISTS%netrogat_ip_custom.txt" --new ^
--filter-tcp=80,443 -hostlist="%LISTS%netrogat.txt" --hostlist="%LISTS%netrogat_custom.txt" --new ^
--filter-tcp=443,2053,2083,2087,2096,8443 --hostlist="%LISTS%list-discord.txt" --payload tls_client_hello --lua-desync=multidisorder:pos=host+1 --new ^
--filter-udp=443 --filter-l7=quic --hostlist="%LISTS%list-quick_ttl.txt" --out-range=-n3 --payload=quic_initial --lua-desync=fake:blob=fake_quic_3.bin:udp_ttl=7:repeats=2 --lua-desync=udplen:pattern=0x0F0F0E0F:repeats=2 --new ^
--filter-tcp=443 --filter-l7=unknown --hostlist="%LISTS%russia-youtube-rtmps.txt" --out-range=-n3 --payload=tls_client_hello --lua-desync=multisplit:seqovl_pattern=fake_tls_2:seqovl=228 --new ^
--filter-udp=443 --hostlist-domains=yt3.ggpht.com,www.youtube.com,signaler-pa.youtube.com --out-range=-d9 --payload=quic_initial --lua-desync=fake:blob=0x0c000000:blob=fake_quic_1:ip_ttl=6 --new ^
--filter-tcp=443 --filter-l7=tls --hostlist="%LISTS%list-youtube.txt" --out-range=-n5 --payload=tls_client_hello --lua-desync=fake:blob=0x0F0F0F0F:tcp_ack=-66000:tcp_ts_up --lua-desync=fake:blob=tls_clienthello_max_ru:tcp_ack=-66000:tcp_ts_up:tls_mod=rnd,dupsid,rndsni,sni=fonts.google.com --lua-desync=multidisorder:pos=5,sld+1 --new ^
--filter-tcp=443,444-65535 --hostlist-domains=awsglobalaccelerator.com,cloudfront.net,amazon.com,amazonaws.com,awsstatic.com,epicgames.com --out-range=-n5 --payload=tls_client_hello --lua-desync=fake:blob=0x1603:tls_mod=rnd,dupsid,sni=fonts.google.com --lua-desync=fake:blob=tls_www_google:tls_mod=rnd,dupsid,sni=fonts.google.com --lua-desync=multisplit:seqovl_pattern=fake_tls_4:pos=1:seqovl=314 --new ^
--filter-tcp=443 --ipset="%LISTS%ipset-cloudflare-%CDN_BypassLevel%.txt" --out-range=-n5 --payload=tls_client_hello --lua-desync=fake:blob=0x0F0F0F0F:tcp_ack=-66000:tcp_ts_up --lua-desync=fake:blob=fake_tls_3:tcp_ack=-66000:tcp_ts_up:tls_mod=rnd,dupsid,rndsni,sni=fonts.google.com --lua-desync=multidisorder:pos=1,sld+1 --new ^
--filter-udp=443,444-65535 --ipset="%LISTS%ipset-cloudflare-%CDN_BypassLevel%.txt" --out-range=-n5 --payload=quic_initial --lua-desync=fake:blob=quic_initial_www_google_com:repeats=6 --new ^
--filter-tcp=443,444-65535 --hostlist-domains=awsglobalaccelerator.com,cloudfront.net,amazon.com,amazonaws.com,awsstatic.com,epicgames.com --out-range=-n5 --payload=http_req --lua-desync=fake:blob=0x1603:blob=!+2:tls_mod=rnd,dupsid,sni=fonts.google.com:ip_id=seq --lua-desync=fakedsplit:pos=method+2:tcp_ack=-66000:tcp_ts_up --lua-desync=multisplit:seqovl_pattern=fake_tls_4:pos=1 --new ^
--filter-tcp=80 --filter-l7=http --out-range=-n4 --payload=http_req --lua-desync=fake:blob=0x0F0F0F0F:http=1:tcp_ts=1 --lua-desync=fakedsplit:pos=1,sld+1:altorder=0 --new ^
--filter-tcp=2053,2083,2087,2096,8443 --filter-l7=tls --out-range=-n5 --payload=tls_client_hello --lua-desync=rst:tcp_md5sig=1:tcp_seq=-10000:tcp_ack=-66000 --lua-desync=multidisorder:pos=3:tcp_md5sig=1:tcp_seq=-10000:tcp_ack=-66000 --new ^
--filter-udp=5056,27002 --out-range=-n15 --payload=quic_initial --lua-desync=fake:blob=@quic_initial_www_google_com.bin:repeats=6 --new ^
--filter-tcp=80,443,6568 --ipset="%LISTS%ipset-anydesk.txt" --out-range=-d10 --lua-desync=multisplit:seqovl=211:seqovl_pattern=tls_clienthello_5 --new ^
--filter-l7=stun,discord --out-range=-d10 --payload=stun,discord_ip_discovery --lua-desync=fake:blob=0x00:repeats=5


REM --filter-tcp=80 --hostlist="%LISTS%list-discord.txt" --dpi-desync=fake,hostfakesplit --dpi-desync-fooling=md5sig --dup=1 --dup-cutoff=n2 --dup-fooling=md5sig --dpi-desync-hostfakesplit-mod=altorder=1 --dpi-desync-fake-tls="%FAKE%tls_clienthello_312.bin" --dpi-desync-fake-tls-mod=rnd,dupsid,sni=www.google.com --new ^
REM --filter-tcp=443 --hostlist="%LISTS%list-discord.txt" --dpi-desync=multisplit --dpi-desync-split-seqovl=228 --dpi-desync-split-seqovl-pattern="%FAKE%fake_tls_2.bin" --dpi-desync-cutoff=n5 --new ^


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
