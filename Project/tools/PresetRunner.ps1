param(
    [Alias("PresetFile")]
    [string]$Preset,

    [string]$ProjectDir,

    [ValidateSet("Interactive", "Service")]
    [string]$Mode = "Interactive",

    [switch]$ServiceMode,

    [switch]$ValidateOnly,

    [switch]$ValidateAll,

    [switch]$PreserveExistingProcess,

    [switch]$NoTray,

    [int]$ErrorDisplaySeconds = 10,

    [switch]$Quiet
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

if ($ServiceMode) {
    $Mode = "Service"
}

function Write-RunnerMessage {
    param(
        [string]$Message,
        [string]$Level = "INFO"
    )

    if ($Quiet -or $Mode -eq "Service") {
        return
    }

    $prefix = switch ($Level) {
        "OK" { "[OK]" }
        "WARN" { "[WARN]" }
        "ERROR" { "[ERROR]" }
        default { "[INFO]" }
    }

    Write-Host (" " + $prefix + " " + $Message)
}

function Get-DefaultProjectDir {
    return [System.IO.Path]::GetFullPath((Split-Path -Parent $PSScriptRoot))
}

function Convert-ToWindowsPath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Value
    )

    return ($Value -replace '/', '\')
}

function Resolve-ExistingPath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $true)]
        [string]$BaseDir,

        [string]$Description = "Path",

        [switch]$AllowCurrentDirectoryFallback
    )

    $windowsPath = Convert-ToWindowsPath $Path
    if ([System.IO.Path]::IsPathRooted($windowsPath)) {
        $resolvedPath = [System.IO.Path]::GetFullPath($windowsPath)
    }
    else {
        $resolvedPath = [System.IO.Path]::GetFullPath((Join-Path $BaseDir $windowsPath))
    }

    if (-not (Test-Path -LiteralPath $resolvedPath)) {
        if ($AllowCurrentDirectoryFallback -and -not [System.IO.Path]::IsPathRooted($windowsPath)) {
            $currentDirectoryPath = [System.IO.Path]::GetFullPath($windowsPath)
            if (Test-Path -LiteralPath $currentDirectoryPath) {
                return $currentDirectoryPath
            }
        }

        throw "$Description not found: $resolvedPath"
    }

    return $resolvedPath
}

function Get-RunnerLogPath {
    param([string]$ProjectDir)

    $commonAppData = [Environment]::GetFolderPath("CommonApplicationData")
    if ($Mode -eq "Service" -and -not [string]::IsNullOrWhiteSpace($commonAppData)) {
        $logDir = Join-Path $commonAppData "GoodbyeZapret\logs"
    }
    else {
        $appData = [Environment]::GetFolderPath("ApplicationData")
        if (-not [string]::IsNullOrWhiteSpace($appData)) {
            $logDir = Join-Path $appData "GoodbyeZapret\logs"
        }
        else {
            $logDir = Join-Path $ProjectDir "tools"
        }
    }

    if (-not (Test-Path -LiteralPath $logDir)) {
        New-Item -ItemType Directory -Path $logDir -Force | Out-Null
    }

    return (Join-Path $logDir "preset-runner.log")
}

function Write-RunnerLog {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectDir,

        [Parameter(Mandatory = $true)]
        [string]$Message,

        [string]$Level = "INFO"
    )

    $stamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Add-Content -LiteralPath (Get-RunnerLogPath $ProjectDir) -Encoding UTF8 -Value "[$stamp][$Level] $Message"
}

function Format-ResolvedPath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$AbsolutePath,

        [switch]$UseAtPrefix
    )

    $prefix = if ($UseAtPrefix) { "@" } else { "" }
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
    $placeholderBases = @{
        PROJECT = $ProjectDir
        BIN = $binDir
        LISTS = $listsDir
        FAKE = $fakeDir
    }

    $resolvedValue = [System.Text.RegularExpressions.Regex]::Replace(
        $resolvedValue,
        '\{\{(?<token>PROJECT|BIN|LISTS|FAKE)\}\}(?<path>[^"\s]*)',
        {
            param($match)

            $token = $match.Groups["token"].Value.ToUpperInvariant()
            $relativePath = $match.Groups["path"].Value
            $baseDir = $placeholderBases[$token]

            if ([string]::IsNullOrWhiteSpace($relativePath)) {
                return ($baseDir.TrimEnd("\") + "\")
            }

            return Resolve-PresetDependencyPath -RelativePath $relativePath -BaseDir $baseDir
        }
    )

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

                $absolutePath = Resolve-PresetDependencyPath -RelativePath $match.Groups["path"].Value -BaseDir $mapping.BaseDir
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

function Resolve-Preset {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Preset,

        [Parameter(Mandatory = $true)]
        [string]$ProjectDir
    )

    $presetPath = Resolve-ExistingPath -Path $Preset -BaseDir $ProjectDir -Description "Preset" -AllowCurrentDirectoryFallback
    $binDir = Join-Path $ProjectDir "bin"
    $exeName = "winws2.exe"
    $arguments = New-Object System.Collections.Generic.List[string]

    foreach ($line in Get-Content -LiteralPath $presetPath -Encoding UTF8) {
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

        $resolvedArgument = Resolve-PresetArgument -Value $trimmed -ProjectDir $ProjectDir
        if (Test-EmptyPortArgument -Value $resolvedArgument) {
            continue
        }

        $arguments.Add($resolvedArgument)
    }

    if ($arguments.Count -eq 0) {
        throw "Preset is empty: $presetPath"
    }

    if ($exeName -notmatch '^[A-Za-z0-9_.-]+\.exe$') {
        throw "Unsupported engine name in preset: $exeName"
    }

    $enginePath = Resolve-ExistingPath -Path $exeName -BaseDir $binDir -Description "Engine"

    return [pscustomobject]@{
        PresetPath = $presetPath
        EngineName = $exeName
        EnginePath = $enginePath
        BinDir = $binDir
        Arguments = $arguments
    }
}

function Stop-ExistingEngineProcesses {
    param([string]$ProjectDir)

    if ($PreserveExistingProcess) {
        return
    }

    foreach ($processName in @("winws", "winws2")) {
        Get-Process -Name $processName -ErrorAction SilentlyContinue | ForEach-Object {
            Write-RunnerLog -ProjectDir $ProjectDir -Message "Stopping existing process $($_.ProcessName) PID $($_.Id)"
            Stop-Process -Id $_.Id -Force -ErrorAction SilentlyContinue
        }
    }
}

function Invoke-DnsFlush {
    param([string]$ProjectDir)

    try {
        ipconfig /flushdns | Out-Null
        Write-RunnerLog -ProjectDir $ProjectDir -Message "DNS cache flushed"
    }
    catch {
        Write-RunnerLog -ProjectDir $ProjectDir -Level "WARN" -Message ("Failed to flush DNS cache: " + $_.Exception.Message)
    }
}

function Start-PresetProcess {
    param(
        [Parameter(Mandatory = $true)]
        [pscustomobject]$ResolvedPreset,

        [Parameter(Mandatory = $true)]
        [string]$ProjectDir
    )

    Stop-ExistingEngineProcesses -ProjectDir $ProjectDir
    Invoke-DnsFlush -ProjectDir $ProjectDir

    Write-RunnerLog -ProjectDir $ProjectDir -Message ("Starting preset: " + $ResolvedPreset.PresetPath)
    Write-RunnerLog -ProjectDir $ProjectDir -Message ("Engine: " + $ResolvedPreset.EnginePath)
    Write-RunnerLog -ProjectDir $ProjectDir -Message ("Mode: " + $Mode)

    $startParams = @{
        FilePath = $ResolvedPreset.EnginePath
        ArgumentList = $ResolvedPreset.Arguments
        WorkingDirectory = $ResolvedPreset.BinDir
        PassThru = $true
    }

    if ($Mode -eq "Interactive" -and [Environment]::UserInteractive) {
        $startParams.WindowStyle = "Minimized"
    }

    $process = Start-Process @startParams
    Start-Sleep -Milliseconds 700

    if ($process.HasExited) {
        $message = "Engine exited during startup with code $($process.ExitCode)."
        Write-RunnerLog -ProjectDir $ProjectDir -Level "ERROR" -Message $message
        throw $message
    }

    Write-RunnerLog -ProjectDir $ProjectDir -Message ("Engine started with PID " + $process.Id)

    if (-not $NoTray) {
        $trayPath = Join-Path $ProjectDir "tools\tray\GoodbyeZapretTray.exe"
        if (Test-Path -LiteralPath $trayPath) {
            $trayRunning = Get-Process -Name "GoodbyeZapretTray" -ErrorAction SilentlyContinue
            if (-not $trayRunning) {
                Start-Process -FilePath $trayPath | Out-Null
                Write-RunnerLog -ProjectDir $ProjectDir -Message "Tray started"
            }
        }
    }

    Write-RunnerMessage -Level "OK" -Message ("Started " + $ResolvedPreset.EngineName + " with PID " + $process.Id)
}

function Start-PresetServiceHost {
    param(
        [Parameter(Mandatory = $true)]
        [pscustomobject]$ResolvedPreset,

        [Parameter(Mandatory = $true)]
        [string]$ProjectDir
    )

    Add-Type -ReferencedAssemblies "System.ServiceProcess" -TypeDefinition @"
using System;
using System.Diagnostics;
using System.IO;
using System.ServiceProcess;
using System.Threading;

public sealed class GoodbyeZapretPresetService : ServiceBase
{
    public static string EnginePath;
    public static string EngineArguments;
    public static string WorkingDirectory;
    public static string LogPath;

    private static Process engineProcess;
    private static bool stopping;

    public GoodbyeZapretPresetService()
    {
        ServiceName = "GoodbyeZapret";
        CanStop = true;
        CanShutdown = true;
        AutoLog = false;
    }

    protected override void OnStart(string[] args)
    {
        RequestAdditionalTime(15000);
        Log("Service start requested");
        stopping = false;

        StopExistingEngineProcesses();
        FlushDns();
        StartEngineProcess();
    }

    protected override void OnStop()
    {
        RequestAdditionalTime(10000);
        stopping = true;
        Log("Service stop requested");
        StopEngineProcess();
    }

    protected override void OnShutdown()
    {
        stopping = true;
        Log("System shutdown requested");
        StopEngineProcess();
        base.OnShutdown();
    }

    private static void StartEngineProcess()
    {
        var startInfo = new ProcessStartInfo();
        startInfo.FileName = EnginePath;
        startInfo.Arguments = EngineArguments;
        startInfo.WorkingDirectory = WorkingDirectory;
        startInfo.UseShellExecute = false;
        startInfo.CreateNoWindow = true;

        engineProcess = Process.Start(startInfo);
        if (engineProcess == null)
        {
            throw new InvalidOperationException("Failed to start engine process.");
        }

        Thread.Sleep(700);
        if (engineProcess.HasExited)
        {
            var code = engineProcess.ExitCode;
            Log("Engine exited during startup with code " + code);
            throw new InvalidOperationException("Engine exited during startup with code " + code + ".");
        }

        Log("Engine started with PID " + engineProcess.Id);

        var monitorThread = new Thread(MonitorEngineProcess);
        monitorThread.IsBackground = true;
        monitorThread.Start();
    }

    private static void MonitorEngineProcess()
    {
        try
        {
            engineProcess.WaitForExit();
            var code = engineProcess.ExitCode;
            Log("Engine exited with code " + code);
            if (!stopping)
            {
                Environment.Exit(code);
            }
        }
        catch (Exception ex)
        {
            Log("Engine monitor failed: " + ex.Message);
            if (!stopping)
            {
                Environment.Exit(1);
            }
        }
    }

    private static void StopEngineProcess()
    {
        try
        {
            if (engineProcess != null && !engineProcess.HasExited)
            {
                Log("Stopping engine PID " + engineProcess.Id);
                engineProcess.Kill();
                engineProcess.WaitForExit(5000);
            }
        }
        catch (Exception ex)
        {
            Log("Failed to stop engine: " + ex.Message);
        }
    }

    private static void StopExistingEngineProcesses()
    {
        foreach (var processName in new[] { "winws", "winws2" })
        {
            foreach (var process in Process.GetProcessesByName(processName))
            {
                try
                {
                    Log("Stopping existing process " + process.ProcessName + " PID " + process.Id);
                    process.Kill();
                    process.WaitForExit(3000);
                }
                catch (Exception ex)
                {
                    Log("Failed to stop existing process " + process.ProcessName + " PID " + process.Id + ": " + ex.Message);
                }
                finally
                {
                    process.Dispose();
                }
            }
        }
    }

    private static void FlushDns()
    {
        try
        {
            var startInfo = new ProcessStartInfo();
            startInfo.FileName = "ipconfig.exe";
            startInfo.Arguments = "/flushdns";
            startInfo.UseShellExecute = false;
            startInfo.CreateNoWindow = true;
            using (var process = Process.Start(startInfo))
            {
                if (process != null)
                {
                    process.WaitForExit(5000);
                }
            }
            Log("DNS cache flushed");
        }
        catch (Exception ex)
        {
            Log("Failed to flush DNS cache: " + ex.Message);
        }
    }

    private static void Log(string message)
    {
        try
        {
            var directory = Path.GetDirectoryName(LogPath);
            if (!String.IsNullOrEmpty(directory))
            {
                Directory.CreateDirectory(directory);
            }
            File.AppendAllText(LogPath, "[" + DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss") + "][INFO] " + message + Environment.NewLine);
        }
        catch
        {
        }
    }
}
"@

    [GoodbyeZapretPresetService]::EnginePath = $ResolvedPreset.EnginePath
    [GoodbyeZapretPresetService]::EngineArguments = [string]::Join(" ", ([string[]]$ResolvedPreset.Arguments))
    [GoodbyeZapretPresetService]::WorkingDirectory = $ResolvedPreset.BinDir
    [GoodbyeZapretPresetService]::LogPath = Get-RunnerLogPath -ProjectDir $ProjectDir

    Write-RunnerLog -ProjectDir $ProjectDir -Message ("Service host initialized for preset: " + $ResolvedPreset.PresetPath)
    Write-RunnerLog -ProjectDir $ProjectDir -Message ("Engine: " + $ResolvedPreset.EnginePath)

    [System.ServiceProcess.ServiceBase]::Run((New-Object GoodbyeZapretPresetService))
}

function Invoke-ValidateAll {
    param([string]$ProjectDir)

    $configRoots = @(
        Join-Path $ProjectDir "configs\preset"
        Join-Path $ProjectDir "configs\Preset"
        Join-Path $ProjectDir "configs\custom"
        Join-Path $ProjectDir "configs\Custom"
    ) | Select-Object -Unique

    $presetFiles = New-Object System.Collections.Generic.List[System.IO.FileInfo]
    foreach ($root in $configRoots) {
        if (Test-Path -LiteralPath $root -PathType Container) {
            Get-ChildItem -LiteralPath $root -Filter "*.txt" -File -Recurse -ErrorAction SilentlyContinue |
                ForEach-Object { $presetFiles.Add($_) }
        }
    }

    $seen = @{}
    $uniquePresetFiles = foreach ($file in $presetFiles) {
        $key = $file.FullName.ToLowerInvariant()
        if (-not $seen.ContainsKey($key)) {
            $seen[$key] = $true
            $file
        }
    }

    if (-not $uniquePresetFiles) {
        Write-RunnerMessage -Level "WARN" -Message "No text presets found."
        return 1
    }

    $failed = 0
    foreach ($file in $uniquePresetFiles | Sort-Object FullName) {
        try {
            $null = Resolve-Preset -Preset $file.FullName -ProjectDir $ProjectDir
            Write-Host ("OK     " + $file.FullName.Substring($ProjectDir.Length).TrimStart("\"))
        }
        catch {
            $failed++
            Write-Host ("FAIL   " + $file.FullName.Substring($ProjectDir.Length).TrimStart("\") + ": " + $_.Exception.Message)
        }
    }

    if ($failed -gt 0) {
        return 1
    }

    return 0
}

try {
    if (-not $ProjectDir) {
        $ProjectDir = Get-DefaultProjectDir
    }
    else {
        $ProjectDir = [System.IO.Path]::GetFullPath($ProjectDir)
    }

    if (-not (Test-Path -LiteralPath $ProjectDir -PathType Container)) {
        throw "Project directory not found: $ProjectDir"
    }

    if ($ValidateAll) {
        exit (Invoke-ValidateAll -ProjectDir $ProjectDir)
    }

    if ([string]::IsNullOrWhiteSpace($Preset)) {
        throw "Preset file is not specified."
    }

    $resolvedPreset = Resolve-Preset -Preset $Preset -ProjectDir $ProjectDir

    if ($ValidateOnly) {
        Write-RunnerMessage -Level "OK" -Message ("Preset is valid: " + $resolvedPreset.PresetPath)
        Write-RunnerLog -ProjectDir $ProjectDir -Message ("Validated preset: " + $resolvedPreset.PresetPath)
        exit 0
    }

    if ($Mode -eq "Service") {
        Start-PresetServiceHost -ResolvedPreset $resolvedPreset -ProjectDir $ProjectDir
    }
    else {
        Start-PresetProcess -ResolvedPreset $resolvedPreset -ProjectDir $ProjectDir
    }
    exit 0
}
catch {
    $message = $_.Exception.Message
    if ($ProjectDir -and (Test-Path -LiteralPath $ProjectDir -PathType Container)) {
        Write-RunnerLog -ProjectDir $ProjectDir -Level "ERROR" -Message $message
    }
    Write-RunnerMessage -Level "ERROR" -Message $message
    if ($Mode -eq "Interactive" -and -not $Quiet -and $ErrorDisplaySeconds -gt 0) {
        Start-Sleep -Seconds $ErrorDisplaySeconds
    }
    exit 1
}
