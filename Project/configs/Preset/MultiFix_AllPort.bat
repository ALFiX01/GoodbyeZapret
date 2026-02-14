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

set "CONFIG_NAME=UltimateFix AllPort"

REM Основана на Bolvan
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

:: Уровень обхода для CDN (Cloudflare, Fastly, Amazon и др.): off / min / base / full / full_ext
:: Режимы отличаются количеством обрабатываемых IP-адресов (чем выше уровень, тем шире список).
if not defined CDN_BypassLevel set "CDN_BypassLevel=base"
if not defined tcp_ports set "tcp_ports=80,443,4950-4955,6695-6705,444-65535"
if not defined udp_ports set "udp_ports=80,443,50000-50099"

start "GoodbyeZapret: %CONFIG_NAME%" /min "%BIN%winws.exe" %log% ^
--wf-l3=ipv4,ipv6 --wf-tcp=%tcp_ports% --wf-udp=%udp_ports% ^
--wf-raw-part=@"%BIN%windivert.filter\windivert_part.stun.txt" ^
--wf-raw-part=@"%BIN%windivert.filter\windivert_part.discord_media.txt" ^
--filter-tcp=80,443 --ipset="%LISTS%netrogat_ip.txt" --ipset="%LISTS%netrogat_ip_custom.txt"  --new ^
--filter-tcp=80,443 --hostlist="%LISTS%netrogat.txt" --hostlist="%LISTS%netrogat_custom.txt" --new ^
--filter-l7=discord,stun --dpi-desync=multidisorder --dpi-desync-split-pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1
--filter-tcp=80 --dpi-desync=fake,fakedsplit --dpi-desync-fakedsplit-mod=altorder=2 --dpi-desync-autottl=2 --dpi-desync-fooling=md5sig --new ^
--filter-tcp=443 --hostlist-domains=googlevideo.com --hostlist="%LISTS%list-youtube.txt" --dpi-desync=multidisorder --dpi-desync-split-pos=1,midsld --new ^
--filter-tcp=4950-4955 --dpi-desync=fake,multidisorder --dpi-desync-split-pos=midsld --dpi-desync-repeats=8 --dpi-desync-fooling=md5sig,badseq --new ^
--filter-tcp=6695-6705 --dpi-desync=fake,multisplit --dpi-desync-repeats=8 --dpi-desync-fooling=md5sig --dpi-desync-autottl=2 --dpi-desync-fake-tls="%FAKE%tls_clienthello_www_google_com.bin" --new ^
--filter-tcp=80,443,1080,2053,2083,2087,2096,8443 --ipset="%LISTS%ipset-discord.txt" --dpi-desync=fake,multisplit --dpi-desync-split-seqovl=664 --dpi-desync-split-pos=1 --dpi-desync-fooling=ts --dpi-desync-repeats=8 --dpi-desync-split-seqovl-pattern="%FAKE%tls_clienthello_max_ru.bin" --dpi-desync-fake-tls="%FAKE%tls_clienthello_max_ru.bin" --new ^
--filter-udp=443 --dpi-desync=fake --dpi-desync-repeats=11 --new ^
--filter-tcp=443,444-65535 --hostlist-domains=awsglobalaccelerator.com,cloudfront.net,amazon.com,amazonaws.com,awsstatic.com,epicgames.com --dpi-desync=multisplit --dpi-desync-split-seqovl=681 --dpi-desync-split-pos=1 --dpi-desync-fooling=badseq,hopbyhop2 --dpi-desync-split-seqovl-pattern="%FAKE%tls_clienthello_www_google_com.bin" --new ^
--filter-udp=443,444-65535 --ipset="%LISTS%ipset-cloudflare-%CDN_BypassLevel%.txt" --dpi-desync=fake --dpi-desync-repeats=6 --dpi-desync-fake-quic="%FAKE%quic_initial_www_google_com.bin" --new ^
--filter-tcp=80 --ipset="%LISTS%ipset-cloudflare-%CDN_BypassLevel%.txt" --ipset-exclude="%LISTS%ipset-dns.txt" --dpi-desync=fake,multisplit --dpi-desync-autottl=2 --dpi-desync-fooling=md5sig --new ^
--filter-tcp=80,443-65535 --ipset="%LISTS%ipset-cloudflare-%CDN_BypassLevel%.txt" --ipset-exclude="%LISTS%ipset-dns.txt" --dpi-desync=multisplit --dpi-desync-split-seqovl=652 --dpi-desync-split-pos=2 --dpi-desync-split-seqovl-pattern="%FAKE%tls_clienthello_www_google_com.bin"

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
