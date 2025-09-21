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

REM Resolve install root early and prepare logging
for /f "delims=" %%A in ('powershell -NoProfile -Command "(Get-Item '%~dp0').Parent.FullName"') do set "ParentDirPath=%%A"
set "LogFile=%ParentDirPath%\Log.txt"

:: Запуск от имени администратора
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo  Requesting administrator privileges...
    call :log INFO "Requesting administrative privileges"
    powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs -ArgumentList '--elevated'" >nul 2>&1
    exit /b
)

for /f "delims=" %%A in ('powershell -NoProfile -Command "(Get-Item '%~dp0').Parent.FullName"') do set "ParentDirPath=%%A" 

chcp 65001 >nul 2>&1

mode con: cols=80 lines=25 >nul 2>&1

set "UpdaterVersion=2.6.1"

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

call :log START "Updater v%UpdaterVersion% / Path: %ParentDirPath%"


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
net stop "monkey" >nul 2>&1
sc delete "monkey" >nul 2>&1

taskkill /F /IM GoodbyeZapretTray.exe >nul 2>&1
if exist "%ParentDirPath%\tools\tray\GoodbyeZapretTray.exe" (
    schtasks /end /tn "GoodbyeZapretTray" >nul 2>&1
)


call :log INFO "Stopped and removed services GoodbyeZapret/WinDivert/monkey"

REM Чтение конфигурации из реестра (новый ключ) или миграция со старого
set "GoodbyeZapret_Config=None"

REM Попытка прочитать из нового расположения
for /f "tokens=2*" %%a in ('reg query "HKCU\Software\ALFiX inc.\GoodbyeZapret" /v "GoodbyeZapret_Config" 2^>nul ^| find /i "GoodbyeZapret_Config"') do set "GoodbyeZapret_Config=%%b"

REM Если не нашли, пробуем старый ключ и переносим
if /i "!GoodbyeZapret_Config!"=="None" (
  for /f "tokens=2*" %%a in ('reg query "HKCU\Software\ASX\Info" /v "GoodbyeZapret_Config" 2^>nul ^| find /i "GoodbyeZapret_Config"') do (
    set "GoodbyeZapret_Config=%%b"
    reg add "HKCU\Software\ALFiX inc.\GoodbyeZapret" /v "GoodbyeZapret_Config" /t REG_SZ /d "%%b" /f >nul
    reg delete "HKCU\Software\ASX\Info" /v "GoodbyeZapret_Config" /f >nul
  )
)

call :log INFO "Preferred config: !GoodbyeZapret_Config!"

echo         ^[*^] Скачивание файлов
set "ZipPath=%ParentDirPath%\GoodbyeZapret.zip"
set "DLURL=https://github.com/ALFiX01/GoodbyeZapret/raw/refs/heads/main/Files/GoodbyeZapret.zip"
if exist "%ZipPath%" del /q "%ZipPath%" >nul 2>&1

call :log INFO "Downloading archive from %DLURL% to %ZipPath%"

REM Скачивание через curl (с последующим fallback на PowerShell)
if exist "%ParentDirPath%\tools\curl\curl.exe" (
     set CURL="%ParentDirPath%\tools\curl\curl.exe"
) else (
    set CURL=curl
)

%CURL% -f -L -# -o "%ParentDirPath%\GoodbyeZapret.zip" "https://github.com/ALFiX01/GoodbyeZapret/raw/refs/heads/main/Files/GoodbyeZapret.zip" >nul 2>&1

for %%I in ("%ZipPath%") do set "FileSize=%%~zI"
if not exist "%ZipPath%" set "FileSize=0"
if %FileSize% LSS 100 (
  call :log INFO "Curl download looks invalid -size %FileSize%-. Trying PowerShell fallback"
  powershell -NoProfile -Command "try { Invoke-WebRequest -Uri '%DLURL%' -OutFile '%ZipPath%' -UseBasicParsing -ErrorAction Stop } catch { exit 1 }" >nul 2>&1
)

for %%I in ("%ZipPath%") do set "FileSize=%%~zI"
if not exist "%ZipPath%" set "FileSize=0"
if %FileSize% LSS 100 (
    echo       %COL%[91m ^[*^] Error - Файл GoodbyeZapret.zip поврежден или URL не доступен ^(Size %FileSize%^) %COL%[90m
    call :log ERROR "Download failed or corrupted. Size=%FileSize%"
    timeout /t 5 >nul
    exit /b 1
)

REM Удаляем только предыдущую распакованную версию (если существует)
if exist "%ParentDirPath%\GoodbyeZapret" (
  echo         ^[*^] Удаление предыдущей версии
  rd /s /q "%ParentDirPath%\GoodbyeZapret" >nul 2>&1
  call :log INFO "Removed previous extracted version folder"
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
    call :log INFO "Extracting archive to !TempExtract!"
    powershell -NoProfile -Command "try { Expand-Archive -Path '%ZipPath%' -DestinationPath '!TempExtract!' -Force -ErrorAction Stop } catch { exit 1 }" >nul 2>&1
    if %errorlevel% neq 0 (
        echo       %COL%[91m ^[*^] Error - Не удалось распаковать архив %COL%[90m
        call :log ERROR "Failed to extract archive"
        if exist "!TempExtract!" rd /s /q "!TempExtract!" >nul 2>&1
        chcp 65001 >nul 2>&1
        exit /b 1
    )
    chcp 65001 >nul 2>&1
    del /Q "%ZipPath%"

    REM Путь к распакованной директории проекта
    set "ExtractRoot=!TempExtract!"

    echo         ^[*^] Копирование основных файлов и папок (кроме tools и configs)
    robocopy "!ExtractRoot!" "%ParentDirPath%" /E /XD "tools" "configs" >nul
    call :log INFO "Copied core files"

    echo         ^[*^] Копирование файлов из папки tools
    if exist "!ExtractRoot!\tools" (
        mkdir "%ParentDirPath%\tools" >nul 2>&1
        robocopy "!ExtractRoot!\tools" "%ParentDirPath%\tools" *.* /NFL /NDL /NJH /NJS /NC /R:0 /W:0 >nul
        call :log INFO "Copied tools"
    )

    if exist "!ExtractRoot!\tools\tray" (
        mkdir "%ParentDirPath%\tools\tray" >nul 2>&1
        robocopy "!ExtractRoot!\tools\tray" "%ParentDirPath%\tools\tray" *.* /NFL /NDL /NJH /NJS /NC /R:0 /W:0 >nul
        call :log INFO "Copied tray"
    )

    if exist "!ExtractRoot!\tools\curl" (
        mkdir "%ParentDirPath%\tools\curl" >nul 2>&1
        robocopy "!ExtractRoot!\tools\curl" "%ParentDirPath%\tools\curl" *.* /NFL /NDL /NJH /NJS /NC /R:0 /W:0 >nul
        call :log INFO "Copied curl"
    )

    echo         ^[*^] Резервное копирование старых конфигов
    if exist "%ParentDirPath%\configs\Preset" (
        del /Q "%ParentDirPath%\configs\OLD_configs\*" >nul 2>&1
        mkdir "%ParentDirPath%\configs\OLD_configs" >nul 2>&1
        move /Y "%ParentDirPath%\configs\Preset\*" "%ParentDirPath%\configs\OLD_configs\" >nul 2>&1
        del /Q "%ParentDirPath%\configs\Preset\*" >nul 2>&1
        call :log INFO "Backup old configs"
    )

    echo         ^[*^] Копирование пресетов конфигов
    if exist "!ExtractRoot!\configs\Preset" (
        robocopy "!ExtractRoot!\configs\Preset" "%ParentDirPath%\configs\Preset" /E >nul
        call :log INFO "Copied preset configurations"
    )

    echo         ^[*^] Копирование Launcher файлов
    if exist "!TempExtract!\Launcher.bat" copy /Y "!TempExtract!\Launcher.bat" "%ParentDirPath%\" >nul
    if exist "!TempExtract!\Launcher.exe" copy /Y "!TempExtract!\Launcher.exe" "%ParentDirPath%\" >nul
    call :log INFO "Updated Launcher files if present"

    REM Удаляем временную директорию
    if exist "!TempExtract!" rd /s /q "!TempExtract!" >nul 2>&1
    call :log INFO "Cleanup temporary extraction folder"
)

tasklist | find /i "Winws" >nul
if %errorlevel% equ 0 (
    for /f "tokens=2*" %%a in ('reg query "HKCU\Software\ALFiX inc.\GoodbyeZapret" /v "GoodbyeZapret_LastStartConfig" 2^>nul ^| find /i "GoodbyeZapret_LastStartConfig"') do set "GoodbyeZapret_LastStartConfig=%%b"
) else (
    reg add "HKCU\Software\ALFiX inc.\GoodbyeZapret" /v "GoodbyeZapret_LastStartConfig" /t REG_SZ /d "None" /f >nul
)

if "%GoodbyeZapret_Config%" NEQ "None" (
    set "batPath="
    if exist "%ParentDirPath%\configs\Preset\%GoodbyeZapret_Config%.bat" set "batPath=Preset"
    if exist "%ParentDirPath%\configs\Custom\%GoodbyeZapret_Config%.bat" set "batPath=Custom"
    if exist "%ParentDirPath%\configs\%GoodbyeZapret_Config%.bat" set "batPath="
    call :log INFO "Starting service with configuration %GoodbyeZapret_Config%"
    if exist "%ParentDirPath%\configs\!batPath!\%GoodbyeZapret_Config%.bat" (
        sc create "GoodbyeZapret" binPath= "cmd.exe /c \"\"%ParentDirPath%\configs\!batPath!\%GoodbyeZapret_Config%.bat\"\"" >nul 2>&1
        sc config "GoodbyeZapret" start= auto >nul 2>&1
        if exist "%ParentDirPath%\tools\tray\GoodbyeZapretTray.exe" (
            schtasks /run /tn "GoodbyeZapretTray" >nul 2>&1
        )
        sc description GoodbyeZapret "%GoodbyeZapret_Config%" >nul 2>&1
        sc start "GoodbyeZapret" >nul 2>&1
        if %errorlevel% equ 0 (
            echo  ^[*^] Служба GoodbyeZapret успешно запущена
            call :log INFO "GoodbyeZapret service started"
        )
        echo  ^[*^] Обновление завершено
        call :log INFO "Update finished"
        start "" "%ParentDirPath%\Launcher.bat"
        timeout /t 1 >nul 2>&1
        exit
    ) else (
        call :log ERROR "Config file not found: %ParentDirPath%\configs\!batPath!\%GoodbyeZapret_Config%.bat"
        echo  ^[*^] Файл конфига %GoodbyeZapret_Config%.bat не найден
        timeout /t 2 >nul
        start "" "%ParentDirPath%\Launcher.bat"
        timeout /t 1 >nul
        exit
    )
) else (
    call :log INFO "Starting last used configuration: %GoodbyeZapret_LastStartConfig%"
    if defined GoodbyeZapret_LastStartConfig (
        rem Определяем путь к последней запусканной конфигурации среди Preset/Custom/корня
        set "cfgPath="
        if exist "%ParentDirPath%\configs\Preset\%GoodbyeZapret_LastStartConfig%" set "cfgPath=%ParentDirPath%\configs\Preset\%GoodbyeZapret_LastStartConfig%"
        if exist "%ParentDirPath%\configs\Custom\%GoodbyeZapret_LastStartConfig%" set "cfgPath=%ParentDirPath%\configs\Custom\%GoodbyeZapret_LastStartConfig%"
        if exist "%ParentDirPath%\configs\%GoodbyeZapret_LastStartConfig%" set "cfgPath=%ParentDirPath%\configs\%GoodbyeZapret_LastStartConfig%"
        if defined cfgPath (
            start "" "!cfgPath!"
            call :log INFO "Launched last used configuration"
        )
    )
    start "" "%ParentDirPath%\Launcher.bat"
    exit
)


:log
set "_lvl=%~1"
shift
set "_msg=%*"
set "_msg=!_msg:^>=^>!"
set "_msg=!_msg:^<=^<!"
set "_msg=!_msg:^|=^|!"
set "_msg=!_msg:&=^&!"
set "_msg=!_msg:(=^(!"
set "_msg=!_msg:)=^)!"
if /i "!_lvl!"=="START" (
  >> "%LogFile%" echo.
  >> "%LogFile%" echo ======================================================================
  >> "%LogFile%" echo [START] %date% %time:~0,8% - !_msg!
  >> "%LogFile%" echo ======================================================================
  exit /b 0
)
>> "%LogFile%" echo [!_lvl!] %time:~0,8% - !_msg!
exit /b 0