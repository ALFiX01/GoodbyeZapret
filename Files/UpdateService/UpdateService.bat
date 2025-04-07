::[Bat To Exe Converter]
::
::YAwzoRdxOk+EWAnk
::fBw5plQjdG8=
::YAwzuBVtJxjWCl3EqQJgSA==
::ZR4luwNxJguZRRnk
::Yhs/ulQjdF+5
::cxAkpRVqdFKZSTk=
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
::[Bat To Exe Converter]
::
::YAwzoRdxOk+EWAnk
::fBw5plQjdG8=
::YAwzuBVtJxjWCl3EqQJgSA==
::ZR4luwNxJguZRRnk
::Yhs/ulQjdF+5
::cxAkpRVqdFKZSTk=
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


set "WiFi=Off"
set "CheckURL=https://raw.githubusercontent.com"

:: Используем curl для проверки доступности основного хоста обновлений
:: -s: Silent mode (без прогресс-бара)
:: -L: Следовать редиректам
:: --head: Получить только заголовки (быстрее, меньше данных)
:: -m 10: Таймаут 10 секунд
:: -o NUL: Отправить тело ответа в никуда (нам нужен только код возврата)
curl -s -L --head -m 10 -o NUL "%CheckURL%"
echo start >> "C:\GoodbyeZapret\test.txt"
IF %ERRORLEVEL% EQU 0 (
    REM Успешно, сервер доступен
    set "WiFi=On"
) ELSE (
    REM Первая попытка не удалась, пробуем еще раз
    timeout /t 10 >nul
    curl -s -L --head -m 10 -o NUL "%CheckURL%"
    IF %ERRORLEVEL% EQU 0 (
        REM Успешно со второй попытки
        set "WiFi=On"
    ) ELSE (
        REM Вторая попытка не удалась, пробуем в третий раз
        timeout /t 8 >nul
        curl -s -L --head -m 10 -o NUL "%CheckURL%"
        IF %ERRORLEVEL% EQU 0 (
            REM Успешно с третьей попытки
            set "WiFi=On"
        ) ELSE (
            echo stop >> "C:\GoodbyeZapret\test2.txt"
            REM Все три попытки не удались
            set "WiFi=Off"
            exit /b
        )
    )
)

REM Получение информации о текущих версиях GoodbyeZapret и тд
for /f "usebackq delims=" %%a in ("%SystemDrive%\GoodbyeZapret\bin\version.txt") do set "Current_Winws_version=%%a"
for /f "usebackq delims=" %%a in ("%SystemDrive%\GoodbyeZapret\lists\version.txt") do set "Current_List_version=%%a"

reg query "HKEY_CURRENT_USER\Software\ALFiX inc.\GoodbyeZapret" /v "GoodbyeZapret_Version" >nul 2>&1
if %errorlevel% neq 0 (
    set "Current_GoodbyeZapret_version=0.0.0"
) else (
    for /f "tokens=3" %%i in ('reg query "HKEY_CURRENT_USER\Software\ALFiX inc.\GoodbyeZapret" /v "GoodbyeZapret_Version" ^| findstr /i "GoodbyeZapret_Version"') do set "Current_GoodbyeZapret_version=%%i"
)


set "GITHUB_RELEASE_URL=https://github.com/Flowseal/zapret-discord-youtube/releases/tag/"
set "GITHUB_DOWNLOAD_URL=https://github.com/Flowseal/zapret-discord-youtube/releases/latest/download/zapret-discord-youtube-"

:: Загрузка нового файла Updater.bat
if exist "%TEMP%\GoodbyeZapret_Updater.bat" del /s /q /f "%TEMP%\GZ_Updater.bat" >nul 2>&1
curl -s -o "%TEMP%\GoodbyeZapret_Updater.bat" "https://raw.githubusercontent.com/ALFiX01/GoodbyeZapret/refs/heads/main/GoodbyeZapret_Version" 
if errorlevel 1 (
    echo ERROR 1
    
)

:: Выполнение загруженного файла GoodbyeZapret_Updater.bat
call "%TEMP%\GoodbyeZapret_Updater.bat" >nul 2>&1
if errorlevel 1 (
    echo ERROR 2
)

set "UpdateNeed=None"
if !Current_GoodbyeZapret_version! neq !Actual_GoodbyeZapret_version! (
    set "UpdateNeed=Yes"
)
if !Current_Winws_version! neq !Actual_Winws_version! (
    set "UpdateNeed=Yes"
)
if !Current_List_version! neq !Actual_List_version! (
    set "UpdateNeed=Yes"
)
REM echo %UpdateNeed% %Current_GoodbyeZapret_version%
REM pause

if %UpdateNeed% equ Yes (
    if not exist "%SystemDrive%\GoodbyeZapret\Updater.exe" (
        curl -g -L -# -o "%SystemDrive%\GoodbyeZapret\Updater.exe" "https://github.com/ALFiX01/GoodbyeZapret/raw/refs/heads/main/Files/Updater/Updater.exe" >nul 2>&1
        start "" "%SystemDrive%\GoodbyeZapret\Updater.exe"
    ) else (
        start "" "%SystemDrive%\GoodbyeZapret\Updater.exe"
    )
) else (
    endlocal
    exit
)
