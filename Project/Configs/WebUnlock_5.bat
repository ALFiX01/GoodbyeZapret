@echo off
chcp 65001 >nul

set currentDir=%~dp0
set currentDir=%currentDir:~0,-1%
for %%i in ("%currentDir%") do set parentDir=%%~dpi

cd /d "%parentDir%"
set BIN=%parentDir%bin\

set "LIST_TITLE=GoodbyeZapret: WebUnlock 5"
set "DISCORD_IPSET_PATH=%parentDir%lists\ipset-discord.txt"
set "LISTS_FOLDER=%parentDir%lists"

start "%LIST_TITLE%" /min "%BIN%winws.exe" ^
--wf-l3=ipv4,ipv6 --wf-tcp=443 --wf-udp=443,50000-65535 ^
--filter-udp=443 --hostlist="%LISTS_FOLDER%\youtubeQ.txt" --dpi-desync=fake,split2 --dpi-desync-repeats=6 --dpi-desync-fake-quic="%BIN%\quic_test_00.bin" --new ^
--filter-tcp=443 --hostlist="%LISTS_FOLDER%\youtube.txt" --dpi-desync=fake,split2 --dpi-desync-split-seqovl=2 --dpi-desync-split-pos=3 --dpi-desync-fake-tls="%BIN%\tls_clienthello_www_google_com.bin" --dpi-desync-ttl=2 --new ^
--filter-tcp=443 --hostlist="%LISTS_FOLDER%\discord.txt" --dpi-desync=fake,split2 --dpi-desync-fooling=badseq --dpi-desync-repeats=6 --dpi-desync-fake-tls="%BIN%\tls_clienthello_www_google_com.bin" --new ^
--filter-udp=443 --hostlist="%LISTS_FOLDER%\discord.txt" --dpi-desync=fake,split2 --dpi-desync-repeats=6 --dpi-desync-fake-quic="%BIN%\quic_1.bin" --new ^
--filter-udp=50000-65535 --dpi-desync=fake,split2 --dpi-desync-any-protocol --dpi-desync-repeats=6 --new ^
--filter-tcp=443 --hostlist="%LISTS_FOLDER%\other.txt" --dpi-desync=fake,split2 --dpi-desync-split-seqovl=1 --dpi-desync-split-tls=sniext --dpi-desync-fake-tls="%BIN%\tls_clienthello_2.bin" --dpi-desync-ttl=2 --new ^
--filter-tcp=443 --hostlist="%LISTS_FOLDER%\faceinsta.txt" --dpi-desync=split2 --dpi-desync-split-seqovl=652 --dpi-desync-split-pos=2 --dpi-desync-split-seqovl-pattern="%BIN%\tls_clienthello_4.bin" --new