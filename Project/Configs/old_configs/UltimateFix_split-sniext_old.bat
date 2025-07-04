@echo off
chcp 65001 >nul

set currentDir=%~dp0
set currentDir=%currentDir:~0,-1%
for %%i in ("%currentDir%") do set parentDir=%%~dpi

cd /d "%parentDir%"

reg add "HKCU\Software\ALFiX inc.\GoodbyeZapret" /t REG_SZ /v "GoodbyeZapret_LastStartConfig" /d "%~nx0" /f >nul

set "FAKE=%parentDir%bin\fake\"
set "BIN=%parentDir%bin\"
set "CONFIG_NAME=GoodbyeZapret: UltimateFix split-sniext"
set "LISTS=%parentDir%lists\"

start "%CONFIG_NAME%" /min "%BIN%winws.exe" ^
--wf-tcp=80,443 --wf-udp=443,50000-59000 ^
--filter-udp=443 --hostlist="%LISTS%youtubeQ.txt" --dpi-desync=fake,split --dpi-desync-repeats=2 --dpi-desync-fake-quic="%FAKE%quic_6.bin" --new ^
--filter-tcp=443 --hostlist="%LISTS%youtube.txt" --dpi-desync=fake,split2 --dpi-desync-split-seqovl=2 --dpi-desync-split-pos=3 --dpi-desync-fake-tls="%FAKE%tls_clienthello_www_google_com.bin" --dpi-desync-ttl=2 --new ^
--filter-tcp=443 --hostlist="%LISTS%russia-discord.txt" --dpi-desync=fake,split2 --dpi-desync-split-tls=sniext --dpi-desync-fake-tls="%FAKE%tls_clienthello_www_google_com.bin" --new ^
--filter-udp=443 --hostlist="%LISTS%russia-discord.txt" --dpi-desync=fake,split2 --dpi-desync-repeats=6 --dpi-desync-fake-quic="%FAKE%quic_1.bin" --new ^
--filter-udp=50000-59000 --dpi-desync=fake,split2 --dpi-desync-any-protocol --dpi-desync-cutoff=d3 --dpi-desync-repeats=6 --new ^
--filter-tcp=443 --hostlist="%LISTS%other.txt" --dpi-desync=fake,split2 --dpi-desync-split-seqovl=1 --dpi-desync-split-tls=sniext --dpi-desync-fake-tls="%FAKE%tls_clienthello_2.bin" --dpi-desync-ttl=2 --new ^
--filter-tcp=443 --hostlist="%LISTS%faceinsta.txt" --dpi-desync=split2 --dpi-desync-split-seqovl=652 --dpi-desync-split-pos=2 --dpi-desync-split-seqovl-pattern="%FAKE%tls_clienthello_4.bin" --new ^
--filter-udp=443 --ipset="%LISTS%ipset-cloudflare.txt" --dpi-desync=fake --dpi-desync-repeats=6 --dpi-desync-fake-quic="%FAKE%quic_initial_www_google_com.bin" --new ^
--filter-tcp=80 --ipset="%LISTS%ipset-cloudflare.txt" --dpi-desync=fake,split2 --dpi-desync-autottl=2 --dpi-desync-fooling=md5sig --new ^
--filter-tcp=443 --ipset="%LISTS%ipset-cloudflare.txt" --dpi-desync=split --dpi-desync-split-pos=1 --dpi-desync-autottl --dpi-desync-fooling=badseq --dpi-desync-repeats=8