using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.ServiceProcess;
using System.Text;
using System.Text.RegularExpressions;
using System.Threading;

internal sealed class GoodbyeZapretService : ServiceBase
{
    private static readonly object ProcessSync = new object();
    private static readonly object LogSync = new object();
    private static ServiceOptions options;
    private static Process engineProcess;
    private static volatile bool stopping;

    public GoodbyeZapretService()
    {
        ServiceName = "GoodbyeZapret";
        CanStop = true;
        CanShutdown = true;
        AutoLog = false;
    }

    public static int Main(string[] args)
    {
        try
        {
            options = ServiceOptions.Parse(args);
            if (options.ConsoleMode)
            {
                stopping = false;
                Log("Console mode start requested");
                Process initialProcess = StartEngineProcess();
                return MonitorEngine(initialProcess);
            }

            ServiceBase.Run(new GoodbyeZapretService());
            return 0;
        }
        catch (Exception ex)
        {
            Log("Fatal startup error: " + ex, "ERROR");
            return 1;
        }
    }

    protected override void OnStart(string[] args)
    {
        RequestAdditionalTime(30000);
        stopping = false;
        Log("Service start requested");
        Process initialProcess = StartEngineProcess();
        Thread monitorThread = new Thread(delegate()
        {
            int exitCode = MonitorEngine(initialProcess);
            if (!stopping)
                Environment.Exit(exitCode == 0 ? 1 : exitCode);
        });
        monitorThread.IsBackground = true;
        monitorThread.Name = "GoodbyeZapret engine monitor";
        monitorThread.Start();
    }

    protected override void OnStop()
    {
        RequestAdditionalTime(15000);
        stopping = true;
        Log("Service stop requested");
        StopOwnedEngine();
    }

    protected override void OnShutdown()
    {
        stopping = true;
        Log("System shutdown requested");
        StopOwnedEngine();
        base.OnShutdown();
    }

    private static Process StartEngineProcess()
    {
        FlushDns();
        ResolvedPreset resolvedPreset = PresetResolver.Resolve(options.PresetPath, options.ProjectDir);
        Log("Starting preset: " + resolvedPreset.PresetPath);
        Log("Engine: " + resolvedPreset.EnginePath);

        ProcessStartInfo startInfo = new ProcessStartInfo();
        startInfo.FileName = resolvedPreset.EnginePath;
        startInfo.Arguments = BuildCommandLine(resolvedPreset.Arguments);
        startInfo.WorkingDirectory = resolvedPreset.BinDir;
        startInfo.UseShellExecute = false;
        startInfo.CreateNoWindow = true;
        startInfo.RedirectStandardOutput = true;
        startInfo.RedirectStandardError = true;

        Process process = new Process();
        process.StartInfo = startInfo;
        process.OutputDataReceived += delegate(object sender, DataReceivedEventArgs eventArgs)
        {
            if (eventArgs.Data != null)
                Log("[ENGINE-OUT] " + eventArgs.Data);
        };
        process.ErrorDataReceived += delegate(object sender, DataReceivedEventArgs eventArgs)
        {
            if (eventArgs.Data != null)
                Log("[ENGINE-ERR] " + eventArgs.Data, "ERROR");
        };

        if (!process.Start())
        {
            process.Dispose();
            throw new InvalidOperationException("Failed to start engine process.");
        }
        process.BeginOutputReadLine();
        process.BeginErrorReadLine();

        lock (ProcessSync)
        {
            engineProcess = process;
        }
        Log("Engine started with PID " + process.Id);
        return process;
    }

    private static int MonitorEngine(Process process)
    {
        int restartCount = 0;
        while (true)
        {
            DateTime startedAt = DateTime.UtcNow;
            int exitCode;
            try
            {
                process.WaitForExit();
                exitCode = process.ExitCode;
            }
            catch (Exception ex)
            {
                Log("Engine monitor failed: " + ex, "ERROR");
                exitCode = 1;
            }
            finally
            {
                lock (ProcessSync)
                {
                    if (ReferenceEquals(engineProcess, process))
                        engineProcess = null;
                }
                process.Dispose();
            }

            Log("Engine exited with code " + exitCode, stopping ? "INFO" : "ERROR");
            if (stopping)
                return 0;

            double runtimeSeconds = (DateTime.UtcNow - startedAt).TotalSeconds;
            if (runtimeSeconds >= options.RestartResetSeconds)
                restartCount = 0;

            if (restartCount >= options.MaxRestarts)
            {
                int hostExitCode = exitCode == 0 ? 1 : exitCode;
                Log("Engine restart limit reached; stopping host with code " + hostExitCode, "ERROR");
                return hostExitCode;
            }

            process = null;
            while (!stopping && process == null)
            {
                restartCount++;
                Log("Restarting engine after unexpected exit (attempt " + restartCount + " of " + options.MaxRestarts + ")", "WARN");
                if (!WaitForRestartDelay(options.RestartDelayMs))
                    return 0;
                try
                {
                    process = StartEngineProcess();
                }
                catch (Exception ex)
                {
                    Log("Engine restart failed: " + ex, "ERROR");
                }
                if (restartCount >= options.MaxRestarts)
                {
                    if (process == null)
                        return 1;
                    break;
                }
            }
        }
    }

    private static bool WaitForRestartDelay(int milliseconds)
    {
        int waited = 0;
        while (!stopping && waited < milliseconds)
        {
            int slice = Math.Min(200, milliseconds - waited);
            Thread.Sleep(slice);
            waited += slice;
        }
        return !stopping;
    }

    private static void StopOwnedEngine()
    {
        Process process;
        lock (ProcessSync)
        {
            process = engineProcess;
        }

        if (process == null)
            return;

        try
        {
            if (!process.HasExited)
            {
                Log("Stopping engine PID " + process.Id);
                process.Kill();
                process.WaitForExit(5000);
            }
        }
        catch (Exception ex)
        {
            Log("Failed to stop engine: " + ex.Message, "WARN");
        }
    }

    private static void FlushDns()
    {
        try
        {
            ProcessStartInfo startInfo = new ProcessStartInfo();
            startInfo.FileName = "ipconfig.exe";
            startInfo.Arguments = "/flushdns";
            startInfo.UseShellExecute = false;
            startInfo.CreateNoWindow = true;
            using (Process process = Process.Start(startInfo))
            {
                if (process != null)
                    process.WaitForExit(5000);
            }
            Log("DNS cache flushed");
        }
        catch (Exception ex)
        {
            Log("Failed to flush DNS cache: " + ex.Message, "WARN");
        }
    }

    private static string BuildCommandLine(IEnumerable<string> arguments)
    {
        List<string> quoted = new List<string>();
        foreach (string argument in arguments)
            quoted.Add(QuoteArgument(argument));
        return String.Join(" ", quoted.ToArray());
    }

    private static string QuoteArgument(string argument)
    {
        if (argument.IndexOf('"') >= 0)
            return argument;
        if (argument.IndexOfAny(new char[] { ' ', '\t' }) < 0)
            return argument;
        return "\"" + argument.Replace("\"", "\\\"") + "\"";
    }

    internal static void Log(string message)
    {
        Log(message, "INFO");
    }

    internal static void Log(string message, string level)
    {
        try
        {
            lock (LogSync)
            {
                string logPath = options == null ? ServiceOptions.GetDefaultLogPath() : options.GetLogPath();
                string directory = Path.GetDirectoryName(logPath);
                if (!String.IsNullOrEmpty(directory))
                    Directory.CreateDirectory(directory);
                File.AppendAllText(logPath,
                    "[" + DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss") + "][" + level + "] " + message + Environment.NewLine,
                    new UTF8Encoding(false));
            }
        }
        catch
        {
        }
    }
}

internal sealed class ServiceOptions
{
    public string PresetPath;
    public string ProjectDir;
    public string LogPath;
    public bool ConsoleMode;
    public int MaxRestarts = 3;
    public int RestartDelayMs = 2000;
    public int RestartResetSeconds = 60;

    public static ServiceOptions Parse(string[] args)
    {
        ServiceOptions result = new ServiceOptions();
        for (int index = 0; index < args.Length; index++)
        {
            string argument = args[index];
            if (String.Equals(argument, "--preset", StringComparison.OrdinalIgnoreCase) && index + 1 < args.Length)
                result.PresetPath = args[++index];
            else if (String.Equals(argument, "--project-dir", StringComparison.OrdinalIgnoreCase) && index + 1 < args.Length)
                result.ProjectDir = args[++index];
            else if (String.Equals(argument, "--log-path", StringComparison.OrdinalIgnoreCase) && index + 1 < args.Length)
                result.LogPath = Path.GetFullPath(args[++index]);
            else if (String.Equals(argument, "--max-restarts", StringComparison.OrdinalIgnoreCase) && index + 1 < args.Length)
                result.MaxRestarts = ParseInteger(args[++index], "--max-restarts", 0, 100);
            else if (String.Equals(argument, "--restart-delay-ms", StringComparison.OrdinalIgnoreCase) && index + 1 < args.Length)
                result.RestartDelayMs = ParseInteger(args[++index], "--restart-delay-ms", 0, 300000);
            else if (String.Equals(argument, "--restart-reset-seconds", StringComparison.OrdinalIgnoreCase) && index + 1 < args.Length)
                result.RestartResetSeconds = ParseInteger(args[++index], "--restart-reset-seconds", 1, 86400);
            else if (String.Equals(argument, "--console", StringComparison.OrdinalIgnoreCase))
                result.ConsoleMode = true;
        }

        if (String.IsNullOrWhiteSpace(result.ProjectDir))
            result.ProjectDir = Path.GetFullPath(Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "..", ".."));
        else
            result.ProjectDir = Path.GetFullPath(result.ProjectDir);

        if (String.IsNullOrWhiteSpace(result.PresetPath))
            throw new ArgumentException("Preset file is not specified.");
        return result;
    }

    private static int ParseInteger(string value, string optionName, int minimum, int maximum)
    {
        int parsed;
        if (!Int32.TryParse(value, out parsed) || parsed < minimum || parsed > maximum)
            throw new ArgumentException(optionName + " must be between " + minimum + " and " + maximum + ".");
        return parsed;
    }

    public string GetLogPath()
    {
        return String.IsNullOrWhiteSpace(LogPath) ? GetDefaultLogPath() : LogPath;
    }

    public static string GetDefaultLogPath()
    {
        string overriddenPath = Environment.GetEnvironmentVariable("GOODBYEZAPRET_LOG_PATH");
        if (!String.IsNullOrWhiteSpace(overriddenPath))
            return Path.GetFullPath(overriddenPath);
        string commonData = Environment.GetFolderPath(Environment.SpecialFolder.CommonApplicationData);
        if (String.IsNullOrWhiteSpace(commonData))
            commonData = AppDomain.CurrentDomain.BaseDirectory;
        return Path.Combine(commonData, "GoodbyeZapret", "logs", "preset-runner.log");
    }
}

internal sealed class ResolvedPreset
{
    public string PresetPath;
    public string EnginePath;
    public string BinDir;
    public List<string> Arguments;
}

internal static class PresetResolver
{
    public static ResolvedPreset Resolve(string preset, string projectDir)
    {
        string presetPath = ResolveExistingPath(preset, projectDir, "Preset");
        string binDir = Path.Combine(projectDir, "bin");
        string engineName = "winws2.exe";
        List<string> arguments = new List<string>();

        foreach (string line in File.ReadAllLines(presetPath, Encoding.UTF8))
        {
            string trimmed = line.Trim();
            if (trimmed.Length == 0)
                continue;
            if (trimmed.StartsWith("#", StringComparison.Ordinal))
            {
                Match engineMatch = Regex.Match(trimmed, "^#\\s*Engine\\s*:\\s*(.+?)\\s*$", RegexOptions.IgnoreCase);
                if (engineMatch.Success)
                    engineName = engineMatch.Groups[1].Value.Trim();
            }
            else
            {
                string resolved = ResolvePresetArgument(trimmed, projectDir);
                if (!IsEmptyPortArgument(resolved))
                    arguments.Add(resolved);
            }
        }

        if (arguments.Count == 0)
            throw new InvalidOperationException("Preset is empty: " + presetPath);
        if (!Regex.IsMatch(engineName, "^[A-Za-z0-9_.-]+\\.exe$"))
            throw new InvalidOperationException("Unsupported engine name in preset: " + engineName);

        ResolvedPreset result = new ResolvedPreset();
        result.PresetPath = presetPath;
        result.EnginePath = ResolveExistingPath(engineName, binDir, "Engine");
        result.BinDir = binDir;
        result.Arguments = arguments;
        return result;
    }

    private static string ResolvePresetArgument(string value, string projectDir)
    {
        string binDir = Path.Combine(projectDir, "bin");
        string listsDir = Path.Combine(projectDir, "lists");
        string fakeDir = Path.Combine(binDir, "fake");
        string luaDir = Path.Combine(binDir, "lua");
        string windivertFilterDir = Path.Combine(binDir, "windivert.filter");

        string resolved = Regex.Replace(value,
            "\\{\\{(?<token>PROJECT|BIN|LISTS|FAKE)\\}\\}(?<path>[^\"\\s]*)",
            delegate(Match match)
            {
                string token = match.Groups["token"].Value.ToUpperInvariant();
                string relativePath = match.Groups["path"].Value;
                string baseDir = projectDir;
                if (token == "BIN") baseDir = binDir;
                else if (token == "LISTS") baseDir = listsDir;
                else if (token == "FAKE") baseDir = fakeDir;
                return String.IsNullOrWhiteSpace(relativePath)
                    ? baseDir.TrimEnd('\\') + "\\"
                    : ResolvePresetDependencyPath(relativePath, baseDir);
            });

        resolved = ReplaceMappedPath(resolved, "@lua/(?<path>[^\"\\s]+)", luaDir, true);
        resolved = ReplaceMappedPath(resolved, "@windivert\\.filter/(?<path>[^\"\\s]+)", windivertFilterDir, true);
        resolved = ReplaceMappedPath(resolved, "@bin/(?<path>[^\"\\s]+)", fakeDir, true);
        return ReplaceMappedPath(resolved, "(?<![@A-Za-z0-9_.-])lists/(?<path>[^\"\\s]+)", listsDir, false);
    }

    private static string ReplaceMappedPath(string value, string pattern, string baseDir, bool useAtPrefix)
    {
        return Regex.Replace(value, pattern, delegate(Match match)
        {
            string path = ResolvePresetDependencyPath(match.Groups["path"].Value, baseDir);
            return (useAtPrefix ? "@" : "") + "\"" + path + "\"";
        }, RegexOptions.IgnoreCase);
    }

    private static string ResolvePresetDependencyPath(string relativePath, string baseDir)
    {
        string fullPath = Path.GetFullPath(Path.Combine(baseDir, ConvertToWindowsPath(relativePath)));
        if (!File.Exists(fullPath) && !Directory.Exists(fullPath))
            throw new FileNotFoundException("Preset dependency not found: " + fullPath);
        return fullPath;
    }

    private static string ResolveExistingPath(string path, string baseDir, string description)
    {
        string windowsPath = ConvertToWindowsPath(path);
        string resolved = Path.IsPathRooted(windowsPath)
            ? Path.GetFullPath(windowsPath)
            : Path.GetFullPath(Path.Combine(baseDir, windowsPath));
        if (!File.Exists(resolved) && !Directory.Exists(resolved))
            throw new FileNotFoundException(description + " not found: " + resolved);
        return resolved;
    }

    private static bool IsEmptyPortArgument(string value)
    {
        return Regex.IsMatch(value.Trim(),
            "^--(?:wf-(?:tcp|udp)(?:-(?:in|out))?|filter-(?:tcp|udp))=(?:\"\"|''|\\s*)$",
            RegexOptions.IgnoreCase);
    }

    private static string ConvertToWindowsPath(string value)
    {
        return value.Replace('/', '\\');
    }
}
