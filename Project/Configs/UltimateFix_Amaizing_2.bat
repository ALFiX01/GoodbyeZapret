@echo off
chcp 65001 >nul

set currentDir=%~dp0
set currentDir=%currentDir:~0,-1%
for %%i in ("%currentDir%") do set parentDir=%%~dpi

cd /d "%parentDir%"

reg add "HKCU\Software\ALFiX inc.\GoodbyeZapret" /t REG_SZ /v "GoodbyeZapret_LastStartConfig" /d "%~nx0" /f >nul

set "BIN=%parentDir%bin\"
set "CONFIG_NAME=GoodbyeZapret: UltimateFix Amaizing 2"
set "LISTS=%parentDir%lists\"
REM BEST
REM discord --dpi-desync=fake,fakedsplit --dpi-desync-ttl=3 --dpi-desync-split-pos=midsld --dpi-desync-fake-tls=0x00000000
REM --dpi-desync=fake --dpi-desync-ttl=1 --dpi-desync-autottl=1 --dpi-desync-fake-http=0x00000000
REM --dpi-desync=fake --dpi-desync-fooling=badseq --dpi-desync-fake-http=0x00000000
REM --dpi-desync=fake --dpi-desync-fooling=datanoack --dpi-desync-fake-http=0x00000000 
REM --dpi-desync=fakedsplit --dpi-desync-ttl=1 --dpi-desync-autottl=3 --dpi-desync-split-pos=1

start "%CONFIG_NAME%" /min "%BIN%winws.exe" ^
--wf-tcp=80,443 --wf-udp=443,50000-50099 ^
--filter-udp=50000-50099 --filter-l7=discord,stun --dpi-desync=fake,fakedsplit --dpi-desync-ttl=3 --dpi-desync-split-pos=midsld --dpi-desync-fake-tls=0x00000000 --new ^
--filter-udp=443 --hostlist="%LISTS%russia-discord.txt" --dpi-desync=fake --dpi-desync-fooling=badseq --dpi-desync-fake-tls="%BIN%tls_clienthello_7.bin" --dpi-desync-fake-tls-mod=rnd --new ^
--filter-udp=443 --hostlist="%LISTS%russia-discord.txt" --dpi-desync=fake,udplen --dpi-desync-udplen-increment=5 --dpi-desync-udplen-pattern=0xDEADBEEF --dpi-desync-fake-quic="%BIN%quic_3.bin" --dpi-desync-repeats=7 --dpi-desync-cutoff=n2 --new ^
--filter-tcp=443 --hostlist="%LISTS%faceinsta.txt" --dpi-desync=fake --dpi-desync-ttl=1 --dpi-desync-autottl=1 --dpi-desync-fake-http=0x00000000 --new ^
--filter-tcp=443 --hostlist="%LISTS%youtube_video-preview.txt" --dpi-desync=fake --dpi-desync-ttl=1 --dpi-desync-autottl=1 --dpi-desync-fake-http=0x00000000 --new ^
--filter-tcp=443 --hostlist="%LISTS%custom-hostlist.txt" --dpi-desync=fake --dpi-desync-fooling=badseq --dpi-desync-fake-tls="%BIN%tls_clienthello_7.bin" --dpi-desync-fake-tls-mod=rnd --new ^
--filter-tcp=443 --hostlist="%LISTS%list-youtube.txt" --dpi-desync=fakedsplit --dpi-desync-ttl=1 --dpi-desync-autottl=2 --dpi-desync-split-pos=method+2 --new ^
--filter-udp=443 --ipset="%LISTS%ipset-cloudflare.txt" --dpi-desync=fake --dpi-desync-repeats=6 --dpi-desync-fake-quic="%BIN%quic_initial_www_google_com.bin" --hostlist-exclude="%LISTS%exclude.txt" --new ^
--filter-tcp=80 --ipset="%LISTS%ipset-cloudflare.txt" --dpi-desync=fake,split2 --dpi-desync-autottl=2 --dpi-desync-fooling=md5sig --hostlist-exclude="%LISTS%exclude.txt" --new ^
--filter-tcp=443 --ipset="%LISTS%ipset-cloudflare.txt" --dpi-desync=fake,split2 --dpi-desync-repeats=6 --dpi-desync-fooling=md5sig --dpi-desync-fake-tls="%BIN%tls_clienthello_www_google_com.bin" --hostlist-exclude="%LISTS%exclude.txt" --new ^
--filter-tcp=443 --hostlist-auto="%LISTS%autohostlist.txt" --hostlist-exclude="%LISTS%exclude-autohostlist.txt" ---dpi-desync=fake --dpi-desync-fooling=badseq --dpi-desync-fake-tls="%BIN%tls_clienthello_7.bin" --dpi-desync-fake-tls-mod=rnd