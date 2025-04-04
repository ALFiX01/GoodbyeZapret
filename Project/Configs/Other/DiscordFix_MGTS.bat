@echo off
chcp 65001 >nul

set currentDir=%~dp0
set currentDir=%currentDir:~0,-1%
for %%i in ("%currentDir%") do set parentDir=%%~dpi

cd /d "%parentDir%"
set BIN=%parentDir%bin\

set "LIST_TITLE=GoodbyeZapret: DiscordFix MGTS"
set "DISCORD_IPSET_PATH=%parentDir%lists\ipset-discord.txt"
set "LISTS_FOLDER=%parentDir%lists"

start "%LIST_TITLE%" /min "%BIN%winws.exe" ^
--wf-tcp=443 --wf-udp=443,50000-65535 ^
--filter-udp=443 --hostlist="%LISTS_FOLDER%\list-discord.txt" --dpi-desync=fake --dpi-desync-repeats=6 --dpi-desync-fake-quic="%BIN%quic_initial_www_google_com.bin" --new ^
--filter-udp=50000-65535 --ipset="%DISCORD_IPSET_PATH%" --dpi-desync=fake,tamper --dpi-desync-any-protocol --dpi-desync-cutoff=d3 --dpi-desync-repeats=6 --new ^
--filter-tcp=443 --hostlist="%LISTS_FOLDER%\list-discord.txt" --dpi-desync=fake --dpi-desync-autottl=2 --dpi-desync-repeats=6  --dpi-desync-fooling=md5sig --dpi-desync-fake-tls="%BIN%tls_clienthello_www_google_com.bin"