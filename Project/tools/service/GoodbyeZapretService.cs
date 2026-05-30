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
    private static ServiceOptions options;
    private static Process engineProcess;
    private static bool stopping;

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
                RunConsole();
                return 0;
            }

            ServiceBase.Run(new GoodbyeZapretService());
            return 0;
        }
        catch (Exception ex)
        {
            Log("Fatal startup error: " + ex.Message, "ERROR");
            return 1;
        }
    }

    protected override void OnStart(string[] args)
    {
        RequestAdditionalTime(30000);
        stopping = false;
        Log("Service start requested");
        StartEngine();
    }

    protected override void OnStop()
    {
        RequestAdditionalTime(15000);
        stopping = true;
        Log("Service stop requested");
        StopEngine();
    }

    protected override void OnShutdown()
    {
        stopping = true;
        Log("System shutdown requested");
        StopEngine();
        base.OnShutdown();
    }

    private static void RunConsole()
    {
        Log("Console mode start requested");
        StartEngine();
        if (engineProcess != null)
        {
            engineProcess.WaitForExit();
        }
    }

    private static void StartEngine()
    {
        StopExistingEngineProcesses();
        FlushDns();

        ResolvedPreset preset = PresetResolver.Resolve(options.PresetPath, options.ProjectDir);
        Log("Starting preset: " + preset.PresetPath);
        Log("Engine: " + preset.EnginePath);

        ProcessStartInfo startInfo = new ProcessStartInfo();
        startInfo.FileName = preset.EnginePath;
        startInfo.Arguments = BuildCommandLine(preset.Arguments);
        startInfo.WorkingDirectory = preset.BinDir;
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
            int code = engineProcess.ExitCode;
            Log("Engine exited during startup with code " + code, "ERROR");
            throw new InvalidOperationException("Engine exited during startup with code " + code + ".");
        }

        Log("Engine started with PID " + engineProcess.Id);

        Thread monitorThread = new Thread(MonitorEngine);
        monitorThread.IsBackground = true;
        monitorThread.Start();
    }

    private static void MonitorEngine()
    {
        try
        {
            engineProcess.WaitForExit();
            int code = engineProcess.ExitCode;
            Log("Engine exited with code " + code, stopping ? "INFO" : "ERROR");
            if (!stopping)
            {
                Environment.Exit(code == 0 ? 1 : code);
            }
        }
        catch (Exception ex)
        {
            Log("Engine monitor failed: " + ex.Message, "ERROR");
            if (!stopping)
            {
                Environment.Exit(1);
            }
        }
    }

    private static void StopEngine()
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
            Log("Failed to stop engine: " + ex.Message, "WARN");
        }

        StopExistingEngineProcesses();
    }

    private static void StopExistingEngineProcesses()
    {
        string[] names = new[] { "winws", "winws2" };
        foreach (string processName in names)
        {
            Process[] processes = Process.GetProcessesByName(processName);
            foreach (Process process in processes)
            {
                try
                {
                    Log("Stopping existing process " + process.ProcessName + " PID " + process.Id);
                    process.Kill();
                    process.WaitForExit(3000);
                }
                catch (Exception ex)
                {
                    Log("Failed to stop existing process " + process.ProcessName + " PID " + process.Id + ": " + ex.Message, "WARN");
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
            ProcessStartInfo startInfo = new ProcessStartInfo();
            startInfo.FileName = "ipconfig.exe";
            startInfo.Arguments = "/flushdns";
            startInfo.UseShellExecute = false;
            startInfo.CreateNoWindow = true;

            using (Process process = Process.Start(startInfo))
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
            Log("Failed to flush DNS cache: " + ex.Message, "WARN");
        }
    }

    private static string BuildCommandLine(IEnumerable<string> arguments)
    {
        List<string> encoded = new List<string>();
        foreach (string argument in arguments)
        {
            encoded.Add(QuoteArgument(argument));
        }
        return String.Join(" ", encoded.ToArray());
    }

    private static string QuoteArgument(string argument)
    {
        if (argument.IndexOf('"') >= 0)
        {
            return argument;
        }

        if (argument.IndexOfAny(new[] { ' ', '\t' }) < 0)
        {
            return argument;
        }

        return "\"" + argument.Replace("\\", "\\\\").Replace("\"", "\\\"") + "\"";
    }

    internal static void Log(string message)
    {
        Log(message, "INFO");
    }

    internal static void Log(string message, string level)
    {
        try
        {
            string logPath = ServiceOptions.GetLogPath();
            string directory = Path.GetDirectoryName(logPath);
            if (!String.IsNullOrEmpty(directory))
            {
                Directory.CreateDirectory(directory);
            }

            File.AppendAllText(
                logPath,
                "[" + DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss") + "][" + level + "] " + message + Environment.NewLine,
                Encoding.UTF8);
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
    public bool ConsoleMode;

    public static ServiceOptions Parse(string[] args)
    {
        ServiceOptions result = new ServiceOptions();

        for (int i = 0; i < args.Length; i++)
        {
            string arg = args[i];
            if (String.Equals(arg, "--preset", StringComparison.OrdinalIgnoreCase) && i + 1 < args.Length)
            {
                result.PresetPath = args[++i];
            }
            else if (String.Equals(arg, "--project-dir", StringComparison.OrdinalIgnoreCase) && i + 1 < args.Length)
            {
                result.ProjectDir = args[++i];
            }
            else if (String.Equals(arg, "--console", StringComparison.OrdinalIgnoreCase))
            {
                result.ConsoleMode = true;
            }
        }

        if (String.IsNullOrWhiteSpace(result.ProjectDir))
        {
            result.ProjectDir = Path.GetFullPath(Path.Combine(AppDomain.CurrentDomain.BaseDirectory, ".."));
        }
        else
        {
            result.ProjectDir = Path.GetFullPath(result.ProjectDir);
        }

        if (String.IsNullOrWhiteSpace(result.PresetPath))
        {
            throw new ArgumentException("Preset file is not specified.");
        }

        return result;
    }

    public static string GetLogPath()
    {
        string commonAppData = Environment.GetFolderPath(Environment.SpecialFolder.CommonApplicationData);
        if (String.IsNullOrWhiteSpace(commonAppData))
        {
            commonAppData = AppDomain.CurrentDomain.BaseDirectory;
        }

        return Path.Combine(commonAppData, "GoodbyeZapret", "logs", "preset-runner.log");
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
        string exeName = "winws2.exe";
        List<string> arguments = new List<string>();

        foreach (string line in File.ReadAllLines(presetPath, Encoding.UTF8))
        {
            string trimmed = line.Trim();
            if (trimmed.Length == 0)
            {
                continue;
            }

            if (trimmed.StartsWith("#", StringComparison.Ordinal))
            {
                Match engineMatch = Regex.Match(trimmed, @"^#\s*Engine\s*:\s*(.+?)\s*$", RegexOptions.IgnoreCase);
                if (engineMatch.Success)
                {
                    exeName = engineMatch.Groups[1].Value.Trim();
                }
                continue;
            }

            string resolvedArgument = ResolvePresetArgument(trimmed, projectDir);
            if (IsEmptyPortArgument(resolvedArgument))
            {
                continue;
            }

            arguments.Add(resolvedArgument);
        }

        if (arguments.Count == 0)
        {
            throw new InvalidOperationException("Preset is empty: " + presetPath);
        }

        if (!Regex.IsMatch(exeName, @"^[A-Za-z0-9_.-]+\.exe$"))
        {
            throw new InvalidOperationException("Unsupported engine name in preset: " + exeName);
        }

        return new ResolvedPreset
        {
            PresetPath = presetPath,
            EnginePath = ResolveExistingPath(exeName, binDir, "Engine"),
            BinDir = binDir,
            Arguments = arguments
        };
    }

    private static string ResolvePresetArgument(string value, string projectDir)
    {
        string binDir = Path.Combine(projectDir, "bin");
        string listsDir = Path.Combine(projectDir, "lists");
        string fakeDir = Path.Combine(binDir, "fake");
        string luaDir = Path.Combine(binDir, "lua");
        string windivertFilterDir = Path.Combine(binDir, "windivert.filter");

        string resolved = Regex.Replace(
            value,
            @"\{\{(?<token>PROJECT|BIN|LISTS|FAKE)\}\}(?<path>[^""\s]*)",
            delegate(Match match)
            {
                string token = match.Groups["token"].Value.ToUpperInvariant();
                string relativePath = match.Groups["path"].Value;
                string baseDir = projectDir;
                if (token == "BIN")
                {
                    baseDir = binDir;
                }
                else if (token == "LISTS")
                {
                    baseDir = listsDir;
                }
                else if (token == "FAKE")
                {
                    baseDir = fakeDir;
                }

                if (String.IsNullOrWhiteSpace(relativePath))
                {
                    return baseDir.TrimEnd('\\') + "\\";
                }

                return ResolvePresetDependencyPath(relativePath, baseDir);
            });

        resolved = ReplaceMappedPath(resolved, @"@lua/(?<path>[^""\s]+)", luaDir, true);
        resolved = ReplaceMappedPath(resolved, @"@windivert\.filter/(?<path>[^""\s]+)", windivertFilterDir, true);
        resolved = ReplaceMappedPath(resolved, @"@bin/(?<path>[^""\s]+)", fakeDir, true);
        resolved = ReplaceMappedPath(resolved, @"(?<![@A-Za-z0-9_.-])lists/(?<path>[^""\s]+)", listsDir, false);

        return resolved;
    }

    private static string ReplaceMappedPath(string value, string pattern, string baseDir, bool useAtPrefix)
    {
        return Regex.Replace(
            value,
            pattern,
            delegate(Match match)
            {
                string absolutePath = ResolvePresetDependencyPath(match.Groups["path"].Value, baseDir);
                return (useAtPrefix ? "@" : "") + "\"" + absolutePath + "\"";
            },
            RegexOptions.IgnoreCase);
    }

    private static string ResolvePresetDependencyPath(string relativePath, string baseDir)
    {
        string resolvedPath = Path.GetFullPath(Path.Combine(baseDir, ConvertToWindowsPath(relativePath)));
        if (!File.Exists(resolvedPath) && !Directory.Exists(resolvedPath))
        {
            throw new FileNotFoundException("Preset dependency not found: " + resolvedPath);
        }

        return resolvedPath;
    }

    private static string ResolveExistingPath(string path, string baseDir, string description)
    {
        string windowsPath = ConvertToWindowsPath(path);
        string resolvedPath = Path.IsPathRooted(windowsPath)
            ? Path.GetFullPath(windowsPath)
            : Path.GetFullPath(Path.Combine(baseDir, windowsPath));

        if (!File.Exists(resolvedPath) && !Directory.Exists(resolvedPath))
        {
            throw new FileNotFoundException(description + " not found: " + resolvedPath);
        }

        return resolvedPath;
    }

    private static bool IsEmptyPortArgument(string value)
    {
        return Regex.IsMatch(
            value.Trim(),
            @"^--(?:wf-(?:tcp|udp)(?:-(?:in|out))?|filter-(?:tcp|udp))=(?:""""|''|\s*)$",
            RegexOptions.IgnoreCase);
    }

    private static string ConvertToWindowsPath(string value)
    {
        return value.Replace('/', '\\');
    }
}
