@echo off
setlocal EnableDelayedExpansion
chcp 65001 >nul
REM ------------------------------------------------------------
REM  auto_find_working_config.bat
REM  Подбор рабочего конфига из папки Configs
REM ------------------------------------------------------------

REM --- Определяем необходимые директории ---
set "toolsDir=%~dp0"
set "toolsDir=%toolsDir:~0,-1%"  REM убираем завершающий обратный слеш
for %%i in ("%toolsDir%") do set "projectDir=%%~dpi"
set "projectDir=%projectDir:~0,-1%"
set "configsDir=%projectDir%\Configs"

if not exist "%configsDir%" (
    echo [ERROR] Папка с конфигами не найдена: "%configsDir%".
    goto :end
)

echo.
echo  Поиск рабочего конфига в "%configsDir%" ...

echo -----------------------------------------------------------------------

REM --- Перебор конфигов (алфавитный порядок) ---
for %%F in ("%configsDir%\*.bat") do (
    set "configPath=%%~fF"
    set "configName=%%~nxF"

    echo Запуск конфигурации !configName! ...
    call "!configPath!"

    REM Небольшая пауза на запуск служб/правил
    timeout /t 3 /nobreak >nul

    echo   Проверка доступности доменов ...
    call "%toolsDir%\curl_test_for_finder.bat" "!configName!" >nul

    if !errorlevel! equ 0 (
        echo.
        echo -----------------------------------------------------------------------
        echo             Найдена рабочая конфигурация: !configName!
        echo -----------------------------------------------------------------------
        goto :success
    ) else (
        echo   Конфигурация !configName! не прошла проверку.
        echo   Очистка окружения ...
        call "%toolsDir%\delete_services.bat" >nul
        echo   Продолжаем поиск...
        echo ------------------------------------------------------------
        echo.
    )
)

echo [INFO] Не удалось найти полностью рабочую конфигурацию.

:success
:end
endlocal
pause
