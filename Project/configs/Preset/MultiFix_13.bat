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

set "CONFIG_NAME=MultiFix 11"

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

start "GoodbyeZapret: %CONFIG_NAME%" /min "%BIN%winws.exe" %log% ^
--wf-tcp=80,443,1080,2053,2083,2087,2096,8443,6568,1024-65535 --wf-udp=443,50000-50090,4 ^
--wf-raw-part=@"%BIN%windivert.filter\windivert_part.stun.txt" --filter-l7=stun --dpi-desync=fake --dpi-desync-fake-discord=0xc80000000114 --dpi-desync-cutoff=n6 --new ^
--wf-raw-part=@"%BIN%windivert.filter\windivert_part.discord_media.txt" --filter-l7=discord --dpi-desync=fake --dpi-desync-fake-quic="%FAKE%quic_initial_www_google_com.bin" --dpi-desync-repeats=6 --new ^
--filter-tcp=80,443 --ipset="%LISTS%netrogat_ip.txt" --ipset="%LISTS%netrogat_ip_custom.txt" --new ^
--filter-tcp=80,443 --hostlist="%LISTS%netrogat.txt" --hostlist="%LISTS%netrogat_custom.txt" --new ^
--filter-udp=443 --hostlist-domains=yt3.ggpht.com --dpi-desync=fake --dpi-desync-fake-quic=0x0c000000 --dpi-desync-fake-quic="%FAKE%fake_quic_2.bin" --dpi-desync-ttl=7 --new ^

--filter-tcp=443 --ipset="%LISTS%russia-youtube-rtmps.txt" --dpi-desync-any-protocol=1 --dpi-desync=fake,multisplit --dpi-desync-split-pos=6,midsld --ip-id=zero --dpi-desync-fake-tls=0x000F000E --dpi-desync-fake-tls-mod=none --dpi-desync-fake-tls="%FAKE%fake_tls_2.bin" --dpi-desync-fake-tls-mod=dupsid --dpi-desync-fooling=ts --dpi-desync-cutoff=n6 --new ^
--filter-udp=443 --hostlist="%LISTS%quick_ttl_site.txt" --dpi-desync=fake,udplen --dpi-desync-udplen-increment=8 --dpi-desync-udplen-pattern=0x0F0F0E0F --dpi-desync-fake-quic="%FAKE%fake_quic_1.bin"  --dpi-desync-repeats=2 --dpi-desync-ttl=6 --dpi-desync-cutoff=n4 --new ^

--filter-udp=443 --hostlist-exclude="%LISTS%russia-discord.txt" --dpi-desync=fake --dpi-desync-repeats=6 --dpi-desync-fake-quic="%FAKE%quic_initial_www_google_com.bin" --new ^
--filter-tcp=80 --dpi-desync=fake,fakedsplit --dpi-desync-fake-http=0x0F0F0F0F --dpi-desync-split-pos=1,sld+1 --dpi-desync-fakedsplit-pattern="%FAKE%fake_tls_2.bin" --dpi-desync-fakedsplit-mod=altorder=0 --dpi-desync-fooling=ts --dpi-desync-cutoff=n5 --new ^
--filter-tcp=80,443 --hostlist="%LISTS%russia-discord.txt" --dpi-desync=fake --dpi-desync-repeats=6 --dpi-desync-fooling=ts --dpi-desync-fake-tls=^! --dpi-desync-fake-tls-mod=rnd,sni=www.google.com --dpi-desync-fake-tls="%FAKE%tls_clienthello_4pda_to.bin" --dpi-desync-fake-tls-mod=none --new ^

--filter-tcp=80,443 --hostlist="%LISTS%russia-blacklist.txt" --hostlist="%LISTS%custom-hostlist.txt" --hostlist="%LISTS%mycdnlist.txt" --hostlist-exclude="%LISTS%list-youtube.txt" --dpi-desync=fake --dpi-desync-repeats=6 --dpi-desync-fooling=ts --dpi-desync-fake-tls=^! --dpi-desync-fake-tls-mod=rnd,sni=www.google.com --dpi-desync-fake-tls="%FAKE%tls_clienthello_4pda_to.bin" --dpi-desync-fake-tls-mod=none --new ^

--filter-tcp=80,443 --hostlist="%LISTS%russia-youtube2.txt" --dpi-desync=fake,multisplit --dpi-desync-split-pos=6,midsld --ip-id=zero --dpi-desync-fake-tls-mod=dupsid,sni=www.google.com --dpi-desync-fooling=ts --dpi-desync-cutoff=n6 --new ^

--filter-tcp=443 --hostlist="%LISTS%anomaly_site.txt" --dpi-desync=fake,fakedsplit --dpi-desync-split-pos=2,endsld-2 --dpi-desync-fake-tls-mod=rnd,sni=fonts.google.com --dpi-desync-fakedsplit-pattern="%FAKE%fake_tls_3.bin" --dpi-desync-fakedsplit-mod=altorder=3 --ip-id=zero --dpi-desync-fooling=ts,badsum --dpi-desync-cutoff=n6 --new ^
--filter-tcp=443 --filter-l7=tls --hostlist-exclude="%LISTS%autohostlist.txt" --dpi-desync=fake,multisplit --ip-id=seqgroup --dpi-desync-fake-tls-mod=dupsid,rnd,sni=download.max.ru --dpi-desync-split-pos=6 --dpi-desync-split-seqovl=315 --dpi-desync-split-seqovl-pattern="%FAKE%fake_tls_11.bin" --dpi-desync-fooling=badseq,ts --dpi-desync-badseq-increment=3 --dpi-desync-badack-increment=21 --dpi-desync-cutoff=n6 --new ^

--filter-tcp=80,443-65535 --ipset="%LISTS%ipset-cloudflare-%CDN_BypassLevel%.txt" --ipset-exclude="%LISTS%ipset-dns.txt" --dpi-desync-any-protocol=1 --dpi-desync=fake,fakedsplit --dpi-desync-split-pos=2,endsld-2 --dpi-desync-fake-tls-mod=rnd,sni=fonts.google.com --dpi-desync-fakedsplit-pattern="%FAKE%fake_tls_3.bin" --dpi-desync-fakedsplit-mod=altorder=3 --ip-id=zero --dpi-desync-fooling=ts,badsum --dpi-desync-cutoff=n6 --new ^
--filter-udp=443,1024-65535 --ipset="%LISTS%ipset-cloudflare-%CDN_BypassLevel%.txt" --dpi-desync=fake --dpi-desync-fake-quic=0x0c000000 --dpi-desync-fake-quic="%FAKE%fake_quic_2.bin" --dpi-desync-ttl=5 --new ^

--filter-tcp=1080,2053,2083,2087,2096,8443 --hostlist-domains=discord.media --dpi-desync=rst,multidisorder --dpi-desync-split-pos=3 --dpi-desync-fooling=md5sig,badseq --dpi-desync-cutoff=n4 --new ^
--filter-tcp=443 --hostlist-auto="%LISTS%autohostlist.txt" --hostlist-exclude="%LISTS%exclude-autohostlist.txt" --hostlist-auto-retrans-threshold=5 --dpi-desync=fake,multisplit --ip-id=seqgroup --dpi-desync-fake-tls-mod=dupsid,sni=max.ru --dpi-desync-split-pos=6 --dpi-desync-split-seqovl=226 --dpi-desync-split-seqovl-pattern="%FAKE%fake_tls_10.bin" --dpi-desync-fooling=ts,badsum --dpi-desync-cutoff=n6


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
