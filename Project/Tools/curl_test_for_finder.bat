@echo off
chcp 65001 >nul
setlocal EnableDelayedExpansion

REM -- Цвета вывода ---------------------------------------------------
for /F %%# in ('echo prompt $E^| cmd') do set "ESC=%%#"
set "GREEN=!ESC![32m"
set "RED=!ESC![31m"
set "YELLOW=!ESC![33m"
set "CYAN=!ESC![36m"
set "RESET=!ESC![0m"

REM Получить текущую и родительскую директорию
REM Добавляю поддержку передачи имени конфига первым параметром (auto_find_working_config.bat)
if "%~1" NEQ "" set "batFile=%~1"
set "currentDir=%~dp0"
set "currentDir=%currentDir:~0,-1%"
for %%i in ("%currentDir%") do set "parentDir=%%~dpi"

REM --- Список доменов в переменной ---
set "domains=rr4---sn-jvhnu5g-n8vr.googlevideo.com i.ytimg.com discord.com cloudflare.com raw.githubusercontent.com"

REM Для GitHub файла используем отдельную переменную
set "github_path=/ALFiX01/GoodbyeZapret/main/GoodbyeZapret_Version"

set "CountOK=0"
set "total=0"
set "failedDomains="
echo.

REM Проверка доменов
for %%u in (%domains%) do (
    set "url=%%u"
    REM Для raw.githubusercontent.com добавляем путь к файлу
    if /I "%%u"=="raw.githubusercontent.com" (
        set "url=%%u!github_path!"
    )
    set /a total+=1
    echo   !CYAN!Проверка %%u ...!RESET!
    curl -4 -s -L -I --connect-timeout 1 --max-time 1 --max-redirs 1 -o nul "!url!"
    if !ERRORLEVEL! EQU 0 (
        echo     !GREEN!Доступен.!RESET!
        set /a CountOK+=1
    ) else (
        echo     !RED!/// НЕДОСТУПЕН ^(код curl: !ERRORLEVEL!^).!RESET!
        set "failedDomains=!failedDomains!%%u "
    )
    echo.
)

REM Проверка результатов
if !CountOK! EQU !total! (
    if defined batFile (
        reg add "HKCU\Software\ALFiX inc.\GoodbyeZapret" /t REG_SZ /v "GoodbyeZapret_LastWorkConfig" /d "%batFile%" /f >nul
        reg add "HKCU\Software\ALFiX inc.\GoodbyeZapret" /t REG_SZ /v "GoodbyeZapret_LastStartConfig" /d "%batFile%" /f >nul
    )
    echo.
    echo  !GREEN!Проверка успешно завершена.!RESET!
    echo STATUS:OK
    exit /b 0
) else (
    set /a failCount=!total!-!CountOK!
    echo.
    echo  !RED!Проверка завершена.!RESET!
    echo STATUS:FAIL
    echo FAILED_COUNT:!failCount!
    echo FAILED_DOMAINS:!failedDomains!
    exit /b !failCount!
)