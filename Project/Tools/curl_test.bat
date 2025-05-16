@echo off
setlocal EnableDelayedExpansion
rem --- Проверка googlevideo ---
set CountOK=0
echo.
echo   Проверка Youtube...

rem -o nul: перенаправить вывод заголовков в пустоту (чтобы не засорять консоль)
curl -s -L -I --connect-timeout 2 -o nul https://rr5---sn-jvhnu5g-c35d.googlevideo.com

rem Проверяем код завершения команды curl. 0 обычно означает успех.
IF %ERRORLEVEL% EQU 0 (
    echo    Доступен.
    set /a "CountOK+=1"
) ELSE (
    echo    НЕДОСТУПЕН ^(код ошибки curl: %ERRORLEVEL%^).
)
echo.

rem --- Проверка discord.com ---
echo  Проверка discord...
curl -s -L -I --connect-timeout 2 -o nul https://discord.com

IF %ERRORLEVEL% EQU 0 (
    echo    Доступен.
    set /a "CountOK+=1"
) ELSE (
    echo    НЕДОСТУПЕН ^(код ошибки curl: %ERRORLEVEL%^).
)

if %CountOK% equ 2 (
    if defined batFile (
        reg add "HKCU\Software\ALFiX inc.\GoodbyeZapret" /t REG_SZ /v "GoodbyeZapret_LastWorkConfig" /d "%batFile%" /f >nul
    )
)
echo.

echo  Проверка завершена.

