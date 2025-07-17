@echo off
:: Quick move selected .bin file(s) to Project\bin\fake
setlocal EnableDelayedExpansion

:: Ensure we are working from the directory where this script resides
cd /d "%~dp0"

:: Destination directory: three levels up (repository root) + Project\bin\fake
set "dest=%~dp0..\..\..\..\bin\fake"

:: Resolve absolute path
for %%I in ("%dest%") do set "dest=%%~fI"

if not exist "!dest!" (
    echo Destination folder not found: "!dest!"
    pause
    goto :eof
)

echo.
echo Select .bin file to move to "!dest!":
set /a idx=0
for %%F in (*.bin) do (
    set /a idx+=1
    set "file[!idx!]=%%F"
    echo !idx!. %%F
)

if !idx! EQU 0 (
    echo No .bin files found in current directory.
    pause
    goto :eof
)

echo 0. Move ALL files
set /p choice=Enter number (0 for all): 

if "%choice%"=="0" goto move_all
if defined file[%choice%] (
    set "selected=!file[%choice%]!"
    goto move_one
)

echo Invalid selection.
goto :eof

:move_one
move /Y "!selected!" "!dest!"
echo Moved "!selected!" to "!dest!".
goto :eof

:move_all
move /Y *.bin "!dest!"
echo Moved all .bin files to "!dest!".
goto :eof 