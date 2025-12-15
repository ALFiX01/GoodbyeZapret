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

set "CONFIG_NAME=UltimateFix 2"
set "FAKE=%ProjectDir%bin\fake\"
set "BIN=%ProjectDir%bin\"
set "LISTS=%ProjectDir%lists\"
cd /d "%BIN%"

echo Config: %CONFIG_NAME%
title GoodbyeZapret:  %CONFIG_NAME%
echo.
echo Winws:


start "GoodbyeZapret: %CONFIG_NAME% - discord_media+stun" /b "%BIN%winws2.exe" ^
--wf-tcp-out=80,443 ^
--lua-init=@"%BIN%lua\zapret-lib.lua" --lua-init=@"%BIN%lua\zapret-antidpi.lua" ^
--wf-raw-part=@"%BIN%windivert.filter\windivert_part.discord_media.txt" ^
--wf-raw-part=@"%BIN%windivert.filter\windivert_part.stun.txt" ^
--filter-l7=stun,discord ^
  --out-range=-d10 ^
  --payload=stun_binding_req,discord_ip_discovery ^
   --lua-desync=fake:blob=0x00000000000000000000000000000000:repeats=6

start "GoodbyeZapret: %CONFIG_NAME%" /b "%BIN%winws.exe" %log% ^
--wf-tcp=80,443,2053,2083,2087,2096,8443 --wf-udp=443,444-65535 ^
--filter-tcp=2053,2083,2087,2096,8443 --dpi-desync=rst,multidisorder --dpi-desync-split-pos=3 --dpi-desync-fooling=md5sig,badseq --dpi-desync-cutoff=n5 --new ^
--filter-udp=5056,27002 --dpi-desync-any-protocol=1 --dpi-desync=fake --dpi-desync-repeats=6 --dpi-desync-cutoff=n15 --dpi-desync-fake-unknown-udp="%FAKE%quic_initial_www_google_com.bin" --new ^
--filter-tcp=443 --hostlist="%LISTS%list-youtube.txt" --dpi-desync=fake --dpi-desync-fooling=badseq --dpi-desync-fake-tls="%FAKE%tls_ClientHello_Edge-106_google.com.bin" --dpi-desync-fake-tls-mod=rnd --new ^
--filter-tcp=80 --hostlist="%LISTS%list-discord.txt" --dpi-desync=fake,hostfakesplit --dpi-desync-fooling=md5sig --dup=1 --dup-cutoff=n2 --dup-fooling=md5sig --dpi-desync-hostfakesplit-mod=altorder=1 --dpi-desync-fake-tls="%FAKE%tls_clienthello_312.bin" --dpi-desync-fake-tls-mod=rnd,dupsid,sni=www.google.com --new ^
--filter-tcp=443 --hostlist="%LISTS%list-discord.txt" --dpi-desync-any-protocol=1 --dpi-desync=multisplit --dpi-desync-split-seqovl=228 --dpi-desync-split-seqovl-pattern="%FAKE%fake_tls_2.bin" --dpi-desync-cutoff=n5


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