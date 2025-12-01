@echo off
:: Copyright (C) 2025 ALFiX, Inc.
:: Any tampering with the program code is forbidden (Запрещены любые вмешательства)

:: Получаем путь к родительской папке и проверяем на пробелы
for /f "delims=" %%A in ('powershell -NoProfile -Command "Split-Path -Parent \"%~f0\""') do set "ParentDirPathForCheck=%%A"

:: Извлекаем имя папки и проверяем на пробелы
for %%A in ("%ParentDirPathForCheck%") do set "FolderName=%%~nxA"

:: Проверка на пробелы
set "tempvar=%FolderName%"
echo."%tempvar%"| findstr /c:" " >nul && (
    echo WARN: The folder name contains spaces.
    pause
    exit /b
)

:: Метод C: fsutil dirty query %SystemDrive% (часто доступен даже на урезанных системах)
fsutil dirty query %SystemDrive% >nul 2>&1
if %errorlevel% neq 0 (
    echo  Requesting administrator privileges...
    powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs -ArgumentList '--elevated'" >nul 2>&1
    exit /b
)

:: Включаем для манипуляции переменными
setlocal EnableDelayedExpansion

set "ErrorCount=0"

:: Определяем архитектуру системы
IF "%PROCESSOR_ARCHITECTURE%"=="AMD64" (set "os_arch=64")
IF "%PROCESSOR_ARCHITECTURE%"=="x86" (set "os_arch=32")
IF DEFINED PROCESSOR_ARCHITEW6432 (set "os_arch=64")

if %os_arch%==32 (
    color f2
    echo Windows x86 detected. Nothing to do.
    echo Press any key for exit
    pause > nul
    exit /b
)

:: Получаем путь к родительской папке
for /f "delims=" %%A in ('powershell -NoProfile -Command "Split-Path -Parent '%~f0'"') do set "ParentDirPath=%%A"


:: Version information
set "Current_GoodbyeZapret_version=2.7.0"
set "Current_GoodbyeZapret_version_code=26NV01"
set "branch=Beta"
set "beta_code=1"

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
        start "" "%ParentDirPath%\launcher.bat"
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

rem Отключение "Предупреждение системы безопасности" 
reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Attachments" /v SaveZoneInformation 2>nul | find "0x1" >nul || (
    reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Attachments" /v SaveZoneInformation /t REG_DWORD /d 1 /f >nul 2>&1
    if not %ERRORLEVEL% equ 0 (
        call :ui_err "Error installing SaveZoneInformation"
        timeout /t 2 >nul
    )
)


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
if not "!ERRORLEVEL!"=="0" (
    echo.
    call :ui_err "Ошибка 02: DNS не отвечает или отсутствует доступ к интернету"
    echo   Проверьте подключение и настройки сети.
    set "WiFi=Off"
    goto :eof
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

REM Устанавливаем значения по умолчанию для конфигурации GoodbyeZapret
REM set "GoodbyeZapret_Current=Не выбран"
set "GoodbyeZapret_Config=Не выбран"
set "GoodbyeZapret_Old=Отсутствует"

REM Проверяем, существует ли служба GoodbyeZapret и получаем текущую конфигурацию
REM reg query "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\GoodbyeZapret" /v "Description" >nul 2>&1
REM if !errorlevel! equ 0 (
REM     for /f "tokens=2*" %%a in ('reg query "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\GoodbyeZapret" /v "Description" 2^>nul ^| find /i "Description"') do set "GoodbyeZapret_Current=%%b"
REM )

REM Проверяем старый конфиг в config-файле
call :ReadConfig GoodbyeZapret_OldConfig

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
    if %errorlevel% equ 0 (
        net stop "GoodbyeZapret" >nul 2>&1
        sc delete "GoodbyeZapret" >nul 2>&1
    )
    
    REM  winws.exe
    tasklist /FI "IMAGENAME eq winws.exe" 2>NUL | find /I /N "winws.exe" >NUL
    if not errorlevel 1 (
        taskkill /F /IM winws.exe >nul 2>&1
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
            del /F /Q "%ParentDirPath%\tools\tray\goodbyezapret_tray.log"
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


REM Проверьте старый конфиг в config-файле
call :ReadConfig GoodbyeZapret_OldConfig
set "GoodbyeZapret_Old=%GoodbyeZapret_OldConfig%"

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
:MainMenuWithoutUiInfo
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
tasklist | find /i "Winws" >nul
if %errorlevel% equ 0 (
    set "WinwsStart=Yes"
) else (
    set "WinwsStart=No"
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
    echo                       %COL%[91mВозможны проблемы в работе   ^[ ST ^] - подробнее%COL%[37m
)

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

set "hasActiveOrStarted=0"
for %%F in ("%ParentDirPath%\configs\Preset\*.bat" "%ParentDirPath%\configs\Custom\*.bat") do (
    set "ConfigName=%%~nF"
    if /i "!ConfigName!"=="%GoodbyeZapret_Config%" set "hasActiveOrStarted=1"
)

REM Modernized config enumeration ----------------------------------------------------
for %%F in ("%ParentDirPath%\configs\Preset\*.bat" "%ParentDirPath%\configs\Custom\*.bat") do (
    set /a "counter+=1"
    set "ConfigName=%%~nF"
    set "ConfigFull=%%~nxF"

    set "StatusText="
    set "StatusColor=%COL%[37m"

    if /i "!ConfigName!"=="%GoodbyeZapret_Config%" (
        set "StatusText=[Текущий]"
        set "StatusColor=%COL%[92m"
    ) else if /i "!ConfigName!"=="!GoodbyeZapret_LastWork!" (
        if "!hasActiveOrStarted!"=="0" (
            set "StatusText=[Работал лучше других]"
            set "StatusColor=%COL%[93m"
        )
    ) else if /i "!ConfigName!"=="%GoodbyeZapret_Old%" (
        set "StatusText=[Последний запущенный]"
        set "StatusColor=%COL%[93m"
    )

        REM Simple alignment for single-digit numbers
        if !counter! lss 10 (set "Pad= ") else (set "Pad=")

    if !counter! geq !StartIndex! if !counter! leq !EndIndex! (
        if defined StatusText (
            echo                  %COL%[36m!counter!.!Pad! %COL%[36m%%~nF !StatusColor!!StatusText!
        ) else (
            echo                  %COL%[36m!counter!.!Pad! %COL%[37m%%~nF
        )
    )

    set "file!counter!=!ConfigFull!"
)
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
    if not "%TotalCheck%"=="Problem" (
    echo                  %COL%[36m^[1-!counter!s^] %COL%[92mЗапустить конфиг
    echo                  %COL%[36m^[1-!counter!^] %COL%[92mУстановить конфиг в автозапуск
    echo                  %COL%[36m^[ AC ^] %COL%[37mАвтоподбор конфига
    echo                  %COL%[36m^[ ST ^] %COL%[37mСостояние GoodbyeZapret
    ) else (
    echo                  %COL%[36m^[1-!counter!s^] %COL%[92mЗапустить конфиг
    echo                  %COL%[36m^[1-!counter!^] %COL%[92mУстановить конфиг в автозапуск
    echo                  %COL%[36m^[ AC ^] %COL%[37mАвтоподбор конфига
    echo                  %COL%[36m^[ ST ^] %COL%[37mСостояние GoodbyeZapret
    )
) else (
    echo                  %COL%[36m^[ DS ^] %COL%[91mУдалить конфиг из автозапуска
    echo                  %COL%[36m^[ ST ^] %COL%[37mСостояние GoodbyeZapret
    if %YesCount% equ 2 echo                  %COL%[36m^[ RS ^] %COL%[37mБыстрый перезапуск и очистка WinDivert
)

REM ---- Pagination options ----
if %TotalPages% gtr 1 (
    echo.
    if %Page% lss %TotalPages% echo                  %COL%[36m^[ N ^] %COL%[37mСледующая страница с конфигами
    if %Page% gtr 1 echo                  %COL%[36m^[ B ^] %COL%[37mПредыдущая страница

)
REM ----------------------------

echo.
echo.
echo                                %COL%[90mВведите номер или действие
set /p "choice=%DEL%                                           %COL%[90m:> "

REM Handle user input with case-insensitive matching
if /i "%choice%"=="DS" goto remove_service
if /i "%choice%"=="вы" goto remove_service

if /i "%choice%"=="ST" goto CurrentStatus
if /i "%choice%"=="ые" goto CurrentStatus

if /i "%choice%"=="AC" goto ConfigAutoFinder
if /i "%choice%"=="фс" goto ConfigAutoFinder

if /i "%choice%"=="RC" goto QuickRestart
if /i "%choice%"=="кы" goto QuickRestart

if /i "%choice%"=="R" goto RR

REM --- Pagination input handling ---
if /i "%choice%"=="N" (
    set /a Page+=1
    goto MainMenu
)
if /i "%choice%"=="т" (
    set /a Page+=1
    goto MainMenu
)
if /i "%choice%"=="B" (
    if %Page% gtr 1 set /a Page-=1
    goto MainMenu
)
if /i "%choice%"=="и" (
    if %Page% gtr 1 set /a Page-=1
    goto MainMenu
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
    echo Ошибка: Файл конфигурации !batRel! не найден.
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

sc create "GoodbyeZapret" binPath= "cmd.exe /c \"\"%ParentDirPath%\configs\!batPath!\!batFile!\"\"" >nul 2>&1
sc config "GoodbyeZapret" start= auto >nul 2>&1

REM Извлекаем базовое имя файла (без папки и расширения) для записи в реестр/описание
for %%A in ("!batRel!") do set "BaseCfg=%%~nA"

REM reg add "HKCU\Software\ALFiX inc.\GoodbyeZapret" /t REG_SZ /v "GoodbyeZapret_Config" /d "!batPath!" /f >nul
REM reg add "HKCU\Software\ALFiX inc.\GoodbyeZapret" /t REG_SZ /v "GoodbyeZapret_ConfigPatch" /d "!BaseCfg!" /f >nul

call :WriteConfig GoodbyeZapret_Config "!BaseCfg!"
call :WriteConfig GoodbyeZapret_OldConfig "!BaseCfg!"
sc description GoodbyeZapret "!BaseCfg!" >nul
sc start "GoodbyeZapret" >nul
cls
echo.
call :ui_ok "!batFile! установлен в службу GoodbyeZapret"

set installing_service=0

if exist "%ParentDirPath%\tools\Config_Check\config_check.exe" (
    echo.
    REM Цветной текст
    for /F "tokens=1,2 delims=#" %%a in ('"prompt #$H#$E# & echo on & for %%b in (1) do rem"') do (set "DEL=%%a" & set "COL=%%b")
    "%ParentDirPath%\tools\Config_Check\config_check.exe" "!batFile!"
)
timeout /t 1 >nul 2>&1

tasklist | find /i "Winws.exe" >nul
if errorlevel 1 (
    echo.
    echo ОШИБКА: Процесс обхода ^(Winws.exe^) не запущен.
    echo.
    timeout /t 2 >nul 2>&1
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
    REM reg delete "HKCU\Software\ALFiX inc.\GoodbyeZapret" /v "GoodbyeZapret_Config" /f >nul 2>&1
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
            call :ui_ok "Удаление успешно завершено"
        ) else (
            call :ui_err "Ошибка при удалении службы"
        )
    )
    call :WriteConfig GoodbyeZapret_Config "Не выбран"
    REM reg delete "HKCU\Software\ALFiX inc.\GoodbyeZapret" /v "GoodbyeZapret_Config" /f >nul 2>&1
    timeout /t 1 >nul 2>&1
goto :install_GZ_service

:end
if !ErrorCount! equ 0 (
    REM Set default values for GoodbyeZapret configuration
    set "GoodbyeZapret_Config=Не выбран"
    set "GoodbyeZapret_Old=Отсутствует"
    REM Check if GoodbyeZapret service exists and get current configuration
    REM reg query "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\GoodbyeZapret" /v "Description" >nul 2>&1
        REM if !errorlevel! equ 0 ( for /f "tokens=2*" %%a in ('reg query "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\GoodbyeZapret" /v "Description" 2^>nul ^| find /i "Description"') do set "GoodbyeZapret_Current=%%b" )

    rem /// Check for old configuration via config ///
    call :ReadConfig GoodbyeZapret_OldConfig
    if "%GoodbyeZapret_OldConfig%"=="NotFound" (
        set "GoodbyeZapret_Old=NotFound"
    ) else (
        set "GoodbyeZapret_Old=%GoodbyeZapret_OldConfig%"
    )

    call :ReadConfig GoodbyeZapret_Config
    if "%GoodbyeZapret_Config%"=="NotFound" (
        REM Если переменная не найдена, установите значение по умолчанию
        set "GoodbyeZapret_Config=Не выбран"
    )

    goto MainMenuWithoutUiInfo
) else (
    echo  Нажмите любую клавишу чтобы продолжить...
    pause >nul 2>&1
    set "batFile="
    REM Set default values for GoodbyeZapret configuration
    set "GoodbyeZapret_Config=Не выбран"
    set "GoodbyeZapret_Old=Отсутствует"
    REM Check if GoodbyeZapret service exists and get current configuration
    REM reg query "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\GoodbyeZapret" /v "Description" >nul 2>&1
        REM if !errorlevel! equ 0 ( for /f "tokens=2*" %%a in ('reg query "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\GoodbyeZapret" /v "Description" 2^>nul ^| find /i "Description"') do set "GoodbyeZapret_Current=%%b" )

    rem /// Check for old configuration via config ///
    call :ReadConfig GoodbyeZapret_OldConfig
    if "%GoodbyeZapret_OldConfig%"=="NotFound" (
        set "GoodbyeZapret_Old=NotFound"
    ) else (
        set "GoodbyeZapret_Old=%GoodbyeZapret_OldConfig%"
    )
    goto MainMenuWithoutUiInfo
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

REM === Итоговая проверка ===
set "TotalCheck=Ok"
set "ProblemDetails="
set "ProblemTips="

REM Проверяем все результаты проверок
for %%V in (BaseFilteringEngineCheckResult AdguardCheckResult KillerCheckResult IntelCheckResult CheckpointCheckResult SmartByteCheckResult VPNCheckResult DNSCheckResult) do (
    if "!%%V!"=="Problem" (
        set "TotalCheck=Problem"
        if defined ProblemDetails (
            set "ProblemDetails=!ProblemDetails!, %%V"
        ) else (
            set "ProblemDetails=%%V"
        )
        REM Находим соответствующие советы
        for %%T in (BaseFilteringEngineCheckTips AdguardCheckTips KillerCheckTips IntelCheckTips CheckpointCheckTips SmartByteCheckTips VPNCheckTips DNSCheckTips) do (
            if "%%V"=="%%~nT" (
                if defined ProblemTips (
                    set "ProblemTips=!ProblemTips! !%%T!"
                ) else (
                    set "ProblemTips=!%%T!"
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
    echo     %COL%[91mВозможны проблемы в работе GoodbyeZapret%COL%[37m
    echo     └ 
    for %%V in (BaseFilteringEngine Adguard Killer Checkpoint SmartByte VPN DNS) do (
        set "CheckResult=!%%VCheckResult!"
        set "CheckTips=!%%VCheckTips!"
        if "!CheckResult!"=="Problem" (
            echo       - %%V:%COL%[91m Проблема обнаружена%COL%[37m
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
echo.
echo    %COL%[90m^[ %COL%[36mB %COL%[90m^] %COL%[93mВернуться в меню
echo    %COL%[90m^[ %COL%[36mI %COL%[90m^] %COL%[93mОткрыть инструкцию
echo    %COL%[90m^[ %COL%[36mT %COL%[90m^] %COL%[93mОткрыть telegram канал
echo    %COL%[90m^[ %COL%[36mU %COL%[90m^] %COL%[93mПереустановить GoodbyeZapret
echo    %COL%[90m^[ %COL%[36mR %COL%[90m^] %COL%[93mБыстрый перезапуск и очистка WinDivert
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

if /i "%choice%"=="I" set "choice=" && goto OpenInstructions
if /i "%choice%"=="ш" set "choice=" && goto OpenInstructions

if /i "%choice%"=="U" set "choice=" && goto FullUpdate
if /i "%choice%"=="г" set "choice=" && goto FullUpdate

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
if /i "%choice%"=="B" mode con: cols=92 lines=%ListBatCount% >nul 2>&1 && set "UpdateNeed=Yes" && goto MainMenu
if /i "%choice%"=="и" mode con: cols=92 lines=%ListBatCount% >nul 2>&1 && set "UpdateNeed=Yes" && goto MainMenu
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
if not defined PageSize set "PageSize=20"
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
set /a BaseLines=22
set /a ListBatCount=BaseLines+VisibleOnPage

REM === Пагинация: если страниц больше одной, добавляем 2 строки ===
if %TotalPages% gtr 1 set /a ListBatCount+=2

REM === Проверка сервисов для YesCount ===
set "YesCount=0"
sc query "GoodbyeZapret" >nul 2>&1
if %errorlevel% equ 0 set /a YesCount+=1

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
    if %YesCount% equ 1 ( set /a ListBatCount+=1 )
    if %YesCount% equ 0 ( set /a ListBatCount+=2 )
) else (
    if %YesCount% equ 0 (
        set /a ListBatCount+=2
    ) else if %YesCount% equ 1 (
        set /a ListBatCount+=2
    ) else if %YesCount% equ 2 (
        REM ничего не добавляем
    ) else (
        set /a ListBatCount-=1
    )
)

REM === Ограничения по высоте ===
set /a MaxWinLines=52
set /a MinWinLines=27
if %ListBatCount% gtr %MaxWinLines% set /a ListBatCount=%MaxWinLines%
if %ListBatCount% lss %MinWinLines% set /a ListBatCount=%MinWinLines%


REM === DEBUG ===
set DEBUG_mode=0
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
    goto CurrentStatus

if /i "%choice%"=="N" (
    set /a Page+=1
    goto MainMenu
)
if /i "%choice%"=="т" (
    set /a Page+=1
    goto MainMenu
)
if /i "%choice%"=="B" (
    if %Page% gtr 1 set /a Page-=1
    goto MainMenu
)
if /i "%choice%"=="и" (
    if %Page% gtr 1 set /a Page-=1
    goto MainMenu
)

REM Return to main menu if no input provided
if "%choice%"=="" goto MainMenu


:: Функция: чтение значения
:ReadConfig
set "CONFIG_FILE=%USERPROFILE%\AppData\Roaming\GoodbyeZapret\config.txt"
REM echo [LOG] Старт функции :ReadConfig для %~1, файл: %CONFIG_FILE%


set "RES="
set "FOUND=0"
REM echo [LOG] Переменные RES и FOUND инициализированы

if not exist "%CONFIG_FILE%" (
    echo [LOG][ОШИБКА] Файл конфигурации не найден!
    goto :eof
)

REM echo [LOG] Начинаем цикл по файлу конфигурации...

for /f "usebackq tokens=1,* delims==" %%A in ("%CONFIG_FILE%") do (
REM    echo [LOG] Анализ строки: %%A=%%B
    if /i "%%A"=="%~1" (
REM        echo [LOG] Найден ключ: %%A, значение: %%B
        set "RES=%%B"
        set "FOUND=1"
    )
)

REM echo [LOG] После цикла: RES=%RES% FOUND=%FOUND%
endlocal & set "RES=%RES%" & set "FOUND=%FOUND%"

if "%FOUND%"=="0" (
    set "RES=NotFound"
REM    echo [LOG] Ключ не найден, RES=NotFound
)

if not "%RES%"=="NotFound" if defined RES (
  if not "%RES%"=="%RES:"=%" set "RES=%RES:~1,-1%"
)

set "%~1=%RES%"

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
set "VARS=WinVer FirstLaunch GoodbyeZapret_Version GoodbyeZapret_Config GoodbyeZapret_ConfigPatch GoodbyeZapret_LastStartConfig GoodbyeZapret_LastWorkConfig GoodbyeZapret_OldConfig GoodbyeZapret_Version_code"
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