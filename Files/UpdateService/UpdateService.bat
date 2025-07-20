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
::Zh4grVQjdCyDJGyX8VAjFD9VQg2LMFeeCbYJ5e31+/m7hUQJfPc9RKjU1bCMOeUp61X2cIIR8HNWndgwOQtcfwauXQomv2dBs1iwJ8OdpwrST1qf70g1VWBsggM=
::YB416Ek+ZG8=
::
::
::978f952a14a936cc963da21a135fa983
@echo off

setlocal EnableDelayedExpansion

for /f "delims=" %%A in ('powershell -NoProfile -Command "(Get-Item '%~dp0').Parent.FullName"') do set "ParentDirPath=%%A" 

chcp 65001 >nul 2>&1

:CHECK_INTERNET
set InternetCheckCount=0
ping -n 1 google.ru >nul
if errorlevel 1 (
    echo [INFO] %time:~0,8% - Update Check - Подключение к Интернету НЕ установлено ^(Попытка: %InternetCheckCount%^)... >> "%ParentDirPath%\Log.txt"
    set /a "InternetCheckCount+=1"
    if "%InternetCheckCount%"=="8" (
        echo [INFO] %time:~0,8% - Update Check - Превышено количество попыток подключения к Интернету, завершение работы скрипта... >> "%ParentDirPath%\Log.txt"
        exit
    )
    timeout /t 2 >nul
    goto CHECK_INTERNET
) else (
    echo [INFO] %time:~0,8% - Update Check - Подключение к Интернету установлено... >> "%ParentDirPath%\Log.txt"
)

:: --- Read Current Version Info ---
set "Current_GoodbyeZapret_version="
set "Current_GoodbyeZapret_version_code="
set "Last_Used_Config="

reg query "HKEY_CURRENT_USER\Software\ALFiX inc.\GoodbyeZapret" /v "GoodbyeZapret_Version" >nul 2>&1
if %errorlevel% equ 0 (
    for /f "tokens=3" %%i in ('reg query "HKEY_CURRENT_USER\Software\ALFiX inc.\GoodbyeZapret" /v "GoodbyeZapret_Version" ^| findstr /i "GoodbyeZapret_Version"') do set "Current_GoodbyeZapret_version=%%i"
)

:: Загрузка нового файла GZ_Updater.bat
if exist "%TEMP%\GZ_Updater.bat" del /s /q /f "%TEMP%\GZ_Updater.bat" >nul 2>&1
curl -s -o "%TEMP%\GZ_Updater.bat" "https://raw.githubusercontent.com/ALFiX01/GoodbyeZapret/refs/heads/main/GoodbyeZapret_Version" 
if errorlevel 1 (
    echo ERROR - Ошибка связи с сервером проверки обновлений GoodbyeZapret
    
)

:: Загрузка нового файла Updater.exe
if not exist "%ParentDirPath%\tools\Updater.exe" (
    curl -g -L -# -o "%ParentDirPath%\tools\Updater.exe" "https://github.com/ALFiX01/GoodbyeZapret/raw/refs/heads/main/Files/Updater/Updater.exe" >nul 2>&1
)

:: Выполнение загруженного файла Updater.bat
call "%TEMP%\GZ_Updater.bat" >nul 2>&1
if errorlevel 1 (
    echo ERROR - Ошибка при выполнении GZ_Updater.bat
)

set "UpdateNeed=No"

reg query "HKEY_CURRENT_USER\Software\ALFiX inc.\GoodbyeZapret" /v "GoodbyeZapret_Version_code" >nul 2>&1
if %errorlevel% equ 0 (
    for /f "tokens=3" %%i in ('reg query "HKEY_CURRENT_USER\Software\ALFiX inc.\GoodbyeZapret" /v "GoodbyeZapret_Version_code" ^| findstr /i "GoodbyeZapret_Version_code"') do set "Current_GoodbyeZapret_version_code=%%i"
)

:: Проверка, изменилась ли версия
echo "%Actual_GoodbyeZapret_version_code%" | findstr /i "%Current_GoodbyeZapret_version_code%" >nul
if errorlevel 1 (
    echo - available update
    set "UpdateNeed=Yes"
    echo [INFO] %time:~0,8% - Update Check - Обнаружено обновление >> "%ParentDirPath%\Log.txt"
) else (
    set "VersionFound=1"
    echo - no update
    rem Если лог-файл существует, удаляем его
    if exist "%ParentDirPath%\Log.txt" (
        del /f /q "%ParentDirPath%\Log.txt" >nul
    )
)

if %UpdateNeed% equ Yes ( goto update_screen ) else ( exit /b )

:update_screen
:: Запуск от имени администратора
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [INFO] %time:~0,8% - Update Check - Requesting administrative privileges >> "%ParentDirPath%\Log.txt"
    echo Requesting administrative privileges...
    start "" /wait /I /min powershell -NoProfile -Command "Start-Process -FilePath '%~s0' -Verb RunAs"
    exit /b
)
set "UpdaterVersion=1.0"

REM Цветной текст
for /F "tokens=1,2 delims=#" %%a in ('"prompt #$H#$E# & echo on & for %%b in (1) do rem"') do (set "DEL=%%a" & set "COL=%%b")

cls
title GoodbyeZapret UpdateService
echo [INFO] %time:~0,8% - Update Check - Добро пожаловать в программу обновления GoodbyeZapret >> "%ParentDirPath%\Log.txt"
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

:end_GoodbyeZapret_Config
echo [INFO] %time:~0,8% - Update Check - Скачивание файлов !Actual_GoodbyeZapret_version! >> "%ParentDirPath%\Log.txt"
echo  ^[*^] Скачивание файлов !Actual_GoodbyeZapret_version!
curl -g -L -# -o "%TEMP%\GoodbyeZapret.zip" "https://github.com/ALFiX01/GoodbyeZapret/raw/refs/heads/main/Files/GoodbyeZapret.zip" >nul 2>&1

for %%I in ("%TEMP%\GoodbyeZapret.zip") do set FileSize=%%~zI
if %FileSize% LSS 100 (
    echo %COL%[91m ^[*^] Error - Файл GoodbyeZapret.zip поврежден или URL не доступен ^(Size %FileSize%^) %COL%[90m
    pause
    del /Q "%TEMP%\GoodbyeZapret.zip"
    exit
)


if exist "%ParentDirPath%" (
  rd /s /q "%ParentDirPath%" >nul 2>&1
)

if exist "%TEMP%\GoodbyeZapret.zip" (
    echo [INFO] %time:~0,8% - Update Check - Распаковка файлов >> "%ParentDirPath%\Log.txt"
    echo  ^[*^] Распаковка файлов
    chcp 850 >nul 2>&1
    powershell -NoProfile Expand-Archive '%TEMP%\GoodbyeZapret.zip' -DestinationPath '%ParentDirPath%' >nul 2>&1
    chcp 65001 >nul 2>&1
) else (
    echo [INFO] %time:~0,8% - Update Check - Error: File not found: %TEMP%\GoodbyeZapret.zip >> "%ParentDirPath%\Log.txt"
    echo %COL%[91m ^[*^] Error: File not found: %TEMP%\GoodbyeZapret.zip %COL%[90m
    timeout /t 5 >nul
    exit
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
    start "" "%ParentDirPath%\Launcher.bat"
    exit
)