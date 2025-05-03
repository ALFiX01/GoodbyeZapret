@echo off
rem --- Проверка googlevideo ---
echo.
echo   Проверка Youtube...

rem -o nul: перенаправить вывод заголовков в пустоту (чтобы не засорять консоль)
curl -s -L -I --connect-timeout 1 -o nul https://rr5---sn-jvhnu5g-c35d.googlevideo.com

rem Проверяем код завершения команды curl. 0 обычно означает успех.
IF %ERRORLEVEL% EQU 0 (
    echo    Доступен.
) ELSE (
    echo    НЕДОСТУПЕН ^(код ошибки curl: %ERRORLEVEL%^).
)
echo.

rem --- Проверка discord.com ---
echo  Проверка discord...
curl -s -L -I --connect-timeout 1 -o nul https://discord.com

IF %ERRORLEVEL% EQU 0 (
    echo    Доступен.
) ELSE (
    echo    НЕДОСТУПЕН ^(код ошибки curl: %ERRORLEVEL%^).
)
echo.

echo  Проверка завершена.

