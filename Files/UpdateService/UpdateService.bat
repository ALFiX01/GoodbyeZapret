::[Bat To Exe Converter]
::
::YAwzoRdxOk+EWAjk
::fBw5plQjdCyDJGyX8VAjFD9VQg2LMFeeCaIS5Of66/m7hXciWO04d7DNiPqHI+9z
::YAwzuBVtJxjWCl3EqQJgSA==
::ZR4luwNxJguZRRnk
::Yhs/ulQjdF65
::cxAkpRVqdFKZSzk=
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

chcp 65001 >nul 2>&1
:: Запуск от имени администратора
reg add HKLM /F >nul 2>&1
if %errorlevel% neq 0 (
    start "" /wait /I /min powershell -NoProfile -Command "start -verb runas '%~s0'" && exit /b
    exit /b
)

setlocal EnableDelayedExpansion
for /f "usebackq delims=" %%a in ("%SystemDrive%\GoodbyeZapret\version.txt") do set "Current_GoodbyeZapret_version=%%a"
for /f "usebackq delims=" %%a in ("%SystemDrive%\GoodbyeZapret\bin\version.txt") do set "Current_Winws_version=%%a"
for /f "usebackq delims=" %%a in ("%SystemDrive%\GoodbyeZapret\lists\version.txt") do set "Current_List_version=%%a"


:: Загрузка нового файла Updater.bat
if exist "%TEMP%\GZ_Updater.bat" del /s /q /f "%TEMP%\GZ_Updater.bat" >nul 2>&1
curl -s -o "%TEMP%\GZ_Updater.bat" "https://raw.githubusercontent.com/ALFiX01/GoodbyeZapret/refs/heads/main/GoodbyeZapret_Version" 
if errorlevel 1 (
    echo ERROR - Ошибка связи с сервером проверки обновлений GoodbyeZapret
    
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


if %UpdateNeed% equ Yes (
    goto Update
) else (
    exit
)

:Update
set "UpdaterVersion=0.2"

REM Цветной текст
for /F "tokens=1,2 delims=#" %%a in ('"prompt #$H#$E# & echo on & for %%b in (1) do rem"') do (set "DEL=%%a" & set "COL=%%b")

echo.
echo Updater version: %UpdaterVersion%
echo.
timeout /t 3 >nul 2>&1
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



curl -g -L -# -o %TEMP%\GoodbyeZapret.zip "https://github.com/ALFiX01/GoodbyeZapret/raw/refs/heads/main/Files/GoodbyeZapret.zip" >nul 2>&1

for %%I in ("%TEMP%\GoodbyeZapret.zip") do set FileSize=%%~zI
if %FileSize% LSS 100 (
    echo ERROR - Файл %Check_FileName% поврежден или URL не доступен ^(Size %FileSize%^)
    pause
    del /Q "%TEMP%\GoodbyeZapret.zip"
    exit
)


if exist "%SystemDrive%\GoodbyeZapret" (
  rd /s /q "%SystemDrive%\GoodbyeZapret" >nul 2>&1
)

if exist "%TEMP%\GoodbyeZapret.zip" (
    chcp 850 >nul 2>&1
    powershell -NoProfile Expand-Archive '%TEMP%\GoodbyeZapret.zip' -DestinationPath '%SystemDrive%\GoodbyeZapret' >nul 2>&1
    chcp 65001 >nul 2>&1
) else (
    Echo Error: File not found: %TEMP%\GoodbyeZapret.zip
    timeout /t 5 >nul
    exit
)


sc create "GoodbyeZapret" binPath= "cmd.exe /c \"%SystemDrive%\GoodbyeZapret\Configs\%GoodbyeZapret_Config%.bat\"" start= auto
sc description GoodbyeZapret "%GoodbyeZapret_Config%" ) >nul 2>&1
sc start "GoodbyeZapret" >nul 2>&1
sc start "GoodbyeZapret" >nul 2>&1
if %errorlevel% equ 0 (
    echo Служба GoodbyeZapret успешно запущена %COL%[37m
) else (
    echo Возможно при запуске службы GoodbyeZapret произошла ошибка
)
start "" "%SystemDrive%\GoodbyeZapret\Launcher.bat"
echo готово
pause

