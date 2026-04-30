param(
    [Parameter(Mandatory = $true)]
    [string]$PresetFile,

    [string]$ProjectDir,

    [switch]$ServiceMode
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Convert-ToWindowsPath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Value
    )

    return ($Value -replace '/', '\')
}

function Format-ResolvedPath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$AbsolutePath,

        [switch]$UseAtPrefix
    )

    $prefix = if ($UseAtPrefix) { '@' } else { '' }
    return $prefix + '"' + $AbsolutePath + '"'
}

function Resolve-PresetDependencyPath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$RelativePath,

        [Parameter(Mandatory = $true)]
        [string]$BaseDir
    )

    $resolvedPath = Join-Path $BaseDir (Convert-ToWindowsPath $RelativePath)
    $resolvedPath = [System.IO.Path]::GetFullPath($resolvedPath)

    if (-not (Test-Path -LiteralPath $resolvedPath)) {
        throw "Preset dependency not found: $resolvedPath"
    }

    return $resolvedPath
}

function Resolve-PresetArgument {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Value,

        [Parameter(Mandatory = $true)]
        [string]$ProjectDir
    )

    $binDir = Join-Path $ProjectDir "bin"
    $listsDir = Join-Path $ProjectDir "lists"
    $fakeDir = Join-Path $binDir "fake"
    $luaDir = Join-Path $binDir "lua"
    $windivertFilterDir = Join-Path $binDir "windivert.filter"

    $resolvedValue = $Value
    $resolvedValue = $resolvedValue.Replace("{{PROJECT}}", ($ProjectDir.TrimEnd("\") + "\"))
    $resolvedValue = $resolvedValue.Replace("{{BIN}}", ($binDir.TrimEnd("\") + "\"))
    $resolvedValue = $resolvedValue.Replace("{{LISTS}}", ($listsDir.TrimEnd("\") + "\"))
    $resolvedValue = $resolvedValue.Replace("{{FAKE}}", ($fakeDir.TrimEnd("\") + "\"))

    $patternMap = @(
        @{
            Pattern = '(?i)@lua/(?<path>[^"\s]+)'
            BaseDir = $luaDir
            UseAtPrefix = $true
        },
        @{
            Pattern = '(?i)@windivert\.filter/(?<path>[^"\s]+)'
            BaseDir = $windivertFilterDir
            UseAtPrefix = $true
        },
        @{
            Pattern = '(?i)@bin/(?<path>[^"\s]+)'
            BaseDir = $fakeDir
            UseAtPrefix = $true
        },
        @{
            Pattern = '(?i)(?<![@A-Za-z0-9_.-])lists/(?<path>[^"\s]+)'
            BaseDir = $listsDir
            UseAtPrefix = $false
        }
    )

    foreach ($mapping in $patternMap) {
        $resolvedValue = [System.Text.RegularExpressions.Regex]::Replace(
            $resolvedValue,
            $mapping.Pattern,
            {
                param($match)

                $absolutePath = Resolve-PresetDependencyPath -RelativePath $match.Groups['path'].Value -BaseDir $mapping.BaseDir
                return Format-ResolvedPath -AbsolutePath $absolutePath -UseAtPrefix:$mapping.UseAtPrefix
            }
        )
    }

    return $resolvedValue
}

function Test-EmptyPortArgument {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Value
    )

    $trimmed = $Value.Trim()
    return $trimmed -match '^(?i)--(?:wf-(?:tcp|udp)(?:-(?:in|out))?|filter-(?:tcp|udp))=(?:""|''''|\s*)$'
}

if (-not $ProjectDir) {
    $ProjectDir = Split-Path -Parent $PSScriptRoot
}

$ProjectDir = [System.IO.Path]::GetFullPath($ProjectDir)
$PresetPath = [System.IO.Path]::GetFullPath($PresetFile)

if (-not (Test-Path -LiteralPath $PresetPath)) {
    throw "Preset not found: $PresetPath"
}

$binDir = Join-Path $ProjectDir "bin"
$exeName = "winws2.exe"
$args = New-Object System.Collections.Generic.List[string]

foreach ($line in Get-Content -LiteralPath $PresetPath -Encoding UTF8) {
    $trimmed = $line.Trim()
    if (-not $trimmed) {
        continue
    }

    if ($trimmed.StartsWith("#")) {
        if ($trimmed -match '^(?i)#\s*Engine\s*:\s*(.+?)\s*$') {
            $exeName = $matches[1].Trim()
        }
        continue
    }

    $value = $trimmed
    $value = Resolve-PresetArgument -Value $value -ProjectDir $ProjectDir
    if (Test-EmptyPortArgument -Value $value) {
        continue
    }
    $args.Add($value)
}

if ($args.Count -eq 0) {
    throw "Preset is empty: $PresetPath"
}

$exePath = Join-Path $binDir $exeName
if (-not (Test-Path -LiteralPath $exePath)) {
    throw "Engine not found: $exePath"
}

$logPath = Join-Path $ProjectDir "tools\Run_Config_Preset.log"

function Write-ServiceLog {
    param([string]$Message)

    if (-not $ServiceMode) {
        return
    }

    $stamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Add-Content -LiteralPath $logPath -Encoding UTF8 -Value "[$stamp] $Message"
}

Write-ServiceLog "Starting preset: $PresetPath"
Write-ServiceLog "Engine: $exePath"

$startParams = @{
    FilePath = $exePath
    ArgumentList = $args
    WorkingDirectory = $binDir
    PassThru = $true
}

if (-not $ServiceMode -and [Environment]::UserInteractive) {
    $startParams.WindowStyle = "Minimized"
}

$process = Start-Process @startParams

if ($ServiceMode) {
    Start-Sleep -Milliseconds 700
    if ($process.HasExited) {
        Write-ServiceLog "Engine exited during startup with code $($process.ExitCode)."
        exit $process.ExitCode
    }

    Write-ServiceLog "Engine started with PID $($process.Id). Waiting for process exit."
    $process.WaitForExit()
    Write-ServiceLog "Engine exited with code $($process.ExitCode)."
    exit $process.ExitCode
}

$trayPath = Join-Path $ProjectDir "tools\tray\GoodbyeZapretTray.exe"
if (-not $ServiceMode -and (Test-Path -LiteralPath $trayPath)) {
    if (-not (Get-Process -Name "GoodbyeZapretTray" -ErrorAction SilentlyContinue)) {
        Start-Process -FilePath $trayPath | Out-Null
    }
}
