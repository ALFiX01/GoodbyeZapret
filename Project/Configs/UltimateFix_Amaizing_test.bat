@echo off
chcp 65001 >nul

goto :Preparing
:Zapusk

set currentDir=%~dp0
set currentDir=%currentDir:~0,-1%
for %%i in ("%currentDir%") do set parentDir=%%~dpi
reg add "HKCU\Software\ALFiX inc.\GoodbyeZapret" /t REG_SZ /v "GoodbyeZapret_LastStartConfig" /d "%~nx0" /f >nul

set "CONFIG_NAME=GoodbyeZapret: UltimateFix Amaizing TEST"
set "FAKE=%parentDir%bin\fake\"
set "BIN=%parentDir%bin\"
set "LISTS=%parentDir%lists\"
cd /d "%BIN%"
REM BEST
REM preview      --dpi-desync=fake,fakedsplit --orig-autottl=+1 --dpi-desync-ttl=1 --dpi-desync-autottl=-2 --dpi-desync-split-pos=method+2
REM --dpi-desync=fake,fakedsplit --orig-autottl=+2 --dpi-desync-ttl=1 --dpi-desync-autottl=-2 --dpi-desync-split-pos=method+2

REM --dpi-desync=fake --dpi-desync-fooling=datanoack --dpi-desync-fake-http=0x00000000 
REM --dpi-desync=fakedsplit --dpi-desync-ttl=1 --dpi-desync-autottl=3 --dpi-desync-split-pos=1
REM powershell -Command "Start-Process 'cmd.exe' -ArgumentList '/c \"\"%parentDir%tools\before_launch_config.bat\" admin\"' -Verb RunAs"
start "%CONFIG_NAME%" /min "%BIN%winws.exe" ^
--wf-tcp=80,443 --wf-udp=443,50000-50090 ^
--filter-l3=ipv4 --filter-tcp=80,443 --hostlist="%LISTS%netrogat.txt" --new ^
--filter-udp=50000-50090 --filter-l7=discord,stun --dpi-desync=fake --dpi-desync-autottl --dup=2 --dup-autottl --dup-cutoff=n3 --new ^
--filter-tcp=443 --hostlist="%LISTS%russia-discord.txt" --dpi-desync=fakedsplit --dpi-desync-split-pos=1 --dpi-desync-fooling=badseq --dpi-desync-repeats=10 --dpi-desync-autottl --new ^
--filter-tcp=443 --ipset="%LISTS%russia-youtube-rtmps.txt" --dpi-desync=syndata --dpi-desync-fake-syndata="%FAKE%tls_clienthello_4.bin" --dpi-desync-autottl --dup=2 --dup-autottl --dup-cutoff=n3 --new ^
--filter-tcp=443 --hostlist="%LISTS%faceinsta.txt" --dpi-desync=syndata,multisplit --dpi-desync-fake-syndata="%FAKE%tls_clienthello_4.bin" --dpi-desync-split-pos=1 --new ^
--filter-udp=443 --hostlist="%LISTS%youtubeQ.txt" --dpi-desync=fake,fakeddisorder --dpi-desync-ttl=1 --dpi-desync-autottl=4 --dpi-desync-split-pos=method+2 --dpi-desync-fake-http=0x00000000 --new ^
--filter-tcp=443 --hostlist="%LISTS%russia-blacklist.txt" --hostlist="%LISTS%custom-hostlist.txt" --dpi-desync=fakeddisorder --dpi-desync-split-pos=2,midsld+1 --dpi-desync-fakedsplit-pattern="%FAKE%tls_clienthello_4.bin" --dpi-desync-fooling=badseq --dpi-desync-autottl 2:2-12 --new ^
--filter-tcp=443 --hostlist="%LISTS%russia-blacklist.txt" --hostlist="%LISTS%custom-hostlist.txt" --hostlist="%LISTS%mycdnlist.txt" --dpi-desync=fake,multidisorder --dpi-desync-split-pos=sld+1 --dpi-desync-fake-tls=0x0F0F0E0F --dpi-desync-fake-tls="%FAKE%tls_clienthello_15.bin" --dpi-desync-fake-tls-mod=rnd,dupsid --dpi-desync-fooling=md5sig --dpi-desync-autottl --dup=2 --dup-fooling=md5sig --dup-autottl --dup-cutoff=n3 --new ^
--filter-tcp=443 --hostlist="%LISTS%list-youtube.txt" --dpi-desync=fakedsplit --dpi-desync-ttl=2 --dpi-desync-split-pos=1 --new ^
--filter-tcp=443 --ipset-exclude-ip=1.1.1.1, 1.0.0.1, 212.109.195.93, 83.220.169.155, 141.105.71.21 --ipset="%LISTS%ipset-cloudflare2.txt" --dpi-desync=syndata,multisplit --dpi-desync-split-seqovl=1 --dpi-desync-fake-syndata="%FAKE%tls_clienthello_16.bin" --dup=2 --dup-cutoff=n3 --new ^
--filter-tcp=80 --hostlist-auto="%LISTS%autohostlist.txt" --hostlist-exclude="%LISTS%exclude-autohostlist.txt" --dpi-desync=fake,multisplit --dpi-desync-split-seqovl=2 --dpi-desync-split-pos=host+1 --dpi-desync-fake-http=0x0E0E0F0E --dpi-desync-fooling=md5sig --new ^
--filter-tcp=443 --hostlist-auto="%LISTS%autohostlist.txt" --hostlist-exclude="%LISTS%exclude-autohostlist.txt" --dpi-desync=fakeddisorder --dpi-desync-split-pos=2,midsld+1 --dpi-desync-fakedsplit-pattern="%FAKE%tls_clienthello_4.bin" --dpi-desync-fooling=badseq

goto :EOF

:Preparing
if not "%1"=="am_admin" (
  powershell -Command "Start-Process -FilePath '%~f0' -ArgumentList 'am_admin' -Verb RunAs"
  exit /b
)
REM --- Gracefully stop and remove services that may interfere ---
REM Stop & delete zapret service if it exists
sc query "zapret" >nul 2>&1
if %errorlevel%==0 (
  sc stop zapret >nul 2>&1
  sc delete zapret >nul 2>&1
)

REM Stop WinDivert service if it exists and running (no delete because this is a shared driver)
sc query "WinDivert" >nul 2>&1
if %errorlevel%==0 (
  sc stop WinDivert >nul 2>&1
  REM give the driver a moment to unload
  ping -n 3 127.0.0.1 > nul
)

ipconfig /flushdns > nul
goto :Zapusk