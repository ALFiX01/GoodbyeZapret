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


if Not exist %SystemDrive%\GoodbyeZapret (
    goto install_assistant
)


:RR

set "BatCount=0"
set "sourcePath=%~dp0"

for %%f in ("%sourcePath%Configs\*.bat") do (
    set /a "BatCount+=1"
)


set /a ListBatCount=BatCount+29
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
set "CheckStatus=WithoutChecked"
set "sourcePath=%~dp0"
set "serviceName=GoodbyeZapret"

set "GoodbyeZapret_Current=Не выбран"
set "GoodbyeZapret_Config=Не выбран"

reg query HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\GoodbyeZapret /v Description >nul 2>&1
if %errorlevel% equ 0 (
   REM Ключ GoodbyeZapret_Version существует.
   for /f "tokens=2*" %%a in ('reg query "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\GoodbyeZapret" /v "Description" 2^>nul ^| find /i "Description"') do set "GoodbyeZapret_Current=%%b"
)

for /f "usebackq delims=" %%a in ("%sourcePath%version.txt") do set "Current_GoodbyeZapret_version=%%a"
for /f "usebackq delims=" %%a in ("%sourcePath%bin\version.txt") do set "Current_Winws_version=%%a"
for /f "usebackq delims=" %%a in ("%sourcePath%lists\version.txt") do set "Current_List_version=%%a"



:: Загрузка нового файла Updater.bat
if exist "%TEMP%\GZ_Updater.bat" del /s /q /f "%TEMP%\GZ_Updater.bat" >nul 2>&1
curl -s -o "%TEMP%\GZ_Updater.bat" "https://raw.githubusercontent.com/ALFiX01/GoodbyeZapret/refs/heads/main/GoodbyeZapret_Version" 
if errorlevel 1 (
    echo ERROR - Ошибка связи с сервером проверки обновлений GoodbyeZapret
    
)
call:AZ_FileChecker_2
if not "%CheckStatus%"=="Checked" (
    echo Ошибка: Не удалось провести проверку файла
    
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

set "ListsVersion_New=%Actual_List_version%"
set "ListsVersion=%Current_List_version%"


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

reg query HKCU\Software\ASX\Info /v GoodbyeZapret_Version >nul 2>&1
if %errorlevel% equ 0 (
   REM Ключ GoodbyeZapret_Version существует.
   for /f "tokens=2*" %%a in ('reg query "HKCU\Software\ASX\Info" /v "GoodbyeZapret_Version" 2^>nul ^| find /i "GoodbyeZapret_Version"') do set "GoodbyeZapret_Version_OLD=%%b"
) else (
   REM Ключ GoodbyeZapret_Version не найден.
   reg add "HKCU\Software\ASX\Info" /t REG_SZ /v "GoodbyeZapret_Version" /d "%GoodbyeZapretVersion%" /f >nul
   set "GoodbyeZapret_Version_OLD=Не выбран"
)

reg query HKCU\Software\ASX\Info /v GoodbyeZapret_Config >nul 2>&1
if %errorlevel% equ 0 (
   REM Ключ GoodbyeZapret_Version существует.
   for /f "tokens=2*" %%a in ('reg query "HKCU\Software\ASX\Info" /v "GoodbyeZapret_Config" 2^>nul ^| find /i "GoodbyeZapret_Config"') do set "GoodbyeZapret_Config=%%b"
)

reg query HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\GoodbyeZapret /v Description >nul 2>&1
if %errorlevel% equ 0 (
   REM Ключ GoodbyeZapret_Version существует.
   for /f "tokens=2*" %%a in ('reg query "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\GoodbyeZapret" /v "Description" 2^>nul ^| find /i "Description"') do set "GoodbyeZapret_Current=%%b"
)


if defined GoodbyeZapretVersion (
    reg add "HKCU\Software\ASX\Info" /v "GoodbyeZapret_Version" /t REG_SZ /d "%GoodbyeZapretVersion%" /f >nul 2>&1
)


:GZ_loading_procces
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

:: Пример содержимого переменной
set "GoodbyeZapret_Current=Текущий конфиг - %GoodbyeZapret_Current%"

:: Подсчет длины текста
set "text_length=0"
for /l %%A in (1,1,90) do (
    set "char=!GoodbyeZapret_Current:~%%A,1!"
    if "!char!"=="" goto :count_done
    set /a text_length+=1
)
:count_done

:: Расчет количества пробелов
set /a spaces=(line_length - text_length) / 2

:: Формирование строки с пробелами
set "padding="
for /l %%A in (1,1,%spaces%) do set "padding=!padding! "


if "%GoodbyeZapret_Current%" NEQ "Не выбран" (
    echo                     %COL%[90m===================================================
    echo %COL%[36m!padding!!GoodbyeZapret_Current! %COL%[37m
    echo                     %COL%[90m===================================================%COL%[37m
    echo.
) else (
echo                     %COL%[37mДобро пожаловать
echo                     %COL%[91mОболочка находится в стадии тестирования и может содержать ошибки%COL%[37m
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
    echo.
    echo                      %COL%[36mDS %COL%[37m- %COL%[91mУдалить службу из автозапуска%COL%[37m
) else (
    echo.
    echo.
    echo                     %COL%[36mDS %COL%[37m- %COL%[91mУдалить службу из автозапуска%COL%[37m
)
if !counter! lss 10 (
    echo                      %COL%[36mRC %COL%[37m- %COL%[91mПринудительно переустановить конфиги%COL%[37m
) else (
    echo                     %COL%[36mRC %COL%[37m- %COL%[91mПринудительно переустановить конфиги%COL%[37m
)
if !counter! lss 10 (
    echo                      %COL%[36mST %COL%[37m- %COL%[91mСостояние GoodbyeZapret%COL%[37m
) else (
    echo                     %COL%[36mST %COL%[37m- %COL%[91mСостояние GoodbyeZapret%COL%[37m
)

if !counter! lss 10 (
    echo                  %COL%[36m^(%COL%[36m1%COL%[37m-%COL%[36m!counter!^)s %COL%[37m- %COL%[91mЗапустить конфиг %COL%[37m
) else (
    echo                %COL%[36m^(%COL%[36m1%COL%[37m-%COL%[36m!counter!^)s %COL%[37m- %COL%[91mЗапустить конфиг %COL%[37m
)

if %UpdateNeed% equ Yes (
    if !counter! lss 10 (
        echo                      %COL%[36mUD %COL%[37m- %COL%[93mОбновить до v!Actual_GoodbyeZapret_version! %COL%[37m
    ) else (
        echo                     %COL%[36mUD %COL%[37m- %COL%[93mОбновить до v!Actual_GoodbyeZapret_version! %COL%[37m
    )
)


echo.
echo.
echo                                     Введите номер (%COL%[36m1%COL%[37m-%COL%[36m!counter!%COL%[37m)
set /p "choice=%DEL%                                            %COL%[90m:> "

if "%choice%"=="B" goto GoBack
if "%choice%"=="и" goto GoBack
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
     reg add "HKCU\Software\ASX\Info" /t REG_SZ /v "GoodbyeZapret_Config" /d "%batFile:~0,-4%" /f >nul
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
    reg delete "HKCU\Software\ASX\Info" /v "GoodbyeZapret_Config" /f >nul 2>&1
goto :end

:end
echo Нажмите любую клавишу чтобы продолжить...
pause >nul 2>&1
goto GoodbyeZapret_Menu


:CurrentStatus
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
    echo   Версия Winws: %COL%[92m%WinwsVersion% %COL%[91m^(Устарела^) %COL%[37m
) else (
    echo   Версия Winws: %COL%[92m%WinwsVersion% %COL%[37m
)

if !Current_List_version! neq !Actual_List_version! (
    echo   Версия Lists: %COL%[92m%ListsVersion% %COL%[91m^(Устарела^) %COL%[37m
) else (
    echo   Версия Lists: %COL%[92m%ListsVersion% %COL%[37m
)
echo. 
echo.
pause >nul 2>&1
goto GZ_loading_procces


:ReInstall_GZ
cls
title Отключение текущего конфига GoodbyeZapret
net stop GoodbyeZapret >nul 2>&1
echo %COL%[90mУдаление службы GoodbyeZapret...
sc delete GoodbyeZapret >nul 2>&1
echo Файл winws.exe в данный момент выполняется.
taskkill /F /IM winws.exe >nul 2>&1
net stop "WinDivert" >nul 2>&1
sc delete "WinDivert" >nul 2>&1
net stop "WinDivert14" >nul 2>&1
sc delete "WinDivert14" >nul 2>&1
echo Файл winws.exe был остановлен.

title Переустановка конфигов GoodbyeZapret

reg query HKCU\Software\ASX\Info /v GoodbyeZapret_Config >nul 2>&1
if %errorlevel% equ 0 (
   REM Ключ GoodbyeZapret_Version существует.
   for /f "tokens=2*" %%a in ('reg query "HKCU\Software\ASX\Info" /v "GoodbyeZapret_Config" 2^>nul ^| find /i "GoodbyeZapret_Config"') do set "GoodbyeZapret_Config=%%b"
)

if exist "%parentDir%\GoodbyeZapret_latest.zip" del /s /q /f "%parentDir%\GoodbyeZapret_latest.zip" >nul 2>&1


curl -g -L -# -o %parentDir%\GoodbyeZapret_latest.zip "https://github.com/ALFiX01/GoodbyeZapret/raw/refs/heads/main/Project/GoodbyeZapret.zip" >nul 2>&1

call:AZ_FileChecker
if not "%CheckStatus%"=="Checked" (
    echo     %COL%[91m   Ошибка: Не удалось провести проверку файла%COL%[37m
    pause
    goto GoodbyeZapret_Menu
)
    if exist "%parentDir%\GoodbyeZapret_latest.zip" (
        start /wait "" "%~dp0Extract.bat"
            if errorlevel 1 (
                echo     %COL%[91m   Ошибка: Не удалось распаковать файл%COL%[37m
                pause
                goto GoodbyeZapret_Menu
            )
        timeout /t 1 >nul
        for /f "usebackq delims=" %%a in ("%parentDir%\GoodbyeZapret_latest\version.txt") do set "GoodbyeZapret_version_newfile=%%a"
        ren "%parentDir%\GoodbyeZapret_latest" "GoodbyeZapret_%GoodbyeZapret_version_newfile%"
        del "%parentDir%\GoodbyeZapret_latest.zip" >nul 2>&1
        start "" "%parentDir%\GoodbyeZapret_%GoodbyeZapret_version_newfile%"
    ) else (
        echo     %COL%[91m   Ошибка: Не удалось скачать файл GoodbyeZapret.zip. Проверьте подключение к интернету и доступность URL.%COL%[37m
        pause
        goto GoodbyeZapret_Menu
    )

title Настройка конфига GoodbyeZapret

echo Устанавливаю службу GoodbyeZapret для файла %GoodbyeZapret_Config%...

(
sc create "GoodbyeZapret" binPath= "cmd.exe /c \"%SystemDrive%\GoodbyeZapret\Configs\%batFile%" start= auto
sc description GoodbyeZapret "%GoodbyeZapret_Config%" ) >nul 2>&1
sc start "GoodbyeZapret" >nul 2>&1
sc start "GoodbyeZapret" >nul 2>&1
if %errorlevel% equ 0 (
    echo Служба GoodbyeZapret успешно запущена %COL%[37m
) else (
    echo Ошибка при запуске службы GoodbyeZapret
)
goto GoodbyeZapret_Menu


:AZ_FileChecker
set "FileSize=0"
set "CheckStatus=Checked"
REM set "file=%ASX-Directory%\Files\Downloads\%FileName%"
set "Check_FilePatch=%parentDir%\GoodbyeZapret_latest.zip"
set "Check_FileName=GoodbyeZapret_latest.zip"

for %%I in ("%Check_FilePatch%") do set FileSize=%%~zI

if not exist "%Check_FilePatch%" ( 
    set "CheckStatus=NoChecked"
    REM echo     %COL%[91m   └ Ошибка: Не удалось провести проверку файла%COL%[37m
    echo ERROR - Не удалось провести проверку файла - %Check_FileName% не найден
    goto GoBack
)

if not defined FileSize (
    set "CheckStatus=NoChecked"
    REM echo     %COL%[91m   └ Ошибка: Не удалось провести проверку файла%COL%[37m
    echo ERROR - Не удалось провести проверку файла %Check_FileName%
    echo.
    del /Q "%Check_FilePatch%"
    goto GoBack
)
if %FileSize% LSS 100 (
    set "CheckStatus=NoChecked"
    REM echo     %COL%[91m   └ Ошибка: Файл не прошел проверку. Возможно, он поврежден %COL%[37m
    echo ERROR - Файл %Check_FileName% поврежден или URL не доступен ^(Size %FileSize%^)
    echo.
    del /Q "%Check_FilePatch%"
    goto GoBack
)
goto :eof

:AZ_FileChecker_2
set "FileSize=0"
set "CheckStatus=Checked"
REM set "file=%ASX-Directory%\Files\Downloads\%FileName%"
set "Check_FilePatch=%TEMP%\GZ_Updater.bat"
set "Check_FileName=GZ_Updater.bat"

for %%I in ("%Check_FilePatch%") do set FileSize=%%~zI

if not exist "%Check_FilePatch%" ( 
    set "CheckStatus=NoChecked"
    REM echo     %COL%[91m   └ Ошибка: Не удалось провести проверку файла%COL%[37m
    echo ERROR - Не удалось провести проверку файла - %Check_FileName% не найден
    goto GoBack
)

if not defined FileSize (
    set "CheckStatus=NoChecked"
    REM echo     %COL%[91m   └ Ошибка: Не удалось провести проверку файла%COL%[37m
    echo ERROR - Не удалось провести проверку файла %Check_FileName%
    echo.
    del /Q "%Check_FilePatch%"
    goto GoBack
)
if %FileSize% LSS 15 (
    set "CheckStatus=NoChecked"
    REM echo     %COL%[91m   └ Ошибка: Файл не прошел проверку. Возможно, он поврежден %COL%[37m
    echo ERROR - Файл %Check_FileName% поврежден или URL не доступен ^(Size %FileSize%^)
    echo.
    del /Q "%Check_FilePatch%"
    goto GoBack
)
goto :eof


:FullUpdate

title Отключение текущего конфига GoodbyeZapret
net stop GoodbyeZapret >nul 2>&1
echo %COL%[90mУдаление службы GoodbyeZapret...
sc delete GoodbyeZapret >nul 2>&1
echo Файл winws.exe в данный момент выполняется.
taskkill /F /IM winws.exe >nul 2>&1
net stop "WinDivert" >nul 2>&1
sc delete "WinDivert" >nul 2>&1
net stop "WinDivert14" >nul 2>&1
sc delete "WinDivert14" >nul 2>&1
echo Файл winws.exe был остановлен.

reg query HKCU\Software\ASX\Info /v GoodbyeZapret_Config >nul 2>&1
if %errorlevel% equ 0 (
   REM Ключ GoodbyeZapret_Version существует.
   for /f "tokens=2*" %%a in ('reg query "HKCU\Software\ASX\Info" /v "GoodbyeZapret_Config" 2^>nul ^| find /i "GoodbyeZapret_Config"') do set "GoodbyeZapret_Config=%%b"
)

if exist "%parentDir%\GoodbyeZapret_latest.zip" del /s /q /f "%parentDir%\GoodbyeZapret_latest.zip" >nul 2>&1

curl -g -L -# -o %parentDir%\GoodbyeZapret_latest.zip "https://github.com/ALFiX01/GoodbyeZapret/raw/refs/heads/main/Project/GoodbyeZapret.zip" >nul 2>&1

call:AZ_FileChecker
if not "%CheckStatus%"=="Checked" (
    echo     %COL%[91m   Ошибка: Не удалось провести проверку файла%COL%[37m
    pause
    goto GoodbyeZapret_Menu
)
    if exist "%parentDir%\GoodbyeZapret_latest.zip" (
        start /wait "" "%~dp0Extract.bat"
            if errorlevel 1 (
                echo     %COL%[91m   Ошибка: Не удалось распаковать файл%COL%[37m
                pause
                goto GoodbyeZapret_Menu
            )
        timeout /t 1 >nul
        for /f "usebackq delims=" %%a in ("%parentDir%\GoodbyeZapret_latest\Version.txt") do set "GoodbyeZapret_version_newfile=%%a"
        ren "%parentDir%\GoodbyeZapret_latest" "GoodbyeZapret_!GoodbyeZapret_version_newfile!"
        del "%parentDir%\GoodbyeZapret_latest.zip" >nul 2>&1
        start "" "%parentDir%\GoodbyeZapret_!GoodbyeZapret_version_newfile!"
    ) else (
        echo     %COL%[91m   Ошибка: Не удалось скачать файл GoodbyeZapret.zip. Проверьте подключение к интернету и доступность URL.%COL%[37m
        pause
        goto GoodbyeZapret_Menu
    )

title Настройка конфига GoodbyeZapret

echo Восстанавливаю службу GoodbyeZapret для файла %GoodbyeZapret_Config%...

(
sc create "GoodbyeZapret" binPath= "cmd.exe /c \"%parentDir%\GoodbyeZapret_!GoodbyeZapret_version_newfile!\Configs\%GoodbyeZapret_Config%.bat\"" start= auto
sc description GoodbyeZapret "%GoodbyeZapret_Config%" ) >nul 2>&1
sc start "GoodbyeZapret" >nul 2>&1
sc start "GoodbyeZapret" >nul 2>&1
if %errorlevel% equ 0 (
    echo Служба GoodbyeZapret успешно запущена %COL%[37m
) else (
    echo Возможно при запуске службы GoodbyeZapret произошла ошибка
)
start "" "%parentDir%\GoodbyeZapret_!GoodbyeZapret_version_newfile!\Launcher.bat"
echo готово
pause
exit



:install_assistant
mode con: cols=112 lines=38 >nul 2>&1
REM Цветной текст
for /F "tokens=1,2 delims=#" %%a in ('"prompt #$H#$E# & echo on & for %%b in (1) do rem"') do (set "DEL=%%a" & set "COL=%%b")

chcp 65001 >nul 2>&1


cls
title ALFiX, Inc. - Установка программного обеспечения
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
echo  %COL%[36mВас приветствует установщик программного обеспечения от ALFiX, Inc.%COL%[37m
echo  Вам нужно ответить на несколько вопросов, чтобы установить и настроить GoodbyeZapret.
echo.
echo.
echo  %COL%[90mНажмите любую клавишу для продолжения...%COL%[37m
pause >nul

cls
echo.
echo.
echo.
echo.
echo  %COL%[36mВопрос 1:%COL%[37m Какой у вас провайдер?
echo.
echo  %COL%[90m1^) MGTS%COL%[37m
echo  %COL%[90m2^) Beeline%COL%[37m
echo  %COL%[90m3^) Rostelecom%COL%[37m
echo  %COL%[90m4^) Другой провайдер%COL%[37m
echo.
set /p choice="%DEL%        >: "

if /i "%choice%"=="1" ( set "ProviderQuastion=Y" && set "ProviderName=MGTS" )
if /i "%choice%"=="2" ( set "ProviderQuastion=Y" && set "ProviderName=Beeline" )
if /i "%choice%"=="3" ( set "ProviderQuastion=Y" && set "ProviderName=Rostelecom" )
if /i "%choice%"=="4" ( set "ProviderQuastion=N" && set "ProviderName=Other" )

cls
echo.
echo.
echo.
echo.
echo  %COL%[36mВопрос 2:%COL%[37m Хотите ли вы чтобы GoodbyeZapret автоматически обновлялся?
echo.
echo  %COL%[90m1^) Да%COL%[37m
echo  %COL%[90m2^) Нет%COL%[37m
echo.
set /p choice="%DEL%        >: "

if /i "%choice%"=="1" ( set "AutoUpdateQuastion=Y" )
if /i "%choice%"=="2" ( set "AutoUpdateQuastion=N" )

cls
echo.
echo.
echo.
echo.
echo  %COL%[36mВопрос 3:%COL%[37m Хотите ли вы чтобы GoodbyeZapret запускался при запуске системы?
echo.
echo  %COL%[90m1^) Да%COL%[37m
echo  %COL%[90m2^) Нет%COL%[37m
echo.
set /p choice="%DEL%        >: "

if /i "%choice%"=="1" ( set "AutoStartQuastion=Y" )
if /i "%choice%"=="2" ( set "AutoStartQuastion=N" )

cls
echo.
echo.
echo.
echo.
echo  %COL%[36mВопрос 4:%COL%[37m Что вы хотите разблокировать через GoodbyeZapret?
echo.
echo  %COL%[90m1^) Только Youtube%COL%[37m
echo  %COL%[90m2^) Только Discord%COL%[37m
echo  %COL%[90m3^) Youtube, Discord и другие сервисы%COL%[37m
echo.
set /p choice="%DEL%        >: "

if /i "%choice%"=="1" ( set "YT-Discord-Quastion=YT" )
if /i "%choice%"=="2" ( set "YT-Discord-Quastion=DS" )
if /i "%choice%"=="3" ( set "YT-Discord-Quastion=YTDS" )

cls
echo.
echo.
echo.
echo.
echo  %COL%[90mВопросы закончились.%COL%[90m
echo  %COL%[93mПодождите пока я выполню установку...
echo.
echo.


curl -g -L -# -o %TEMP%\GoodbyeZapret.zip "https://github.com/ALFiX01/GoodbyeZapret/raw/refs/heads/main/Project/GoodbyeZapret.zip" >nul 2>&1

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

if %ProviderQuastion%=="N" (
    del /f /q "%SystemDrive%\GoodbyeZapret\Configs\DiscordFix_Beeline-Rostelekom.bat" >nul 2>&1
    del /f /q "%SystemDrive%\GoodbyeZapret\Configs\DiscordFix_MGTS.bat" >nul 2>&1
    del /f /q "%SystemDrive%\GoodbyeZapret\Configs\UltimateFix_ALT_Beeline-Rostelekom.bat" >nul 2>&1
    del /f /q "%SystemDrive%\GoodbyeZapret\Configs\UltimateFix_ALT_MGTS.bat" >nul 2>&1
    del /f /q "%SystemDrive%\GoodbyeZapret\Configs\UltimateFix_Beeline-Rostelekom.bat" >nul 2>&1
    del /f /q "%SystemDrive%\GoodbyeZapret\Configs\UltimateFix_MGTS.bat" >nul 2>&1
    del /f /q "%SystemDrive%\GoodbyeZapret\Configs\YoutubeFix_ALT_MGTS.bat" >nul 2>&1
    del /f /q "%SystemDrive%\GoodbyeZapret\Configs\YoutubeFix_MGTS.bat" >nul 2>&1
)

echo.
echo  %COL%[92mУстановка завершена.
echo.
echo.
echo  %COL%[90mНажмите любую клавишу для настройки GoodbyeZapret...
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



REM if "%ProviderQuastion%" == "N" ( goto Provider_Quastion_no )
REM if "%ProviderQuastion%" == "Y" ( goto Provider_Quastion_yes )


REM если провайдера нет в списке
:Provider_Quastion_no

if "%YT-Discord-Quastion%" == "YT" (
    call "%SystemDrive%\GoodbyeZapret\Configs\YoutubeFix.bat"
    set "batFile=YoutubeFix.bat"
    start https://youtube.com
    cls
    echo.
    echo.
    echo.
    echo.
    echo  %COL%[90mЯ запустил тестовый конфиг и запустил Youtube.
    echo  Проверьте, что все работает.
    echo.
    echo  %COL%[93mРаботает ли Youtube?
    echo.
    echo  %COL%[90m1^) Да%COL%[37m
    echo  %COL%[90m2^) Нет%COL%[37m
    echo.
    set /p choice="%DEL%        >: "

    if /i "%choice%"=="1" ( set "Working=Y" && goto Complete_Working )
    if /i "%choice%"=="2" ( set "Working=N"
        call "%SystemDrive%\GoodbyeZapret\Configs\YoutubeFix_ALT.bat"
        set "batFile=YoutubeFix_ALT.bat"
        start https://youtube.com
        cls
        echo.
        echo.
        echo.
        echo.
        echo  %COL%[90mЯ запустил альтернативный конфиг и запустил Youtube.
        echo  Проверьте, что все работает.
        echo.
        echo  %COL%[93mРаботает ли Youtube?
        echo.
        echo  %COL%[90m1^) Да%COL%[37m
        echo  %COL%[90m2^) Нет%COL%[37m
        echo.
        set /p choice="%DEL%        >: "
        
        if /i "%choice%"=="1" ( set "Working=Y" && goto Complete_Working )
        if /i "%choice%"=="2" ( set "Working=N" && Goto Complete_NotWorking )
    )
)

:DS-Fixing
if "%YT-Discord-Quastion%" == "DS" (
    call "%SystemDrive%\GoodbyeZapret\Configs\DiscordFix.bat"
    set "batFile=DiscordFix.bat"
    start "" "C:\Users\%USERNAME%\AppData\Local\Discord\Update.exe" --processStart Discord.exe
    cls
    echo.
    echo.
    echo.
    echo.
    echo  %COL%[90mЯ Запустил тестовый конфиг и запустил Discord.
    echo  Проверьте, что все работает.
    echo.
    echo  %COL%[93mРаботает ли Discord и Войсы в нем?
    echo.
    echo  %COL%[90m1^) Да%COL%[37m
    echo  %COL%[90m2^) Нет%COL%[37m
    echo.
    set /p choice="%DEL%        >: "

    if /i "%choice%"=="1" ( set "Working=Y" && goto Complete_Working )
    if /i "%choice%"=="2" ( set "Working=N"
        call "%SystemDrive%\GoodbyeZapret\Configs\DiscordFix_ALT.bat"
        set "batFile=DiscordFix_ALT.bat"
        start "" "C:\Users\%USERNAME%\AppData\Local\Discord\Update.exe" --processStart Discord.exe
        cls
        echo.
        echo.
        echo.
        echo.
        echo  %COL%[90mЯ Запустил альтернативный конфиг и запустил Discord.
        echo  Проверьте, что все работает.
        echo.
        echo  %COL%[93mА щас работает ли Discord и Войсы в нем?
        echo.
        echo  %COL%[90m1^) Да%COL%[37m
        echo  %COL%[90m2^) Нет%COL%[37m
        echo.
        set /p choice="%DEL%        >: "
        
        if /i "%choice%"=="1" ( set "Working=Y" && goto Complete_Working )
        if /i "%choice%"=="2" ( set "Working=N" && Goto Complete_NotWorking )
    )
)

:YTDS-Fixing
if "%YT-Discord-Quastion%" == "YTDS" (
    call "%SystemDrive%\GoodbyeZapret\Configs\UltimateFix.bat"
    set "batFile=UltimateFix.bat"
    start https://youtube.com
    start "" "C:\Users\%USERNAME%\AppData\Local\Discord\Update.exe" --processStart Discord.exe
    cls
    echo.
    echo.
    echo.
    echo.
    echo  %COL%[90mЯ Запустил тестовый конфиг и запустил Youtube и Discord.
    echo  Проверьте, что все работает.
    echo.
    echo  %COL%[93mРаботает ли Youtube и Discord?
    echo.
    echo  %COL%[90m1^) Да%COL%[37m
    echo  %COL%[90m2^) Нет%COL%[37m
    echo.
    set /p choice="%DEL%        >: "

    if /i "%choice%"=="1" ( set "Working=Y" && goto Complete_Working )
    if /i "%choice%"=="2" ( set "Working=N"
        call "%SystemDrive%\GoodbyeZapret\Configs\UltimateFix_ALT.bat"
        set "batFile=UltimateFix_ALT.bat"
        start https://youtube.com
        start "" "C:\Users\%USERNAME%\AppData\Local\Discord\Update.exe" --processStart Discord.exe
        cls
        echo.
        echo.
        echo.
        echo.
        echo  Я Запустил альтернативный конфиг и запустил Youtube и Discord.
        echo  Проверьте, что все работает.
        echo.
        echo  %COL%[93mА щас работает ли Youtube и Discord?
        echo.
        echo  %COL%[90m1^) Да%COL%[37m
        echo  %COL%[90m2^) Нет%COL%[37m
        echo.
        set /p choice="%DEL%        >: "
        
        if /i "%choice%"=="1" ( set "Working=Y" && goto Complete_Working )
        if /i "%choice%"=="2" ( set "Working=N"
            call "%SystemDrive%\GoodbyeZapret\Configs\UltimateFix_ALT_2.bat"
            set "batFile=UltimateFix_ALT_2.bat"
            start https://youtube.com
            start "" "C:\Users\%USERNAME%\AppData\Local\Discord\Update.exe" --processStart Discord.exe
            cls
            echo.
            echo.
            echo.
            echo.
            echo  Я Запустил другой альтернативный конфиг и запустил Youtube и Discord.
            echo  Проверьте, что все работает.
            echo.
            echo  %COL%[93mТеперь работает ли Youtube и Discord?
            echo.
            echo  %COL%[90m1^) Да%COL%[37m
            echo  %COL%[90m2^) Нет%COL%[37m
            echo.
            set /p choice="%DEL%        >: "
            
            if /i "%choice%"=="1" ( set "Working=Y" && goto Complete_Working )
            if /i "%choice%"=="2" ( set "Working=N" && Goto Complete_NotWorking )
        )
    )
)



:Complete_Working
if "%AutoStartQuastion%" == "Y" (
     cls
     echo.
     echo.
     echo.
     echo Устанавливаю службу GoodbyeZapret для файла %batFile%-%batFile:~0,-4%...
     echo %COL%[93mНажмите любую клавишу для подтверждения%COL%[37m
     pause >nul 2>&1
     sc create "GoodbyeZapret" binPath= "cmd.exe /c \"%SystemDrive%\GoodbyeZapret\Configs\%batFile%" start= auto
     reg add "HKCU\Software\ASX\Info" /t REG_SZ /v "GoodbyeZapret_Config" /d "%batFile:~0,-4%" /f >nul
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
)
pause
cls
echo.
echo.
echo.
echo.
echo  %COL%[92mПоздравляю. GoodbyeZapret настроен и работает.%COL%[37m
echo  %COL%[93mПерезагрузите ПК, чтобы служба GoodbyeZapret заработала.%COL%[37m
echo.
echo  Если у вас возникли проблемы, пожалуйста, обратитесь к разработчику.
echo.
echo.
echo  %COL%[90mНажмите любую клавишу для завершения...
pause >nul
exit


:Complete_NotWorking
cls
echo.
echo.
echo.
echo.
echo  %COL%[91mК сожалению, мои попытки настроить вам GoodbyeZapret не увенчались успехом.%COL%[37m
echo.
echo  Пожалуйста, обратитесь к разработчику.
echo.
echo.
echo  %COL%[90mНажмите любую клавишу для завершения...
pause >nul
exit