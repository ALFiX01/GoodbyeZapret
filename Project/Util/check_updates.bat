@echo off
setlocal EnableDelayedExpansion

REM Получение информации о текущих версиях GoodbyeZapret и тд
for /f "usebackq delims=" %%a in ("%SystemDrive%\GoodbyeZapret\bin\version.txt") do set "Current_Winws_version=%%a"
for /f "usebackq delims=" %%a in ("%SystemDrive%\GoodbyeZapret\lists\version.txt") do set "Current_List_version=%%a"

reg query "HKEY_CURRENT_USER\Software\ALFiX inc.\GoodbyeZapret" /v "GoodbyeZapret_Version" >nul 2>&1
if %errorlevel% neq 0 (
    set "Current_GoodbyeZapret_version=0.0.0"
) else (
    for /f "tokens=3" %%i in ('reg query "HKEY_CURRENT_USER\Software\ALFiX inc.\GoodbyeZapret" /v "GoodbyeZapret_Version" ^| findstr /i "GoodbyeZapret_Version"') do set "Current_GoodbyeZapret_version=%%i"
)


set "GITHUB_RELEASE_URL=https://github.com/Flowseal/zapret-discord-youtube/releases/tag/"
set "GITHUB_DOWNLOAD_URL=https://github.com/Flowseal/zapret-discord-youtube/releases/latest/download/zapret-discord-youtube-"

:: Загрузка нового файла Updater.bat
if exist "%TEMP%\GoodbyeZapret_Updater.bat" del /s /q /f "%TEMP%\GZ_Updater.bat" >nul 2>&1
curl -s -o "%TEMP%\GoodbyeZapret_Updater.bat" "https://raw.githubusercontent.com/ALFiX01/GoodbyeZapret/refs/heads/main/GoodbyeZapret_Version" 
if errorlevel 1 (
    echo ERROR 1
    
)

:: Выполнение загруженного файла GoodbyeZapret_Updater.bat
call "%TEMP%\GoodbyeZapret_Updater.bat" >nul 2>&1
if errorlevel 1 (
    echo ERROR 2
)

set "UpdateNeed=None"
if !Current_GoodbyeZapret_version! neq !Actual_GoodbyeZapret_version! (
    set "UpdateNeed=Yes"
)
if !Current_Winws_version! neq !Actual_Winws_version! (
    set "UpdateNeed=Yes"
)
if !Current_List_version! neq !Actual_List_version! (
    set "UpdateNeed=Yes"
)
REM echo %UpdateNeed% %Current_GoodbyeZapret_version%
REM pause

if %UpdateNeed% equ Yes (
    if not exist "%SystemDrive%\GoodbyeZapret\Updater.exe" (
        curl -g -L -# -o "%SystemDrive%\GoodbyeZapret\Updater.exe" "https://github.com/ALFiX01/GoodbyeZapret/raw/refs/heads/main/Files/Updater/Updater.exe" >nul 2>&1
        start "" "%SystemDrive%\GoodbyeZapret\Updater.exe"
    ) else (
        start "" "%SystemDrive%\GoodbyeZapret\Updater.exe"
    )
) else (
    endlocal
    exit
)
