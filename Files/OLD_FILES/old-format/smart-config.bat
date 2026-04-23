@echo off
chcp 65001 >nul
setlocal EnableDelayedExpansion

:: --- НАСТРОЙКА ЛОГИРОВАНИЯ ---
:: Отключаем буферизацию Python, чтобы лог шел в реальном времени
set PYTHONUNBUFFERED=1

set "currentDir=%~dp0"
set "currentDir=%currentDir:~0,-1%"
for %%i in ("%currentDir%") do set "parentDir=%%~dpi"
for %%i in ("%parentDir:~0,-1%") do set "ProjectDir=%%~dpi"

:: Файл лога
set "LOG_FILE=%ProjectDir%\orchestrator.log"

:: Если файл лога существует, очищаем его перед запуском (опционально)
if exist "%LOG_FILE%" del "%LOG_FILE%"

:: Рабочие директории
set "BIN_DIR=%ProjectDir%bin"
set "TOOLS_DIR=%ProjectDir%tools"
set "LUA_DIR=%ProjectDir%bin\lua"

:: Генерация base_path.lua
set "BASE_PATH_LUA=%LUA_DIR%\base_path.lua"
echo Генерация base_path.lua...
(
    echo ORCHESTRA_BASE_PATH = "!LUA_DIR:\=/!/"
) > "%BASE_PATH_LUA%"

if errorlevel 1 (
    echo ОШИБКА: Не удалось создать base_path.lua
    pause
    exit /b 1
)
echo base_path.lua успешно создан.

timeout /t 1 /nobreak >nul

echo ==========================================
echo Корневая папка: "%ProjectDir%"
echo BIN_DIR: "%BIN_DIR%"
echo LUA_DIR: "%LUA_DIR%"
echo ЛОГ ФАЙЛ: "%LOG_FILE%"
echo ==========================================
echo.

:: Проверка существования файлов
if not exist "%TOOLS_DIR%\SmartConfig.exe" (
    echo ОШИБКА: SmartConfig.exe не найден!
    pause
    exit /b 1
)

if not exist "%LUA_DIR%\learned-strategies.lua" (
    echo ПРЕДУПРЕЖДЕНИЕ: learned-strategies.lua не найден
)

echo Запуск SmartConfig.exe...
echo Нажмите Ctrl+C для остановки.
echo.

:: === ЗАПУСК ===

chcp 850 >nul 2>&1
"%TOOLS_DIR%\SmartConfig.exe" --bin "%BIN_DIR%" --lua "%LUA_DIR%" --learned-init "%LUA_DIR%\learned-strategies.lua" 2>&1 | powershell -NoProfile -ExecutionPolicy Bypass -Command "$input | ForEach-Object { Write-Host $_; $_ | Add-Content -Path '%LOG_FILE%' -Encoding UTF8 }"

echo.
chcp 65001 >nul
echo SmartConfig.exe завершен. Лог сохранен в:
echo %LOG_FILE%
pause