@echo off
chcp 65001 >nul
setlocal EnableDelayedExpansion

REM Получить текущую и родительскую директорию
REM Добавляю поддержку передачи имени конфига первым параметром (auto_find_working_config.bat)
if "%~1" NEQ "" set "batFile=%~1"
set "currentDir=%~dp0"
set "currentDir=%currentDir:~0,-1%"
for %%i in ("%currentDir%") do set "parentDir=%%~dpi"


REM --- Список доменов---
set "domains=rr4---sn-jvhnu5g-n8ve7.googlevideo.com i.ytimg.com discord.com updates.discord.com cloudflare.com raw.githubusercontent.com www.youtube.com"

REM --- Расширенный Список доменов---
REM set "domains=rr4---sn-jvhnu5g-n8vr.googlevideo.com rr7---sn-jvhnu5g-n8vy.googlevideo.com rr16---sn-n8v7znlk.googlevideo.com i.ytimg.com/vi/dQw4w9WgXcQ/maxresdefault.jpg discord.com cloudflare.com raw.githubusercontent.com"


REM Для GitHub файла используем отдельную переменную
set "github_path=/ALFiX01/GoodbyeZapret/refs/heads/main/GoodbyeZapret_Version"

set "CountOK=0"
set "total=0"
echo.

if exist "%ParentDir%curl\curl.exe" (
    set CURL="%ParentDir%curl\curl.exe"
) else (
    set "CURL=curl"
)

REM Проверка доменов
for %%u in (%domains%) do (
    set "url=%%u"
    REM Для raw.githubusercontent.com добавляем путь к файлу
    if /I "%%u"=="raw.githubusercontent.com" (
        set "url=%%u!github_path!"
    )
    set /a total+=1
    %CURL% --ipv4 --silent --show-error --head --connect-timeout 1 --max-time 2 --max-redirs 1 --fail -o nul "!url!"
    if !ERRORLEVEL! EQU 0 (
        echo     %%u Доступен.
        set /a CountOK+=1
    ) else (
        echo     %%u /// НЕДОСТУПЕН ^(код curl: !ERRORLEVEL!^).
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
    echo  Проверка успешно завершена.
    timeout /t 2 >nul 2>&1
    exit /b 0
) else (
    echo.
    echo  Проверка завершена.
    timeout /t 2 >nul 2>&1
    exit /b 1
)