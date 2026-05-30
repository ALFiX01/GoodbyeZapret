param(
    [string]$ProjectDir
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

if (-not $ProjectDir) {
    $ProjectDir = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot "..\.."))
}
else {
    $ProjectDir = [System.IO.Path]::GetFullPath($ProjectDir)
}

$serviceDir = $PSScriptRoot
$sourcePath = Join-Path $serviceDir "GoodbyeZapretService.cs"
$outputPath = Join-Path $serviceDir "GoodbyeZapretService.exe"
$legacyPaths = @(
    (Join-Path $ProjectDir "tools\GoodbyeZapretService.exe"),
    (Join-Path $ProjectDir "tools\GoodbyeZapretService.cs"),
    (Join-Path $ProjectDir "tools\BuildGoodbyeZapretService.ps1")
)

foreach ($legacyPath in $legacyPaths) {
    if (Test-Path -LiteralPath $legacyPath -PathType Leaf) {
        Remove-Item -LiteralPath $legacyPath -Force -ErrorAction SilentlyContinue
    }
}

if (-not (Test-Path -LiteralPath $sourcePath -PathType Leaf)) {
    throw "Service source not found: $sourcePath"
}

$needsBuild = -not (Test-Path -LiteralPath $outputPath -PathType Leaf)
if (-not $needsBuild) {
    $sourceTime = (Get-Item -LiteralPath $sourcePath).LastWriteTimeUtc
    $outputTime = (Get-Item -LiteralPath $outputPath).LastWriteTimeUtc
    $needsBuild = $sourceTime -gt $outputTime
}

if (-not $needsBuild) {
    exit 0
}

Add-Type `
    -Path $sourcePath `
    -ReferencedAssemblies @("System.ServiceProcess.dll") `
    -OutputAssembly $outputPath `
    -OutputType ConsoleApplication

if (-not (Test-Path -LiteralPath $outputPath -PathType Leaf)) {
    throw "Failed to build service wrapper: $outputPath"
}
