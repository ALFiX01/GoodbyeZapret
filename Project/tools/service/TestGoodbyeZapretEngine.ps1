param(
    [Parameter(Mandatory = $true)]
    [string]$ProjectDir,
    [switch]$Interactive
)

$ErrorActionPreference = 'Stop'

try {
    $projectDir = [System.IO.Path]::GetFullPath($ProjectDir)
    $servicePath = [System.IO.Path]::GetFullPath((Join-Path $projectDir 'tools\service\GoodbyeZapretService.exe'))
    $enginePaths = @(
        [System.IO.Path]::GetFullPath((Join-Path $projectDir 'bin\winws.exe')),
        [System.IO.Path]::GetFullPath((Join-Path $projectDir 'bin\winws2.exe'))
    )

    $service = Get-CimInstance Win32_Service -Filter "Name='GoodbyeZapret'"
    $engines = @()
    if (-not $Interactive -and $service -and $service.State -eq 'Running' -and $service.ProcessId -gt 0) {
        $serviceProcess = Get-CimInstance Win32_Process -Filter "ProcessId=$($service.ProcessId)"
        if (-not $serviceProcess -or
            -not [string]::Equals($serviceProcess.ExecutablePath, $servicePath, [System.StringComparison]::OrdinalIgnoreCase)) {
            exit 1
        }
        $engines = Get-CimInstance Win32_Process -Filter "ParentProcessId=$($service.ProcessId)"
    } elseif ($Interactive -or -not $service -or $service.State -ne 'Running') {
        # Interactive presets are launched directly; constrain the result to this project's bin.
        $engines = Get-CimInstance Win32_Process -Filter "Name='winws.exe' OR Name='winws2.exe'"
    } else {
        exit 1
    }
    foreach ($engine in $engines) {
        foreach ($enginePath in $enginePaths) {
            if ([string]::Equals($engine.ExecutablePath, $enginePath, [System.StringComparison]::OrdinalIgnoreCase)) {
                exit 0
            }
        }
    }
} catch {
    exit 1
}

exit 1
