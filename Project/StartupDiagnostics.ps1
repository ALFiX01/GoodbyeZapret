param(
    [string]$LauncherPath,
    [switch]$Quiet
)

$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$errorCount = 0
$warningCount = 0
$fixedCount = 0

function Add-CheckError {
    param([string]$Message)

    $script:errorCount++
    Write-Host ("  [ERROR] " + $Message) -ForegroundColor Red
}

function Add-CheckWarn {
    param([string]$Message)

    $script:warningCount++
    if (-not $Quiet) {
        Write-Host ("  [WARN] " + $Message) -ForegroundColor Yellow
    }
}

function Add-CheckFixed {
    param([string]$Message)

    $script:fixedCount++
    Write-Host ("  [FIXED] " + $Message) -ForegroundColor Green
}

function Add-CheckInfo {
    param([string]$Message)

    if (-not $Quiet) {
        Write-Host ("  [INFO] " + $Message) -ForegroundColor Yellow
    }
}

function Add-CheckOk {
    param([string]$Message)

    if (-not $Quiet) {
        Write-Host ("  [OK] " + $Message) -ForegroundColor Green
    }
}

function Test-RequiredFile {
    param(
        [string]$RootPath,
        [string]$RelativePath,
        [int64]$MinSize = 1
    )

    $path = Join-Path $RootPath $RelativePath
    $item = Get-Item -LiteralPath $path -ErrorAction SilentlyContinue
    if ($null -eq $item) {
        Add-CheckError ("Required file is missing, possibly removed by antivirus: " + $RelativePath)
        return
    }

    if ($item.Length -lt $MinSize) {
        Add-CheckError ("Required file looks corrupted or empty: " + $RelativePath)
    }
}

function Repair-DuplicateConfigKeys {
    param(
        [string]$ConfigPath,
        [string]$Content
    )

    $lines = $Content -split "\r?\n"
    $lastIndexByKey = @{}
    $originalKeyByLower = @{}
    $duplicateKeys = New-Object System.Collections.Generic.List[string]

    for ($i = 0; $i -lt $lines.Count; $i++) {
        $line = $lines[$i]
        $trimmedLine = $line.Trim()

        if ($trimmedLine.Length -eq 0 -or $trimmedLine.StartsWith('#') -or $trimmedLine.StartsWith(';')) {
            continue
        }

        $separatorIndex = $line.IndexOf('=')
        if ($separatorIndex -lt 1) {
            continue
        }

        $rawKey = $line.Substring(0, $separatorIndex)
        $key = $rawKey.Trim()

        if ([string]::IsNullOrWhiteSpace($key) -or $rawKey -ne $key -or $key -match '\s') {
            continue
        }

        $keyLower = $key.ToLowerInvariant()
        if ($lastIndexByKey.ContainsKey($keyLower) -and -not $duplicateKeys.Contains($originalKeyByLower[$keyLower])) {
            [void]$duplicateKeys.Add($originalKeyByLower[$keyLower])
        }

        $lastIndexByKey[$keyLower] = $i
        $originalKeyByLower[$keyLower] = $key
    }

    if ($duplicateKeys.Count -eq 0) {
        return $Content
    }

    $repairedLines = New-Object System.Collections.Generic.List[string]
    for ($i = 0; $i -lt $lines.Count; $i++) {
        $line = $lines[$i]
        $trimmedLine = $line.Trim()

        if ($trimmedLine.Length -eq 0 -or $trimmedLine.StartsWith('#') -or $trimmedLine.StartsWith(';')) {
            [void]$repairedLines.Add($line)
            continue
        }

        $separatorIndex = $line.IndexOf('=')
        if ($separatorIndex -lt 1) {
            [void]$repairedLines.Add($line)
            continue
        }

        $rawKey = $line.Substring(0, $separatorIndex)
        $key = $rawKey.Trim()

        if ([string]::IsNullOrWhiteSpace($key) -or $rawKey -ne $key -or $key -match '\s') {
            [void]$repairedLines.Add($line)
            continue
        }

        $keyLower = $key.ToLowerInvariant()
        if ($lastIndexByKey[$keyLower] -eq $i) {
            [void]$repairedLines.Add($line)
        }
    }

    $repairedContent = [string]::Join([Environment]::NewLine, $repairedLines)
    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($ConfigPath, $repairedContent, $utf8NoBom)

    Add-CheckFixed ("config.txt duplicate keys removed, kept last value for: " + ([string]::Join(', ', $duplicateKeys)))
    return $repairedContent
}

function Test-ConfigFile {
    param([string]$ConfigPath)

    $configErrorCountBefore = $script:errorCount

    if (-not (Test-Path -LiteralPath $ConfigPath)) {
        Add-CheckInfo ("config.txt not found, first launch initialization will create it: " + $ConfigPath)
        return
    }

    $configItem = Get-Item -LiteralPath $ConfigPath -ErrorAction SilentlyContinue
    if ($null -eq $configItem) {
        Add-CheckError ("config.txt cannot be opened: " + $ConfigPath)
        return
    }

    if ($configItem.Length -eq 0) {
        Add-CheckError ("config.txt is empty: " + $ConfigPath)
        return
    }

    $bytes = [System.IO.File]::ReadAllBytes($ConfigPath)
    if ($bytes.Length -ge 2 -and (
            ($bytes[0] -eq 0xFF -and $bytes[1] -eq 0xFE) -or
            ($bytes[0] -eq 0xFE -and $bytes[1] -eq 0xFF))) {
        Add-CheckError 'config.txt is saved as UTF-16. Save it as UTF-8 without BOM.'
        return
    }

    if ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) {
        Add-CheckError 'config.txt contains UTF-8 BOM. Save it as UTF-8 without BOM.'
        return
    }

    if ($bytes -contains 0x00) {
        Add-CheckError 'config.txt contains zero bytes and looks corrupted.'
        return
    }

    try {
        $utf8 = New-Object System.Text.UTF8Encoding($false, $true)
        $content = $utf8.GetString($bytes)
    }
    catch {
        Add-CheckError 'config.txt is not valid UTF-8. Save it as UTF-8 without BOM.'
        return
    }

    $content = Repair-DuplicateConfigKeys -ConfigPath $ConfigPath -Content $content

    $keys = @{}
    $validLineCount = 0
    $lineNumber = 0
    foreach ($line in ($content -split "\r?\n")) {
        $lineNumber++
        $trimmedLine = $line.Trim()

        if ($trimmedLine.Length -eq 0 -or $trimmedLine.StartsWith('#') -or $trimmedLine.StartsWith(';')) {
            continue
        }

        $separatorIndex = $line.IndexOf('=')
        if ($separatorIndex -lt 1) {
            Add-CheckError ("config.txt line " + $lineNumber + " has invalid format: " + $line)
            continue
        }

        $rawKey = $line.Substring(0, $separatorIndex)
        $key = $rawKey.Trim()
        $value = $line.Substring($separatorIndex + 1)

        if ([string]::IsNullOrWhiteSpace($key)) {
            Add-CheckError ("config.txt line " + $lineNumber + " has empty key")
            continue
        }

        if ($rawKey -ne $key -or $key -match '\s') {
            Add-CheckError ("config.txt key on line " + $lineNumber + " contains spaces: " + $rawKey)
            continue
        }

        $keyLower = $key.ToLowerInvariant()
        if ($keys.ContainsKey($keyLower)) {
            Add-CheckError ("config.txt has duplicate key: " + $key)
            continue
        }
        $keys[$keyLower] = $true

        if ($value.Length -lt 2 -or -not $value.StartsWith('"') -or -not $value.EndsWith('"')) {
            Add-CheckError ("config.txt value for " + $key + " must be wrapped in quotes")
            continue
        }

        $unquotedValue = $value.Substring(1, $value.Length - 2)
        if ($unquotedValue -match '\s') {
            Add-CheckError ("config.txt value for " + $key + " contains spaces: " + $value)
            continue
        }

        $validLineCount++
    }

    if ($validLineCount -eq 0) {
        Add-CheckError 'config.txt does not contain any valid key-value entries.'
        return
    }

    if ($script:errorCount -eq $configErrorCountBefore) {
        Add-CheckOk 'config.txt is readable, UTF-8, not empty, and has valid entries'
    }
}

function Repair-TextConfigFileNames {
    param([string]$ProjectRoot)

    $configRoot = Join-Path $ProjectRoot 'configs'
    $configDirs = @(
        'preset'
        'custom'
        'preset\external'
    )

    $configFiles = New-Object System.Collections.Generic.List[System.IO.FileInfo]
    $seenPaths = @{}
    foreach ($relativeDir in $configDirs) {
        $dirPath = Join-Path $configRoot $relativeDir
        if (Test-Path -LiteralPath $dirPath -PathType Container) {
            Get-ChildItem -LiteralPath $dirPath -File -Recurse -ErrorAction SilentlyContinue |
                Where-Object {
                    if ($_.Extension.ToLowerInvariant() -ne '.txt') {
                        $false
                    }
                    else {
                        $baseName = [System.IO.Path]::GetFileNameWithoutExtension($_.Name)
                    $safeBaseName = (($baseName -replace '[^A-Za-z0-9_ -]', '') -replace '\s+', '_') -replace '_+', '_'
                        if ([string]::IsNullOrWhiteSpace($safeBaseName)) {
                            $safeBaseName = 'config'
                        }

                        (($safeBaseName + $_.Extension) -ne $_.Name)
                    }
                } |
                ForEach-Object {
                    $pathKey = $_.FullName.ToLowerInvariant()
                    if (-not $seenPaths.ContainsKey($pathKey)) {
                        $seenPaths[$pathKey] = $true
                        $configFiles.Add($_)
                    }
                }
        }
    }

    foreach ($file in ($configFiles | Sort-Object FullName)) {
        if (-not (Test-Path -LiteralPath $file.FullName -PathType Leaf)) {
            continue
        }

        $currentFile = Get-Item -LiteralPath $file.FullName -ErrorAction SilentlyContinue
        if ($null -eq $currentFile) {
            continue
        }

        $baseName = [System.IO.Path]::GetFileNameWithoutExtension($currentFile.Name)
        $safeBaseName = (($baseName -replace '[^A-Za-z0-9_ -]', '') -replace '\s+', '_') -replace '_+', '_'
        if ([string]::IsNullOrWhiteSpace($safeBaseName)) {
            $safeBaseName = 'config'
        }

        $safeName = $safeBaseName + $currentFile.Extension
        if ($safeName -eq $currentFile.Name) {
            continue
        }

        $targetPath = Join-Path $currentFile.DirectoryName $safeName
        $relativeSource = $currentFile.FullName.Substring($configRoot.Length).TrimStart('\')
        $relativeTarget = $targetPath.Substring($configRoot.Length).TrimStart('\')
        $existingTarget = Get-Item -LiteralPath $targetPath -ErrorAction SilentlyContinue

        if ($null -ne $existingTarget -and $existingTarget.FullName -ne $currentFile.FullName) {
            if ($existingTarget.LastWriteTime -le $currentFile.LastWriteTime) {
                Remove-Item -LiteralPath $existingTarget.FullName -Force
                Add-CheckFixed ("Deleted older duplicate txt config: " + $relativeTarget)
                Rename-Item -LiteralPath $currentFile.FullName -NewName $safeName -ErrorAction Stop
                Add-CheckFixed ("Sanitized txt config file name: " + $relativeSource + " -> " + $relativeTarget)
            }
            else {
                Remove-Item -LiteralPath $currentFile.FullName -Force
                Add-CheckFixed ("Deleted older duplicate txt config: " + $relativeSource)
            }

            continue
        }

        Rename-Item -LiteralPath $currentFile.FullName -NewName $safeName -ErrorAction Stop
        Add-CheckFixed ("Sanitized txt config file name: " + $relativeSource + " -> " + $relativeTarget)
    }
}

function Clear-SpacedConfigSelections {
    param([string]$ConfigPath)

    if (-not (Test-Path -LiteralPath $ConfigPath)) {
        return
    }

    $bytes = [System.IO.File]::ReadAllBytes($ConfigPath)
    if ($bytes.Length -ge 2 -and (
            ($bytes[0] -eq 0xFF -and $bytes[1] -eq 0xFE) -or
            ($bytes[0] -eq 0xFE -and $bytes[1] -eq 0xFF))) {
        return
    }

    if ($bytes -contains 0x00) {
        return
    }

    try {
        $utf8 = New-Object System.Text.UTF8Encoding($false, $true)
        $content = $utf8.GetString($bytes)
    }
    catch {
        return
    }

    $keysToClear = @{
        'goodbyezapret_laststartconfig' = $true
        'goodbyezapret_lastworkconfig' = $true
        'goodbyezapret_config' = $true
    }

    $changed = $false
    $lines = $content -split "\r?\n", -1
    for ($i = 0; $i -lt $lines.Count; $i++) {
        $line = $lines[$i]
        $trimmedLine = $line.Trim()
        if ($trimmedLine.Length -eq 0 -or $trimmedLine.StartsWith('#') -or $trimmedLine.StartsWith(';')) {
            continue
        }

        $separatorIndex = $line.IndexOf('=')
        if ($separatorIndex -lt 1) {
            continue
        }

        $rawKey = $line.Substring(0, $separatorIndex)
        $key = $rawKey.Trim()
        if (-not $keysToClear.ContainsKey($key.ToLowerInvariant())) {
            continue
        }

        $value = $line.Substring($separatorIndex + 1)
        $unquotedValue = $value
        if ($value.Length -ge 2 -and $value.StartsWith('"') -and $value.EndsWith('"')) {
            $unquotedValue = $value.Substring(1, $value.Length - 2)
        }

        if ($unquotedValue -match '\s') {
            $lines[$i] = $rawKey + '=""'
            $changed = $true
            Add-CheckFixed ("Cleared config value with spaces: " + $key)
        }
    }

    if ($changed) {
        $newContent = $lines -join [Environment]::NewLine
        $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
        [System.IO.File]::WriteAllText($ConfigPath, $newContent, $utf8NoBom)
    }
}

function Clear-MissingConfigSelections {
    param(
        [string]$ConfigPath,
        [string]$ProjectRoot
    )

    if (-not (Test-Path -LiteralPath $ConfigPath)) {
        return
    }

    $configRoot = Join-Path $ProjectRoot 'configs'
    if (-not (Test-Path -LiteralPath $configRoot -PathType Container)) {
        return
    }

    $configDirs = @(
        'preset'
        'custom'
        'preset\external'
    )

    $knownConfigs = @{}
    foreach ($relativeDir in $configDirs) {
        $dirPath = Join-Path $configRoot $relativeDir
        if (-not (Test-Path -LiteralPath $dirPath -PathType Container)) {
            continue
        }

        Get-ChildItem -LiteralPath $dirPath -File -Recurse -ErrorAction SilentlyContinue |
            Where-Object { $_.Extension.ToLowerInvariant() -in @('.txt', '.bat', '.cmd') } |
            ForEach-Object {
                $nameKey = $_.Name.ToLowerInvariant()
                $relativeKey = $_.FullName.Substring($configRoot.Length).TrimStart('\').Replace('\', '/').ToLowerInvariant()
                $knownConfigs[$nameKey] = $true
                $knownConfigs[$relativeKey] = $true
            }
    }

    $bytes = [System.IO.File]::ReadAllBytes($ConfigPath)
    if ($bytes.Length -ge 2 -and (
            ($bytes[0] -eq 0xFF -and $bytes[1] -eq 0xFE) -or
            ($bytes[0] -eq 0xFE -and $bytes[1] -eq 0xFF))) {
        return
    }

    if ($bytes -contains 0x00) {
        return
    }

    try {
        $utf8 = New-Object System.Text.UTF8Encoding($false, $true)
        $content = $utf8.GetString($bytes)
    }
    catch {
        return
    }

    $keysToCheck = @{
        'goodbyezapret_laststartconfig' = $true
        'goodbyezapret_lastworkconfig' = $true
        'goodbyezapret_config' = $true
    }

    $changed = $false
    $lines = $content -split "\r?\n", -1
    for ($i = 0; $i -lt $lines.Count; $i++) {
        $line = $lines[$i]
        $trimmedLine = $line.Trim()
        if ($trimmedLine.Length -eq 0 -or $trimmedLine.StartsWith('#') -or $trimmedLine.StartsWith(';')) {
            continue
        }

        $separatorIndex = $line.IndexOf('=')
        if ($separatorIndex -lt 1) {
            continue
        }

        $rawKey = $line.Substring(0, $separatorIndex)
        $key = $rawKey.Trim()
        $keyLower = $key.ToLowerInvariant()
        if (-not $keysToCheck.ContainsKey($keyLower)) {
            continue
        }

        $value = $line.Substring($separatorIndex + 1)
        if ($value.Length -lt 2 -or -not $value.StartsWith('"') -or -not $value.EndsWith('"')) {
            continue
        }

        $unquotedValue = $value.Substring(1, $value.Length - 2)
        if ([string]::IsNullOrWhiteSpace($unquotedValue)) {
            continue
        }

        $normalizedValue = $unquotedValue.Replace('\', '/').TrimStart('/').ToLowerInvariant()
        $configCandidates = @($normalizedValue)
        if ($keyLower -eq 'goodbyezapret_config' -and [string]::IsNullOrEmpty([System.IO.Path]::GetExtension($normalizedValue))) {
            $configCandidates += ($normalizedValue + '.txt')
        }

        $configExists = $false
        foreach ($configCandidate in $configCandidates) {
            if ($knownConfigs.ContainsKey($configCandidate)) {
                $configExists = $true
                break
            }
        }

        if (-not $configExists) {
            $lines[$i] = $rawKey + '=""'
            $changed = $true
            Add-CheckFixed ("Cleared missing config reference: " + $key + '="' + $unquotedValue + '"')
        }
    }

    if ($changed) {
        $newContent = $lines -join [Environment]::NewLine
        $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
        [System.IO.File]::WriteAllText($ConfigPath, $newContent, $utf8NoBom)
    }
}

function Test-ConfigFileNames {
    param([string]$ProjectRoot)

    $configRoot = Join-Path $ProjectRoot 'configs'
    $configDirs = @(
        'preset'
        'custom'
        'preset\external'
    )

    $configFiles = New-Object System.Collections.Generic.List[System.IO.FileInfo]
    foreach ($relativeDir in $configDirs) {
        $dirPath = Join-Path $configRoot $relativeDir
        if (Test-Path -LiteralPath $dirPath -PathType Container) {
            Get-ChildItem -LiteralPath $dirPath -File -Recurse -ErrorAction SilentlyContinue |
                Where-Object { $_.Extension.ToLowerInvariant() -in @('.txt', '.bat', '.cmd') } |
                ForEach-Object { $configFiles.Add($_) }
        }
    }

    $seen = @{}
    $checkedCount = 0
    $configNameErrorCountBefore = $script:errorCount
    foreach ($file in $configFiles) {
        $key = $file.FullName.ToLowerInvariant()
        if ($seen.ContainsKey($key)) {
            continue
        }
        $seen[$key] = $true
        $checkedCount++

        $relativePath = $file.FullName.Substring($configRoot.Length).TrimStart('\')
        if ($file.Extension.ToLowerInvariant() -eq '.txt' -and $file.Name -match '\s') {
            Add-CheckError ("Txt config file name still contains spaces after repair: " + $relativePath)
            continue
        }
        elseif ($file.Name -match '\s') {
            Add-CheckError ("Config file name contains spaces: " + $relativePath)
            continue
        }

        $unsupportedChars = New-Object System.Collections.Generic.List[string]
        foreach ($char in $file.Name.ToCharArray()) {
            $charText = [string]$char
            if ($charText -notmatch '^[A-Za-z0-9_.-]$' -and -not $unsupportedChars.Contains($charText)) {
                $unsupportedChars.Add($charText)
            }
        }

        if ($unsupportedChars.Count -gt 0) {
            Add-CheckError ("Config file name contains unsupported special characters: " + $relativePath + " (" + ($unsupportedChars -join ' ') + ")")
        }
    }

    if ($checkedCount -eq 0) {
        Add-CheckWarn 'No config files found in configs\preset, configs\custom, or configs\preset\external'
        return
    }

    if ($script:errorCount -eq $configNameErrorCountBefore) {
        Add-CheckOk ("Config file names are safe in configs\preset, configs\custom, and configs\preset\external (" + $checkedCount + " checked)")
    }
}

if (-not $Quiet) {
    Write-Host ''
    Write-Host ' GoodbyeZapret startup diagnostics' -ForegroundColor Cyan
    Write-Host ''
}

if ([string]::IsNullOrWhiteSpace($LauncherPath)) {
    $LauncherPath = Join-Path $PSScriptRoot 'Launcher.bat'
}

$launcherItem = Get-Item -LiteralPath $LauncherPath -ErrorAction SilentlyContinue
if ($null -eq $launcherItem) {
    Add-CheckError ("Launcher.bat not found: " + $LauncherPath)
    $projectRoot = $PSScriptRoot
}
else {
    $launcherFullPath = $launcherItem.FullName
    $projectRoot = $launcherItem.DirectoryName

    if ($launcherFullPath -match ' ') {
        Add-CheckError ("Path to Launcher.bat contains spaces: " + $launcherFullPath)
    }
    else {
        Add-CheckOk 'Path to Launcher.bat does not contain spaces'
    }

    if ([regex]::IsMatch($launcherFullPath, '\p{IsCyrillic}')) {
        Add-CheckError ("Path to Launcher.bat contains Cyrillic characters: " + $launcherFullPath)
    }
    else {
        Add-CheckOk 'Path to Launcher.bat does not contain Cyrillic characters'
    }

    $forbiddenPathChars = @('&', '(', ')', '!', '%', '^', '=', ';', ',', "'", '`')
    $foundForbiddenChars = @()
    foreach ($char in $forbiddenPathChars) {
        if ($launcherFullPath.Contains($char)) {
            $foundForbiddenChars += $char
        }
    }

    if ($foundForbiddenChars.Count -gt 0) {
        Add-CheckError ("Path to Launcher.bat contains unsupported special characters: " + ($foundForbiddenChars -join ' '))
    }
    else {
        Add-CheckOk 'Path to Launcher.bat does not contain unsupported special characters'
    }
}

if ([Environment]::Is64BitOperatingSystem -and ($env:PROCESSOR_ARCHITECTURE -eq 'AMD64' -or $env:PROCESSOR_ARCHITEW6432 -eq 'AMD64')) {
    Add-CheckOk 'Windows architecture is supported: x64'
}
else {
    Add-CheckError ("Unsupported Windows architecture. Required: x64 AMD64. Current: " + $env:PROCESSOR_ARCHITECTURE)
}

try {
    $os = Get-CimInstance Win32_OperatingSystem -ErrorAction Stop
    if ($os.Caption -match 'Windows 10|Windows 11') {
        Add-CheckOk ("Windows version is supported: " + $os.Caption)
    }
    else {
        Add-CheckError ("Unsupported Windows version. Required: Windows 10 or Windows 11. Current: " + $os.Caption)
    }
}
catch {
    $version = [Environment]::OSVersion.Version
    if ($version.Major -ge 10) {
        Add-CheckWarn ("Could not read Windows caption, but NT version looks compatible: " + $version.ToString())
    }
    else {
        Add-CheckError ("Unsupported Windows NT version: " + $version.ToString())
    }
}

if (Test-Path -LiteralPath $projectRoot -PathType Container) {
    $writeTestPath = Join-Path $projectRoot ('.gz_write_test_' + [Guid]::NewGuid().ToString('N') + '.tmp')
    try {
        [System.IO.File]::WriteAllText($writeTestPath, 'test', [System.Text.Encoding]::ASCII)
        Remove-Item -LiteralPath $writeTestPath -Force
        Add-CheckOk 'Project folder is writable'
    }
    catch {
        Add-CheckError ("Project folder is not writable: " + $projectRoot)
    }
}
else {
    Add-CheckError ("Project folder not found: " + $projectRoot)
}

$localCurlPath = Join-Path $projectRoot 'tools\curl\curl.exe'
$localCurl = Get-Item -LiteralPath $localCurlPath -ErrorAction SilentlyContinue
$systemCurl = Get-Command curl.exe -ErrorAction SilentlyContinue
if ($null -ne $localCurl -and $localCurl.Length -gt 0) {
    Add-CheckOk 'curl fallback is available: tools\curl\curl.exe'
}
elseif ($null -ne $systemCurl) {
    Add-CheckOk ("curl fallback is available: " + $systemCurl.Source)
}
else {
    Add-CheckError 'curl fallback is unavailable: neither tools\curl\curl.exe nor system curl.exe was found'
}

foreach ($relativeDir in @('bin', 'tools', 'configs', 'lists')) {
    if (Test-Path -LiteralPath (Join-Path $projectRoot $relativeDir) -PathType Container) {
        Add-CheckOk ("Required folder exists: " + $relativeDir)
    }
    else {
        Add-CheckError ("Required folder is missing, possibly removed by antivirus: " + $relativeDir)
    }
}

$requiredFileErrorCountBefore = $errorCount
Test-RequiredFile $projectRoot 'bin\winws2.exe' 1024
Test-RequiredFile $projectRoot 'bin\WinDivert.dll' 1024
Test-RequiredFile $projectRoot 'bin\Monkey64.sys' 1024
Test-RequiredFile $projectRoot 'tools\config_builder\builder.exe' 1024
Test-RequiredFile $projectRoot 'tools\PresetRunner.ps1' 1
Test-RequiredFile $projectRoot 'tools\Updater.exe' 1024
Test-RequiredFile $projectRoot 'tools\service\GoodbyeZapretService.exe' 1024
if ($errorCount -eq $requiredFileErrorCountBefore) {
    Add-CheckOk 'Required executable and driver files are present'
}

Repair-TextConfigFileNames $projectRoot
Test-ConfigFileNames $projectRoot

$configPath = Join-Path $env:APPDATA 'GoodbyeZapret\config.txt'
Clear-SpacedConfigSelections $configPath
Clear-MissingConfigSelections $configPath $projectRoot
Test-ConfigFile $configPath

if ($errorCount -gt 0) {
    Write-Host ''
    Write-Host (" Diagnostics found errors: " + $errorCount) -ForegroundColor Red
    if ($fixedCount -gt 0) {
        Write-Host (" Diagnostics fixes applied: " + $fixedCount) -ForegroundColor Green
    }
    if ($warningCount -gt 0) {
        Write-Host (" Diagnostics warnings: " + $warningCount) -ForegroundColor Yellow
    }
    Write-Host ' Fix the listed issues before starting GoodbyeZapret.' -ForegroundColor Red
    exit 1
}

if ($warningCount -gt 0 -and -not $Quiet) {
    Write-Host ''
    Write-Host (" Diagnostics completed with warnings: " + $warningCount) -ForegroundColor Yellow
    if ($fixedCount -gt 0) {
        Write-Host (" Diagnostics fixes applied: " + $fixedCount) -ForegroundColor Green
    }
}
elseif ($fixedCount -gt 0) {
    Write-Host ''
    Write-Host (" Diagnostics completed successfully. Fixes applied: " + $fixedCount) -ForegroundColor Green
}
elseif (-not $Quiet) {
    Write-Host ''
    Write-Host ' Diagnostics completed successfully.' -ForegroundColor Green
}

if ($fixedCount -gt 0) {
    Start-Sleep -Seconds 3
}
exit 0
