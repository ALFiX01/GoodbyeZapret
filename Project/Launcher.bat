::[Bat To Exe Converter]
::
::YAwzoRdxOk+EWAjk
::fBw5plQjdCuDJOl7RaKA9quH/eQy7NtmtmmtA9RLEVpWEpCtilLtyFVrAoivE9hTwlDmSZ8u2XRmv8QDCBlBeyiqfh0xvSNss3OhMtSVtAGvQ0uGhg==
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

set "Current_GoodbyeZapret_version=1.5.2"

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


set "WiFi=Off"
set "CheckURL=https://raw.githubusercontent.com"

echo Checking connectivity to update server ^(%CheckURL%^)...
:: Используем curl для проверки доступности основного хоста обновлений
:: -s: Silent mode (без прогресс-бара)
:: -L: Следовать редиректам
:: --head: Получить только заголовки (быстрее, меньше данных)
:: -m 10: Таймаут 10 секунд
:: -o NUL: Отправить тело ответа в никуда (нам нужен только код возврата)
curl -s -L --head -m 10 -o NUL "%CheckURL%"

IF %ERRORLEVEL% EQU 0 (
    REM Успешно, сервер доступен
    echo Connection successful.
    set "WiFi=On"
) ELSE (
    REM Попытка не удалась
    cls
    echo.
    echo   Error 01: Cannot reach the update server.
    echo   Connection check to %CheckURL% failed ^(curl errorlevel: %ERRORLEVEL%^).
    echo   Please check your internet connection, firewall settings,
    echo   or if %CheckURL% is accessible from your network.
    set "WiFi=Off"
    timeout /t 5 >nul
    REM ВАЖНО: Решите, должен ли скрипт завершаться при отсутствии связи.
    REM Если установка/обновление невозможны без сети, то лучше выйти.
    REM Раскомментируйте следующую строку, если выход необходим:
    REM exit /b 1
)

if Not exist %SystemDrive%\GoodbyeZapret (
    goto install_screen
)

:RR

set "BatCount=0"
set "sourcePath=%~dp0"

for %%f in ("%sourcePath%Configs\*.bat") do (
    set /a "BatCount+=1"
)

set /a ListBatCount=BatCount+28
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
   set "GoodbyeZapret_Old_TEXT=Раньше использовался - %GoodbyeZapret_Old%"
)

for /f "usebackq delims=" %%a in ("%SystemDrive%\GoodbyeZapret\bin\version.txt") do set "Current_Winws_version=%%a"
for /f "usebackq delims=" %%a in ("%SystemDrive%\GoodbyeZapret\lists\version.txt") do set "Current_List_version=%%a"
for /f "usebackq delims=" %%a in ("%SystemDrive%\GoodbyeZapret\Configs\version.txt") do set "Current_Configs_version=%%a"

:: Загрузка нового файла GZ_Updater.bat
if exist "%TEMP%\GZ_Updater.bat" del /s /q /f "%TEMP%\GZ_Updater.bat" >nul 2>&1
curl -s -o "%TEMP%\GZ_Updater.bat" "https://raw.githubusercontent.com/ALFiX01/GoodbyeZapret/refs/heads/main/GoodbyeZapret_Version" 
if errorlevel 1 (
    echo ERROR - Ошибка связи с сервером проверки обновлений GoodbyeZapret
    
)

:: Загрузка нового файла Updater.exe
if not exist "%SystemDrive%\GoodbyeZapret\Updater.exe" (
    curl -g -L -# -o "%SystemDrive%\GoodbyeZapret\Updater.exe" "https://github.com/ALFiX01/GoodbyeZapret/raw/refs/heads/main/Files/Updater/Updater.exe" >nul 2>&1
)

set FileSize=0
for %%I in ("%TEMP%\GZ_Updater.bat") do set FileSize=%%~zI
if %FileSize% LSS 15 (
    set "CheckStatus=NoChecked"
    REM echo     %COL%[91m   └ Ошибка: Файл не прошел проверку. Возможно, он поврежден %COL%[37m
    echo ERROR - Файл GZ_Updater.bat поврежден или URL не доступен ^(Size %FileSize%^)
    echo.
    del /Q "%TEMP%\GZ_Updater.bat"
    pause
) else (
    set "CheckStatus=Checked"
)


:: Выполнение загруженного файла Updater.bat
call "%TEMP%\GZ_Updater.bat" >nul 2>&1
if errorlevel 1 (
    echo ERROR - Ошибка при выполнении GZ_Updater.bat
)

REM Версии GoodbyeZapret
set "GoodbyeZapretVersion_New=%Actual_GoodbyeZapret_version%"
set "GoodbyeZapretVersion=%Current_GoodbyeZapret_version%"

set "WinwsVersion_New=%Actual_Winws_version%"
set "WinwsVersion=%Current_Winws_version%"

set "ConfigsVersion_New=%Actual_Configs_version%"
set "ConfigsVersion=%Current_Configs_version%"

set "ListsVersion_New=%Actual_List_version%"
set "ListsVersion=%Current_List_version%"

set "UpdateNeedCount=0"
call :CompareVersions "!Current_GoodbyeZapret_version!" "!Actual_GoodbyeZapret_version!" comparisonResult
if "!comparisonResult!"=="-1" ( set /a "UpdateNeedCount+=1" )
call :CompareVersions "!Current_Winws_version!" "!Actual_Winws_version!" comparisonResult
if "!comparisonResult!"=="-1" ( set /a "UpdateNeedCount+=1" )
if "!Current_Configs_version!" LSS "!Actual_Configs_version!" ( set /a "UpdateNeedCount+=1" )
if "!Current_List_version!" LSS "!Actual_List_version!" ( set /a "UpdateNeedCount+=1" )

set "UpdateNeed=No"
set "UpdateNeedLevel=0"
call :CompareVersions "!Current_GoodbyeZapret_version!" "!Actual_GoodbyeZapret_version!" comparisonResult
if "!comparisonResult!"=="-1" (
    set "UpdateNeed=Yes"
    set /a "UpdateNeedLevel+=1"
)
call :CompareVersions "!Current_Winws_version!" "!Actual_Winws_version!" comparisonResult
if "!comparisonResult!"=="-1" (
    set "UpdateNeed=Yes"
    set /a "UpdateNeedLevel+=1"
)
if "!Current_List_version!" LSS "!Actual_List_version!" (
    set "UpdateNeed=Yes"
    set /a "UpdateNeedLevel+=1"
)
REM Сравнение Configs не влияло на UpdateNeedLevel в оригинале, поэтому здесь его нет

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
    echo ERROR - Не удалось прочитать значение GoodbyeZapret_Version
    pause
)

if not defined GoodbyeZapret_Config (
    echo ERROR - Не удалось прочитать значение GoodbyeZapret_Config
    pause
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
   set "GoodbyeZapret_Old_TEXT=Раньше использовался - %GoodbyeZapret_Old%"
)

if defined GoodbyeZapretVersion (
    reg add "HKEY_CURRENT_USER\Software\ALFiX inc.\GoodbyeZapret" /v "GoodbyeZapret_Version" /t REG_SZ /d "%GoodbyeZapretVersion%" /f >nul 2>&1
)


:GZ_loading_procces
if %UpdateNeedCount% GEQ 2 (
    goto Update_Need_screen
)
:MainMenu

:: Проверка запущенного процесса
tasklist | find /i "Winws.exe" >nul
if %errorlevel% equ 0 (
    echo Процесс %ProcessName% запущен.
    cls
    echo.
    echo           %COL%[92m  ______                ____            _____                         __ 
) else (
    echo Процесс %ProcessName% не найден.
    cls
    echo.
    echo           %COL%[90m  ______                ____            _____                         __ 
)

if not defined GoodbyeZapretVersion (
    title GoodbyeZapret - Launcher
) else (
    title GoodbyeZapret - Launcher
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
: Длина строки
set "old_line_length=90"

:: Подсчет длины текста
set "old_text_length=0"
for /l %%A in (1,1,90) do (
    set "old_char=!GoodbyeZapret_Old_TEXT:~%%A,1!"
    if "!old_char!"=="" goto :old_count_done
    set /a old_text_length+=1
)
:old_count_done

:: Расчет количества пробелов
set /a old_spaces=(old_line_length - old_text_length) / 2

:: Формирование строки с пробелами
set "old_padding="
for /l %%A in (1,1,%old_spaces%) do set "old_padding=!old_padding! "


if "%GoodbyeZapret_Current%" NEQ "Не выбран" (
    echo              %COL%[90m ─────────────────────────────────────────────────────────────── %COL%[37m
    echo %COL%[36m!padding!!GoodbyeZapret_Current_TEXT! %COL%[37m
    echo              %COL%[90m ─────────────────────────────────────────────────────────────── %COL%[37m
    echo.
) else (
    echo              %COL%[90m ─────────────────────────────────────────────────────────────── %COL%[37m
    echo %COL%[36m!padding!!GoodbyeZapret_Current_TEXT! %COL%[37m

    echo %COL%[90m!old_padding!!GoodbyeZapret_Old_TEXT! %COL%[37m
    
    echo              %COL%[90m ─────────────────────────────────────────────────────────────── %COL%[37m
    echo.
)
set "choice="
set "counter=0"
for %%F in ("%sourcePath%Configs\*.bat") do (
    set /a "counter+=1"
    set "CurrentCheckFileName=%%~nxF"
    set "ConfigName=%%~nF"
    
    if /i "!ConfigName!"=="%GoodbyeZapret_Current%" (
        if !counter! lss 10 (
            echo                       %COL%[36m!counter!. %COL%[36m%%~nF ^(текущий^)
        ) else (
            echo                      %COL%[36m!counter!. %COL%[36m%%~nF ^(текущий^)
        )
    ) else if /i "!ConfigName!"=="%GoodbyeZapret_Old%" (
        if !counter! lss 10 (
            echo                       %COL%[36m!counter!. %COL%[93m%%~nF ^(ранее использовался^)
        ) else (
            echo                      %COL%[36m!counter!. %COL%[93m%%~nF ^(ранее использовался^)
        )
    ) else (
        if !counter! lss 10 (
            echo                       %COL%[36m!counter!. %COL%[37m%%~nF
        ) else (
            echo                      %COL%[36m!counter!. %COL%[37m%%~nF
        )
    )
    set "file!counter!=%%~nxF"
)
set /a "lastChoice=counter-1"
echo.
echo              %COL%[90m ─────────────────────────────────────────────────────────────── %COL%[37m
echo                %COL%[36mДействия:
echo.
echo                          %COL%[96m^[ DS ^] %COL%[91mУдалить службу из автозапуска
echo                          %COL%[96m^[ RC ^] %COL%[91mПереустановить конфиги
echo                          %COL%[96m^[ ST ^] %COL%[91mСостояние GoodbyeZapret
echo                          %COL%[96m^[ 1s ^] %COL%[91mЗапустить конфиг
echo                          %COL%[96m^[ SQ ^] %COL%[91mЗапустить конфиги поочередно
REM echo                     %COL%[96m^[1-%counter%s^] %COL%[91mЗапустить конфиг

if %UpdateNeed% equ Yes (
echo                          %COL%[96m^[ UD ^] %COL%[91mОбновить до актульной версии
)


echo.
echo.
REM echo                                     Введите номер (%COL%[96m1%COL%[37m-%COL%[96m!counter!%COL%[37m)
echo                              %COL%[37mВведите номер или команду %COL%[90m(1-%counter%):
set /p "choice=%DEL%                                           %COL%[90m:> "
if "%choice%"=="DS" goto remove_service
if "%choice%"=="ds" goto remove_service
if "%choice%"=="RC" goto ReInstall_GZ
if "%choice%"=="rc" goto ReInstall_GZ
if "%choice%"=="SQ" goto SeqStart
if "%choice%"=="sq" goto SeqStart
if "%choice%"=="ST" goto CurrentStatus
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
    explorer "%SystemDrive%\GoodbyeZapret\Configs\%batFile%"
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
     echo.
     echo  Подтвердите установку %batFile% в службу GoodbyeZapret...
     echo %COL%[93m Нажмите любую клавишу для подтверждения %COL%[37m
     pause >nul 2>&1
     sc create "GoodbyeZapret" binPath= "cmd.exe /c \"%SystemDrive%\GoodbyeZapret\Configs\%batFile%" start= auto
     reg add "HKCU\Software\ALFiX inc.\GoodbyeZapret" /t REG_SZ /v "GoodbyeZapret_Config" /d "%batFile:~0,-4%" /f >nul
     reg add "HKCU\Software\ALFiX inc.\GoodbyeZapret" /t REG_SZ /v "GoodbyeZapret_OldConfig" /d "%batFile:~0,-4%" /f >nul
     sc description GoodbyeZapret "%batFile:~0,-4%" >nul
     sc start "GoodbyeZapret" >nul
     if %errorlevel% equ 0 (
         sc start "GoodbyeZapret" >nul 2>&1
         if %errorlevel% equ 0 (
             echo  Служба GoodbyeZapret успешно запущена %COL%[37m
         ) else (
             echo  Ошибка при запуске службы
         )
     )
     echo %COL%[92m %batFile% установлен в службу GoodbyeZapret %COL%[37m
     goto :end
 )

:remove_service
    REM Цветной текст
    for /F "tokens=1,2 delims=#" %%a in ('"prompt #$H#$E# & echo on & for %%b in (1) do rem"') do (set "DEL=%%a" & set "COL=%%b")
    echo.
    net stop GoodbyeZapret >nul 2>&1
    if %errorlevel% equ 0 (
        echo  Служба успешно остановлена.
    ) else (
        echo  Ошибка при остановке службы или служба уже остановлена.
    )
    sc query "GoodbyeZapret" >nul 2>&1
    if %errorlevel% equ 0 (
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
                echo  Файл winws.exe остановлен.
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
for %%F in ("%sourcePath%Configs\*.bat") do (
    set /a "counter+=1"
    echo Запуск %%~nxF...
    start /wait cmd /c "%%F"
    pause
)
echo Все конфиги завершили выполнение.
goto :end


:CurrentStatus
REM Проверка наличия и корректности пути службы обновления GoodbyeZapret
set "GoodbyeZapretUpdaterService=0"
reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\Run" /v "GoodbyeZapret Updater" >nul 2>&1
if %errorlevel% equ 0 (
    for /f "tokens=3*" %%i in ('reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\Run" /v "GoodbyeZapret Updater" 2^>nul ^| find /i "GoodbyeZapret Updater"') do (
        set "GoodbyeZapretUpdaterPath=%%j"
        if /I "!GoodbyeZapretUpdaterPath!" EQU "%SystemDrive%\GoodbyeZapret\GoodbyeZapretUpdaterService.exe" (
            if exist "%SystemDrive%\GoodbyeZapret\GoodbyeZapretUpdaterService.exe" (
                set "GoodbyeZapretUpdaterService=1"
            )
        )
    )
)

cls
mode con: cols=80 lines=25 >nul 2>&1
title GoodbyeZapret - Status
echo.
echo   %COL%[36m┌─────────────────── Состояние GoodbyeZapret ───────────────────┐
echo   ^│ %COL%[37mСлужбы:                                                       %COL%[36m^│
echo   ^│ %COL%[90m──────────────────────────────────────────────────────────    %COL%[36m^│
sc query "GoodbyeZapret" >nul 2>&1
if %errorlevel% equ 0 (
    echo   ^│ %COL%[92m√ %COL%[37mGoodbyeZapret: Установлена и работает                       %COL%[36m^│
) else (
    echo   ^│ %COL%[91mX %COL%[37mGoodbyeZapret: Не установлена                               %COL%[36m^│
)
if !GoodbyeZapretUpdaterService! equ 1 (
    echo   ^│ %COL%[92m√ %COL%[37mUpdater: Установлен и работает                              %COL%[36m^│
    set "GoodbyeZapretUpdaterServiceAction=Выключить"
) else (
    echo   ^│ %COL%[91mX %COL%[37mUpdater: Не установлен                                      %COL%[36m^│
    set "GoodbyeZapretUpdaterServiceAction=Включить"
)
tasklist | find /i "Winws.exe" >nul
if %errorlevel% equ 0 (
    echo   ^│ %COL%[92m√ %COL%[37mWinws.exe: Запущен                                          %COL%[36m^│
) else (
    echo   ^│ %COL%[91mX %COL%[37mWinws.exe: Не запущен                                       %COL%[36m^│
)

echo   ^│                                                               ^│
echo   ^│ %COL%[37mВерсии:                                                       %COL%[36m^│
echo   ^│ %COL%[90m──────────────────────────────────────────────────────────    %COL%[36m^│
call :CompareVersions "!Current_GoodbyeZapret_version!" "!Actual_GoodbyeZapret_version!" comparisonResult
if "!comparisonResult!"=="-1" (
    echo   ^│ %COL%[37mGoodbyeZapret: %COL%[91m%GoodbyeZapretVersion% %COL%[92m^(→ %Actual_GoodbyeZapret_version%^)                                %COL%[36m^│
) else (
    echo   ^│ %COL%[37mGoodbyeZapret: %COL%[92m%GoodbyeZapretVersion%                                          %COL%[36m^│
)
call :CompareVersions "!Current_Winws_version!" "!Actual_Winws_version!" comparisonResult
if "!comparisonResult!"=="-1" (
    echo   ^│ %COL%[37mWinws:         %COL%[91m%WinwsVersion% %COL%[92m^(→ %Actual_Winws_version%^)                                  %COL%[36m^│
) else (
    echo   ^│ %COL%[37mWinws:         %COL%[92m%WinwsVersion%                                           %COL%[36m^│
)
if "!Current_Configs_version!" LSS "!Actual_Configs_version!" ( 
    echo   ^│ %COL%[37mConfigs:       %COL%[91m%ConfigsVersion% %COL%[92m^(→ %Actual_Configs_version%^)                                      %COL%[36m^│
) else (
    echo   ^│ %COL%[37mConfigs:       %COL%[92m%ConfigsVersion%                                             %COL%[36m^│
)
if "!Current_List_version!" LSS "!Actual_List_version!" ( 
    echo   ^│ %COL%[37mLists:         %COL%[91m%ListsVersion% %COL%[92m^(→ %Actual_List_version%^)                                       %COL%[36m^│
) else (
    echo   ^│ %COL%[37mLists:         %COL%[92m%ListsVersion%                                             %COL%[36m^│
)
echo   └───────────────────────────────────────────────────────────────┘
echo.
echo   %COL%[36m^[ %COL%[96mF %COL%[36m^] %COL%[93m%GoodbyeZapretUpdaterServiceAction% Updater   %COL%[36m^[ %COL%[96mB %COL%[36m^] %COL%[93mВернуться в меню
echo   %COL%[36m^[ %COL%[96mU %COL%[36m^] %COL%[93mОбновить
echo.
echo   %COL%[37mВыберите действие %COL%[90m^(F/B^):
set /p "choice=%DEL%   %COL%[90m:> "
if /i "%choice%"=="B" mode con: cols=92 lines=%ListBatCount% >nul 2>&1 && goto MainMenu
if /i "%choice%"=="и" mode con: cols=92 lines=%ListBatCount% >nul 2>&1 && goto MainMenu
if /i "%choice%"=="F" goto GoodbyeZapretUpdaterService_toggle
if /i "%choice%"=="а" goto GoodbyeZapretUpdaterService_toggle
if /i "%choice%"=="U" start "Update GoodbyeZapret" "%SystemDrive%\GoodbyeZapret\Updater.exe"
if /i "%choice%"=="г" start "Update GoodbyeZapret" "%SystemDrive%\GoodbyeZapret\Updater.exe"
goto CurrentStatus


:ReInstall_GZ
start "Update GoodbyeZapret" "%SystemDrive%\GoodbyeZapret\Updater.exe"
exit

:FullUpdate
start "Update GoodbyeZapret" "%SystemDrive%\GoodbyeZapret\Updater.exe"
exit

:GoodbyeZapretUpdaterService_toggle
if !GoodbyeZapretUpdaterService! equ 1 (
    reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Run" /v "GoodbyeZapret Updater" /f >nul 2>&1
) else (
    if not exist "%SystemDrive%\GoodbyeZapret\GoodbyeZapretUpdaterService.exe" (
        curl -g -L -# -o "%SystemDrive%\GoodbyeZapret\GoodbyeZapretUpdaterService.exe" "https://github.com/ALFiX01/GoodbyeZapret/raw/refs/heads/main/Files/UpdateService/UpdateService.exe" >nul 2>&1
    )
    reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Run" /v "GoodbyeZapret Updater" /t REG_SZ /d "%SystemDrive%\GoodbyeZapret\GoodbyeZapretUpdaterService.exe" /f >nul 2>&1
)

goto CurrentStatus

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
mode con: cols=80 lines=25 >nul 2>&1
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
echo  %COL%[37m Добро пожаловать в установщик GoodbyeZapret
echo  %COL%[90m Для корректной работы рекомендуется отключить антивирус
echo  %COL%[90m ───────────────────────────────────────────────────────────────
echo.
echo  %COL%[36m Нажмите любую клавишу для продолжения...
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
echo  %COL%[37m Добро пожаловать в установщик GoodbyeZapret
echo  %COL%[90m Для корректной работы рекомендуется отключить антивирус
echo  %COL%[90m ───────────────────── ВЫПОЛНЯЕТСЯ УСТАНОВКА ─────────────────────
echo.
if not exist "%SystemDrive%\GoodbyeZapret" (
    md %SystemDrive%\GoodbyeZapret
)
echo  ^[*^] Скачивание файлов GoodbyeZapret...
curl -g -L -# -o %TEMP%\GoodbyeZapret.zip "https://github.com/ALFiX01/GoodbyeZapret/raw/refs/heads/main/Files/GoodbyeZapret.zip"
if errorlevel 1 (
    echo %COL%[91m ^[*^] Ошибка: Не удалось скачать GoodbyeZapret.zip ^(Код: %errorlevel%^) %COL%[90m
)

echo  ^[*^] Скачивание Updater.exe...
curl -g -L -# -o "%SystemDrive%\GoodbyeZapret\Updater.exe" "https://github.com/ALFiX01/GoodbyeZapret/raw/refs/heads/main/Files/Updater/Updater.exe"
 if errorlevel 1 (
    echo %COL%[91m ^[*^] Ошибка: Не удалось скачать Updater.exe ^(Код: %errorlevel%^) %COL%[90m
    echo %COL%[93m ^[*^] Установка продолжится, но обновление может не работать.%COL%[90m
    REM Не выходим, так как основной zip скачался
)


if exist "%TEMP%\GoodbyeZapret.zip" (
    echo  ^[*^] Распаковка файлов
    chcp 850 >nul 2>&1
    powershell -NoProfile Expand-Archive '%TEMP%\GoodbyeZapret.zip' -DestinationPath '%SystemDrive%\GoodbyeZapret' >nul 2>&1
    chcp 65001 >nul 2>&1
    if exist "%SystemDrive%\GoodbyeZapret" (
        echo  ^[*^] Местоположение GoodbyeZapret: %SystemDrive%\GoodbyeZapret
    )
) else (
    echo %COL%[91m ^[*^] Error: File not found: %TEMP%\GoodbyeZapret.zip %COL%[90m
    timeout /t 5 >nul
    exit
)

echo.
echo   %COL%[92m√ Установка успешно завершена
echo   %COL%[90m───────────────────────────────────────────────────────────────
echo.
echo   %COL%[36mНажмите любую клавишу для запуска GoodbyeZapret...
pause >nul
goto RR


:Update_Need_screen
REM Цветной текст
for /F "tokens=1,2 delims=#" %%a in ('"prompt #$H#$E# & echo on & for %%b in (1) do rem"') do (set "DEL=%%a" & set "COL=%%b")
cls
mode con: cols=80 lines=25 >nul 2>&1
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
echo  %COL%[37m Доступны обновления компонентов:
echo  %COL%[90m ───────────────────────────────────────────────────────────────
echo.

set "OnlyWinwsUpdate=1"
call :CompareVersions "!Current_GoodbyeZapret_version!" "!Actual_GoodbyeZapret_version!" comparisonResult
if "!comparisonResult!"=="-1" ( :: Оригинал использовал LSS
    echo   %COL%[37mGoodbyeZapret: %COL%[92mv!Current_GoodbyeZapret_version! → v!Actual_GoodbyeZapret_version!
    set "OnlyWinwsUpdate=0"
)
call :CompareVersions "!Current_Winws_version!" "!Actual_Winws_version!" comparisonResult
if "!comparisonResult!" neq "0" ( :: Оригинал использовал NEQ
    echo   %COL%[37mWinws:         %COL%[92mv!Current_Winws_version! → v!Actual_Winws_version!
)
if "!Current_Configs_version!" LSS "!Actual_Configs_version!" ( 
    echo   %COL%[37mConfigs:       %COL%[92mv!Current_Configs_version! → v!Actual_Configs_version!
    set "OnlyWinwsUpdate=0"
)
if "!Current_List_version!" LSS "!Actual_List_version!" ( 
    echo   %COL%[37mLists:         %COL%[92mv!Current_List_version! → v!Actual_List_version!
    set "OnlyWinwsUpdate=0"
)
echo.
echo  %COL%[90m ───────────────────────────────────────────────────────────────
echo  %COL%[37m Выберите действие:
echo  %COL%[91m ^[B^]%COL%[37m Пропустить       %COL%[92m ^[U^]%COL%[37m Обновить
echo.
set /p "choice=%DEL%   %COL%[90m:> "
if /i "%choice%"=="B" mode con: cols=92 lines=%ListBatCount% >nul 2>&1 && goto MainMenu
if /i "%choice%"=="и" mode con: cols=92 lines=%ListBatCount% >nul 2>&1 && goto MainMenu
if /i "%choice%"=="U" (
    if !OnlyWinwsUpdate! equ 1 (
        goto WinwsUpdate
    ) else (
        goto FullUpdate
    )
)
if /i "%choice%"=="г" (
    if !OnlyWinwsUpdate! equ 1 (
        goto WinwsUpdate
    ) else (
        goto FullUpdate
    )
)
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


:: ==============================
:: ПОДПРОГРАММЫ
:: ==============================

:CompareVersions <Version1> <Version2> <ResultVarName>
:: Сравнивает две версии в формате X.Y.Z[.N] с помощью PowerShell.
:: Устанавливает переменную с именем %3 в:
::   -1, если Version1 < Version2
::    0, если Version1 == Version2
::    1, если Version1 > Version2
::   99, если произошла ошибка сравнения (неверный формат)
setlocal EnableDelayedExpansion
set "v1=%~1"
set "v2=%~2"
set "outputVar=%~3"
set "psResult=99" :: По умолчанию - ошибка

:: Проверка на пустые строки, чтобы PowerShell не ругался
if not defined v1 set "v1=0.0.0"
if not defined v2 set "v2=0.0.0"

:: Команда PowerShell для сравнения версий
set "psCmd=$v1Str = '!v1!'; $v2Str = '!v2!'; try { $v1 = [version]$v1Str; $v2 = [version]$v2Str; if ($v1 -lt $v2) { Write-Host -NoNewline -1 } elseif ($v1 -gt $v2) { Write-Host -NoNewline 1 } else { Write-Host -NoNewline 0 } } catch { Write-Host -NoNewline 99 }"

:: Выполняем PowerShell и получаем результат
chcp 850 >nul 2>&1
for /f %%r in ('powershell -NoProfile -Command "!psCmd!"') do set "psResult=%%r"
chcp 65001 >nul 2>&1

:: Возвращаем результат в переменную вызывающей стороны
endlocal & set "%outputVar%=%psResult%"
goto :eof

:: ========== КОНЕЦ ПОДПРОГРАММ ==========