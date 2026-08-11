[CmdletBinding()]
param(
    [string]$ProjectDir = (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
)

$ErrorActionPreference = 'Stop'
$serviceDir = Join-Path $ProjectDir 'tools\service'
$sourcePath = Join-Path $serviceDir 'GoodbyeZapretService.cs'
$outputPath = Join-Path $serviceDir 'GoodbyeZapretService.exe'
$temporaryOutput = Join-Path $serviceDir 'GoodbyeZapretService.new.exe'

if (-not (Test-Path -LiteralPath $sourcePath -PathType Leaf)) {
    throw "Service source not found: $sourcePath"
}

$compilerCandidates = @(
    (Join-Path $env:WINDIR 'Microsoft.NET\Framework64\v4.0.30319\csc.exe'),
    (Join-Path $env:WINDIR 'Microsoft.NET\Framework\v4.0.30319\csc.exe'),
    (Join-Path ([Runtime.InteropServices.RuntimeEnvironment]::GetRuntimeDirectory()) 'csc.exe')
)
$compilerPath = $compilerCandidates | Where-Object { Test-Path -LiteralPath $_ -PathType Leaf } | Select-Object -First 1
if (-not (Test-Path -LiteralPath $compilerPath -PathType Leaf)) {
    throw 'C# compiler for .NET Framework 4 was not found.'
}

if (Test-Path -LiteralPath $temporaryOutput) {
    Remove-Item -LiteralPath $temporaryOutput -Force
}

try {
    & $compilerPath /nologo /optimize+ /target:exe /platform:anycpu `
        /reference:System.dll /reference:System.Core.dll /reference:System.ServiceProcess.dll `
        "/out:$temporaryOutput" $sourcePath
    if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $temporaryOutput)) {
        throw "Service compilation failed with exit code $LASTEXITCODE."
    }

    Move-Item -LiteralPath $temporaryOutput -Destination $outputPath -Force
    Write-Host "Built service: $outputPath"
}
finally {
    if (Test-Path -LiteralPath $temporaryOutput) {
        Remove-Item -LiteralPath $temporaryOutput -Force -ErrorAction SilentlyContinue
    }
}
