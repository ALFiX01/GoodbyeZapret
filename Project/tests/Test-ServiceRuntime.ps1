[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$projectDir = Split-Path -Parent $PSScriptRoot
$serviceDir = Join-Path $projectDir 'tools\service'
$buildScript = Join-Path $serviceDir 'BuildGoodbyeZapretService.ps1'
$serviceExe = Join-Path $serviceDir 'GoodbyeZapretService.exe'
$tempRoot = Join-Path ([IO.Path]::GetTempPath()) ('GoodbyeZapret-ServiceTest-' + [guid]::NewGuid().ToString('N'))
$unrelated = $null
$projectEngine = $null

function Assert-True {
    param([bool]$Condition, [string]$Message)
    if (-not $Condition) {
        throw "ASSERTION FAILED: $Message"
    }
}

try {
    Assert-True (Test-Path -LiteralPath $buildScript) 'service build script must be packaged'

    & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $buildScript -ProjectDir $projectDir
    Assert-True ($LASTEXITCODE -eq 0) 'service build must succeed'
    Assert-True (Test-Path -LiteralPath $serviceExe) 'service executable must exist after build'

    New-Item -ItemType Directory -Path $tempRoot -Force | Out-Null
    $serviceUnderTest = Join-Path $tempRoot 'ServiceHostUnderTest.exe'
    Copy-Item -LiteralPath $serviceExe -Destination $serviceUnderTest
    $testProject = Join-Path $tempRoot 'project'
    $testBin = Join-Path $testProject 'bin'
    $testConfigs = Join-Path $testProject 'configs'
    $otherBin = Join-Path $tempRoot 'other'
    New-Item -ItemType Directory -Path $testBin,$testConfigs,$otherBin -Force | Out-Null

    $fakeSource = Join-Path $tempRoot 'FakeEngine.cs'
    $fakeCode = @'
using System;
using System.IO;
using System.Threading;

internal static class Program
{
    public static int Main(string[] args)
    {
        string statePath = null;
        string sequence = "0";
        bool stay = false;
        foreach (string arg in args)
        {
            if (arg.StartsWith("--state=", StringComparison.OrdinalIgnoreCase)) statePath = arg.Substring(8).Trim('"');
            else if (arg.StartsWith("--sequence=", StringComparison.OrdinalIgnoreCase)) sequence = arg.Substring(11);
            else if (arg == "--stay") stay = true;
        }

        Console.WriteLine("ENGINE_STDOUT");
        Console.Error.WriteLine("ENGINE_STDERR");
        if (stay)
        {
            Thread.Sleep(30000);
            return 0;
        }

        int attempt = 0;
        if (!String.IsNullOrEmpty(statePath) && File.Exists(statePath))
            Int32.TryParse(File.ReadAllText(statePath), out attempt);
        attempt++;
        if (!String.IsNullOrEmpty(statePath)) File.WriteAllText(statePath, attempt.ToString());

        string[] codes = sequence.Split(',');
        int index = Math.Min(attempt - 1, codes.Length - 1);
        int code;
        return Int32.TryParse(codes[index], out code) ? code : 1;
    }
}
'@
    [IO.File]::WriteAllText($fakeSource, $fakeCode, [Text.UTF8Encoding]::new($false))

    $frameworkDir = [Runtime.InteropServices.RuntimeEnvironment]::GetRuntimeDirectory()
    $csc = Join-Path $frameworkDir 'csc.exe'
    Assert-True (Test-Path -LiteralPath $csc) 'C# compiler must be available'
    & $csc /nologo /target:exe /out:"$testBin\winws2.exe" $fakeSource
    Assert-True ($LASTEXITCODE -eq 0) 'fake engine compilation must succeed'
    Copy-Item -LiteralPath (Join-Path $testBin 'winws2.exe') -Destination (Join-Path $otherBin 'winws2.exe')

    $fakeProbeState = Join-Path $tempRoot 'fake-probe.txt'
    $fakeProbe = Start-Process -FilePath (Join-Path $testBin 'winws2.exe') `
        -ArgumentList ('--state="' + $fakeProbeState + '" --sequence=177') -PassThru -Wait -WindowStyle Hidden
    Assert-True ($fakeProbe.ExitCode -eq 177) ('fake engine must return the requested code, got ' + $fakeProbe.ExitCode)
    Assert-True (Test-Path -LiteralPath $fakeProbeState) 'fake engine probe must create its state file'

    $unrelated = Start-Process -FilePath (Join-Path $otherBin 'winws2.exe') -ArgumentList '--stay' -PassThru -WindowStyle Hidden
    Start-Sleep -Milliseconds 200
    Assert-True (-not $unrelated.HasExited) 'unrelated engine must start'

    $statePath = Join-Path $tempRoot 'attempts.txt'
    $logPath = Join-Path $tempRoot 'service.log'
    $presetPath = Join-Path $testConfigs 'test.txt'
    @(
        '# Preset: service runtime test'
        '# Engine: winws2.exe'
        ('--state="' + $statePath + '"')
        '--sequence=177,10,0'
    ) | Set-Content -LiteralPath $presetPath -Encoding UTF8

    $serviceArgumentLine = '--console --preset "{0}" --project-dir "{1}" --max-restarts 2 --restart-delay-ms 50' -f `
        $presetPath, $testProject
    $serviceStartInfo = New-Object Diagnostics.ProcessStartInfo
    $serviceStartInfo.FileName = $serviceUnderTest
    $serviceStartInfo.Arguments = $serviceArgumentLine
    $serviceStartInfo.UseShellExecute = $false
    $serviceStartInfo.CreateNoWindow = $true
    $serviceStartInfo.EnvironmentVariables['GOODBYEZAPRET_LOG_PATH'] = $logPath
    $serviceProcess = [Diagnostics.Process]::Start($serviceStartInfo)
    $serviceProcess.WaitForExit()

    Assert-True ($serviceProcess.ExitCode -ne 0) 'unexpected engine termination must fail the host'
    Assert-True (-not $unrelated.HasExited) 'service must not kill an unrelated winws2 process'
    $log = if (Test-Path -LiteralPath $logPath) { Get-Content -LiteralPath $logPath -Raw } else { '<log file missing>' }
    Assert-True (Test-Path -LiteralPath $statePath) ("engine state file must be created. Exit: " + $serviceProcess.ExitCode + ". Log: " + $log)
    Assert-True ((Get-Content -LiteralPath $statePath -Raw).Trim() -eq '3') 'engine must be restarted exactly twice'

    Assert-True ($log.Contains('ENGINE_STDOUT')) 'engine stdout must be captured'
    Assert-True ($log.Contains('ENGINE_STDERR')) 'engine stderr must be captured'
    Assert-True ($log.Contains('Restarting engine')) 'restart attempts must be logged'
    Assert-True ($log.Contains('Engine exited with code 177')) 'first engine exit code must be logged'
    Assert-True ($log.Contains('Engine exited with code 10')) 'second engine exit code must be logged'
    Assert-True ($log.Contains('Engine exited with code 0')) 'clean but unexpected engine exit must be logged'

    $projectEngine = Start-Process -FilePath (Join-Path $testBin 'winws2.exe') -ArgumentList '--stay' -PassThru -WindowStyle Hidden
    Start-Sleep -Milliseconds 200
    $replacementPreset = Join-Path $testConfigs 'replacement.txt'
    @(
        '# Preset: interactive replacement test'
        '# Engine: winws2.exe'
        '--sequence=0'
    ) | Set-Content -LiteralPath $replacementPreset -Encoding UTF8
    & powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $projectDir 'tools\PresetRunner.ps1') `
        -Preset $replacementPreset -ProjectDir $testProject -Mode Interactive -NoTray -Quiet -ErrorDisplaySeconds 0
    Assert-True ($LASTEXITCODE -eq 1) 'short-lived replacement engine must be reported as failed'
    $projectEngine.Refresh()
    $unrelated.Refresh()
    Assert-True ($projectEngine.HasExited) 'interactive runner must replace an engine from the current project'
    Assert-True (-not $unrelated.HasExited) 'interactive runner must leave another project engine untouched'

    $serviceSource = Get-Content -LiteralPath (Join-Path $serviceDir 'GoodbyeZapretService.cs') -Raw
    Assert-True (-not $serviceSource.Contains('GetProcessesByName')) 'service source must not kill engines by global process name'

    $presetRunner = Get-Content -LiteralPath (Join-Path $projectDir 'tools\PresetRunner.ps1') -Raw
    Assert-True (-not $presetRunner.Contains('GetProcessesByName')) 'fallback runner must not kill engines by global process name'
    Assert-True ($presetRunner.Contains('StartsWith($binDir')) 'interactive runner must scope replacement to the current project bin directory'

    $launcher = Get-Content -LiteralPath (Join-Path $projectDir 'Launcher.bat') -Raw
    Assert-True ($launcher.Contains('if not "!ServiceCreateError!"=="0"')) 'Launcher must reject every nonzero sc/create result'
    Assert-True ($launcher.Contains('sc failure "GoodbyeZapret"')) 'Launcher must configure service recovery'

    $updater = Get-Content -LiteralPath (Join-Path $projectDir 'tools\updater_for_zip-ver.bat') -Raw
    Assert-True ($updater.Contains('if errorlevel 1')) 'updater must check service command failures'

    $diagnostics = Get-Content -LiteralPath (Join-Path $projectDir 'StartupDiagnostics.ps1') -Raw
    Assert-True ($diagnostics.Contains('tools\service\BuildGoodbyeZapretService.ps1')) 'startup diagnostics must verify the build script'

    Write-Host 'Service runtime tests passed.' -ForegroundColor Green
}
finally {
    if ($projectEngine -and -not $projectEngine.HasExited) {
        Stop-Process -Id $projectEngine.Id -Force -ErrorAction SilentlyContinue
        $null = $projectEngine.WaitForExit(3000)
    }
    if ($unrelated -and -not $unrelated.HasExited) {
        Stop-Process -Id $unrelated.Id -Force -ErrorAction SilentlyContinue
        $null = $unrelated.WaitForExit(3000)
    }
    if (Test-Path -LiteralPath $tempRoot) {
        Remove-Item -LiteralPath $tempRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
}
