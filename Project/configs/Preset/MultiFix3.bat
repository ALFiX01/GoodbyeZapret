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
set "GoodbyeZapret_LastStartConfig=%~nx0"

if not defined GoodbyeZapret_LastStartConfig (
  echo ERROR: GoodbyeZapret_LastStartConfig is not set
)

reg add "HKCU\Software\ALFiX inc.\GoodbyeZapret" /t REG_SZ /v "GoodbyeZapret_LastStartConfig" /d "%GoodbyeZapret_LastStartConfig%" /f >nul

set "CONFIG_NAME=MultiFix"

REM Основана на Bolvan
set "FAKE=%ProjectDir%bin\fake\"
set "BIN=%ProjectDir%bin\"
set "LISTS=%ProjectDir%lists\"
cd /d "%BIN%"


echo Config: %CONFIG_NAME%
title GoodbyeZapret:  %CONFIG_NAME%
echo.
echo Winws: %ESC%[90m

REM --wf-raw=@"%BIN%windivert.filter\windivert.discord_media+stun.txt" --filter-udp=50000-50099 --filter-l7=discord,stun --dpi-desync=fake --new ^
REM --filter-l3=ipv4 --filter-udp=50000-50099 --filter-l7=discord,stun --dpi-desync=fake --dpi-desync-fooling=ts --dup-cutoff=n3 --new ^

REM --dpi-desync=fake --dpi-desync-fooling=ts \\\\ --dpi-desync=multidisorder --dpi-desync-split-pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1
REM --dpi-desync=fakedsplit --dpi-desync-fooling=ts --dpi-desync-split-pos=1

REM --filter-tcp=443 --dpi-desync-any-protocol --hostlist-domains=googlevideo.com --hostlist="%LISTS%list-youtube.txt" --dpi-desync=fakedsplit --dpi-desync-fooling=ts --dpi-desync-split-pos=1 --dpi-desync-cutoff=n4 --dpi-desync-repeats=6 --new ^

REM --filter-tcp=80 --hostlist="%LISTS%russia-discord.txt" --dpi-desync=fakedsplit --dpi-desync-fooling=badseq --dpi-desync-split-pos=1 --new ^

:: НЕ ВКЛЮЧАТЬ без надобности - приводит к тормозам соединения или полному отключению обхода! ::
REM set log=--debug=@%~dp0log_debug.txt

start "GoodbyeZapret: %CONFIG_NAME% - discord_media+stun" /b "%BIN%winws.exe" ^
--wf-raw=@"%BIN%windivert.filter\windivert.discord_media+stun.txt" --filter-l7=discord,stun --dpi-desync-any-protocol=1 --dpi-desync=fake --dpi-desync-repeats=6 --dpi-desync-cutoff=n3

REM --filter-tcp=443 --ipset-exclude="%LISTS%russia-youtube.txt" --ipset-exclude="%LISTS%ipset-cloudflare4.txt" --hostlist-exclude="%LISTS%russia-blacklist.txt" --hostlist-exclude="%LISTS%custom-hostlist.txt" --hostlist-exclude="%LISTS%mycdnlist.txt" --dpi-desync=fakedsplit --dpi-desync-ttl=1 --dpi-desync-autottl=-1 --dpi-desync-split-pos=1  --dpi-desync-cutoff=n5 --dpi-desync-repeats=4 --new ^
REM --filter-udp=443 --hostlist-exclude="%LISTS%russia-discord.txt" --dpi-desync=fake,udplen --dpi-desync-fake-quic="%FAKE%fake_quic_3.bin" --dpi-desync-repeats=2 --dpi-desync-cutoff=n4 --new ^
REM --filter-tcp=80 --hostlist-exclude="%LISTS%russia-discord.txt" --hostlist-exclude="%LISTS%russia-blacklist.txt" --hostlist-exclude="%LISTS%custom-hostlist.txt" --hostlist-exclude="%LISTS%mycdnlist.txt" --dpi-desync=fakeddisorder --orig-autottl=+1 --dpi-desync-ttl=1 --dpi-desync-autottl=-3 --dpi-desync-split-pos=method+2 --new ^
REM --filter-tcp=443 --hostlist-exclude="%LISTS%russia-discord.txt" --hostlist-exclude="%LISTS%russia-blacklist.txt" --hostlist-exclude="%LISTS%custom-hostlist.txt" --hostlist-exclude="%LISTS%mycdnlist.txt" --dpi-desync=fakeddisorder --dpi-desync-ttl=2 --dpi-desync-split-pos=midsld --dup-cutoff=n3 --new ^

REM --ipset-exclude="%LISTS%exclude-cloudflare_ip.txt"
start "GoodbyeZapret: %CONFIG_NAME%" /b "%BIN%winws.exe" %log% ^
--wf-tcp=80,443-65535 --wf-udp=443,444-65535 ^
--filter-tcp=80,443 --ipset="%LISTS%netrogat_ip.txt" --new ^
--filter-tcp=80,443 --hostlist="%LISTS%netrogat.txt" --new ^
--filter-tcp=443 --hostlist="%LISTS%list-youtube.txt" --dpi-desync-any-protocol=1 --dpi-desync=fake --dpi-desync-ttl=1 --dpi-desync-autottl=-2 --dpi-desync-fake-tls=0x00000000 --dpi-desync-fake-tls=! --dpi-desync-fake-tls-mod=rnd,rndsni,dupsid --dpi-desync-cutoff=n2 --new ^
--filter-tcp=80 --hostlist="%LISTS%list-youtube.txt" --dpi-desync=syndata --dpi-desync-fake-syndata="%FAKE%http_iana_org.bin" --new ^
--filter-tcp=80 --hostlist="%LISTS%russia-discord.txt" --dpi-desync=fake,multisplit --dpi-desync-ttl=8 --dpi-desync-split-pos=midsld --dpi-desync-fake-http=0x00000000 --dpi-desync-fake-tls=! --new ^
--filter-tcp=443 --hostlist="%LISTS%russia-blacklist.txt" --hostlist="%LISTS%custom-hostlist.txt" --hostlist="%LISTS%mycdnlist.txt" --hostlist-exclude="%LISTS%list-youtube.txt" --dpi-desync-any-protocol=1 --dpi-desync=fakeddisorder --dpi-desync-ttl=2 --dpi-desync-split-pos=midsld --dup-cutoff=n3 --dpi-desync-cutoff=n3 --new ^
--filter-tcp=80 --hostlist="%LISTS%russia-blacklist.txt" --hostlist="%LISTS%custom-hostlist.txt" --hostlist="%LISTS%mycdnlist.txt" --hostlist-exclude="%LISTS%russia-discord.txt" --dpi-desync-any-protocol=1 --dpi-desync=fakeddisorder --orig-autottl=+1 --dpi-desync-ttl=1 --dpi-desync-autottl=-3 --dpi-desync-split-pos=method+2 --dpi-desync-cutoff=n5 --new ^
--filter-tcp=443 --ipset="%LISTS%ipset-cloudflare4.txt" --dpi-desync-any-protocol --dpi-desync=split2 --dpi-desync-split-seqovl=652 --dpi-desync-split-pos=2 --dpi-desync-split-seqovl-pattern="%FAKE%tls_clienthello_www_google_com.bin" --dpi-desync-cutoff=n3 --new ^
--filter-tcp=443 --hostlist-auto="%LISTS%autohostlist.txt" --hostlist-exclude="%LISTS%exclude-autohostlist.txt" --hostlist-auto-fail-threshold=2 --dpi-desync=fakeddisorder --dpi-desync-ttl=2 --dpi-desync-split-pos=midsld --dup-cutoff=n3 --new ^
--filter-tcp=80 --hostlist-auto="%LISTS%autohostlist.txt" --hostlist-exclude="%LISTS%exclude-autohostlist.txt" --hostlist-auto-fail-threshold=2 --dpi-desync-any-protocol=1 --dpi-desync=syndata --dpi-desync-fake-syndata="%FAKE%http_iana_org.bin" --dpi-desync-cutoff=n3

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
