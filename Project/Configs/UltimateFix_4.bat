@echo off
chcp 65001 >nul

goto :Preparing
:Zapusk

set currentDir=%~dp0
set currentDir=%currentDir:~0,-1%
for %%i in ("%currentDir%") do set parentDir=%%~dpi
reg add "HKCU\Software\ALFiX inc.\GoodbyeZapret" /t REG_SZ /v "GoodbyeZapret_LastStartConfig" /d "%~nx0" /f >nul

set "CONFIG_NAME=GoodbyeZapret: UltimateFix 4"
set "FAKE=%parentDir%bin\fake\"
set "BIN=%parentDir%bin\"
set "LISTS=%parentDir%lists\"
cd /d "%BIN%"

start "%CONFIG_NAME%" /min "%BIN%winws.exe" ^
--wf-tcp=80,443 --wf-udp=443,50000-65535 ^
--filter-udp=50000-50100 --filter-l7=discord,stun --dpi-desync=fake --dpi-desync-repeats=6 --new ^
--filter-tcp=80 --hostlist="%LISTS%russia-discord.txt" --dpi-desync=fakedsplit --dpi-desync-autottl=2 --dpi-desync-fooling=md5sig --new ^
--filter-udp=443 --hostlist="%LISTS%russia-blacklist.txt" --dpi-desync=fake --dpi-desync-repeats=6 --dpi-desync-fake-quic="%FAKE%quic_initial_www_google_com.bin" --new ^
--filter-tcp=80 --hostlist="%LISTS%russia-blacklist.txt" --dpi-desync=fake,split2 --dpi-desync-autottl=2 --dpi-desync-fooling=md5sig --new ^
--filter-tcp=443 --hostlist="%LISTS%russia-blacklist.txt" --dpi-desync=fake,split --dpi-desync-split-pos=1 --dpi-desync-autottl --dpi-desync-fooling=badseq --dpi-desync-repeats=8 --new ^
--filter-udp=443 --ipset="%LISTS%ipset-cloudflare.txt" --dpi-desync=fake --dpi-desync-repeats=6 --dpi-desync-fake-quic="%FAKE%quic_initial_www_google_com.bin" --new ^
--filter-tcp=80 --ipset="%LISTS%ipset-cloudflare.txt" --dpi-desync=fake,split2 --dpi-desync-autottl=2 --dpi-desync-fooling=md5sig --new ^
--filter-tcp=443 --ipset="%LISTS%ipset-cloudflare.txt" --dpi-desync=split --dpi-desync-split-pos=1 --dpi-desync-autottl --dpi-desync-fooling=badseq --dpi-desync-repeats=8

goto :EOF

:Preparing
if not "%1"=="am_admin" (powershell start -verb runas '%0' am_admin & exit /b)
for /f "skip=3 tokens=1,2,* delims=: " %%i in ('sc query "zapret"') do (
 if %%j==4 (
 echo Zapret service is running!
 echo Stopping service...
 net stop zapret > nul
 echo Deleting service...
 sc delete zapret > nul
 )
rem exit
)
for /f "skip=3 tokens=1,2,* delims=: " %%i in ('sc query "WinDivert"') do (
 if %%j==4 (
 echo WinDivert service is running!
 echo Stopping service...
 net stop WinDivert > nul
 ping -n 3 127.0.0.1 > nul
 )
rem exit
)
ipconfig /flushdns > nul
goto :Zapusk