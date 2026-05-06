param(
    [Parameter(Mandatory = $true)]
    [string]$ProjectDir
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$resolvedProjectDir = [System.IO.Path]::GetFullPath($ProjectDir)
$trayDir = Join-Path $resolvedProjectDir "tools\tray"
$trayLauncher = Join-Path $trayDir "GoodbyeZapretTray.exe"
$trayRuntime = Join-Path $resolvedProjectDir "tools\tray-runtime\GoodbyeZapretTray.exe"

if (-not (Test-Path -LiteralPath $trayLauncher)) {
    throw "Tray launcher not found: $trayLauncher"
}

if (-not (Test-Path -LiteralPath $trayRuntime)) {
    throw "Tray runtime not found: $trayRuntime"
}

$user = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
$action = New-ScheduledTaskAction -Execute $trayLauncher -WorkingDirectory $trayDir
$trigger = New-ScheduledTaskTrigger -AtLogOn -User $user
$trigger.Delay = "PT30S"

$principal = New-ScheduledTaskPrincipal -UserId $user -LogonType Interactive -RunLevel Limited
$settings = New-ScheduledTaskSettingsSet `
    -AllowStartIfOnBatteries `
    -DontStopIfGoingOnBatteries `
    -StartWhenAvailable `
    -MultipleInstances IgnoreNew `
    -RestartCount 3 `
    -RestartInterval (New-TimeSpan -Minutes 1) `
    -ExecutionTimeLimit ([TimeSpan]::Zero)

$existingTask = Get-ScheduledTask -TaskName "GoodbyeZapretTray" -ErrorAction SilentlyContinue
if ($existingTask) {
    Unregister-ScheduledTask -TaskName "GoodbyeZapretTray" -Confirm:$false
}

Register-ScheduledTask `
    -TaskName "GoodbyeZapretTray" `
    -Action $action `
    -Trigger $trigger `
    -Principal $principal `
    -Settings $settings `
    -Force | Out-Null

$task = Get-ScheduledTask -TaskName "GoodbyeZapretTray"
if (-not $task) {
    throw "Failed to register GoodbyeZapretTray task"
}
