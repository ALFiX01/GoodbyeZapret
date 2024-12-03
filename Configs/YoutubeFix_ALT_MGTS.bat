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
set LIST_TITLE=GoodbyeZapret: YouTube Fix MGTS
:: Путь к основному списку хостов
set LIST_PATH=%parentDir%lists\list-youtube.txt

start "%LIST_TITLE%" /min "%BIN%winws.exe" ^
--wf-tcp=80,443 --wf-udp=443,50000-65535 ^
--filter-udp=443 --hostlist="%LIST_PATH%" --dpi-desync=fake --dpi-desync-udplen-increment=10 --dpi-desync-repeats=6 --dpi-desync-udplen-pattern=0xDEADBEEF --dpi-desync-fake-quic="%BIN%quic_initial_www_google_com.bin" --new ^
--filter-udp=50000-65535 --dpi-desync=fake --dpi-desync-any-protocol --dpi-desync-cutoff=d3 --dpi-desync-repeats=6 --dpi-desync-fake-quic="%BIN%quic_initial_www_google_com.bin" --new ^
--filter-tcp=80 --hostlist="%LIST_PATH%" --dpi-desync=fake --dpi-desync-autottl=2 --dpi-desync-fooling=md5sig --new ^
--filter-tcp=443 --hostlist="%LIST_PATH%" --dpi-desync=fake --dpi-desync-autottl=2 --dpi-desync-repeats=6 --dpi-desync-fooling=badseq --dpi-desync-fake-tls="%BIN%tls_clienthello_www_google_com.bin"