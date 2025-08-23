@ECHO OFF
title ---] Windivert to Monkey renaming... [---
color f1
PUSHD "%~dp0"

IF "%PROCESSOR_ARCHITECTURE%"=="AMD64" (set "os_arch=64")
IF "%PROCESSOR_ARCHITECTURE%"=="x86" (set "os_arch=32")
IF DEFINED PROCESSOR_ARCHITEW6432 (set "os_arch=64")

if %os_arch%==32 (
color f2
echo Windows x86 detected! Nothing to do.
echo Press any key for exit
pause > nul
exit /b
)
if not "%1"=="am_admin" (powershell start -verb runas '%0' am_admin & exit /b)
for /f "skip=3 tokens=1,2,* delims=: " %%i in ('sc query "zapret"') do (
 if %%j==4 (
 color fc
 echo Zapret service is running!
 echo Stopping service...
 net stop zapret > nul
 echo Deleting service...
 sc delete zapret > nul
 )
)
for /f "skip=3 tokens=1,2,* delims=: " %%i in ('sc query "WinDivert"') do (
 if %%j==4 (
 color fc
 echo WinDivert service is running!
 echo Stopping service...
 net stop WinDivert > nul
 ping -n 4 127.0.0.1 > nul
 )
rem exit
)
cls
if %os_arch%==64 (
rename "%~dp0WinDivert.dll" WinDivert.dll.bak
rename "%~dp0WinDivert64.sys" WinDivert64.sys.bak
curl -sOL https://github.com/bol-van/zapret-win-bundle/raw/refs/heads/master/windivert-hide/WinDivert.dll
curl -sOL https://github.com/bol-van/zapret-win-bundle/raw/refs/heads/master/windivert-hide/Monkey64.sys
)
color f2
echo Renaming completed

ping -n 6 127.0.0.1 > nul
exit /b
