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
echo  Вопрос 3: Что вы хотите разблокировать через GoodbyeZapret?
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
echo  Вопросы закончились.
echo  Подождите пока я выполню установку...
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
echo Установка завершена.
echo.
echo.
echo Нажмите любую клавишу для автоматической настройки GoodbyeZapret...
pause >nul


cls
echo.
echo.
echo.
echo.
echo  Установка завершена.
echo  Давай попробуем настроить GoodbyeZapret.
echo.
echo.


if %ProviderQuastion%=="N" ( goto :Provider_Quastion_no )
if %ProviderQuastion%=="Y" ( goto :Provider_Quastion_yes )

REM если провайдера нет в списке
:Provider_Quastion_no
if %YT-Discord-Quastion%=="YT" (
    start "" "%SystemDrive%\GoodbyeZapret\Configs\YoutubeFix.bat"
    start https://youtube.com

    echo  Я Запустил тестовый конфиг и запустил Youtube.
    echo  Проверьте, что все работает.
    echo.
    echo Работает ли Youtube?
    echo.
    echo  %COL%[90m1^) Да%COL%[37m
    echo  %COL%[90m2^) Нет%COL%[37m
    echo.
    set /p choice="%DEL%        >: "

    if /i "%choice%"=="1" ( set "Working=Y" )
    if /i "%choice%"=="2" ( 
        start "" "%SystemDrive%\GoodbyeZapret\Configs\YoutubeFix_ALT.bat"
        start https://youtube.com
        cls
        echo.
        echo.
        echo.
        echo.
        echo  Я Запустил альтернативный конфиг и запустил Youtube.
        echo  Проверьте, что все работает.
        echo.
        echo Работает ли Youtube?
        echo.
        echo  %COL%[90m1^) Да%COL%[37m
        echo  %COL%[90m2^) Нет%COL%[37m
        echo.
        set /p choice="%DEL%        >: "
        
        if /i "%choice%"=="1" ( set "Working=Y" )
        if /i "%choice%"=="2" ( set "Working=N" )
    )
)


if %YT-Discord-Quastion%=="DS" (
    start "" "%SystemDrive%\GoodbyeZapret\Configs\DiscordFix.bat"
    start "" "C:\Users\%USERNAME%\AppData\Local\Discord\Update.exe" --processStart Discord.exe
    cls
    echo.
    echo.
    echo.
    echo.
    echo  Я Запустил тестовый конфиг и запустил Discord.
    echo  Проверьте, что все работает.
    echo.
    echo Работает ли Discord и Войсы в нем?
    echo.
    echo  %COL%[90m1^) Да%COL%[37m
    echo  %COL%[90m2^) Нет%COL%[37m
    echo.
    set /p choice="%DEL%        >: "

    if /i "%choice%"=="1" ( set "Working=Y" )
    if /i "%choice%"=="2" ( 
        start "" "%SystemDrive%\GoodbyeZapret\Configs\DiscordFix_ALT.bat"
        start "" "C:\Users\%USERNAME%\AppData\Local\Discord\Update.exe" --processStart Discord.exe
        cls
        echo.
        echo.
        echo.
        echo.
        echo  Я Запустил альтернативный конфиг и запустил Discord.
        echo  Проверьте, что все работает.
        echo.
        echo  А щас работает ли Discord и Войсы в нем?
        echo.
        echo  %COL%[90m1^) Да%COL%[37m
        echo  %COL%[90m2^) Нет%COL%[37m
        echo.
        set /p choice="%DEL%        >: "
        
        if /i "%choice%"=="1" ( set "Working=Y" )
        if /i "%choice%"=="2" ( set "Working=N" )
    )
)

if %YT-Discord-Quastion%=="YTDS" (
    start "" "%SystemDrive%\GoodbyeZapret\Configs\UltimateFix.bat"
    start https://youtube.com
    start "" "C:\Users\%USERNAME%\AppData\Local\Discord\Update.exe" --processStart Discord.exe
    cls
    echo.
    echo.
    echo.
    echo.
    echo  Я Запустил тестовый конфиг и запустил Youtube и Discord.
    echo  Проверьте, что все работает.
    echo.
    echo  Работает ли Youtube и Discord?
    echo.
    echo  %COL%[90m1^) Да%COL%[37m
    echo  %COL%[90m2^) Нет%COL%[37m
    echo.
    set /p choice="%DEL%        >: "

    if /i "%choice%"=="1" ( set "Working=Y" )
    if /i "%choice%"=="2" ( 
        start "" "%SystemDrive%\GoodbyeZapret\Configs\UltimateFix_ALT.bat"
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
        echo  А щас работает ли Youtube и Discord?
        echo.
        echo  %COL%[90m1^) Да%COL%[37m
        echo  %COL%[90m2^) Нет%COL%[37m
        echo.
        set /p choice="%DEL%        >: "
        
        if /i "%choice%"=="1" ( set "Working=Y" )
        if /i "%choice%"=="2" ( 
            start "" "%SystemDrive%\GoodbyeZapret\Configs\UltimateFix_ALT_2.bat"
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
            echo  Теперь работает ли Youtube и Discord?
            echo.
            echo  %COL%[90m1^) Да%COL%[37m
            echo  %COL%[90m2^) Нет%COL%[37m
            echo.
            set /p choice="%DEL%        >: "
            
            if /i "%choice%"=="1" ( set "Working=Y" )
            if /i "%choice%"=="2" ( set "Working=N" )
        )
    )
)

REM если провайдер есть в списке
:Provider_Quastion_yes
if %ProviderName%=="MGTS" (
    set "Discord=DiscordFix_MGTS.bat"
    set "Youtube=YoutubeFix_MGTS.bat"
    set "Ultimate=UltimateFix_MGTS.bat"
    set "UltimateALT=UltimateFix_ALT_MGTS.bat"
)

if %ProviderName%=="Beeline" (
    set "Discord=DiscordFix_Beeline-Rostelekom.bat"
    set "Youtube=YoutubeFix.bat"
    set "Ultimate=UltimateFix_Beeline-Rostelekom.bat"
    set "UltimateALT=UltimateFix_ALT_Beeline-Rostelekom.bat"
)

if %ProviderName%=="Rostelecom" (
    set "Discord=DiscordFix_Beeline-Rostelekom.bat"
    set "Youtube=YoutubeFix.bat"
    set "Ultimate=UltimateFix_Beeline-Rostelekom.bat"
    set "UltimateALT=UltimateFix_ALT_Beeline-Rostelekom.bat"
)



if %YT-Discord-Quastion%=="YT" (
    start "" "%SystemDrive%\GoodbyeZapret\Configs\%Youtube%"
    start https://youtube.com

    echo  Я Запустил тестовый конфиг и запустил Youtube.
    echo  Проверьте, что все работает.
    echo.
    echo Работает ли Youtube?
    echo.
    echo  %COL%[90m1^) Да%COL%[37m
    echo  %COL%[90m2^) Нет%COL%[37m
    echo.
    set /p choice="%DEL%        >: "

    if /i "%choice%"=="1" ( set "Working=Y" )
    if /i "%choice%"=="2" ( 
        start "" "%SystemDrive%\GoodbyeZapret\Configs\YoutubeFix.bat"
        start https://youtube.com
        cls
        echo.
        echo.
        echo.
        echo.
        echo  Я Запустил альтернативный конфиг и запустил Youtube.
        echo  Проверьте, что все работает.
        echo.
        echo Работает ли Youtube?
        echo.
        echo  %COL%[90m1^) Да%COL%[37m
        echo  %COL%[90m2^) Нет%COL%[37m
        echo.
        set /p choice="%DEL%        >: "
        
        if /i "%choice%"=="1" ( set "Working=Y" )
        if /i "%choice%"=="2" (
            start "" "%SystemDrive%\GoodbyeZapret\Configs\YoutubeFix_ALT.bat"
            start https://youtube.com
            cls
            echo.
            echo.
            echo.
            echo.
            echo  Я Запустил второй альтернативный конфиг и запустил Youtube.
            echo  Проверьте, что все работает.
            echo.
            echo Работает ли Youtube?
            echo.
            echo  %COL%[90m1^) Да%COL%[37m
            echo  %COL%[90m2^) Нет%COL%[37m
            echo.
            set /p choice="%DEL%        >: "
            
            if /i "%choice%"=="1" ( set "Working=Y" )
            if /i "%choice%"=="2" ( set "Working=N" )
        )
    )
)

if %YT-Discord-Quastion%=="DS" (
    start "" "%SystemDrive%\GoodbyeZapret\Configs\%Discord%"
    start "" "C:\Users\%USERNAME%\AppData\Local\Discord\Update.exe" --processStart Discord.exe
    cls
    echo.
    echo.
    echo.
    echo.
    echo  Я Запустил тестовый конфиг и запустил Discord.
    echo  Проверьте, что все работает.
    echo.
    echo Работает ли Discord и Войсы в нем?
    echo.
    echo  %COL%[90m1^) Да%COL%[37m
    echo  %COL%[90m2^) Нет%COL%[37m
    echo.
    set /p choice="%DEL%        >: "

    if /i "%choice%"=="1" ( set "Working=Y" )
    if /i "%choice%"=="2" ( 
        start "" "%SystemDrive%\GoodbyeZapret\Configs\DiscordFix.bat"
        start "" "C:\Users\%USERNAME%\AppData\Local\Discord\Update.exe" --processStart Discord.exe
        cls
        echo.
        echo.
        echo.
        echo.
        echo  Я Запустил альтернативный конфиг и запустил Discord.
        echo  Проверьте, что все работает.
        echo.
        echo  А щас работает ли Discord и Войсы в нем?
        echo.
        echo  %COL%[90m1^) Да%COL%[37m
        echo  %COL%[90m2^) Нет%COL%[37m
        echo.
        set /p choice="%DEL%        >: "
        
        if /i "%choice%"=="1" ( set "Working=Y" )
        if /i "%choice%"=="2" ( 
            start "" "%SystemDrive%\GoodbyeZapret\Configs\DiscordFix_ALT.bat"
            start "" "C:\Users\%USERNAME%\AppData\Local\Discord\Update.exe" --processStart Discord.exe
            cls
            echo.
            echo.
            echo.
            echo.
            echo  Я Запустил второй альтернативный конфиг и запустил Discord.
            echo  Проверьте, что все работает.
            echo.
            echo  А щас работает ли Discord и Войсы в нем?
            echo.
            echo  %COL%[90m1^) Да%COL%[37m
            echo  %COL%[90m2^) Нет%COL%[37m
            echo.
            set /p choice="%DEL%        >: "
            
            if /i "%choice%"=="1" ( set "Working=Y" )
            if /i "%choice%"=="2" ( set "Working=N" )
        )
    )
)

if %YT-Discord-Quastion%=="YTDS" (
    start "" "%SystemDrive%\GoodbyeZapret\Configs\%Ultimate%"
    start https://youtube.com
    start "" "C:\Users\%USERNAME%\AppData\Local\Discord\Update.exe" --processStart Discord.exe
    cls
    echo.
    echo.
    echo.
    echo.
    echo  Я Запустил тестовый конфиг и запустил Youtube и Discord.
    echo  Проверьте, что все работает.
    echo.
    echo  Работает ли Youtube и Discord?
    echo.
    echo  %COL%[90m1^) Да%COL%[37m
    echo  %COL%[90m2^) Нет%COL%[37m
    echo.
    set /p choice="%DEL%        >: "

    if /i "%choice%"=="1" ( set "Working=Y" )
    if /i "%choice%"=="2" ( 
        start "" "%SystemDrive%\GoodbyeZapret\Configs\%UltimateALT%"
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
        echo  А щас работает ли Youtube и Discord?
        echo.
        echo  %COL%[90m1^) Да%COL%[37m
        echo  %COL%[90m2^) Нет%COL%[37m
        echo.
        set /p choice="%DEL%        >: "
        
        if /i "%choice%"=="1" ( set "Working=Y" )
        if /i "%choice%"=="2" ( 
            start "" "%SystemDrive%\GoodbyeZapret\Configs\UltimateFix_ALT.bat"
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
            echo  Теперь работает ли Youtube и Discord?
            echo.
            echo  %COL%[90m1^) Да%COL%[37m
            echo  %COL%[90m2^) Нет%COL%[37m
            echo.
            set /p choice="%DEL%        >: "
            
            if /i "%choice%"=="1" ( set "Working=Y" )
            if /i "%choice%"=="2" ( 
                start "" "%SystemDrive%\GoodbyeZapret\Configs\UltimateFix_ALT_2.bat"
                start https://youtube.com
                start "" "C:\Users\%USERNAME%\AppData\Local\Discord\Update.exe" --processStart Discord.exe
                cls
                echo.
                echo.
                echo.
                echo.
                echo  Я Запустил последний альтернативный конфиг и запустил Youtube и Discord.
                echo  Проверьте, что все работает.
                echo.
                echo  Теперь работает ли Youtube и Discord?
                echo.
                echo  %COL%[90m1^) Да%COL%[37m
                echo  %COL%[90m2^) Нет%COL%[37m
                echo.
                set /p choice="%DEL%        >: "
                
                if /i "%choice%"=="1" ( set "Working=Y" )
                if /i "%choice%"=="2" ( set "Working=N" )
            )
        )
    )
)


if %Working%=="Y" (
    cls
    echo.
    echo.
    echo.
    echo.
    echo  Поздравляю! GoodbyeZapret настроен и работает.
    echo.
    echo  Если у вас возникли проблемы, пожалуйста, обратитесь к разработчику.
    echo.
    echo.
    echo  Нажмите любую клавишу для завершения...
    pause >nul
    exit
)