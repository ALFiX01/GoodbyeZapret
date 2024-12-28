::[Bat To Exe Converter]
::
::YAwzoRdxOk+EWAjk
::fBw5plQjdCuDJOl7RaKA9quH/eQy7NtmtmmtA9RLEVpWEpCtilLtyFVrAoivE9hTwlDmSZ8u2XRmj9kJAhhQMxOlakInqnxHoWCXPtGZoUHoSUfp
::YAwzuBVtJxjWCl3EqQJgSA==
::ZR4luwNxJguZRRnk
::Yhs/ulQjdF65
::cxAkpRVqdFKZSDk=
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
::Zh4grVQjdCyDJGyX8VAjFD9VQg2LMFeeCbYJ5e31+/m7hUQJfPc9RKjU1bCMOeUp61X2cIIR5mhVks4PGCdRcAG/bwM45GNDpXCAJYmZqwqB
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

mode con: cols=120 lines=40 >nul 2>&1

REM Цветной текст
for /F "tokens=1,2 delims=#" %%a in ('"prompt #$H#$E# & echo on & for %%b in (1) do rem"') do (set "DEL=%%a" & set "COL=%%b")

chcp 65001 >nul 2>&1


cls
title ALFiX, Inc. - Установка программного обеспечения
echo.
echo.
echo.
echo.
echo  Вас приветствует установщик программного обеспечения от ALFiX, Inc.
echo  Вам будет нужно ответить на несколько вопросов, чтобы установить и настроить программное обеспечение.
echo.
echo  %COL%[90mНажмите любую клавишу для продолжения...%COL%[37m
pause >nul

cls
echo.
echo.
echo.
echo.
echo  Вопрос 1: Какой у вас провайдер?
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
echo  Вопрос 2: Хотите ли вы чтобы GoodbyeZapret автоматически обновлялся?
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
echo  Вопрос 3: Хотите ли вы чтобы GoodbyeZapret запускался при запуске системы?
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
echo  Вопрос 4: Что вы хотите разблокировать через GoodbyeZapret?
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
