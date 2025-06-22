@echo off
chcp 65001 >nul
setlocal EnableDelayedExpansion
set currentDir=%~dp0
set currentDir=%currentDir:~0,-1%
for %%i in ("%currentDir%") do set parentDir=%%~dpi

rem --- Список доменов в переменной ---
set "domains=rr4---sn-jvhnu5g-n8vr.googlevideo.com i.ytimg.com discord.com cloudflare.com"

set CountOK=0
echo.

for %%u in (%domains%) do (
    echo   Проверка %%u ...
    curl -s -L -I --connect-timeout 2 -o nul %%u

    IF !ERRORLEVEL! EQU 0 (
        echo     Доступен.
        set /a "CountOK+=1"
    ) ELSE (
        echo     /// НЕДОСТУПЕН ^(код curl: !ERRORLEVEL!^).
    )
    echo.
)

set /a total=0
for %%u in (%domains%) do set /a total+=1

if %CountOK% equ %total% (
    if defined batFile (
        reg add "HKCU\Software\ALFiX inc.\GoodbyeZapret" /t REG_SZ /v "GoodbyeZapret_LastWorkConfig" /d "%batFile%" /f >nul
    )
    echo.
    echo  Проверка успешно завершена.
) else (
echo.
echo  Проверка завершена.
)
timeout /t 2 >nul 2>&1