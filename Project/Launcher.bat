::[Bat To Exe Converter]
::
::YAwzoRdxOk+EWAjk
::fBw5plQjdCuDJOlwRJyA8qq3/Ngy6dtnt1etA6hLN6o2QAOtgN6PjD8DamM+8FDKWpjYUpki0nhDnfENHAldai6tbxk9qmFM+G2GOKc=
::YAwzuBVtJxjWCl3EqQJgSA==
::ZR4luwNxJguZRRnk
::Yhs/ulQjdF65
::cxAkpRVqdFKZSjk=
::cBs/ulQjdF65
::ZR41oxFsdFKZSDk=
::eBoioBt6dFKZSDk=
::cRo6pxp7LAbNWATEpCI=
::egkzugNsPRvcWATEpCI=
::dAsiuh18IRvcCxnZtBJQ
::cRYluBh/LU+EWAnk
::YxY4rhs+aU+IeA==
::cxY6rQJ7JhzQF1fEqQJhZk4aHmQ=
::ZQ05rAF9IBncCkqN+0xwdVs0
::ZQ05rAF9IAHYFVzEqQIXJxRQTh2HBmqqFLAIiA==
::eg0/rx1wNQPfEVWB+kM9LVsJDGQ=
::fBEirQZwNQPfEVWB+kM9LVsJDGQ=
::cRolqwZ3JBvQF1fEqQJQ
::dhA7uBVwLU+EWHio0ksIaBJaT2Q=
::YQ03rBFzNR3SWATElA==
::dhAmsQZ3MwfNWATElA==
::ZQ0/vhVqMQ3MEVWAtB9wSA==
::Zg8zqx1/OA3MEVWAtB9wSA==
::dhA7pRFwIByZRRnk
::Zh4grVQjdCyDJGyX8VAjFD9VQg2LMFeeCbYJ5e31+/m7hUQJfPc9RKjU1bCMOeUp61X2cIIR5mhVks4PGCd0fwelbQcxuyBHrmHl
::YB416Ek+ZW8=
::
::
::978f952a14a936cc963da21a135fa983
@echo off
:: Copyright (C) 2025 ALFiX, Inc.
:: Any tampering with the program code is forbidden (Запрещены любые вмешательства)

:: Запуск от имени администратора
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Requesting administrative privileges...
    start "" /wait /I /min powershell -NoProfile -Command "Start-Process -FilePath '%~s0' -Verb RunAs"
    exit /b
)

setlocal EnableDelayedExpansion

set "Current_GoodbyeZapret_version=1.8.0"
set "Current_GoodbyeZapret_version_code=19MAY01"

REM Настройки UAC
set "L_ConsentPromptBehaviorAdmin=0"
set "L_ConsentPromptBehaviorUser=3"
set "L_EnableInstallerDetection=1"
set "L_EnableLUA=1"
set "L_EnableSecureUIAPaths=1"
set "L_FilterAdministratorToken=0"
set "L_PromptOnSecureDesktop=0"

REM Путь к реестру UAC
set "UAC_HKLM=HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"

REM Основной цикл проверки и обновления значений UAC
set "UAC_check=Success"
for %%i in (
    ConsentPromptBehaviorAdmin
    ConsentPromptBehaviorUser
    EnableInstallerDetection
    EnableLUA
    EnableSecureUIAPaths
    FilterAdministratorToken
    PromptOnSecureDesktop
) do (
    for /f "tokens=3" %%a in ('reg query "%UAC_HKLM%" /v "%%i" 2^>nul ^| find /i "%%i"') do (
        REM Удаляем префикс "0x" из текущего значения
        set "current_value=%%a"
        set "current_value=!current_value:0x=!"

        REM Получаем ожидаемое значение
        call set "expected_value=%%L_%%i%%"

        REM Сравниваем значения
        if not "!current_value!" == "!expected_value!" (
            echo [WARN ] %TIME% - Параметр UAC '%%i' имеет неожиданное значение. Текущее: 0x!current_value!, Ожидаемое: 0x!expected_value!.
            reg add "%UAC_HKLM%" /v "%%i" /t REG_DWORD /d !expected_value! /f >nul 2>&1
            if errorlevel 1 (
                echo [ERROR] %TIME% - Не удалось изменить параметр UAC '%%i'. Возможно, недостаточно прав.
                set "UAC_check=Error"
            ) else (
                echo [INFO ] %TIME% - Параметр UAC '%%i' успешно изменён на 0x!expected_value!.
            )
        )
    )
)

REM reg add HKCU\Console /v VirtualTerminalLevel /t REG_DWORD /d 1 /f >nul

:: Получение информации о текущем языке интерфейса и выход, если язык не ru-RU
for /f "tokens=3" %%i in ('reg query "HKCU\Control Panel\International" /v "LocaleName" ^| findstr /i "LocaleName"') do set "WinLang=%%i"
if /I "%WinLang%" NEQ "ru-RU" (
    cls
    echo.
    echo   Error 01: Invalid interface language. Requires ru-RU. Current: %WinLang%
    timeout /t 4 >nul
    exit /b
)

reg query "HKEY_CURRENT_USER\Software\ALFiX inc.\GoodbyeZapret" /v "GoodbyeZapret_Version" >nul 2>&1
if %errorlevel% neq 0 (
    reg add "HKEY_CURRENT_USER\Software\ALFiX inc.\GoodbyeZapret" /v "GoodbyeZapret_Version" /t REG_SZ /d "%Current_GoodbyeZapret_version%" /f >nul 2>&1
) else (
    for /f "tokens=3" %%i in ('reg query "HKEY_CURRENT_USER\Software\ALFiX inc.\GoodbyeZapret" /v "GoodbyeZapret_Version" ^| findstr /i "GoodbyeZapret_Version"') do set "Registry_Version=%%i"
    if not "!Registry_Version!"=="%Current_GoodbyeZapret_version%" (
        reg add "HKEY_CURRENT_USER\Software\ALFiX inc.\GoodbyeZapret" /v "GoodbyeZapret_Version" /t REG_SZ /d "%Current_GoodbyeZapret_version%" /f >nul 2>&1
    )
)

reg query "HKEY_CURRENT_USER\Software\ALFiX inc.\GoodbyeZapret" /v "GoodbyeZapret_Version_code" >nul 2>&1
if %errorlevel% neq 0 (
    reg add "HKEY_CURRENT_USER\Software\ALFiX inc.\GoodbyeZapret" /v "GoodbyeZapret_Version_code" /t REG_SZ /d "%Current_GoodbyeZapret_version_code%" /f >nul 2>&1
) else (
    for /f "tokens=3" %%i in ('reg query "HKEY_CURRENT_USER\Software\ALFiX inc.\GoodbyeZapret" /v "GoodbyeZapret_Version_code" ^| findstr /i "GoodbyeZapret_Version_code"') do set "Registry_Version_code=%%i"
    if not "!Registry_Version!"=="%Current_GoodbyeZapret_version%" (
        echo Component service update currently in progress. Thank you for your patience.
        reg add "HKEY_CURRENT_USER\Software\ALFiX inc.\GoodbyeZapret" /v "GoodbyeZapret_Version_code" /t REG_SZ /d "%Current_GoodbyeZapret_version_code%" /f >nul 2>&1
        if exist "%SystemDrive%\GoodbyeZapret\tools\UpdateService.exe" del "%SystemDrive%\GoodbyeZapret\tools\UpdateService.exe" >nul 2>&1
        curl -g -L -# -o "%SystemDrive%\GoodbyeZapret\tools\UpdateService.exe" "https://github.com/ALFiX01/GoodbyeZapret/raw/refs/heads/main/Files/UpdateService/UpdateService.exe" >nul 2>&1
        if exist "%SystemDrive%\GoodbyeZapret\tools\Updater.exe" del "%SystemDrive%\GoodbyeZapret\tools\Updater.exe" >nul 2>&1
        curl -g -L -# -o "%SystemDrive%\GoodbyeZapret\tools\Updater.exe" "https://github.com/ALFiX01/GoodbyeZapret/raw/refs/heads/main/Files/Updater/Updater.exe" >nul 2>&1
    )
)

set "WiFi=Off"
set "CheckURL=https://google.ru"

echo Checking connectivity to update server ^(%CheckURL%^)...
:: Используем curl для проверки доступности основного хоста обновлений
:: -s: Silent mode (без прогресс-бара)
:: -L: Следовать редиректам
:: --head: Получить только заголовки (быстрее, меньше данных)
:: -m 10: Таймаут 8 секунд
:: -o NUL: Отправить тело ответа в никуда (нам нужен только код возврата)
curl -s -L --head -m 8 -o NUL "%CheckURL%"

IF %ERRORLEVEL% EQU 0 (
    REM Успешно, сервер доступен
    echo Connection successful.
    set "WiFi=On"
) ELSE (
    REM Попытка не удалась
    cls
    echo.
    echo   Error 02: Cannot reach the update server.
    echo   Connection check to %CheckURL% failed ^(curl errorlevel: %ERRORLEVEL%^).
    echo   Please check your internet connection, firewall settings,
    echo   or if %CheckURL% is accessible from your network.
    set "WiFi=Off"
    timeout /t 3 >nul
)

if Not exist %SystemDrive%\GoodbyeZapret (
    goto install_screen
)

:RR

set "BatCount=0"
set "sourcePath=%~dp0"

for %%f in ("%sourcePath%configs\*.bat") do (
    set /a "BatCount+=1"
)

set /a ListBatCount=BatCount+25
mode con: cols=92 lines=%ListBatCount% >nul 2>&1

REM Цветной текст
for /F "tokens=1,2 delims=#" %%a in ('"prompt #$H#$E# & echo on & for %%b in (1) do rem"') do (set "DEL=%%a" & set "COL=%%b")

chcp 65001 >nul 2>&1

:GoodbyeZapret_Menu
:: tasklist /FI "IMAGENAME eq winws.exe" 2>NUL | find /I /N "winws.exe" >NUL
:: if "%ERRORLEVEL%"=="0" ( 
    REM Процесс winws.exe уже запущен.
:: ) else (
::     sc start "GoodbyeZapret" >nul 2>&1
:: )

set "CheckStatus=WithoutChecked"
set "sourcePath=%~dp0"

set "GoodbyeZapret_Current=Не выбран"
set "GoodbyeZapret_Current_TEXT=Текущий конфиг - Не выбран"
set "GoodbyeZapret_Config=Не выбран"
set "GoodbyeZapret_Old=Отсутствует"

reg query HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\GoodbyeZapret /v Description >nul 2>&1
if %errorlevel% equ 0 (
   REM Ключ GoodbyeZapret_Version существует.
   for /f "tokens=2*" %%a in ('reg query "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\GoodbyeZapret" /v "Description" 2^>nul ^| find /i "Description"') do set "GoodbyeZapret_Current=%%b"
)


reg query "HKEY_CURRENT_USER\Software\ALFiX inc.\GoodbyeZapret" /v "GoodbyeZapret_OldConfig" >nul 2>&1
if %errorlevel% equ 0 (
   REM Ключ GoodbyeZapret_OldConfig существует.
   for /f "tokens=2*" %%a in ('reg query "HKEY_CURRENT_USER\Software\ALFiX inc.\GoodbyeZapret" /v "GoodbyeZapret_OldConfig" 2^>nul ^| find /i "GoodbyeZapret_OldConfig"') do set "GoodbyeZapret_Old=%%b"
)

set "RepairNeed=No"

if not exist "%SystemDrive%\GoodbyeZapret\bin\version.txt" (
    set "RepairNeed=Yes"
) else if not exist "%SystemDrive%\GoodbyeZapret\lists\version.txt" (
    set "RepairNeed=Yes"
) else if not exist "%SystemDrive%\GoodbyeZapret\configs\version.txt" (
    set "RepairNeed=Yes"
)

if %WiFi%==On (
    if "%RepairNeed%" equ "Yes" (
        echo   Error 03: Critical error. GoodbyeZapret needs to be reinstalled.
        echo   Starting the reinstallation...
        :: Загрузка нового файла Updater.exe
        timeout /t 2 >nul
        if not exist "%SystemDrive%\GoodbyeZapret\tools\Updater.exe" (
        curl -g -L -# -o "%SystemDrive%\GoodbyeZapret\tools\Updater.exe" "https://github.com/ALFiX01/GoodbyeZapret/raw/refs/heads/main/Files/Updater/Updater.exe" >nul 2>&1
        ) else (
            timeout /t 2 >nul
            start "" "%SystemDrive%\GoodbyeZapret\tools\Updater.exe"
            exit /b
        )
    )
)

tasklist | find /i "Winws.exe" >nul
if %errorlevel% equ 0 (
    for /f "tokens=2*" %%a in ('reg query "HKCU\Software\ALFiX inc.\GoodbyeZapret" /v "GoodbyeZapret_LastStartConfig" 2^>nul ^| find /i "GoodbyeZapret_LastStartConfig"') do set "GoodbyeZapret_LastStartConfig=%%b"
) else (
    reg add "HKCU\Software\ALFiX inc.\GoodbyeZapret" /v "GoodbyeZapret_LastStartConfig" /t REG_SZ /d "None" /f >nul
)


for /f "usebackq delims=" %%a in ("%SystemDrive%\GoodbyeZapret\bin\version.txt") do set "Current_Winws_version=%%a"
for /f "usebackq delims=" %%a in ("%SystemDrive%\GoodbyeZapret\lists\version.txt") do set "Current_List_version=%%a"
for /f "usebackq delims=" %%a in ("%SystemDrive%\GoodbyeZapret\configs\version.txt") do set "Current_configs_version=%%a"

:: Загрузка нового файла GZ_Updater.bat

if %WiFi%==Off ( goto skip_for_wifi )

if exist "%TEMP%\GZ_Updater.bat" del /s /q /f "%TEMP%\GZ_Updater.bat" >nul 2>&1
curl -s -o "%TEMP%\GZ_Updater.bat" "https://raw.githubusercontent.com/ALFiX01/GoodbyeZapret/refs/heads/main/GoodbyeZapret_Version" 
if errorlevel 1 (
    echo   Error 04: Server error. Error connecting to update check server GoodbyeZapret
) 

:: Загрузка нового файла Updater.exe
if not exist "%SystemDrive%\GoodbyeZapret\tools\Updater.exe" (
    curl -g -L -# -o "%SystemDrive%\GoodbyeZapret\tools\Updater.exe" "https://github.com/ALFiX01/GoodbyeZapret/raw/refs/heads/main/Files/Updater/Updater.exe" >nul 2>&1
)

set FileSize=0
for %%I in ("%TEMP%\GZ_Updater.bat") do set FileSize=%%~zI
if %FileSize% LSS 15 (
    set "CheckStatus=NoChecked"
    echo   Error 05: FileCheck error. File GZ_Updater.bat is corrupted or URL is not available ^(Size %FileSize%^)
    echo.
    del /Q "%TEMP%\GZ_Updater.bat"
    pause
) else (
    set "CheckStatus=Checked"
)


:: Выполнение загруженного файла Updater.bat
call "%TEMP%\GZ_Updater.bat" >nul 2>&1
if errorlevel 1 (
    echo   Error 05: Start error. Error while executing GZ_Updater.bat
)

REM Версии GoodbyeZapret
set "GoodbyeZapretVersion_New=%Actual_GoodbyeZapret_version%"
set "GoodbyeZapretVersion=%Current_GoodbyeZapret_version%"

set "UpdateNeed=No"

if %StatusProject%==0 (
    cls
    echo.
    echo  Я был рад быть вам полезным, но пришло время прощаться.
    echo  Проект GoodbyeZapret закрыт.
    echo.
    sc query "GoodbyeZapret" >nul 2>&1
    net stop "GoodbyeZapret" >nul 2>&1
    sc delete "GoodbyeZapret" >nul 2>&1
    tasklist /FI "IMAGENAME eq winws.exe" 2>NUL | find /I /N "winws.exe" >NUL
    taskkill /F /IM winws.exe >nul 2>&1
    net stop "WinDivert" >nul 2>&1
    sc delete "WinDivert" >nul 2>&1
    net stop "WinDivert14" >nul 2>&1
    sc delete "WinDivert14" >nul 2>&1
    reg delete "HKCU\Software\ALFiX inc.\GoodbyeZapret" /v "GoodbyeZapret_Config" /f >nul 2>&1
    rd /s /q "%SystemDrive%\GoodbyeZapret\configs" >nul 2>&1
    rd /s /q "%SystemDrive%\GoodbyeZapret\bin" >nul 2>&1
    rd /s /q "%SystemDrive%\GoodbyeZapret\lists" >nul 2>&1
    rd /s /q "%SystemDrive%\GoodbyeZapret\tools" >nul 2>&1
    timeout /t 7 >nul 2>&1
    Exit
)

:: Проверка, изменилась ли версия
echo "%Actual_GoodbyeZapret_version_code%" | findstr /i "%Current_GoodbyeZapret_version_code%" >nul
if errorlevel 1 (
    echo - available update
    set "UpdateNeed=Yes"
) else (
    set "VersionFound=1"
)

:skip_for_wifi
REM Версии GoodbyeZapret
REM set "GoodbyeZapretVersion=%Current_GoodbyeZapret_version%"

cls
title GoodbyeZapret - Launcher


REM Попытка прочитать значение из нового реестра
for /f "tokens=2*" %%a in ('reg query "HKCU\Software\ALFiX inc.\GoodbyeZapret" /v "GoodbyeZapret_Config" 2^>nul ^| find /i "GoodbyeZapret_Config"') do (
    set "GoodbyeZapret_Config=%%b"
    goto :end_GoodbyeZapret_Config
)

REM Если ключ нигде не найден, установить значение по умолчанию
set "GoodbyeZapret_Config=Не найден"

:end_GoodbyeZapret_Config


REM Попытка прочитать значение из нового реестра
for /f "tokens=2*" %%a in ('reg query "HKCU\Software\ALFiX inc.\GoodbyeZapret" /v "GoodbyeZapret_Version" 2^>nul ^| find /i "GoodbyeZapret_Version"') do (
    set "GoodbyeZapret_Version_OLD=%%b"
    goto :end_GoodbyeZapret_Version_OLD
)

REM Попытка перенести значение из старого реестра в новый
for /f "tokens=2*" %%a in ('reg query "HKCU\Software\ASX\Info" /v "GoodbyeZapret_Version" 2^>nul ^| find /i "GoodbyeZapret_Version"') do (
    set "GoodbyeZapret_Version_OLD=%%b"
    reg add "HKCU\Software\ALFiX inc.\GoodbyeZapret" /v "GoodbyeZapret_Version" /t REG_SZ /d "%%b" /f >nul
    reg delete "HKCU\Software\ASX\Info" /v "GoodbyeZapret_Version" /f >nul
    goto :end_GoodbyeZapret_Version_OLD
)

REM Если ключ нигде не найден, создать с дефолтным значением
reg add "HKCU\Software\ALFiX inc.\GoodbyeZapret" /v "GoodbyeZapret_Version" /t REG_SZ /d "%GoodbyeZapretVersion%" /f >nul
set "GoodbyeZapret_Version_OLD=Не найден"

:end_GoodbyeZapret_Version_OLD

if not defined GoodbyeZapretVersion (
    echo   Error 06: Read error. Failed to read value GoodbyeZapret_Version
    set "GoodbyeZapretVersion=%Current_GoodbyeZapret_version%"
    set "Actual_GoodbyeZapret_version=0.0.0"
    set "UpdateNeed=No"
    timeout /t 2 >nul
)

if not defined GoodbyeZapret_Config (
    echo   Error 07: Read error. Failed to read value GoodbyeZapret_Config
    timeout /t 2 >nul
)

reg query HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\GoodbyeZapret /v Description >nul 2>&1
if %errorlevel% equ 0 (
   REM Ключ GoodbyeZapret_Version существует.
   for /f "tokens=2*" %%a in ('reg query "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\GoodbyeZapret" /v "Description" 2^>nul ^| find /i "Description"') do set "GoodbyeZapret_Current=%%b"
   :: Пример содержимого переменной
    set "GoodbyeZapret_Current_TEXT=Текущий конфиг - %GoodbyeZapret_Current%"
)


reg query "HKEY_CURRENT_USER\Software\ALFiX inc.\GoodbyeZapret" /v "GoodbyeZapret_OldConfig" >nul 2>&1
if %errorlevel% equ 0 (
   REM Ключ GoodbyeZapret_OldConfig существует.
   for /f "tokens=2*" %%a in ('reg query "HKEY_CURRENT_USER\Software\ALFiX inc.\GoodbyeZapret" /v "GoodbyeZapret_OldConfig" 2^>nul ^| find /i "GoodbyeZapret_OldConfig"') do set "GoodbyeZapret_Old=%%b"
)

if defined GoodbyeZapretVersion (
    reg add "HKEY_CURRENT_USER\Software\ALFiX inc.\GoodbyeZapret" /v "GoodbyeZapret_Version" /t REG_SZ /d "%GoodbyeZapretVersion%" /f >nul 2>&1
)


:GZ_loading_procces
if "%UpdateNeed%"=="Yes" (
    goto Update_Need_screen
)
:MainMenu

reg query "HKEY_CURRENT_USER\Software\ALFiX inc.\GoodbyeZapret" /v "GoodbyeZapret_LastWorkConfig" >nul 2>&1
if %errorlevel% equ 0 (
for /f "tokens=2*" %%a in ('reg query "HKCU\Software\ALFiX inc.\GoodbyeZapret" /v "GoodbyeZapret_LastWorkConfig" 2^>nul ^| find /i "GoodbyeZapret_LastWorkConfig"') do set "GoodbyeZapret_LastWorkConf=%%b"
    set "GoodbyeZapret_LastWork=!GoodbyeZapret_LastWorkConf:~0,-4!"
) else (   
    set GoodbyeZapret_LastWork=none
)

sc query "GoodbyeZapret" >nul 2>&1
if %errorlevel% equ 0 (
    set "GoodbyeZapretStart=Yes"
) else (
    set "GoodbyeZapretStart=No"
)
tasklist | find /i "Winws.exe" >nul
if %errorlevel% equ 0 (
    set "WinwsStart=Yes"
    for /f "tokens=2*" %%a in ('reg query "HKCU\Software\ALFiX inc.\GoodbyeZapret" /v "GoodbyeZapret_LastStartConfig" 2^>nul ^| find /i "GoodbyeZapret_LastStartConfig"') do set "GoodbyeZapret_LastStartConfig=%%b"
    set "TrimmedLastStart=%GoodbyeZapret_LastStartConfig:~0,-4%"
) else (
    set "WinwsStart=No"
    reg add "HKCU\Software\ALFiX inc.\GoodbyeZapret" /v "GoodbyeZapret_LastStartConfig" /t REG_SZ /d "None" /f >nul
)

sc qc windivert >nul
if %errorlevel% equ 0 (
    set "WinDivertStart=Yes"
) else (
    set "WinDivertStart=No"
)

set "YesCount=0"
if "%GoodbyeZapretStart%"=="Yes" set /a YesCount+=1
if "%WinwsStart%"=="Yes" set /a YesCount+=1
if "%WinDivertStart%"=="Yes" set /a YesCount+=1
if %YesCount% equ 3 (
    echo Процесс %ProcessName% запущен.
    cls
    echo.
    echo           %COL%[92m  ______                ____            _____                         __ 
) else if %YesCount% equ 2 (
    echo Процесс %ProcessName% частично запущен.
    cls
    echo.
    echo           %COL%[33m  ______                ____            _____                         __ 
) else (
    echo Процесс %ProcessName% не найден.
    cls
    echo.
    echo           %COL%[91m  ______                ____            _____                         __ 
)

:: Проверка запущенного процесса
:: tasklist | find /i "Winws.exe" >nul
:: if %errorlevel% equ 0 (
::     echo Процесс %ProcessName% запущен.
::     cls
::     echo.
::     echo           %COL%[92m  ______                ____            _____                         __ 
:: ) else (
::     echo Процесс %ProcessName% не найден.
::     cls
::     echo.
::     echo           %COL%[90m  ______                ____            _____                         __ 
:: )

if not defined GoodbyeZapretVersion (
    title GoodbyeZapret - Launcher
) else (
    title GoodbyeZapret - Launcher %Current_GoodbyeZapret_version%
)

echo            / ____/___  ____  ____/ / /_  __  ____/__  /  ____ _____  ________  / /_
echo           / / __/ __ \/ __ \/ __  / __ \/ / / / _ \/ /  / __ `/ __ \/ ___/ _ \/ __/
echo          / /_/ / /_/ / /_/ / /_/ / /_/ / /_/ /  __/ /__/ /_/ / /_/ / /  /  __/ /_  
echo          \____/\____/\____/\__,_/_.___/\__, /\___/____/\__,_/ .___/_/   \___/\__/  
echo                                       /____/               /_/                     
echo.

if not "%CheckStatus%"=="Checked" if not "%CheckStatus%"=="WithoutChecked" (
REM    echo          %COL%[90mОшибка: Не удалось провести проверку файлов - Скрипт может быть не стабилен%COL%[37m
    echo                %COL%[90mОшибка: Не удалось проверить файлы - Возможны проблемы в работе%COL%[37m
    echo.
) else (
    echo.
)

set "LISTS=%SystemDrive%\GoodbyeZapret\lists\"
set "FILE=%LISTS%ipset-cloudflare.txt"

if not exist "%FILE%" (
    echo Error ipset-cloudflare.txt not found, path: %FILE%
    goto :eof
)

findstr /C:"0.0.0.0" "%FILE%" >nul
if %ERRORLEVEL%==0 (
    REM echo Enabling cloudflare bypass
    set "cloudflare=%COL%[91mВЫКЛ"
) else (
    REM echo Disabling cloudflare bypass
    set "cloudflare=%COL%[92mВКЛ"
)


REM ================================================================================================

: Длина строки
set "line_length=90"

:: Подсчет длины текста
set "text_length=0"
for /l %%A in (1,1,90) do (
    set "char=!GoodbyeZapret_Current_TEXT:~%%A,1!"
    if "!char!"=="" goto :count_done
    set /a text_length+=1
)
:count_done

:: Расчет количества пробелов
set /a spaces=(line_length - text_length) / 2

:: Формирование строки с пробелами
set "padding="
for /l %%A in (1,1,%spaces%) do set "padding=!padding! "


REM ================================================================================================

if "%GoodbyeZapret_Current%" NEQ "Не выбран" (
    echo             %COL%[90m ────────────────────────────────────────────────────────────────── %COL%[37m
) else (
    echo             %COL%[90m ────────────────────────────────────────────────────────────────── %COL%[37m
)
for /f "tokens=2*" %%a in ('reg query "HKCU\Software\ALFiX inc.\GoodbyeZapret" /v "GoodbyeZapret_LastStartConfig" 2^>nul ^| find /i "GoodbyeZapret_LastStartConfig"') do set "GoodbyeZapret_LastStartConfig=%%b"
set "TrimmedLastStart=%GoodbyeZapret_LastStartConfig:~0,-4%"
echo                 %COL%[36mКонфиги:
echo.
set "choice="
set "counter=0"

for %%F in ("%sourcePath%configs\*.bat") do (
    set /a "counter+=1"
    set "CurrentCheckFileName=%%~nxF"
    set "ConfigName=%%~nF"

if /i "!ConfigName!"=="%GoodbyeZapret_Current%" (
    if !counter! lss 10 (
        echo                  %COL%[36m!counter!. %COL%[36m%%~nF %COL%[92m^[Активен^]
    ) else (
        echo                 %COL%[36m!counter!. %COL%[36m%%~nF %COL%[92m^[Активен^]
    )
) else if /i "!ConfigName!"=="%TrimmedLastStart%" (
    if !counter! lss 10 (
        echo                  %COL%[36m!counter!. %COL%[96m%%~nF %COL%[96m^[Запущен^]
    ) else (
        echo                 %COL%[36m!counter!. %COL%[96m%%~nF %COL%[96m^[Запущен^]
    )
) else if /i "!ConfigName!"=="!GoodbyeZapret_LastWork!" (
    if !counter! lss 10 (
        echo                  %COL%[36m!counter!. %COL%[93m%%~nF %COL%[90m^[Раньше работал^]
    ) else (
        echo                 %COL%[36m!counter!. %COL%[93m%%~nF %COL%[90m^[Раньше работал^]
    )
) else if /i "!ConfigName!"=="%GoodbyeZapret_Old%" (
    if !counter! lss 10 (
        echo                  %COL%[36m!counter!. %COL%[93m%%~nF ^[Использовался^]
    ) else (
        echo                 %COL%[36m!counter!. %COL%[93m%%~nF ^[Использовался^]
    )
) else (
    if !counter! lss 10 (
        echo                  %COL%[36m!counter!. %COL%[37m%%~nF
    ) else (
        echo                 %COL%[36m!counter!. %COL%[37m%%~nF
    )
)
    set "file!counter!=%%~nxF"
)
set /a "lastChoice=counter-1"

if %UpdateNeed% equ Yes (
    if defined Actual_GoodbyeZapret_version (
        echo.
        echo                  %COL%[91mДоступно обновление GoodbyeZapret v%Actual_GoodbyeZapret_version%. ^[ UD ^] - обновить %COL%[37m
    ) else (
        echo.
        echo                       %COL%[91mДоступно обновление GoodbyeZapret. ^[ UD ^] - обновить%COL%[37m
    )
)
echo             %COL%[90m ────────────────────────────────────────────────────────────────── %COL%[37m
echo                 %COL%[36mДействия:
echo.

if "%GoodbyeZapret_Current%"=="Не выбран" (
echo                 %COL%[36m^[1-!counter!^] %COL%[92mУстановить конфиг в автозапуск
REM echo             %COL%[36m^[ SQ ^] %COL%[37mЗапустить конфиги поочередно
echo                 %COL%[36m^[1-!counter!s^] %COL%[92mЗапустить конфиг
echo.
echo                 %COL%[36m^[ ST ^] %COL%[37mСостояние GoodbyeZapret
echo                 %COL%[36m^[ CF ^] %COL%[37mОбход cloudflare ^(%cloudflare%%COL%[37m^)
) else (
echo                 %COL%[36m^[ DS ^] %COL%[91mУдалить конфиг из автозапуска
echo.
echo                 %COL%[36m^[ ST ^] %COL%[37mСостояние GoodbyeZapret
echo                 %COL%[36m^[ CF ^] %COL%[37mОбход cloudflare ^(%cloudflare%%COL%[37m^)
)
echo.
echo.
REM echo                                     Введите номер (%COL%[96m1%COL%[37m-%COL%[96m!counter!%COL%[37m)
echo                                %COL%[90mВведите номер или действие
set /p "choice=%DEL%                                           %COL%[90m:> "
if "%choice%"=="DS" goto remove_service
if "%choice%"=="вы" goto remove_service
if "%choice%"=="ds" goto remove_service

if "%choice%"=="CF" goto cloudflare_toggle
if "%choice%"=="са" goto cloudflare_toggle
if "%choice%"=="cf" goto cloudflare_toggle

if "%choice%"=="SQ" goto SeqStart
if "%choice%"=="ый" goto SeqStart
if "%choice%"=="sq" goto SeqStart
if "%choice%"=="ST" goto CurrentStatus
if "%choice%"=="ые" goto CurrentStatus
if "%choice%"=="st" goto CurrentStatus
if %UpdateNeed% equ Yes (
    if "%choice%"=="ud" goto Update_Need_screen
    if "%choice%"=="UD" goto Update_Need_screen
)
if "%choice%"=="" goto MainMenu

set "batFile=!file%choice:~0,-1%!"
if "%choice:~-1%"=="s" (
    set "batFile=!file%choice:~0,-1%!"
    echo Запустите %batFile% Вручную
    explorer "%SystemDrive%\GoodbyeZapret\configs\%batFile%"
    goto :end
) else (
    set "batFile=!file%choice%!"
)

    REM Цветной текст
    for /F "tokens=1,2 delims=#" %%a in ('"prompt #$H#$E# & echo on & for %%b in (1) do rem"') do (set "DEL=%%a" & set "COL=%%b")

if not defined batFile (
    echo Неверный выбор. Пожалуйста, попробуйте снова.
    goto :eof
)
 if defined batFile (
    cls
    echo %COL%[97m
     echo.
     echo  Подтвердите установку %COL%[36m%batFile:~0,-4%%COL%[97m в службу GoodbyeZapret
     echo %COL%[90m Нажмите любую клавишу для подтверждения... %COL%[37m
     echo.
     pause >nul 2>&1
     (
        sc create "GoodbyeZapret" binPath= "cmd.exe /c \"%SystemDrive%\GoodbyeZapret\configs\%batFile%" start= auto
     ) >nul 2>&1
     reg add "HKCU\Software\ALFiX inc.\GoodbyeZapret" /t REG_SZ /v "GoodbyeZapret_Config" /d "%batFile:~0,-4%" /f >nul
     reg add "HKCU\Software\ALFiX inc.\GoodbyeZapret" /t REG_SZ /v "GoodbyeZapret_OldConfig" /d "%batFile:~0,-4%" /f >nul
     sc description GoodbyeZapret "%batFile:~0,-4%" >nul
     sc start "GoodbyeZapret" >nul
     if %errorlevel% equ 0 (
         sc start "GoodbyeZapret" >nul 2>&1
         if %errorlevel% equ 0 (
             echo  - Служба GoodbyeZapret успешно запущена %COL%[37m
         ) else (
             echo  - Ошибка при запуске службы
         )
     )
     echo  - %COL%[92m %batFile% установлен в службу GoodbyeZapret %COL%[37m

    timeout /t 2 >nul 2>&1
    if exist "%SystemDrive%\GoodbyeZapret\tools\curl_test.bat" (
        call "%SystemDrive%\GoodbyeZapret\tools\curl_test.bat"
    )
     goto :end
 )

:remove_service
    cls
    REM Цветной текст
    for /F "tokens=1,2 delims=#" %%a in ('"prompt #$H#$E# & echo on & for %%b in (1) do rem"') do (set "DEL=%%a" & set "COL=%%b")
    echo.
    sc query "GoodbyeZapret" >nul 2>&1
    if %errorlevel% equ 0 (
        net stop "GoodbyeZapret" >nul 2>&1
        sc delete "GoodbyeZapret" >nul 2>&1
        if %errorlevel% equ 0 (
            echo %COL%[92m Служба GoodbyeZapret успешно удалена %COL%[37m
            tasklist /FI "IMAGENAME eq winws.exe" 2>NUL | find /I /N "winws.exe">NUL
            if "%ERRORLEVEL%"=="0" (
                taskkill /F /IM winws.exe >nul 2>&1
                net stop "WinDivert" >nul 2>&1
                sc delete "WinDivert" >nul 2>&1
                net stop "WinDivert14" >nul 2>&1
                sc delete "WinDivert14" >nul 2>&1
                echo  Файл winws.exe остановлен
            )
            echo %COL%[92m Удаление успешно завершено %COL%[37m
        ) else (
            echo  Ошибка при удалении службы
        )
    ) else (
        echo  Служба GoodbyeZapret не найдена
    )
    reg delete "HKCU\Software\ALFiX inc.\GoodbyeZapret" /v "GoodbyeZapret_Config" /f >nul 2>&1
goto :end

:end
if !ErrorCount! equ 0 (
    goto GoodbyeZapret_Menu
) else (
    echo  Нажмите любую клавишу чтобы продолжить...
    pause >nul 2>&1
    set "batFile="
    goto GoodbyeZapret_Menu
)

:SeqStart
cls
echo Запуск конфигов поочередно...
set "counter=0"
for %%F in ("%sourcePath%configs\*.bat") do (
    set /a "counter+=1"
    echo Запуск %%~nxF...
    start /wait cmd /c "%%F"
    pause
)
echo Все конфиги завершили выполнение
goto :end


:CurrentStatus
reg query "HKEY_CURRENT_USER\Software\ALFiX inc.\GoodbyeZapret" /v "Auto-update" >nul 2>&1
if %errorlevel% equ 0 (
    for /f "tokens=2*" %%a in ('reg query "HKEY_CURRENT_USER\Software\ALFiX inc.\GoodbyeZapret" /v "Auto-update" 2^>nul ^| find /i "Auto-update"') do set "Auto-update=%%b"
) else (
    set "Auto-update=1"
)

sc query BFE | findstr "STATE" >nul
if %errorlevel% equ 0 (
    for /f "tokens=4" %%a in ('sc query BFE ^| findstr "STATE"') do set "BFE_STATE=%%a"
) else (
    set "BFE_STATE=UNKNOWN"
)

sc qc BFE | findstr "START_TYPE" >nul
if %errorlevel% equ 0 (
    for /f "tokens=4" %%a in ('sc qc BFE ^| findstr "START_TYPE"') do set "BFE_START=%%a"
) else (
    set "BFE_START=UNKNOWN"
)

:: BaseFilteringEngine (BFE) - Служба базовой фильтрации
if not "%BFE_STATE%"=="RUNNING" (
    if not "%BFE_START%"=="AUTO_START" (
        REM Служба BFE ^(Служба базовой фильтрации^) не запущена или не установлена.
        set "BaseFilteringEngineCheckResult=Problem"
        set "BaseFilteringEngineCheckTips=Попробуйте установить и запустить службу BFE"
    ) else (
        REM Служба BFE ^(Служба базовой фильтрации^) не запущена.
        set "BaseFilteringEngineCheckResult=Problem"
        set "BaseFilteringEngineCheckTips=Попробуйте запустить службу BFE"
    )
) else if not "%BFE_START%"=="AUTO_START" (
    REM Служба BFE ^(Служба базовой фильтрации^) имеет неправильный режим запуска.
    set "BaseFilteringEngineCheckResult=Problem"
    set "BaseFilteringEngineCheckTips=Попробуйте установить режим запуска службы BFE на автоматический"
)



:: AdguardSvc.exe
tasklist /FI "IMAGENAME eq AdguardSvc.exe" | find /I "AdguardSvc.exe" > nul
if !errorlevel!==0 (
    :: Adguard process found. Adguard may cause problems with Discord - https://github.com/Flowseal/zapret-discord-youtube/issues/417
    set "AdguardCheckResult=Problem"
    set "AdguardCheckTips=Попробуйте отключить/удалить Adguard"
) else (
    set "AdguardCheckResult=Ok"
) 

REM === Поиск сервисов Killer ===
set "KillerCheckResult=Ok"
set "KillerServices="
for /f "tokens=2 delims=:" %%a in ('sc query ^| findstr /I "SERVICE_NAME:" ^| findstr /I "Killer"') do (
    if defined KillerServices (
        set "KillerServices=!KillerServices!,%%a"
    ) else (
        set "KillerServices=%%a"
    )
)

if defined KillerServices (
    set "KillerCheckResult=Problem"
    set "KillerCheckTips=Попробуйте удалить сервисы Killer ^(!KillerServices! ^)."
) else (
    set "KillerCheckResult=Ok"
)

REM === Поиск сервисов Check Point ===
set "CheckpointCheckResult=Ok"
set "CheckpointServices="
for /f "tokens=2 delims=:" %%a in ('sc query ^| findstr /I "SERVICE_NAME:" ^| findstr /I "Check Point"') do (
    if defined CheckpointServices (
        set "CheckpointServices=!CheckpointServices!,%%a"
    ) else (
        set "CheckpointServices=%%a"
    )
)

if defined CheckpointServices (
    set "CheckpointCheckResult=Problem"
    set "CheckpointCheckTips=Попробуйте удалить сервисы Check Point ^(!CheckpointServices! ^)."
) else (
    set "CheckpointCheckResult=Ok"
)

REM === Поиск сервисов SmartByte ===
set "SmartByteCheckResult=Ok"
set "SmartByteServices="
for /f "tokens=2 delims=:" %%a in ('sc query ^| findstr /I "SERVICE_NAME:" ^| findstr /I "SmartByte"') do (
    if defined SmartByteServices (
        set "SmartByteServices=!SmartByteServices!,%%a"
    ) else (
        set "SmartByteServices=%%a"
    )
)

if defined SmartByteServices (
    set "SmartByteCheckResult=Problem"
    set "SmartByteCheckTips=Попробуйте удалить/отключить сервисы SmartByte ^(!SmartByteServices! ^)."
) else (
    set "SmartByteCheckResult=Ok"
)


REM === Поиск VPN сервисов ===
set "VPNServices="
for /f "tokens=2 delims=:" %%a in ('sc query ^| findstr /I "SERVICE_NAME:" ^| findstr /I "VPN"') do (
    if defined VPNServices (
        set "VPNServices=!VPNServices!,%%a"
    ) else (
        set "VPNServices=%%a"
    )
)

if defined VPNServices (
    set "VPNCheckResult=Problem"
    set "VPNCheckTips=Убедитесь, что все VPN отключены ^(!VPNServices! ^)."
) else (
    set "VPNCheckResult=Ok"
)

:: DNS
set "dnsfound=0"
for /f "skip=1 tokens=*" %%a in ('wmic nicconfig where "IPEnabled=true" get DNSServerSearchOrder /format:table') do (
    echo %%a | findstr /i "192.168." >nul
    if !errorlevel!==0 (
        set "dnsfound=1"
    )
)
if !dnsfound!==1 (
    :: DNS servers are probably not specified.
    :: Provider's DNS servers are automatically used, which may affect zapret.
    set "DNSCheckResult=Problem"
    set "DNSCheckTips=Рекомендуется установить известные DNS-серверы ^(например Google DNS 8.8.8.8 - 8.8.4.4^)"
) else (
    set "DNSCheckResult=Ok"
)

:: Итоговая проверка
set "TotalCheck=Ok"
set "ProblemDetails="
set "ProblemTips="

for %%V in (BaseFilteringEngineCheckResult AdguardCheckResult KillerCheckResult CheckpointCheckResult SmartByteCheckResult VPNCheckResult DNSCheckResult ) do (
    if "!%%V!"=="Problem" (
        set "TotalCheck=Problem"
        set "ProblemDetails=!ProblemDetails! %%V"
        for %%T in (BaseFilteringEngineCheckTips AdguardCheckTips KillerCheckTips CheckpointCheckTips SmartByteCheckTips VPNCheckTips DNSCheckTips ) do (
            if "%%V"=="%%~nT" (
                set "ProblemTips=!ProblemTips! !%%T!"
            )
        )
    )
)
if "%TotalCheck%"=="Problem" (
    mode con: cols=92 lines=36 >nul 2>&1
) else (
    mode con: cols=92 lines=27 >nul 2>&1
)

cls
REM Цветной текст
for /F "tokens=1,2 delims=#" %%a in ('"prompt #$H#$E# & echo on & for %%b in (1) do rem"') do (set "DEL=%%a" & set "COL=%%b")
title GoodbyeZapret - Состояние
echo.
echo    %COL%[36m┌───────────────────────────── Состояние GoodbyeZapret ─────────────────────────────┐
echo    ^│ %COL%[37mСлужбы:                                                                           %COL%[36m^│
echo    ^│ %COL%[90m───────────────────────────────────────────────────────────────────────────────── %COL%[36m^│
sc query "GoodbyeZapret" >nul 2>&1
if %errorlevel% equ 0 (
    echo    ^│ %COL%[92m√ %COL%[37mGoodbyeZapret: %COL%[92mУстановлен и работает                                            %COL%[36m^│
) else (
    echo    ^│ %COL%[91mX %COL%[37mGoodbyeZapret: Не установлен                                                    %COL%[36m^│
)
tasklist | find /i "Winws.exe" >nul
if %errorlevel% equ 0 (
    echo    ^│ %COL%[92m√ %COL%[37mWinws.exe: %COL%[92mЗапущен                                                              %COL%[36m^│
) else (
    echo    ^│ %COL%[91mX %COL%[37mWinws.exe: Не запущен                                                           %COL%[36m^│
)
sc qc windivert >nul
if %errorlevel% equ 0 (
    echo    ^│ %COL%[92m√ %COL%[37mWinDivert: %COL%[92mУстановлен                                                           %COL%[36m^│
) else (
    echo    ^│ %COL%[91mX %COL%[37mWinDivert: Не установлен                                                        %COL%[36m^│
)
if "%Auto-update%"=="1" (
    echo    ^│ %COL%[92m√ %COL%[37mАвтообновление: %COL%[92mВключено                                                        %COL%[36m^│
    set "AutoUpdateTextParam=Выключить"
    set "AutoUpdateStatus=On"
) else (
    echo    ^│ %COL%[91mX %COL%[37mАвтообновление: Выключено                                                       %COL%[36m^│
    set "AutoUpdateTextParam=Включить"
    set "AutoUpdateStatus=Off"
)
echo    ^│                                                                                   ^│
echo    ^│ %COL%[37mВерсии:                                                                           %COL%[36m^│
echo    ^│ %COL%[90m───────────────────────────────────────────────────────────────────────────────── %COL%[36m^│

if "%UpdateNeed%"=="Yes" (
    echo    ^│ %COL%[37mGoodbyeZapret: %COL%[91m%GoodbyeZapretVersion% %COL%[92m^(→ %Actual_GoodbyeZapret_version%^)                                %COL%[36m^│
) else (
    echo    ^│ %COL%[37mGoodbyeZapret: %COL%[92m%GoodbyeZapretVersion%                                                              %COL%[36m^│
)

    echo    ^│ %COL%[37mWinws:         %COL%[92m%Current_Winws_version%                                                               %COL%[36m^│
    echo    ^│ %COL%[37mconfigs:       %COL%[92m%Current_configs_version%                                                                 %COL%[36m^│
    echo    ^│ %COL%[37mLists:         %COL%[92m%Current_List_version%                                                                 %COL%[36m^│
echo    └───────────────────────────────────────────────────────────────────────────────────┘
echo.
:: Вывод результатов
if "%TotalCheck%"=="Problem" (
    echo     %COL%[91mВозможны проблемы в работе GoodbyeZapret %COL%[37m
    echo     └ Причины:
    for %%V in (BaseFilteringEngine Adguard Killer Checkpoint SmartByte VPN DNS) do (
        set "CheckResult=!%%VCheckResult!"
        set "CheckTips=!%%VCheckTips!"
        if "!CheckResult!"=="Problem" (
            echo.
            echo       - %%V:%COL%[91m Проблема обнаружена%COL%[37m
            if defined CheckTips (
                echo         %COL%[90m!CheckTips!%COL%[37m
            )
        )
    )
) else (
    echo     %COL%[92mПроблемы в работе GoodbyeZapret НЕ обнаружены%COL%[37m
)
echo.
echo    %COL%[90m─────────────────────────────────────────────────────────────────────────────────────
echo.
echo    %COL%[36m^[ %COL%[96mB %COL%[36m^] %COL%[93mВернуться в меню
echo    %COL%[36m^[ %COL%[96mA %COL%[36m^] %COL%[93m%AutoUpdateTextParam% автообновление
echo    %COL%[36m^[ %COL%[96mR %COL%[36m^] %COL%[93mПереустановить GoodbyeZapret
if %UpdateNeed% equ Yes (
    echo    %COL%[36m^[ %COL%[96mU %COL%[36m^] %COL%[93mОбновить до актуальной версии
)
echo.
set /p "choice=%DEL%   %COL%[90m:> "
if /i "%choice%"=="B" mode con: cols=92 lines=%ListBatCount% >nul 2>&1 && goto MainMenu
if /i "%choice%"=="и" mode con: cols=92 lines=%ListBatCount% >nul 2>&1 && goto MainMenu
if /i "%choice%"=="R" goto FullUpdate
if /i "%choice%"=="к" goto FullUpdate
if %UpdateNeed% equ Yes (
if /i "%choice%"=="U" start "Update GoodbyeZapret" "%SystemDrive%\GoodbyeZapret\tools\Updater.exe"
if /i "%choice%"=="г" start "Update GoodbyeZapret" "%SystemDrive%\GoodbyeZapret\tools\Updater.exe"
)
if /i "%choice%"=="A" ( if /i "%AutoUpdateStatus%"=="On" (
    reg add "HKCU\Software\ALFiX inc.\GoodbyeZapret" /v "Auto-update" /t REG_SZ /d "0" /f >nul 2>&1
    del "%SystemDrive%\GoodbyeZapret\tools\UpdateService.exe" >nul 2>&1
    del "%ProgramData%\Microsoft\Windows\Start Menu\Programs\Startup\UpdateService.lnk" >nul 2>&1
    )
)
if /i "%choice%"=="ф" ( if /i "%AutoUpdateStatus%"=="On" (
    reg add "HKCU\Software\ALFiX inc.\GoodbyeZapret" /v "Auto-update" /t REG_SZ /d "0" /f >nul 2>&1
    del "%SystemDrive%\GoodbyeZapret\tools\UpdateService.exe" >nul 2>&1
    del "%ProgramData%\Microsoft\Windows\Start Menu\Programs\Startup\UpdateService.lnk" >nul 2>&1
    )
)

if /i "%choice%"=="A" ( if /i "%AutoUpdateStatus%"=="Off" (
    reg add "HKCU\Software\ALFiX inc.\GoodbyeZapret" /v "Auto-update" /t REG_SZ /d "1" /f >nul 2>&1
    chcp 850 >nul 2>&1
    powershell "$WshShell = New-Object -comObject WScript.Shell; $Shortcut = $WshShell.CreateShortcut('%ProgramData%\Microsoft\Windows\Start Menu\Programs\Startup\UpdateService.lnk'); $Shortcut.TargetPath = '%SystemDrive%\GoodbyeZapret\tools\UpdateService.exe'; $Shortcut.Save()"
    chcp 65001 >nul 2>&1
    del "%SystemDrive%\GoodbyeZapret\tools\UpdateService.exe" >nul 2>&1
    curl -g -L -# -o "%SystemDrive%\GoodbyeZapret\tools\UpdateService.exe" "https://github.com/ALFiX01/GoodbyeZapret/raw/refs/heads/main/Files/UpdateService/UpdateService.exe" >nul 2>&1
    )
)
if /i "%choice%"=="ф" ( if /i "%AutoUpdateStatus%"=="Off" (
    reg add "HKCU\Software\ALFiX inc.\GoodbyeZapret" /v "Auto-update" /t REG_SZ /d "1" /f >nul 2>&1
    chcp 850 >nul 2>&1
    powershell "$WshShell = New-Object -comObject WScript.Shell; $Shortcut = $WshShell.CreateShortcut('%ProgramData%\Microsoft\Windows\Start Menu\Programs\Startup\UpdateService.lnk'); $Shortcut.TargetPath = '%SystemDrive%\GoodbyeZapret\tools\UpdateService.exe'; $Shortcut.Save()"
    chcp 65001 >nul 2>&1
    del "%SystemDrive%\GoodbyeZapret\tools\UpdateService.exe" >nul 2>&1
    curl -g -L -# -o "%SystemDrive%\GoodbyeZapret\tools\UpdateService.exe" "https://github.com/ALFiX01/GoodbyeZapret/raw/refs/heads/main/Files/UpdateService/UpdateService.exe" >nul 2>&1
    )
)
goto CurrentStatus


:cloudflare_toggle
set "LISTS=%SystemDrive%\GoodbyeZapret\lists\"
set "FILE=%LISTS%ipset-cloudflare.txt"

if not exist "%FILE%" (
    echo Error! ipset-cloudflare.txt not found, path: %FILE%
    goto :eof
)

findstr /C:"0.0.0.0" "%FILE%" >nul
if %ERRORLEVEL%==0 (
    echo Enabling cloudflare bypass...
    >"%FILE%" (
        echo 173.245.48.0/20
        echo 103.21.244.0/22
        echo 103.22.200.0/22
        echo 103.31.4.0/22
        echo 141.101.64.0/18
        echo 108.162.192.0/18
        echo 190.93.240.0/20
        echo 188.114.96.0/20
        echo 197.234.240.0/22
        echo 198.41.128.0/17
        echo 162.158.0.0/15
        echo 104.16.0.0/13
        echo 104.24.0.0/14
        echo 172.64.0.0/13
        echo 131.0.72.0/22
    )
) else (
    echo Disabling cloudflare bypass...
    >"%FILE%" (
        echo 0.0.0.0/32
    )
)
goto MainMenu

:FullUpdate
start "Update GoodbyeZapret" "%SystemDrive%\GoodbyeZapret\tools\Updater.exe"
exit


REM РЕЖИМ УСТАНОВКИ
:install_screen
IF "%WiFi%" == "Off" (
    cls
    echo.
    echo   Error 01: No internet connection.
    timeout /t 4 >nul
    exit
)

set "Assistant_version=0.3"
REM mode con: cols=112 lines=38 >nul 2>&1
mode con: cols=80 lines=28 >nul 2>&1
REM Цветной текст
for /F "tokens=1,2 delims=#" %%a in ('"prompt #$H#$E# & echo on & for %%b in (1) do rem"') do (set "DEL=%%a" & set "COL=%%b")
chcp 65001 >nul 2>&1

cls
title Установщик программного обеспечения от ALFiX, Inc.
echo.
echo        %COL%[36m ┌──────────────────────────────────────────────────────────────┐
echo         │   %COL%[91m ██╗███╗   ██╗███████╗████████╗ █████╗ ██╗     ██╗        %COL%[36m │
echo         │   %COL%[91m ██║████╗  ██║██╔════╝╚══██╔══╝██╔══██╗██║     ██║        %COL%[36m │
echo         │   %COL%[91m ██║██╔██╗ ██║███████╗   ██║   ███████║██║     ██║        %COL%[36m │
echo         │   %COL%[91m ██║██║╚██╗██║╚════██║   ██║   ██╔══██║██║     ██║        %COL%[36m │
echo         │   %COL%[91m ██║██║ ╚████║███████║   ██║   ██║  ██║███████╗███████╗   %COL%[36m │
echo         │   %COL%[91m ╚═╝╚═╝  ╚═══╝╚══════╝   ╚═╝   ╚═╝  ╚═╝╚══════╝╚══════╝   %COL%[36m │
echo         └──────────────────────────────────────────────────────────────┘
echo.
echo        %COL%[37m Добро пожаловать в установщик GoodbyeZapret
echo        %COL%[90m Для корректной работы рекомендуется отключить антивирус
echo        %COL%[90m ───────────────────────────────────────────────────────────────
echo.
echo        %COL%[36m Нажмите любую клавишу для продолжения...
pause >nul


:install_GoodbyeZapret
cls
title Установщик программного обеспечения от ALFiX, Inc.
echo.
echo        %COL%[36m ┌──────────────────────────────────────────────────────────────┐
echo         │   %COL%[91m ██╗███╗   ██╗███████╗████████╗ █████╗ ██╗     ██╗        %COL%[36m │
echo         │   %COL%[91m ██║████╗  ██║██╔════╝╚══██╔══╝██╔══██╗██║     ██║        %COL%[36m │
echo         │   %COL%[91m ██║██╔██╗ ██║███████╗   ██║   ███████║██║     ██║        %COL%[36m │
echo         │   %COL%[91m ██║██║╚██╗██║╚════██║   ██║   ██╔══██║██║     ██║        %COL%[36m │
echo         │   %COL%[91m ██║██║ ╚████║███████║   ██║   ██║  ██║███████╗███████╗   %COL%[36m │
echo         │   %COL%[91m ╚═╝╚═╝  ╚═══╝╚══════╝   ╚═╝   ╚═╝  ╚═╝╚══════╝╚══════╝   %COL%[36m │
echo         └──────────────────────────────────────────────────────────────┘
echo.
echo        %COL%[37m Добро пожаловать в установщик GoodbyeZapret
echo        %COL%[90m Для корректной работы рекомендуется отключить антивирус
echo        %COL%[90m ───────────────────── ВЫПОЛНЯЕТСЯ УСТАНОВКА ─────────────────────
echo.
if not exist "%SystemDrive%\GoodbyeZapret" (
    md %SystemDrive%\GoodbyeZapret
)
echo        ^[*^] Скачивание файлов GoodbyeZapret...
curl -g -L -# -o %TEMP%\GoodbyeZapret.zip "https://github.com/ALFiX01/GoodbyeZapret/raw/refs/heads/main/Files/GoodbyeZapret.zip"
if errorlevel 1 (
    echo %COL%[91m ^[*^] Ошибка: Не удалось скачать GoodbyeZapret.zip ^(Код: %errorlevel%^) %COL%[90m
)

echo        ^[*^] Скачивание Updater.exe...
curl -g -L -# -o "%SystemDrive%\GoodbyeZapret\tools\Updater.exe" "https://github.com/ALFiX01/GoodbyeZapret/raw/refs/heads/main/Files/Updater/Updater.exe"
 if errorlevel 1 (
    echo         %COL%[91m ^[*^] Ошибка: Не удалось скачать Updater.exe ^(Код: %errorlevel%^) %COL%[90m
    echo         %COL%[93m ^[*^] Установка продолжится, но обновление может не работать.%COL%[90m
    REM Не выходим, так как основной zip скачался
)


if exist "%TEMP%\GoodbyeZapret.zip" (
    echo        ^[*^] Распаковка файлов
    chcp 850 >nul 2>&1
    powershell -NoProfile Expand-Archive '%TEMP%\GoodbyeZapret.zip' -DestinationPath '%SystemDrive%\GoodbyeZapret' >nul 2>&1
    chcp 65001 >nul 2>&1
    if exist "%SystemDrive%\GoodbyeZapret" (
        echo        ^[*^] Местоположение GoodbyeZapret: %SystemDrive%\GoodbyeZapret
    )
) else (
    echo        %COL%[91m ^[*^] Error: File not found: %TEMP%\GoodbyeZapret.zip %COL%[90m
    timeout /t 5 >nul
    exit
)

echo        ^[*^] Создание ярлыка на рабочем столе...
chcp 850 >nul 2>&1
powershell "$WshShell = New-Object -comObject WScript.Shell; $Shortcut = $WshShell.CreateShortcut([Environment]::GetFolderPath('Desktop') + '\GoodbyeZapret.lnk'); $Shortcut.TargetPath = '%SystemDrive%\GoodbyeZapret\launcher.exe'; $Shortcut.Save()"
chcp 65001 >nul 2>&1

echo.
echo        %COL%[92m√ Установка успешно завершена
echo        %COL%[90m───────────────────────────────────────────────────────────────
echo.
echo        %COL%[36mНажмите любую клавишу для запуска GoodbyeZapret...
pause >nul
goto RR


:Update_Need_screen
set "PatchNoteLines=0"
curl -g -L -o "%SystemDrive%\GoodbyeZapret\bin\PatchNote.txt" "https://raw.githubusercontent.com/ALFiX01/GoodbyeZapret/refs/heads/main/Files/PatchNote.txt"
for /f %%A in ('type "%SystemDrive%\GoodbyeZapret\bin\PatchNote.txt" ^| find /c /v ""') do set "PatchNoteLines=%%A"
set /a PatchNoteLines=PatchNoteLines+21
mode con: cols=80 lines=%PatchNoteLines% >nul 2>&1
REM Цветной текст
for /F "tokens=1,2 delims=#" %%a in ('"prompt #$H#$E# & echo on & for %%b in (1) do rem"') do (set "DEL=%%a" & set "COL=%%b")
cls
REM mode con: cols=80 lines=28 >nul 2>&1
chcp 65001 >nul 2>&1

cls
echo.
echo        %COL%[36m ┌──────────────────────────────────────────────────────────────┐
echo         │     %COL%[91m ██╗   ██╗██████╗ ██████╗  █████╗ ████████╗███████╗     %COL%[36m │
echo         │     %COL%[91m ██║   ██║██╔══██╗██╔══██╗██╔══██╗╚══██╔══╝██╔════╝     %COL%[36m │
echo         │     %COL%[91m ██║   ██║██████╔╝██║  ██║███████║   ██║   █████╗       %COL%[36m │
echo         │     %COL%[91m ██║   ██║██╔═══╝ ██║  ██║██╔══██║   ██║   ██╔══╝       %COL%[36m │
echo         │     %COL%[91m ╚██████╔╝██║     ██████╔╝██║  ██║   ██║   ███████╗     %COL%[36m │
echo         │     %COL%[91m  ╚═════╝ ╚═╝     ╚═════╝ ╚═╝  ╚═╝   ╚═╝   ╚══════╝     %COL%[36m │
echo         └──────────────────────────────────────────────────────────────┘
echo.
echo  %COL%[36m Доступно обновление GoodbyeZapret %COL%[92mv!Current_GoodbyeZapret_version! → v!Actual_GoodbyeZapret_version!
echo  %COL%[90m ──────────────────────────────────────────────────────────────────────────── %COL%[36m
echo   Описание обновления: %COL%[37m
type "%SystemDrive%\GoodbyeZapret\bin\PatchNote.txt"
echo.
echo.
echo  %COL%[90m ────────────────────────────────────────────────────────────────────────────
REM echo  %COL%[36m Выберите действие:
echo.
echo                      %COL%[92m ^[U^]%COL%[37m Обновить  / %COL%[91m ^[B^]%COL%[37m Пропустить
echo.
set /p "choice=%DEL%   %COL%[90m:> "
if /i "%choice%"=="B" mode con: cols=92 lines=%ListBatCount% >nul 2>&1 && goto MainMenu
if /i "%choice%"=="и" mode con: cols=92 lines=%ListBatCount% >nul 2>&1 && goto MainMenu
if /i "%choice%"=="U" ( goto FullUpdate )
if /i "%choice%"=="г" ( goto FullUpdate )
goto Update_Need_screen


:WinwsUpdate
echo.
curl -g -L -# -o "%TEMP%\WinwsUpdateFiles.zip" "https://github.com/ALFiX01/GoodbyeZapret/raw/refs/heads/main/Files/WinwsUpdateFiles.zip" >nul 2>&1
if exist "%TEMP%\WinwsUpdateFiles.zip" (
    echo   ^[*^] Распаковка файлов...
    chcp 850 >nul 2>&1
    powershell -NoProfile -Command "Expand-Archive -Path '%TEMP%\WinwsUpdateFiles.zip' -DestinationPath '%TEMP%\WinwsUpdate' -Force" >nul 2>&1
    if not exist "%SystemDrive%\GoodbyeZapret\bin\" mkdir "%SystemDrive%\GoodbyeZapret\bin\" >nul 2>&1
    
    echo   ^[*^] Остановка и удаление служб...
    taskkill /F /IM winws.exe >nul 2>&1
    net stop "WinDivert" >nul 2>&1
    sc delete "WinDivert" >nul 2>&1
    net stop "WinDivert14" >nul 2>&1
    sc delete "WinDivert14" >nul 2>&1
    
    if exist "%SystemDrive%\GoodbyeZapret\bin\cygwin1.dll" del /f /q "%SystemDrive%\GoodbyeZapret\bin\cygwin1.dll" >nul 2>&1
    if exist "%SystemDrive%\GoodbyeZapret\bin\WinDivert.dll" del /f /q "%SystemDrive%\GoodbyeZapret\bin\WinDivert.dll" >nul 2>&1
    if exist "%SystemDrive%\GoodbyeZapret\bin\WinDivert64.sys" del /f /q "%SystemDrive%\GoodbyeZapret\bin\WinDivert64.sys" >nul 2>&1
    if exist "%SystemDrive%\GoodbyeZapret\bin\winws.exe" del /f /q "%SystemDrive%\GoodbyeZapret\bin\winws.exe" >nul 2>&1
    
    move /y "%TEMP%\WinwsUpdate\cygwin1.dll" "%SystemDrive%\GoodbyeZapret\bin\" >nul 2>&1
    move /y "%TEMP%\WinwsUpdate\WinDivert.dll" "%SystemDrive%\GoodbyeZapret\bin\" >nul 2>&1
    move /y "%TEMP%\WinwsUpdate\WinDivert64.sys" "%SystemDrive%\GoodbyeZapret\bin\" >nul 2>&1
    move /y "%TEMP%\WinwsUpdate\winws.exe" "%SystemDrive%\GoodbyeZapret\bin\" >nul 2>&1
    
    chcp 65001 >nul 2>&1
    del /f /q "%TEMP%\WinwsUpdateFiles.zip" >nul 2>&1
    rd /s /q "%TEMP%\WinwsUpdate" >nul 2>&1
    
    echo !Actual_Winws_version! > "%SystemDrive%\GoodbyeZapret\bin\version.txt"
    
    echo   ^[*^] Запуск службы GoodbyeZapret...
    sc start "GoodbyeZapret" >nul 2>&1
    
    echo %COL%[92m ^[*^] Обновление winws успешно завершено %COL%[37m
    timeout /t 1 >nul
    mode con: cols=92 lines=%ListBatCount% >nul 2>&1
    goto MainMenu
) else (
    echo %COL%[91m ^[*^]  Ошибка: Не удалось загрузить файл обновления winws %COL%[37m
    timeout /t 1 >nul
    mode con: cols=92 lines=%ListBatCount% >nul 2>&1
    goto MainMenu
)