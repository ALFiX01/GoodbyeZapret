@echo off
chcp 65001 >nul

set currentDir=%~dp0
set currentDir=%currentDir:~0,-1%
for %%i in ("%currentDir%") do set parentDir=%%~dpi

cd /d "%parentDir%"

reg add "HKCU\Software\ALFiX inc.\GoodbyeZapret" /t REG_SZ /v "GoodbyeZapret_LastStartConfig" /d "%~nx0" /f >nul

set "BIN=%parentDir%bin\"
set "CONFIG_NAME=GoodbyeZapret: UltimateFix 6"
set "LISTS=%parentDir%lists\"

start "%CONFIG_NAME%" /min "%BIN%winws.exe" ^
--wf-tcp=80,443 --wf-udp=443,50000-50090 ^
--filter-tcp=80,443 --hostlist="%LISTS%exclude-autohostlist.txt" --new ^
--filter-tcp=443 --ipset="%LISTS%russia-youtube-rtmps.txt" --dpi-desync=syndata --dpi-desync-fake-syndata="%BIN%tls_clienthello_4.bin" --dpi-desync-autottl 2:2-8 --new ^
--filter-udp=443 --hostlist="%LISTS%russia-youtubeQ.txt" --dpi-desync=fake,udplen --dpi-desync-udplen-increment=4 --dpi-desync-fake-quic="%BIN%quic_4.bin" --dpi-desync-cutoff=n3 --dpi-desync-repeats=2 --new ^
--filter-tcp=80 --hostlist="%LISTS%mycdnlist.txt" --hostlist="%LISTS%russia-blacklist.txt" --hostlist="%LISTS%custom-hostlist.txt" --dpi-desync=fake,multisplit --dpi-desync-split-seqovl=2 --dpi-desync-split-pos=sld+1 --dpi-desync-fake-http=0x0F --dpi-desync-autottl 2:2-12 --new ^
--filter-tcp=443 --hostlist="%LISTS%russia-blacklist.txt" --hostlist="%LISTS%custom-hostlist.txt" --hostlist="%LISTS%mycdnlist.txt" --hostlist-domains=googlevideo.com --hostlist="%LISTS%russia-youtube.txt" --hostlist="%LISTS%russia-discord.txt" --dpi-desync=fake,multidisorder --dpi-desync-split-pos=7,sld+1 --dpi-desync-fake-tls=0x0F0F0F0F --dpi-desync-fake-tls="%BIN%tls_clienthello_4.bin" --dpi-desync-fake-tls-mod=rnd,dupsid,sni=fonts.google.com --dpi-desync-fooling=badseq --dpi-desync-autottl 2:2-12 --new ^
--filter-udp=50000-50090 --filter-l7=discord,stun --dpi-desync=fake --new ^
--filter-tcp=80 --hostlist-auto="%LISTS%autohostlist.txt" --hostlist-exclude="%LISTS%exclude-autohostlist.txt" --dpi-desync=fake,multisplit --dpi-desync-split-seqovl=2 --dpi-desync-split-pos=host+1 --dpi-desync-fake-http=0x0F --dpi-desync-fooling=md5sig --new ^
--filter-tcp=443 --hostlist-auto="%LISTS%autohostlist.txt" --hostlist-exclude="%LISTS%exclude-autohostlist.txt" --dpi-desync=fakeddisorder --dpi-desync-split-pos=2,sld+1 --dpi-desync-fakedsplit-pattern="%BIN%tls_clienthello_4.bin" --dpi-desync-fooling=badseq
