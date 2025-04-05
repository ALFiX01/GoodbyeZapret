@echo off
chcp 65001 >nul

set currentDir=%~dp0
set currentDir=%currentDir:~0,-1%
for %%i in ("%currentDir%") do set parentDir=%%~dpi

cd /d "%parentDir%"

set "BIN=%parentDir%bin\"
set "LIST_TITLE=GoodbyeZapret: WebUnlock 2"
set "LISTS_FOLDER=%parentDir%lists"

start "%LIST_TITLE%" /min "%BIN%winws.exe" ^
--wf-tcp=80,443 --wf-udp=443,50000-50090 ^
--filter-tcp=443 --ipset="%LISTS_FOLDER%\russia-youtube-rtmps.txt" --dpi-desync=syndata --dpi-desync-fake-syndata="%BIN%tls_clienthello_4.bin" --dpi-desync-autottl --new ^
--filter-udp=443 --hostlist="%LISTS_FOLDER%\youtubeQ.txt" --dpi-desync=fake,udplen --dpi-desync-udplen-increment=2 --dpi-desync-fake-quic="%BIN%quic_3.bin" --dpi-desync-cutoff=n3 --dpi-desync-repeats=2 --new ^
--filter-tcp=443 --ipset="%LISTS_FOLDER%\ipset-discord.txt" --dpi-desync=syndata --dpi-desync-fake-syndata="%BIN%tls_clienthello_3.bin" --dpi-desync-autottl --new ^
--filter-tcp=443 --hostlist="%LISTS_FOLDER%\youtube.txt" --dpi-desync=multisplit --dpi-desync-split-seqovl=1 --dpi-desync-split-pos=midsld+1 --new ^
--filter-udp=443 --hostlist="%LISTS_FOLDER%\discord.txt" --dpi-desync=fake,udplen --dpi-desync-udplen-increment=5 --dpi-desync-udplen-pattern=0xDEADBEEF --dpi-desync-fake-quic="%BIN%quic_2.bin" --dpi-desync-repeats=7 --dpi-desync-cutoff=n2 --new ^
--filter-udp=50000-50090 --dpi-desync=fake --dpi-desync-any-protocol --dpi-desync-cutoff=n3 --new ^
--filter-tcp=443 --hostlist="%LISTS_FOLDER%\youtubeGV.txt" --dpi-desync=multisplit --dpi-desync-split-seqovl=1 --dpi-desync-split-pos=midsld-1 --new ^
--filter-tcp=80 --hostlist="%LISTS_FOLDER%\other.txt" --dpi-desync=fake,multisplit --dpi-desync-fooling=md5sig --dpi-desync-autottl --new ^
--filter-tcp=443 --hostlist="%LISTS_FOLDER%\other.txt" --dpi-desync=fake,multisplit --dpi-desync-split-seqovl=1 --dpi-desync-split-pos=1 --dpi-desync-fake-tls="%BIN%tls_clienthello_2.bin" --dpi-desync-ttl=5 --new ^
--filter-tcp=443 --hostlist="%LISTS_FOLDER%\faceinsta.txt" --dpi-desync=split2 --dpi-desync-split-seqovl=652 --dpi-desync-split-pos=2 --dpi-desync-split-seqovl-pattern="%BIN%tls_clienthello_4.bin" --new