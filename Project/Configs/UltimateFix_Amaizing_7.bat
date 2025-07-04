@echo off
chcp 65001 >nul

goto :Preparing
:Zapusk

set "currentDir=%~dp0"
set "currentDir=%currentDir:~0,-1%"
for %%i in ("%currentDir%") do set "parentDir=%%~dpi"
reg add "HKCU\Software\ALFiX inc.\GoodbyeZapret" /t REG_SZ /v "GoodbyeZapret_LastStartConfig" /d "%~nx0" /f >nul

set "CONFIG_NAME=GoodbyeZapret: UltimateFix Amaizing 7"
set "FAKE=%parentDir%bin\fake\"
set "BIN=%parentDir%bin\"
set "LISTS=%parentDir%lists\"
cd /d "%BIN%"
REM BEST
REM --filter-udp=443 --hostlist="%LISTS%youtubeQ.txt" --dpi-desync=fake,fakeddisorder --dpi-desync-ttl=1 --dpi-desync-autottl=4 --dpi-desync-split-pos=method+2 --dpi-desync-fake-http=0x00000000 --new ^

REM --filter-tcp=443 --hostlist="%LISTS%russia-blacklist.txt" --hostlist="%LISTS%custom-hostlist.txt" --hostlist="%LISTS%mycdnlist.txt" --dpi-desync=fake,multidisorder --dpi-desync-split-pos=sld+1 --dpi-desync-fake-tls=0x0F0F0E0F --dpi-desync-fake-tls="%FAKE%tls_clienthello_15.bin" --dpi-desync-fake-tls-mod=rnd,dupsid --dpi-desync-fooling=md5sig --dpi-desync-autottl --dup=2 --dup-fooling=md5sig --dup-autottl --dup-cutoff=n3 --new ^
REM --filter-tcp=443 --ipset="%LISTS%russia-youtube-rtmps.txt" --dpi-desync=syndata --dpi-desync-fake-syndata="%FAKE%tls_clienthello_7.bin" --dup=2 --dup-cutoff=n3 --new ^
REM --filter-tcp=443 --ipset="%LISTS%russia-youtube-rtmps.txt" --dpi-desync=syndata --dpi-desync-fake-syndata="%FAKE%syn_packet.bin" --dup=2 --dup-cutoff=n3 --new ^
REM --filter-tcp=443 --ipset="%LISTS%russia-youtube-rtmps.txt" --dpi-desync=syndata --dpi-desync-fake-syndata="%FAKE%syn_packet_test.bin" --dup=2 --dup-cutoff=n3 --new ^
REM --filter-l3=ipv4 --filter-tcp=443 --hostlist="%LISTS%russia-discord.txt" --dpi-desync=fakedsplit --dpi-desync-split-pos=1 --dpi-desync-fooling=badseq --dpi-desync-repeats=6 --dpi-desync-autottl --new ^
REM --filter-tcp=80 --hostlist="%LISTS%youtube_video-preview.txt" --dpi-desync=fake,fakedsplit --dpi-desync-fooling=md5sig --dup=1 --dup-cutoff=n2 --dup-fooling=md5sig --dpi-desync-split-pos=method+2 --new ^
REM --wf-tcp=80,443 --wf-udp=443,50000-50099 ^

start "%CONFIG_NAME%" /min "%BIN%winws.exe" ^
--wf-tcp=80,443,1024-65535 --wf-udp=443,50000-50099,1024-65535 ^
--filter-l3=ipv4 --filter-tcp=80,443 --hostlist="%LISTS%netrogat.txt" --new ^
--filter-l3=ipv4 --filter-udp=50000-50099 --filter-l7=discord,stun --dpi-desync=fake,fakeddisorder --dpi-desync-fooling=datanoack --dpi-desync-autottl --dup=2 --dup-autottl --dup-cutoff=n3 --new ^
--filter-tcp=443 --ipset="%LISTS%russia-youtube-rtmps.txt" --dpi-desync=syndata --dpi-desync-fake-syndata="%FAKE%syn_packet.bin" --dup=2 --dup-cutoff=n3 --new ^
--filter-tcp=443 --hostlist="%LISTS%faceinsta.txt" --dpi-desync=fake,multisplit --dpi-desync-fake-tls=0x0F0F0E0F --dpi-desync-fake-tls="%FAKE%tls_clienthello_16.bin" --dpi-desync-fake-tls-mod=rnd,dupsid --dpi-desync-fooling=md5sig --dpi-desync-split-pos=sld+1 --dpi-desync-autottl --dup=2 --dup-fooling=md5sig --dup-autottl --dup-cutoff=n3 --new ^
--filter-udp=443 --hostlist="%LISTS%youtubeQ.txt" --dpi-desync=fake,udplen --dpi-desync-udplen-increment=8 --dpi-desync-udplen-pattern=0xFEA82025 --dpi-desync-fake-quic="%FAKE%quic_4.bin" --dpi-desync-cutoff=n4 --dpi-desync-repeats=2 --new ^
--filter-tcp=443 --hostlist="%LISTS%russia-blacklist.txt" --hostlist="%LISTS%custom-hostlist.txt" --hostlist="%LISTS%mycdnlist.txt" --dpi-desync=fake,multidisorder --dpi-desync-split-pos=sld+1 --dpi-desync-fake-tls=0x0F0F0E0F --dpi-desync-fake-tls="%FAKE%tls_clienthello_16.bin" --dpi-desync-fake-tls-mod=rnd,dupsid --dpi-desync-fooling=md5sig --dpi-desync-autottl --dup=2 --dup-fooling=md5sig --dup-autottl --dup-cutoff=n3 --new ^
--filter-tcp=80 --hostlist="%LISTS%russia-blacklist.txt" --hostlist="%LISTS%custom-hostlist.txt" --hostlist="%LISTS%mycdnlist.txt" --dpi-desync=fake,multisplit --dpi-desync-split-seqovl=2 --dpi-desync-split-pos=sld+1 --dpi-desync-fake-http="%FAKE%http_fake_MS.bin" --dpi-desync-fooling=md5sig --dup=2 --dup-fooling=md5sig --dup-cutoff=n3 --new ^
--filter-tcp=443 --hostlist-domains=updates.discord.com, stable.dl2.discordapp.net, getchu.com, rutracker.org, static.rutracker.cc, cdn77.com --dpi-desync=multisplit --dpi-desync-split-seqovl=293 --dpi-desync-split-seqovl-pattern="%FAKE%tls_clienthello_12.bin" --new ^
--filter-tcp=443 --hostlist-domains=googlevideo.com --hostlist="%LISTS%russia-youtube.txt" --ipcache-hostname --dpi-desync=syndata,fake,multisplit --dpi-desync-split-pos=sld+1 --dpi-desync-fake-syndata="%FAKE%tls_clienthello_7.bin" --dpi-desync-fake-tls=0x0F0F0E0F --dpi-desync-fake-tls="%FAKE%tls_clienthello_9.bin" --dpi-desync-fake-tls-mod=rnd,dupsid --dpi-desync-fooling=md5sig --dpi-desync-autottl --dup=2 --dup-fooling=md5sig --dup-autottl --dup-cutoff=n3 --new ^
--filter-tcp=443 --hostlist-domains=googlevideo.com --hostlist="%LISTS%youtube_video-chanel-preview.txt" --dpi-desync=fake,multisplit --dpi-desync-split-pos=sld+1 --dpi-desync-fake-tls=0x0F0F0E0F --dpi-desync-fake-tls="%FAKE%tls_clienthello_14.bin" --dpi-desync-fake-tls-mod=rnd,dupsid --dpi-desync-fooling=md5sig --dpi-desync-autottl --dup=2 --dup-fooling=md5sig --dup-autottl --dup-cutoff=n3 --new ^
--filter-l3=ipv4 --filter-tcp=443 --ipset="%LISTS%ipset-cloudflare2.txt" --ipset-exclude-ip=1.1.1.1,1.0.0.1,212.109.195.93,83.220.169.155,141.105.71.21,18.244.96.0/19,18.244.128.0/19 --dpi-desync=multisplit --dpi-desync-split-seqovl=286 --dpi-desync-split-seqovl-pattern="%FAKE%tls_clienthello_11.bin" --dup=2 --dup-cutoff=n3 --new ^
--filter-tcp=80 --hostlist-auto="%LISTS%autohostlist.txt" --hostlist-exclude="%LISTS%exclude-autohostlist.txt" --dpi-desync=fake,multisplit --dpi-desync-split-seqovl=2 --dpi-desync-split-pos=host+1 --dpi-desync-fake-http=0x0E0E0F0E --dpi-desync-fooling=md5sig --new ^
--filter-tcp=443 --hostlist-auto="%LISTS%autohostlist.txt" --hostlist-exclude="%LISTS%exclude-autohostlist.txt" --dpi-desync=fake,fakedsplit --dpi-desync-split-pos=1 --dpi-desync-fake-tls="%FAKE%tls_clienthello_9.bin" --dpi-desync-fooling=badseq --dpi-desync-autottl

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

goto :Zapusk