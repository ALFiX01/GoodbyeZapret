@echo off

chcp 65001 >nul 2>&1
:: Запуск от имени администратора
reg add HKLM /F >nul 2>&1
if %errorlevel% neq 0 (
    start "" /wait /I /min powershell -NoProfile -Command "start -verb runas '%~s0'" && exit /b
    exit /b
)

timeout /t 4 >nul 2>&1
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

curl -g -L -# -o %TEMP%\GoodbyeZapret.zip "https://github.com/ALFiX01/GoodbyeZapret/raw/refs/heads/main/Project/GoodbyeZapret.zip" >nul 2>&1

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

