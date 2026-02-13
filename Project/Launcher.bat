@echo off
cd /d "%~dp0" >nul 2>&1
:: Copyright (C) 2025 ALFiX, Inc.
:: Any tampering with the program code is forbidden (Запрещены любые вмешательства)

:: Запуск от имени админа
if not "%1"=="am_admin" (
    powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -WorkingDirectory '%~dp0' -Verb RunAs -ArgumentList 'am_admin'" & exit /b
)

:: Получаем путь к родительской папке и проверяем на пробелы
for /f "delims=" %%A in ('powershell -NoProfile -Command "Split-Path -Parent \"%~f0\""') do set "ParentDirPathForCheck=%%A"

:: Извлекаем имя папки и проверяем на пробелы
for %%A in ("%ParentDirPathForCheck%") do set "FolderName=%%~nxA"

:: Проверка на пробелы
set "tempvar=%FolderName%"
echo."%tempvar%"| findstr /c:" " >nul && (
    cls
    echo.
    echo  WARN: The folder name contains spaces.
    echo.
    pause
    exit /b
)

:: Включаем для манипуляции переменными
setlocal EnableDelayedExpansion

set "ErrorCount=0"

:: --- Определяем архитектуру системы
set "os_arch="
if /I "%PROCESSOR_ARCHITECTURE%"=="AMD64" set "os_arch=64"
if /I "%PROCESSOR_ARCHITECTURE%"=="ARM64" set "os_arch=64"
if /I "%PROCESSOR_ARCHITECTURE%"=="x86"   set "os_arch=32"
if defined PROCESSOR_ARCHITEW6432 set "os_arch=64"

if not defined os_arch (
    echo Unsupported CPU architecture: %PROCESSOR_ARCHITECTURE%
    pause > nul
    exit /b 1
)

if %os_arch%==32 (
    color f2
    echo Windows x86 detected. Nothing to do.
    echo Press any key for exit
    pause > nul
    exit /b
)

:: Получаем путь к родительской папке
for /f "delims=" %%A in ('powershell -NoProfile -Command "Split-Path -Parent '%~f0'"') do set "ParentDirPath=%%A"


:: Version information Stable Beta Alpha
set "Current_GoodbyeZapret_version=3.4.0"
set "Current_GoodbyeZapret_version_code=13F01"
set "branch=Stable"
set "beta_code=0"

chcp 65001 >nul 2>&1

:: Инициализируем конфигурационный файл
if not exist "%USERPROFILE%\AppData\Roaming\GoodbyeZapret" md "%USERPROFILE%\AppData\Roaming\GoodbyeZapret"
set "CONFIG_FILE=%USERPROFILE%\AppData\Roaming\GoodbyeZapret\config.txt"

if not exist "%CONFIG_FILE%" call :InitConfigFromRegistry

REM Читаем значение текущего конфига из config.txt
set "GoodbyeZapret_Config="
call :ReadConfig GoodbyeZapret_Config
if "%GoodbyeZapret_Config%"=="NotFound" (
    REM Если переменная не найдена, установите значение по умолчанию
    set "GoodbyeZapret_Config=Не выбран"
)

call :ui_header

REM Проверка и изменение шрифта консоли
for /f "tokens=2*" %%A in ('reg query "HKEY_CURRENT_USER\Console" /v "FaceName" 2^>nul ^| findstr /i "FaceName"') do (
    set "CurrentFont=%%B"
)

if /i not "%CurrentFont%"=="__DefaultTTFont__" (
    reg add "HKEY_CURRENT_USER\Console" /v "FaceName" /t REG_SZ /d "__DefaultTTFont__" /f >nul 2>&1
    if errorlevel 1 (
        call :ui_err "Ошибка при изменении шрифта консоли"
    ) else (
        call :ui_info "Шрифт консоли изменен с %CurrentFont% на __DefaultTTFont__"
        timeout /t 2 >nul
        start "" /d "%ParentDirPath%" "%ParentDirPath%\launcher.bat"
        exit /b
    )
)


REM Проверка, выполнялась ли настройка ранее

call :ReadConfig FirstLaunch
if "%FirstLaunch%"=="NotFound" (
    REM Если переменная не найдена, установите значение по умолчанию
    set "FirstLaunch=1"
)

if "%FirstLaunch%"=="0" (
    goto :skip_checks
)

call :ui_info "Первый запуск, выполняю проверку и настройку..."

REM /// UAC Settings ///
set "L_ConsentPromptBehaviorAdmin=0"
set "L_ConsentPromptBehaviorUser=3"
set "L_EnableInstallerDetection=1"
set "L_EnableLUA=1"
set "L_EnableSecureUIAPaths=1"
set "L_FilterAdministratorToken=0"
set "L_PromptOnSecureDesktop=0"
set "L_ValidateAdminCodeSignatures=0"

REM === Код проверки и исправления UAC параметров ===
REM UAC registry path
set "UAC_HKLM=HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"

REM Главный цикл для проверки и обновления значений UAC
set "UAC_check=Success"
for %%i in (
    ConsentPromptBehaviorAdmin
    ConsentPromptBehaviorUser
    EnableInstallerDetection
    EnableLUA
    EnableSecureUIAPaths
    FilterAdministratorToken
    PromptOnSecureDesktop
    ValidateAdminCodeSignatures
) do (
    REM Check if key exists before reading
    reg query "%UAC_HKLM%" /v "%%i" >nul 2>&1
    if !errorlevel! equ 0 (
        for /f "tokens=3" %%a in ('reg query "%UAC_HKLM%" /v "%%i" 2^>nul ^| find /i "%%i"') do (
            REM Удаляем префикс "0x" из текущего значения
            set "current_value=%%a"
            set "current_value=!current_value:0x=!"

            REM Получаем ожидаемое значение
            call set "expected_value=%%L_%%i%%"

            REM Сравниваем значения
            if not "!current_value!" == "!expected_value!" (
                call :ui_warn "UAC parameter '%%i' has unexpected value. Current: 0x!current_value!, Expected: 0x!expected_value!."
                reg add "%UAC_HKLM%" /v "%%i" /t REG_DWORD /d !expected_value! /f >nul 2>&1
                if !errorlevel! equ 1 (
                    call :ui_err "Failed to change UAC parameter '%%i'. Possibly insufficient privileges."
                    set "UAC_check=Error"
                ) else (
                    call :ui_info "UAC parameter '%%i' successfully changed to 0x!expected_value!."
                )
            )
        )
    ) else (
        REM Ключ не существует, создаем его
        call set "expected_value=%%L_%%i%%"
        reg add "%UAC_HKLM%" /v "%%i" /t REG_DWORD /d !expected_value! /f >nul 2>&1
        if !errorlevel! equ 1 (
            call :ui_err "Failed to create UAC parameter '%%i'. Possibly insufficient privileges."
            set "UAC_check=Error"
        ) else (
            call :ui_info "UAC parameter '%%i' successfully created with value 0x!expected_value!."
        )
    )
)

REM Отключение "предупреждения системы безопасности"
set "ExpectedSaveZone=1"
set "CurrentSaveZone="
for /f "tokens=3" %%a in ('reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Attachments" /v SaveZoneInformation 2^>nul ^| find /i "SaveZoneInformation"') do (
    set "CurrentSaveZone=%%a"
)
if not defined CurrentSaveZone (
    reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Attachments" /v SaveZoneInformation /t REG_DWORD /d %ExpectedSaveZone% /f >nul 2>&1
    if errorlevel 1 (
        call :ui_err "Error installing SaveZoneInformation"
        timeout /t 2 >nul
    )
) else (
    set "CurrentSaveZone=!CurrentSaveZone:0x=!"
    if /i not "!CurrentSaveZone!"=="%ExpectedSaveZone%" (
        reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Attachments" /v SaveZoneInformation /t REG_DWORD /d %ExpectedSaveZone% /f >nul 2>&1
        if errorlevel 1 (
            call :ui_err "Error updating SaveZoneInformation"
            timeout /t 2 >nul
        )
    )
)
set "CurrentSaveZone="


REM /// Предупреждения при запуске любых exe ///
REM === Проверка и установка DisableSecuritySettingsCheck ===
reg query "HKLM\SOFTWARE\Microsoft\Internet Explorer\Security" /v "DisableSecuritySettingsCheck" 2>nul | find "0x1" >nul
if errorlevel 1 (
    reg add "HKLM\SOFTWARE\Microsoft\Internet Explorer\Security" /f /v "DisableSecuritySettingsCheck" /t REG_DWORD /d 1 >nul 2>&1
)

REM === Проверка и установка LowRiskFileTypes ===
set "ExpectedLowRisk=.exe;.reg;.bat;.vbs;.cmd;.ps1;.zip;.rar;.msi;.msu;.lnk;.7z;.tar.gz;.doc;.docx;.pdf;"

rem Правильное чтение значения реестра с tokens=2*
for /f "skip=2 tokens=2*" %%i in ('reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Associations" /v "LowRiskFileTypes" 2^>nul') do set "CurrentLowRisk=%%j"

if not defined CurrentLowRisk (
    echo [INFO ] %TIME% - Setting LowRiskFileTypes=%ExpectedLowRisk%
    reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Associations" /v LowRiskFileTypes /t REG_SZ /d "%ExpectedLowRisk%" /f >nul 2>&1
) else (
    if /i not "%CurrentLowRisk%"=="%ExpectedLowRisk%" (
        echo [INFO ] %TIME% - Updating LowRiskFileTypes from "%CurrentLowRisk%" to "%ExpectedLowRisk%"
        reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Associations" /v LowRiskFileTypes /t REG_SZ /d "%ExpectedLowRisk%" /f >nul 2>&1
    )
)
set "CurrentLowRisk="

REM === Проверка и установка параметра 1806 в зоне 3 ===
reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings\Zones\3" /v "1806" 2>nul | find "0x0" >nul
if errorlevel 1 (
    echo [INFO ] %TIME% - Setting parameter 1806=0 in zone 3
    reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings\Zones\3" /f /v "1806" /t REG_DWORD /d 0 >nul 2>&1
)
REM ///

REM Проверяем результат выполнения
if "!UAC_check!" == "Error" (
    call :ui_warn "Некоторые параметры UAC не удалось настроить правильно."
)

REM TESTING

call :ReadConfig WinVer

rem 2) Если ключ отсутствует — записать текущую версию
if "%WinVer%"=="NotFound" (
    chcp 850 >nul 2>&1
    for /f "usebackq delims=" %%a in (`powershell -Command "(Get-CimInstance Win32_OperatingSystem).Caption"`) do (
        chcp 65001 >nul 2>&1
        set "WinVersion=%%a"

        REM Проверяем, является ли система Windows 11
        echo !WinVersion! | find /i "11" >nul
        if not errorlevel 1 (
            set "WinVer=11"
            call :WriteConfig WinVer "11"
            echo Set Win Version - 11
        ) else (
            REM Проверяем, является ли система Windows 10
            echo !WinVersion! | find /i "10" >nul
            if not errorlevel 1 (
                set "WinVer=10"
                call :WriteConfig WinVer "10"
                echo Set Win Version - 10
            )
        )
    )
)

REM По завершению создаём метку в реестре
call :WriteConfig FirstLaunch 0
REM reg add "HKCU\Software\ALFiX inc.\GoodbyeZapret" /v "FirstLaunch" /t REG_SZ /d "0" /f >nul 2>&1


REM /// Language ///
:: Получение информации о текущем языке интерфейса и выход, если язык не ru-RU
for /f "tokens=3" %%i in ('reg query "HKCU\Control Panel\International" /v "LocaleName" ^| findstr /i "LocaleName"') do set "WinLang=%%i"
if /I "%WinLang%" NEQ "ru-Ru" (
    cls
    echo.
    echo   Error 01: Invalid Windows interface language. GoodbyeZapret may encounter problems.
    echo.
    echo   Required: ru-RU
    echo   Current:  %WinLang%
    timeout /t 5 >nul
    call :ui_header
)

:skip_checks

REM /// GoodbyeZapret Version ///
rem 1) Прочитать текущую версию из config.txt
call :ReadConfig GoodbyeZapret_Version

rem 2) Если ключ отсутствует — записать текущую версию
if "%GoodbyeZapret_Version%"=="NotFound" (
    call :WriteConfig GoodbyeZapret_Version "%Current_GoodbyeZapret_version%"
) else (
    rem 3) Если отличается — обновить версию в config.txt
    if /i not "%GoodbyeZapret_Version%"=="%Current_GoodbyeZapret_version%" (
        call :WriteConfig GoodbyeZapret_Version "%Current_GoodbyeZapret_version%"
    )
)


rem /// GoodbyeZapret_Version_code — новый метод через config ///

rem 1) Прочитать текущее значение из config.txt
call :ReadConfig GoodbyeZapret_Version_code

set "UPDATED="
rem 2) Если ключ отсутствует — записать текущий код версии
if "%GoodbyeZapret_Version_code%"=="NotFound" (
    call :WriteConfig GoodbyeZapret_Version_code "%Current_GoodbyeZapret_version_code%"
    set "UPDATED=1"
) else (
    rem 3) Если отличается — обновить значение в config.txt
    if /i not "%GoodbyeZapret_Version_code%"=="%Current_GoodbyeZapret_version_code%" (
        rem call :ui_info "Выполняется обновление компонентов. Пожалуйста, подождите..."
        call :WriteConfig GoodbyeZapret_Version_code "%Current_GoodbyeZapret_version_code%"
        if not defined UPDATED set "UPDATED=1"
        rem call :ui_ok "Обновление компонентов завершено."
    )
)

rem 4) Действия после обновления (по аналогии с веткой реестра)
if defined UPDATED (
    if not exist "%ParentDirPath%\tools" mkdir "%ParentDirPath%\tools" >nul 2>&1
)


set "WiFi=Off"
set "CheckURL=https://raw.githubusercontent.com"
set "CheckURL_BACKUP=https://mail.ru"
set "DNS_TEST=google.com"

REM --- Combined DNS and internet connectivity check ---
call :ui_info "Проверка DNS и подключения к интернету..."

REM First check DNS resolution
nslookup %DNS_TEST% >nul 2>&1
if errorlevel 1 (
    echo.
    call :ui_err "Ошибка 02: DNS не отвечает или отсутствует доступ к интернету"
    echo   Проверьте подключение и настройки сети.
    set "WiFi=Off"
)

REM --- Если DNS работает, проверяем основной сервер ---

if not defined CURL (
if exist "%ParentDirPath%\tools\curl\curl.exe" (
    set CURL="%ParentDirPath%\tools\curl\curl.exe"
) else (
    set "CURL=curl"
    )
)

call :ui_info "DNS работает. Проверка сервера обновлений (%CheckURL%)..."
%CURL% -4 -s -I --fail --connect-timeout 1 --max-time 1 -o nul "%CheckURL%"
IF %ERRORLEVEL% EQU 0 (
    call :ui_ok "Соединение установлено. Перехожу далее"
    set "UpdaterServerConnect=Yes"
    set "WiFi=On"
) ELSE (
    call :ui_warn "Сервер обновлений недоступен. Проверка общего подключения (%CheckURL_BACKUP%)..."
    %CURL% -4 -s -I --fail --connect-timeout 1 --max-time 2 -o nul "%CheckURL_BACKUP%"
    IF %ERRORLEVEL% EQU 0 (
        call :ui_ok "Интернет доступен"
        call :ui_warn "Но сервер обновлений недоступен (%CheckURL%)"
        set "WiFi=On"
    ) ELSE (
        echo.
        call :ui_err "Ошибка 03: нет доступа к интернету"
        echo   Проверьте подключение и настройки сети.
        set "WiFi=Off"
    )
)

call :ui_info "Выполняю необходимые проверки..."

if not exist "%ParentDirPath%" (
    goto install_screen
)

:RR

REM call :timer_start

REM Инициализируем переменные
set "BatCount=0"
set "sourcePath=%~dp0"

REM --- Запускаем проверку статуса перед изменением размера окна ---
REM set "SilentMode=1"
REM call :CurrentStatus
REM set "SilentMode="
REM ------------------------------------------------------------

set "TotalCheck=Ok"

REM Инициализируем коды цветов
for /F "tokens=1,2 delims=#" %%a in ('"prompt #$H#$E# & echo on & for %%b in (1) do rem"') do (set "DEL=%%a" & set "COL=%%b")

REM Устанавливаем кодировку UTF-8
chcp 65001 >nul 2>&1

REM === UI helpers: цвета, символы, заголовок ===
goto :UI_HELPERS_END

:ui_init
    if defined ESC exit /b
    if defined COL (set "ESC=%COL%") else (
        for /F "tokens=1,2 delims=#" %%a in ('"prompt #$H#$E# & echo on & for %%b in (1) do rem"') do (set "DEL=%%a" & set "ESC=%%b")
    )
    REM Получаем сохраненную версию Windows из config
    call :ReadConfig "WinVer"
    set "C_RESET=%ESC%[0m"
    set "C_DIM=%ESC%[90m"
    set "C_INFO=%ESC%[36m"
    set "C_OK=%ESC%[32m"
    set "C_WARN=%ESC%[33m"
    set "C_ERR=%ESC%[31m"
    set "C_TITLE=%ESC%[96m"
    set "C_PRIMARY=%ESC%[94m"
    if "%WinVer%"=="11" (
        set "S_OK=✔"
    ) else (
        set "S_OK=√"  
    )
    set "S_WARN=▲"
    set "S_ERR=✖"
    set "S_INFO=●"
    goto :eof

:ui_info
    call :ui_init
    set "msg=%~1"
    echo  %C_INFO%[ %S_INFO% ]%C_RESET% !msg!
    endlocal & goto :eof

:ui_ok
    call :ui_init
    set "msg=%~1"
    echo  %C_OK%[ %S_OK% ]%C_RESET% !msg!
    endlocal & goto :eof

:ui_warn
    call :ui_init
    set "msg=%~1"
    echo  %C_WARN%[ %S_WARN% ]%C_RESET% !msg!
    endlocal & goto :eof

:ui_err
    call :ui_init
    set "msg=%~1"
    echo  %C_ERR%[ %S_ERR% ]%C_RESET% !msg!
    endlocal & goto :eof

:ui_hr
    call :ui_init

    chcp 850 >nul 2>&1
    for /f "usebackq tokens=*" %%L in (`powershell -NoProfile -Command "$Host.UI.RawUI.WindowSize.Width"`) do set "W=%%L"
    chcp 65001 >nul 2>&1
    set "line="
    for /l %%i in (1,1,!W!) do set "line=!line!─"
    echo %C_DIM%!line!%C_RESET%
    endlocal & goto :eof

    :ui_header
    call :ui_init
    setlocal EnableDelayedExpansion
    cls
    if not defined Current_GoodbyeZapret_version ( set "Current_GoodbyeZapret_version=ERROR" )
    if not defined Current_GoodbyeZapret_version_code ( set "Current_GoodbyeZapret_version_code=ERROR" )
    if not defined branch ( set "branch=ERROR" )
    if not defined beta_code ( set "beta_code=ERROR" )
    call :ui_hr
    echo                          %C_RESET%______                ____            _____                         __ 
    echo                         / ____/___  ____  ____/ / /_  __  ____/__  /  ____ _____  ________  / /_
    echo                        / / __/ __ \/ __ \/ __  / __ \/ / / / _ \/ /  / __ `/ __ \/ ___/ _ \/ __/
    echo                       / /_/ / /_/ / /_/ / /_/ / /_/ / /_/ /  __/ /__/ /_/ / /_/ / /  /  __/ /_ 
    echo                       \____/\____/\____/\__,_/_.___/\__, /\___/____/\__,_/ .___/_/   \___/\__/ 
    echo                                                    /____/               /_/
    echo.
    echo  %C_PRIMARY%Версия:%C_RESET% %Current_GoodbyeZapret_version%   %C_PRIMARY%Код:%C_RESET% %Current_GoodbyeZapret_version_code%   %C_PRIMARY%Ветка:%C_RESET% %branch%   %C_PRIMARY%Конфиг:%C_RESET% !GoodbyeZapret_Config!  
    call :ui_hr
    endlocal & goto :eof

:ui_header_for_END
    set "GoodbyeZapret_Config="
    call :ReadConfig GoodbyeZapret_Config
    if "%GoodbyeZapret_Config%"=="NotFound" (
        REM Если переменная не найдена, установите значение по умолчанию
        set "GoodbyeZapret_Config=Не выбран"
    )
    call :ui_init
    cls
    call :ui_hr
    echo             %C_RESET%______                ____            _____                         __ 
    echo            / ____/___  ____  ____/ / /_  __  ____/__  /  ____ _____  ________  / /_
    echo           / / __/ __ \/ __ \/ __  / __ \/ / / / _ \/ /  / __ `/ __ \/ ___/ _ \/ __/
    echo          / /_/ / /_/ / /_/ / /_/ / /_/ / /_/ /  __/ /__/ /_/ / /_/ / /  /  __/ /_ 
    echo          \____/\____/\____/\__,_/_.___/\__, /\___/____/\__,_/ .___/_/   \___/\__/ 
    echo                                       /____/               /_/
    echo.
    echo  %C_PRIMARY%Версия:%C_RESET% %Current_GoodbyeZapret_version%   %C_PRIMARY%Код:%C_RESET% %Current_GoodbyeZapret_version_code%   %C_PRIMARY%Ветка:%C_RESET% %branch%   %C_PRIMARY%Конфиг:%C_RESET% %GoodbyeZapret_Config%
    call :ui_hr
    endlocal & goto :eof

:UI_HELPERS_END

:GoodbyeZapret_Menu
REM Инициализируем переменные статуса
set "CheckStatus=WithoutChecked"
set "sourcePath=%~dp0"

REM Устанавливаем значения по умолчанию для конфига GoodbyeZapret
REM set "GoodbyeZapret_Current=Не выбран"
set "GoodbyeZapret_Config=Не выбран"

REM Проверяем, существует ли служба GoodbyeZapret и получаем текущую конфигурацию
REM reg query "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\GoodbyeZapret" /v "Description" >nul 2>&1
REM if !errorlevel! equ 0 (
REM     for /f "tokens=2*" %%a in ('reg query "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\GoodbyeZapret" /v "Description" 2^>nul ^| find /i "Description"') do set "GoodbyeZapret_Current=%%b"
REM )

REM Инициализируем флаг ремонта
set "RepairNeed=No"

REM Обработка процесса ремонта, если необходимо, и доступен WiFi
if /i "!WiFi!"=="On" (
    if /i "!RepairNeed!"=="Yes" (
        cls
        echo.
        echo  Error 03: Critical error. GoodbyeZapret needs to be reinstalled.
        echo  Starting the reinstallation...
        timeout /t 2 >nul

        REM Создаем директорию tools, если она не существует
        if not exist "%ParentDirPath%\tools" (
            md "%ParentDirPath%\tools" >nul 2>&1
        )

        if not exist "%ParentDirPath%\tools\curl\curl.exe" (
            echo  Error: сurl.exe not found
            echo  try downloading it from the project repository on github.
            timeout /t 4 >nul
        )

        REM Download Updater.exe if not present
        if not exist "%ParentDirPath%\tools\Updater.exe" (
            %CURL% -g -L -s -o "%ParentDirPath%\tools\Updater.exe" "https://github.com/ALFiX01/GoodbyeZapret/raw/refs/heads/main/Files/Updater/Updater.exe" >nul 2>&1
            if not exist "%ParentDirPath%\tools\Updater.exe" (
                echo  Error: Failed to download Updater.exe
                echo  Please check your internet connection and try again.
                timeout /t 3 >nul
                goto GoodbyeZapret_Menu
            )
        )

        timeout /t 2 >nul
        start "" "%ParentDirPath%\tools\Updater.exe"
        exit /b 0
    )
) else if /i "!RepairNeed!"=="Yes" (
    echo.
    echo  Error 04: Critical error. GoodbyeZapret needs to be reinstalled.
    echo  Internet connection required for repair. Please check your connection.
    timeout /t 3 >nul
)

:: Загрузка нового файла GZ_Updater.bat
REM Проверить состояние WiFi перед тем, как продолжить операции обновления
if /i "!WiFi!"=="Off" goto skip_for_wifi

REM Очистить временный файл, если он существует
if exist "%TEMP%\GZ_Updater.bat" (
    del /q /f "%TEMP%\GZ_Updater.bat" >nul 2>&1
    if exist "%TEMP%\GZ_Updater.bat" (
        echo Error: Failed to delete temporary file %TEMP%\GZ_Updater.bat
        timeout /t 2 >nul
    )
)

if not defined CURL (
    set "CURL=curl"
)

%CURL% -4 -s -I --fail --connect-timeout 1 --max-time 1 -o nul "https://raw.githubusercontent.com/ALFiX01/GoodbyeZapret/refs/heads/main/GoodbyeZapret_Version"

IF !ERRORLEVEL! NEQ 0 (
    set "CheckStatus=FileCheckError"
    goto OnFileCheckError
)

REM Скачать файл обновления версии
%CURL% -s -o "%TEMP%\GZ_Updater.bat" "https://raw.githubusercontent.com/ALFiX01/GoodbyeZapret/refs/heads/main/GoodbyeZapret_Version"
if errorlevel 1 (
    echo Error 04: Server error. Failed to connect to GoodbyeZapret update check server
    set "CheckStatus=NoChecked"
    goto OnFileCheckError
)

REM Проверить успешность загрузки файла GZ_Updater.bat
if not exist "%TEMP%\GZ_Updater.bat" (
    echo Error: Failed to download GZ_Updater.bat file
    set "CheckStatus=NoChecked"
    goto OnFileCheckError
)

REM Скачайте Updater.exe, если он не установлен
if not exist "%ParentDirPath%\tools\Updater.exe" (
    REM Создайте директорию tools, если она не существует
    if not exist "%ParentDirPath%\tools" (
        md "%ParentDirPath%\tools" >nul 2>&1
    )
    
    if not defined CURL (
    if exist "%ParentDirPath%\tools\curl\curl.exe" (
        set CURL="%ParentDirPath%\tools\curl\curl.exe"
    ) else (
        set CURL=curl
        )
    )
    %CURL% -g -L -s -o "%ParentDirPath%\tools\Updater.exe" "https://github.com/ALFiX01/GoodbyeZapret/raw/refs/heads/main/Files/Updater/Updater.exe"
    if not exist "%ParentDirPath%\tools\Updater.exe" (
        echo Error: Failed to download Updater.exe
        set "CheckStatus=NoChecked"
        goto OnFileCheckError
    )
)

REM Проверьте размер файла GZ_Updater.bat
set "FileSize=0"
for %%I in ("%TEMP%\GZ_Updater.bat") do set "FileSize=%%~zI"

if %FileSize% LSS 15 (
    echo Error 05: FileCheck error. File GZ_Updater.bat is corrupted or URL is not available.
    echo ^(Size: %FileSize% bytes^)
    echo.
    del /q "%TEMP%\GZ_Updater.bat" >nul 2>&1
    timeout /t 2 >nul
    set "CheckStatus=FileCheckError"
    goto OnFileCheckError
) else (
    set "CheckStatus=Checked"
)

if "%CheckStatus%"=="FileCheckError" (
    set "Actual_GoodbyeZapret_version=0.0.0"
    set "StatusProject=1"
    goto OnFileCheckError
)

REM Выполнить загруженный файл Updater.bat
call "%TEMP%\GZ_Updater.bat" >nul 2>&1
if errorlevel 1 (
    echo Error 05: Start error. Failed to execute GZ_Updater.bat
    set "CheckStatus=NoChecked"
    goto OnFileCheckError
)

:OnFileCheckError

if "%CheckStatus%"=="FileCheckError" (
    set "Actual_GoodbyeZapret_version=0.0.0"
    set "StatusProject=1"
)

set "UpdateNeed=No"

if "%StatusProject%"=="0" (
    cls
    echo.
    echo  Я был рад быть вам полезным, но пришло время прощаться.
    echo  Проект GoodbyeZapret был закрыт.
    echo.
    REM  GoodbyeZapret
    sc query "GoodbyeZapret" >nul 2>&1
    if !errorlevel! equ 0 (
    net stop "GoodbyeZapret" >nul 2>&1
    sc delete "GoodbyeZapret" >nul 2>&1
    )

    
    REM  winws.exe
    tasklist /FI "IMAGENAME eq winws.exe" 2>NUL | find /I /N "winws.exe" >NUL
    if not errorlevel 1 (
        taskkill /F /IM winws.exe >nul 2>&1
        taskkill /F /IM winws2.exe >nul 2>&1
    )
    
    REM  WinDivert
    sc query "WinDivert" >nul 2>&1
    if %errorlevel% equ 0 (
        net stop "WinDivert" >nul 2>&1
        sc delete "WinDivert" >nul 2>&1
    )
    
    REM  monkey
    sc query "monkey" >nul 2>&1
    if %errorlevel% equ 0 (
        net stop "monkey" >nul 2>&1
        sc delete "monkey" >nul 2>&1
    )
    
    REM Clean up registry and directories 
    reg delete "HKCU\Software\ALFiX inc.\GoodbyeZapret" /v "GoodbyeZapret_Config" /f >nul 2>&1
    if exist "%ParentDirPath%\configs" rd /s /q "%ParentDirPath%\configs" >nul 2>&1
    if exist "%ParentDirPath%\bin" rd /s /q "%ParentDirPath%\bin" >nul 2>&1
    if exist "%ParentDirPath%\lists" rd /s /q "%ParentDirPath%\lists" >nul 2>&1
    if exist "%ParentDirPath%\tools" rd /s /q "%ParentDirPath%\tools" >nul 2>&1
    
    timeout /t 7 >nul 2>&1
    exit /b
)

REM Проверяем, изменилась ли версия
if not "%CheckStatus%"=="FileCheckError" (
    if defined Actual_GoodbyeZapret_version_code (
        if defined Current_GoodbyeZapret_version_code (
            echo "%Actual_GoodbyeZapret_version_code%" | findstr /i "%Current_GoodbyeZapret_version_code%" >nul
            if errorlevel 1 (
                set "UpdateNeed=Yes"
            ) else (
                set "UpdateNeed=No"
                set "VersionFound=1"
            )
        ) else (
            set "UpdateNeed=No"
        )
    ) else (
        set "UpdateNeed=No"
    )
)

:skip_for_wifi

REM Проверяем, существует ли GoodbyeZapretTray.exe перед запуском
if exist "%ParentDirPath%\tools\tray\GoodbyeZapretTray.exe" (
    REM Завершаем процесс GoodbyeZapretTray.exe, если он уже запущен
    tasklist /FI "IMAGENAME eq GoodbyeZapretTray.exe" 2>NUL | find /I /N "GoodbyeZapretTray.exe" >NUL
    if !errorlevel! equ 1 (
        REM GoodbyeZapretTray.exe не запущен, ничего делать не нужно
    ) else (
        taskkill /F /IM GoodbyeZapretTray.exe >nul 2>&1
        if exist "%ParentDirPath%\tools\tray\goodbyezapret_tray.log" (
            del /F /Q "%ParentDirPath%\tools\tray\goodbyezapret_tray.log" >nul
        )
        timeout /t 1 >nul
    )
    start "" "%ParentDirPath%\tools\tray\GoodbyeZapretTray.exe"
)

title GoodbyeZapret - Launcher

REM Попробуйте прочитать значение из config.txt
call :ReadConfig GoodbyeZapret_Config
if not defined GoodbyeZapret_Config (
    set "GoodbyeZapret_Config=Not found"
)

rem Попробовать считать значение из config
call :ReadConfig GoodbyeZapret_Version

if "%GoodbyeZapret_Version%"=="NotFound" (
    set "GoodbyeZapret_Version_OLD=NotFound"
) else (
    set "GoodbyeZapret_Version_OLD=%GoodbyeZapret_Version%"
)

goto :end_GoodbyeZapret_Version_OLD

:end_GoodbyeZapret_Version_OLD

REM Проверяем, была ли ранее определена переменная Current_GoodbyeZapret_version
if not defined Current_GoodbyeZapret_version (
    REM Если переменная не определена, устанавливаем значения по умолчанию. Независимо от состояния Wi-Fi.
    set "Current_GoodbyeZapret_version=NotFound"
    set "Actual_GoodbyeZapret_version=0.0.0"
    set "UpdateNeed=No"

    REM Теперь проверяем, почему переменная не была определена. Если Wi-Fi НЕ выключен, значит, произошла ошибка чтения из сети.
    if /I not "%WiFi%"=="off" (
        echo.
        echo   Error 06: Read error. Failed to read value GoodbyeZapret_Version
        timeout /t 2 >nul
    )
)

REM Проверьте сервис GoodbyeZapret и получите текущую конфигурацию
reg query "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\GoodbyeZapret" /v Description >nul 2>&1
if %errorlevel% equ 0 (
    for /f "tokens=2*" %%a in ('reg query "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\GoodbyeZapret" /v "Description" 2^>nul ^| find /i "Description"') do (
        set "GoodbyeZapret_Current=%%b"
    )
)

if /i "%GoodbyeZapret_Config%" neq "NotFound" if /i not "%GoodbyeZapret_Config%"=="%GoodbyeZapret_Current%" call :WriteConfig GoodbyeZapret_Config "%GoodbyeZapret_Current%"

REM Update version in registry if defined
 if defined Current_GoodbyeZapret_version (
    call :WriteConfig GoodbyeZapret_Version "%Current_GoodbyeZapret_version%"
 )

:GZ_loading_process
set "SilentMode=1"
call :CurrentStatus
set "SilentMode="

if "%UpdateNeedShowScreen%"=="1" (
    goto MainMenu
) else (
    if "%UpdateNeed%"=="Yes" (
        set "UpdateNeedShowScreen=1"
        goto Update_Need_screen
    )
)


:MainMenu
call :ui_info "Загружаю интерфейс..."
REM ------ New: run quick problem check silently ------
REM ----------------------------------------------------
:MainMenu_without_ui_info
REM call :ResizeMenuWindow
mode con: cols=92 lines=41
if /i "%WiFi%"=="Off" mode con: cols=92 lines=42
REM Check for last working config in registry

call :ReadConfig GoodbyeZapret_Config
if "%GoodbyeZapret_Config%"=="NotFound" (
    REM Если переменная не найдена, установите значение по умолчанию
    set "GoodbyeZapret_Config=Не выбран"
)

REM Check GoodbyeZapret service status
sc query "GoodbyeZapret" >nul 2>&1
if %errorlevel% equ 0 (
    set "GoodbyeZapretStart=Yes"
) else (
    set "GoodbyeZapretStart=No"
)

REM Check Winws process status
set "WinwsStart=No"
for %%P in (winws.exe winws2.exe) do (
    tasklist /FI "IMAGENAME eq %%P" 2>nul | find /I "%%P" >nul && set "WinwsStart=Yes"
)

REM Проверка запущенных служб WinDivert
set "WinDivertStart=No"

for %%S in ("WinDivert" "WinDivert14" "monkey") do (
    sc query %%~S 2>nul | find /I "RUNNING" >nul
    if not errorlevel 1 (
        set "WinDivertStart=Yes"
    )
)

REM Count running services/processes
set "YesCount=0"
if "%GoodbyeZapretStart%"=="Yes" set /a YesCount+=1
if "%WinwsStart%"=="Yes" set /a YesCount+=1
if "%WinDivertStart%"=="Yes" set /a YesCount+=1


REM Display status based on running count
if %YesCount% equ 3 (
    REM запущены все сервисы
    cls
    echo.
    echo           %COL%[92m  ______                ____            _____                         __ 
) else if %YesCount% equ 2 (
    REM запущены Winws и WinDivert
    cls
    echo.
    echo           %COL%[33m  ______                ____            _____                         __ 
) else (
    REM запущен только GoodbyeZapret
    cls
    echo.
    echo           %COL%[90m  ______                ____            _____                         __ 
)


REM Set window title
if not defined Current_GoodbyeZapret_version (
    if /i "%branch%"=="beta" (
        title GoodbyeZapret - Launcher - бета версия %beta_code%
    ) else if /i "%branch%"=="alpha" (
        title GoodbyeZapret - Launcher - альфа версия
    ) else (
        title GoodbyeZapret - Launcher
    )
) else (
    if /i "%branch%"=="beta" (
        title GoodbyeZapret - Launcher v%Current_GoodbyeZapret_version% бета %beta_code%
    ) else if /i "%branch%"=="alpha" (
        title GoodbyeZapret - Launcher v%Current_GoodbyeZapret_version% альфа
    ) else (
        title GoodbyeZapret - Launcher v%Current_GoodbyeZapret_version%
    )
)


echo            / ____/___  ____  ____/ / /_  __  ____/__  /  ____ _____  ________  / /_
echo           / / __/ __ \/ __ \/ __  / __ \/ / / / _ \/ /  / __ `/ __ \/ ___/ _ \/ __/
echo          / /_/ / /_/ / /_/ / /_/ / /_/ / /_/ /  __/ /__/ /_/ / /_/ / /  /  __/ /_
echo          \____/\____/\____/\__,_/_.___/\__, /\___/____/\__,_/ .___/_/   \___/\__/

if /i "%branch%"=="beta" (
    echo                                        /____/  бета версия  /_/
    echo.
) else if /i "%branch%"=="alpha" (
    echo                                        /____/ альфа версия  /_/
    echo.
) else (
    echo                                        /____/              /_/
    echo.
)



REM call :timer_end


REM Check internet connection and file status
if /i "%WiFi%"=="Off" (
    echo                            %COL%[90mОшибка: Нет подключения к интернету%COL%[37m
) else if "%CheckStatus%"=="FileCheckError" (
    echo                %COL%[90mОшибка: Нет связи с сервером - возможны проблемы в работе%COL%[37m
) else if not "%CheckStatus%"=="Checked" if not "%CheckStatus%"=="WithoutChecked" (
    echo                %COL%[90mОшибка: Не удалось проверить файлы - возможны проблемы в работе%COL%[37m
) else (
    echo.
)

REM ------ New: warn user if system problems detected ------
if "%TotalCheck%"=="Problem" (
    echo                         %COL%[90mВозможна нестабильная работа GoodbyeZapret
    echo             %COL%[90m ────────────────────────────────────────────────────────────────── %COL%[37m
) else (
    echo             %COL%[90m ────────────────────────────────────────────────────────────────── %COL%[37m
    echo.
)
echo.
echo.
echo.
echo.
echo.
echo.
echo                               %COL%[96m^[ 1 ^]%COL%[37m Состояние GoodbyeZapret
echo.
echo                               %COL%[96m^[ 2 ^]%COL%[37m Конфигуратор стратегий
echo.
echo                               %COL%[96m^[ 3 ^]%COL%[37m Выбор готового конфига
echo.
echo                               %COL%[96m^[ 4 ^]%COL%[37m Доп. настройки обхода
echo.
echo                               %COL%[96m^[ 5 ^]%COL%[37m Проверить доступ к CDN 
echo.
echo                               %COL%[96m^[ 6 ^]%COL%[37m Открыть инструкцию
echo.
echo.
echo.
echo.
echo.
echo.
echo.
echo.
echo.

REM Display separator line
echo             %COL%[90m ────────────────────────────────────────────────────────────────── %COL%[37m
echo                             %COL%[90mВведите %COL%[96m^[ номер ^]%COL%[90m и нажмите %COL%[96mEnter%COL%[90m 
echo.
set /p "choice=%DEL%                                           %COL%[90m:> "

REM Handle user input with case-insensitive matching
if /i "%choice%"=="1" goto CurrentStatus 
if /i "%choice%"=="2" goto ConfiguratorMenu
if /i "%choice%"=="3" goto ConfigSelectorMenu_without_ui_info
if /i "%choice%"=="4" goto MenuBypassSettings_without_ui_info
if /i "%choice%"=="5" Start https://hyperion-cs.github.io/dpi-checkers/ru/tcp-16-20
if /i "%choice%"=="6" goto OpenInstructions
goto MainMenu

:MenuBypassSettings
call :ui_info "Загружаю интерфейс..."
REM ------ New: run quick problem check silently ------
REM ----------------------------------------------------
:MenuBypassSettings_without_ui_info
REM call :ResizeMenuWindow
title GoodbyeZapret - Дополнительные настройки обхода
mode con: cols=92 lines=41
REM Check for last working config in registry

set "hostspath=%SystemRoot%\System32\drivers\etc\hosts"
set "tempfile=%temp%\hosts.tmp"
findstr /c:"### Discord Finland Media Servers BEGIN" "%hostspath%" >nul
if not errorlevel 1 (
    set "FinlandDiscordHost=On"
) else (
    set "FinlandDiscordHost=Off"
)

findstr /c:"### Twitch Servers BEGIN" "%hostspath%" >nul
if not errorlevel 1 (
    set "TwitchHost=On"
) else (
    set "TwitchHost=Off"
)

findstr /c:"### YouTube TCP Servers BEGIN" "%hostspath%" >nul
if not errorlevel 1 (
    set "YoutubeHost=On"
) else (
    set "YoutubeHost=Off"
)


REM Display status based on running count
if %YesCount% equ 3 (
    REM запущены все сервисы
    cls
    echo.
    echo           %COL%[92m  ______                ____            _____                         __ 
) else if %YesCount% equ 2 (
    REM запущены Winws и WinDivert
    cls
    echo.
    echo           %COL%[33m  ______                ____            _____                         __ 
) else (
    REM запущен только GoodbyeZapret
    cls
    echo.
    echo           %COL%[90m  ______                ____            _____                         __ 
)


echo            / ____/___  ____  ____/ / /_  __  ____/__  /  ____ _____  ________  / /_
echo           / / __/ __ \/ __ \/ __  / __ \/ / / / _ \/ /  / __ `/ __ \/ ___/ _ \/ __/
echo          / /_/ / /_/ / /_/ / /_/ / /_/ / /_/ /  __/ /__/ /_/ / /_/ / /  /  __/ /_
echo          \____/\____/\____/\__,_/_.___/\__, /\___/____/\__,_/ .___/_/   \___/\__/

if /i "%branch%"=="beta" (
    echo                                        /____/  бета версия  /_/
    echo.
) else if /i "%branch%"=="alpha" (
    echo                                        /____/ альфа версия  /_/
    echo.
) else (
    echo                                        /____/              /_/
    echo.
)

echo             %COL%[90m ────────────────────────────────────────────────────────────────── %COL%[37m

call "%USERPROFILE%\AppData\Roaming\GoodbyeZapret\ports.bat"

if not defined tcp_ports set "tcp_ports=80,443,1080,2053,2083,2087,2096,8443,6568,1024-65535"
if not defined udp_ports set "udp_ports=80,443,1024-65535,4" 

echo.
echo.
echo                    %COL%[96m^[ 1 ^]%COL%[37m Уровень обхода CDN               ^(%COL%[96m%CDN_BypassLevel%%COL%[37m^)
echo.
echo                    %COL%[96m^[ 2 ^]%COL%[37m Host Обход Discord + Fin. Voice   ^(%COL%[96m%FinlandDiscordHost%%COL%[37m^)
echo.
echo                    %COL%[96m^[ 3 ^]%COL%[37m Host Обход twitch                 ^(%COL%[96m%TwitchHost%%COL%[37m^)
echo.
echo                    %COL%[96m^[ 4 ^]%COL%[37m Host Обход YouTube                ^(%COL%[96m%YoutubeHost%%COL%[37m^)
echo.
echo                    %COL%[96m^[ 5 ^]%COL%[37m TCP порты обхода:
echo                    %COL%[92m%tcp_ports%
echo.
echo                    %COL%[96m^[ 6 ^]%COL%[37m UDP порты обхода:
echo                    %COL%[92m%udp_ports%
echo.
echo.
echo.
echo.
echo.
echo.
echo.
echo.
echo.
echo.
echo.
echo.
echo.

REM Display separator line
REM echo             %COL%[90m ────────────────────────────────────────────────────────────────── %COL%[37m
echo                    %COL%[90mВведите %COL%[96m^[ номер ^]%COL%[90m или %COL%[96m^[ B ^]%COL%[90m для выхода в главное меню
echo.
set /p "choice=%DEL%                                           %COL%[90m:> "

REM Handle user input with case-insensitive matching
if /i "%choice%"=="1" goto CDN_BypassLevelSelector
if /i "%choice%"=="2" goto FinlandDiscordHostSelector
if /i "%choice%"=="3" goto TwitchHostSelector
if /i "%choice%"=="4" goto YoutubeHostsSelector

if /i "%choice%"=="B" goto MainMenu_without_ui_info
if /i "%choice%"=="и" goto MainMenu_without_ui_info

:: Проверки ввода с использованием полученных лимитов
if "%choice%"=="5" (
    set /p tcp_ports="%DEL%   Введите новые TCP порты: "
    REM Записываем новое значение в реестр (системные переменные)

    reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /v "tcp_ports" /t REG_SZ /d "!tcp_ports!" /f >nul

    if defined tcp_ports (
        call :WriteConfig tcp_ports "%tcp_ports%"
    ) else (
        echo ^[ERROR^] tcp_ports не определен
    )
    goto MenuBypassSettings_without_ui_info
)

:: Проверки ввода с использованием полученных лимитов
if "%choice%"=="6" (
    set /p udp_ports="%DEL%   Введите новые UDP порты: "
    REM Записываем новое значение в реестр (системные переменные)

    reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /v "udp_ports" /t REG_SZ /d "!udp_ports!" /f >nul

    if defined udp_ports (
        call :WriteConfig udp_ports "%udp_ports%"
    ) else (
        echo ^[ERROR^] udp_ports не определен
    )
    goto MenuBypassSettings_without_ui_info
)

goto MenuBypassSettings_without_ui_info


:ConfigSelectorMenu
call :ui_info "Загружаю интерфейс..."
REM ------ New: run quick problem check silently ------
REM ----------------------------------------------------
:ConfigSelectorMenu_without_ui_info
set "PanelBack=ConfigSelectorMenu"
call :ResizeMenuWindow
REM Check for last working config in registry
call :ReadConfig GoodbyeZapret_LastWorkConfig
if "%GoodbyeZapret_LastWorkConfig%"=="NotFound" (
    set "GoodbyeZapret_LastWork=none"
) else (
    rem Обрезать последние 4 символа: %var:~0,-4%
    set "GoodbyeZapret_LastWork=%GoodbyeZapret_LastWorkConfig:~0,-4%"
)

call :ReadConfig GoodbyeZapret_Config
if "%GoodbyeZapret_Config%"=="NotFound" (
    REM Если переменная не найдена, установите значение по умолчанию
    set "GoodbyeZapret_Config=Не выбран"
)

REM Check GoodbyeZapret service status
sc query "GoodbyeZapret" >nul 2>&1
if %errorlevel% equ 0 (
    set "GoodbyeZapretStart=Yes"
) else (
    set "GoodbyeZapretStart=No"
)

REM Check Winws process status
set "WinwsStart=No"
for %%P in (winws.exe winws2.exe) do (
    tasklist /FI "IMAGENAME eq %%P" 2>nul | find /I "%%P" >nul && set "WinwsStart=Yes"
)

REM Проверка запущенных служб WinDivert
set "WinDivertStart=No"

for %%S in ("WinDivert" "WinDivert14" "monkey") do (
    sc query %%~S 2>nul | find /I "RUNNING" >nul
    if not errorlevel 1 (
        set "WinDivertStart=Yes"
        goto :DoneStartCheck
    )
)

:DoneStartCheck
REM Count running services/processes
set "YesCount=0"
if "%GoodbyeZapretStart%"=="Yes" set /a YesCount+=1
if "%WinwsStart%"=="Yes" set /a YesCount+=1
if "%WinDivertStart%"=="Yes" set /a YesCount+=1


REM Display status based on running count
if %YesCount% equ 3 (
    REM запущены все сервисы
    cls
    echo.
    echo           %COL%[92m  ______                ____            _____                         __ 
) else if %YesCount% equ 2 (
    REM запущены Winws и WinDivert
    cls
    echo.
    echo           %COL%[33m  ______                ____            _____                         __ 
) else (
    REM запущен только GoodbyeZapret
    cls
    echo.
    echo           %COL%[90m  ______                ____            _____                         __ 
)


REM Set window title
if not defined Current_GoodbyeZapret_version (
    if /i "%branch%"=="beta" (
        title GoodbyeZapret - Launcher - бета версия %beta_code%
    ) else (
        title GoodbyeZapret - Launcher
    )
) else (
    if /i "%branch%"=="beta" (
        title GoodbyeZapret - Launcher v%Current_GoodbyeZapret_version% бета %beta_code% 
    ) else (
        title GoodbyeZapret - Launcher v%Current_GoodbyeZapret_version%
    )
)

echo            / ____/___  ____  ____/ / /_  __  ____/__  /  ____ _____  ________  / /_
echo           / / __/ __ \/ __ \/ __  / __ \/ / / / _ \/ /  / __ `/ __ \/ ___/ _ \/ __/
echo          / /_/ / /_/ / /_/ / /_/ / /_/ / /_/ /  __/ /__/ /_/ / /_/ / /  /  __/ /_ 
echo          \____/\____/\____/\__,_/_.___/\__, /\___/____/\__,_/ .___/_/   \___/\__/ 

if /i "%branch%"=="beta" (
    echo                                       /____/  бета версия  /_/ 
    echo.
) else (
    echo                                       /____/               /_/
    echo             %COL%[90mГотовые конфиги менее эффективны. Используйте конфигуратор стратегий %COL%[37m
)


REM call :timer_end

REM ---------------------------------------------------------

REM Display separator line
echo             %COL%[90m ────────────────────────────────────────────────────────────────── %COL%[37m

echo                  %COL%[36mКонфиги:
echo.
set "choice="
set "counter=0"

REM -- Ensure pagination variables exist --
if not defined Page set "Page=1"
if not defined PageSize set "PageSize=20"
REM ---------------------------------------

REM ---------- Pagination indices ----------
set /a StartIndex=(Page-1)*PageSize+1
set /a EndIndex=StartIndex+PageSize-1

if not defined ParentDirPath (
:: Get the parent directory path more reliably
for /f "delims=" %%A in ('powershell -NoProfile -Command "Split-Path -Parent '%~f0'"') do set "ParentDirPath=%%A"  
)

if not exist "%ParentDirPath%\configs\Preset" (
    Echo  ОШИБКА - "%ParentDirPath%\configs\Preset"
    pause >nul
)

dir /b "%ParentDirPath%\configs\Preset" | findstr . >nul
if errorlevel 1 (
    echo.
    echo  ОШИБКА - конфиги не найдены.
    echo  Папка конфигов = %ParentDirPath%\configs\Preset
    pause >nul
)

setlocal EnableDelayedExpansion
set "hasActiveOrStarted=0"
set /a counter=0

REM === Получаем список .bat с natural sort =========================
chcp 850 >nul 2>&1
powershell -NoProfile -Command ^
    "Get-ChildItem '%ParentDirPath%\configs\Preset','%ParentDirPath%\configs\Custom' -Filter *.bat |" ^
    "Sort-Object { [regex]::Replace($_.Name, '\d+', { param($m) $m.Value.PadLeft(20,'0') }) } |" ^
    "ForEach-Object { $_.FullName }" ^
    > "%temp%\cfg_list.tmp"
chcp 65001 >nul 2>&1
REM === Проверка активного конфига ================================
for /f "delims=" %%F in (%temp%\cfg_list.tmp) do (
    if /i "%%~nF"=="%GoodbyeZapret_Config%" set "hasActiveOrStarted=1"
)

REM === Вывод ======================================================
for /f "delims=" %%F in (%temp%\cfg_list.tmp) do (
    set /a counter+=1
    set "ConfigName=%%~nF"
    set "ConfigFull=%%~nxF"

    set "StatusText="
    set "StatusColor=%COL%[37m"

    if /i "!ConfigName!"=="%GoodbyeZapret_Config%" (
        set "StatusText=[Текущий]"
        set "StatusColor=%COL%[92m"
    ) else if /i "!ConfigName!"=="!GoodbyeZapret_LastWork!" if "!hasActiveOrStarted!"=="0" (
        set "StatusText=[Работал лучше других]"
        set "StatusColor=%COL%[93m"
    )

    if !counter! lss 10 (set "Pad= ") else set "Pad="

    if !counter! geq !StartIndex! if !counter! leq !EndIndex! (
        if defined StatusText (
            echo                  !Pad!%COL%[36m!counter!. %COL%[36m!ConfigName! !StatusColor!!StatusText!
        ) else (
            echo                  !Pad!%COL%[36m!counter!. %COL%[37m!ConfigName!
        )
    )

    set "file!counter!=!ConfigFull!"
)

del "%temp%\cfg_list.tmp"

REM ---------------------------------------------------------------------------------

set /a "lastChoice=counter"
set /a TotalPages=(counter+PageSize-1)/PageSize
if %Page% gtr %TotalPages% set /a Page=%TotalPages%

REM Display update notification if available
if "%UpdateNeed%"=="Yes" (
    if defined Current_GoodbyeZapret_version (
        title GoodbyeZapret v%Current_GoodbyeZapret_version% - ДОСТУПНО ОБНОВЛЕНИЕ
    ) else (
        title GoodbyeZapret - ДОСТУПНО ОБНОВЛЕНИЕ
    )
)

echo             %COL%[90m ────────────────────────────────────────────────────────────────── %COL%[37m
echo                  %COL%[36mДействия:
echo.

REM Display different menu options based on current service status
if "%GoodbyeZapret_Config%"=="Не выбран" (
    echo                  %COL%[36m^[1-!counter!s^] %COL%[92mЗапустить конфиг
    echo                   %COL%[36m^[1-!counter!^] %COL%[92mУстановить конфиг в автозапуск
    echo                    %COL%[36m^[ A ^] %COL%[37mАвтоподбор конфига
) else (
    echo                    %COL%[36m^[ D ^] %COL%[91mУдалить конфиг из автозапуска
    echo                    %COL%[36m^[ R ^] %COL%[37mБыстрый перезапуск конфига
    echo                    %COL%[36m^[ A ^] %COL%[37mАвтоподбор конфига
)

REM ---- Pagination options ----
if %TotalPages% gtr 1 (
    echo.
    if %Page% lss %TotalPages% echo                    %COL%[36m^[ N ^] %COL%[37mСледующая страница с конфигами
    if %Page% gtr 1 echo                    %COL%[36m^[ B ^] %COL%[37mПредыдущая страница
    if %Page% equ 1 echo                    %COL%[36m^[ B ^] %COL%[37mВернуться в главное меню
) else (
    echo                    %COL%[36m^[ B ^] %COL%[37mВернуться в главное меню
)
REM ----------------------------
echo.
echo.
echo                              %COL%[90mВведите %COL%[96m^[ номер ^]%COL%[90m или %COL%[96m^[ букву ^]%COL%[90m
echo.
set /p "choice=%DEL%                                           %COL%[90m:> "

REM Handle user input with case-insensitive matching
if /i "%choice%"=="D" goto remove_service
if /i "%choice%"=="в" goto remove_service

if /i "%choice%"=="R" goto QuickRestart
if /i "%choice%"=="к" goto QuickRestart

if /i "%choice%"=="S" goto CurrentStatus
if /i "%choice%"=="ы" goto CurrentStatus

if /i "%choice%"=="A" goto ConfigAutoFinder
if /i "%choice%"=="ф" goto ConfigAutoFinder


if /i "%choice%"=="RR" goto RR

REM --- Pagination input handling ---
if /i "%choice%"=="N" (
    set /a Page+=1
    goto ConfigSelectorMenu
)
if /i "%choice%"=="т" (
    set /a Page+=1
    goto ConfigSelectorMenu
)
if /i "%choice%"=="B" (
    if %Page% equ 1 goto MainMenu_without_ui_info
    if %Page% gtr 1 set /a Page-=1
    goto ConfigSelectorMenu
)
if /i "%choice%"=="и" (
    if %Page% equ 1 goto MainMenu_without_ui_info
    if %Page% gtr 1 set /a Page-=1
    goto ConfigSelectorMenu
)
REM ---------------------------------

REM Handle update option only if update is available
if "%UpdateNeed%"=="Yes" (
    if /i "%choice%"=="UD" goto Update_Need_screen
)

REM Return to main menu if no input provided
if "%choice%"=="" goto MainMenu

REM Handle configuration file selection and validation
if "%choice:~-1%"=="s" (
    REM Manual start mode - open config file in explorer
    set "batFile=!file%choice:~0,-1%!"

    REM Определяем, в какой папке лежит выбранный bat
    set "batRel="
    if exist "%ParentDirPath%\configs\Preset\!batFile!" set "batRel=Preset\!batFile!" && set "batPath=Preset"
    if exist "%ParentDirPath%\configs\Custom\!batFile!" set "batRel=Custom\!batFile!" && set "batPath=Custom"

    if defined batRel (
        echo Запустите "%ParentDirPath%\configs\!batPath!\!batFile!" вручную
        explorer "%ParentDirPath%\configs\!batPath!\!batFile!"
        goto :end
    ) else (
        echo Неверный выбор. Пожалуйста, попробуйте снова.
        goto MainMenu
    )
) else (
    REM Service installation mode
    set "batFile=!file%choice%!"

    REM Определяем папку (Preset/Custom) для установки
    set "batRel="
    if exist "%ParentDirPath%\configs\Preset\!batFile!" set "batRel=Preset\!batFile!" & set "batPath=Preset"
    if exist "%ParentDirPath%\configs\Custom\!batFile!" set "batRel=Custom\!batFile!" & set "batPath=Custom"
)

REM Initialize color variables if not already set
if not defined COL (
    for /F "tokens=1,2 delims=#" %%a in ('"prompt #$H#$E# & echo on & for %%b in (1) do rem"') do (set "DEL=%%a" & set "COL=%%b")
)

REM Validate configuration file selection
if not defined batFile (
    echo Неверный выбор. Пожалуйста, попробуйте снова.
    goto MainMenu
)

REM Check if selected config file exists
if not exist "%ParentDirPath%\configs\!batRel!" (
    echo Ошибка: Файл конфига !batRel! не найден.
    echo Пожалуйста, попробуйте снова.
    goto MainMenu
)

REM Confirm installation with user
cls
echo %COL%[97m
echo.
echo   Подтвердите установку %COL%[36m!batFile!%COL%[97m в службу GoodbyeZapret
echo  %COL%[90m Нажмите любую клавишу для подтверждения... %COL%[37m
echo.
pause >nul 2>&1

REM Clean up existing service before installing new one
call :remove_service_before_installing
call :install_GZ_service

:install_GZ_service
cls
call :ui_init
call :ui_hr
echo   %C_TITLE%Установка службы GoodbyeZapret !batRel! %C_RESET%
call :ui_hr
if "!batfile!"=="MultiFix_ts.bat" (
    REM Проверка, включались ли уже TCP timestamps
    netsh interface tcp show global | findstr /i "timestamps" | findstr /i "enabled" > nul
    if !errorlevel!==0 (
        echo TCP timestamps уже были включены ранее, пропуск...
    ) else (
        echo   Выполняется автоматическое включение TCP timestamps...
        netsh interface tcp set global timestamps=enabled > nul 2>&1
        if !errorlevel!==0 (
            echo TCP timestamps успешно включены
        ) else (
            echo Ошибка включения TCP timestamps
        )
    )
    echo   Перехожу к установке конфига в службу
    timeout /t 2 >nul
    cls
    call :ui_init
    call :ui_hr
    echo   %C_TITLE%Установка службы GoodbyeZapret %C_RESET%
    call :ui_hr
)

echo.

if exist "%ParentDirPath%\tools\tray\GoodbyeZapretTray.exe" (
    schtasks /Create /TN "GoodbyeZapretTray" /SC ONLOGON /RL HIGHEST /IT /F /TR "\"%ParentDirPath%\tools\tray\GoodbyeZapretTray.exe\"" >nul 2>&1
    schtasks /run /tn "GoodbyeZapretTray" >nul 2>&1
)

call :ui_info "Устанавливаю !batFile! в службу GoodbyeZapret..."

if "!batfile!"=="smart-config.bat" (
    set "LUA_DIR=%ParentDirPath%\bin\lua"

    :: Генерация base_path.lua
    set "BASE_PATH_LUA=!LUA_DIR!\base_path.lua"
    echo Генерация base_path.lua...
    (
        echo ORCHESTRA_BASE_PATH = "!LUA_DIR:\=/!/"
    ) > "!BASE_PATH_LUA!"

    sc create "GoodbyeZapret" binPath= "\"%ParentDirPath%\tools\SmartConfig.exe\" --bin \"%ParentDirPath%\bin\" --lua \"%ParentDirPath%\bin\lua\" --learned-init \"%ParentDirPath%\bin\lua\learned-strategies.lua\"" >nul 2>&1
    sc config "GoodbyeZapret" start= auto >nul 2>&1 
) else (
    sc create "GoodbyeZapret" binPath= "cmd.exe /c \"\"%ParentDirPath%\configs\!batPath!\!batFile!\"\"" >nul 2>&1
    sc config "GoodbyeZapret" start= auto >nul 2>&1 
)


REM Извлекаем базовое имя файла (без папки и расширения) для записи в реестр/описание
for %%A in ("!batRel!") do set "BaseCfg=%%~nA"

REM reg add "HKCU\Software\ALFiX inc.\GoodbyeZapret" /t REG_SZ /v "GoodbyeZapret_Config" /d "!batPath!" /f >nul
REM reg add "HKCU\Software\ALFiX inc.\GoodbyeZapret" /t REG_SZ /v "GoodbyeZapret_ConfigPatch" /d "!BaseCfg!" /f >nul

call :WriteConfig GoodbyeZapret_Config "!BaseCfg!"
sc description GoodbyeZapret "!BaseCfg!" >nul
sc start "GoodbyeZapret" >nul
cls
echo.
call :ui_ok "!batFile! установлен в службу GoodbyeZapret"

set installing_service=0

if not "!batfile!"=="smart-config.bat" (
    if exist "%ParentDirPath%\tools\Config_Check\config_check.exe" (
        echo.
        REM Цветной текст
        for /F "tokens=1,2 delims=#" %%a in ('"prompt #$H#$E# & echo on & for %%b in (1) do rem"') do (set "DEL=%%a" & set "COL=%%b")
        "%ParentDirPath%\tools\Config_Check\config_check.exe" "!batFile!"
    )
)

if /I not "!batfile!"=="smart-config.bat" if /I not "!batfile!"=="ConfiguratorFix.bat" (
    tasklist | find /I "Winws.exe" >nul
    if errorlevel 1 (
        tasklist | find /I "Winws2.exe" >nul
        if errorlevel 1 (
            echo.
            echo ОШИБКА: Процес обхода ^(Winws.exe или Winws2.exe^) не запущен.
            echo.
            timeout /t 2 >nul 2>&1
        )
    )
)
goto :end

:remove_service
    cls
    call :ui_init
    call :ui_hr
    echo   %C_TITLE%Удаление службы GoodbyeZapret%C_RESET%
    call :ui_hr
    REM Цветной текст
    for /F "tokens=1,2 delims=#" %%a in ('"prompt #$H#$E# & echo on & for %%b in (1) do rem"') do (set "DEL=%%a" & set "COL=%%b")
    echo.
    sc query "GoodbyeZapret" >nul 2>&1
    if !errorlevel! equ 0 (
        net stop "GoodbyeZapret" >nul 2>&1
        sc delete "GoodbyeZapret" >nul 2>&1
        if !errorlevel! equ 0 (
            call :ui_ok "Служба GoodbyeZapret успешно удалена"
            tasklist /FI "IMAGENAME eq winws.exe" 2>NUL | find /I /N "winws.exe" >NUL
            if "!errorlevel!"=="0" (
                taskkill /F /IM winws.exe >nul 2>&1
                net stop "WinDivert" >nul 2>&1
                sc delete "WinDivert" >nul 2>&1
                net stop "WinDivert14" >nul 2>&1
                sc delete "WinDivert14" >nul 2>&1
                net stop "monkey" >nul 2>&1
                sc delete "monkey" >nul 2>&1
                call :ui_ok "Файл winws.exe остановлен"
                ipconfig /flushdns > nul
            )
            tasklist /FI "IMAGENAME eq winws2.exe" 2>NUL | find /I /N "winws2.exe" >NUL
            if "!errorlevel!"=="0" (
                taskkill /F /IM winws2.exe >nul 2>&1
                net stop "WinDivert" >nul 2>&1
                sc delete "WinDivert" >nul 2>&1
                net stop "WinDivert14" >nul 2>&1
                sc delete "WinDivert14" >nul 2>&1
                net stop "monkey" >nul 2>&1
                sc delete "monkey" >nul 2>&1
                call :ui_ok "Файл winws2.exe остановлен"
                ipconfig /flushdns > nul
            )
            call :ui_ok "Удаление успешно завершено"
        ) else (
            call :ui_err "Ошибка при удалении службы"
        )
    ) else (
        call :ui_warn "Служба GoodbyeZapret не найдена"
    )

    taskkill /F /IM GoodbyeZapretTray.exe >nul 2>&1
    schtasks /end /tn "GoodbyeZapretTray" >nul 2>&1
    schtasks /delete /tn "GoodbyeZapretTray" /f >nul 2>&1
    call :WriteConfig GoodbyeZapret_Config "NotFound"
    timeout /t 1 >nul 2>&1
goto :end

:remove_service_before_installing
    cls
    call :ui_init
    call :ui_hr
    echo   %C_TITLE%Удаление старой службы GoodbyeZapret %C_RESET%
    call :ui_hr
    call :ui_info "подготовка к установке !batRel! в GoodbyeZapret..."
    echo.
    sc query "GoodbyeZapret" >nul 2>&1
    if %errorlevel% equ 0 (
        net stop "GoodbyeZapret" >nul 2>&1
        sc delete "GoodbyeZapret" >nul 2>&1
        if %errorlevel% equ 0 (
            call :ui_ok "Служба GoodbyeZapret успешно удалена"
            tasklist /FI "IMAGENAME eq winws.exe" 2>NUL | find /I /N "winws.exe" >NUL
            if "%ERRORLEVEL%"=="0" (
                taskkill /F /IM winws.exe >nul 2>&1
                net stop "WinDivert" >nul 2>&1
                sc delete "WinDivert" >nul 2>&1
                net stop "WinDivert14" >nul 2>&1
                sc delete "WinDivert14" >nul 2>&1
                call :ui_ok "Файл winws.exe остановлен"
                ipconfig /flushdns > nul
            )
            tasklist /FI "IMAGENAME eq winws2.exe" 2>NUL | find /I /N "winws2.exe" >NUL
            if "%ERRORLEVEL%"=="0" (
                taskkill /F /IM winws2.exe >nul 2>&1
                net stop "WinDivert" >nul 2>&1
                sc delete "WinDivert" >nul 2>&1
                net stop "WinDivert14" >nul 2>&1
                sc delete "WinDivert14" >nul 2>&1
                call :ui_ok "Файл winws2.exe остановлен"
                ipconfig /flushdns > nul
            )
            call :ui_ok "Удаление успешно завершено"
        ) else (
            call :ui_err "Ошибка при удалении службы"
        )
    )
    call :WriteConfig GoodbyeZapret_Config "NotFound"
    timeout /t 1 >nul 2>&1
goto :install_GZ_service

:end
if !ErrorCount! equ 0 (
    REM Set default values for GoodbyeZapret configuration
    set "GoodbyeZapret_Config=Не выбран"

    call :ReadConfig GoodbyeZapret_Config
    if "%GoodbyeZapret_Config%"=="NotFound" (
        REM Если переменная не найдена, установите значение по умолчанию
        set "GoodbyeZapret_Config=Не выбран"
    )
    if "%PanelBack%"=="Configurator" ( goto ConfiguratorMenu ) else ( goto ConfigSelectorMenu_without_ui_info )
) else (
    echo  Нажмите любую клавишу чтобы продолжить...
    pause >nul 2>&1
    set "batFile="
    REM Set default values for GoodbyeZapret configuration
    set "GoodbyeZapret_Config=Не выбран"

    if "%PanelBack%"=="Configurator" ( goto ConfiguratorMenu ) else ( goto ConfigSelectorMenu_without_ui_info )
)

:CurrentStatus
REM REM Check Auto-update setting from registry
REM reg query "HKEY_CURRENT_USER\Software\ALFiX inc.\GoodbyeZapret" /v "Auto-update" >nul 2>&1
REM if %errorlevel% equ 0 (
REM     for /f "tokens=2*" %%a in ('reg query "HKEY_CURRENT_USER\Software\ALFiX inc.\GoodbyeZapret" /v "Auto-update" 2^>nul ^| find /i "Auto-update"') do set "Auto-update=%%b"
REM ) else (
REM     set "Auto-update=1"
REM ) 

REM Check BFE service state
sc query BFE | findstr "STATE" >nul 2>&1
if %errorlevel% equ 0 (
    for /f "tokens=4" %%a in ('sc query BFE 2^>nul ^| findstr "STATE"') do set "BFE_STATE=%%a"
) else (
    set "BFE_STATE=UNKNOWN"
)

REM Check BFE service start type
sc qc BFE | findstr "START_TYPE" >nul 2>&1
if %errorlevel% equ 0 (
    for /f "tokens=4" %%a in ('sc qc BFE 2^>nul ^| findstr "START_TYPE"') do set "BFE_START=%%a"
) else (
    set "BFE_START=UNKNOWN"
)

REM BaseFilteringEngine (BFE) - Служба базовой фильтрации
if not "%BFE_STATE%"=="RUNNING" (
    if not "%BFE_START%"=="AUTO_START" (
        REM Служба BFE (Служба базовой фильтрации) не запущена или не установлена.
        set "BaseFilteringEngineCheckResult=Problem"
        set "BaseFilteringEngineCheckTips=Попробуйте установить и запустить службу BFE"
    ) else (
        REM Служба BFE (Служба базовой фильтрации) не запущена.
        set "BaseFilteringEngineCheckResult=Problem"
        set "BaseFilteringEngineCheckTips=Попробуйте запустить службу BFE"
    )
) else if not "%BFE_START%"=="AUTO_START" (
    REM Служба BFE (Служба базовой фильтрации) имеет неправильный режим запуска.
    set "BaseFilteringEngineCheckResult=Problem"
    set "BaseFilteringEngineCheckTips=Попробуйте установить режим запуска службы BFE на автоматический"
) else (
    REM Служба BFE работает корректно
    set "BaseFilteringEngineCheckResult=Ok"
    set "BaseFilteringEngineCheckTips="
)

:: AdguardSvc.exe
tasklist /FI "IMAGENAME eq AdguardSvc.exe" 2>NUL | find /I "AdguardSvc.exe" >NUL
if !errorlevel!==0 (
    :: Adguard process found. Adguard may cause problems with Discord - https://github.com/Flowseal/zapret-discord-youtube/issues/417
    set "AdguardCheckResult=Problem"
    set "AdguardCheckTips=Попробуйте отключить/удалить Adguard"
) else (
    set "AdguardCheckResult=Ok"
    set "AdguardCheckTips="
) 

REM === Поиск сервисов Killer ===
set "KillerCheckResult=Ok"
set "KillerServices="
set "KillerCheckTips="
for /f "tokens=2 delims=:" %%a in ('sc query 2^>NUL ^| findstr /I "SERVICE_NAME:" ^| findstr /I "Killer"') do (
    set "KillerServiceName=%%a"
    set "KillerServiceName=!KillerServiceName: =!"
    if defined KillerServices (
        set "KillerServices=!KillerServices!,!KillerServiceName!"
    ) else (
        set "KillerServices=!KillerServiceName!"
    )
)

if defined KillerServices (
    set "KillerCheckResult=Problem"
    set "KillerCheckTips=Попробуйте удалить сервисы Killer ^(!KillerServices!^)."
) else (
    set "KillerCheckResult=Ok"
)

REM === Поиск сервисов Intel Connectivity Network Service ===
set "IntelCheckResult=Ok"
set "IntelServices="
set "IntelCheckTips="
for /f "tokens=2 delims=:" %%a in ('sc query 2^>NUL ^| findstr /I "SERVICE_NAME:" ^| findstr /I "Intel" ^| findstr /I "Connectivity" ^| findstr /I "Network"') do (
    set "IntelServiceName=%%a"
    set "IntelServiceName=!IntelServiceName: =!"
    if defined IntelServices (
        set "IntelServices=!IntelServices!,!IntelServiceName!"
    ) else (
        set "IntelServices=!IntelServiceName!"
    )
)

if defined IntelServices (
    set "IntelCheckResult=Problem"
    set "IntelCheckTips=Отключите/удалите Intel Connectivity Network ^(!IntelServices!^) ."
) else (
    set "IntelCheckResult=Ok"
)

REM === Поиск сервисов Check Point ===
set "CheckpointCheckResult=Ok"
set "CheckpointServices="
set "CheckpointCheckTips="

REM Список целевых сервисов Check Point, которые необходимо обнаружить
for %%S in (TracSrvWrapper EPWD) do (
    sc query "%%S" 2>NUL | findstr /I "SERVICE_NAME" >NUL
    if !errorlevel!==0 (
        if defined CheckpointServices (
            set "CheckpointServices=!CheckpointServices!,%%S"
        ) else (
            set "CheckpointServices=%%S"
        )
    )
)

if defined CheckpointServices (
    set "CheckpointCheckResult=Problem"
    set "CheckpointCheckTips=Попробуйте удалить сервисы Check Point ^(!CheckpointServices!^)."
) else (
    set "CheckpointCheckResult=Ok"
)

REM === Поиск сервисов SmartByte ===
set "SmartByteCheckResult=Ok"
set "SmartByteServices="
set "SmartByteCheckTips="
for /f "tokens=2 delims=:" %%a in ('sc query 2^>NUL ^| findstr /I "SERVICE_NAME:" ^| findstr /I "SmartByte"') do (
    set "SmartByteServiceName=%%a"
    set "SmartByteServiceName=!SmartByteServiceName: =!"
    if defined SmartByteServices (
        set "SmartByteServices=!SmartByteServices!,!SmartByteServiceName!"
    ) else (
        set "SmartByteServices=!SmartByteServiceName!"
    )
)

if defined SmartByteServices (
    set "SmartByteCheckResult=Problem"
    set "SmartByteCheckTips=Отключите/удалите сервисы SmartByte ^(!SmartByteServices!^) ."
) else (
    set "SmartByteCheckResult=Ok"
)

REM === Поиск VPN сервисов ===
set "VPNCheckResult=Ok"
set "VPNServices="
set "VPNCheckTips="
for /f "tokens=2 delims=:" %%a in ('sc query 2^>NUL ^| findstr /I "SERVICE_NAME:" ^| findstr /I "VPN"') do (
    set "VPNServiceName=%%a"
    set "VPNServiceName=!VPNServiceName: =!"
    if defined VPNServices (
        set "VPNServices=!VPNServices!,!VPNServiceName!"
    ) else (
        set "VPNServices=!VPNServiceName!"
    )
)

if defined VPNServices (
    set "VPNCheckResult=Problem"
    set "VPNCheckTips=VPN должен быть выключен ^(!VPNServices!^)"
) else (
    set "VPNCheckResult=Ok"
)

REM === Проверка DNS серверов ===
set "DNSCheckResult=Ok"
set "DNSCheckTips="
set "dnsfound=0"
set "dns_configured=0"

REM Проверяем наличие настроенных DNS серверов (WMIC, затем PowerShell как запасной вариант)
for /f "skip=1 tokens=*" %%a in ('wmic nicconfig where "IPEnabled=true" get DNSServerSearchOrder /format:table 2^>NUL') do (
    echo %%a | findstr /r /c:"[0-9]" >nul
    if !errorlevel!==0 (
        set "dns_configured=1"
        echo %%a | findstr /i "192\.168\." >nul
        if !errorlevel!==0 (
            set "dnsfound=1"
        )
    )
)

IF !dns_configured!==0 (
    chcp 850 >nul 2>&1
    for /f "usebackq delims=" %%a in (`powershell -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='SilentlyContinue'; (Get-DnsClientServerAddress -AddressFamily IPv4 | Where-Object { $_.ServerAddresses } | ForEach-Object { $_.ServerAddresses } | Where-Object { $_ } | Select-Object -Unique)"`) do (
        chcp 65001 >nul 2>&1
        set "dns_configured=1"
        echo %%a | findstr /i "192\.168\." >nul
        if !errorlevel!==0 (
            set "dnsfound=1"
        )
    )
)

REM Если DNS не настроены или используются локальные DNS
if !dns_configured!==0 (
    set "DNSCheckResult=Problem"
    set "DNSCheckTips=DNS не настроены. Задайте публичные DNS ^(8.8.8.8, 8.8.4.4^)"
) else if !dnsfound!==1 (
    set "DNSCheckResult=Problem"
    set "DNSCheckTips=Локальные DNS ^(192.168.x.x^). Задайте публичные DNS ^(8.8.8.8, 8.8.4.4^)"
) else (
    set "DNSCheckResult=Ok"
)

REM === Проверка IPv6 (должен быть выключен) ===
set "IPv6CheckResult=Ok"
set "IPv6CheckTips="
set "IPv6EnabledStatus=False"

REM Проверяем статус IPv6 на всех АКТИВНЫХ (Status=Up) адаптерах.
REM Если хотя бы на одном адаптере галочка стоит, возвращаем True.
chcp 850 >nul 2>&1
for /f "usebackq tokens=*" %%A in (`powershell -NoProfile -Command "if (@(Get-NetAdapter | Where-Object { $_.Status -eq 'Up' } | Get-NetAdapterBinding -ComponentID ms_tcpip6 | Where-Object { $_.Enabled -eq $true }).Count -gt 0) { Write-Output 'True' } else { Write-Output 'False' }"`) do (
    chcp 65001 >nul 2>&1
    set "IPv6EnabledStatus=%%A"
)

if "!IPv6EnabledStatus!"=="True" (
    set "IPv6CheckResult=Problem"
    set "IPv6CheckTips=IPv6 включен. Уберите галочку 'IP версии 6' в свойствах сетевого адаптера."
) else (
    set "IPv6CheckResult=Ok"
)

REM === Итоговая проверка ===
set "TotalCheck=Ok"
set "ProblemDetails="
set "ProblemTips="

REM Проверяем все результаты проверок (Добавлен IPv6CheckResult)
for %%V in (BaseFilteringEngineCheckResult AdguardCheckResult KillerCheckResult IntelCheckResult CheckpointCheckResult SmartByteCheckResult VPNCheckResult DNSCheckResult IPv6CheckResult) do (
    if "!%%V!"=="Problem" (
        set "TotalCheck=Problem"
        if defined ProblemDetails (
            set "ProblemDetails=!ProblemDetails!, %%V"
        ) else (
            set "ProblemDetails=%%V"
        )
        REM Находим соответствующие советы (Добавлен IPv6CheckTips)
        REM Обратите внимание: имя переменной совета должно совпадать с проверкой (CheckResult -> CheckTips) для логики ниже, 
        REM но в вашем скрипте имена уже сопоставлены вручную, поэтому просто добавляем в список.
        for %%T in (BaseFilteringEngineCheckTips AdguardCheckTips KillerCheckTips IntelCheckTips CheckpointCheckTips SmartByteCheckTips VPNCheckTips DNSCheckTips IPv6CheckTips) do (
            REM Хитрость вашего скрипта: он ищет соответствие имен переменных. 
            REM Чтобы это сработало для IPv6, имя переменной результата и совета должны иметь схожий префикс.
            REM В данном случае: IPv6CheckResult и IPv6CheckTips.
            
            REM Логика сопоставления (упрощенно, так как %%V содержит полное имя переменной результата):
            if "%%V"=="IPv6CheckResult" if "%%T"=="IPv6CheckTips" (
                 if defined ProblemTips (
                    set "ProblemTips=!ProblemTips! !%%T!"
                ) else (
                    set "ProblemTips=!%%T!"
                )
            )
            
            REM Ваш оригинальный блок сопоставления для остальных переменных:
            if "%%V"=="%%~nT" ( 
                if not "%%V"=="IPv6CheckResult" (
                    if defined ProblemTips (
                        set "ProblemTips=!ProblemTips! !%%T!"
                    ) else (
                        set "ProblemTips=!%%T!"
                    )
                )
            )
        )
    )
)

REM Exit early if running in silent mode (called from main menu)
if "%SilentMode%"=="1" goto :eof

REM Настройка размера консоли в зависимости от наличия проблем
if "!TotalCheck!"=="Problem" (
    mode con: cols=92 lines=35 >nul 2>&1
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
tasklist | find /i "Winws" >nul
if %errorlevel% equ 0 (
    echo    ^│ %COL%[92m√ %COL%[37mWinws.exe: %COL%[92mЗапущен                                                              %COL%[36m^│
) else (
    echo    ^│ %COL%[91mX %COL%[37mWinws.exe: Не запущен                                                           %COL%[36m^│
)

sc qc WinDivert >nul 2>&1
if %errorlevel% equ 0 (
    echo    ^│ %COL%[92m√ %COL%[37mWinDivert: %COL%[92mУстановлен                                                           %COL%[36m^│
) else (
    sc qc monkey >nul 2>&1
    if !errorlevel! equ 0 (
        echo    ^│ %COL%[92m√ %COL%[37mmonkey: %COL%[92mУстановлен                                                              %COL%[36m^│
    ) else (
        echo    ^│ %COL%[91mX %COL%[37mWinDivert: Не установлен                                                        %COL%[36m^│
    )
)

REM if "%Auto-update%"=="1" (
REM     echo    ^│ %COL%[92m√ %COL%[37mАвтообновление: %COL%[92mВключено                                                        %COL%[36m^│
REM     set "AutoUpdateTextParam=Выключить"
REM     set "AutoUpdateStatus=On"
REM ) else (
REM     echo    ^│ %COL%[91mX %COL%[37mАвтообновление: Выключено                                                       %COL%[36m^│
REM     set "AutoUpdateTextParam=Включить"
REM     set "AutoUpdateStatus=Off"
REM )
echo    ^│                                                                                   ^│
echo    ^│ %COL%[37mВерсии:                                                                           %COL%[36m^│
echo    ^│ %COL%[90m───────────────────────────────────────────────────────────────────────────────── %COL%[36m^│

if "%UpdateNeed%"=="Yes" (
    echo    ^│ %COL%[37mGoodbyeZapret: %COL%[91m%Current_GoodbyeZapret_version% %COL%[92m^(→ %Actual_GoodbyeZapret_version%^)                                                    %COL%[36m^│
) else (
    echo    ^│ %COL%[37mGoodbyeZapret: %COL%[92m%Current_GoodbyeZapret_version%                                                              %COL%[36m^│
)

REM     echo    ^│ %COL%[37mWinws:         %COL%[92m%Current_Winws_version%                                                                 %COL%[36m^│
echo    └───────────────────────────────────────────────────────────────────────────────────┘
echo.
:: Вывод результатов

if "%TotalCheck%"=="Problem" (
    echo     %COL%[91mЕсть замечания по использованию GoodbyeZapret%COL%[37m
    echo     └ 
    for %%V in (BaseFilteringEngine Adguard Killer Checkpoint SmartByte VPN DNS) do (
        set "CheckResult=!%%VCheckResult!"
        set "CheckTips=!%%VCheckTips!"
        if "!CheckResult!"=="Problem" (
            echo       - %%V:
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
echo    %COL%[90m^[ %COL%[32mF %COL%[90m^] %COL%[32mПоддержать разработку проекта
echo    %COL%[90m^[ %COL%[32mT %COL%[90m^] %COL%[32mОткрыть telegram канал
echo.
echo    %COL%[90m^[ %COL%[36mU %COL%[90m^] %COL%[90mПереустановить GoodbyeZapret
echo    %COL%[90m^[ %COL%[36mR %COL%[90m^] %COL%[90mБыстрый перезапуск и очистка WinDivert
echo    %COL%[90m^[ %COL%[36mB %COL%[90m^] %COL%[90mВернуться в главное меню
if "%UpdateNeed%"=="Yes" (
    echo    %COL%[90m^[ %COL%[36mU %COL%[90m^] %COL%[93mОбновить до актуальной версии
)
echo.
echo.
set /p "choice=%DEL%   %COL%[90m:> "

REM Handle menu choices with proper error checking
if /i "%choice%"=="B" (
    call :ResizeMenuWindow
    set "choice=" && goto MainMenu
)

if /i "%choice%"=="и" (
    call :ResizeMenuWindow
    set "choice=" && goto MainMenu
)

if /i "%choice%"=="U" set "choice=" && goto FullUpdate
if /i "%choice%"=="г" set "choice=" && goto FullUpdate

if /i "%choice%"=="C" set "choice=" && goto CDN_BypassLevelSelector
if /i "%choice%"=="с" set "choice=" && goto CDN_BypassLevelSelector

if /i "%choice%"=="T" set "choice=" && goto OpenTelegram
if /i "%choice%"=="е" set "choice=" && goto OpenTelegram

if /i "%choice%"=="R" set "choice=" && goto QuickRestart
if /i "%choice%"=="к" set "choice=" && goto QuickRestart

if /i "%choice%"=="F" set "choice=" && start https://pay.cloudtips.ru/p/b98d1870
if /i "%choice%"=="а" set "choice=" && start https://pay.cloudtips.ru/p/b98d1870

REM Handle update option only if update is needed
if "%UpdateNeed%"=="Yes" (
    if /i "%choice%"=="U" (
        if exist "%ParentDirPath%\tools\Updater.exe" (
            start "Update GoodbyeZapret" "%ParentDirPath%\tools\Updater.exe"
        ) else (
            echo    %COL%[91mОшибка: Updater.exe не найден%COL%[37m
            timeout /t 3 >nul
        )
    )
    if /i "%choice%"=="г" (
        if exist "%ParentDirPath%\tools\Updater.exe" (
            start "Update GoodbyeZapret" "%ParentDirPath%\tools\Updater.exe"
        ) else (
            echo    %COL%[91mОшибка: Updater.exe не найден%COL%[37m
            timeout /t 3 >nul
        )
    )
)


goto CurrentStatus

:OpenTelegram
start https://t.me/+QUADX-YqFUJhM2Fi
goto CurrentStatus

:QuickRestart
    cls
    if not defined COL (
        for /F "tokens=1,2 delims=#" %%a in ('"prompt #$H#$E# & echo on & for %%b in (1) do rem"') do (set "DEL=%%a" & set "COL=%%b")
    )
    echo.
    echo    %COL%[36mВыполняется быстрый перезапуск и очистка WinDivert...%COL%[37m
    
    sc query "GoodbyeZapret" >nul 2>&1
    if %errorlevel% neq 0 (
        echo    %COL%[91mСлужба GoodbyeZapret не установлена%COL%[37m
        timeout /t 2 >nul 2>&1
        if defined QuickRestartFromMainMenu (
            set "QuickRestartFromMainMenu="
            goto MainMenu
        ) else (
            goto CurrentStatus
        )
    )

    echo    %COL%[90mОстановка службы GoodbyeZapret...%COL%[37m
    net stop "GoodbyeZapret" >nul 2>&1

    echo    %COL%[90mОстановка GoodbyeZapretTray...%COL%[37m
    taskkill /F /IM GoodbyeZapretTray.exe >nul 2>&1
    schtasks /end /tn "GoodbyeZapretTray" >nul 2>&1

    tasklist /FI "IMAGENAME eq winws.exe" 2>NUL | find /I /N "winws.exe" >NUL
    if not errorlevel 1 (
        echo    %COL%[90mОстановка winws.exe...%COL%[37m
        taskkill /F /IM winws.exe >nul 2>&1
        taskkill /F /IM winws2.exe >nul 2>&1
    )

    for %%S in (WinDivert WinDivert14 monkey) do (
        sc query "%%S" >nul 2>&1
        if !errorlevel! equ 0 (
            echo    %COL%[90mОстановка %%S...%COL%[37m
            net stop "%%S" >nul 2>&1
        )
    )

    echo    %COL%[90mОчистка DNS-кэша...%COL%[37m
    ipconfig /flushdns >nul 2>&1

    echo    %COL%[90mЗапуск службы GoodbyeZapret...%COL%[37m
    sc start "GoodbyeZapret" >nul 2>&1
    echo    %COL%[92mПерезапуск выполнен успешно%COL%[37m
    timeout /t 2 >nul 2>&1
    echo    %COL%[90mЗапуск службы GoodbyeZapretTray    ...%COL%[37m
    if exist "%ParentDirPath%\tools\tray\GoodbyeZapretTray.exe" (
        schtasks /run /tn "GoodbyeZapretTray" >nul 2>&1
    )
    if defined QuickRestartFromMainMenu (
        set "QuickRestartFromMainMenu="
        goto MainMenu
    ) else (
        goto CurrentStatus
    )

:FullUpdate
REM === Update Updater.exe ===
set "UpdaterPath=%ParentDirPath%\tools\Updater.exe"

if exist "%UpdaterPath%" (
    del /f /q "%UpdaterPath%" >nul 2>&1
)

echo [INFO ] %TIME% - Downloading Updater.exe...
if not defined CURL (
if exist "%ParentDirPath%\tools\curl\curl.exe" (
    set CURL="%ParentDirPath%\tools\curl\curl.exe"
) else (
    set "CURL=curl"
    )
)
%CURL% -g -L -s -o "%UpdaterPath%" "https://github.com/ALFiX01/GoodbyeZapret/raw/refs/heads/main/Files/Updater/Updater.exe"

if exist "%UpdaterPath%" (
    echo [INFO ] %TIME% - Updater.exe downloaded successfully
) else (
    echo [ERROR] %TIME% - Failed to download Updater.exe
)
REM === Start Updater.exe ===
start "Update GoodbyeZapret" "%ParentDirPath%\tools\Updater.exe"
exit


REM РЕЖИМ УСТАНОВКИ
:install_screen
IF "%WiFi%" == "Off" (
    cls
    echo.
    echo   Error 01: No internet connection.
    timeout /t 4 >nul 2>&1
    goto MainMenu
)

set "Assistant_version=0.3"
REM mode con: cols=112 lines=38 >nul 2>&1
mode con: cols=80 lines=28 >nul 2>&1
REM Цветной текст
if not defined COL (
    for /F "tokens=1,2 delims=#" %%a in ('"prompt #$H#$E# & echo on & for %%b in (1) do rem"') do (set "DEL=%%a" & set "COL=%%b")
)
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
if not exist "%ParentDirPath%" (
    md "%ParentDirPath%"
)
echo        ^[*^] Скачивание файлов GoodbyeZapret...

%CURL% -g -L -# -o %TEMP%\GoodbyeZapret.zip "https://github.com/ALFiX01/GoodbyeZapret/raw/refs/heads/main/Files/GoodbyeZapret.zip"
if errorlevel 1 (
    echo %COL%[91m ^[*^] Ошибка: Не удалось скачать GoodbyeZapret.zip ^(Код: %errorlevel%^) %COL%[90m
)

echo        ^[*^] Скачивание Updater.exe...
%CURL% -g -L -# -o "%ParentDirPath%\tools\Updater.exe" "https://github.com/ALFiX01/GoodbyeZapret/raw/refs/heads/main/Files/Updater/Updater.exe"
 if errorlevel 1 (
    echo         %COL%[91m ^[*^] Ошибка: Не удалось скачать Updater.exe ^(Код: %errorlevel%^) %COL%[90m
    echo         %COL%[93m ^[*^] Установка продолжится, но обновление может не работать.%COL%[90m
    REM Не выходим, так как основной zip скачался
)


if exist "%TEMP%\GoodbyeZapret.zip" (
    echo        ^[*^] Распаковка файлов
    chcp 850 >nul 2>&1
    powershell -NoProfile Expand-Archive '%TEMP%\GoodbyeZapret.zip' -DestinationPath '%ParentDirPath%' >nul 2>&1
    chcp 65001 >nul 2>&1
    if exist "%ParentDirPath%" (
        echo        ^[*^] Местоположение GoodbyeZapret: %ParentDirPath%
    )
) else (
    echo        %COL%[91m ^[*^] Error: File not found: %TEMP%\GoodbyeZapret.zip %COL%[90m
    timeout /t 5 >nul
    exit
)

echo        ^[*^] Создание ярлыка на рабочем столе...
chcp 850 >nul 2>&1
powershell "$WshShell = New-Object -comObject WScript.Shell; $Shortcut = $WshShell.CreateShortcut([Environment]::GetFolderPath('Desktop') + '\GoodbyeZapret.lnk'); $Shortcut.TargetPath = '%ParentDirPath%\launcher.bat'; $Shortcut.Save()"
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
if not defined CURL (
if exist "%ParentDirPath%\tools\curl\curl.exe" (
    set CURL="%ParentDirPath%\tools\curl\curl.exe"
) else (
    set "CURL=curl"
    )
)
%CURL% -g -L -o "%ParentDirPath%\bin\PatchNote.txt" "https://raw.githubusercontent.com/ALFiX01/GoodbyeZapret/refs/heads/main/Files/PatchNote.txt"
for /f %%A in ('type "%ParentDirPath%\bin\PatchNote.txt" ^| find /c /v ""') do set "PatchNoteLines=%%A"
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
type "%ParentDirPath%\bin\PatchNote.txt"
echo.
echo.
echo  %COL%[90m ────────────────────────────────────────────────────────────────────────────
REM echo  %COL%[36m Выберите действие:
echo.
echo                      %COL%[92m ^[U^]%COL%[37m Обновить  / %COL%[91m ^[B^]%COL%[37m Пропустить
echo.
set /p "choice=%DEL%   %COL%[90m:> "
if /i "%choice%"=="B" ( mode con: cols=92 lines=%ListBatCount%
set "UpdateNeed=Yes"
goto MainMenu )
if /i "%choice%"=="и" ( mode con: cols=92 lines=%ListBatCount%
set "UpdateNeed=Yes"
goto MainMenu )
if /i "%choice%"=="U" ( goto FullUpdate )
if /i "%choice%"=="г" ( goto FullUpdate )
goto Update_Need_screen


:ConfigAutoFinder
REM Цветной текст
for /F "tokens=1,2 delims=#" %%a in ('"prompt #$H#$E# & echo on & for %%b in (1) do rem"') do (set "DEL=%%a" & set "COL=%%b")
start "" "%ParentDirPath%\tools\Config_Check\auto_find_working_config.exe"
goto MainMenu

:ResizeMenuWindow
REM === Пересчет размеров консоли для меню ===

REM Базовый путь должен совпадать с логикой вывода в меню
set "BasePath=%ParentDirPath%"

REM === Подсчет количества конфигов ===
set "PresetCount=0"
set "CustomCount=0"
for /f %%A in ('dir /b /a:-d "%BasePath%\configs\Preset\*.bat" 2^>nul ^| find /v /c ""') do set "PresetCount=%%A"
for /f %%A in ('dir /b /a:-d "%BasePath%\configs\Custom\*.bat" 2^>nul ^| find /v /c ""') do set "CustomCount=%%A"
set /a BatCount=PresetCount+CustomCount

REM === Пагинация ===
if not defined Page set "Page=1"
if not defined PageSize set "PageSize=21"
set /a TotalPages=(BatCount+PageSize-1)/PageSize
if %TotalPages% lss 1 set /a TotalPages=1
if %Page% lss 1 set /a Page=1
if %Page% gtr %TotalPages% set /a Page=%TotalPages%

set /a StartIndex=(Page-1)*PageSize+1
set /a EndIndex=StartIndex+PageSize-1

REM === Сколько элементов реально видно на текущей странице ===
set /a Remaining=BatCount-StartIndex+1
if %Remaining% lss 0 set /a Remaining=0
if %Remaining% gtr %PageSize% set /a Remaining=%PageSize%
set /a VisibleOnPage=Remaining

REM === Базовое количество строк интерфейса ===
set /a BaseLines=25
set /a ListBatCount=BaseLines+VisibleOnPage

REM === Пагинация: если страниц больше одной, добавляем 2 строки ===
if %TotalPages% gtr 1 set /a ListBatCount+=2

REM === Проверка сервисов для YesCount ===
set "YesCount=0"
sc query "GoodbyeZapret" >nul 2>&1
if %errorlevel% equ 0 ( set /a YesCount+=1 ) else ( set /a YesCount-=1 )

tasklist | find /i "Winws" >nul 2>&1
if %errorlevel% equ 0 set /a YesCount+=1

for %%S in ("WinDivert" "WinDivert14" "monkey") do (
    sc query %%~S 2>nul | find /I "RUNNING" >nul
    if not errorlevel 1 (
        set /a YesCount+=1
        goto :DoneStartCheck_YesCount
    )
)

:DoneStartCheck_YesCount

REM === Предупреждения о сети и проверке файлов ===
if /i "%WiFi%"=="Off" set /a ListBatCount+=1
REM if /i "%CheckStatus%"=="FileCheckError" set /a ListBatCount+=1
if not defined CheckStatus set "CheckStatus=WithoutChecked"
if not "%CheckStatus%"=="Checked" if not "%CheckStatus%"=="WithoutChecked" set /a ListBatCount+=1

REM === Корректировка по YesCount ===
if /I "%TotalCheck%"=="Problem" (
    REM Ветка для Problem (оставляю как у тебя)
    if %YesCount% equ 2 ( set /a ListBatCount+=1 )
) else (
    if %YesCount% equ 1 (
        set /a ListBatCount+=2
    ) else if %YesCount% equ 2 (
        REM ничего не добавляем
    ) else (
        set /a ListBatCount-=1
    )
)

REM === Ограничения по высоте ===
set /a MaxWinLines=52
set /a MinWinLines=28
if %ListBatCount% gtr %MaxWinLines% set /a ListBatCount=%MaxWinLines%
if %ListBatCount% lss %MinWinLines% set /a ListBatCount=%MinWinLines%


REM === DEBUG ===
set "DEBUG_mode=0"
if "%DEBUG_mode%"=="1" (
 echo WiFi - %WiFi%
 echo CheckStatus - %CheckStatus%
 echo YesCount - %YesCount%
 echo TotalCheck - %TotalCheck%
 echo BatCount - %BatCount%
 echo ListBatCount - %ListBatCount%
 pause
) 

mode con: cols=92 lines=%ListBatCount%
goto :eof


:OpenInstructions
if exist "%ParentDirPath%\instructions.html" (
    start "" "%ParentDirPath%\instructions.html"
) else (
    echo Файл инструкции не найден: %ParentDirPath%\instructions.html
    timeout /t 3 >nul
)
goto MainMenu


:OpenConfiguratorInstructions
if exist "%ParentDirPath%\tools\config_builder\Configurator-Instructions.html" (
    start "" "%ParentDirPath%\tools\config_builder\Configurator-Instructions.html"
) else (
    echo Файл инструкции не найден: %ParentDirPath%\tools\config_builder\Configurator-Instructions.html
    timeout /t 3 >nul
)
goto ConfiguratorMenu


:: Функция: чтение значения
:: Использование: call :ReadConfig НАЗВАНИЕ_КЛЮЧА [ЗНАЧЕНИЕ_ПО_УМОЛЧАНИЮ]
:ReadConfig
if "%Configurator%"=="1" (
    set "CONFIG_FILE=%USERPROFILE%\AppData\Roaming\GoodbyeZapret\configurator.txt" 
) else (
    set "CONFIG_FILE=%USERPROFILE%\AppData\Roaming\GoodbyeZapret\config.txt" 
)
REM echo [LOG] Старт функции :ReadConfig для %~1, файл: %CONFIG_FILE%

set "RES="
set "FOUND=0"

if not exist "%CONFIG_FILE%" (
    echo [LOG][ОШИБКА] Файл конфига не найден
    REM Если конфига нет, сразу пробуем применить дефолтное значение
    goto :CheckDefault
)

for /f "usebackq tokens=1,* delims==" %%A in ("%CONFIG_FILE%") do (
    if /i "%%A"=="%~1" (
        set "RES=%%B"
        set "FOUND=1"
    )
)

:: БАРЬЕР: Перенос переменной RES из setlocal в основной контекст
if defined RES (
    for /f "delims=" %%V in ("%RES%") do (
        set "RES=%%V"
        set "FOUND=1"
    )
) else (
    set "RES="
    set "FOUND=0"
)

:CheckDefault
:: Если ключ не найден (FOUND=0), проверяем аргумент %2 (значение по умолчанию)
if "%FOUND%"=="0" (
    if not "%~2"=="" (
        set "RES=%~2"
        REM echo [LOG] Ключ не найден, установлено значение по умолчанию: %~2
    ) else (
        set "RES=NotFound"
        REM echo [LOG] Ключ не найден, дефолт не задан, RES=NotFound
    )
)

:: Очистка кавычек, если значение было найдено или задано дефолтом (и не равно NotFound)
if not "%RES%"=="NotFound" if defined RES (
  if not "%RES%"=="%RES:"=%" set "RES=%RES:~1,-1%"
)

:: Финальное присвоение результата переменной с именем ключа
set "%~1=%RES%"

set "Configurator=0"
goto :eof


:: Функция: запись значения с пробелами
:WriteConfig
set "CONFIG_FILE=%USERPROFILE%\AppData\Roaming\GoodbyeZapret\config.txt"
:: Вызов: call :WriteConfig VariableName "Значение с пробелами"

set "TEMP_FILE=%~dp0config_temp.txt"
if exist "%TEMP_FILE%" del "%TEMP_FILE%"

set "found=0"

:: 1) Сохраняем ключ ДО shift
set "KEY=%~1"

:: 2) Значение берём из %~2 (одно аргументированное значение в кавычках)
set "VALUE=%~2"

:: Переписываем файл, меняя только нужную строку
for /f "usebackq tokens=1,* delims==" %%A in ("%CONFIG_FILE%") do (
    if /i "%%~A"=="!KEY!" (
        >>"%TEMP_FILE%" echo %%A="!VALUE!"
        set "found=1"
    ) else (
        >>"%TEMP_FILE%" echo %%A=%%B
    )
)

:: 3) Если ключа не было — добавляем
if "!found!"=="0" (
    >>"%TEMP_FILE%" echo !KEY!="!VALUE!"
)

move /y "%TEMP_FILE%" "%CONFIG_FILE%" >nul 2>&1
goto :eof

:DelConfig
set "CONFIG_FILE=%USERPROFILE%\AppData\Roaming\GoodbyeZapret\config.txt"
set "TEMP_FILE=%~dp0config_temp.txt"
if exist "%TEMP_FILE%" del "%TEMP_FILE%"
set "DELVAR=%~1"
for /f "tokens=1,* delims==" %%A in ("%CONFIG_FILE%") do (
    if /i not "%%A"=="!DELVAR!" (
        echo %%A=%%B>> "%TEMP_FILE%"
    )
)
move /y "%TEMP_FILE%" "%CONFIG_FILE%" >nul 2>&1
goto :eof


:: Функция: инициализация конфига из реестра
:InitConfigFromRegistry

REM Переключаемся на кодовую страницу, поддерживающую символы Unicode
chcp 850 >nul 2>&1
for /f "usebackq delims=" %%a in (`powershell -Command "(Get-CimInstance Win32_OperatingSystem).Caption"`) do (
    chcp 65001 >nul 2>&1    
    set "WinVersion=%%a"

    REM Проверяем, является ли система Windows 11
    echo !WinVersion! | find /i "Windows 11" >nul
    if not errorlevel 1 (
        set "WinVer=Windows 11"
        reg add "HKEY_CURRENT_USER\Software\ALFiX inc.\GoodbyeZapret" /t REG_SZ /v "WinVer" /d "11" /f >nul 2>&1
    ) else (
        REM Проверяем, является ли система Windows 10
        echo !WinVersion! | find /i "Windows 10" >nul
        if not errorlevel 1 (
            set "WinVer=Windows 10"
            reg add "HKEY_CURRENT_USER\Software\ALFiX inc.\GoodbyeZapret" /t REG_SZ /v "WinVer" /d "10" /f >nul 2>&1
        )
    )
)


set "CONFIG_FILE=%USERPROFILE%\AppData\Roaming\GoodbyeZapret\config.txt"
set "VARS=WinVer FirstLaunch GoodbyeZapret_Version GoodbyeZapret_Config GoodbyeZapret_ConfigPatch GoodbyeZapret_LastStartConfig GoodbyeZapret_LastWorkConfig GoodbyeZapret_Version_code"
set "REG_KEY=HKCU\Software\ALFiX inc.\GoodbyeZapret"

if exist "%CONFIG_FILE%" goto :eof

echo Инициализация config.txt из реестра...
if not exist "%USERPROFILE%\AppData\Roaming\GoodbyeZapret" mkdir "%USERPROFILE%\AppData\Roaming\GoodbyeZapret"
> "%CONFIG_FILE%" type nul

for %%V in (%VARS%) do (
    for /f "skip=2 tokens=2,*" %%A in ('reg query "%REG_KEY%" /v "%%V" 2^>nul') do (
        if not "%%B"=="" >>"%CONFIG_FILE%" echo %%V="%%B"
    )
)
goto :eof

:CDN_BypassLevelSelector
REM Проверяем текущее значение и переключаем на следующее по циклу
if /i "%CDN_BypassLevel%"=="off" (
    set "CDN_BypassLevel=base"
) else if /i "%CDN_BypassLevel%"=="base" (
    set "CDN_BypassLevel=full"
) else (
    REM Если значение max или переменная пуста/неизвестна — сбрасываем в off
    set "CDN_BypassLevel=off"
)

REM Записываем новое значение в реестр (системные переменные)
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /v "CDN_BypassLevel" /t REG_SZ /d "%CDN_BypassLevel%" /f >nul

if defined CDN_BypassLevel (
    call :WriteConfig CDN_LVL "%CDN_BypassLevel%"
) else (
    echo ^[ERROR^] CDN_BypassLevel не определен
)

goto :MainMenu_without_ui_info


:ConfiguratorMenu
title Zapret Configurator

REM Check GoodbyeZapret service status
sc query "GoodbyeZapret" >nul 2>&1
if %errorlevel% equ 0 (
    set "GoodbyeZapretStart=Yes"
) else (
    set "GoodbyeZapretStart=No"
)

set "ENGN=2"
set "Configurator=1" & call :ReadConfig ENGN 2

:UpdateLimits
:: Получаем количество стратегий в зависимости от движка
"%ParentDirPath%\tools\config_builder\builder.exe" --engine !ENGN! --get-limits > "%ParentDirPath%\tools\config_builder\config_builder_limits.bat"

if exist "%ParentDirPath%\tools\config_builder\config_builder_limits.bat" (
    call "%ParentDirPath%\tools\config_builder\config_builder_limits.bat"
    del "%ParentDirPath%\tools\config_builder\config_builder_limits.bat"
) else (
    echo [ERROR] Could not load limits
    set "MAX_YouTube=0" & set "MAX_YouTubeGoogleVideo=0" & set "MAX_YouTubeQuic=0" & set "MAX_Twitch=0" & set "MAX_Discord=0" & set "MAX_DiscordUpdate=0" & set "MAX_DiscordQuic=0" & set "MAX_blacklist=0" & set "MAX_STUN=0" & set "MAX_CDN=0" & set "MAX_AmazonTCP=0" & set "MAX_AmazonUDP=0" & set "MAX_Custom=0"
)

set "Configurator=1" & call :ReadConfig YT 1
set "Configurator=1" & call :ReadConfig YTGV 1
set "Configurator=1" & call :ReadConfig YTQ 1
set "Configurator=1" & call :ReadConfig TW 0
set "Configurator=1" & call :ReadConfig DSUPD 1
set "Configurator=1" & call :ReadConfig DS 1
set "Configurator=1" & call :ReadConfig DSQ 1
set "Configurator=1" & call :ReadConfig BL 0
set "Configurator=1" & call :ReadConfig STUN 1
set "Configurator=1" & call :ReadConfig CDN 1
set "Configurator=1" & call :ReadConfig AMZTCP 1
set "Configurator=1" & call :ReadConfig AMZUDP 1
set "Configurator=1" & call :ReadConfig CUSTOM 0
set "Configurator=1" & call :ReadConfig CDN_LVL base

:MENU
cls
title GoodbyeZapret - Конфигуратор стратегий

:: Список всех переменных для проверки
set "CHECK_LIST=YT YTGV YTQ TW DSUPD DS DSQ BL STUN CDN AMZTCP AMZUDP CUSTOM"

:: Цикл по каждой переменной из списка
for %%V in (%CHECK_LIST%) do (
    :: Если значение переменной меньше 10
    if !%%V! LSS 10 (
        set "%%V_sp=  "
    ) else (
        set "%%V_sp= "
    )
)

echo.
echo    %COL%[36m╔════════════════════════════════════════════════════════════════════════════════════╗
echo    %COL%[36m║%COL%[90m [КЛАВИША]   Модуль               Текущее      ^(доступно^)                           %COL%[36m║
echo    %COL%[36m╠════════════════════════════════════════════════════════════════════════════════════╣

echo    %COL%[36m║   %COL%[96m[  1 ]%COL%[37m  YouTube                    %COL%[92m!YT!          !YT_sp!%COL%[90m(0-!MAX_YouTube!)
echo    %COL%[36m║   %COL%[96m[  2 ]%COL%[37m  YouTube GoogleVideo        %COL%[92m!YTGV!          !YTGV_sp!%COL%[90m(0-!MAX_YouTubeGoogleVideo!)
echo    %COL%[36m║   %COL%[96m[  3 ]%COL%[37m  YouTube QUIC               %COL%[92m!YTQ!          !YTQ_sp!%COL%[90m(0-!MAX_YouTubeQuic!)
echo    %COL%[36m║ 
echo    %COL%[36m║   %COL%[96m[  4 ]%COL%[37m  Twitch                     %COL%[92m!TW!          !TW_sp!%COL%[90m(0-!MAX_Twitch!)
echo    %COL%[36m║
echo    %COL%[36m║   %COL%[96m[  5 ]%COL%[37m  Discord Update             %COL%[92m!DSUPD!          !DSUPD_sp!%COL%[90m(0-!MAX_DiscordUpdate!)
echo    %COL%[36m║   %COL%[96m[  6 ]%COL%[37m  Discord                    %COL%[92m!DS!          !DS_sp!%COL%[90m(0-!MAX_Discord!)
echo    %COL%[36m║   %COL%[96m[  7 ]%COL%[37m  Discord QUIC               %COL%[92m!DSQ!          !DSQ_sp!%COL%[90m(0-!MAX_DiscordQuic!)
echo    %COL%[36m║   %COL%[96m[  8 ]%COL%[37m  STUN                       %COL%[92m!STUN!          !STUN_sp!%COL%[90m(0-!MAX_STUN!)
echo    %COL%[36m║
echo    %COL%[36m║   %COL%[96m[  9 ]%COL%[37m  CDN                        %COL%[92m!CDN!          !CDN_sp!%COL%[90m(0-!MAX_CDN!)
echo    %COL%[36m║   %COL%[96m[ 10 ]%COL%[37m  Amazon CDN TCP             %COL%[92m!AMZTCP!          !AMZTCP_sp!%COL%[90m(0-!MAX_AmazonTCP!)
echo    %COL%[36m║   %COL%[96m[ 11 ]%COL%[37m  Amazon CDN UDP             %COL%[92m!AMZUDP!          !AMZUDP_sp!%COL%[90m(0-!MAX_AmazonUDP!)
echo    %COL%[36m║
echo    %COL%[36m║   %COL%[96m[ 12 ]%COL%[37m  Blacklist                  %COL%[92m!BL!          !BL_sp!%COL%[90m(0-!MAX_blacklist!)
echo    %COL%[36m║   %COL%[96m[ 13 ]%COL%[37m  Личные списки              %COL%[92m!CUSTOM!          !CUSTOM_sp!%COL%[90m(0-!MAX_custom!)

echo    %COL%[36m╠════════════════════════════════════════════════════════════════════════════════════
echo    %COL%[36m║   %COL%[96m[ L ]%COL%[37m   Уровень CDN              %COL%[92m!CDN_LVL!       %COL%[90m(off/base/full)
echo    %COL%[36m║   %COL%[96m[ E ]%COL%[37m   Движок                  %COL%[92mZapret!ENGN!    %COL%[90m(Zapret1/Zapret2)
echo    %COL%[36m╚════════════════════════════════════════════════════════════════════════════════════╝
echo.
echo    %COL%[92m[ S ] Запустить обход
echo    %COL%[94m[ A ] Автоподбор стратегии
echo    %COL%[92m[ С ] Быстро проверить обход
echo    %COL%[91m[ K ] Остановить обход
if exist "%ParentDirPath%\Configs\Custom\ConfiguratorFix.bat" (
    if "%GoodbyeZapretStart%"=="Yes" (
        echo    %COL%[91m[ D ] Удалить из автозапуска
    ) else (
        echo    %COL%[92m[ U ] Добавить в автозапуск
    )
)

echo.
echo    %COL%[90m[ L ] Открыть личные списки  
echo    %COL%[90m[ I ] Инструкция   
echo    %COL%[90m[ B ] Назад
echo.
set /p "opt=%DEL%   %COL%[90m:> "


if /i "%opt%"=="S" goto START
if /i "%opt%"=="ы" goto START
if /i "%opt%"=="A" goto ConfiguratorAutoPicker
if /i "%opt%"=="ф" goto ConfiguratorAutoPicker
if /i "%opt%"=="K" goto KILL
if /i "%opt%"=="л" goto KILL

if /i "%opt%"=="cfg" explorer "%USERPROFILE%\AppData\Roaming\GoodbyeZapret\configurator.txt"
if /i "%opt%"=="I" goto OpenConfiguratorInstructions
if /i "%opt%"=="ш" goto OpenConfiguratorInstructions
if /i "%opt%"=="L" goto OpenPersonalList
if /i "%opt%"=="д" goto OpenPersonalList
if /i "%opt%"=="B" goto MainMenu_without_ui_info
if /i "%opt%"=="И" goto MainMenu_without_ui_info
if /i "%opt%"=="C" goto START_with_checking
if /i "%opt%"=="с" goto START_with_checking

if exist "%ParentDirPath%\Configs\Custom\ConfiguratorFix.bat" (
    if /i "%opt%"=="U" ( 
    cls
    echo.
    echo  [*] Сборка стратегий в конфиг на Zapret!ENGN!...
    "%ParentDirPath%\tools\config_builder\builder.exe" --engine !ENGN! --youtube !YT! --youtubegooglevideo !YTGV! --youtubequic !YTQ! --twitch !TW! --discordupdate !DSUPD! --discord !DS! --discordquic !DSQ! --blacklist !BL! --stun !STUN! --cdn !CDN! --amazontcp !AMZTCP! --amazonudp !AMZUDP! --custom !CUSTOM! --cdn-level !CDN_LVL!
        set "batFile=ConfiguratorFix.bat"
        set "batRel=Custom\ConfiguratorFix.bat"
        set "batPath=Custom"
        set "PanelBack=Configurator"
        call :remove_service_before_installing
        call :install_GZ_service
        call :WriteConfig GoodbyeZapret_Config "ConfiguratorFix"
    )
if /i "%opt%"=="г" (
        cls
        echo.
        echo  [*] Сборка стратегий в конфиг на Zapret!ENGN!...
        "%ParentDirPath%\tools\config_builder\builder.exe" --engine !ENGN! --youtube !YT! --youtubegooglevideo !YTGV! --youtubequic !YTQ! --twitch !TW! --discordupdate !DSUPD! --discord !DS! --discordquic !DSQ! --blacklist !BL! --stun !STUN! --cdn !CDN! --amazontcp !AMZTCP! --amazonudp !AMZUDP! --custom !CUSTOM! --cdn-level !CDN_LVL!
        set "batFile=ConfiguratorFix.bat"
        set "batRel=Custom\ConfiguratorFix.bat"
        set "batPath=Custom"
        set "PanelBack=Configurator"
        call :remove_service_before_installing
        call :install_GZ_service
        call :WriteConfig GoodbyeZapret_Config "ConfiguratorFix"
    )
)

if exist "%ParentDirPath%\Configs\Custom\ConfiguratorFix.bat" (
    if /i "%opt%"=="D" ( 
        set "PanelBack=Configurator"
        call :remove_service
    )
if /i "%opt%"=="в" (
        set "PanelBack=Configurator"
        call :remove_service
    )
)

:: Проверки ввода с использованием полученных лимитов
if "%opt%"=="1" (
    set /p val="%DEL%   Введите стратегию для YouTube (0-!MAX_YouTube!): "
    :: Простая проверка: если введено больше макс, сбрасываем (опционально)
    if !val! gtr !MAX_YouTube! (
        echo  Неверное значение. Максимум - !MAX_YouTube!
        pause
    ) else (
        set "YT=!val!"
    )
    goto MENU
)

if "%opt%"=="2" (
    set /p val="%DEL%   Введите стратегию для YouTube GoogleVideo (0-!MAX_YouTubeGoogleVideo!): "
    :: Простая проверка: если введено больше макс, сбрасываем (опционально)
    if !val! gtr !MAX_YouTubeGoogleVideo! (
        echo  Неверное значение. Максимум - !MAX_YouTubeGoogleVideo!
        pause
    ) else (
        set "YTGV=!val!"
    )
    goto MENU
)

if "%opt%"=="3" (
    set /p val="%DEL%   Введите стратегию для YouTube Quic (0-!MAX_YouTubeQuic!): "
    :: Простая проверка: если введено больше макс, сбрасываем (опционально)
    if !val! gtr !MAX_YouTubeQuic! (
        echo  Неверное значение. Максимум - !MAX_YouTubeQuic!
        pause
    ) else (
        set "YTQ=!val!"
    )
    goto MENU
)

if "%opt%"=="4" (
    set /p val="%DEL%   Введите стратегию для Twitch (0-!MAX_Twitch!): "
    :: Простая проверка: если введено больше макс, сбрасываем (опционально)
    if !val! gtr !MAX_Twitch! (
        echo  Неверное значение. Максимум - !MAX_Twitch!
        pause
    ) else (
        set "TW=!val!"
    )
    goto MENU
)

if "%opt%"=="5" (
    set /p val="%DEL%   Введите стратегию для Discord Update (0-!MAX_DiscordUpdate!): "
    if !val! gtr !MAX_DiscordUpdate! (
        echo  Неверное значение. Максимум - !MAX_DiscordUpdate!
        pause
    ) else (
        set "DSUPD=!val!"
    )
    goto MENU
)

if "%opt%"=="6" (
    set /p val="%DEL%   Введите стратегию для Discord (0-!MAX_Discord!): "
    if !val! gtr !MAX_Discord! (
        echo  Неверное значение. Максимум - !MAX_Discord!
        pause
    ) else (
        set "DS=!val!"
    )
    goto MENU
)

if "%opt%"=="7" (
    set /p val="%DEL%   Введите стратегию для Discord Quic (0-!MAX_DiscordQuic!): "
    if !val! gtr !MAX_DiscordQuic! (
        echo  Неверное значение. Максимум - !MAX_DiscordQuic!
        pause
    ) else (
        set "DSQ=!val!"
    )
    goto MENU
)

if "%opt%"=="8" (
    set /p val="%DEL%   Введите стратегию для STUN (0-!MAX_STUN!): "
    if !val! gtr !MAX_STUN! (
        echo  Неверное значение. Максимум - !MAX_STUN!
        pause
    ) else (
        set "STUN=!val!"
    )
    goto MENU
)

if "%opt%"=="9" (
    set /p val="%DEL%   Введите стратегию для CDN (0-!MAX_CDN!): "
    if !val! gtr !MAX_CDN! (
        echo  Неверное значение. Максимум - !MAX_CDN!
        pause
    ) else (
        set "CDN=!val!"
    )
    goto MENU
)

if "%opt%"=="10" (
    set /p val="%DEL%   Введите стратегию для CDN Amazon TCP (0-!MAX_AmazonTCP!): "
    if !val! gtr !MAX_AmazonTCP! (
        echo  Неверное значение. Максимум - !MAX_AmazonTCP!
        pause
    ) else (
        set "AMZTCP=!val!"
    )
    goto MENU
)

if "%opt%"=="11" (
    set /p val="%DEL%   Введите стратегию для CDN Amazon UDP (0-!MAX_AmazonUDP!): "
    if !val! gtr !MAX_AmazonUDP! (
        echo  Неверное значение. Максимум - !MAX_AmazonUDP!
        pause
    ) else (
        set "AMZUDP=!val!"
    )
    goto MENU
)

if "%opt%"=="12" (
    set /p val="%DEL%   Введите стратегию для Blacklist (0-!MAX_blacklist!): "
    if !val! gtr !MAX_blacklist! (
        echo  Неверное значение. Максимум - !MAX_blacklist!
        pause
    ) else (
        set "BL=!val!"
    )
    goto MENU
)

if "%opt%"=="13" (
    set /p val="%DEL%   Введите стратегию для личных списков (0-!MAX_Custom!): "
    if !val! gtr !MAX_Custom! (
        echo  Неверное значение. Максимум - !MAX_Custom!
        pause
    ) else (
        set "CUSTOM=!val!"
    )
    goto MENU
)

if /i "%opt%"=="L" (set /p CDN_LVL="%DEL%   Задайте CDN (off/base/full): " & goto MENU)
if /i "%opt%"=="д" (set /p CDN_LVL="%DEL%   Задайте CDN (off/base/full): " & goto MENU)

if /i "%opt%"=="E" (
    if "!ENGN!"=="1" (set "ENGN=2") else (set "ENGN=1")
    :: Сбрасываем значения, так как в другом движке другие лимиты
    set "YT=1" & set "YTGV=1" & set "YTQ=1" & set "TW=0" & set "DS=1" & set "DSUPD=1" & set "BL=1" & set "STUN=1" & set "CDN=1" & set "AMZTCP=1" & set "AMZUDP=1" & set "CUSTOM=0"
    goto UpdateLimits
)
if /i "%opt%"=="у" (
    if "!ENGN!"=="1" (set "ENGN=2") else (set "ENGN=1")
    :: Сбрасываем значения, так как в другом движке другие лимиты
    set "YT=1" & set "YTGV=1" & set "YTQ=1" & set "TW=0" & set "DS=1" & set "DSUPD=1" & set "BL=1" & set "STUN=1" & set "CDN=1" & set "AMZTCP=1" & set "AMZUDP=1" & set "CUSTOM=0"
    goto UpdateLimits
)

goto MENU

:ConfiguratorAutoPicker
cls
title GoodbyeZapret - Автоподбор стратегий
echo.
echo  %COL%[36mВыберите модуль для автоподбора:
echo.
echo    %COL%[96m[  1 ]%COL%[37m  YouTube
echo    %COL%[96m[  2 ]%COL%[37m  YouTube GoogleVideo
echo    %COL%[96m[  3 ]%COL%[37m  YouTube QUIC
echo.
echo    %COL%[96m[  4 ]%COL%[37m  Twitch
echo.
echo    %COL%[96m[  5 ]%COL%[37m  Discord Update
echo    %COL%[96m[  6 ]%COL%[37m  Discord
echo    %COL%[96m[  7 ]%COL%[37m  Discord QUIC
echo    %COL%[96m[  8 ]%COL%[37m  STUN
echo.
echo    %COL%[96m[  9 ]%COL%[37m  CDN
echo    %COL%[96m[ 10 ]%COL%[37m  Amazon CDN TCP
echo    %COL%[96m[ 11 ]%COL%[37m  Amazon CDN UDP
echo.
echo    %COL%[96m[ 12 ]%COL%[37m  Blacklist
echo    %COL%[96m[ 13 ]%COL%[37m  Личные списки
echo.
echo    %COL%[90m[  0 ] Назад
echo.
set /p "AutoChoice=%DEL%   %COL%[90m:> "

set "AutoVar="
set "AutoMaxVar="
set "AutoName="

if "%AutoChoice%"=="0" goto MENU
if "%AutoChoice%"=="1"  (set "AutoVar=YT"     & set "AutoMaxVar=MAX_YouTube"            & set "AutoName=YouTube")
if "%AutoChoice%"=="2"  (set "AutoVar=YTGV"   & set "AutoMaxVar=MAX_YouTubeGoogleVideo" & set "AutoName=YouTube GoogleVideo")
if "%AutoChoice%"=="3"  (set "AutoVar=YTQ"    & set "AutoMaxVar=MAX_YouTubeQuic"        & set "AutoName=YouTube QUIC")
if "%AutoChoice%"=="4"  (set "AutoVar=TW"     & set "AutoMaxVar=MAX_Twitch"             & set "AutoName=Twitch")
if "%AutoChoice%"=="5"  (set "AutoVar=DSUPD"  & set "AutoMaxVar=MAX_DiscordUpdate"      & set "AutoName=Discord Update")
if "%AutoChoice%"=="6"  (set "AutoVar=DS"     & set "AutoMaxVar=MAX_Discord"            & set "AutoName=Discord")
if "%AutoChoice%"=="7"  (set "AutoVar=DSQ"    & set "AutoMaxVar=MAX_DiscordQuic"        & set "AutoName=Discord QUIC")
if "%AutoChoice%"=="8"  (set "AutoVar=STUN"   & set "AutoMaxVar=MAX_STUN"               & set "AutoName=STUN")
if "%AutoChoice%"=="9"  (set "AutoVar=CDN"    & set "AutoMaxVar=MAX_CDN"                & set "AutoName=CDN")
if "%AutoChoice%"=="10" (set "AutoVar=AMZTCP" & set "AutoMaxVar=MAX_AmazonTCP"          & set "AutoName=Amazon CDN TCP")
if "%AutoChoice%"=="11" (set "AutoVar=AMZUDP" & set "AutoMaxVar=MAX_AmazonUDP"          & set "AutoName=Amazon CDN UDP")
if "%AutoChoice%"=="12" (set "AutoVar=BL"     & set "AutoMaxVar=MAX_blacklist"          & set "AutoName=Blacklist")
if "%AutoChoice%"=="13" (set "AutoVar=CUSTOM" & set "AutoMaxVar=MAX_Custom"             & set "AutoName=Личные списки")

if not defined AutoVar goto ConfiguratorAutoPicker

call set "AutoMax=%%%AutoMaxVar%%%"
if not defined AutoMax set "AutoMax=0"
call set "AutoPrev=%%%AutoVar%%%"
set "AutoPrev_YT=!YT!"
set "AutoPrev_YTGV=!YTGV!"
set "AutoPrev_YTQ=!YTQ!"
set "AutoPrev_TW=!TW!"
set "AutoPrev_DSUPD=!DSUPD!"
set "AutoPrev_DS=!DS!"
set "AutoPrev_DSQ=!DSQ!"
set "AutoPrev_STUN=!STUN!"
set "AutoPrev_CDN=!CDN!"
set "AutoPrev_AMZTCP=!AMZTCP!"
set "AutoPrev_AMZUDP=!AMZUDP!"
set "AutoPrev_BL=!BL!"
set "AutoPrev_CUSTOM=!CUSTOM!"
call :ConfiguratorAutoBackup

set "AutoZeroOthers=1"
echo.
echo  %COL%[36mОбнулить остальные стратегии на время автоподбора?%COL%[90m [Enter=Да / N=Нет]
set /p "AutoZeroChoice=%DEL%   %COL%[90m:> "
if /i "!AutoZeroChoice!"=="N" set "AutoZeroOthers=0"
if /i "!AutoZeroChoice!"=="Н" set "AutoZeroOthers=0"
set /a AutoIndex=0
set "AutoAlmostList="
set /a AutoAlmostCount=0

:ConfiguratorAutoLoop
if !AutoIndex! gtr !AutoMax! goto ConfiguratorAutoNotFound
call :ConfiguratorAutoSetTestVars
call :ConfiguratorAutoApply
call :ConfiguratorAutoCheck

if "!AutoCheckResult!"=="0" goto ConfiguratorAutoSave
if "!AutoCheckResult!"=="1" (
    set /a AutoAlmostCount+=1
    set "AutoAlmostList=!AutoAlmostList!!AutoIndex! "
)
set /a AutoIndex+=1
goto ConfiguratorAutoLoop

:ConfiguratorAutoSave
call :ConfiguratorAutoRestoreAll
for %%V in (!AutoVar!) do set "%%V=!AutoIndex!"
call :ConfiguratorAutoApply
echo.
echo  %COL%[92m[OK]%COL%[37m Найдена рабочая стратегия %COL%[92m!AutoIndex!%COL%[37m для %COL%[92m!AutoName!%COL%[37m.
pause >nul
goto MENU

:ConfiguratorAutoCancel
call :ConfiguratorAutoRestoreAll
set "%AutoVar%=!AutoPrev!"
set /a AutoIndex=AutoPrev
call :ConfiguratorAutoApply
echo.
echo  %COL%[90mВозвращено предыдущее значение %COL%[92m!AutoPrev!%COL%[90m для %COL%[92m!AutoName!%COL%[90m.
pause >nul
goto MENU

:ConfiguratorAutoNotFound
call :ConfiguratorAutoRestoreAll
set "%AutoVar%=!AutoPrev!"
set /a AutoIndex=AutoPrev
call :ConfiguratorAutoApply
echo.
echo  %COL%[91m[WARN]%COL%[37m Подходящая стратегия не найдена (0-!AutoMax!).
if !AutoAlmostCount! gtr 0 (
    echo  %COL%[93m[INFO]%COL%[37m Почти рабочие стратегии: %COL%[92m!AutoAlmostList!%COL%[37m
)
echo  %COL%[90mВозвращено значение %COL%[92m!AutoPrev!%COL%[90m для %COL%[92m!AutoName!%COL%[90m.
pause >nul
goto MENU

:ConfiguratorAutoApply
cls
echo.
echo  [*] Модуль: !AutoName!  Стратегия: !AutoIndex! (0-!AutoMax!)
echo  [*] Сборка стратегий в конфиг на Zapret!ENGN!...
"%ParentDirPath%\tools\config_builder\builder.exe" --engine !ENGN! --youtube !YT! --youtubegooglevideo !YTGV! --youtubequic !YTQ! --twitch !TW! --discordupdate !DSUPD! --discord !DS! --discordquic !DSQ! --blacklist !BL! --stun !STUN! --cdn !CDN! --amazontcp !AMZTCP! --amazonudp !AMZUDP! --custom !CUSTOM! --cdn-level !CDN_LVL!

if exist %ParentDirPath%\Configs\Custom\ConfiguratorFix.bat (
	set "currentDir=%~dp0"
    echo  [*] Запуск...
    explorer "%ParentDirPath%\Configs\Custom\ConfiguratorFix.bat"
)
echo  [*] Проверяем процесс обхода...
timeout /t 3 >nul 2>&1
if !ENGN! equ 1 (
    tasklist | find /i "Winws.exe" >nul
        if errorlevel 1 (
            echo.
            echo %COL%[91m ОШИБКА: Процесс обхода ^(Winws.exe^) НЕ ЗАПУЩЕН. %COL%[37m
            echo.
            timeout /t 3 >nul 2>&1
        ) else (
            echo  [*] Процесс обхода работает, ошибки не обнаружены
            timeout /t 1 >nul 2>&1
        )
) else (
    tasklist | find /i "Winws2.exe" >nul
        if errorlevel 1 (
            echo.
            echo %COL%[91m ОШИБКА: Процесс обхода ^(Winws2.exe^) НЕ ЗАПУЩЕН. %COL%[37m
            echo.
            timeout /t 3 >nul 2>&1
        ) else (
            echo  [*] Процесс обхода работает, ошибки не обнаружены
            timeout /t 1 >nul 2>&1
        )
)
exit /b

:ConfiguratorAutoSetTestVars
if "!AutoZeroOthers!"=="1" (
    for %%V in (YT YTGV YTQ TW DSUPD DS DSQ STUN CDN AMZTCP AMZUDP BL CUSTOM) do set "%%V=0"
)
for %%V in (!AutoVar!) do set "%%V=!AutoIndex!"
exit /b

:ConfiguratorAutoRestoreAll
set "YT=!AutoPrev_YT!"
set "YTGV=!AutoPrev_YTGV!"
set "YTQ=!AutoPrev_YTQ!"
set "TW=!AutoPrev_TW!"
set "DSUPD=!AutoPrev_DSUPD!"
set "DS=!AutoPrev_DS!"
set "DSQ=!AutoPrev_DSQ!"
set "STUN=!AutoPrev_STUN!"
set "CDN=!AutoPrev_CDN!"
set "AMZTCP=!AutoPrev_AMZTCP!"
set "AMZUDP=!AutoPrev_AMZUDP!"
set "BL=!AutoPrev_BL!"
set "CUSTOM=!AutoPrev_CUSTOM!"
exit /b

:ConfiguratorAutoBackup
set "AutoBackupFile=%USERPROFILE%\AppData\Roaming\GoodbyeZapret\autopick_backup.txt"
if not exist "%USERPROFILE%\AppData\Roaming\GoodbyeZapret" md "%USERPROFILE%\AppData\Roaming\GoodbyeZapret" >nul 2>&1
> "%AutoBackupFile%" echo # GoodbyeZapret AutoPick backup
>>"%AutoBackupFile%" echo Date=%DATE% Time=%TIME%
>>"%AutoBackupFile%" echo ENGN="!ENGN!"
>>"%AutoBackupFile%" echo YT="!YT!"
>>"%AutoBackupFile%" echo YTGV="!YTGV!"
>>"%AutoBackupFile%" echo YTQ="!YTQ!""
>>"%AutoBackupFile%" echo TW="!TW!""
>>"%AutoBackupFile%" echo DSUPD="!DSUPD!"
>>"%AutoBackupFile%" echo DS="!DS!"
>>"%AutoBackupFile%" echo DSQ="!DSQ!""
>>"%AutoBackupFile%" echo STUN="!STUN!"
>>"%AutoBackupFile%" echo CDN="!CDN!"
>>"%AutoBackupFile%" echo AMZTCP="!AMZTCP!""
>>"%AutoBackupFile%" echo AMZUDP="!AMZUDP!"
>>"%AutoBackupFile%" echo BL="!BL!""
>>"%AutoBackupFile%" echo CUSTOM="!CUSTOM!"
exit /b

:ConfiguratorAutoCheck
set "AutoCheckResult=2"
set "AutoGitPath=/ALFiX01/GoodbyeZapret/main/GoodbyeZapret_Version"
set "AutoDomainFileDefault=%ParentDirPath%\tools\Config_Check\domains.txt"
set "AutoDomainFile=%AutoDomainFileDefault%"
set "AutoModuleFile="
set "AutoDomainUsedModule=0"

if /i "!AutoVar!"=="YT"    set "AutoModuleFile=%ParentDirPath%\tools\Config_Check\domains\youtube.txt"
if /i "!AutoVar!"=="YTGV"  set "AutoModuleFile=%ParentDirPath%\tools\Config_Check\domains\youtube_googlevideo.txt"
if /i "!AutoVar!"=="YTQ"   set "AutoModuleFile=%ParentDirPath%\tools\Config_Check\domains\youtube_quic.txt"
if /i "!AutoVar!"=="TW"    set "AutoModuleFile=%ParentDirPath%\tools\Config_Check\domains\twitch.txt"
if /i "!AutoVar!"=="DSUPD" set "AutoModuleFile=%ParentDirPath%\tools\Config_Check\domains\discord_update.txt"
if /i "!AutoVar!"=="DS"    set "AutoModuleFile=%ParentDirPath%\tools\Config_Check\domains\discord.txt"
if /i "!AutoVar!"=="DSQ"   set "AutoModuleFile=%ParentDirPath%\tools\Config_Check\domains\discord_quic.txt"
if /i "!AutoVar!"=="STUN"  set "AutoModuleFile=%ParentDirPath%\tools\Config_Check\domains\stun.txt"
if /i "!AutoVar!"=="CDN"   set "AutoModuleFile=%ParentDirPath%\tools\Config_Check\domains\cdn.txt"
if /i "!AutoVar!"=="AMZTCP" set "AutoModuleFile=%ParentDirPath%\tools\Config_Check\domains\amazon_tcp.txt"
if /i "!AutoVar!"=="AMZUDP" set "AutoModuleFile=%ParentDirPath%\tools\Config_Check\domains\amazon_udp.txt"
if /i "!AutoVar!"=="BL"    set "AutoModuleFile=%ParentDirPath%\tools\Config_Check\domains\blacklist.txt"
if /i "!AutoVar!"=="CUSTOM" set "AutoModuleFile=%ParentDirPath%\tools\Config_Check\domains\custom.txt"

if defined AutoModuleFile if exist "!AutoModuleFile!" (
    set "AutoDomainFile=!AutoModuleFile!"
    set "AutoDomainUsedModule=1"
)

if not defined CURL (
    if exist "%ParentDirPath%\tools\curl\curl.exe" (
        set CURL="%ParentDirPath%\tools\curl\curl.exe"
    ) else (
        set "CURL=curl"
    )
)

:ConfiguratorAutoCheck_ReadDomains
set "AutoFailed=0"
set "AutoTotal=0"
set "AutoFailedDomains="
echo.
if "!AutoDomainUsedModule!"=="1" (
    echo  [*] Автопроверка доменов ^(модульный список^)...
) else (
    echo  [*] Автопроверка доменов...
)

if exist "!AutoDomainFile!" (
    for /f "usebackq delims=" %%D in ("!AutoDomainFile!") do (
        set "AutoLine=%%D"
        if defined AutoLine (
            for /f "tokens=* delims= " %%L in ("!AutoLine!") do set "AutoLine=%%L"
            if "!AutoLine:~0,3!"=="ï»¿" set "AutoLine=!AutoLine:~3!"
            if defined AutoLine if not "!AutoLine:~0,1!"=="#" call :ConfiguratorAutoCheckOne "!AutoLine!"
        )
    )
) else (
    for %%D in (rr6---sn-jvhnu5g-n8vy.googlevideo.com i.ytimg.com/vi/dQw4w9WgXcQ/maxresdefault.jpg discord.com cloudflare.com aws.amazon.com raw.githubusercontent.com) do (
        call :ConfiguratorAutoCheckOne "%%D"
    )
)

if !AutoTotal! LEQ 0 (
    if "!AutoDomainUsedModule!"=="1" (
        set "AutoDomainFile=!AutoDomainFileDefault!"
        set "AutoDomainUsedModule=0"
        goto ConfiguratorAutoCheck_ReadDomains
    )
    set "AutoCheckResult=2"
    echo  ^[WARN^] Список доменов пуст.
    exit /b
)

if !AutoFailed! EQU 0 (
    set "AutoCheckResult=0"
    echo  ^[OK^] Все домены доступны.
    exit /b
)

if !AutoFailed! EQU 1 (
    set "AutoCheckResult=1"
    echo  ^[WARN^] Недоступен 1 домен: !AutoFailedDomains!
    exit /b
)

set "AutoCheckResult=2"
echo  ^[FAIL^] Недоступно доменов: !AutoFailed!
exit /b

:ConfiguratorAutoCheckOne
set "AutoUrlRaw=%~1"
if /i "!AutoUrlRaw!"=="raw.githubusercontent.com" set "AutoUrlRaw=raw.githubusercontent.com!AutoGitPath!"
set "AutoUrl=!AutoUrlRaw!"
if /i not "!AutoUrl:~0,7!"=="http://" if /i not "!AutoUrl:~0,8!"=="https://" set "AutoUrl=https://!AutoUrl!"
set /a AutoTotal+=1

set "AutoCode="
for /f "delims=" %%H in ('
    curl -L -k --connect-timeout 1 -m 6 -s -o NUL -w "%%{http_code}" "!AutoUrl!"
') do set "AutoCode=%%H"

if not defined AutoCode (
    set /a AutoFailed+=1
    set "AutoFailedDomains=!AutoFailedDomains!!AutoUrlRaw! "
    exit /b
)

REM Если AutoCode остался 000 или пустой — значит связи нет вообще (ошибка curl)
if "!AutoCode!"=="000" goto :AutoCheckFail
if not defined AutoCode goto :AutoCheckFail

REM Если сервер ответил ЛЮБЫМ кодом (200, 302, 403, 404, 500) — домен жив.
REM Выходим как "успех"
exit /b

:AutoCheckFail
set /a AutoFailed+=1
set "AutoFailedDomains=!AutoFailedDomains!!AutoUrlRaw! "
exit /b

:START
cls
echo.

echo  [*] Сборка стратегий в конфиг на Zapret!ENGN!...
"%ParentDirPath%\tools\config_builder\builder.exe" --engine !ENGN! --youtube !YT! --youtubegooglevideo !YTGV! --youtubequic !YTQ! --twitch !TW! --discordupdate !DSUPD! --discord !DS! --discordquic !DSQ! --blacklist !BL! --stun !STUN! --cdn !CDN! --amazontcp !AMZTCP! --amazonudp !AMZUDP! --custom !CUSTOM! --cdn-level !CDN_LVL!

if exist %ParentDirPath%\Configs\Custom\ConfiguratorFix.bat (
	set "currentDir=%~dp0"
    echo  [*] Запуск...
    explorer "%ParentDirPath%\Configs\Custom\ConfiguratorFix.bat"
)
echo  [*] Проверяем процесс обхода...
timeout /t 3 >nul 2>&1
if !ENGN! equ 1 (
    tasklist | find /i "Winws.exe" >nul
        if errorlevel 1 (
            echo.
            echo %COL%[91m ОШИБКА: Процесс обхода ^(Winws.exe^) НЕ ЗАПУЩЕН. %COL%[37m
            echo.
            timeout /t 3 >nul 2>&1
        ) else (
            echo  [*] Процесс обхода работает, ошибки не обнаружены
            timeout /t 1 >nul 2>&1
        )
) else (
    tasklist | find /i "Winws2.exe" >nul
        if errorlevel 1 (
            echo.
            echo %COL%[91m ОШИБКА: Процесс обхода ^(Winws2.exe^) НЕ ЗАПУЩЕН. %COL%[37m
            echo.
            timeout /t 3 >nul 2>&1
        ) else (
            echo  [*] Процесс обхода работает, ошибки не обнаружены
            timeout /t 1 >nul 2>&1
        )
)
goto MENU

:START_with_checking
cls
echo.

echo  [*] Сборка стратегий в конфиг на Zapret!ENGN!...
"%ParentDirPath%\tools\config_builder\builder.exe" --engine !ENGN! --youtube !YT! --youtubegooglevideo !YTGV! --youtubequic !YTQ! --twitch !TW! --discordupdate !DSUPD! --discord !DS! --discordquic !DSQ! --blacklist !BL! --stun !STUN! --cdn !CDN! --amazontcp !AMZTCP! --amazonudp !AMZUDP! --custom !CUSTOM! --cdn-level !CDN_LVL!

if exist %ParentDirPath%\Configs\Custom\ConfiguratorFix.bat (
	set "currentDir=%~dp0"
    echo  [*] Запуск...
explorer "%ParentDirPath%\Configs\Custom\ConfiguratorFix.bat"
)
echo  [*] Проверяем процесс обхода...
timeout /t 3 >nul 2>&1
if !ENGN! equ 1 (
    tasklist | find /i "Winws.exe" >nul
        if errorlevel 1 (
            echo.
            echo %COL%[91m ОШИБКА: Процесс обхода ^(Winws.exe^) НЕ ЗАПУЩЕН. %COL%[37m
            echo.
            timeout /t 3 >nul 2>&1
        ) else (
            echo  [*] Процесс обхода работает, ошибки не обнаружены
            timeout /t 1 >nul 2>&1
        )
) else (
    tasklist | find /i "Winws2.exe" >nul
        if errorlevel 1 (
            echo.
            echo %COL%[91m ОШИБКА: Процесс обхода ^(Winws2.exe^) НЕ ЗАПУЩЕН. %COL%[37m
            echo.
            timeout /t 3 >nul 2>&1
        ) else (
            echo  [*] Процесс обхода работает, ошибки не обнаружены
            timeout /t 1 >nul 2>&1
        )
)
if exist "%ParentDirPath%\tools\Config_Check\config_check.exe" (
    cls
    echo %COL%[37m
    REM Цветной текст
    for /F "tokens=1,2 delims=#" %%a in ('"prompt #$H#$E# & echo on & for %%b in (1) do rem"') do (set "DEL=%%a" & set "COL=%%b")
    "%ParentDirPath%\tools\Config_Check\config_check.exe" "!batFile!"
)
goto MENU

:KILL
echo  [*] Завершаю работу winws...
taskkill /F /IM winws.exe /T >nul 2>&1
taskkill /F /IM winws2.exe /T >nul 2>&1
goto MENU

:OpenPersonalList
explorer "%ParentDirPath%\lists\ipset-custom.txt"
explorer "%ParentDirPath%\lists\list-custom.txt"
goto MENU

:FinlandDiscordHostSelector
set "HOSTS=%hostspath%"

if /i "%FinlandDiscordHost%"=="off" (
    rem На всякий случай сначала чистим старый блок, потом добавляем свежий
    call :ui_info "Добавляю записи в файл hosts..."
    call :AddFinlandDiscordHost

    timeout /t 2 >nul
    ipconfig /flushdns >nul

) else (
    call :ui_info "Удаляю записи из файла hosts..."
    call :RemoveFinlandDiscordHosts

    timeout /t 2 >nul
    ipconfig /flushdns >nul
)

goto MenuBypassSettings_without_ui_info


:AddFinlandDiscordHost
>>"%HOSTS%" echo ### Discord Finland Media Servers BEGIN
rem Добавляем основные домены через прокси
>>"%HOSTS%" echo 23.227.38.74 discord.com
>>"%HOSTS%" echo 23.227.38.74 gateway.discord.gg
>>"%HOSTS%" echo 23.227.38.74 updates.discord.com
>>"%HOSTS%" echo 23.227.38.74 cdn.discordapp.com
>>"%HOSTS%" echo 23.227.38.74 status.discord.com
>>"%HOSTS%" echo 23.227.38.74 cdn.prod.website-files.com

rem Добавляем голосовые сервера (finland)
for /l %%N in (10001,1,10199) do (
    >>"%HOSTS%" echo 104.25.158.178 finland%%N.discord.media
)
>>"%HOSTS%" echo ### Discord Finland Media Servers END
goto :eof


:RemoveFinlandDiscordHosts
chcp 850 >nul 2>&1
rem Снимаем атрибут "Только чтение" для надежности
attrib -r "%HOSTS%"

rem Исправленная версия: читаем в переменную $txt, затем фильтруем и записываем
powershell -Command "$path = $env:windir + '\System32\drivers\etc\hosts'; $txt = Get-Content $path; $txt | Where-Object { $_ -notmatch 'Discord Finland Media Servers' -and $_ -notmatch 'finland.*\.discord\.media' -and $_ -notmatch '23\.227\.38\.74' } | Set-Content $path -Force"

chcp 65001 >nul 2>&1
goto :eof

:TwitchHostSelector
set "HOSTS=%hostspath%"

if /i "%TwitchHost%"=="off" (
    rem На всякий случай сначала чистим старый блок, потом добавляем свежий
    call :ui_info "Добавляю записи в файл hosts..."
    call :AddTwitchHosts

    timeout /t 2 >nul
    ipconfig /flushdns >nul

) else (
    call :ui_info "Удаляю записи из файла hosts..."
    call :RemoveTwitchHosts

    timeout /t 2 >nul
    ipconfig /flushdns >nul
)

goto MenuBypassSettings_without_ui_info


:AddTwitchHosts
>>"%HOSTS%" echo ### Twitch Servers BEGIN
>>"%HOSTS%" echo 185.68.247.42 usher.ttvnw.net
>>"%HOSTS%" echo 185.68.247.42 gql.twitch.tv
>>"%HOSTS%" echo ### Twitch Servers END
goto :eof


:RemoveTwitchHosts
chcp 850 >nul 2>&1
rem Сначала снимаем атрибут "Только чтение", если он есть, чтобы избежать ошибок доступа
attrib -r "%HOSTS%"

rem Исправленная команда: читаем в переменную $txt, затем фильтруем и сохраняем.
rem Это разрывает одновременное чтение и запись.
powershell -Command "$path = $env:windir + '\System32\drivers\etc\hosts'; $txt = Get-Content $path; $txt | Where-Object { $_ -notmatch 'Twitch Servers' -and $_ -notmatch '185.68.247.42' } | Set-Content $path -Force"

chcp 65001 >nul 2>&1
goto :eof


:YoutubeHostsSelector
set "HOSTS=%hostspath%"

if /i "%YoutubeHost%"=="off" (
    rem На всякий случай сначала чистим старый блок, потом добавляем свежий
    call :ui_info "Добавляю записи в файл hosts..."
    call :AddYoutubeHosts

    timeout /t 2 >nul
    ipconfig /flushdns >nul

) else (
    call :ui_info "Удаляю записи из файла hosts..."
    call :RemoveYoutubeHosts

    timeout /t 2 >nul
    ipconfig /flushdns >nul
)

goto MenuBypassSettings_without_ui_info

:AddYoutubeHosts
>>"%HOSTS%" echo ### YouTube TCP Servers BEGIN
>>"%HOSTS%" echo 142.250.117.93 www.youtube.com
>>"%HOSTS%" echo ### YouTube TCP Servers END
goto :eof

:RemoveYoutubeHosts
chcp 850 >nul 2>&1
rem Снимаем атрибут "Только чтение" для надежности
attrib -r "%HOSTS%"

rem Исправленная логика: читаем в $txt, потом пишем
powershell -NoProfile -ExecutionPolicy Bypass -Command "$p='%HOSTS%'; if(-not (Test-Path -LiteralPath $p)) { exit }; $t=Get-Content -LiteralPath $p -Raw -ErrorAction SilentlyContinue; if($null -eq $t){$t=''}; $re='(?ms)^\s*### YouTube TCP Servers BEGIN\s*$.*?^\s*### YouTube TCP Servers END\s*$\r?\n?'; $t=[regex]::Replace($t,$re,''); Set-Content -LiteralPath $p -Value $t -Force"

chcp 65001 >nul 2>&1
goto :eof

:timer_start
set start_time=%time%
goto :eof

:timer_end
set end_time=%time%

:: Парсинг начального времени
for /f "tokens=1-4 delims=:., " %%a in ("%start_time%") do (
    set /a start_h=%%a
    set /a start_m=100%%b %% 100
    set /a start_s=100%%c %% 100
    set /a start_ms=100%%d %% 100
)

:: Парсинг конечного времени
for /f "tokens=1-4 delims=:., " %%a in ("%end_time%") do (
    set /a end_h=%%a
    set /a end_m=100%%b %% 100
    set /a end_s=100%%c %% 100
    set /a end_ms=100%%d %% 100
)

:: Вычисление разницы
set /a total_ms=(%end_h%-%start_h%)*3600000 + (%end_m%-%start_m%)*60000 + (%end_s%-%start_s%)*1000 + (%end_ms%-%start_ms%)

echo Выполнение заняло: %total_ms% миллисекунд
goto :eof
