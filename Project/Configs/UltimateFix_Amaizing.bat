@echo off
chcp 65001 >nul

set currentDir=%~dp0
set currentDir=%currentDir:~0,-1%
for %%i in ("%currentDir%") do set parentDir=%%~dpi

cd /d "%parentDir%"

reg add "HKCU\Software\ALFiX inc.\GoodbyeZapret" /t REG_SZ /v "GoodbyeZapret_LastStartConfig" /d "%~nx0" /f >nul

set "BIN=%parentDir%bin\"
set "CONFIG_NAME=GoodbyeZapret: UltimateFix Amaizing"
set "LISTS=%parentDir%lists\"
REM BEST
REM preview      --dpi-desync=fake --dpi-desync-fooling=badseq --dpi-desync-fake-http=0x00000000
REM --dpi-desync=fake --dpi-desync-ttl=2 --dpi-desync-fake-tls-mod=rnd,dupsid,rndsni,padencap

REM --dpi-desync=fake --dpi-desync-fooling=datanoack --dpi-desync-fake-http=0x00000000 
REM --dpi-desync=fakedsplit --dpi-desync-ttl=1 --dpi-desync-autottl=3 --dpi-desync-split-pos=1

start "%CONFIG_NAME%" /min "%BIN%winws.exe" ^
--wf-tcp=80,443 --wf-udp=443,50000-50099 ^
--filter-udp=50000-50099 --filter-l7=discord,stun --dpi-desync=fake --new ^
--filter-tcp=443 --hostlist="%LISTS%russia-discord.txt" --dpi-desync=fakedsplit --dpi-desync-split-pos=1 --dpi-desync-fooling=badseq --dpi-desync-repeats=10 --dpi-desync-autottl --new ^
--filter-tcp=443 --hostlist="%LISTS%youtube_video-preview.txt" --dpi-desync=fake --dpi-desync-ttl=2 --dpi-desync-fake-tls-mod=rnd,dupsid,rndsni,padencap --new ^
--filter-udp=443 --ipset="%LISTS%russia-youtube-rtmps.txt" --dpi-desync=syndata,multisplit --dpi-desync-fake-syndata="%BIN%tls_clienthello_4.bin" --dpi-desync-split-pos=1 --new ^
--filter-tcp=443 --hostlist="%LISTS%faceinsta.txt" --dpi-desync=syndata,multisplit --dpi-desync-fake-syndata="%BIN%tls_clienthello_4.bin" --dpi-desync-split-pos=1 --new ^
--filter-udp=443 --hostlist="%LISTS%youtubeQ.txt" --dpi-desync=fake,fakeddisorder --dpi-desync-ttl=1 --dpi-desync-autottl=4 --dpi-desync-split-pos=method+2 --dpi-desync-fake-http=0x00000000 --new ^
--filter-tcp=443 --hostlist="%LISTS%russia-blacklist.txt" --hostlist="%LISTS%custom-hostlist.txt" --dpi-desync=fakeddisorder --dpi-desync-split-pos=2,midsld+1 --dpi-desync-fakedsplit-pattern="%BIN%tls_clienthello_4.bin" --dpi-desync-fooling=badseq --dpi-desync-autottl 2:2-12 --new ^
--filter-tcp=443 --hostlist="%LISTS%list-youtube.txt" --dpi-desync=fakedsplit --dpi-desync-ttl=2 --dpi-desync-split-pos=1 --new ^
--filter-udp=443 --ipset="%LISTS%ipset-cloudflare.txt" --dpi-desync=fake --dpi-desync-repeats=6 --dpi-desync-fake-quic="%BIN%quic_initial_www_google_com.bin" --hostlist-exclude="%LISTS%exclude.txt" --new ^
--filter-tcp=80 --ipset="%LISTS%ipset-cloudflare.txt" --dpi-desync=fake,split2 --dpi-desync-autottl=2 --dpi-desync-fooling=md5sig --hostlist-exclude="%LISTS%exclude.txt" --new ^
--filter-tcp=443 --ipset="%LISTS%ipset-cloudflare.txt" --dpi-desync=split --dpi-desync-split-pos=1 --dpi-desync-autottl --dpi-desync-fooling=badseq --dpi-desync-repeats=8 --hostlist-exclude="%LISTS%exclude.txt" --new ^
--filter-tcp=443 --hostlist-auto="%LISTS%autohostlist.txt" --hostlist-exclude="%LISTS%exclude-autohostlist.txt" --dpi-desync=fakeddisorder --dpi-desync-split-pos=2,midsld+1 --dpi-desync-fakedsplit-pattern="%BIN%tls_clienthello_4.bin" --dpi-desync-fooling=badseq