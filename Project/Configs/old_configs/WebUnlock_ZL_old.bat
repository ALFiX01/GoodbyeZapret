@echo off
chcp 65001 >nul

set currentDir=%~dp0
set currentDir=%currentDir:~0,-1%
for %%i in ("%currentDir%") do set parentDir=%%~dpi

cd /d "%parentDir%"

reg add "HKCU\Software\ALFiX inc.\GoodbyeZapret" /t REG_SZ /v "GoodbyeZapret_LastStartConfig" /d "%~nx0" /f >nul

set "CONFIG_NAME=GoodbyeZapret: WebUnlock ZL"
set "FAKE=%parentDir%bin\fake\"
set "BIN=%parentDir%bin\"
set "LISTS=%parentDir%lists\"
cd /d "%BIN%"

start "%CONFIG_NAME%" /min "%BIN%winws.exe" ^
--wf-tcp=80,443 --wf-udp=443,50000-50099 ^
--filter-udp=50000-50100 --filter-l7=discord,stun --dpi-desync=fake --dpi-desync-repeats=6 --new ^
--filter-udp=443 --hostlist="%LISTS%youtubeQ.txt" --dpi-desync=fake --dpi-desync-fake-quic="%FAKE%quic_1.bin" --dpi-desync-repeats=4 --new ^
--filter-tcp=443 --hostlist-domains=googlevideo.com --dpi-desync=fakedsplit --dpi-desync-split-seqovl=1 --dpi-desync-split-pos=1 --dpi-desync-fooling=badseq --dpi-desync-repeats=10 --dpi-desync-ttl=4 --new ^
--filter-tcp=443 --hostlist="%LISTS%youtube.txt" --dpi-desync=fake,multisplit --dpi-desync-split-seqovl=2 --dpi-desync-split-pos=3 --dpi-desync-fake-tls="%FAKE%tls_clienthello_2.bin" --dpi-desync-ttl=3 --new ^
--filter-tcp=80 --hostlist="%LISTS%russia-blacklist.txt" --dpi-desync=fake,multisplit --dpi-desync-fooling=md5sig --new ^
--filter-tcp=443 --hostlist="%LISTS%russia-blacklist.txt" --hostlist="%LISTS%custom-hostlist.txt" --dpi-desync=fake,multisplit --dpi-desync-split-seqovl=1 --dpi-desync-split-pos=1 --dpi-desync-fake-tls="%FAKE%tls_clienthello_2.bin" --dpi-desync-ttl=5 --new ^
--filter-l3=ipv4 --filter-tcp=443 --ipset="%LISTS%ipset-cloudflare2.txt" --ipset-exclude-ip=1.1.1.1, 1.0.0.1, 212.109.195.93, 83.220.169.155, 141.105.71.21, 18.244.96.0/19, 18.244.128.0/19 --dpi-desync=multisplit --dpi-desync-split-seqovl=209 --dpi-desync-split-seqovl-pattern="%FAKE%tls_clienthello_5.bin" --dpi-desync-split-pos=sld+1 --dup=2 --dup-cutoff=n3 --new ^
--filter-udp=50000-50099 --dpi-desync=fake --dpi-desync-any-protocol --dpi-desync-cutoff=d2 --dpi-desync-fake-quic="%FAKE%quic_1.bin" --new ^
--filter-tcp=443 --hostlist-auto="%LISTS%autohostlist.txt" --dpi-desync=fake,multidisorder --dpi-desync-split-seqovl=1 --dpi-desync-split-pos=midsld,1 --dpi-desync-fooling=md5sig,badseq --dpi-desync-fake-tls="%FAKE%tls_clienthello_4.bin" --dpi-desync-autottl

