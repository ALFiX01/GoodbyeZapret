::[Bat To Exe Converter]
::
::YAwzoRdxOk+EWAjk
::fBw5plQjdCuDJOl7RaKA9quH/eQy7NtmtmmtA9RLEVpWEpCtilLtyFVrAoivE9hTwlDmSZ8u2XRmv8QDCBlBeyiqfh0xvSNss3OhMtSVtAGvQ0uGhg==
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

chcp 65001 >nul 2>&1
:: Запуск от имени администратора
reg add HKLM /F >nul 2>&1
if %errorlevel% neq 0 (
    start "" /wait /I /min powershell -NoProfile -Command "start -verb runas '%~s0'" && exit /b
    exit /b
)

setlocal EnableDelayedExpansion

mode con: cols=80 lines=25 >nul 2>&1

set "UpdaterVersion=1.0"

REM Цветной текст
for /F "tokens=1,2 delims=#" %%a in ('"prompt #$H#$E# & echo on & for %%b in (1) do rem"') do (set "DEL=%%a" & set "COL=%%b")

cls
title Установщик программного обеспечения от ALFiX, Inc. (v%UpdaterVersion%)
echo.
echo        %COL%[36m ┌──────────────────────────────────────────────────────────────┐
echo         ^│     %COL%[91m ██╗   ██╗██████╗ ██████╗  █████╗ ████████╗███████╗     %COL%[36m ^│
echo         ^│     %COL%[91m ██║   ██║██╔══██╗██╔══██╗██╔══██╗╚══██╔══╝██╔════╝     %COL%[36m ^│
echo         ^│     %COL%[91m ██║   ██║██████╔╝██║  ██║███████║   ██║   █████╗       %COL%[36m ^│
echo         ^│     %COL%[91m ██║   ██║██╔═══╝ ██║  ██║██╔══██║   ██║   ██╔══╝       %COL%[36m ^│
echo         ^│     %COL%[91m ╚██████╔╝██║     ██████╔╝██║  ██║   ██║   ███████╗     %COL%[36m ^│
echo         ^│     %COL%[91m  ╚═════╝ ╚═╝     ╚═════╝ ╚═╝  ╚═╝   ╚═╝   ╚══════╝     %COL%[36m ^│
echo         └──────────────────────────────────────────────────────────────┘
echo.
echo  %COL%[37m Добро пожаловать в программу обновления GoodbyeZapret
echo  %COL%[90m Для корректной работы рекомендуется отключить антивирус
echo  %COL%[37m ──────────────────── ВЫПОЛНЯЕТСЯ ОБНОВЛЕНИЕ ───────────────────── %COL%[90m
echo.


timeout /t 1 >nul 2>&1
echo  ^[*^] Отключение текущего конфига GoodbyeZapret
net stop GoodbyeZapret >nul 2>&1
echo  ^[*^] Удаление службы GoodbyeZapret
sc delete GoodbyeZapret >nul 2>&1
echo  ^[*^] Остановка процессов WinDivert
taskkill /F /IM winws.exe >nul 2>&1
net stop "WinDivert" >nul 2>&1
sc delete "WinDivert" >nul 2>&1
net stop "WinDivert14" >nul 2>&1
sc delete "WinDivert14" >nul 2>&1

reg query "HKCU\Software\ALFiX inc.\GoodbyeZapret" /v "GoodbyeZapret_Config" >nul 2>&1
if %errorlevel% equ 0 (
    for /f "tokens=2*" %%a in ('reg query "HKCU\Software\ALFiX inc.\GoodbyeZapret" /v "GoodbyeZapret_Config" 2^>nul ^| find /i "GoodbyeZapret_Config"') do (
        set "GoodbyeZapret_Config=%%b"
        goto :end_GoodbyeZapret_Config
    )
) else (
    set "GoodbyeZapret_Config=None"
    goto :end_GoodbyeZapret_Config
)

REM Попытка перенести значение из старого реестра в новый
reg query "HKCU\Software\ASX\Info" /v "GoodbyeZapret_Config" >nul 2>&1
if %errorlevel% equ 0 (
    for /f "tokens=2*" %%a in ('reg query "HKCU\Software\ASX\Info" /v "GoodbyeZapret_Config" 2^>nul ^| find /i "GoodbyeZapret_Config"') do (
    set "GoodbyeZapret_Config=%%b"
    reg add "HKCU\Software\ALFiX inc.\GoodbyeZapret" /v "GoodbyeZapret_Config" /t REG_SZ /d "%%b" /f >nul
    reg delete "HKCU\Software\ASX\Info" /v "GoodbyeZapret_Config" /f >nul
    goto :end_GoodbyeZapret_Config
    )
)

REM Если ключ нигде не найден, установить значение по умолчанию

:end_GoodbyeZapret_Config
echo  ^[*^] Скачивание файлов
curl -g -L -# -o %TEMP%\GoodbyeZapret.zip "https://github.com/ALFiX01/GoodbyeZapret/raw/refs/heads/main/Files/GoodbyeZapret.zip" >nul 2>&1

for %%I in ("%TEMP%\GoodbyeZapret.zip") do set FileSize=%%~zI
if %FileSize% LSS 100 (
    echo %COL%[91m ^[*^] Error - Файл GoodbyeZapret.zip поврежден или URL не доступен ^(Size %FileSize%^) %COL%[90m
    pause
    del /Q "%TEMP%\GoodbyeZapret.zip"
    exit
)


if exist "%SystemDrive%\GoodbyeZapret" (
  rd /s /q "%SystemDrive%\GoodbyeZapret" >nul 2>&1
)

if exist "%TEMP%\GoodbyeZapret.zip" (
    echo  ^[*^] Распаковка файлов
    chcp 850 >nul 2>&1
    powershell -NoProfile Expand-Archive '%TEMP%\GoodbyeZapret.zip' -DestinationPath '%SystemDrive%\GoodbyeZapret' >nul 2>&1
    chcp 65001 >nul 2>&1
) else (
    echo %COL%[91m ^[*^] Error: File not found: %TEMP%\GoodbyeZapret.zip %COL%[90m
    timeout /t 5 >nul
    exit
)


if "%GoodbyeZapret_Config%" NEQ "None" (
    if exist "%SystemDrive%\GoodbyeZapret\Configs\%GoodbyeZapret_Config%.bat" (
        sc create "GoodbyeZapret" binPath= "cmd.exe /c \"%SystemDrive%\GoodbyeZapret\Configs\%GoodbyeZapret_Config%.bat\"" start= auto
        sc description GoodbyeZapret "%GoodbyeZapret_Config%" >nul 2>&1
        sc start "GoodbyeZapret" >nul 2>&1
        if %errorlevel% equ 0 (
            echo  ^[*^] Служба GoodbyeZapret успешно запущена
        )
        echo  ^[*^] Обновление завершено
        start "" "%SystemDrive%\GoodbyeZapret\Launcher.exe"
        timeout /t 2 >nul 2>&1
        exit
    ) else (
        echo  ^[*^] Файл конфигурации %GoodbyeZapret_Config%.bat не найден
        timeout /t 2 >nul
        start "" "%SystemDrive%\GoodbyeZapret\Launcher.exe"
        timeout /t 1 >nul
        exit
    )
) else (
    start "" "%SystemDrive%\GoodbyeZapret\Launcher.exe"
)