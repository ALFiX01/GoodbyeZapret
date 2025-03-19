::[Bat To Exe Converter]
::
::YAwzoRdxOk+EWAjk
::fBw5plQjdCyDJGyX8VAjFD9VQg2LMFeeCaIS5Of66/m7tV8YWuE3NY7V3vmdI/IW/UH2fIAoxDRTm8Rs
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
:: Copyright (C) 2024 ALFiX, Inc.
:: Any tampering with the program code is forbidden (Запрещены любые вмешательства)

:: Запуск от имени администратора
reg add HKLM /F >nul 2>&1
if %errorlevel% neq 0 (
    start "" /wait /I /min powershell -NoProfile -Command "start -verb runas '%~s0'" && exit /b
    exit /b
)


setlocal EnableDelayedExpansion

:: Получение информации о текущем языке интерфейса и выход, если язык не ru-RU
for /f "tokens=3" %%i in ('reg query "HKCU\Control Panel\International" /v "LocaleName"') do set WinLang=%%i
if /I "%WinLang%" NEQ "ru-RU" (
    cls
    echo.
    echo   Error 01: Invalid interface language.
    timeout /t 4 >nul
    exit /b
)


ping -n 1 google.ru >nul 2>&1
IF %ERRORLEVEL% EQU 1 (
    cls
    echo.
    echo   Error 01: No internet connection.
    timeout /t 4 >nul
    set "WiFi=Off"
 ) else (
 	set "WiFi=On"
)

if Not exist %SystemDrive%\GoodbyeZapret (
    goto install_assistant
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

:: Получаем текущую папку BAT-файла
set currentDir=%~dp0

:: Убираем последний слэш
set currentDir=%currentDir:~0,-1%

:: Переходим в родительскую папку
for %%i in ("%currentDir%") do set parentDir=%%~dpi
set parentDir=%parentDir:~0,-1%

:: Переходим в родительскую папку родительской папки
for %%i in ("%parentDir:~0,-1%") do set parentDir2=%%~dpi

set parentDir2=%parentDir2:~0,-1%


:GoodbyeZapret_Menu
tasklist /FI "IMAGENAME eq winws.exe" 2>NUL | find /I /N "winws.exe" >NUL
if "%ERRORLEVEL%"=="0" ( 
    REM Процесс winws.exe уже запущен.
) else (
    sc start "GoodbyeZapret" >nul 2>&1
)

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

for /f "usebackq delims=" %%a in ("%SystemDrive%\GoodbyeZapret\version.txt") do set "Current_GoodbyeZapret_version=%%a"
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
if !Current_GoodbyeZapret_version! LSS !Actual_GoodbyeZapret_version! ( set /a "UpdateNeedCount+=1" )
if !Current_Winws_version! neq !Actual_Winws_version! ( set /a "UpdateNeedCount+=1" )
if !Current_Configs_version! neq !Actual_Configs_version! ( set /a "UpdateNeedCount+=1" )
if !Current_List_version! neq !Actual_List_version! ( set /a "UpdateNeedCount+=1" )

set "UpdateNeed=No"
set "UpdateNeedLevel=0"
if !Current_GoodbyeZapret_version! LSS !Actual_GoodbyeZapret_version! (
    set "UpdateNeed=Yes"
    set /a "UpdateNeedLevel+=1"
)
if !Current_Winws_version! neq !Actual_Winws_version! (
    set "UpdateNeed=Yes"
    set /a "UpdateNeedLevel+=1"
)
if !Current_List_version! neq !Actual_List_version! (
    set "UpdateNeed=Yes"
    set /a "UpdateNeedLevel+=1"
)

cls
title GoodbyeZapret - Launcher


REM Попытка прочитать значение из нового реестра
for /f "tokens=2*" %%a in ('reg query "HKCU\Software\ALFiX inc.\GoodbyeZapret" /v "GoodbyeZapret_Config" 2^>nul ^| find /i "GoodbyeZapret_Config"') do (
    set "GoodbyeZapret_Config=%%b"
    goto :end_GoodbyeZapret_Config
)

REM Попытка перенести значение из старого реестра в новый
for /f "tokens=2*" %%a in ('reg query "HKCU\Software\ASX\Info" /v "GoodbyeZapret_Config" 2^>nul ^| find /i "GoodbyeZapret_Config"') do (
    set "GoodbyeZapret_Config=%%b"
    reg add "HKCU\Software\ALFiX inc.\GoodbyeZapret" /v "GoodbyeZapret_Config" /t REG_SZ /d "%%b" /f >nul
    reg delete "HKCU\Software\ASX\Info" /v "GoodbyeZapret_Config" /f >nul
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
    exit
)

if not defined GoodbyeZapret_Config (
    echo ERROR - Не удалось прочитать значение GoodbyeZapret_Config
    pause
    exit
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
if %UpdateNeedCount% GEQ 3 (
    goto Update_Need_screen
)
:MainMenu
:: Проверка запущенного процесса
tasklist | find /i "Winws.exe" >nul
if %errorlevel% equ 0 (
    echo Процесс %ProcessName% запущен.
) else (
    echo Процесс %ProcessName% не найден.
)

if not defined GoodbyeZapretVersion (
    title GoodbyeZapret - Launcher
) else (
    title GoodbyeZapret - Launcher
)

cls
echo.
echo           %COL%[90m_____                 _ _                  ______                    _   
echo          / ____^|               ^| ^| ^|                ^|___  /                   ^| ^|  
echo         ^| ^|  __  ___   ___   __^| ^| ^|__  _   _  ___     / / __ _ _ __  _ __ ___^| ^|_ 
echo         ^| ^| ^|_ ^|/ _ \ / _ \ / _` ^| '_ \^| ^| ^| ^|/ _ \   / / / _` ^| '_ \^| '__/ _ \ __^|
echo         ^| ^|__^| ^| ^(_^) ^| ^(_^) ^| ^(_^| ^| ^|_^) ^| ^|_^| ^|  __/  / /_^| ^(_^| ^| ^|_^) ^| ^| ^|  __/ ^|_ 
echo          \_____^|\___/ \___/ \__,_^|_.__/ \__, ^|\___^| /_____\__,_^| .__/^|_^|  \___^|\__^|
echo                                          __/ ^|                 ^| ^|                 
echo                                         ^|___/                  ^|_^|
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
    echo                     %COL%[90m===================================================
    echo %COL%[36m!padding!!GoodbyeZapret_Current_TEXT! %COL%[37m
    echo                     %COL%[90m===================================================%COL%[37m
    echo.
) else (
    echo                     %COL%[90m===================================================
    echo %COL%[36m!padding!!GoodbyeZapret_Current_TEXT! %COL%[37m

    echo %COL%[90m!old_padding!!GoodbyeZapret_Old_TEXT! %COL%[37m
    
    echo                     %COL%[90m===================================================%COL%[37m
    echo.
)

echo                         Выберите конфиг для установки в автозапуск
echo.

set "counter=0"
for %%F in ("%sourcePath%Configs\*.bat") do (
    set /a "counter+=1"
    set "CurrentCheckFileName=%%~nxF"
    if !counter! lss 10 (
        echo                      %COL%[36m!counter!. %COL%[37m%%~nF
    ) else (
        echo                     %COL%[36m!counter!. %COL%[37m%%~nF
    )
    set "file!counter!=%%~nxF"
)
set /a "lastChoice=counter-1"

echo                     %COL%[90m===================================================
if !counter! lss 10 (
    echo.
    echo                      %COL%[96mDS %COL%[37m- %COL%[91mУдалить службу из автозапуска%COL%[37m
) else (
    echo.
    echo                     %COL%[96mDS %COL%[37m- %COL%[91mУдалить службу из автозапуска%COL%[37m
)
if !counter! lss 10 (
    echo                      %COL%[96mRC %COL%[37m- %COL%[91mПринудительно переустановить конфиги%COL%[37m
) else (
    echo                     %COL%[96mRC %COL%[37m- %COL%[91mПринудительно переустановить конфиги%COL%[37m
)
if !counter! lss 10 (
    echo                      %COL%[96mST %COL%[37m- %COL%[91mСостояние GoodbyeZapret%COL%[37m
) else (
    echo                     %COL%[96mST %COL%[37m- %COL%[91mСостояние GoodbyeZapret%COL%[37m
)

if !counter! lss 10 (
    echo                  %COL%[96m^(1%COL%[37m-%COL%[96m!counter!^)s %COL%[37m- %COL%[91mЗапустить конфиг %COL%[37m
) else (
    echo                %COL%[96m^(1%COL%[37m-%COL%[96m!counter!^)s %COL%[37m- %COL%[91mЗапустить конфиг %COL%[37m
)

if %UpdateNeed% equ Yes (
    if !counter! lss 10 (
        echo                      %COL%[96mUD %COL%[37m- %COL%[93mОбновить до актульной версии%COL%[37m
    ) else (
        echo                     %COL%[96mUD %COL%[37m- %COL%[93mОбновить до актульной версии%COL%[37m
    )
)


echo.
echo.
echo                                     Введите номер (%COL%[96m1%COL%[37m-%COL%[96m!counter!%COL%[37m)
set /p "choice=%DEL%                                            %COL%[90m:> "
if "%choice%"=="DS" goto remove_service
if "%choice%"=="ds" goto remove_service
if "%choice%"=="RC" goto ReInstall_GZ
if "%choice%"=="rc" goto ReInstall_GZ
if "%choice%"=="ST" goto CurrentStatus
if "%choice%"=="st" goto CurrentStatus
if %UpdateNeed% equ Yes (
    if "%choice%"=="ud" goto FullUpdate
    if "%choice%"=="UD" goto FullUpdate
)


set "batFile=!file%choice:~0,-1%!"
if "%choice:~-1%"=="s" (
    set "batFile=!file%choice:~0,-1%!"
    echo Запустите %batFile% Вручную
    explorer "%SystemDrive%\GoodbyeZapret\Configs\%batFile%"
    goto :end
) else (
    set "batFile=!file%choice%!"
)



if not defined batFile (
    echo Неверный выбор. Пожалуйста, попробуйте снова.
    goto :eof
)
 if defined batFile (
     echo.
     echo Устанавливаю службу GoodbyeZapret для файла %batFile%...
     echo %COL%[93mНажмите любую клавишу для подтверждения%COL%[37m
     pause >nul 2>&1
     sc create "GoodbyeZapret" binPath= "cmd.exe /c \"%SystemDrive%\GoodbyeZapret\Configs\%batFile%" start= auto
     reg add "HKCU\Software\ALFiX inc.\GoodbyeZapret" /t REG_SZ /v "GoodbyeZapret_Config" /d "%batFile:~0,-4%" /f >nul
     reg add "HKCU\Software\ALFiX inc.\GoodbyeZapret" /t REG_SZ /v "GoodbyeZapret_OldConfig" /d "%batFile:~0,-4%" /f >nul
     sc description GoodbyeZapret "%batFile:~0,-4%"
     sc start "GoodbyeZapret" >nul
     if %errorlevel% equ 0 (
         echo Запускаю службу GoodbyeZapret...%COL%[92m
         sc start "GoodbyeZapret" >nul 2>&1
         if %errorlevel% equ 0 (
             echo Служба GoodbyeZapret успешно запущена %COL%[37m
         ) else (
             echo Ошибка при запуске службы
         )
     ) else (
         echo Ошибка при установке службы. Возможно вы забыли перезагрузить пк.
     )
     goto :end
 )


:remove_service
    echo.
    echo Остановка службы GoodbyeZapret...
    net stop GoodbyeZapret >nul 2>&1
    if %errorlevel% equ 0 (
        echo Служба успешно остановлена.
    ) else (
        echo Ошибка при остановке службы или служба уже остановлена.
    )
    echo Удаление службы GoodbyeZapret...
    sc query "GoodbyeZapret" >nul 2>&1
    if %errorlevel% equ 0 (
        sc delete "GoodbyeZapret" >nul 2>&1
        if %errorlevel% equ 0 (
            echo Служба GoodbyeZapret успешно удалена
            tasklist /FI "IMAGENAME eq winws.exe" 2>NUL | find /I /N "winws.exe">NUL
            if "%ERRORLEVEL%"=="0" (
                echo Файл winws.exe в данный момент выполняется.
                taskkill /F /IM winws.exe >nul 2>&1
                net stop "WinDivert" >nul 2>&1
                sc delete "WinDivert" >nul 2>&1
                net stop "WinDivert14" >nul 2>&1
                sc delete "WinDivert14" >nul 2>&1
                echo Файл winws.exe был остановлен.
            ) else (
                echo Файл winws.exe в данный момент не выполняется.
            )
            echo %COL%[92mУдаление успешно завершено. Перезагрузите пк.%COL%[37m
        ) else (
            echo Ошибка при удалении службы
        )
    ) else (
        echo Служба GoodbyeZapret не найдена
    )
    reg delete "HKCU\Software\ALFiX inc.\GoodbyeZapret" /v "GoodbyeZapret_Config" /f >nul 2>&1
goto :end

:end
echo Нажмите любую клавишу чтобы продолжить...
pause >nul 2>&1
goto GoodbyeZapret_Menu


:CurrentStatus
REM Проверка наличия и корректности пути службы обновления GoodbyeZapret
set "GoodbyeZapretUpdaterService=0"

REM Проверяем запись в автозагрузке
reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\Run" /v "GoodbyeZapret Updater" >nul 2>&1
if %errorlevel% equ 0 (
    for /f "tokens=3*" %%i in ('reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\Run" /v "GoodbyeZapret Updater" 2^>nul ^| find /i "GoodbyeZapret Updater"') do (
        set "GoodbyeZapretUpdaterPath=%%j"
        echo "!GoodbyeZapretUpdaterPath!"
        if /I "!GoodbyeZapretUpdaterPath!" EQU "%SystemDrive%\GoodbyeZapret\GoodbyeZapretUpdaterService.exe" (
            if exist "%SystemDrive%\GoodbyeZapret\GoodbyeZapretUpdaterService.exe" (
                set "GoodbyeZapretUpdaterService=1"
            )
        )
    )
)

cls
echo.
echo   %COL%[37mСостояние служб GoodbyeZapret
echo   %COL%[90m=============================%COL%[37m
sc query "GoodbyeZapret" >nul 2>&1
if %errorlevel% equ 0 (
    echo   Служба GoodbyeZapret: %COL%[92mУстановлена и работает%COL%[37m
) else (
    echo   Служба GoodbyeZapret: %COL%[91mНе установлена%COL%[37m
)
if !GoodbyeZapretUpdaterService! equ 1 (
    echo   Служба GoodbyeZapret Updater: %COL%[92mУстановлена и работает%COL%[37m
    set "GoodbyeZapretUpdaterServiceAction=Выключить"
) else (
    echo   Служба GoodbyeZapret Updater: %COL%[91mНе установлена%COL%[37m
    set "GoodbyeZapretUpdaterServiceAction=Включить"
)
tasklist | find /i "Winws.exe" >nul
if %errorlevel% equ 0 (
    echo   Процесс Winws.exe: %COL%[92mЗапущен%COL%[37m
) else (
    echo   Процесс Winws.exe:  %COL%[91mНе найден%COL%[37m
)
echo.
echo.
echo   Состояние версий GoodbyeZapret
echo   %COL%[90m==============================%COL%[37m
if !Current_GoodbyeZapret_version! LSS !Actual_GoodbyeZapret_version! (
    echo   Версия GodbyeZapret: %COL%[92m%GoodbyeZapretVersion% %COL%[91m^(Устарела^) %COL%[37m
) else (
    echo   Версия GodbyeZapret: %COL%[92m%GoodbyeZapretVersion% %COL%[37m
)

if !Current_Winws_version! neq !Actual_Winws_version! (
    echo   Версия Winws: %COL%[92m%WinwsVersion% %COL%[91m^(Устарела^) ^(!Current_Winws_version! → !Actual_Winws_version!^) %COL%[37m
) else (
    echo   Версия Winws: %COL%[92m%WinwsVersion% %COL%[37m
)

if !Current_Configs_version! neq !Actual_Configs_version! (
    echo   Версия Configs: %COL%[92m%ConfigsVersion% %COL%[91m^(Устарела^) ^(!Current_Configs_version! → !Actual_Configs_version!^) %COL%[37m
) else (
    echo   Версия Configs: %COL%[92m%ConfigsVersion% %COL%[37m
)

if !Current_List_version! neq !Actual_List_version! (
    echo   Версия Lists: %COL%[92m%ListsVersion% %COL%[91m^(Устарела^) ^(!Current_List_version! → !Actual_List_version!^) %COL%[37m
) else (
    echo   Версия Lists: %COL%[92m%ListsVersion% %COL%[37m
)
echo. 
echo.
echo. 
echo.
echo                 %COL%[96mF %COL%[37m- %COL%[93m%GoodbyeZapretUpdaterServiceAction% GoodbyeZapret Updater%COL%[37m / %COL%[96mB %COL%[37m- %COL%[93mВернуться назад%COL%[37m
echo.
echo.
echo                                     Введите букву (%COL%[96mF%COL%[90m/%COL%[96mB%COL%[37m)
echo.
set /p "choice=%DEL%                                            %COL%[90m:> "

if /i "%choice%"=="B" goto MainMenu
if /i "%choice%"=="и" goto MainMenu
if /i "%choice%"=="F" goto GoodbyeZapretUpdaterService_toggle
if /i "%choice%"=="а" goto GoodbyeZapretUpdaterService_toggle
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
:install_assistant
IF "%WiFi%" == "Off" (
 	echo [WARN ] %TIME% - Соединение с интернетом отсутствует >> "%ASX-Directory%\Files\Logs\%date%.txt"
    cls
    echo.
    echo   Error 01: No internet connection.
    timeout /t 4 >nul
    exit
)

set "Assistant_version=0.2"
mode con: cols=112 lines=38 >nul 2>&1
REM Цветной текст
for /F "tokens=1,2 delims=#" %%a in ('"prompt #$H#$E# & echo on & for %%b in (1) do rem"') do (set "DEL=%%a" & set "COL=%%b")

chcp 65001 >nul 2>&1


cls
title ALFiX, Inc. - Помощник по установке программного обеспечения ALFiX, Inc. (версия %Assistant_version%)
echo.
echo.

echo                                                    %COL%[91m@@@@@@@            
echo                                                    @@@@@@@            
echo                                                    @@@@@@@            
echo                                                    @@@@@@@            
echo                                                    @@@@@@@            
echo                                                    @@@@@@@            
echo                                                    @@@@@@@            
echo                                               @@@@@@@@@@@@@@@@@       
echo                                               @@@@@@@@@@@@@@@@@       
echo                                                 @@@@@@@@@@@@@         
echo                                                  @@@@@@@@@@@          
echo                                         %COL%[36m@@@@       %COL%[91m@@@@@@@       %COL%[36m@@@@ 
echo                                         %COL%[36m@@@@         %COL%[91m@@@         %COL%[36m@@@@ 
echo                                         @@@@                     @@@@ 
echo                                         @@@@                     @@@@ 
echo                                         @@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 
echo                                         @@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 

echo.
echo.
echo.
echo  %COL%[36mВас приветствует установщик программного обеспечения от ALFiX, Inc.
echo  %COL%[37mВам нужно ответить на несколько вопросов, чтобы установить и настроить GoodbyeZapret.
echo.
echo.
echo  %COL%[90mНажмите любую клавишу для продолжения...
pause >nul


:install_GoodbyeZapret
cls
echo.
echo.
echo.
echo.
echo  %COL%[90m Идет процесс установки.
echo  %COL%[93m Пожалуйста подождите...
echo.
echo.


curl -g -L -# -o %TEMP%\GoodbyeZapret.zip "https://github.com/ALFiX01/GoodbyeZapret/raw/refs/heads/main/Files/GoodbyeZapret.zip" >nul 2>&1
curl -g -L -# -o "%SystemDrive%\GoodbyeZapret\Updater.exe" "https://github.com/ALFiX01/GoodbyeZapret/raw/refs/heads/main/Files/Updater/Updater.exe" >nul 2>&1


if exist "%TEMP%\GoodbyeZapret.zip" (
    chcp 850 >nul 2>&1
    powershell -NoProfile Expand-Archive '%TEMP%\GoodbyeZapret.zip' -DestinationPath '%SystemDrive%\GoodbyeZapret' >nul 2>&1
    chcp 65001 >nul 2>&1
    if exist "%SystemDrive%\GoodbyeZapret" (
        echo  GoodbyeZapret будет находиться по пути: %SystemDrive%\GoodbyeZapret
    )
) else (
    Echo Error: File not found: %TEMP%\GoodbyeZapret.zip
    timeout /t 5 >nul
    exit
)

echo.
echo  %COL%[92mУстановка завершена.
echo.
echo.
echo  %COL%[90mНажмите любую клавишу для запуска GoodbyeZapret...
pause >nul


cls
echo.
echo.
echo.
echo.
echo  %COL%[90mУстановка завершена.
echo  Давай попробуем настроить GoodbyeZapret...
echo.
echo.



:Update_Need_screen
cls
mode con: cols=92 lines=30 >nul 2>&1
echo.
echo.
echo.
cls
echo.
echo           %COL%[90m_____                 _ _                  ______                    _   
echo          / ____^|               ^| ^| ^|                ^|___  /                   ^| ^|  
echo         ^| ^|  __  ___   ___   __^| ^| ^|__  _   _  ___     / / __ _ _ __  _ __ ___^| ^|_ 
echo         ^| ^| ^|_ ^|/ _ \ / _ \ / _` ^| '_ \^| ^| ^| ^|/ _ \   / / / _` ^| '_ \^| '__/ _ \ __^|
echo         ^| ^|__^| ^| ^(_^) ^| ^(_^) ^| ^(_^| ^| ^|_^) ^| ^|_^| ^|  __/  / /_^| ^(_^| ^| ^|_^) ^| ^| ^|  __/ ^|_ 
echo          \_____^|\___/ \___/ \__,_^|_.__/ \__, ^|\___^| /_____\__,_^| .__/^|_^|  \___^|\__^|
echo                                          __/ ^|                 ^| ^|                 
echo                                         ^|___/                  ^|_^|
echo.
echo.
echo                   %COL%[97mДоступны новые версии GoodbyeZapret и других компонентов%COL%[37m
echo.
echo.
echo.
if !Current_GoodbyeZapret_version! LSS !Actual_GoodbyeZapret_version! (
    echo                                 GodbyeZapret: %COL%[92m^(v!Current_GoodbyeZapret_version! → v!Actual_GoodbyeZapret_version!^) %COL%[37m
)
if !Current_Winws_version! neq !Actual_Winws_version! (
    echo                                     Winws: %COL%[92m^(v!Current_Winws_version! → v!Actual_Winws_version!^) %COL%[37m
)

if !Current_Configs_version! neq !Actual_Configs_version! (
    echo                                       Configs: %COL%[92m^(v!Current_Configs_version! → v!Actual_Configs_version!^) %COL%[37m
)

if !Current_List_version! neq !Actual_List_version! (
    echo                                        Lists: %COL%[92m^(v!Current_List_version! → v!Actual_List_version!^) %COL%[37m
)
echo.
echo.
echo.
echo.
echo.
echo.
echo.

echo                                %COL%[91mB%COL%[37m - Пропустить  /  %COL%[92mU%COL%[37m - Обновить
echo.
set /p "choice=%DEL%                                            %COL%[90m:> "
if /i "%choice%"=="B" mode con: cols=92 lines=%ListBatCount% >nul 2>&1 && goto MainMenu
if /i "%choice%"=="и" mode con: cols=92 lines=%ListBatCount% >nul 2>&1 && goto MainMenu
if /i "%choice%"=="U" goto FullUpdate
if /i "%choice%"=="г" goto FullUpdate
goto Update_Need_screen