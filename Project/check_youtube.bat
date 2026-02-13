@echo off
setlocal EnableExtensions

REM Script for checking connectivity to domains (YouTube CDN / GGC)
REM Usage: check_domain.bat [domain]

where curl >NUL 2>NUL
if errorlevel 1 (
  echo curl not found. Install curl or ensure it is in PATH.
  pause
  exit /b 2
)

set "DOMAIN=%~1"
REM Дефолтный домен для теста, если не введен вручную
if "%DOMAIN%"=="" set "DOMAIN=rr6---sn-jvhnu5g-n8vy.googlevideo.com"

REM --- Очистка ввода от http://, https:// и слешей ---
set "DOMAIN=%DOMAIN:http://=%"
set "DOMAIN=%DOMAIN:https://=%"
set "DOMAIN=%DOMAIN:/=%"

echo Checking domain: %DOMAIN% ...

REM Параметры curl:
REM -I: Только заголовки (HEAD request) - быстрее, чем качать страницу
REM -k: Игнорировать ошибки SSL (insecure) - важно для CDN
REM -L: Не переходить по редиректам (нам важно просто достучаться до сервера)
REM --connect-timeout 2: Тайм-аут соединения (сек)
REM -m 4: Общий тайм-аут (сек)
REM -s: Тихо (без прогресс-бара)
REM -w: Вывод только HTTP кода
REM -o NUL: Игнорировать вывод данных

set "CODE=000"
for /f %%C in ('curl -I -k --connect-timeout 1 -m 4 -s -o NUL -w "%%{http_code}" "https://%DOMAIN%"') do set "CODE=%%C"

REM Если код 000, значит curl вообще не смог соединиться
if "%CODE%"=="000" goto fail
if "%CODE%"=="" goto fail

REM Любой ответ от сервера (200, 302, 403, 404, 405) означает, что домен ЖИВ.
REM Для CDN видео 404 - это нормальный ответ на корень сайта.
goto ok

:fail
echo [FAIL] Domain NOT reachable. (Connection error or Timeout)
pause
exit /b 1

:ok
echo [OK] Domain reachable. HTTP response: %CODE%
pause
exit /b 0