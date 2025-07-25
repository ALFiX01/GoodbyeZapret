@echo off
chcp 65001 >nul

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

set currentDir=%~dp0
set currentDir=%currentDir:~0,-1%
for %%i in ("%currentDir%") do set parentDir=%%~dpi
for %%i in ("%parentDir:~0,-1%") do set ProjectDir=%%~dpi
reg add "HKCU\Software\ALFiX inc.\GoodbyeZapret" /t REG_SZ /v "GoodbyeZapret_LastStartConfig" /d "%~nx0" /f >nul

set "CONFIG_NAME=GoodbyeZapret: UltimateFix Amaizing Amazon"
set "FAKE=%ProjectDir%bin\fake\"
set "BIN=%ProjectDir%bin\"
set "LISTS=%ProjectDir%lists\"
cd /d "%BIN%"

REM Config settings

set YTDB_UDP_Repeats=2
set YTDB_Cutoff_Limit=3
set YTDB_TTL_Limit=7

REM Config Start
start "%CONFIG_NAME%" /min "%BIN%winws.exe" ^
--wf-tcp=80,443,444-65535 --wf-udp=443,444-65535 --new ^
--filter-tcp=80,443 --hostlist="%LISTS%netrogat.txt" --new ^
--filter-udp=443 --hostlist="%LISTS%russia-youtubeQ.txt" --dpi-desync=fake,udplen --dpi-desync-udplen-increment=8 --dpi-desync-udplen-pattern=0x0F0F0E0F --dpi-desync-fake-quic="%FAKE%quic_6.bin" --dpi-desync-cutoff=n3 --dpi-desync-repeats=2 --new ^
--filter-tcp=443 --hostlist-domains=googlevideo.com --hostlist="%LISTS%russia-youtube.txt" --dpi-desync=multisplit --dpi-desync-split-seqovl=1 --dpi-desync-split-pos=sld+1 --new ^
--filter-tcp=443 --hostlist-domains=ntc.party --hostlist="%LISTS%russia-discord.txt" --dpi-desync=multisplit --dpi-desync-split-seqovl=209 --dpi-desync-split-seqovl-pattern="%FAKE%tls_clienthello_5.bin" --dpi-desync-split-pos=sld+1 --dup=2 --dup-cutoff=n3 --new ^
--filter-tcp=443 --hostlist-domains=updates.discord.com, stable.dl2.discordapp.net, getchu.com, rutracker.org, static.rutracker.cc --dpi-desync=multisplit --dpi-desync-split-seqovl=318 --dpi-desync-split-seqovl-pattern="%FAKE%tls_clienthello_15.bin" --new ^
--filter-tcp=80 --hostlist-domains=amazon.com,amazonaws.com,awsstatic.com,epicgames.com --dpi-desync=fake,multisplit --dpi-desync-split-seqovl=2 --dpi-desync-split-pos=sld+1 --dpi-desync-fake-http=0x0F0F0E0F --dpi-desync-fooling=md5sig --dup=2 --dup-fooling=md5sig --dup-cutoff=n3 --new ^
--filter-tcp=80 --ipset="%LISTS%ipset-cloudflare2.txt" --ipset-exclude-ip=1.1.1.1,1.0.0.1,212.109.195.93,83.220.169.155,141.105.71.21,18.244.96.0/19,18.244.128.0/19 --dpi-desync=fake,multisplit --dpi-desync-split-seqovl=2 --dpi-desync-split-pos=sld+1 --dpi-desync-fake-http=0x0F0F0E0F --dpi-desync-fooling=md5sig --dup=2 --dup-fooling=md5sig --dup-cutoff=n3 --new ^
--filter-tcp=443,444-65535 --hostlist-domains=amazon.com,amazonaws.com,awsstatic.com,epicgames.com --dpi-desync=multisplit --dpi-desync-split-seqovl=211 --dpi-desync-split-pos=sld+2 --dpi-desync-split-seqovl-pattern="%FAKE%tls_clienthello_5.bin" --new ^
--filter-tcp=443,444-65535 --ipset="%LISTS%ipset-cloudflare2.txt" --ipset-exclude-ip=1.1.1.1,1.0.0.1,212.109.195.93,83.220.169.155,141.105.71.21,18.244.96.0/19,18.244.128.0/19 --dpi-desync=multisplit --dpi-desync-split-seqovl=211 --dpi-desync-split-pos=sld+2 --dpi-desync-split-seqovl-pattern="%FAKE%tls_clienthello_5.bin" --new ^
--filter-udp=443,444-65535 --ipset="%LISTS%ipset-cloudflare2.txt" --ipset-exclude-ip=1.1.1.1,1.0.0.1,212.109.195.93,83.220.169.155,141.105.71.21,18.244.96.0/19,18.244.128.0/19 --dpi-desync=fake --dpi-desync-any-protocol --dpi-desync-fake-unknown-udp="%FAKE%quic_6.bin" --dpi-desync-repeats=%YTDB_UDP_Repeats% --dpi-desync-cutoff=n%YTDB_Cutoff_Limit% --dpi-desync-ttl=%YTDB_TTL_Limit% --new ^
--filter-l3=ipv4 --filter-tcp=443 --ipset="%LISTS%ipset-cloudflare2.txt" --ipset-exclude-ip=1.1.1.1, 1.0.0.1, 212.109.195.93, 83.220.169.155, 141.105.71.21, 18.244.96.0/19, 18.244.128.0/19 --dpi-desync=multisplit --dpi-desync-split-seqovl=209 --dpi-desync-split-seqovl-pattern="%FAKE%tls_clienthello_5.bin" --dpi-desync-split-pos=sld+1 --dup=2 --dup-cutoff=n3 --new ^
exit /b
