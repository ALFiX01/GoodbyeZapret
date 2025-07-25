::[Bat To Exe Converter]
::
::YAwzoRdxOk+EWAjk
::fBw5plQjdCuDJOlwRJyA8qq3/Ngy6dtnt1etA6hLN6o2QAOtgN4bfZzS3bqyB+8c7kf9cKwsxmhfjPcKDQ1RfR2lIAY3pg4=
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
::YxY4rhs+aU+IeA==
::cxY6rQJ7JhzQF1fEqQJhZk4aHmQ=
::ZQ05rAF9IBncCkqN+0xwdVs0
::ZQ05rAF9IAHYFVzEqQIXJxRQTh2HBmqqFLAIiA==
::eg0/rx1wNQPfEVWB+kM9LVsJDGQ=
::fBEirQZwNQPfEVWB+kM9LVsJDGQ=
::cRolqwZ3JBvQF1fEqQJQ
::dhA7uBVwLU+EWHio0ksIaBJaT2Q=
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
:: Copyright (C) 2025 ALFiX, Inc.
:: Any tampering with the program code is forbidden (Запрещены любые вмешательства)

net session >nul 2>&1
if %errorlevel% neq 0 (
    echo  Requesting administrator privileges...
    powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs -ArgumentList '--elevated'" >nul 2>&1
    exit /b
)

:: Enable delayed expansion for variable manipulation
setlocal EnableDelayedExpansion
set "ErrorCount=0"

:: Get the parent directory path more reliably
for /f "delims=" %%A in ('powershell -NoProfile -Command "Split-Path -Parent '%~f0'"') do set "ParentDirPath=%%A"

:: Version information
set "Current_GoodbyeZapret_version=2.1.0"
set "Current_GoodbyeZapret_version_code=22YL01"
set "branch=Stable"
set "beta_code=0"

REM /// UAC Settings ///
set "L_ConsentPromptBehaviorAdmin=0"
set "L_ConsentPromptBehaviorUser=3"
set "L_EnableInstallerDetection=1"
set "L_EnableLUA=1"
set "L_EnableSecureUIAPaths=1"
set "L_FilterAdministratorToken=0"
set "L_PromptOnSecureDesktop=0"
set "L_ValidateAdminCodeSignatures=0"

REM UAC registry path
set "UAC_HKLM=HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"

REM Main loop for checking and updating UAC values
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
            REM Remove "0x" prefix from current value
            set "current_value=%%a"
            set "current_value=!current_value:0x=!"

            REM Get expected value
            call set "expected_value=%%L_%%i%%"

            REM Compare values
            if not "!current_value!" == "!expected_value!" (
                echo [WARN ] %TIME% - UAC parameter '%%i' has unexpected value. Current: 0x!current_value!, Expected: 0x!expected_value!.
                reg add "%UAC_HKLM%" /v "%%i" /t REG_DWORD /d !expected_value! /f >nul 2>&1
                if !errorlevel! equ 1 (
                    echo [ERROR] %TIME% - Failed to change UAC parameter '%%i'. Possibly insufficient privileges.
                    set "UAC_check=Error"
                ) else (
                    echo [INFO ] %TIME% - UAC parameter '%%i' successfully changed to 0x!expected_value!.
                )
            )
        )
    ) else (
        REM Key doesn't exist, create it
        call set "expected_value=%%L_%%i%%"
        reg add "%UAC_HKLM%" /v "%%i" /t REG_DWORD /d !expected_value! /f >nul 2>&1
        if !errorlevel! equ 1 (
            echo [ERROR] %TIME% - Failed to create UAC parameter '%%i'. Possibly insufficient privileges.
            set "UAC_check=Error"
        ) else (
            echo [INFO ] %TIME% - UAC parameter '%%i' successfully created with value 0x!expected_value!.
        )
    )
)

REM Check execution result
if "!UAC_check!" == "Error" (
    echo [WARN ] %TIME% - Some UAC parameters could not be configured correctly.
)

REM /// Language ///
:: Получение информации о текущем языке интерфейса и выход, если язык не ru-RU
for /f "tokens=3" %%i in ('reg query "HKCU\Control Panel\International" /v "LocaleName" ^| findstr /i "LocaleName"') do set "WinLang=%%i"
if /I "%WinLang%" NEQ "ru-RU" (
    cls
    echo.
    echo   Error 01: Invalid interface language. Requires ru-RU. Current: %WinLang%
    timeout /t 4 >nul
    exit /b
)

REM /// GoodbyeZapret Version ///
reg query "HKEY_CURRENT_USER\Software\ALFiX inc.\GoodbyeZapret" /v "GoodbyeZapret_Version" >nul 2>&1
if %errorlevel% neq 0 (
    reg add "HKEY_CURRENT_USER\Software\ALFiX inc.\GoodbyeZapret" /v "GoodbyeZapret_Version" /t REG_SZ /d "%Current_GoodbyeZapret_version%" /f >nul 2>&1
) else (
    for /f "tokens=3" %%i in ('reg query "HKEY_CURRENT_USER\Software\ALFiX inc.\GoodbyeZapret" /v "GoodbyeZapret_Version" ^| findstr /i "GoodbyeZapret_Version"') do set "Registry_Version=%%i"
    if not "!Registry_Version!"=="%Current_GoodbyeZapret_version%" (
        reg add "HKEY_CURRENT_USER\Software\ALFiX inc.\GoodbyeZapret" /v "GoodbyeZapret_Version" /t REG_SZ /d "%Current_GoodbyeZapret_version%" /f >nul 2>&1
    )
)

REM Check for GoodbyeZapret_Version_code value in registry
reg query "HKEY_CURRENT_USER\Software\ALFiX inc.\GoodbyeZapret" /v "GoodbyeZapret_Version_code" >nul 2>&1
if %errorlevel% neq 0 (
    REM Key doesn't exist, create with current version value
    reg add "HKEY_CURRENT_USER\Software\ALFiX inc.\GoodbyeZapret" /v "GoodbyeZapret_Version_code" /t REG_SZ /d "%Current_GoodbyeZapret_version_code%" /f >nul 2>&1
    if errorlevel 1 (
        echo [ERROR] %TIME% - Failed to create GoodbyeZapret_Version_code key in registry
    )
) else (
    REM Key exists, check value
    for /f "tokens=3" %%i in ('reg query "HKEY_CURRENT_USER\Software\ALFiX inc.\GoodbyeZapret" /v "GoodbyeZapret_Version_code" 2^>nul ^| findstr /i "GoodbyeZapret_Version_code"') do set "Registry_Version_code=%%i"
    
    if not "!Registry_Version_code!"=="%Current_GoodbyeZapret_version_code%" (
        echo [INFO ] %TIME% - Component service update in progress. Please wait...
        
        REM Update registry value
        reg add "HKEY_CURRENT_USER\Software\ALFiX inc.\GoodbyeZapret" /v "GoodbyeZapret_Version_code" /t REG_SZ /d "%Current_GoodbyeZapret_version_code%" /f >nul 2>&1
        if errorlevel 1 (
            echo [ERROR] %TIME% - Failed to update GoodbyeZapret_Version_code in registry
        )

        REM Create tools folder if it doesn't exist
        if not exist "%ParentDirPath%\tools" mkdir "%ParentDirPath%\tools" >nul 2>&1

        REM Update UpdateService.exe
        if exist "%ParentDirPath%\tools\UpdateService.exe" (
            del "%ParentDirPath%\tools\UpdateService.exe" >nul 2>&1
        )
        echo [INFO ] %TIME% - Downloading UpdateService.exe...
        curl -g -L -s -o "%ParentDirPath%\tools\UpdateService.exe" "https://github.com/ALFiX01/GoodbyeZapret/raw/refs/heads/main/Files/UpdateService/UpdateService.exe"
        if exist "%ParentDirPath%\tools\UpdateService.exe" (
            echo [INFO ] %TIME% - UpdateService.exe downloaded successfully
        ) else (
            echo [ERROR] %TIME% - Failed to download UpdateService.exe
        )

        REM Update Updater.exe
        if exist "%ParentDirPath%\tools\Updater.exe" (
            del "%ParentDirPath%\tools\Updater.exe" >nul 2>&1
        )
        echo [INFO ] %TIME% - Downloading Updater.exe...
        curl -g -L -s -o "%ParentDirPath%\tools\Updater.exe" "https://github.com/ALFiX01/GoodbyeZapret/raw/refs/heads/main/Files/Updater/Updater.exe"
        if exist "%ParentDirPath%\tools\Updater.exe" (
            echo [INFO ] %TIME% - Updater.exe downloaded successfully
        ) else (
            echo [ERROR] %TIME% - Failed to download Updater.exe
        )
        
        echo [INFO ] %TIME% - Component update completed
    )
)

set "WiFi=Off"
set "CheckURL=https://ya.ru"
set "CheckURL_BACKUP=https://mail.ru"

echo   Checking connectivity to update server ^(%CheckURL%^)...
:: Используем curl для проверки доступности основного хоста обновлений
:: -s: Silent mode (без прогресс-бара)
:: -L: Следовать редиректам
:: --head: Получить только заголовки (быстрее, меньше данных)
:: -m 8: Таймаут 8 секунд
:: -o NUL: Отправить тело ответа в никуда (нам нужен только код возврата)
:: --connect-timeout 5: Таймаут на подключение 5 секунд
:: --max-time 8: Общий таймаут 8 секунд

REM --- Attempt connectivity check with primary URL ---
curl -4 -s -L --head -I --connect-timeout 2 --max-time 2 --max-redirs 1 -o nul "%CheckURL%"
IF %ERRORLEVEL% EQU 0 (
    echo   Connection successful.
    set "WiFi=On"
) ELSE (
    REM Primary URL failed, try backup URL
    echo   Primary host unreachable, trying backup URL ^(%CheckURL_BACKUP%^)...
    curl -4 -s -L --head -I --connect-timeout 3 --max-time 2 --max-redirs 2 -o nul "%CheckURL_BACKUP%"
    IF %ERRORLEVEL% EQU 0 (
        echo   Connection successful via backup URL.
        set "WiFi=On"
    ) ELSE (
        echo.
        echo   Error 02: Cannot reach the update servers.
        echo   Connection checks to %CheckURL% and %CheckURL_BACKUP% failed ^(curl errorlevel: %ERRORLEVEL%^).
        echo   Please check your internet connection, firewall settings,
        echo   or if those hosts are accessible from your network.
        set "WiFi=Off"
        timeout /t 3 >nul
    )
)

if not exist "%ParentDirPath%" (
    goto install_screen
)

:RR

REM Initialize variables
set "BatCount=0"
set "sourcePath=%~dp0"

REM --- Run health check in silent mode before sizing window ---
set "SilentMode=1"
call :CurrentStatus
set "SilentMode="
REM ------------------------------------------------------------

REM Re-calculate amount of *.bat configs and resize console every time we enter the menu (prevents list from «исчезать» after returning)
call :ResizeMenuWindow

REM Initialize color codes
for /F "tokens=1,2 delims=#" %%a in ('"prompt #$H#$E# & echo on & for %%b in (1) do rem"') do (set "DEL=%%a" & set "COL=%%b")

REM Set UTF-8 encoding
chcp 65001 >nul 2>&1

:GoodbyeZapret_Menu
REM Initialize status variables
set "CheckStatus=WithoutChecked"
set "sourcePath=%~dp0"

REM Set default values for GoodbyeZapret configuration
set "GoodbyeZapret_Current=Не выбран"
set "GoodbyeZapret_Current_TEXT=Текущий конфиг - Не выбран"
set "GoodbyeZapret_Config=Не выбран"
set "GoodbyeZapret_Old=Отсутствует"

REM Check if GoodbyeZapret service exists and get current configuration
reg query "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\GoodbyeZapret" /v "Description" >nul 2>&1
if !errorlevel! equ 0 (
    for /f "tokens=2*" %%a in ('reg query "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\GoodbyeZapret" /v "Description" 2^>nul ^| find /i "Description"') do set "GoodbyeZapret_Current=%%b"
)

REM Check for old configuration in registry
reg query "HKEY_CURRENT_USER\Software\ALFiX inc.\GoodbyeZapret" /v "GoodbyeZapret_OldConfig" >nul 2>&1
if !errorlevel! equ 0 (
    for /f "tokens=2*" %%a in ('reg query "HKEY_CURRENT_USER\Software\ALFiX inc.\GoodbyeZapret" /v "GoodbyeZapret_OldConfig" 2^>nul ^| find /i "GoodbyeZapret_OldConfig"') do set "GoodbyeZapret_Old=%%b"
)

REM Initialize repair flag
set "RepairNeed=No"

REM Handle repair process if needed and WiFi is available
if /i "!WiFi!"=="On" (
    if /i "!RepairNeed!"=="Yes" (
        echo Error 03: Critical error. GoodbyeZapret needs to be reinstalled.
        echo Starting the reinstallation...
        timeout /t 2 >nul

        REM Create tools directory if it doesn't exist
        if not exist "%ParentDirPath%\tools" (
            md "%ParentDirPath%\tools" >nul 2>&1
        )

        REM Download Updater.exe if not present
        if not exist "%ParentDirPath%\tools\Updater.exe" (
            curl -g -L -s -o "%ParentDirPath%\tools\Updater.exe" "https://github.com/ALFiX01/GoodbyeZapret/raw/refs/heads/main/Files/Updater/Updater.exe" >nul 2>&1
            if not exist "%ParentDirPath%\tools\Updater.exe" (
                echo Error: Failed to download Updater.exe
                echo Please check your internet connection and try again.
                timeout /t 3 >nul
                goto GoodbyeZapret_Menu
            )
        )

        timeout /t 2 >nul
        start "" "%ParentDirPath%\tools\Updater.exe"
        exit /b 0
    )
) else if /i "!RepairNeed!"=="Yes" (
    echo Error 04: Critical error. GoodbyeZapret needs to be reinstalled.
    echo Internet connection required for repair. Please check your connection.
    timeout /t 3 >nul
)

REM Check if Winws process is running and handle last start configuration
tasklist /FI "IMAGENAME eq winws.exe" 2>NUL | find /I /N "winws.exe" >NUL
if !errorlevel! equ 0 (
    REM Winws is running, get last start config
    for /f "tokens=2*" %%a in ('reg query "HKCU\Software\ALFiX inc.\GoodbyeZapret" /v "GoodbyeZapret_LastStartConfig" 2^>nul ^| find /i "GoodbyeZapret_LastStartConfig"') do set "GoodbyeZapret_LastStartConfig=%%b"
    if not defined GoodbyeZapret_LastStartConfig (
        set "GoodbyeZapret_LastStartConfig=None"
    )
) else (
    REM Winws is not running, set default value
    reg add "HKCU\Software\ALFiX inc.\GoodbyeZapret" /v "GoodbyeZapret_LastStartConfig" /t REG_SZ /d "None" /f >nul 2>&1
    set "GoodbyeZapret_LastStartConfig=None"
)


REM  for /f "usebackq delims=" %%a in ("%ParentDirPath%\bin\version.txt") do set "Current_Winws_version=%%a"
REM for /f "usebackq delims=" %%a in ("%ParentDirPath%\lists\version.txt") do set "Current_List_version=%%a"
REM for /f "usebackq delims=" %%a in ("%ParentDirPath%\configs\version.txt") do set "Current_configs_version=%%a"

:: Загрузка нового файла GZ_Updater.bat

REM Check WiFi status before proceeding with update operations
if /i "!WiFi!"=="Off" goto skip_for_wifi

REM Clean up temporary file if it exists
if exist "%TEMP%\GZ_Updater.bat" (
    del /q /f "%TEMP%\GZ_Updater.bat" >nul 2>&1
    if exist "%TEMP%\GZ_Updater.bat" (
        echo Error: Failed to delete temporary file %TEMP%\GZ_Updater.bat
        timeout /t 2 >nul
    )
)


curl -4 -s -L -I --connect-timeout 3 --max-time 1 --max-redirs 1 -o nul "https://raw.githubusercontent.com/ALFiX01/GoodbyeZapret/refs/heads/main/GoodbyeZapret_Version"

IF !ERRORLEVEL! NEQ 0 (
    set "CheckStatus=FileCheckError"
    goto OnFileCheckError
)

REM Download version update file
curl -s -o "%TEMP%\GZ_Updater.bat" "https://raw.githubusercontent.com/ALFiX01/GoodbyeZapret/refs/heads/main/GoodbyeZapret_Version"
if errorlevel 1 (
    echo Error 04: Server error. Failed to connect to GoodbyeZapret update check server
    set "CheckStatus=NoChecked"
    goto OnFileCheckError
)

REM Verify successful download of GZ_Updater.bat
if not exist "%TEMP%\GZ_Updater.bat" (
    echo Error: Failed to download GZ_Updater.bat file
    set "CheckStatus=NoChecked"
    goto OnFileCheckError
)

REM Download Updater.exe if not present
if not exist "%ParentDirPath%\tools\Updater.exe" (
    REM Create tools directory if it doesn't exist
    if not exist "%ParentDirPath%\tools" (
        md "%ParentDirPath%\tools" >nul 2>&1
    )
    
    curl -g -L -s -o "%ParentDirPath%\tools\Updater.exe" "https://github.com/ALFiX01/GoodbyeZapret/raw/refs/heads/main/Files/Updater/Updater.exe"
    if not exist "%ParentDirPath%\tools\Updater.exe" (
        echo Error: Failed to download Updater.exe
        set "CheckStatus=NoChecked"
        goto OnFileCheckError
    )
)

REM Check file size of GZ_Updater.bat
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

REM Execute downloaded Updater.bat file
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
REM GoodbyeZapret versions
set "GoodbyeZapretVersion_New=%Actual_GoodbyeZapret_version%"
set "GoodbyeZapretVersion=%Current_GoodbyeZapret_version%"

set "UpdateNeed=No"

if "%StatusProject%"=="0" (
    cls
    echo.
    echo  Я был рад быть вам полезным, но пришло время прощаться.
    echo  Проект GoodbyeZapret был закрыт.
    echo.
    REM Stop and remove GoodbyeZapret service
    sc query "GoodbyeZapret" >nul 2>&1
    if %errorlevel% equ 0 (
        net stop "GoodbyeZapret" >nul 2>&1
        sc delete "GoodbyeZapret" >nul 2>&1
    )
    
    REM Kill winws.exe process if running
    tasklist /FI "IMAGENAME eq winws.exe" 2>NUL | find /I /N "winws.exe" >NUL
    if not errorlevel 1 (
        taskkill /F /IM winws.exe >nul 2>&1
    )
    
    REM Stop and remove WinDivert services
    sc query "WinDivert" >nul 2>&1
    if %errorlevel% equ 0 (
        net stop "WinDivert" >nul 2>&1
        sc delete "WinDivert" >nul 2>&1
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

REM Check if version has changed
if not "%CheckStatus%"=="FileCheckError" (
    if defined Actual_GoodbyeZapret_version_code (
        if defined Current_GoodbyeZapret_version_code (
            echo "%Actual_GoodbyeZapret_version_code%" | findstr /i "%Current_GoodbyeZapret_version_code%" >nul
            if errorlevel 1 (
                echo - available update
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
cls

title GoodbyeZapret - Launcher

REM Try to read value from registry
for /f "tokens=2*" %%a in ('reg query "HKCU\Software\ALFiX inc.\GoodbyeZapret" /v "GoodbyeZapret_Config" 2^>nul ^| find /i "GoodbyeZapret_Config"') do (
    set "GoodbyeZapret_Config=%%b"
    goto :GoodbyeZapret_Config_Found
)

REM If key not found, set default value
set "GoodbyeZapret_Config=Not found"

:GoodbyeZapret_Config_Found

REM Try to read value from new registry
for /f "tokens=2*" %%a in ('reg query "HKCU\Software\ALFiX inc.\GoodbyeZapret" /v "GoodbyeZapret_Version" 2^>nul ^| find /i "GoodbyeZapret_Version"') do (
    set "GoodbyeZapret_Version_OLD=%%b"
    goto :end_GoodbyeZapret_Version_OLD
)

REM Try to migrate value from old registry to new
for /f "tokens=2*" %%a in ('reg query "HKCU\Software\ASX\Info" /v "GoodbyeZapret_Version" 2^>nul ^| find /i "GoodbyeZapret_Version"') do (
    set "GoodbyeZapret_Version_OLD=%%b"
    reg add "HKCU\Software\ALFiX inc.\GoodbyeZapret" /v "GoodbyeZapret_Version" /t REG_SZ /d "%%b" /f >nul 2>&1
    reg delete "HKCU\Software\ASX\Info" /v "GoodbyeZapret_Version" /f >nul 2>&1
    goto :end_GoodbyeZapret_Version_OLD
)

REM If key not found anywhere, create with default value
if not defined GoodbyeZapretVersion (
    set "GoodbyeZapretVersion=0.0.0"
)
reg add "HKCU\Software\ALFiX inc.\GoodbyeZapret" /v "GoodbyeZapret_Version" /t REG_SZ /d "%GoodbyeZapretVersion%" /f >nul 2>&1
set "GoodbyeZapret_Version_OLD=Not found"

:end_GoodbyeZapret_Version_OLD

REM Error handling for missing version
if not defined GoodbyeZapretVersion (
    echo   Error 06: Read error. Failed to read value GoodbyeZapret_Version
    set "GoodbyeZapretVersion=%Current_GoodbyeZapret_version%"
    set "Actual_GoodbyeZapret_version=0.0.0"
    set "UpdateNeed=No"
    timeout /t 1 >nul
)

REM Error handling for missing config
if not defined GoodbyeZapret_Config (
    echo   Error 07: Read error. Failed to read value GoodbyeZapret_Config
    timeout /t 2 >nul
)

REM Check for GoodbyeZapret service and get current config
reg query "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\GoodbyeZapret" /v Description >nul 2>&1
if %errorlevel% equ 0 (
    for /f "tokens=2*" %%a in ('reg query "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\GoodbyeZapret" /v "Description" 2^>nul ^| find /i "Description"') do (
        set "GoodbyeZapret_Current=%%b"
        set "GoodbyeZapret_Current_TEXT=Current config - %%b"
    )
)

REM Check for old config in registry
reg query "HKEY_CURRENT_USER\Software\ALFiX inc.\GoodbyeZapret" /v "GoodbyeZapret_OldConfig" >nul 2>&1
if %errorlevel% equ 0 (
    for /f "tokens=2*" %%a in ('reg query "HKEY_CURRENT_USER\Software\ALFiX inc.\GoodbyeZapret" /v "GoodbyeZapret_OldConfig" 2^>nul ^| find /i "GoodbyeZapret_OldConfig"') do (
        set "GoodbyeZapret_Old=%%b"
    )
)

REM Update version in registry if defined
if defined GoodbyeZapretVersion (
    reg add "HKEY_CURRENT_USER\Software\ALFiX inc.\GoodbyeZapret" /v "GoodbyeZapret_Version" /t REG_SZ /d "%GoodbyeZapretVersion%" /f >nul 2>&1
)

:GZ_loading_procces
if "%UpdateNeed%"=="Yes" (
    goto Update_Need_screen
)

:MainMenu
REM Check for last working config in registry
reg query "HKEY_CURRENT_USER\Software\ALFiX inc.\GoodbyeZapret" /v "GoodbyeZapret_LastWorkConfig" >nul 2>&1
if %errorlevel% equ 0 (
    for /f "tokens=2*" %%a in ('reg query "HKCU\Software\ALFiX inc.\GoodbyeZapret" /v "GoodbyeZapret_LastWorkConfig" 2^>nul ^| find /i "GoodbyeZapret_LastWorkConfig"') do (
        set "GoodbyeZapret_LastWorkConf=%%b"
        set "GoodbyeZapret_LastWork=!GoodbyeZapret_LastWorkConf:~0,-4!"
    )
) else (   
    set "GoodbyeZapret_LastWork=none"
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
    for /f "tokens=2*" %%a in ('reg query "HKCU\Software\ALFiX inc.\GoodbyeZapret" /v "GoodbyeZapret_LastStartConfig" 2^>nul ^| find /i "GoodbyeZapret_LastStartConfig"') do (
        set "GoodbyeZapret_LastStartConfig=%%b"
        set "TrimmedLastStart=!GoodbyeZapret_LastStartConfig:~0,-4!"
    )
) else (
    set "WinwsStart=No"
    reg add "HKCU\Software\ALFiX inc.\GoodbyeZapret" /v "GoodbyeZapret_LastStartConfig" /t REG_SZ /d "None" /f >nul 2>&1
)

REM Check WinDivert service status
set "WinDivertStart=No"
sc query "WinDivert" 2>NUL | find /I "RUNNING" >NUL
if %errorlevel% equ 0 set "WinDivertStart=Yes"
if "%WinDivertStart%"=="No" (
    sc query "WinDivert14" 2>NUL | find /I "RUNNING" >NUL
    if %errorlevel% equ 0 set "WinDivertStart=Yes"
)

REM Count running services/processes
set "YesCount=0"
if "%GoodbyeZapretStart%"=="Yes" set /a YesCount+=1
if "%WinwsStart%"=="Yes" set /a YesCount+=1
if "%WinDivertStart%"=="Yes" set /a YesCount+=1

REM ------ New: run quick problem check silently ------
set "SilentMode=1"
call :CurrentStatus
set "SilentMode="
REM ----------------------------------------------------

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
if not defined GoodbyeZapretVersion (
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
if %YesCount% geq 2 (
if "%TotalCheck%"=="Problem" (
    echo                        %COL%[91mВозможны проблемы в работе ^[ ST ^] - подробнее%COL%[37m
)
)
REM ---------------------------------------------------------

REM ================================================================================================

REM Calculate text length and center padding
set "line_length=90"
set "text_length=0"

REM Count actual text length (more efficient method)
for /l %%A in (0,1,89) do (
    set "char=!GoodbyeZapret_Current_TEXT:~%%A,1!"
    if "!char!"=="" goto :count_done
    set /a text_length+=1
)
:count_done

REM Calculate padding spaces for centering
set /a spaces=(line_length - text_length) / 2

REM Build padding string (handle negative values)
set "padding="
if %spaces% gtr 0 (
    for /l %%A in (1,1,%spaces%) do set "padding=!padding! "
)


REM ================================================================================================

REM Display separator line
echo             %COL%[90m ────────────────────────────────────────────────────────────────── %COL%[37m

REM Get last started config from registry
for /f "tokens=2*" %%a in ('reg query "HKCU\Software\ALFiX inc.\GoodbyeZapret" /v "GoodbyeZapret_LastStartConfig" 2^>nul ^| find /i "GoodbyeZapret_LastStartConfig"') do set "GoodbyeZapret_LastStartConfig=%%b"
set "TrimmedLastStart=%GoodbyeZapret_LastStartConfig:~0,-4%"

echo                 %COL%[36mКонфиги:
echo.
set "choice="
set "counter=0"

REM -- Ensure pagination variables exist --
if not defined Page set "Page=1"
if not defined PageSize set "PageSize=25"
REM ---------------------------------------

REM ---------- Pagination indices ----------
set /a StartIndex=(Page-1)*PageSize+1
set /a EndIndex=StartIndex+PageSize-1

REM Modernized config enumeration ----------------------------------------------------
for %%F in ("%ParentDirPath%\configs\Preset\*.bat" "%ParentDirPath%\configs\Custom\*.bat") do (
    set /a "counter+=1"
    set "ConfigName=%%~nF"
    set "ConfigFull=%%~nxF"

    REM Determine status tag and color once
    set "StatusText="
    set "StatusColor=%COL%[37m"

    if /i "!ConfigName!"=="%GoodbyeZapret_Current%" (
        set "StatusText=[Активен]"
        set "StatusColor=%COL%[92m"
    ) else if /i "!ConfigName!"=="%TrimmedLastStart%" (
        set "StatusText=[Запущен]"
        set "StatusColor=%COL%[96m"
    ) else if /i "!ConfigName!"=="!GoodbyeZapret_LastWork!" (
        set "StatusText=[Раньше работал]"
        set "StatusColor=%COL%[93m"
    ) else if /i "!ConfigName!"=="%GoodbyeZapret_Old%" (
        set "StatusText=[Использовался]"
        set "StatusColor=%COL%[93m"
    )

    REM Simple alignment for single-digit numbers
    if !counter! lss 10 (
        set "Pad= "
    ) else (
        set "Pad="
    )

    if !counter! geq !StartIndex! if !counter! leq !EndIndex! (
        if defined StatusText (
            echo                 %COL%[36m!counter!.!Pad! %COL%[36m%%~nF !StatusColor!!StatusText!
        ) else (
            echo                 %COL%[36m!counter!.!Pad! %COL%[37m%%~nF
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
    if defined Actual_GoodbyeZapret_version (
        echo.
        echo                  %COL%[91mДоступно обновление GoodbyeZapret v%Actual_GoodbyeZapret_version%. ^[ UD ^] - обновить %COL%[37m
    ) else (
        echo.
        echo                       %COL%[91mДоступно обновление GoodbyeZapret. ^[ UD ^] - обновить %COL%[37m
    )
)

echo             %COL%[90m ────────────────────────────────────────────────────────────────── %COL%[37m
echo                 %COL%[36mДействия:
echo.

REM Display different menu options based on current service status
if "%GoodbyeZapret_Current%"=="Не выбран" (
    echo                 %COL%[36m^[1-!counter!^] %COL%[92mУстановить конфиг в автозапуск
    echo                 %COL%[36m^[1-!counter!s^] %COL%[92mЗапустить конфиг
    echo.
    if not "%TotalCheck%"=="Problem" (
    echo                 %COL%[36m^[ ST ^] %COL%[37mСостояние GoodbyeZapret
    )
    echo                 %COL%[36m^[ AC ^] %COL%[37mЗапустить автоподбор конфига
) else (
    echo                 %COL%[36m^[ DS ^] %COL%[91mУдалить конфиг из автозапуска
    echo                 %COL%[36m^[ ST ^] %COL%[37mСостояние GoodbyeZapret
)

REM ---- Pagination options ----
if %TotalPages% gtr 1 (
    echo.
    if %Page% lss %TotalPages% echo                 %COL%[36m^[ N ^] %COL%[37mСледующая страница
    if %Page% gtr 1 echo                 %COL%[36m^[ B ^] %COL%[37mПредыдущая страница
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
call :install_GZ_sevice

:install_GZ_sevice
cls
echo.
echo   -%COL%[37m !batFile! устанавливается в службу GoodbyeZapret...

sc create "GoodbyeZapret" binPath= "cmd.exe /c \"\"%ParentDirPath%\configs\!batPath!\!batFile!\"\"" >nul 2>&1
sc config "GoodbyeZapret" start= auto >nul 2>&1

REM Извлекаем базовое имя файла (без папки и расширения) для записи в реестр/описание
for %%A in ("!batRel!") do set "BaseCfg=%%~nA"

reg add "HKCU\Software\ALFiX inc.\GoodbyeZapret" /t REG_SZ /v "GoodbyeZapret_Config" /d "!batPath!" /f >nul
reg add "HKCU\Software\ALFiX inc.\GoodbyeZapret" /t REG_SZ /v "GoodbyeZapret_ConfigPatch" /d "!BaseCfg!" /f >nul
reg add "HKCU\Software\ALFiX inc.\GoodbyeZapret" /t REG_SZ /v "GoodbyeZapret_OldConfig" /d "!BaseCfg!" /f >nul
sc description GoodbyeZapret "!BaseCfg!" >nul
sc start "GoodbyeZapret" >nul
if %errorlevel% equ 0 (
    cmd /c "sc start GoodbyeZapret" >nul
    if %errorlevel% equ 0 (
        echo  - Служба GoodbyeZapret успешно запущена %COL%[37m
    ) else (
        echo  - Ошибка при запуске службы
    )
)
cls
echo.
echo   -%COL%[92m !batFile! установлен в службу GoodbyeZapret %COL%[37m
set installing_service=0
timeout /t 1 >nul 2>&1
if exist "%ParentDirPath%\tools\Config_Check\curl_check.exe" (
    echo.
    "%ParentDirPath%\tools\Config_Check\curl_check.exe" "!batFile!"
)
call :ResizeMenuWindow
goto :end

:remove_service
    cls
    REM Цветной текст
    for /F "tokens=1,2 delims=#" %%a in ('"prompt #$H#$E# & echo on & for %%b in (1) do rem"') do (set "DEL=%%a" & set "COL=%%b")
    echo.
    sc query "GoodbyeZapret" >nul 2>&1
    if %errorlevel% equ 0 (
        net stop "GoodbyeZapret" >nul 2>&1
        sc delete "GoodbyeZapret" >nul 2>&1
        if %errorlevel% equ 0 (
            echo %COL%[92m Служба GoodbyeZapret успешно удалена %COL%[37m
            tasklist /FI "IMAGENAME eq winws.exe" 2>NUL | find /I /N "winws.exe" >NUL
            if "%ERRORLEVEL%"=="0" (
                taskkill /F /IM winws.exe >nul 2>&1
                net stop "WinDivert" >nul 2>&1
                sc delete "WinDivert" >nul 2>&1
                net stop "WinDivert14" >nul 2>&1
                sc delete "WinDivert14" >nul 2>&1
                echo  Файл winws.exe остановлен
                ipconfig /flushdns > nul
            )
            echo %COL%[92m Удаление успешно завершено %COL%[37m
        ) else (
            echo  Ошибка при удалении службы
        )
    ) else (
        echo  Служба GoodbyeZapret не найдена
    )
    reg delete "HKCU\Software\ALFiX inc.\GoodbyeZapret" /v "GoodbyeZapret_Config" /f >nul 2>&1
    call :ResizeMenuWindow
goto :end

:remove_service_before_installing
    cls
    echo.
    echo   -%COL%[37m подготовка к установке !batRel! в GoodbyeZapret...
    REM Цветной текст
    for /F "tokens=1,2 delims=#" %%a in ('"prompt #$H#$E# & echo on & for %%b in (1) do rem"') do (set "DEL=%%a" & set "COL=%%b")
    echo.
    sc query "GoodbyeZapret" >nul 2>&1
    if %errorlevel% equ 0 (
        net stop "GoodbyeZapret" >nul 2>&1
        sc delete "GoodbyeZapret" >nul 2>&1
        if %errorlevel% equ 0 (
            echo %COL%[92m Служба GoodbyeZapret успешно удалена %COL%[37m
            tasklist /FI "IMAGENAME eq winws.exe" 2>NUL | find /I /N "winws.exe" >NUL
            if "%ERRORLEVEL%"=="0" (
                taskkill /F /IM winws.exe >nul 2>&1
                net stop "WinDivert" >nul 2>&1
                sc delete "WinDivert" >nul 2>&1
                net stop "WinDivert14" >nul 2>&1
                sc delete "WinDivert14" >nul 2>&1
                echo  Файл winws.exe остановлен
                ipconfig /flushdns > nul
            )
            echo %COL%[92m Удаление успешно завершено %COL%[37m
        ) else (
            echo  Ошибка при удалении службы
        )
    )
    reg delete "HKCU\Software\ALFiX inc.\GoodbyeZapret" /v "GoodbyeZapret_Config" /f >nul 2>&1
    timeout /t 1 >nul 2>&1
goto :install_GZ_sevice

:end
if !ErrorCount! equ 0 (
    goto GoodbyeZapret_Menu
) else (
    echo  Нажмите любую клавишу чтобы продолжить...
    pause >nul 2>&1
    set "batFile="
    goto GoodbyeZapret_Menu
)

:CurrentStatus
REM Check Auto-update setting from registry
reg query "HKEY_CURRENT_USER\Software\ALFiX inc.\GoodbyeZapret" /v "Auto-update" >nul 2>&1
if %errorlevel% equ 0 (
    for /f "tokens=2*" %%a in ('reg query "HKEY_CURRENT_USER\Software\ALFiX inc.\GoodbyeZapret" /v "Auto-update" 2^>nul ^| find /i "Auto-update"') do set "Auto-update=%%b"
) else (
    set "Auto-update=1"
)

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
    set "VPNCheckTips=Отключите VPN ^(!VPNServices!^) ."
) else (
    set "VPNCheckResult=Ok"
)

REM === Проверка DNS серверов ===
set "DNSCheckResult=Ok"
set "DNSCheckTips="
set "dnsfound=0"
set "dns_configured=0"

REM Проверяем наличие настроенных DNS серверов
for /f "skip=1 tokens=*" %%a in ('wmic nicconfig where "IPEnabled=true" get DNSServerSearchOrder /format:table 2^>NUL') do (
    echo %%a | findstr /r /c:"[0-9]" >nul
    if !errorlevel!==0 (
        set "dns_configured=1"
        REM Проверяем на использование локальных DNS (192.168.x.x)
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
    mode con: cols=92 lines=36 >nul 2>&1
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
sc qc windivert >nul
if %errorlevel% equ 0 (
    echo    ^│ %COL%[92m√ %COL%[37mWinDivert: %COL%[92mУстановлен                                                           %COL%[36m^│
) else (
    echo    ^│ %COL%[91mX %COL%[37mWinDivert: Не установлен                                                        %COL%[36m^│
)
if "%Auto-update%"=="1" (
    echo    ^│ %COL%[92m√ %COL%[37mАвтообновление: %COL%[92mВключено                                                        %COL%[36m^│
    set "AutoUpdateTextParam=Выключить"
    set "AutoUpdateStatus=On"
) else (
    echo    ^│ %COL%[91mX %COL%[37mАвтообновление: Выключено                                                       %COL%[36m^│
    set "AutoUpdateTextParam=Включить"
    set "AutoUpdateStatus=Off"
)
echo    ^│                                                                                   ^│
echo    ^│ %COL%[37mВерсии:                                                                           %COL%[36m^│
echo    ^│ %COL%[90m───────────────────────────────────────────────────────────────────────────────── %COL%[36m^│

if "%UpdateNeed%"=="Yes" (
    echo    ^│ %COL%[37mGoodbyeZapret: %COL%[91m%GoodbyeZapretVersion% %COL%[92m^(→ %Actual_GoodbyeZapret_version%^)                                %COL%[36m^│
) else (
    echo    ^│ %COL%[37mGoodbyeZapret: %COL%[92m%GoodbyeZapretVersion%                                                              %COL%[36m^│
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
echo    %COL%[36m^[ %COL%[96mB %COL%[36m^] %COL%[93mВернуться в меню
echo    %COL%[36m^[ %COL%[96mA %COL%[36m^] %COL%[93m%AutoUpdateTextParam% автообновление
echo    %COL%[36m^[ %COL%[96mR %COL%[36m^] %COL%[93mПереустановить GoodbyeZapret
echo    %COL%[36m^[ %COL%[96mIN %COL%[36m^] %COL%[93mОткрыть инструкцию
if "%UpdateNeed%"=="Yes" (
    echo    %COL%[36m^[ %COL%[96mU %COL%[36m^] %COL%[93mОбновить до актуальной версии
)
echo.
set /p "choice=%DEL%   %COL%[90m:> "

REM Handle menu choices with proper error checking
if /i "%choice%"=="B" (
    call :ResizeMenuWindow
    goto MainMenu
)
if /i "%choice%"=="и" (
    call :ResizeMenuWindow
    goto MainMenu
)

if /i "%choice%"=="IN" goto OpenInstructions
if /i "%choice%"=="шт" goto OpenInstructions

if /i "%choice%"=="R" goto FullUpdate
if /i "%choice%"=="к" goto FullUpdate

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

REM Handle auto-update toggle with improved logic
if /i "%choice%"=="A" (
    if /i "%AutoUpdateStatus%"=="On" (
        REM Disable auto-update
        reg add "HKCU\Software\ALFiX inc.\GoodbyeZapret" /v "Auto-update" /t REG_SZ /d "0" /f >nul 2>&1
        if exist "%ParentDirPath%\tools\UpdateService.exe" del "%ParentDirPath%\tools\UpdateService.exe" >nul 2>&1
        if exist "%ProgramData%\Microsoft\Windows\Start Menu\Programs\Startup\UpdateService.lnk" del "%ProgramData%\Microsoft\Windows\Start Menu\Programs\Startup\UpdateService.lnk" >nul 2>&1
        echo    %COL%[92mАвтообновление отключено%COL%[37m
        timeout /t 2 >nul
    ) else (
        REM Enable auto-update
        reg add "HKCU\Software\ALFiX inc.\GoodbyeZapret" /v "Auto-update" /t REG_SZ /d "1" /f >nul 2>&1
        chcp 850 >nul 2>&1
        powershell -Command "$WshShell = New-Object -comObject WScript.Shell; $Shortcut = $WshShell.CreateShortcut('%ProgramData%\Microsoft\Windows\Start Menu\Programs\Startup\UpdateService.lnk'); $Shortcut.TargetPath = '%ParentDirPath%\tools\UpdateService.exe'; $Shortcut.Save()" >nul 2>&1
        chcp 65001 >nul 2>&1
        if exist "%ParentDirPath%\tools\UpdateService.exe" del "%ParentDirPath%\tools\UpdateService.exe" >nul 2>&1
        curl -g -L -# -o "%ParentDirPath%\tools\UpdateService.exe" "https://github.com/ALFiX01/GoodbyeZapret/raw/refs/heads/main/Files/UpdateService/UpdateService.exe" >nul 2>&1
        if exist "%ParentDirPath%\tools\UpdateService.exe" (
            echo    %COL%[92mАвтообновление включено%COL%[37m
        ) else (
            echo    %COL%[91mОшибка загрузки UpdateService.exe%COL%[37m
        )
        timeout /t 2 >nul
    )
)

REM Handle Cyrillic 'A' key (ф)
if /i "%choice%"=="ф" (
    if /i "%AutoUpdateStatus%"=="On" (
        REM Disable auto-update
        reg add "HKCU\Software\ALFiX inc.\GoodbyeZapret" /v "Auto-update" /t REG_SZ /d "0" /f >nul 2>&1
        if exist "%ParentDirPath%\tools\UpdateService.exe" del "%ParentDirPath%\tools\UpdateService.exe" >nul 2>&1
        if exist "%ProgramData%\Microsoft\Windows\Start Menu\Programs\Startup\UpdateService.lnk" del "%ProgramData%\Microsoft\Windows\Start Menu\Programs\Startup\UpdateService.lnk" >nul 2>&1
        echo    %COL%[92mАвтообновление отключено%COL%[37m
        timeout /t 2 >nul
    ) else (
        REM Enable auto-update
        reg add "HKCU\Software\ALFiX inc.\GoodbyeZapret" /v "Auto-update" /t REG_SZ /d "1" /f >nul 2>&1
        chcp 850 >nul 2>&1
        powershell -Command "$WshShell = New-Object -comObject WScript.Shell; $Shortcut = $WshShell.CreateShortcut('%ProgramData%\Microsoft\Windows\Start Menu\Programs\Startup\UpdateService.lnk'); $Shortcut.TargetPath = '%ParentDirPath%\tools\UpdateService.exe'; $Shortcut.Save()" >nul 2>&1
        chcp 65001 >nul 2>&1
        if exist "%ParentDirPath%\tools\UpdateService.exe" del "%ParentDirPath%\tools\UpdateService.exe" >nul 2>&1
        curl -g -L -# -o "%ParentDirPath%\tools\UpdateService.exe" "https://github.com/ALFiX01/GoodbyeZapret/raw/refs/heads/main/Files/UpdateService/UpdateService.exe" >nul 2>&1
        if exist "%ParentDirPath%\tools\UpdateService.exe" (
            echo    %COL%[92mАвтообновление включено%COL%[37m
        ) else (
            echo    %COL%[91mОшибка загрузки UpdateService.exe%COL%[37m
        )
        timeout /t 2 >nul
    )
)

goto CurrentStatus

:FullUpdate
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
curl -g -L -# -o %TEMP%\GoodbyeZapret.zip "https://github.com/ALFiX01/GoodbyeZapret/raw/refs/heads/main/Files/GoodbyeZapret.zip"
if errorlevel 1 (
    echo %COL%[91m ^[*^] Ошибка: Не удалось скачать GoodbyeZapret.zip ^(Код: %errorlevel%^) %COL%[90m
)

echo        ^[*^] Скачивание Updater.exe...
curl -g -L -# -o "%ParentDirPath%\tools\Updater.exe" "https://github.com/ALFiX01/GoodbyeZapret/raw/refs/heads/main/Files/Updater/Updater.exe"
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
curl -g -L -o "%ParentDirPath%\bin\PatchNote.txt" "https://raw.githubusercontent.com/ALFiX01/GoodbyeZapret/refs/heads/main/Files/PatchNote.txt"
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
if /i "%choice%"=="B" mode con: cols=92 lines=%ListBatCount% >nul 2>&1 && goto MainMenu
if /i "%choice%"=="и" mode con: cols=92 lines=%ListBatCount% >nul 2>&1 && goto MainMenu
if /i "%choice%"=="U" ( goto FullUpdate )
if /i "%choice%"=="г" ( goto FullUpdate )
goto Update_Need_screen


:ConfigAutoFinder
start "" "%ParentDirPath%\tools\Config_Check\auto_find_working_config.exe"
goto MainMenu

:ResizeMenuWindow
REM Recalculate number of config files and adjust console size dynamically
set "sourcePath=%~dp0"
set "BatCount=0"
for %%f in ("%sourcePath%configs\Preset\*.bat" "%sourcePath%configs\Custom\*.bat") do set /a BatCount+=1

REM Ensure PageSize defined (default 25)
if not defined PageSize set "PageSize=20"

REM Determine number of configs to show on current page
set /a VisibleConfigs=BatCount
if %VisibleConfigs% gtr %PageSize% set /a VisibleConfigs=%PageSize%

set /a ListBatCount=VisibleConfigs+23

REM Add extra lines for pagination hints when more than one page
set /a TotalPages=(BatCount+PageSize-1)/PageSize
if %TotalPages% gtr 1 set /a ListBatCount+=2

REM If service GoodbyeZapret installed, reduce height by 2 lines
sc query "GoodbyeZapret" >nul 2>&1
if %errorlevel% equ 0 (
    set /a ListBatCount-=2
)

REM Доп. Корректировка высоты консоли-----------------------
:: Сбрасываем старую логику и добавляем новую более точную

REM Определяем количество запущенных компонентов (GoodbyeZapret, Winws, WinDivert)
set "YesCount=0"
sc query "GoodbyeZapret" >nul 2>&1
if %errorlevel% equ 0 set /a YesCount+=1

tasklist | find /i "Winws" >nul 2>&1
if %errorlevel% equ 0 set /a YesCount+=1

sc query "WinDivert" 2>NUL | find /I "RUNNING" >NUL
if %errorlevel% equ 0 (
    set /a YesCount+=1
) else (
    sc query "WinDivert14" 2>NUL | find /I "RUNNING" >NUL
    if %errorlevel% equ 0 set /a YesCount+=1
)

REM Добавляем строку только если будет показано предупреждение «Возможны проблемы...»
if %YesCount% geq 2 if "%TotalCheck%"=="Problem" set /a ListBatCount+=1

REM Отсутствие интернета выводит отдельную строку
if /i "%WiFi%"=="Off" set /a ListBatCount+=1

REM Уведомление о доступном обновлении
if /i "%UpdateNeed%"=="Yes" set /a ListBatCount+=1

REM Ошибка проверки файлов/подключения к серверу
if /i "%CheckStatus%"=="FileCheckError" set /a ListBatCount+=1
REM --------------------------------------------------------

REM Limit maximum window height to avoid oversized console
set /a MaxWinLines=52
if %ListBatCount% gtr %MaxWinLines% set /a ListBatCount=%MaxWinLines%

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