@echo off
chcp 65001 >nul

set currentDir=%~dp0
set currentDir=%currentDir:~0,-1%
for %%i in ("%currentDir%") do set parentDir=%%~dpi

cd /d "%parentDir%"

reg add "HKCU\Software\ALFiX inc.\GoodbyeZapret" /t REG_SZ /v "GoodbyeZapret_LastStartConfig" /d "%~nx0" /f >nul

set "BIN=%parentDir%bin\"
set "LIST_TITLE=GoodbyeZapret: UltimateFix Amaizing"
set "LISTS_FOLDER=%parentDir%lists"
REM BEST
REM --dpi-desync=fake --dpi-desync-fooling=badseq --dpi-desync-fake-http=0x00000000
REM --dpi-desync=fake --dpi-desync-fooling=datanoack --dpi-desync-fake-http=0x00000000 
REM --dpi-desync=fakedsplit --dpi-desync-ttl=1 --dpi-desync-autottl=3 --dpi-desync-split-pos=1

start "%LIST_TITLE%" /min "%BIN%winws.exe" ^
--wf-tcp=80,443 --wf-udp=443,50000-50099 ^
--filter-udp=50000-50099 --filter-l7=discord,stun --dpi-desync=fake --dpi-desync-repeats=5 --new ^
--filter-tcp=443 --hostlist="%LISTS_FOLDER%\youtube_video-preview.txt" --dpi-desync=fake --dpi-desync-fooling=badseq --dpi-desync-fake-http=0x00000000 --new ^
--filter-udp=443 --hostlist="%LISTS_FOLDER%\youtubeQ.txt" --dpi-desync=fake,fakeddisorder --dpi-desync-ttl=1 --dpi-desync-autottl=4 --dpi-desync-split-pos=method+2 --dpi-desync-fake-http=0x00000000 --new ^
--filter-tcp=443 --hostlist="%LISTS_FOLDER%\list-youtube.txt" --dpi-desync=fakedsplit --dpi-desync-ttl=1 --dpi-desync-autottl=3 --dpi-desync-split-pos=1 --new ^
--filter-udp=443 --ipset="%LISTS_FOLDER%\ipset-cloudflare.txt" --dpi-desync=fake --dpi-desync-repeats=6 --dpi-desync-fake-quic="%BIN%quic_initial_www_google_com.bin" --hostlist-exclude="%LISTS_FOLDER%\exclude.txt" --new ^
--filter-tcp=80 --ipset="%LISTS_FOLDER%\ipset-cloudflare.txt" --dpi-desync=fake,split2 --dpi-desync-autottl=2 --dpi-desync-fooling=md5sig --hostlist-exclude="%LISTS_FOLDER%\exclude.txt" --new ^
--filter-tcp=443 --ipset="%LISTS_FOLDER%\ipset-cloudflare.txt" --dpi-desync=fake,split2 --dpi-desync-repeats=6 --dpi-desync-fooling=md5sig --dpi-desync-fake-tls="%BIN%tls_clienthello_www_google_com.bin" --hostlist-exclude="%LISTS_FOLDER%\exclude.txt"
