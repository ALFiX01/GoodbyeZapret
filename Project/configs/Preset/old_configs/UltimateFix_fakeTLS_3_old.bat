@echo off
chcp 65001 >nul

set currentDir=%~dp0
set currentDir=%currentDir:~0,-1%
for %%i in ("%currentDir%") do set parentDir=%%~dpi
for %%i in ("%parentDir:~0,-1%") do set ProjectDir=%%~dpi
set "GoodbyeZapret_LastStartConfig=%~nx0"

if not defined GoodbyeZapret_LastStartConfig (
  echo ERROR: GoodbyeZapret_LastStartConfig is not set
  pause
)
reg add "HKCU\Software\ALFiX inc.\GoodbyeZapret" /t REG_SZ /v "GoodbyeZapret_LastStartConfig" /d "%GoodbyeZapret_LastStartConfig%" /f >nul
cd /d "%parentDir%"


set "FAKE=%ProjectDir%bin\fake\"
set "BIN=%ProjectDir%bin\"
set "CONFIG_NAME=UltimateFix fakeTLS 3"
set "LISTS=%ProjectDir%lists\"

start "GoodbyeZapret: %CONFIG_NAME%" /b "%BIN%winws.exe" %YTDB_prog_log%^
--wf-tcp=80,443 --wf-udp=443,50000-50100 ^
--filter-udp=50000-50100 --filter-l7=discord,stun --dpi-desync=fake --dpi-desync-repeats=6 --new ^
--filter-udp=443 --hostlist="%LISTS%russia-blacklist.txt" --dpi-desync=fake --dpi-desync-repeats=11 --dpi-desync-fake-quic="%FAKE%quic_initial_www_google_com.bin" --new ^
--filter-tcp=80 --hostlist="%LISTS%russia-blacklist.txt" --dpi-desync=fake,fakedsplit --dpi-desync-autottl=2 --dpi-desync-fooling=md5sig --new ^
--filter-tcp=443 --hostlist="%LISTS%russia-blacklist.txt" --dpi-desync=fake,multidisorder --dpi-desync-split-pos=1,midsld --dpi-desync-repeats=11 --dpi-desync-fooling=md5sig --dpi-desync-fake-tls-mod=rnd,dupsid,sni=www.google.com --new ^
--filter-udp=443 --ipset="%LISTS%ipset-cloudflare.txt" --dpi-desync=fake --dpi-desync-repeats=11 --dpi-desync-fake-quic="%FAKE%quic_initial_www_google_com.bin" --new ^
--filter-tcp=80 --ipset="%LISTS%ipset-cloudflare.txt" --dpi-desync=fake,fakedsplit --dpi-desync-autottl=2 --dpi-desync-fooling=md5sig --new ^
--filter-tcp=443 --ipset="%LISTS%ipset-cloudflare.txt" --dpi-desync=fake,multidisorder --dpi-desync-split-pos=1,midsld --dpi-desync-repeats=11 --dpi-desync-fooling=md5sig
