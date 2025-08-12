@echo off
setlocal enabledelayedexpansion
cls

:: Ensure working directory is the script's directory
cd /d "%~dp0"

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

:: Use PowerShell to get adapters with IPv4 gateway and status Up
for /f "usebackq delims=" %%a in (`powershell -NoProfile -Command "Get-NetIPConfiguration | Where-Object { $_.IPv4DefaultGateway -ne $null -and $_.NetAdapter.Status -eq 'Up' } | Select-Object -ExpandProperty InterfaceAlias"`) do (
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

:: Numeric validation to avoid invalid/non-numeric input
echo(%choice%| findstr /r "^[0-9][0-9]*$" >nul || (
    echo Invalid input. Please enter a number between 1 and %count%.
    goto adapter_prompt
)
set /a test=%choice%

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
powershell -Command "Write-Host 'IPv4:' -ForegroundColor DarkGray"
for /f "tokens=*" %%a in ('netsh interface ipv4 show dnsservers name^="%adapter_name%" ^| findstr /i "DNS"') do (
    powershell -Command "Write-Host '%%a' -ForegroundColor Blue"
)
echo.
powershell -Command "Write-Host 'IPv6:' -ForegroundColor DarkGray"
for /f "tokens=*" %%a in ('netsh interface ipv6 show dnsservers interface^="%adapter_name%" ^| findstr /i "DNS"') do (
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
echo [1] Google DNS (IPv4+IPv6)
echo [2] Cloudflare DNS (IPv4+IPv6)
echo [3] OpenDNS (IPv4+IPv6)
powershell -Command "Write-Host '[4] Reset to DHCP (IPv4+IPv6)' -ForegroundColor Red"
echo [5] Custom DNS...
echo [6] Flush DNS cache
echo [7] Test DNS resolution
echo [8] Exit Without Changes
echo.

:: DNS choice loop
:dns_prompt
set "dns_choice="
set /p dns_choice="Enter your choice (1-8): "

:: Remove spaces
set "dns_choice=%dns_choice: =%"

:: Validate input
if not defined dns_choice (
    echo Please enter a value.
    goto dns_prompt
)

if not "%dns_choice%"=="1" if not "%dns_choice%"=="2" ^
if not "%dns_choice%"=="3" if not "%dns_choice%"=="4" ^
if not "%dns_choice%"=="5" if not "%dns_choice%"=="6" ^
if not "%dns_choice%"=="7" if not "%dns_choice%"=="8" (
    echo Invalid choice. Please enter 1-8.
    goto dns_prompt
)

if "%dns_choice%"=="8" (
    echo.
    echo Exiting without changes...
    timeout /t 2 >nul
    exit /b
)

if "%dns_choice%"=="6" goto flush_dns
if "%dns_choice%"=="7" goto test_dns
if "%dns_choice%"=="5" goto custom_dns

:: Confirmation screen
cls
echo =======================================================
echo              DNS Configuration Utility
echo =======================================================
echo.
echo WARNING: This will overwrite your current DNS settings
echo.
echo You selected option [%dns_choice%]:
if "%dns_choice%"=="1" echo Configure Google DNS IPv4: 8.8.8.8, 8.8.4.4 ^| IPv6: 2001:4860:4860::8888, 2001:4860:4860::8844
if "%dns_choice%"=="2" echo Configure Cloudflare DNS IPv4: 1.1.1.1, 1.0.0.1 ^| IPv6: 2606:4700:4700::1111, 2606:4700:4700::1001
if "%dns_choice%"=="3" echo Configure OpenDNS IPv4: 208.67.222.222, 208.67.220.220 ^| IPv6: 2620:119:35::35, 2620:119:53::53
if "%dns_choice%"=="4" echo Reset to DHCP settings (IPv4+IPv6)
if "%dns_choice%"=="5" (
    echo Custom DNS configuration:
    if defined CUSTOM_V4_PRIMARY echo   IPv4 primary: %CUSTOM_V4_PRIMARY%
    if defined CUSTOM_V4_SECONDARY echo   IPv4 secondary: %CUSTOM_V4_SECONDARY%
    if not defined CUSTOM_V4_PRIMARY if not defined CUSTOM_V4_SECONDARY echo   IPv4: no changes
    if defined CUSTOM_V6_PRIMARY echo   IPv6 primary: %CUSTOM_V6_PRIMARY%
    if defined CUSTOM_V6_SECONDARY echo   IPv6 secondary: %CUSTOM_V6_SECONDARY%
    if not defined CUSTOM_V6_PRIMARY if not defined CUSTOM_V6_SECONDARY echo   IPv6: no changes
)
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
    echo Setting Google DNS IPv4:
    netsh interface ipv4 set dnsservers name="%adapter_name%" static 8.8.8.8 primary
    if errorlevel 1 goto error
    netsh interface ipv4 add dnsservers name="%adapter_name%" address=8.8.4.4 index=2
    if errorlevel 1 goto error
    echo Setting Google DNS IPv6:
    netsh interface ipv6 set dnsservers interface="%adapter_name%" static 2001:4860:4860::8888 primary
    if errorlevel 1 goto error
    netsh interface ipv6 add dnsservers interface="%adapter_name%" address=2001:4860:4860::8844 index=2
    if errorlevel 1 goto error
)

if "%dns_choice%"=="2" (
    echo Setting Cloudflare DNS IPv4:
    netsh interface ipv4 set dnsservers name="%adapter_name%" static 1.1.1.1 primary
    if errorlevel 1 goto error
    netsh interface ipv4 add dnsservers name="%adapter_name%" address=1.0.0.1 index=2
    if errorlevel 1 goto error
    echo Setting Cloudflare DNS IPv6:
    netsh interface ipv6 set dnsservers interface="%adapter_name%" static 2606:4700:4700::1111 primary
    if errorlevel 1 goto error
    netsh interface ipv6 add dnsservers interface="%adapter_name%" address=2606:4700:4700::1001 index=2
    if errorlevel 1 goto error
)

if "%dns_choice%"=="3" (
    echo Setting OpenDNS IPv4:
    netsh interface ipv4 set dnsservers name="%adapter_name%" static 208.67.222.222 primary
    if errorlevel 1 goto error
    netsh interface ipv4 add dnsservers name="%adapter_name%" address=208.67.220.220 index=2
    if errorlevel 1 goto error
    echo Setting OpenDNS IPv6:
    netsh interface ipv6 set dnsservers interface="%adapter_name%" static 2620:119:35::35 primary
    if errorlevel 1 goto error
    netsh interface ipv6 add dnsservers interface="%adapter_name%" address=2620:119:53::53 index=2
    if errorlevel 1 goto error
)

if "%dns_choice%"=="4" (
    echo Resetting to DHCP settings IPv4:
    netsh interface ipv4 set dnsservers name="%adapter_name%" source=dhcp
    if errorlevel 1 goto error
    echo Clearing IPv6 DNS server list (auto):
    netsh interface ipv6 delete dnsservers interface="%adapter_name%" all
    if errorlevel 1 goto error
)

if "%dns_choice%"=="5" (
    if defined CUSTOM_V4_PRIMARY (
        echo Setting custom IPv4 primary: %CUSTOM_V4_PRIMARY%
        netsh interface ipv4 set dnsservers name="%adapter_name%" static %CUSTOM_V4_PRIMARY% primary
        if errorlevel 1 goto error
        if defined CUSTOM_V4_SECONDARY (
            echo Adding custom IPv4 secondary: %CUSTOM_V4_SECONDARY%
            netsh interface ipv4 add dnsservers name="%adapter_name%" address=%CUSTOM_V4_SECONDARY% index=2
            if errorlevel 1 goto error
        )
    )
    if defined CUSTOM_V6_PRIMARY (
        echo Setting custom IPv6 primary: %CUSTOM_V6_PRIMARY%
        netsh interface ipv6 set dnsservers interface="%adapter_name%" static %CUSTOM_V6_PRIMARY% primary
        if errorlevel 1 goto error
        if defined CUSTOM_V6_SECONDARY (
            echo Adding custom IPv6 secondary: %CUSTOM_V6_SECONDARY%
            netsh interface ipv6 add dnsservers interface="%adapter_name%" address=%CUSTOM_V6_SECONDARY% index=2
            if errorlevel 1 goto error
        )
    )
)

echo.
echo SUCCESS: DNS settings applied successfully
echo.
echo Flushing DNS cache...
ipconfig /flushdns >nul 2>&1
echo DNS cache flushed.
echo.
echo Press any key to exit...
pause >nul
exit /b

:custom_dns
cls
echo =======================================================
echo              Custom DNS Configuration
echo =======================================================
echo.
set "CUSTOM_V4_PRIMARY="
set "CUSTOM_V4_SECONDARY="
set "CUSTOM_V6_PRIMARY="
set "CUSTOM_V6_SECONDARY="
set /p CUSTOM_V4_PRIMARY="Enter IPv4 primary DNS (leave blank to skip): "
set /p CUSTOM_V4_SECONDARY="Enter IPv4 secondary DNS (optional): "
set /p CUSTOM_V6_PRIMARY="Enter IPv6 primary DNS (leave blank to skip): "
set /p CUSTOM_V6_SECONDARY="Enter IPv6 secondary DNS (optional): "
goto apply_confirm

:flush_dns
cls
echo =======================================================
echo                  Flushing DNS cache
echo =======================================================
echo.
ipconfig /flushdns
echo.
echo Press any key to return to menu...
pause >nul
goto menu

:test_dns
cls
echo =======================================================
echo                 Testing DNS resolution
echo =======================================================
echo.
echo Running: nslookup cloudflare.com
nslookup cloudflare.com
echo.
echo Press any key to return to menu...
pause >nul
goto menu

:apply_confirm
cls
echo =======================================================
echo              DNS Configuration Utility
echo =======================================================
echo.
echo WARNING: This will overwrite your current DNS settings
echo.
echo You selected option [5]:
echo Custom DNS configuration
if defined CUSTOM_V4_PRIMARY echo   IPv4 primary: %CUSTOM_V4_PRIMARY%
if defined CUSTOM_V4_SECONDARY echo   IPv4 secondary: %CUSTOM_V4_SECONDARY%
if not defined CUSTOM_V4_PRIMARY if not defined CUSTOM_V4_SECONDARY echo   IPv4: no changes
if defined CUSTOM_V6_PRIMARY echo   IPv6 primary: %CUSTOM_V6_PRIMARY%
if defined CUSTOM_V6_SECONDARY echo   IPv6 secondary: %CUSTOM_V6_SECONDARY%
if not defined CUSTOM_V6_PRIMARY if not defined CUSTOM_V6_SECONDARY echo   IPv6: no changes
echo.
echo [Y] Yes - Apply Changes
echo [N] No - Return to Menu
echo.
goto confirm_prompt
:error
echo.
echo ERROR: Operation failed with error code %errorlevel%
echo Please try again or contact support
echo.
pause
exit /b