@echo off
chcp 65001 >nul

set currentDir=%~dp0
set currentDir=%currentDir:~0,-1%
for %%i in ("%currentDir%") do set parentDir=%%~dpi

cd /d "%parentDir%"

reg add "HKCU\Software\ALFiX inc.\GoodbyeZapret" /t REG_SZ /v "GoodbyeZapret_LastStartConfig" /d "%~nx0" /f >nul

set "BIN=%parentDir%bin\"
set "CONFIG_NAME=GoodbyeZapret: UltimateFix Amaizing 5"
set "LISTS=%parentDir%lists\"

start "%CONFIG_NAME%" /min "%BIN%winws.exe" ^
--wf-tcp=80,443 --wf-udp=443,50000-50099 ^
--filter-udp=50000-50099 --filter-l7=discord,stun --dpi-desync=fake --new ^
--filter-tcp=443 --hostlist="%LISTS%russia-discord.txt" --dpi-desync=fakedsplit --dpi-desync-split-pos=1 --dpi-desync-fooling=badseq --dpi-desync-repeats=10 --dpi-desync-autottl --new ^
--filter-tcp=443 --hostlist="%LISTS%youtube_video-preview.txt" --filter-l7=tls --dpi-desync=fake,multidisorder --dpi-desync-repeats=20 --dpi-desync-split-pos=1,midsld --dpi-desync-fooling=md5sig --dpi-desync-fake-tls-mod=rnd,dupsid,sni=www.google.com --new ^
--filter-tcp=443 --hostlist="%LISTS%youtubeQ.txt" --hostlist="%LISTS%list-youtube.txt" --filter-l7=tls --dpi-desync=fake,multidisorder --dpi-desync-repeats=20 --dpi-desync-split-pos=1,midsld --dpi-desync-fooling=md5sig --dpi-desync-fake-tls-mod=rnd,dupsid,sni=www.google.com --new ^
--filter-udp=443 --hostlist="%LISTS%youtubeQ.txt" --filter-l7=tls --dpi-desync=fake,multidisorder --dpi-desync-repeats=10 --dpi-desync-split-pos=1,midsld --dpi-desync-fooling=md5sig --dpi-desync-fake-tls-mod=rnd,dupsid,sni=www.google.com --new ^
--filter-tcp=443 --hostlist="%LISTS%list-youtube.txt" --dpi-desync=fake,ipfrag2 --dpi-desync-fake-quic="%BIN%quic_3.bin" --dpi-desync-cutoff=n3 --dpi-desync-repeats=3 --new ^
--filter-tcp=443 --hostlist="%LISTS%custom-hostlist.txt" --dpi-desync=fake,ipfrag2 --dpi-desync-fake-quic="%BIN%quic_3.bin" --dpi-desync-cutoff=n3 --dpi-desync-repeats=3 --new ^
--filter-tcp=443 --hostlist="%LISTS%custom-hostlist.txt" --filter-l7=tls --dpi-desync=fake,multidisorder --dpi-desync-repeats=10 --dpi-desync-split-pos=1,midsld --dpi-desync-fooling=md5sig --dpi-desync-fake-tls-mod=rnd,dupsid,sni=www.google.com --new ^
--filter-udp=443 --ipset="%LISTS%russia-youtube-rtmps.txt" --hostlist="%LISTS%youtubeQ.txt" --dpi-desync=fake,ipfrag2 --dpi-desync-fake-quic="%BIN%quic_3.bin" --dpi-desync-cutoff=n3 --dpi-desync-repeats=3 --new ^
--filter-tcp=443 --hostlist="%LISTS%faceinsta.txt" --dpi-desync=fake,ipfrag2 --dpi-desync-fake-quic="%BIN%quic_3.bin" --dpi-desync-cutoff=n3 --dpi-desync-repeats=3 --new ^
--filter-udp=443 --ipset="%LISTS%ipset-cloudflare.txt" --dpi-desync=fake,ipfrag2 --dpi-desync-fake-quic="%BIN%quic_3.bin" --dpi-desync-cutoff=n3 --dpi-desync-repeats=3 --hostlist-exclude="%LISTS%exclude.txt" --new ^
--filter-tcp=80 --ipset="%LISTS%ipset-cloudflare.txt" --dpi-desync=fake,split2 --dpi-desync-autottl=2 --dpi-desync-fooling=md5sig --hostlist-exclude="%LISTS%exclude.txt" --new ^
--filter-tcp=443 --ipset="%LISTS%ipset-cloudflare.txt" --dpi-desync=split --dpi-desync-split-pos=1 --dpi-desync-autottl --dpi-desync-fooling=badseq --dpi-desync-repeats=8 --hostlist-exclude="%LISTS%exclude.txt" --new ^
--filter-tcp=443 --hostlist-auto="%LISTS%autohostlist.txt" --hostlist-exclude="%LISTS%exclude-autohostlist.txt" --dpi-desync=fake,ipfrag2 --dpi-desync-fake-quic="%BIN%quic_3.bin" --dpi-desync-cutoff=n3 --dpi-desync-repeats=3 --new ^
--filter-tcp=443 --hostlist-auto="%LISTS%autohostlist.txt" --hostlist-exclude="%LISTS%exclude-autohostlist.txt" --filter-l7=tls --dpi-desync=fake,multidisorder --dpi-desync-repeats=20 --dpi-desync-split-pos=1,midsld --dpi-desync-fooling=md5sig --dpi-desync-fake-tls-mod=rnd,dupsid,sni=www.google.com