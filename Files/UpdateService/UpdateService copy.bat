::[Bat To Exe Converter]
::
::YAwzoRdxOk+EWAjk
::fBw5plQjdCuDJOlwRJyA8qq3/Ngy6dtnt1etA6hLN6o2QAOtgN4bfZzS3bqyB+8c7kf9cKwsxmhfjPcKDQ1RfR2lIAY3pg4=
::YAwzuBVtJxjWCl3EqQJgSA==
::ZR4luwNxJguZRRnk
::Yhs/ulQjdF+5
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

setlocal EnableDelayedExpansion

rem Resolve install root (parent of this script directory)
for /f "delims=" %%A in ('powershell -NoProfile -Command "(Get-Item '%~dp0').Parent.FullName"') do set "ParentDirPath=%%A"
set "LogFile=%ParentDirPath%\Log.txt"

chcp 65001 >nul 2>&1

rem Detect interactive run (hold window open if launched as .bat) and allow override via args
set "HOLD=0"
if /i "%~x0"==".bat" set "HOLD=1"
if /i "%~1"=="--hold" set "HOLD=1"
if /i "%~1"=="--no-hold" set "HOLD=0"

rem ---------------------------
rem Core settings
rem ---------------------------
set "MaxInternetAttempts=10"
set "CheckURL=https://ya.ru"
set "CheckURL_BACKUP=https://mail.ru"
if not defined CheckURL set "CheckURL=https://ya.ru"
if not defined CheckURL_BACKUP set "CheckURL_BACKUP=https://mail.ru"

rem ---------------------------
rem Helper: logging
rem ---------------------------



rem ---------------------------
rem Nice header (colors)
rem ---------------------------
for /F "tokens=1,2 delims=#" %%a in ('"prompt #$H#$E# & echo on & for %%b in (1) do rem"') do (set "DEL=%%a" & set "COL=%%b")

cls
title GoodbyeZapret UpdateService
call :log START "UpdateService / Path: %ParentDirPath%"
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
echo  %COL%[37m Добро пожаловать в программу обновления GoodbyeZapret
echo  %COL%[90m Для корректной работы рекомендуется отключить антивирус
echo  %COL%[37m ───────────────────── ПРОВЕРКА ОБНОВЛЕНИЯ ───────────────────── %COL%[90m
echo.

rem ---------------------------
rem Connectivity check with retry and fallback
rem ---------------------------
call :check_internet
if errorlevel 1 (
    echo  %COL%[91mОшибка: нет подключения к серверам обновлений%COL%[37m
    call :log ERROR "No connectivity to update servers"
    timeout /t 3 >nul 2>&1
    goto :finish_err
)

rem ---------------------------
rem Read current version from registry
rem ---------------------------
set "Current_GoodbyeZapret_version="
set "Current_GoodbyeZapret_version_code="
reg query "HKCU\Software\ALFiX inc.\GoodbyeZapret" /v "GoodbyeZapret_Version" >nul 2>&1 && (
  for /f "tokens=3" %%i in ('reg query "HKCU\Software\ALFiX inc.\GoodbyeZapret" /v "GoodbyeZapret_Version" ^| findstr /i "GoodbyeZapret_Version"') do set "Current_GoodbyeZapret_version=%%i"
)
reg query "HKCU\Software\ALFiX inc.\GoodbyeZapret" /v "GoodbyeZapret_Version_code" >nul 2>&1 && (
  for /f "tokens=3" %%i in ('reg query "HKCU\Software\ALFiX inc.\GoodbyeZapret" /v "GoodbyeZapret_Version_code" ^| findstr /i "GoodbyeZapret_Version_code"') do set "Current_GoodbyeZapret_version_code=%%i"
)

rem ---------------------------
rem Download and execute version descriptor (GZ_Updater.bat)
rem ---------------------------
if exist "%TEMP%\GZ_Updater.bat" del /q /f "%TEMP%\GZ_Updater.bat" >nul 2>&1
curl -4 -sS -L --fail --retry 3 --retry-delay 1 -o "%TEMP%\GZ_Updater.bat" "https://raw.githubusercontent.com/ALFiX01/GoodbyeZapret/refs/heads/main/GoodbyeZapret_Version"
if errorlevel 1 (
    echo  %COL%[91mОшибка: не удалось скачать файл версии%COL%[37m
    call :log ERROR "Failed to download GoodbyeZapret_Version"
    goto :finish_err
)

call "%TEMP%\GZ_Updater.bat" >nul 2>&1
if errorlevel 1 (
    echo  %COL%[91mОшибка: не удалось прочитать информацию об обновлении%COL%[37m
    call :log ERROR "Failed to execute GZ_Updater.bat"
    goto :finish_err
)

del /q "%TEMP%\GZ_Updater.bat" >nul 2>&1

rem Ensure Updater.exe exists (used later by Launcher)
if not exist "%ParentDirPath%\tools" md "%ParentDirPath%\tools" >nul 2>&1
if not exist "%ParentDirPath%\tools\Updater.exe" (
  curl -4 -sS -L --fail --retry 3 --retry-delay 1 -o "%ParentDirPath%\tools\Updater.exe" "https://github.com/ALFiX01/GoodbyeZapret/raw/refs/heads/main/Files/Updater/Updater.exe" >nul 2>&1
)

rem ---------------------------
rem Decide if update is needed
rem ---------------------------
set "UpdateNeed=No"

if defined Actual_GoodbyeZapret_version_code if defined Current_GoodbyeZapret_version_code (
    if /i not "%Actual_GoodbyeZapret_version_code%"=="%Current_GoodbyeZapret_version_code%" set "UpdateNeed=Yes"
) else (
    rem If we cannot compare codes, assume no update to avoid looping
    set "UpdateNeed=No"
)

if /i not "%UpdateNeed%"=="Yes" (
    echo  %COL%[92mОбновления не найдены%COL%[37m
    if exist "%LogFile%" del /f /q "%LogFile%" >nul 2>&1
    goto :finish_ok
)

call :log INFO "Update available: v%Current_GoodbyeZapret_version_code% -> v%Actual_GoodbyeZapret_version_code%"

rem ---------------------------
rem Elevate only when needed for service/replace operations
rem ---------------------------
net session >nul 2>&1
if errorlevel 1 (
    call :log INFO "Requesting administrative privileges"
    echo Requesting administrative privileges...
    start "" /wait /I /min powershell -NoProfile -Command "Start-Process -FilePath '%~s0' -Verb RunAs"
    exit /b
)

rem ---------------------------
rem Update flow UI
rem ---------------------------
cls
title GoodbyeZapret UpdateService
echo.
echo  %COL%[37m ───────────────────── ВЫПОЛНЯЕТСЯ ОБНОВЛЕНИЕ ───────────────────── %COL%[90m
echo.

rem Stop and clean services/processes
echo   ^[*^] Отключение текущего конфига GoodbyeZapret
sc query "GoodbyeZapret" >nul 2>&1 && net stop "GoodbyeZapret" >nul 2>&1
echo   ^[*^] Удаление службы GoodbyeZapret
sc query "GoodbyeZapret" >nul 2>&1 && sc delete "GoodbyeZapret" >nul 2>&1
echo   ^[*^] Остановка процессов/служб WinDivert
taskkill /F /IM winws.exe >nul 2>&1
for %%S in (WinDivert WinDivert14 monkey) do (
  sc query "%%S" >nul 2>&1 && (
    net stop "%%S" >nul 2>&1
    sc delete "%%S" >nul 2>&1
  )
)

taskkill /F /IM GoodbyeZapretTray.exe >nul 2>&1
if exist "%ParentDirPath%\tools\tray\GoodbyeZapretTray.exe" (
    schtasks /end /tn "GoodbyeZapretTray" >nul 2>&1
)

rem Remember preferred config name
set "GoodbyeZapret_Config=None"
reg query "HKCU\Software\ALFiX inc.\GoodbyeZapret" /v "GoodbyeZapret_Config" >nul 2>&1 && (
  for /f "tokens=2*" %%a in ('reg query "HKCU\Software\ALFiX inc.\GoodbyeZapret" /v "GoodbyeZapret_Config" 2^>nul ^| find /i "GoodbyeZapret_Config"') do set "GoodbyeZapret_Config=%%b"
)

call :log INFO "Downloading files for !Actual_GoodbyeZapret_version!"
echo   ^[*^] Скачивание файлов !Actual_GoodbyeZapret_version!
set "ZipPath=%TEMP%\GoodbyeZapret.zip"
if exist "%ZipPath%" del /q /f "%ZipPath%" >nul 2>&1

curl -4 -sS -L --fail --retry 3 --retry-delay 1 -o "%ZipPath%" "https://github.com/ALFiX01/GoodbyeZapret/raw/refs/heads/main/Files/GoodbyeZapret.zip" >nul 2>&1
if errorlevel 1 (
    echo  %COL%[91mОшибка: не удалось скачать GoodbyeZapret.zip%COL%[37m
    call :log ERROR "Failed to download GoodbyeZapret.zip"
    goto :finish_err
)

for %%I in ("%ZipPath%") do set "FileSize=%%~zI"
if not defined FileSize (
    echo  %COL%[91mОшибка: GoodbyeZapret.zip не найден или пустой%COL%[37m
    call :log ERROR "Downloaded zip missing or empty"
    goto :finish_err
)
if %FileSize% LSS 100 (
    echo  %COL%[91mОшибка: GoodbyeZapret.zip поврежден ^(Size %FileSize%^)%COL%[37m
    call :log ERROR "Zip too small (%FileSize% bytes)"
    del /q /f "%ZipPath%" >nul 2>&1
    goto :finish_err
)

call :log INFO "Extracting archive"
echo   ^[*^] Распаковка файлов
chcp 850 >nul 2>&1
powershell -NoProfile -Command "Expand-Archive -LiteralPath '%ZipPath%' -DestinationPath '%ParentDirPath%' -Force" >nul 2>&1
set "ps_err=%errorlevel%"
chcp 65001 >nul 2>&1
del /q /f "%ZipPath%" >nul 2>&1
if not "%ps_err%"=="0" (
    echo  %COL%[91mОшибка распаковки архива%COL%[37m
    call :log ERROR "Expand-Archive failed (code %ps_err%)"
    goto :finish_err
)

rem Restore service from stored config (if available)
call :restore_service

echo   ^[*^] Обновление завершено
call :log INFO "Update finished"
if exist "%ParentDirPath%\Launcher.bat" start "" "%ParentDirPath%\Launcher.bat"
timeout /t 1 >nul 2>&1
goto :finish_ok


:: -------------------------------------------------------
:: Functions
:: -------------------------------------------------------
:finish_ok
rem Cleanup accidental file like v08AV01 created by shell redirection quirks
set "FirstActual="
if defined Actual_GoodbyeZapret_version_code for /f "tokens=1" %%A in ("!Actual_GoodbyeZapret_version_code!") do set "FirstActual=%%A"
if defined FirstActual (
  if exist "v!FirstActual!" del /f /q "v!FirstActual!" >nul 2>&1
  if exist "%ParentDirPath%\tools\v!FirstActual!" del /f /q "%ParentDirPath%\tools\v!FirstActual!" >nul 2>&1
)
set "FirstCurrent="
if defined Current_GoodbyeZapret_version_code for /f "tokens=1" %%A in ("!Current_GoodbyeZapret_version_code!") do set "FirstCurrent=%%A"
if defined FirstCurrent (
  if exist "v!FirstCurrent!" del /f /q "v!FirstCurrent!" >nul 2>&1
  if exist "%ParentDirPath%\tools\v!FirstCurrent!" del /f /q "%ParentDirPath%\tools\v!FirstCurrent!" >nul 2>&1
)
if "%HOLD%"=="1" (
  echo.
  echo  %COL%[90mНажмите любую клавишу для выхода...%COL%[37m
  pause >nul
) else (
  rem short delay to avoid blinking window
  timeout /t 1 >nul 2>&1
)
exit /b 0

:finish_err
rem Cleanup accidental file like v08AV01 created by shell redirection quirks
set "FirstActual="
if defined Actual_GoodbyeZapret_version_code for /f "tokens=1" %%A in ("!Actual_GoodbyeZapret_version_code!") do set "FirstActual=%%A"
if defined FirstActual (
  if exist "v!FirstActual!" del /f /q "v!FirstActual!" >nul 2>&1
  if exist "%ParentDirPath%\v!FirstActual!" del /f /q "%ParentDirPath%\v!FirstActual!" >nul 2>&1
)
set "FirstCurrent="
if defined Current_GoodbyeZapret_version_code for /f "tokens=1" %%A in ("!Current_GoodbyeZapret_version_code!") do set "FirstCurrent=%%A"
if defined FirstCurrent (
  if exist "v!FirstCurrent!" del /f /q "v!FirstCurrent!" >nul 2>&1
  if exist "%ParentDirPath%\v!FirstCurrent!" del /f /q "%ParentDirPath%\v!FirstCurrent!" >nul 2>&1
)
if "%HOLD%"=="1" (
  echo.
  echo  %COL%[91mПроизошла ошибка. Нажмите любую клавишу для выхода...%COL%[37m
  pause >nul
) else (
  timeout /t 3 >nul 2>&1
)
exit /b 1

:check_internet
setlocal EnableDelayedExpansion
set "attempt=0"
echo   Checking connectivity to update server ^(%CheckURL%^)...
:_try
set /a attempt+=1
curl -4 -sS -L -I --fail --connect-timeout 3 --max-time 4 -o nul "%CheckURL%"
if !errorlevel! equ 0 (
    echo   Connection successful.
    endlocal & exit /b 0
)
echo   Primary unreachable, trying backup ^(%CheckURL_BACKUP%^)...
curl -4 -sS -L -I --fail --connect-timeout 3 --max-time 4 -o nul "%CheckURL_BACKUP%"
if !errorlevel! equ 0 (
    echo   Connection successful via backup URL.
    endlocal & exit /b 0
)
echo   Error 02: Cannot reach update servers. Attempt: !attempt!/%MaxInternetAttempts%
if !attempt! geq %MaxInternetAttempts% (
    endlocal & exit /b 1
)
timeout /t 2 >nul
goto _try


:restore_service
setlocal EnableDelayedExpansion
set "cfg=%GoodbyeZapret_Config%"
if /i "!cfg!"=="None" goto _try_last

set "batPath="
if exist "%ParentDirPath%\configs\Preset\!cfg!.bat" set "batPath=Preset"
if exist "%ParentDirPath%\configs\Custom\!cfg!.bat" set "batPath=Custom"
if exist "%ParentDirPath%\configs\!cfg!.bat" set "batPath="

if defined batPath if exist "%ParentDirPath%\configs\!batPath!\!cfg!.bat" (
    sc create "GoodbyeZapret" binPath= "cmd.exe /c \"\"%ParentDirPath%\configs\!batPath!\!cfg!.bat\"\"" >nul 2>&1
    sc config "GoodbyeZapret" start= auto >nul 2>&1
      if exist "%ParentDirPath%\tools\tray\GoodbyeZapretTray.exe" (
        schtasks /run /tn "GoodbyeZapretTray" >nul 2>&1
      )
    sc description GoodbyeZapret "!cfg!" >nul 2>&1
    sc start "GoodbyeZapret" >nul 2>&1
    if !errorlevel! equ 0 echo   ^[*^] Служба GoodbyeZapret успешно запущена
    endlocal & exit /b 0
)

:_try_last
rem Резервный вариант: попробуйте последнюю запущенную конфигурацию
for /f "tokens=2*" %%a in ('reg query "HKCU\Software\ALFiX inc.\GoodbyeZapret" /v "GoodbyeZapret_LastStartConfig" 2^>nul ^| find /i "GoodbyeZapret_LastStartConfig"') do set "LastStart=%%b"
if not defined LastStart endlocal & exit /b 0

set "cfgName=!LastStart!"
set "maybeExt=!cfgName:~-4!"
if /i "!maybeExt!"==".bat" (
    set "cfgFile=!cfgName!"
) else (
    set "cfgFile=!cfgName!.bat"
)
set "foundPath="
if exist "%ParentDirPath%\configs\Preset\!cfgFile!" set "foundPath=%ParentDirPath%\configs\Preset\!cfgFile!"
if not defined foundPath if exist "%ParentDirPath%\configs\Custom\!cfgFile!" set "foundPath=%ParentDirPath%\configs\Custom\!cfgFile!"
if not defined foundPath if exist "%ParentDirPath%\configs\!cfgFile!" set "foundPath=%ParentDirPath%\configs\!cfgFile!"
if defined foundPath start "" "!foundPath!"
endlocal & exit /b 0

:_noop
exit /b 0

:log
set "_lvl=%~1"
shift
set "_msg=%*"
rem Sanitize special redirection/control characters to avoid accidental file creation
set "_msg=!_msg:^>=^>!"
set "_msg=!_msg:^<=^<!"
set "_msg=!_msg:^|=^|!"
set "_msg=!_msg:&=^&!"
set "_msg=!_msg:(=^(!"
set "_msg=!_msg:)=^)!"
if /i "!_lvl!"=="START" (
  >> "%LogFile%" echo.
  >> "%LogFile%" echo ======================================================================
  >> "%LogFile%" echo [START] %date% %time:~0,8% - !_msg!
  >> "%LogFile%" echo ======================================================================
  exit /b 0
)
>> "%LogFile%" echo [!_lvl!] %time:~0,8% - !_msg!
exit /b 0