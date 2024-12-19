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
set LIST_TITLE=GoodbyeZapret: Discord Fix Beeline-Rostelekom
:: Путь к основному списку хостов
set LIST_PATH=%parentDir%lists\list-ultimate.txt
:: Путь к списку IP-адресов Discord
set DISCORD_IPSET_PATH=%parentDir%lists\ipset-discord.txt

start "%LIST_TITLE%" /min "%BIN%winws.exe" --wf-udp=50000-65535 ^
--filter-udp=50000-65535 --ipset="%DISCORD_IPSET_PATH%" --dpi-desync=fake --dpi-desync-any-protocol --dpi-desync-cutoff=d3 --dpi-desync-repeats=6 ^
--wf-l3=ipv4 --wf-tcp=443 --dpi-desync=syndata
--wf-l3=ipv4 --wf-tcp=443 --dpi-desync=syndata --dpi-desync-fake-syndata=/cygdrive/c/zapret-win-bundle-master/blockcheck/zapret/files/fake/tls_clienthello_iana_org.bin
--wf-l3=ipv4 --wf-tcp=443 --dpi-desync=syndata,split2
--wf-l3=ipv4 --wf-tcp=443 --dpi-desync=syndata,split2 --dpi-desync-fake-syndata=/cygdrive/c/zapret-win-bundle-master/blockcheck/zapret/files/fake/tls_clienthello_iana_org.bin
--wf-l3=ipv4 --wf-tcp=443 --dpi-desync=syndata,disorder2
--wf-l3=ipv4 --wf-tcp=443 --dpi-desync=syndata,disorder2 --dpi-desync-fake-syndata=/cygdrive/c/zapret-win-bundle-master/blockcheck/zapret/files/fake/tls_clienthello_iana_org.bin
--wf-l3=ipv4 --wf-tcp=443 --dpi-desync=syndata --wssize 1:6
--wf-l3=ipv4 --wf-tcp=443 --dpi-desync=syndata --dpi-desync-fake-syndata=/cygdrive/c/zapret-win-bundle-master/blockcheck/zapret/files/fake/tls_clienthello_iana_org.bin --wssize 1:6
--wf-l3=ipv4 --wf-tcp=443 --dpi-desync=syndata,split2 --wssize 1:6
--wf-l3=ipv4 --wf-tcp=443 --dpi-desync=syndata,split2 --dpi-desync-fake-syndata=/cygdrive/c/zapret-win-bundle-master/blockcheck/zapret/files/fake/tls_clienthello_iana_org.bin --wssize 1:6
--wf-l3=ipv4 --wf-tcp=443 --dpi-desync=syndata,disorder2 --wssize 1:6
--wf-l3=ipv4 --wf-tcp=443 --dpi-desync=syndata,disorder2 --dpi-desync-fake-syndata=/cygdrive/c/zapret-win-bundle-master/blockcheck/zapret/files/fake/tls_clienthello_iana_org.bin --wssize 1:6