param(
    [Parameter(Mandatory = $true)]
    [string]$ProjectDir
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$resolvedProjectDir = [System.IO.Path]::GetFullPath($ProjectDir)
$trayDir = Join-Path $resolvedProjectDir "tools\tray"
$trayExe = Join-Path $trayDir "GoodbyeZapretTray.exe"

if (-not (Test-Path -LiteralPath $trayExe)) {
    throw "Tray executable not found: $trayExe"
}

$user = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
$action = New-ScheduledTaskAction -Execute $trayExe -WorkingDirectory $trayDir
$trigger = New-ScheduledTaskTrigger -AtLogOn -User $user
$trigger.Delay = "PT30S"

$principal = New-ScheduledTaskPrincipal -UserId $user -LogonType Interactive -RunLevel Highest
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
    $existingAction = @($existingTask.Actions | Where-Object { $_.CimClass.CimClassName -like "*ExecAction" } | Select-Object -First 1)
    $existingRunLevel = [string]$existingTask.Principal.RunLevel
    $existingCommand = if ($existingAction) { [string]$existingAction.Execute } else { "" }
    $existingWorkingDirectory = if ($existingAction) { [string]$existingAction.WorkingDirectory } else { "" }

    if (
        [string]::Equals($existingCommand, $trayExe, [System.StringComparison]::OrdinalIgnoreCase) -and
        [string]::Equals($existingWorkingDirectory, $trayDir, [System.StringComparison]::OrdinalIgnoreCase) -and
        $existingRunLevel -match "Highest"
    ) {
        exit 0
    }

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
