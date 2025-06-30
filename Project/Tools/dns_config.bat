@echo off
setlocal enabledelayedexpansion
cls

:: Check for administrative privileges
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo  Requesting administrator privileges...
    powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs -ArgumentList '--elevated'" >nul 2>&1
    exit /b
)

mode con: cols=55 lines=25 >nul 2>&1

set count=0

:: Title screen
cls
echo =======================================================
echo               DNS Configuration Utility
echo =======================================================
echo.

set count=0

:: Use PowerShell to get adapters with IP address and gateway
for /f "tokens=1,2 delims==" %%a in ('powershell -Command "Get-NetIPConfiguration | Where-Object { $_.IPv4DefaultGateway -ne $null -and $_.NetAdapter.status -eq 'Up' } | Select-Object -ExpandProperty InterfaceAlias"') do (
    set /a count+=1
    set "adapter_!count!=%%a"
)

if %count% equ 0 (
    echo WARNING: No active adapters with internet access found.
    echo Please check your network connection.
    echo.
    pause
    exit /b
)


for /l %%i in (1,1,%count%) do (
    powershell -Command "Write-Host ' %%i. !adapter_%%i!' -ForegroundColor Blue"
)
echo.
echo -------------------------------------------------------

:: Adapter selection loop
:adapter_prompt
set "choice="
set /p choice="Select number (1-%count%): "

:: Remove spaces
set "choice=%choice: =%"

:: Validate input
if not defined choice (
    echo Please enter a value.
    goto adapter_prompt
)

set /a test=%choice% 2>nul
if not defined test (
    echo Invalid input. Please enter a number between 1 and %count%.
    goto adapter_prompt
)

if %test% lss 1 (
    echo Value too low. Please enter a number between 1 and %count%.
    goto adapter_prompt
)

if %test% gtr %count% (
    echo Value too high. Please enter a number between 1 and %count%.
    goto adapter_prompt
)

set "adapter_name=!adapter_%test%!"

:: Display selected adapter info
cls
echo =======================================================
echo         Selected Adapter: %adapter_name%
echo =======================================================
echo.
echo Current DNS Settings:
echo.
for /f "tokens=*" %%a in ('netsh interface ipv4 show dnsservers name^="%adapter_name%" ^| findstr /i "DNS"') do (
    powershell -Command "Write-Host '%%a' -ForegroundColor Blue"
)
echo.
echo Press any key to continue to the menu...
pause >nul

:: DNS configuration menu
:menu
cls
echo =======================================================
echo               DNS Configuration Utility
echo =======================================================
echo.
powershell -Command "Write-Host 'Configure DNS Settings:' -ForegroundColor Blue"
echo [1] Google Public DNS (8.8.8.8, 8.8.4.4)
echo [2] Cloudflare DNS (1.1.1.1, 1.0.0.1)
echo [3] OpenDNS (208.67.222.222, 208.67.220.220)
powershell -Command "Write-Host '[4] Reset to DHCP' -ForegroundColor Red"
echo [5] Exit Without Changes
echo.

:: DNS choice loop
:dns_prompt
set "dns_choice="
set /p dns_choice="Enter your choice (1-5): "

:: Remove spaces
set "dns_choice=%dns_choice: =%"

:: Validate input
if not defined dns_choice (
    echo Please enter a value.
    goto dns_prompt
)

if not "%dns_choice%"=="1" if not "%dns_choice%"=="2" ^
if not "%dns_choice%"=="3" if not "%dns_choice%"=="4" ^
if not "%dns_choice%"=="5" (
    echo Invalid choice. Please enter 1-5.
    goto dns_prompt
)

if "%dns_choice%"=="5" (
    echo.
    echo Exiting without changes...
    timeout /t 2 >nul
    exit /b
)

:: Confirmation screen
cls
echo =======================================================
echo              DNS Configuration Utility
echo =======================================================
echo.
echo WARNING: This will overwrite your current DNS settings
echo.
echo You selected option [%dns_choice%]:
if "%dns_choice%"=="1" echo Configure Google Public DNS (8.8.8.8, 8.8.4.4)
if "%dns_choice%"=="2" echo Configure Cloudflare DNS (1.1.1.1, 1.0.0.1)
if "%dns_choice%"=="3" echo Configure OpenDNS (208.67.222.222, 208.67.220.220)
if "%dns_choice%"=="4" echo Reset to DHCP settings
echo.
echo [Y] Yes - Apply Changes
echo [N] No - Return to Menu
echo.

:confirm_prompt
set "confirm="
set /p confirm="Confirm (Y/N): "
set "confirm=%confirm: =%"

if /i "%confirm%"=="Y" goto apply_settings
if /i "%confirm%"=="N" goto menu

echo Invalid choice. Please enter Y or N.
goto confirm_prompt

:: Apply DNS settings
:apply_settings
cls
echo =======================================================
echo   Applying DNS Settings to "%adapter_name%"
echo =======================================================
echo.

if "%dns_choice%"=="1" (
    echo Setting Google Public DNS IPv4:
    netsh interface ipv4 set dnsservers name="%adapter_name%" static 8.8.8.8 primary
    netsh interface ipv4 add dnsservers name="%adapter_name%" address=8.8.4.4 index=2
)

if "%dns_choice%"=="2" (
    echo Setting Cloudflare DNS IPv4:
    netsh interface ipv4 set dnsservers name="%adapter_name%" static 1.1.1.1 primary
    netsh interface ipv4 add dnsservers name="%adapter_name%" address=1.0.0.1 index=2
)

if "%dns_choice%"=="3" (
    echo Setting OpenDNS IPv4:
    netsh interface ipv4 set dnsservers name="%adapter_name%" static 208.67.222.222 primary
    netsh interface ipv4 add dnsservers name="%adapter_name%" address=208.67.220.220 index=2
)

if "%dns_choice%"=="4" (
    echo Resetting to DHCP settings IPv4:
    netsh interface ipv4 set dnsservers name="%adapter_name%" source=dhcp
)

echo.
echo SUCCESS: DNS settings applied successfully
echo.
echo Press any key to exit...
pause >nul
exit /b

:error
echo.
echo ERROR: Operation failed with error code %errorlevel%
echo Please try again or contact support
echo.
pause
exit /b