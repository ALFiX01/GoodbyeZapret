::[Bat To Exe Converter]
::
::YAwzoRdxOk+EWAjk
::fBw5plQjdCuDJOlwRJyA8qq3/Ngy6dtnt1etA6hLN6o2QAOtgN4bfZzS3bqyB+8c7kf9cKwsxmhfjPcKDQ1RfR2lIAY3pg4=
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
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo  Requesting administrator privileges...
    powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs -ArgumentList '--elevated'" >nul 2>&1
    exit /b
)

for /f "delims=" %%A in ('powershell -NoProfile -Command "(Get-Item '%~dp0').Parent.FullName"') do set "ParentDirPath=%%A" 

chcp 65001 >nul 2>&1

mode con: cols=80 lines=25 >nul 2>&1

set "UpdaterVersion=2.1"

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
echo        %COL%[37m Добро пожаловать в программу обновления GoodbyeZapret
echo        %COL%[90m Для корректной работы рекомендуется отключить антивирус
echo        %COL%[37m ──────────────────── ВЫПОЛНЯЕТСЯ ОБНОВЛЕНИЕ ──────────────────── %COL%[90m
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
echo         ^[*^] Скачивание файлов
curl -g -L -# -o "%ParentDirPath%\GoodbyeZapret.zip" "https://github.com/ALFiX01/GoodbyeZapret/raw/refs/heads/main/Files/GoodbyeZapret.zip" >nul 2>&1

for %%I in ("%ParentDirPath%\GoodbyeZapret.zip") do set "FileSize=%%~zI"
if %FileSize% LSS 100 (
    echo       %COL%[91m ^[*^] Error - Файл GoodbyeZapret.zip поврежден или URL не доступен ^(Size %FileSize%^) %COL%[90m
    pause
    del /Q "%ParentDirPath%\GoodbyeZapret.zip"
    exit
)

REM Удаляем только предыдущую распакованную версию (если существует)
if exist "%ParentDirPath%\GoodbyeZapret" (
  echo         ^[*^] Удаление предыдущей версии
  rd /s /q "%ParentDirPath%\GoodbyeZapret" >nul 2>&1
)

if exist "%ParentDirPath%\Launcher.bat" del /Q "%ParentDirPath%\Launcher.bat" >nul 2>&1
if exist "%ParentDirPath%\Launcher.exe" del /Q "%ParentDirPath%\Launcher.exe" >nul 2>&1

if not exist "%ParentDirPath%\GoodbyeZapret.zip" (
    echo        %COL%[91m ^[*^] Error: File not found: %ParentDirPath%\GoodbyeZapret.zip %COL%[90m
    timeout /t 5 >nul
    exit
) else (
    echo         ^[*^] Распаковка файлов
    REM Создаем временную директорию для распаковки
    set "TempExtract=%ParentDirPath%\GZ_Temp"
    if exist "!TempExtract!" rd /s /q "!TempExtract!" >nul 2>&1
    mkdir "!TempExtract!" >nul 2>&1

    chcp 850 >nul 2>&1
    powershell -NoProfile Expand-Archive '%ParentDirPath%\GoodbyeZapret.zip' -DestinationPath '!TempExtract!' >nul 2>&1
    chcp 65001 >nul 2>&1
    del /Q "%ParentDirPath%\GoodbyeZapret.zip"

    REM Путь к распакованной директории проекта
    set "ExtractRoot=!TempExtract!"

    echo         ^[*^] Копирование основных файлов и папок (кроме tools и configs)
    robocopy "!ExtractRoot!" "%ParentDirPath%" /E /XD "tools" "configs" >nul

    echo         ^[*^] Копирование файлов из папки tools
    if exist "!ExtractRoot!\tools" (
        mkdir "%ParentDirPath%\tools" >nul 2>&1
        robocopy "!ExtractRoot!\tools" "%ParentDirPath%\tools" *.* /NFL /NDL /NJH /NJS /NC /R:0 /W:0 >nul
    )

    echo         ^[*^] Копирование пресетов конфигурации
    if exist "!ExtractRoot!\configs\Preset" (
        robocopy "!ExtractRoot!\configs\Preset" "%ParentDirPath%\configs\Preset" /E >nul
    )

    echo         ^[*^] Копирование Launcher файлов
    if exist "!TempExtract!\Launcher.bat" copy /Y "!TempExtract!\Launcher.bat" "%ParentDirPath%" >nul
    if exist "!TempExtract!\Launcher.exe" copy /Y "!TempExtract!\Launcher.exe" "%ParentDirPath%" >nul

    REM Удаляем временную директорию
    if exist "!TempExtract!" rd /s /q "!TempExtract!" >nul 2>&1
)

tasklist | find /i "Winws" >nul
if %errorlevel% equ 0 (
    for /f "tokens=2*" %%a in ('reg query "HKCU\Software\ALFiX inc.\GoodbyeZapret" /v "GoodbyeZapret_LastStartConfig" 2^>nul ^| find /i "GoodbyeZapret_LastStartConfig"') do set "GoodbyeZapret_LastStartConfig=%%b"
) else (
    reg add "HKCU\Software\ALFiX inc.\GoodbyeZapret" /v "GoodbyeZapret_LastStartConfig" /t REG_SZ /d "None" /f >nul
)

if "%GoodbyeZapret_Config%" NEQ "None" (
    if exist "%ParentDirPath%\configs\Preset\%GoodbyeZapret_Config%" set "batPath=Preset"
    if exist "%ParentDirPath%\configs\Custom\%GoodbyeZapret_Config%" set "batPath=Custom"
    if exist "%ParentDirPath%\configs\%GoodbyeZapret_Config%" set "batPath="
    echo [INFO] %time:~0,8% - Update Check - Запуск конфигурации %GoodbyeZapret_Config% >> "%ParentDirPath%\Log.txt"
    if exist "%ParentDirPath%\configs\!batPath!\%GoodbyeZapret_Config%.bat" (
        sc create "GoodbyeZapret" binPath= "cmd.exe /c \"\"%ParentDirPath%\configs\!batPath!\%GoodbyeZapret_Config%.bat\"\""
        sc config "GoodbyeZapret" start= auto
        sc description GoodbyeZapret "%GoodbyeZapret_Config%" >nul 2>&1
        sc start "GoodbyeZapret" >nul 2>&1
        if %errorlevel% equ 0 (
            echo  ^[*^] Служба GoodbyeZapret успешно запущена
        )
        echo  ^[*^] Обновление завершено
        if exist "%ParentDirPath%\Log.txt" (
            del /f /q "%ParentDirPath%\Log.txt" >nul
        )
        start "" "%ParentDirPath%\Launcher.bat"
        timeout /t 1 >nul 2>&1
        exit
    ) else (
        echo [INFO] %time:~0,8% - Update Check - Error: File not found: %ParentDirPath%\configs\!batPath!\%GoodbyeZapret_Config%.bat >> "%ParentDirPath%\Log.txt"
        echo  ^[*^] Файл конфигурации %GoodbyeZapret_Config%.bat не найден
        timeout /t 2 >nul
        start "" "%ParentDirPath%\Launcher.bat"
        timeout /t 1 >nul
        exit
    )
) else (
    echo [INFO] %time:~0,8% - Update Check - Запуск конфигурации %GoodbyeZapret_LastStartConfig% >> "%ParentDirPath%\Log.txt"
    if defined GoodbyeZapret_LastStartConfig (
        if exist "%ParentDirPath%\configs\!batPath!\%GoodbyeZapret_LastStartConfig%" (
            start "" "%ParentDirPath%\configs\!batPath!\%GoodbyeZapret_LastStartConfig%" 
        ) else (
            if exist "%ParentDirPath%\configs\%GoodbyeZapret_LastStartConfig%" (
                start "" "%ParentDirPath%\configs\%GoodbyeZapret_LastStartConfig%"
            )
        )
    )
    if exist "%ParentDirPath%\Log.txt" (
    del /f /q "%ParentDirPath%\Log.txt" >nul
    )
    start "" "%ParentDirPath%\Launcher.bat"
    exit
)