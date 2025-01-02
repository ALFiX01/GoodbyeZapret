@echo off
chcp 65001 >nul
:: 65001 - UTF-8

:: Получаем текущую папку BAT-файла
set currentDir=%~dp0
:: Убираем последний слэш
set currentDir=%currentDir:~0,-1%
:: Переходим в родительскую папку
for %%i in ("%currentDir%") do set parentDir=%%~dpi

:: Переходим в родительскую директорию
cd /d "%parentDir%"
:: Устанавливаем путь к папке bin
set BIN=%parentDir%bin\

:: Устанавливаем название программы
set LIST_TITLE=GoodbyeZapret: Ultimate Fix
:: Путь к основному списку хостов
set LIST_PATH=%parentDir%lists\list-ultimate.txt
:: Путь к списку IP-адресов Discord
set DISCORD_IPSET_PATH=%parentDir%lists\ipset-discord.txt

start "%LIST_TITLE%" /min "%BIN%winws.exe" ^
--wf-tcp=80,443 --wf-udp=443,50000-65535 ^
--filter-udp=443 --hostlist="%LIST_PATH%" --dpi-desync=fake --dpi-desync-repeats=6 --dpi-desync-fake-quic="%BIN%quic_initial_www_google_com.bin" --new ^
--filter-udp=50000-65535 --ipset="%DISCORD_IPSET_PATH%" --dpi-desync=fake --dpi-desync-any-protocol --dpi-desync-cutoff=d3 --dpi-desync-repeats=6 --dpi-desync-fake-quic="%BIN%quic_initial_www_google_com.bin" --new ^
--filter-tcp=80 --hostlist="%LIST_PATH%" --dpi-desync=fake,split2 --dpi-desync-autottl=2 --dpi-desync-fooling=md5sig --new ^
--filter-tcp=443 --hostlist="%LIST_PATH%" --dpi-desync=fake,split --dpi-desync-autottl=2 --dpi-desync-repeats=6 --dpi-desync-fooling=badseq --dpi-desync-fake-tls="%BIN%tls_clienthello_www_google_com.bin"






Invoke-ZapretStrategy -StrategyName "MGTS v1" -Arguments "--wf-tcp=80,443 --wf-udp=443,50000-59000 $YQ2 $YT7 $DISUDP5 $DISIP3 $DISTCP9 $other1 $faceinsta"

$YT1 = "--filter-tcp=443 --hostlist=""$LISTS\youtube.txt"" --dpi-desync=fake,split2 --dpi-desync-split-seqovl=2 --dpi-desync-split-pos=3 --dpi-desync-fake-tls=""$BIN\tls_clienthello_www_google_com.bin"" --dpi-desync-ttl=3 --new"
$YT5 = "--filter-tcp=443 --hostlist=""$LISTS\youtube.txt"" --dpi-desync=fake,split2 --dpi-desync-split-seqovl=2 --dpi-desync-split-pos=3 --dpi-desync-fake-tls=""$BIN\tls_clienthello_2.bin"" --dpi-desync-autottl=2 --new"
$YT2 = "--filter-tcp=443 --hostlist=""$LISTS\youtube.txt"" --dpi-desync=fake,split2 --dpi-desync-split-seqovl=2 --dpi-desync-split-pos=3 --new"
$YT4 = "--filter-tcp=443 --hostlist=""$LISTS\youtube.txt"" --dpi-desync=split --dpi-desync-split-pos=1 --dpi-desync-fooling=badseq --dpi-desync-repeats=10 --dpi-desync-autottl=2 --new"
$YT8 = "--filter-tcp=443 --hostlist=""$LISTS\youtube.txt"" --dpi-desync=split --dpi-desync-split-pos=1 --dpi-desync-fooling=badseq --dpi-desync-repeats=10 --dpi-desync-cutoff=d2 --dpi-desync-ttl=3 --new"
$YT7 = "--filter-tcp=443 --hostlist=""$LISTS\youtube.txt"" --dpi-desync=split --dpi-desync-split-pos=1 --dpi-desync-fooling=badseq --dpi-desync-repeats=10 --dpi-desync-ttl=4 --new"
$YT3 = "--filter-tcp=443 --hostlist=""$LISTS\youtube.txt"" --dpi-desync=split --dpi-desync-split-seqovl=1 --dpi-desync-split-tls=sniext --dpi-desync-fake-tls=""$BIN\tls_clienthello_www_google_com.bin"" --dpi-desync-ttl=1 --new"
$YT6 = "--filter-tcp=443 --hostlist=""$LISTS\youtube.txt"" --dpi-desync=fake,split2 --dpi-desync-split-seqovl=1 --dpi-desync-split-tls=sniext --dpi-desync-fake-tls=""$BIN\tls_clienthello_www_google_com.bin"" --dpi-desync-ttl=4 --new"
$YT9 = "--filter-tcp=443 --hostlist=""$LISTS\youtube.txt"" --dpi-desync=fake,multisplit --dpi-desync-split-seqovl=2 --dpi-desync-split-pos=3 --dpi-desync-fake-tls=""$BIN\tls_clienthello_2.bin"" --dpi-desync-ttl=3 --new"

$YGV1 = "--filter-tcp=443 --hostlist=""$LISTS\youtubeGV.txt"" --dpi-desync=split --dpi-desync-split-pos=1 --dpi-desync-fooling=badseq --dpi-desync-repeats=10 --dpi-desync-cutoff=d2 --dpi-desync-ttl=4 --new"
$YGV2 = "--filter-tcp=443 --hostlist=""$LISTS\youtubeGV.txt"" --dpi-desync=fakedsplit --dpi-desync-split-pos=1 --dpi-desync-fooling=badseq --dpi-desync-repeats=10 --dpi-desync-ttl=4 --new"
$YGV3 = "--filter-tcp=443 --hostlist=""$LISTS\youtubeGV.txt"" --dpi-desync=multisplit --dpi-desync-split-seqovl=1 --dpi-desync-split-pos=midsld-1 --new"

$YRTMP1 = "--filter-tcp=443 --ipset=""$LISTS\russia-youtube-rtmps.txt"" --dpi-desync=syndata --dpi-desync-fake-syndata=""$BIN\tls_clienthello_4.bin"" --dpi-desync-autottl --new"

$DISTCP1 = "--filter-tcp=443 --hostlist=""$LISTS\discord.txt"" --dpi-desync=split --dpi-desync-split-pos=1 --dpi-desync-fooling=badseq --dpi-desync-repeats=10 --dpi-desync-ttl=4 --new"
$DISTCP2 = "--filter-tcp=443 --hostlist=""$LISTS\discord.txt"" --dpi-desync=split2 --dpi-desync-split-seqovl=652 --dpi-desync-split-pos=2 --dpi-desync-split-seqovl-pattern=""$BIN\tls_clienthello_2.bin"" --new"
$DISTCP3 = "--filter-tcp=443 --hostlist=""$LISTS\discord.txt"" --dpi-desync=fake,split --dpi-desync-repeats=6 --dpi-desync-fooling=badseq --dpi-desync-fake-tls=""$BIN\tls_clienthello_www_google_com.bin"" --new"
$DISTCP4 = "--filter-tcp=443 --hostlist=""$LISTS\discord.txt"" --dpi-desync=fake,split2 --dpi-desync-ttl=1 --dpi-desync-autottl=5 --dpi-desync-repeats=6 --dpi-desync-fake-tls=""$BIN\tls_clienthello_sberbank_ru.bin"" --new"
$DISTCP5 = "--filter-tcp=443 --hostlist=""$LISTS\discord.txt"" --dpi-desync=syndata --dpi-desync-fake-syndata=""$BIN\tls_clienthello_3.bin"" --dpi-desync-ttl=5 --new"
$DISTCP6 = "--filter-tcp=443 --hostlist=""$LISTS\discord.txt"" --dpi-desync=fake,split --dpi-desync-autottl=2 --dpi-desync-repeats=6 --dpi-desync-fooling=badseq --dpi-desync-fake-tls=""$BIN\tls_clienthello_www_google_com.bin"" --new"
$DISTCP7 = "--filter-tcp=443 --hostlist=""$LISTS\discord.txt"" --dpi-desync=fake,split2 --dpi-desync-split-seqovl=1 --dpi-desync-split-tls=sniext --dpi-desync-fake-tls=""$BIN\tls_clienthello_www_google_com.bin"" --dpi-desync-ttl=4 --new"
$DISTCP8 = "--filter-tcp=443 --hostlist=""$LISTS\discord.txt"" --dpi-desync=fake,split2 --dpi-desync-split-seqovl=1 --dpi-desync-split-tls=sniext --dpi-desync-fake-tls=""$BIN\tls_clienthello_www_google_com.bin"" --dpi-desync-ttl=2 --new"
$DISTCP9 = "--filter-tcp=443 --hostlist=""$LISTS\discord.txt"" --dpi-desync=split --dpi-desync-split-pos=1 --dpi-desync-fooling=badseq --dpi-desync-repeats=10 --dpi-desync-autottl --new"
$DISTCP10 = "--filter-tcp=443 --hostlist=""$LISTS\discord.txt"" --dpi-desync=split --dpi-desync-split-pos=1 --dpi-desync-fooling=badseq --dpi-desync-repeats=10 --dpi-desync-ttl=3 --new"
$DISTCP11 = "--filter-tcp=443 --hostlist=""$LISTS\discord.txt"" --dpi-desync=fakedsplit --dpi-desync-split-pos=1 --dpi-desync-fooling=badseq --dpi-desync-repeats=10 --dpi-desync-autottl --new"
$DISTCP12 = "--filter-tcp=443 --hostlist=""$LISTS\youtube.txt"" --dpi-desync=multisplit --dpi-desync-split-seqovl=1 --dpi-desync-split-pos=midsld+1 --new"
$DISTCP80 = "--filter-tcp=80 --hostlist=""$LISTS\discord.txt"" --dpi-desync=fake,split2 --dpi-desync-autottl=2 --dpi-desync-fooling=md5sig --new"


$UDP1 = "--filter-udp=50000-59000 --dpi-desync=fake,split2 --dpi-desync-any-protocol --dpi-desync-cutoff=d2 --dpi-desync-fake-quic=""$BIN\quic_test_00.bin"" --new"
#$UDP6 = "--filter-udp=50000-65535 --dpi-desync=fake,split2 --dpi-desync-any-protocol --dpi-desync-cutoff=d2 --dpi-desync-fake-quic=""$BIN\quic_test_00.bin"" --new"
$UDP2 = "--filter-udp=50000-59000 --dpi-desync=fake --dpi-desync-any-protocol --dpi-desync-cutoff=d3 --dpi-desync-repeats=6 --new"
$UDP3 = "--filter-udp=50000-59000 --dpi-desync=fake --dpi-desync-any-protocol --dpi-desync-cutoff=d3 --dpi-desync-repeats=6 --dpi-desync-fake-quic=""$BIN\quic_initial_www_google_com.bin"" --new"
$UDP4 = "--filter-udp=50000-59000 --dpi-desync=fake,tamper --dpi-desync-any-protocol --dpi-desync-cutoff=d3 --dpi-desync-repeats=6 --dpi-desync-fake-quic=""$BIN\quic_initial_www_google_com.bin"" --new"
$UDP5 = "--filter-udp=50000-59000 --dpi-desync=fake,tamper --dpi-desync-any-protocol --dpi-desync-cutoff=n5 --dpi-desync-repeats=10 --dpi-desync-fake-quic=""$BIN\quic_initial_www_google_com.bin"" --new"
$UDP7 = "--filter-udp=50000-50090 --dpi-desync=fake --dpi-desync-any-protocol --dpi-desync-cutoff=n3 --new"

$YQ1 = "--filter-udp=443 --hostlist=""$LISTS\youtubeQ.txt"" --dpi-desync=fake --dpi-desync-repeats=2 --dpi-desync-cutoff=n2 --dpi-desync-fake-quic=""$BIN\quic_test_00.bin"" --new"
$YQ2 = "--filter-udp=443 --hostlist=""$LISTS\youtubeQ.txt"" --dpi-desync=fake --dpi-desync-repeats=4 --dpi-desync-fake-quic=""$BIN\quic_initial_www_google_com.bin"" --new"
$YQ3 = "--filter-udp=443 --hostlist=""$LISTS\youtubeQ.txt"" --dpi-desync=fake --dpi-desync-repeats=4 --dpi-desync-fake-quic=""$BIN\quic_1.bin"" --new"
$YQ4 = "--filter-udp=443 --hostlist=""$LISTS\youtubeQ.txt"" --dpi-desync=fake --dpi-desync-repeats=11 --dpi-desync-fake-quic=""$BIN\quic_initial_www_google_com.bin"" --new"
$YQ5 = "--filter-udp=443 --hostlist=""$LISTS\youtubeQ.txt"" --dpi-desync=fake --dpi-desync-repeats=2 --dpi-desync-cutoff=n2 --dpi-desync-fake-quic=""$BIN\quic_initial_www_google_com.bin"" --new"
$YQ6 = "--filter-udp=443 --hostlist=""$LISTS\youtubeQ.txt"" --dpi-desync=fake --dpi-desync-fake-quic=""$BIN\quic_1.bin"" --dpi-desync-repeats=4 --new"
$YQ7 = "--filter-udp=443 --hostlist=""$LISTS\youtubeQ.txt"" --dpi-desync=fake,udplen --dpi-desync-udplen-increment=2 --dpi-desync-fake-quic=""$BIN\quic_3.bin"" --dpi-desync-cutoff=n3 --dpi-desync-repeats=2 --new"

$DISUDP1 = "--filter-udp=443 --hostlist=""$LISTS\discord.txt"" --dpi-desync=fake --dpi-desync-udplen-increment=10 --dpi-desync-repeats=7 --dpi-desync-udplen-pattern=0xDEADBEEF --dpi-desync-fake-quic=""$BIN\quic_test_00.bin"" --dpi-desync-cutoff=n2 --new"
$DISUDP2 = "--filter-udp=443 --hostlist=""$LISTS\discord.txt"" --dpi-desync=fake --dpi-desync-repeats=6 --dpi-desync-fake-quic=""$BIN\quic_1.bin"" --new"
$DISUDP3 = "--filter-udp=443 --hostlist=""$LISTS\discord.txt"" --dpi-desync=fake --dpi-desync-repeats=6 --dpi-desync-fake-quic=""$BIN\quic_initial_www_google_com.bin"" --new"
$DISUDP4 = "--filter-udp=443 --hostlist=""$LISTS\discord.txt"" --dpi-desync=fake --dpi-desync-repeats=6 --dpi-desync-fake-quic=""$BIN\quic_initial_vk_com.bin"" --new"
$DISUDP5 = "--filter-udp=443 --hostlist=""$LISTS\discord.txt"" --dpi-desync=fake --dpi-desync-udplen-increment=10 --dpi-desync-repeats=7 --dpi-desync-udplen-pattern=0xDEADBEEF --dpi-desync-fake-quic=""$BIN\quic_initial_www_google_com.bin"" --new"
$DISUDP6 = "--filter-udp=443 --hostlist=""$LISTS\discord.txt"" --dpi-desync=fake,split2 --dpi-desync-udplen-increment=10 --dpi-desync-repeats=6 --dpi-desync-udplen-pattern=0xDEADBEEF --dpi-desync-fake-quic=""$BIN\quic_initial_www_google_com.bin"" --new"
$DISUDP7 = "--filter-udp=443 --hostlist=""$LISTS\discord.txt"" --dpi-desync=fake --dpi-desync-udplen-increment=10 --dpi-desync-repeats=6 --dpi-desync-udplen-pattern=0xDEADBEEF --dpi-desync-fake-quic=""$BIN\quic_initial_www_google_com.bin"" --new"
$DISUDP8 = "--filter-udp=443 --hostlist=""$LISTS\discord.txt"" --dpi-desync=fake --dpi-desync-udplen-increment=10 --dpi-desync-udplen-pattern=0xDEADBEEF --dpi-desync-fake-quic=""$BIN\quic_2.bin"" --dpi-desync-repeats=8 --dpi-desync-cutoff=n2 --new"
$DISUDP9 = "--filter-udp=443 --hostlist=""$LISTS\discord.txt"" --dpi-desync=fake,udplen --dpi-desync-udplen-increment=5 --dpi-desync-udplen-pattern=0xDEADBEEF --dpi-desync-fake-quic=""$BIN\quic_2.bin"" --dpi-desync-repeats=7 --dpi-desync-cutoff=n2 --new"

$DISIP1 = "--filter-udp=50000-50100 --ipset=""$LISTS\ipset-discord.txt"" --dpi-desync=fake --dpi-desync-any-protocol --dpi-desync-cutoff=d3 --dpi-desync-repeats=6 --new"
$DISIP2 = "--filter-udp=50000-65535 --ipset=""$LISTS\ipset-discord.txt"" --dpi-desync=fake --dpi-desync-any-protocol --dpi-desync-cutoff=d3 --dpi-desync-repeats=6 --new"
$DISIP3 = "--filter-udp=50000-59000 --dpi-desync=fake --dpi-desync-any-protocol --dpi-desync-cutoff=n2 --dpi-desync-fake-quic=""$BIN\quic_initial_www_google_com.bin"" --new"
$DISIP4 = "--filter-udp=50000-50099 --dpi-desync=fake --dpi-desync-any-protocol --dpi-desync-cutoff=d2 --dpi-desync-fake-quic=""$BIN\quic_1.bin"" -- new"
$DISIP5 = "--filter-tcp=443 --ipset=""$LISTS\ipset-discord.txt"" --dpi-desync=syndata --dpi-desync-fake-syndata=""$BIN\tls_clienthello_3.bin"" --dpi-desync-autottl --new"

$faceinsta = "--filter-tcp=443 --hostlist=""$LISTS\faceinsta.txt"" --dpi-desync=split2 --dpi-desync-split-seqovl=652 --dpi-desync-split-pos=2 --dpi-desync-split-seqovl-pattern=""$BIN\tls_clienthello_4.bin"" -- new"

$other1 = "--filter-tcp=443 --hostlist=""$LISTS\other.txt"" --dpi-desync=fake,split2 --dpi-desync-split-seqovl=1 --dpi-desync-split-tls=sniext --dpi-desync-fake-tls=""$BIN\tls_clienthello_2.bin"" --dpi-desync-ttl=2 --new"
$other2 = "--filter-tcp=80 --hostlist=""$LISTS\other.txt"" --dpi-desync=fake,multisplit --dpi-desync-fooling=md5sig --dpi-desync-autottl --new"
$other3 = "--filter-tcp=443 --hostlist=""$LISTS\other.txt"" --dpi-desync=fake,multisplit --dpi-desync-split-seqovl=1 --dpi-desync-split-pos=1 --dpi-desync-fake-tls=""$BIN\tls_clienthello_2.bin"" --dpi-desync-ttl=5 --new"
$other4 = "--filter-tcp=443 --hostlist=""$LISTS\other.txt"" --dpi-desync=fake,multisplit --dpi-desync-split-seqovl=1 --dpi-desync-split-pos=midsld-1 --dpi-desync-fooling=md5sig,badseq --dpi-desync-fake-tls=""$BIN\tls_clienthello_4.bin"" --dpi-desync-autottl --new"



start "%LIST_TITLE%" /min "%BIN%winws.exe" ^
--wf-tcp=80,443 --wf-udp=443,50000-59000 ^
--filter-udp=443 --hostlist="%LISTS%\youtubeQ.txt" --dpi-desync=fake --dpi-desync-repeats=4 --dpi-desync-fake-quic="%BIN%\quic_initial_www_google_com.bin" --new ^
--filter-tcp=443 --hostlist="%LISTS%\youtube.txt" --dpi-desync=split --dpi-desync-split-pos=1 --dpi-desync-fooling=badseq --dpi-desync-repeats=10 --dpi-desync-ttl=4 --new ^
--filter-udp=443 --hostlist="%LISTS%\discord.txt" --dpi-desync=fake --dpi-desync-udplen-increment=10 --dpi-desync-repeats=7 --dpi-desync-udplen-pattern=0xDEADBEEF --dpi-desync-fake-quic="%BIN%\quic_initial_www_google_com.bin" --new ^
--filter-udp=50000-59000 --dpi-desync=fake --dpi-desync-any-protocol --dpi-desync-cutoff=n2 --dpi-desync-fake-quic="%BIN%\quic_initial_www_google_com.bin" --new ^
--filter-tcp=443 --hostlist="%LISTS%\discord.txt" --dpi-desync=split --dpi-desync-split-pos=1 --dpi-desync-fooling=badseq --dpi-desync-repeats=10 --dpi-desync-autottl --new ^
--filter-tcp=443 --hostlist="%LISTS%\other.txt" --dpi-desync=fake,split2 --dpi-desync-split-seqovl=1 --dpi-desync-split-tls=sniext --dpi-desync-fake-tls="%BIN%\tls_clienthello_2.bin" --dpi-desync-ttl=2 --new ^
--filter-tcp=443 --hostlist="%LISTS%\faceinsta.txt" --dpi-desync=split2 --dpi-desync-split-seqovl=652 --dpi-desync-split-pos=2 --dpi-desync-split-seqovl-pattern="%BIN%\tls_clienthello_4.bin" --new