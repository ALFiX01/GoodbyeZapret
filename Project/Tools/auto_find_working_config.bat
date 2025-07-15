@echo off
setlocal EnableDelayedExpansion
chcp 65001 >nul
REM ------------------------------------------------------------
REM  auto_find_working_config.bat
REM  Подбор рабочего конфига из папки Configs
REM ------------------------------------------------------------

mode con: cols=106 lines=37 >nul 2>&1

REM --- Определяем необходимые директории ---
set "toolsDir=%~dp0"
set "toolsDir=%toolsDir:~0,-1%"  REM убираем завершающий обратный слеш
for %%i in ("%toolsDir%") do set "projectDir=%%~dpi"
set "projectDir=%projectDir:~0,-1%"
set "configsDir=%projectDir%\Configs\Preset"
REM --- Проверяем существование директории с конфигами заранее ---
if not exist "%configsDir%" (
    echo [ERROR] Папка с конфигами не найдена: "%configsDir%".
    pause
    goto :end
)

set "batFileFound=0"
for %%F in ("%configsDir%\*.bat") do (
    set "batFileFound=1"
    goto :bat_found
)
:bat_found

if "!batFileFound!"=="0" (
    echo [ОШИБКА] В папке "%configsDir%" нет ни одного .bat файла.
    pause
    goto :end
)

REM --- Инициализация массива для почти рабочих конфигов ---
set "almostWorkingConfigs="
set "foundAlmostWorking=0"

REM -- Цвета вывода ---------------------------------------------------
for /F %%# in ('echo prompt $E^| cmd') do set "ESC=%%#"
REM --- ANSI цветовые коды ---
set "RESET=!ESC![0m"
set "GREEN=!ESC![32m"
set "YELLOW=!ESC![33m"
set "RED=!ESC![31m"
set "CYAN=!ESC![36m"

echo.
echo  Поиск рабочего конфига в "%configsDir%" ...

echo -----------------------------------------------------------------------

REM --- Перебор конфигов (алфавитный порядок) ---
for %%F in ("%configsDir%\*.bat") do (
    set "configPath=%%~fF"
    set "configName=%%~nxF"

    echo !CYAN! Запуск конфига !configName! ...!RESET!
    call "!configPath!"

    REM Небольшая пауза на запуск служб/правил
    timeout /t 2 /nobreak >nul

    echo   !CYAN!Проверка доступности доменов ...!RESET!

    REM --- Запускаем скрипт проверки и фиксируем код возврата ---
    set "failedCount=0"
    set "failedDomainList="
    set "tmpFile=%temp%\curl_test_out_%random%.txt"

    call "%toolsDir%\curl_test_for_finder.bat" "!configName!" > "!tmpFile!"
    set "retCode=!errorlevel!"

    REM --- Разбираем вывод скрипта ---
    for /f "tokens=1* delims=:" %%A in ('type "!tmpFile!"') do (
        if "%%A"=="FAILED_COUNT" set "failedCount=%%B"
        if "%%A"=="FAILED_DOMAINS" set "failedDomainList=%%B"
    )
    del "!tmpFile!" >nul 2>&1

    if !retCode! equ 0 (
        echo.
        echo -----------------------------------------------------------------------
        echo             !GREEN!Найден рабочий конфиг: !configName!!RESET!
        echo -----------------------------------------------------------------------
        echo   !CYAN!Нажмите любую клавишу, чтобы продолжить поиск...!RESET!
        pause >nul
        call :SmartCleanup
        echo   !CYAN!Продолжаем поиск...!RESET!
        echo ------------------------------------------------------------
        echo.
    ) else if !retCode! equ 1 (
        REM Конфиг разблокировал все домены кроме одного
        set /a foundAlmostWorking+=1
        set "almostWorkingConfigs=!almostWorkingConfigs!конфиг !configName! не разблокировал: !failedDomainList!#"
        
        echo   !YELLOW!Конфиг !configName! почти работает. Не разблокирован только 1 домен. !RESET!
        call :SmartCleanup
        echo   !CYAN!Продолжаем поиск...!RESET!
        echo ------------------------------------------------------------
        echo.
    ) else (
        echo   !RED!Конфиг !configName! не прошёл проверку. Не разблокировано доменов: !failedCount!!RESET!
        call :SmartCleanup
        echo   !CYAN!Продолжаем поиск...!RESET!
        echo ------------------------------------------------------------
        echo.
    )
)

echo !YELLOW![INFO] Не удалось найти полностью рабочий конфиг.!RESET!

if !foundAlmostWorking! gtr 0 (
    echo.
    echo -----------------------------------------------------------------------
    echo          !YELLOW!Найдены почти рабочие конфиги (1 недоступный домен):!RESET!
    echo -----------------------------------------------------------------------

    call :PrintAlmostWorking
    echo.
)

goto :after_print

:PrintAlmostWorking
rem  Вывести каждый элемент из списка almostWorkingConfigs, разделённых символом #
set "__tmpList=%almostWorkingConfigs%"
:loopAlmost
for /f "tokens=1* delims=#" %%a in ("%__tmpList%") do (
    if not "%%a"=="" echo   %%a
    set "__tmpList=%%b"
)
if defined __tmpList if not "%__tmpList%"=="" goto :loopAlmost
exit /b

:after_print
:end
endlocal
pause

:SmartCleanup
rem Проверяем, нужно ли чистить среду. Если сервисы/процессы не найдены, пропускаем.
sc query "GoodbyeZapret" >nul 2>&1
if not errorlevel 1 goto :do_cleanup

tasklist /FI "IMAGENAME eq winws.exe" 2>NUL | find /I "winws.exe" >NUL
if not errorlevel 1 goto :do_cleanup

echo   !CYAN!Очистка не требуется.!RESET!
goto :eof

:do_cleanup
echo   !CYAN!Очистка окружения ...!RESET!
chcp 850 >nul 2>&1
call "%toolsDir%\delete_services_for_finder.bat" >nul
chcp 65001 >nul
goto :eof
