::[Bat To Exe Converter]
::
::YAwzoRdxOk+EWAjk
::fBw5plQjdCuDJOlwRJyA8qq3/Ngy6dtnt1etA6hLN6o2QAOtgN6PjD8DamM+8FDKWpjYUpki0nhDnfENHAldai6tbxk9qmFM+G2GOKc=
::YAwzuBVtJxjWCl3EqQJgSA==
::ZR4luwNxJguZRRnk
::Yhs/ulQjdF+5
::cxAkpRVqdFKZSjk=
::cBs/ulQjdF+5
::ZR41oxFsdFKZSDk=
::eBoioBt6dFKZSDk=
::cRo6pxp7LAbNWATEpCI=
::egkzugNsPRvcWATEpCI=
::dAsiuh18IRvcCxnZtBJQ
::cRYluBh/LU+EWAnk
::YxY4rhs+aU+JeA==
::cxY6rQJ7JhzQF1fEqQJQ
::ZQ05rAF9IBncCkqN+0xwdVs0
::ZQ05rAF9IAHYFVzEqQJQ
::eg0/rx1wNQPfEVWB+kM9LVsJDGQ=
::fBEirQZwNQPfEVWB+kM9LVsJDGQ=
::cRolqwZ3JBvQF1fEqQJQ
::dhA7uBVwLU+EWDk=
::YQ03rBFzNR3SWATElA==
::dhAmsQZ3MwfNWATElA==
::ZQ0/vhVqMQ3MEVWAtB9wSA==
::Zg8zqx1/OA3MEVWAtB9wSA==
::dhA7pRFwIByZRRnk
::Zh4grVQjdCyDJGyX8VAjFD9VQg2LMFeeCbYJ5e31+/m7hUQJfPc9RKjU1bCMOeUp61X2cIIR8HNWndgwOQtcfwaufDMBuWpDomGXecKEtm8=
::YB416Ek+ZW8=
::
::
::978f952a14a936cc963da21a135fa983
@echo off

setlocal EnableDelayedExpansion

:: Запуск от имени администратора
reg add HKLM /F >nul 2>&1
if %errorlevel% neq 0 (
    start "" /wait /I /min powershell -NoProfile -Command "start -verb runas '%~s0'" && exit /b
    exit /b
)

for /f "delims=" %%A in ('powershell -NoProfile -Command "(Get-Item '%~dp0').FullName"') do set "ParentDirPath=%%A" 

set "currentDir=%~dp0"
set "currentDir=%currentDir:~0,-1%\GoodbyeZapret"
for %%i in ("%currentDir%") do set parentDir=%%~dpi
set "ProjecDir=%ParentDirPath%GoodbyeZapret"

if not exist "%ProjecDir%" (
    mkdir "%ProjecDir%"
)

chcp 65001 >nul 2>&1

mode con: cols=80 lines=25 >nul 2>&1

set "UpdaterVersion=1.2"

REM Цветной текст
for /F "tokens=1,2 delims=#" %%a in ('"prompt #$H#$E# & echo on & for %%b in (1) do rem"') do (set "DEL=%%a" & set "COL=%%b")

cls
title Установщик программного обеспечения от ALFiX, Inc. (v%UpdaterVersion%)
echo.
echo        %COL%[36m ┌──────────────────────────────────────────────────────────────┐
echo         ^│     %COL%[91m ██╗███╗   ██╗███████╗████████╗ █████╗ ██╗     ██╗      %COL%[36m ^│
echo         ^│     %COL%[91m ██║████╗  ██║██╔════╝╚══██╔══╝██╔══██╗██║     ██║      %COL%[36m ^│
echo         ^│     %COL%[91m ██║██╔██╗ ██║███████╗   ██║   ███████║██║     ██║      %COL%[36m ^│
echo         ^│     %COL%[91m ██║██║╚██╗██║╚════██║   ██║   ██╔══██║██║     ██║      %COL%[36m ^│
echo         ^│     %COL%[91m ██║██║ ╚████║███████║   ██║   ██║  ██║███████╗███████╗ %COL%[36m ^│
echo         ^│     %COL%[91m ╚═╝╚═╝  ╚═══╝╚══════╝   ╚═╝   ╚═╝  ╚═╝╚══════╝╚══════╝ %COL%[36m ^│
echo         └──────────────────────────────────────────────────────────────┘

echo.
echo        %COL%[37m Добро пожаловать в программу установки GoodbyeZapret
echo        %COL%[90m Для корректной работы нужно отключить антивирус
echo.
echo        %COL%[91m Выключите антивирус и нажмите Enter
pause >nul
echo        %COL%[93m Добавьте папку в исключения антивируса и нажмите Enter... %COL%[90m
pause >nul
timeout /t 1 >nul
cls
title Установщик программного обеспечения от ALFiX, Inc. (v%UpdaterVersion%)
echo.
echo        %COL%[36m ┌──────────────────────────────────────────────────────────────┐
echo         ^│     %COL%[91m ██╗███╗   ██╗███████╗████████╗ █████╗ ██╗     ██╗      %COL%[36m ^│
echo         ^│     %COL%[91m ██║████╗  ██║██╔════╝╚══██╔══╝██╔══██╗██║     ██║      %COL%[36m ^│
echo         ^│     %COL%[91m ██║██╔██╗ ██║███████╗   ██║   ███████║██║     ██║      %COL%[36m ^│
echo         ^│     %COL%[91m ██║██║╚██╗██║╚════██║   ██║   ██╔══██║██║     ██║      %COL%[36m ^│
echo         ^│     %COL%[91m ██║██║ ╚████║███████║   ██║   ██║  ██║███████╗███████╗ %COL%[36m ^│
echo         ^│     %COL%[91m ╚═╝╚═╝  ╚═══╝╚══════╝   ╚═╝   ╚═╝  ╚═╝╚══════╝╚══════╝ %COL%[36m ^│
echo         └──────────────────────────────────────────────────────────────┘
echo.
echo        %COL%[37m Добро пожаловать в программу установки GoodbyeZapret
echo        %COL%[90m Для корректной работы нужно отключить антивирус
echo.
echo        %COL%[37m ──────────────────── ВЫПОЛНЯЕТСЯ УСТАНОВКА ───────────────────── %COL%[90m
echo.


timeout /t 1 >nul 2>&1
echo         ^[*^] Отключение текущего конфига GoodbyeZapret
net stop GoodbyeZapret >nul 2>&1
echo         ^[*^] Удаление службы GoodbyeZapret
sc delete GoodbyeZapret >nul 2>&1
echo         ^[*^] Остановка процессов WinDivert
taskkill /F /IM winws.exe >nul 2>&1
net stop "WinDivert" >nul 2>&1
sc delete "WinDivert" >nul 2>&1


curl -4 -s -L -I --connect-timeout 3 -o nul "https://github.com/ALFiX01/GoodbyeZapret/raw/refs/heads/main/Files/GoodbyeZapret.zip"
if errorlevel 1 (
    echo        %COL%[91m ^[*^] Error: Failed to connect to GoodbyeZapret server %COL%[90m
    timeout /t 5 >nul
    exit
)

echo         ^[*^] Скачивание файлов
curl -g -L -# -o "%ProjecDir%\GoodbyeZapret.zip" "https://github.com/ALFiX01/GoodbyeZapret/raw/refs/heads/main/Files/GoodbyeZapret.zip" >nul 2>&1

for %%I in ("%ProjecDir%\GoodbyeZapret.zip") do set FileSize=%%~zI
if %FileSize% LSS 100 (
    echo       %COL%[91m ^[*^] Error - Файл GoodbyeZapret.zip поврежден или URL не доступен ^(Size %FileSize%^) %COL%[90m
    pause
    del /Q "%ProjecDir%\GoodbyeZapret.zip"
    exit
)

REM Удаляем только предыдущую распакованную версию (если существует)
if exist "%ProjecDir%\GoodbyeZapret" (
  echo         ^[*^] Удаление предыдущей версии
  rd /s /q "%ProjecDir%\GoodbyeZapret" >nul 2>&1
)

if exist "%ProjecDir%\GoodbyeZapret.zip" (
    echo         ^[*^] Распаковка файлов
    chcp 850 >nul 2>&1
    powershell -NoProfile Expand-Archive '%ProjecDir%\GoodbyeZapret.zip' -DestinationPath '%ProjecDir%' >nul 2>&1
    chcp 65001 >nul 2>&1
    del /Q "%ProjecDir%\GoodbyeZapret.zip"
) else (
    echo        %COL%[91m ^[*^] Error: File not found: %ProjecDir%\GoodbyeZapret.zip %COL%[90m
    timeout /t 5 >nul
    exit
)

if exist "%ProjecDir%\Launcher.exe" (
    start "" "%ProjecDir%\Launcher.exe"
) else (
    echo        %COL%[91m ^[*^] Error: File not found: %ProjecDir%\Launcher.exe %COL%[90m
    timeout /t 5 >nul
    exit
)
