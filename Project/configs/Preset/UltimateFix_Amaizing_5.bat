@echo off
chcp 65001 >nul

goto :Preparing
:Zapusk

set currentDir=%~dp0
set currentDir=%currentDir:~0,-1%
for %%i in ("%currentDir%") do set parentDir=%%~dpi
for %%i in ("%parentDir:~0,-1%") do set ProjectDir=%%~dpi
reg add "HKCU\Software\ALFiX inc.\GoodbyeZapret" /t REG_SZ /v "GoodbyeZapret_LastStartConfig" /d "%~nx0" /f >nul

set "CONFIG_NAME=GoodbyeZapret: UltimateFix Amaizing 5"
set "FAKE=%ProjectDir%bin\fake\"
set "BIN=%ProjectDir%bin\"
set "LISTS=%ProjectDir%lists\"
cd /d "%BIN%"

start "%CONFIG_NAME%" /min "%BIN%winws.exe" ^
--wf-tcp=80,443 --wf-udp=443,50000-50099 ^
--filter-udp=50000-50099 --filter-l7=discord,stun --dpi-desync=fake --new ^
--filter-tcp=443 --hostlist="%LISTS%russia-discord.txt" --dpi-desync=fakedsplit --dpi-desync-split-pos=1 --dpi-desync-fooling=badseq --dpi-desync-repeats=10 --dpi-desync-autottl --new ^
--filter-tcp=443 --hostlist="%LISTS%youtubeQ.txt" --hostlist="%LISTS%list-youtube.txt" --filter-l7=tls --dpi-desync=fake,multidisorder --dpi-desync-repeats=20 --dpi-desync-split-pos=1,midsld --dpi-desync-fooling=md5sig --dpi-desync-fake-tls-mod=rnd,dupsid,sni=www.google.com --new ^
--filter-udp=443 --hostlist="%LISTS%youtubeQ.txt" --filter-l7=tls --dpi-desync=fake,multidisorder --dpi-desync-repeats=10 --dpi-desync-split-pos=1,midsld --dpi-desync-fooling=md5sig --dpi-desync-fake-tls-mod=rnd,dupsid,sni=www.google.com --new ^
--filter-tcp=443 --hostlist="%LISTS%list-youtube.txt" --dpi-desync=fake,ipfrag2 --dpi-desync-fake-quic="%FAKE%quic_3.bin" --dpi-desync-cutoff=n3 --dpi-desync-repeats=3 --new ^
--filter-tcp=443 --hostlist="%LISTS%custom-hostlist.txt" --dpi-desync=fake,ipfrag2 --dpi-desync-fake-quic="%FAKE%quic_3.bin" --dpi-desync-cutoff=n3 --dpi-desync-repeats=3 --new ^
--filter-tcp=443 --hostlist="%LISTS%custom-hostlist.txt" --filter-l7=tls --dpi-desync=fake,multidisorder --dpi-desync-repeats=10 --dpi-desync-split-pos=1,midsld --dpi-desync-fooling=md5sig --dpi-desync-fake-tls-mod=rnd,dupsid,sni=www.google.com --new ^
--filter-udp=443 --ipset="%LISTS%russia-youtube-rtmps.txt" --hostlist="%LISTS%youtubeQ.txt" --dpi-desync=fake,ipfrag2 --dpi-desync-fake-quic="%FAKE%quic_3.bin" --dpi-desync-cutoff=n3 --dpi-desync-repeats=3 --new ^
--filter-tcp=443 --hostlist="%LISTS%faceinsta.txt" --dpi-desync=fake,ipfrag2 --dpi-desync-fake-quic="%FAKE%quic_3.bin" --dpi-desync-cutoff=n3 --dpi-desync-repeats=3 --new ^
--filter-l3=ipv4 --filter-tcp=443 --ipset="%LISTS%ipset-cloudflare2.txt" --ipset-exclude-ip=1.1.1.1, 1.0.0.1, 212.109.195.93, 83.220.169.155, 141.105.71.21, 18.244.96.0/19, 18.244.128.0/19 --dpi-desync=multisplit --dpi-desync-split-seqovl=209 --dpi-desync-split-seqovl-pattern="%FAKE%tls_clienthello_5.bin" --dpi-desync-split-pos=sld+1 --dup=2 --dup-cutoff=n3 --new ^
--filter-tcp=443 --hostlist-auto="%LISTS%autohostlist.txt" --hostlist-exclude="%LISTS%exclude-autohostlist.txt" --dpi-desync=fake,ipfrag2 --dpi-desync-fake-quic="%FAKE%quic_3.bin" --dpi-desync-cutoff=n3 --dpi-desync-repeats=3 --new ^
--filter-tcp=443 --hostlist-auto="%LISTS%autohostlist.txt" --hostlist-exclude="%LISTS%exclude-autohostlist.txt" --filter-l7=tls --dpi-desync=fake,multidisorder --dpi-desync-repeats=20 --dpi-desync-split-pos=1,midsld --dpi-desync-fooling=md5sig --dpi-desync-fake-tls-mod=rnd,dupsid,sni=www.google.com

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