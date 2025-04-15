@echo off
chcp 65001 >nul

set currentDir=%~dp0
set currentDir=%currentDir:~0,-1%
for %%i in ("%currentDir%") do set parentDir=%%~dpi

cd /d "%parentDir%"

reg query "HKEY_CURRENT_USER\Software\ALFiX inc.\GoodbyeZapret" /v "Auto-update" >nul 2>&1
if %errorlevel% equ 0 (
    for /f "tokens=2*" %%a in ('reg query "HKEY_CURRENT_USER\Software\ALFiX inc.\GoodbyeZapret" /v "Auto-update" 2^>nul ^| find /i "Auto-update"') do set "Auto-update=%%b"
) else (
    set "Auto-update=0"
)

reg add "HKCU\Software\ALFiX inc.\GoodbyeZapret" /t REG_SZ /v "GoodbyeZapret_LastStartConfig" /d "%~nx0" /f >nul
if "%Auto-update%"=="1" ( Start "" "%parentDir%Tools\UpdateService.exe" )

set "BIN=%parentDir%bin\"
set "LIST_TITLE=GoodbyeZapret: UltimateFix split-sniext"
set "LISTS_FOLDER=%parentDir%lists"

start "%LIST_TITLE%" /min "%BIN%winws.exe" ^
--wf-tcp=80,443 --wf-udp=443,50000-59000 ^
--filter-udp=443 --hostlist="%LISTS_FOLDER%\youtubeQ.txt" --dpi-desync=fake,split --dpi-desync-repeats=2 --dpi-desync-fake-quic="%BIN%\quic_test_00.bin" --new ^
--filter-tcp=443 --hostlist="%LISTS_FOLDER%\youtube.txt" --dpi-desync=fake,split2 --dpi-desync-split-seqovl=2 --dpi-desync-split-pos=3 --dpi-desync-fake-tls="%BIN%\tls_clienthello_www_google_com.bin" --dpi-desync-ttl=2 --new ^
--filter-tcp=443 --hostlist="%LISTS_FOLDER%\discord.txt" --dpi-desync=fake,split2 --dpi-desync-split-tls=sniext --dpi-desync-fake-tls="%BIN%\tls_clienthello_www_google_com.bin" --new ^
--filter-udp=443 --hostlist="%LISTS_FOLDER%\discord.txt" --dpi-desync=fake,split2 --dpi-desync-repeats=6 --dpi-desync-fake-quic="%BIN%\quic_1.bin" --new ^
--filter-udp=50000-59000 --dpi-desync=fake,split2 --dpi-desync-any-protocol --dpi-desync-cutoff=d3 --dpi-desync-repeats=6 --new ^
--filter-tcp=443 --hostlist="%LISTS_FOLDER%\other.txt" --dpi-desync=fake,split2 --dpi-desync-split-seqovl=1 --dpi-desync-split-tls=sniext --dpi-desync-fake-tls="%BIN%\tls_clienthello_2.bin" --dpi-desync-ttl=2 --new ^
--filter-tcp=443 --hostlist="%LISTS_FOLDER%\faceinsta.txt" --dpi-desync=split2 --dpi-desync-split-seqovl=652 --dpi-desync-split-pos=2 --dpi-desync-split-seqovl-pattern="%BIN%\tls_clienthello_4.bin" --new ^
--filter-udp=443 --ipset="%LISTS_FOLDER%\ipset-cloudflare.txt" --dpi-desync=fake --dpi-desync-repeats=6 --dpi-desync-fake-quic="%BIN%quic_initial_www_google_com.bin" --new ^
--filter-tcp=80 --ipset="%LISTS_FOLDER%\ipset-cloudflare.txt" --dpi-desync=fake,split2 --dpi-desync-autottl=2 --dpi-desync-fooling=md5sig --new ^
--filter-tcp=443 --ipset="%LISTS_FOLDER%\ipset-cloudflare.txt" --dpi-desync=split --dpi-desync-split-pos=1 --dpi-desync-autottl --dpi-desync-fooling=badseq --dpi-desync-repeats=8