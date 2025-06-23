@echo off
chcp 65001 >nul

goto :Preparing
:Zapusk

set currentDir=%~dp0
set currentDir=%currentDir:~0,-1%
for %%i in ("%currentDir%") do set parentDir=%%~dpi
reg add "HKCU\Software\ALFiX inc.\GoodbyeZapret" /t REG_SZ /v "GoodbyeZapret_LastStartConfig" /d "%~nx0" /f >nul

set "CONFIG_NAME=GoodbyeZapret: UltimateFix Amaizing 4"
set "FAKE=%parentDir%bin\fake\"
set "BIN=%parentDir%bin\"
set "LISTS=%parentDir%lists\"
cd /d "%BIN%"

REM МОЖНО ИЗМЕНИТЬ ЭТО ЧИСЛО
set "Dup=2"

start "%CONFIG_NAME%" /min "%BIN%winws.exe" ^
--wf-tcp=80,443 --wf-udp=443,50000-50099 ^
--filter-udp=50000-50099 --filter-l7=discord,stun --dpi-desync=fake --new ^
--filter-tcp=443 --hostlist="%LISTS%russia-discord.txt" --dpi-desync=fakedsplit --dpi-desync-split-pos=1 --dpi-desync-fooling=badseq --dpi-desync-repeats=10 --dpi-desync-autottl --new ^
--filter-tcp=443 --hostlist="%LISTS%youtubeQ.txt" --hostlist="%LISTS%list-youtube.txt" --filter-l7=tls --dup=%Dup% --dup-autottl=+1:3-64 --dpi-desync=fake,multidisorder --dpi-desync-repeats=20 --dpi-desync-split-pos=1,midsld --dpi-desync-fooling=md5sig --dpi-desync-fake-tls-mod=rnd,dupsid,sni=www.google.com --new ^
--filter-udp=443 --hostlist="%LISTS%youtubeQ.txt" --filter-l7=tls --dup=%Dup% --dup-autottl=+1:3-64 --dpi-desync=fake,multidisorder --dpi-desync-repeats=10 --dpi-desync-split-pos=1,midsld --dpi-desync-fooling=md5sig --dpi-desync-fake-tls-mod=rnd,dupsid,sni=www.google.com --new ^
--filter-tcp=443 --hostlist="%LISTS%list-youtube.txt" --filter-l7=quic --dup=%Dup% --dup-autottl=+1:3-64 --dpi-desync=fake --dpi-desync-repeats=20 --dpi-desync-fake-quic="%FAKE%quic_initial_www_google_com.bin" --new ^
--filter-tcp=443 --hostlist="%LISTS%custom-hostlist.txt" --filter-l7=quic --dup=%Dup% --dup-autottl=+1:3-64 --dpi-desync=fake --dpi-desync-repeats=20 --dpi-desync-fake-quic="%FAKE%quic_initial_www_google_com.bin" --new ^
--filter-tcp=443 --hostlist="%LISTS%custom-hostlist.txt" --filter-l7=tls --dup=%Dup% --dup-autottl=+1:3-64 --dpi-desync=fake,multidisorder --dpi-desync-repeats=10 --dpi-desync-split-pos=1,midsld --dpi-desync-fooling=md5sig --dpi-desync-fake-tls-mod=rnd,dupsid,sni=www.google.com --new ^
--filter-udp=443 --ipset="%LISTS%russia-youtube-rtmps.txt" --hostlist="%LISTS%youtubeQ.txt" --filter-l7=quic --dup=%Dup% --dup-autottl=+1:3-64 --dpi-desync=fake --dpi-desync-repeats=20 --dpi-desync-fake-quic="%FAKE%quic_initial_www_google_com.bin" --new ^
--filter-tcp=443 --hostlist="%LISTS%faceinsta.txt" --filter-l7=quic --dup=%Dup% --dup-autottl=+1:3-64 --dpi-desync=fake --dpi-desync-repeats=20 --dpi-desync-fake-quic="%FAKE%quic_initial_www_google_com.bin" --new ^
--filter-udp=443 --ipset="%LISTS%ipset-cloudflare.txt" --dup=%Dup% --dup-autottl=+1:3-64 --dpi-desync=fake --dpi-desync-repeats=20 --dpi-desync-fake-quic="%FAKE%quic_initial_www_google_com.bin" --hostlist-exclude="%LISTS%exclude.txt" --new ^
--filter-tcp=80 --ipset="%LISTS%ipset-cloudflare.txt" --dpi-desync=fake,split2 --dpi-desync-autottl=2 --dpi-desync-fooling=md5sig --hostlist-exclude="%LISTS%exclude.txt" --new ^
--filter-tcp=443 --ipset="%LISTS%ipset-cloudflare.txt" --dpi-desync=split --dpi-desync-split-pos=1 --dpi-desync-autottl --dpi-desync-fooling=badseq --dpi-desync-repeats=8 --hostlist-exclude="%LISTS%exclude.txt" --new ^
--filter-tcp=443 --hostlist-auto="%LISTS%autohostlist.txt" --hostlist-exclude="%LISTS%exclude-autohostlist.txt" --filter-l7=quic --dup=%Dup% --dup-autottl=+1:3-64 --dpi-desync=fake --dpi-desync-repeats=20 --dpi-desync-fake-quic="%FAKE%quic_initial_www_google_com.bin" --new ^
--filter-tcp=443 --hostlist-auto="%LISTS%autohostlist.txt" --hostlist-exclude="%LISTS%exclude-autohostlist.txt" --filter-l7=tls --dup=%Dup% --dup-autottl=+1:3-64 --dpi-desync=fake,multidisorder --dpi-desync-repeats=20 --dpi-desync-split-pos=1,midsld --dpi-desync-fooling=md5sig --dpi-desync-fake-tls-mod=rnd,dupsid,sni=www.google.com

goto :EOF

:Preparing
if not "%1"=="am_admin" (
  powershell -Command "Start-Process -FilePath '%~f0' -ArgumentList 'am_admin' -Verb RunAs"
  exit /b
)
REM --- Gracefully stop and remove services that may interfere ---

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
sc query "WinDivert" >nul 2>&1
if %errorlevel% equ 0 (
  sc stop WinDivert >nul 2>&1
  REM give the driver a moment to unload
  ping -n 3 127.0.0.1 > nul
)

REM Flush DNS cache
ipconfig /flushdns > nul

goto :Zapusk