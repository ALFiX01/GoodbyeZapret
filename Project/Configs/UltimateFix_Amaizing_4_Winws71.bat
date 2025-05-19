@echo off
chcp 65001 >nul

set currentDir=%~dp0
set currentDir=%currentDir:~0,-1%
for %%i in ("%currentDir%") do set parentDir=%%~dpi

cd /d "%parentDir%"

reg add "HKCU\Software\ALFiX inc.\GoodbyeZapret" /t REG_SZ /v "GoodbyeZapret_LastStartConfig" /d "%~nx0" /f >nul

set "BIN=%parentDir%bin\"
set "CONFIG_NAME=GoodbyeZapret: UltimateFix Amaizing 4 TEST dup  |  Winws v71"
set "LISTS=%parentDir%lists\"

REM Можно изменить
set "Dup=2"

REM Требуется winws 71

start "%CONFIG_NAME%" /min "%BIN%winws_71.exe" ^
--wf-tcp=80,443 --wf-udp=443,50000-50099 ^
--filter-udp=50000-50099 --filter-l7=discord,stun --dpi-desync=fake --new ^
--filter-tcp=443 --hostlist="%LISTS%russia-discord.txt" --dpi-desync=fakedsplit --dpi-desync-split-pos=1 --dpi-desync-fooling=badseq --dpi-desync-repeats=10 --dpi-desync-autottl --new ^
--filter-tcp=443 --hostlist="%LISTS%youtube_video-preview.txt" --filter-l7=tls --dup=%Dup% --dup-autottl=+1:3-64 --dpi-desync=fake,multidisorder --dpi-desync-repeats=20 --dpi-desync-split-pos=1,midsld --dpi-desync-fooling=md5sig --dpi-desync-fake-tls-mod=rnd,dupsid,sni=www.google.com --new ^
--filter-tcp=443 --hostlist="%LISTS%youtubeQ.txt" --hostlist="%LISTS%list-youtube.txt" --filter-l7=tls --dup=%Dup% --dup-autottl=+1:3-64 --dpi-desync=fake,multidisorder --dpi-desync-repeats=20 --dpi-desync-split-pos=1,midsld --dpi-desync-fooling=md5sig --dpi-desync-fake-tls-mod=rnd,dupsid,sni=www.google.com --new ^
--filter-udp=443 --hostlist="%LISTS%youtubeQ.txt" --filter-l7=tls --dup=%Dup% --dup-autottl=+1:3-64 --dpi-desync=fake,multidisorder --dpi-desync-repeats=10 --dpi-desync-split-pos=1,midsld --dpi-desync-fooling=md5sig --dpi-desync-fake-tls-mod=rnd,dupsid,sni=www.google.com --new ^
--filter-tcp=443 --hostlist="%LISTS%list-youtube.txt" --filter-l7=quic --dup=%Dup% --dup-autottl=+1:3-64 --dpi-desync=fake --dpi-desync-repeats=20 --dpi-desync-fake-quic="%BIN%quic_initial_www_google_com.bin" --new ^
--filter-tcp=443 --hostlist="%LISTS%custom-hostlist.txt" --filter-l7=quic --dup=%Dup% --dup-autottl=+1:3-64 --dpi-desync=fake --dpi-desync-repeats=20 --dpi-desync-fake-quic="%BIN%quic_initial_www_google_com.bin" --new ^
--filter-tcp=443 --hostlist="%LISTS%custom-hostlist.txt" --filter-l7=tls --dup=%Dup% --dup-autottl=+1:3-64 --dpi-desync=fake,multidisorder --dpi-desync-repeats=10 --dpi-desync-split-pos=1,midsld --dpi-desync-fooling=md5sig --dpi-desync-fake-tls-mod=rnd,dupsid,sni=www.google.com --new ^
--filter-udp=443 --ipset="%LISTS%russia-youtube-rtmps.txt" --hostlist="%LISTS%youtubeQ.txt" --filter-l7=quic --dup=%Dup% --dup-autottl=+1:3-64 --dpi-desync=fake --dpi-desync-repeats=20 --dpi-desync-fake-quic="%BIN%quic_initial_www_google_com.bin" --new ^
--filter-tcp=443 --hostlist="%LISTS%faceinsta.txt" --filter-l7=quic --dup=%Dup% --dup-autottl=+1:3-64 --dpi-desync=fake --dpi-desync-repeats=20 --dpi-desync-fake-quic="%BIN%quic_initial_www_google_com.bin" --new ^
--filter-udp=443 --ipset="%LISTS%ipset-cloudflare.txt" --dup=%Dup% --dup-autottl=+1:3-64 --dpi-desync=fake --dpi-desync-repeats=20 --dpi-desync-fake-quic="%BIN%quic_initial_www_google_com.bin" --hostlist-exclude="%LISTS%exclude.txt" --new ^
--filter-tcp=80 --ipset="%LISTS%ipset-cloudflare.txt" --dpi-desync=fake,split2 --dpi-desync-autottl=2 --dpi-desync-fooling=md5sig --hostlist-exclude="%LISTS%exclude.txt" --new ^
--filter-tcp=443 --ipset="%LISTS%ipset-cloudflare.txt" --dpi-desync=split --dpi-desync-split-pos=1 --dpi-desync-autottl --dpi-desync-fooling=badseq --dpi-desync-repeats=8 --hostlist-exclude="%LISTS%exclude.txt" --new ^
--filter-tcp=443 --hostlist-auto="%LISTS%autohostlist.txt" --hostlist-exclude="%LISTS%exclude-autohostlist.txt" --filter-l7=quic --dup=%Dup% --dup-autottl=+1:3-64 --dpi-desync=fake --dpi-desync-repeats=20 --dpi-desync-fake-quic="%BIN%quic_initial_www_google_com.bin" --new ^
--filter-tcp=443 --hostlist-auto="%LISTS%autohostlist.txt" --hostlist-exclude="%LISTS%exclude-autohostlist.txt" --filter-l7=tls --dup=%Dup% --dup-autottl=+1:3-64 --dpi-desync=fake,multidisorder --dpi-desync-repeats=20 --dpi-desync-split-pos=1,midsld --dpi-desync-fooling=md5sig --dpi-desync-fake-tls-mod=rnd,dupsid,sni=www.google.com