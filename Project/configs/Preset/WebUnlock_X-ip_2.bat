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
for %%i in ("%parentDir:~0,-1%") do set "ProjectDir=%%~dpi"
set "GoodbyeZapret_LastStartConfig=%~nx0"

if not defined GoodbyeZapret_LastStartConfig (
  echo ERROR: GoodbyeZapret_LastStartConfig is not set
  pause
)
reg add "HKCU\Software\ALFiX inc.\GoodbyeZapret" /t REG_SZ /v "GoodbyeZapret_LastStartConfig" /d "%GoodbyeZapret_LastStartConfig%" /f >nul

set "CONFIG_NAME=WebUnlock X-ip 2"
set "FAKE=%ProjectDir%bin\fake\"
set "BIN=%ProjectDir%bin\"
set "LISTS=%ProjectDir%lists\"
cd /d "%BIN%"

echo Config: %CONFIG_NAME%
title GoodbyeZapret:   %CONFIG_NAME%
echo.
echo Winws:


start "GoodbyeZapret: %CONFIG_NAME%" /b "%BIN%winws.exe" %YTDB_prog_log%^
--wf-tcp=80,443 --wf-udp=443,50000-65535 ^
--filter-tcp=80,443 --hostlist="%LISTS%netrogat.txt" --new ^
--filter-tcp=443 --ipset="%LISTS%russia-youtube-rtmps.txt" --dpi-desync=syndata --dpi-desync-fake-syndata="%FAKE%tls_clienthello_4.bin" --dpi-desync-fooling=badseq --new ^
--filter-udp=443 --hostlist="%LISTS%youtubeQ.txt" --dpi-desync=fake,udplen --dpi-desync-udplen-increment=4 --dpi-desync-fake-quic="%FAKE%quic_4.bin" --dpi-desync-cutoff=n3 --dpi-desync-repeats=2 --new ^
--filter-tcp=443 --hostlist="%LISTS%youtube.txt" --dpi-desync=multisplit --dpi-desync-split-seqovl=1 --dpi-desync-split-pos=midsld+1 --dpi-desync-split-seqovl-pattern="%FAKE%tls_clienthello_7.bin" --new ^
--filter-tcp=80,443 --hostlist="%LISTS%mycdnlist.txt" --dpi-desync=fakeddisorder --dpi-desync-split-pos=2,midsld --dpi-desync-fakedsplit-pattern="%FAKE%tls_clienthello_1.bin" --dpi-desync-fooling=badseq --new ^
--filter-tcp=443 --hostlist="%LISTS%russia-discord.txt" --dpi-desync=fake --dpi-desync-fooling=badseq --dpi-desync-fake-tls="%FAKE%tls_clienthello_7.bin" --dpi-desync-fake-tls-mod=rnd --new ^
--filter-tcp=80 --dpi-desync=fake,multisplit --dpi-desync-split-seqovl=1 --dpi-desync-split-pos=sld+1 --dpi-desync-fooling=badseq --new ^
--filter-tcp=443 --hostlist-exclude="%LISTS%netrogat.txt" --dpi-desync=fakeddisorder --dpi-desync-split-pos=2,midsld+1 --dpi-desync-fakedsplit-pattern="%FAKE%tls_clienthello_4.bin" --dpi-desync-fooling=badseq --new ^
--filter-udp=443 --hostlist="%LISTS%russia-discord.txt" --dpi-desync=fake,udplen --dpi-desync-udplen-increment=5 --dpi-desync-udplen-pattern=0xDEADBEEF --dpi-desync-fake-quic="%FAKE%quic_2.bin" --dpi-desync-repeats=7 --dpi-desync-cutoff=n2 --new ^
--filter-udp=50000-50099 --filter-l7=discord,stun --dpi-desync=fake --new ^
--filter-tcp=443 --ipset-ip=XXX.XXX.XXX.XXX/XX,XXX.XXX.XXX.XXX/XX --wssize=1:6 --hostlist-domains=googlevideo.com --dpi-desync=multidisorder --dpi-desync-split-seqovl=1 --dpi-desync-split-pos=1,host+2,sld+2,sld+5,sniext+1,sniext+2,endhost-2 --new ^
--filter-tcp=443 --hostlist-domains=googlevideo.com --hostlist="%LISTS%youtube_video-chanel-preview.txt" --dpi-desync=multisplit --dpi-desync-split-seqovl=1 --dpi-desync-split-pos=2,midsld-2 --dpi-desync-split-seqovl-pattern="%FAKE%tls_clienthello_7.bin" --new ^
--filter-tcp=443 --hostlist="%LISTS%list-facebook_instagram.txt" --dpi-desync=split2 --dpi-desync-split-seqovl=652 --dpi-desync-split-pos=2 --dpi-desync-split-seqovl-pattern="%FAKE%tls_clienthello_4.bin" --new ^
--filter-l3=ipv4 --filter-tcp=443 --ipset="%LISTS%ipset-cloudflare3.txt" --ipset-exclude-ip=1.1.1.1,1.0.0.1,212.109.195.93,83.220.169.155,141.105.71.21,18.244.96.0/19,18.244.128.0/19 --dpi-desync=multisplit --dpi-desync-split-seqovl=209 --dpi-desync-split-seqovl-pattern="%FAKE%tls_clienthello_5.bin" --dpi-desync-split-pos=sld+1 --dup=2 --dup-cutoff=n3

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