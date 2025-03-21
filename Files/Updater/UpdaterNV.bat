::[Bat To Exe Converter]
:: ... существующий код ...
@echo off

chcp 65001 >nul 2>&1
:: Запуск от имени администратора
reg add HKLM /F >nul 2>&1
if %errorlevel% neq 0 (
    echo Запрос прав администратора...
    start "" /wait /I /min powershell -NoProfile -Command "start -verb runas '%~s0'" && exit /b
    exit /b
)

setlocal EnableDelayedExpansion

set "UpdaterVersion=0.4"

REM Цветной текст
for /F "tokens=1,2 delims=#" %%a in ('"prompt #$H#$E# & echo on & for %%b in (1) do rem"') do (set "DEL=%%a" & set "COL=%%b")

call :colorEcho 0A "GoodbyeZapret Updater v%UpdaterVersion%"
echo.
echo ========================================
echo.

title GoodbyeZapret Updater v%UpdaterVersion%

echo ^[*^] Остановка текущих процессов...
net stop GoodbyeZapret >nul 2>&1
sc delete GoodbyeZapret >nul 2>&1

echo ^[*^] Завершение процесса winws.exe...
taskkill /F /IM winws.exe >nul 2>&1
if %errorlevel% equ 0 (
    echo ^[+^] Процесс winws.exe успешно остановлен.
) else (
    echo ^[i^] Процесс winws.exe не запущен или уже остановлен.
)

echo ^[*^] Удаление сервисов WinDivert...
net stop "WinDivert" >nul 2>&1
sc delete "WinDivert" >nul 2>&1
net stop "WinDivert14" >nul 2>&1
sc delete "WinDivert14" >nul 2>&1

echo.
echo ^[*^] Получение конфигурации...

REM Попытка прочитать значение из нового реестра
for /f "tokens=2*" %%a in ('reg query "HKCU\Software\ALFiX inc.\GoodbyeZapret" /v "GoodbyeZapret_Config" 2^>nul ^| find /i "GoodbyeZapret_Config"') do (
    set "GoodbyeZapret_Config=%%b"
    echo ^[+^] Найдена конфигурация: !GoodbyeZapret_Config!
    goto :end_GoodbyeZapret_Config
)

REM Попытка перенести значение из старого реестра в новый
for /f "tokens=2*" %%a in ('reg query "HKCU\Software\ASX\Info" /v "GoodbyeZapret_Config" 2^>nul ^| find /i "GoodbyeZapret_Config"') do (
    set "GoodbyeZapret_Config=%%b"
    echo ^[i^] Перенос конфигурации из устаревшего места в реестре: !GoodbyeZapret_Config!
    reg add "HKCU\Software\ALFiX inc.\GoodbyeZapret" /v "GoodbyeZapret_Config" /t REG_SZ /d "%%b" /f >nul
    reg delete "HKCU\Software\ASX\Info" /v "GoodbyeZapret_Config" /f >nul
    goto :end_GoodbyeZapret_Config
)

REM Если ключ нигде не найден, установить значение по умолчанию
set "GoodbyeZapret_Config=Default"
echo ^[!^] Конфигурация не найдена, будет использована конфигурация по умолчанию: !GoodbyeZapret_Config!

:end_GoodbyeZapret_Config
echo.
echo ^[*^] Скачивание обновлений...

set "DownloadURL=https://github.com/ALFiX01/GoodbyeZapret/raw/refs/heads/main/Files/GoodbyeZapret.zip"
set "DownloadPath=%TEMP%\GoodbyeZapret.zip"
set "TempInstallPath=%TEMP%\GoodbyeZapret_Update"

curl -g -L -# -o "%DownloadPath%" "%DownloadURL%" 2>nul

if not exist "%DownloadPath%" (
    call :colorEcho 0C "^[!^] Ошибка загрузки: файл не создан"
    echo.
    goto :DownloadError
)

for %%I in ("%DownloadPath%") do set FileSize=%%~zI
if %FileSize% LSS 100 (
    call :colorEcho 0C "^[!^] Ошибка загрузки: файл поврежден или недоступен (размер %FileSize% байт)"
    echo.
    goto :DownloadError
)

echo ^[+^] Загрузка успешно завершена (%FileSize% байт)
echo.

echo ^[*^] Проверка обновления...
if exist "%TempInstallPath%" rd /s /q "%TempInstallPath%" >nul 2>&1
mkdir "%TempInstallPath%" >nul 2>&1

echo ^[*^] Распаковка архива во временную папку...
chcp 850 >nul 2>&1
powershell -NoProfile -Command "& {try { Expand-Archive -Path '%DownloadPath%' -DestinationPath '%TempInstallPath%' -Force; Write-Output 'success' } catch { Write-Output $_.Exception.Message }}" > "%TEMP%\expand_result.txt"
chcp 65001 >nul 2>&1

set /p ExpandResult=<"%TEMP%\expand_result.txt"
del "%TEMP%\expand_result.txt" >nul 2>&1

if not "%ExpandResult%"=="success" (
    call :colorEcho 0C "^[!^] Ошибка распаковки: %ExpandResult%"
    echo.
    goto :ExtractError
)

echo ^[+^] Архив успешно распакован
echo.

REM Проверка наличия основных файлов в распакованном архиве
if not exist "%TempInstallPath%\Launcher.exe" (
    call :colorEcho 0C "^[!^] Ошибка: в архиве отсутствуют необходимые файлы"
    echo.
    goto :ExtractError
)

REM Проверка наличия конфигурационного файла
if "%GoodbyeZapret_Config%" NEQ "Default" (
    if not exist "%TempInstallPath%\Configs\%GoodbyeZapret_Config%.bat" (
        echo ^[!^] Внимание: файл выбранной конфигурации %GoodbyeZapret_Config% отсутствует в новой версии
        echo ^[i^] Проверяем наличие других конфигураций...
        
        if exist "%TempInstallPath%\Configs\Default.bat" (
            echo ^[i^] Найдена конфигурация по умолчанию, будет использована она
            set "GoodbyeZapret_Config=Default"
        ) else (
            call :colorEcho 0C "^[!^] Ошибка: не найдены конфигурационные файлы"
            echo.
            goto :ExtractError
        )
    )
)

echo ^[*^] Резервное копирование пользовательских настроек...
if exist "%SystemDrive%\GoodbyeZapret\user_settings.ini" (
    copy "%SystemDrive%\GoodbyeZapret\user_settings.ini" "%TempInstallPath%\" >nul 2>&1
    echo ^[+^] Пользовательские настройки сохранены
)

echo ^[*^] Установка обновления...
REM Удаляем старую версию только после успешной проверки обновления
if exist "%SystemDrive%\GoodbyeZapret" (
    echo ^[*^] Удаление предыдущей установки...
    rd /s /q "%SystemDrive%\GoodbyeZapret" >nul 2>&1
)

echo ^[*^] Перемещение файлов...
xcopy "%TempInstallPath%\*" "%SystemDrive%\GoodbyeZapret\" /E /I /H /Y >nul 2>&1

if not exist "%SystemDrive%\GoodbyeZapret\Launcher.exe" (
    call :colorEcho 0C "^[!^] Ошибка установки: файлы не скопированы"
    echo.
    goto :InstallError
)

echo ^[+^] Файлы успешно установлены
echo.
echo ^[*^] Установка и запуск службы...

if "%GoodbyeZapret_Config%" EQU "Default" (
    echo ^[i^] Используется конфигурация по умолчанию, служба не создается
    echo.
) else (
    if exist "%SystemDrive%\GoodbyeZapret\Configs\%GoodbyeZapret_Config%.bat" (
        sc create "GoodbyeZapret" binPath= "cmd.exe /c \"%SystemDrive%\GoodbyeZapret\Configs\%GoodbyeZapret_Config%.bat\"" start= auto
        sc description GoodbyeZapret "%GoodbyeZapret_Config%" >nul 2>&1
        sc start "GoodbyeZapret" >nul 2>&1
        
        if %errorlevel% equ 0 (
            call :colorEcho 0A "^[+^] Служба GoodbyeZapret успешно запущена"
            echo.
        ) else (
            call :colorEcho 0E "^[!^] Возможно при запуске службы GoodbyeZapret произошла ошибка"
            echo.
        )
    ) else (
        call :colorEcho 0C "^[!^] Ошибка: файл конфигурации %GoodbyeZapret_Config%.bat не найден"
        echo.
        call :colorEcho 0C "    Проверьте установку и попробуйте снова"
        echo.
        timeout /t 5 >nul
        exit /b 1
    )
)

:DownloadError
echo Попытка использовать локальную копию...
if exist "%SystemDrive%\GoodbyeZapret\GoodbyeZapret.zip" (
    echo ^[+^] Найдена локальная копия, используем её вместо скачивания
    copy "%SystemDrive%\GoodbyeZapret\GoodbyeZapret.zip" "%DownloadPath%" >nul
    goto :end_GoodbyeZapret_Config
) else (
    call :colorEcho 0C "Локальная копия не найдена. Обновление невозможно."
    echo.
    timeout /t 5 >nul
    exit /b 1
)

:ExtractError
call :colorEcho 0C "Не удалось распаковать архив. Обновление невозможно."
echo.
call :colorEcho 0E "Текущая установка не была затронута."
echo.
timeout /t 5 >nul
exit /b 1

:InstallError
call :colorEcho 0C "Не удалось установить обновление."
echo.
call :colorEcho 0C "Восстанавливаем предыдущую версию..."
if exist "%TempInstallPath%" (
    xcopy "%TempInstallPath%\*" "%SystemDrive%\GoodbyeZapret\" /E /I /H /Y >nul 2>&1
)
call :colorEcho 0E "Рекомендуется перезапустить компьютер и попробовать снова."
echo.
timeout /t 5 >nul
exit /b 1

:colorEcho
echo %COL%[%~1m%~2%COL%[0m
exit /b