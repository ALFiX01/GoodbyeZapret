@echo off
chcp 65001 >nul

set currentDir=%~dp0
set currentDir=%currentDir:~0,-1%
for %%i in ("%currentDir%") do set parentDir=%%~dpi

cd /d "%parentDir%"

set "BIN=%parentDir%bin\"
set "LIST_TITLE=GoodbyeZapret: UltimateFix fakeTLS"
set "LISTS_FOLDER=%parentDir%lists"

start "%LIST_TITLE%" /min "%BIN%winws.exe" ^
--wf-tcp=80,443 --wf-udp=443,50000-50100 ^
--filter-udp=443 --hostlist="%LISTS_FOLDER%\list-general.txt" --dpi-desync=fake --dpi-desync-repeats=8 --dpi-desync-fake-quic="%BIN%quic_initial_www_google_com.bin" --new ^
--filter-udp=50000-50100 --ipset="%LISTS_FOLDER%\ipset-discord.txt" --dpi-desync=fake --dpi-desync-any-protocol --dpi-desync-cutoff=d4 --dpi-desync-repeats=8 --new ^
--filter-tcp=80 --hostlist="%LISTS_FOLDER%\list-general.txt" --dpi-desync=fake,split2 --dpi-desync-autottl=3 --dpi-desync-fooling=md5sig --new ^
--filter-tcp=443 --hostlist="%LISTS_FOLDER%\list-general.txt" --dpi-desync=fake --dpi-desync-ttl=4 --dpi-desync-fake-tls-mod=rnd,rndsni,padencap --new ^
--filter-udp=443 --ipset="%LISTS_FOLDER%\ipset-cloudflare.txt" --dpi-desync=fake --dpi-desync-repeats=8 --dpi-desync-fake-quic="%BIN%quic_initial_www_google_com.bin" --new ^
--filter-tcp=80 --ipset="%LISTS_FOLDER%\ipset-cloudflare.txt" --dpi-desync=fake,split2 --dpi-desync-autottl=3 --dpi-desync-fooling=md5sig --new ^
--filter-tcp=443 --ipset="%LISTS_FOLDER%\ipset-cloudflare.txt" --dpi-desync=fake --dpi-desync-ttl=4 --dpi-desync-fake-tls-mod=rnd,rndsni,padencap