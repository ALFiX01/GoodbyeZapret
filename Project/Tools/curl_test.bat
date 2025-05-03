@echo off

SET URL_GOOGLEVIDEO=https://rr5---sn-jvhnu5g-c35d.googlevideo.com
SET URL_DISCORD=https://discord.com

rem --- Проверка googlevideo ---
echo  Проверка Youtube...

rem -o nul: перенаправить вывод заголовков в пустоту (чтобы не засорять консоль)
curl -s -L -I --connect-timeout 1 -o nul %URL_GOOGLEVIDEO%

rem Проверяем код завершения команды curl. 0 обычно означает успех.
IF %ERRORLEVEL% EQU 0 (
    echo   Доступен.
) ELSE (
    echo   НЕДОСТУПЕН ^(код ошибки curl: %ERRORLEVEL%^).
)
echo.

rem --- Проверка discord.com ---
echo  Проверка discord...
curl -s -L -I --connect-timeout 1 -o nul %URL_DISCORD%

IF %ERRORLEVEL% EQU 0 (
    echo   Доступен.
) ELSE (
    echo   НЕДОСТУПЕН ^(код ошибки curl: %ERRORLEVEL%^).
)
echo.

echo Проверка завершена.

