# Set color theme
$Theme = @{
    Primary   = 'Cyan'
    Success   = 'Green'
    Warning   = 'Yellow'
    Error     = 'Red'
    Info      = 'White'
}

# GoodbyeZapret ASCII Logo (English, fresh style)
$Logo = @"

 ██████╗  ██████╗  ██████╗ ██████╗ ██╗   ██╗███████╗    ███████╗ █████╗ ██████╗ ██████╗ ███████╗████████╗
██╔════╝ ██╔═══██╗██╔═══██╗██╔══██╗╚██╗ ██╔╝██╔════╝    ╚══███╔╝██╔══██╗██╔══██╗██╔══██╗██╔════╝╚══██╔══╝
██║  ███╗██║   ██║██║   ██║██████╔╝ ╚████╔╝ █████╗        ███╔╝ ███████║██████╔╝██████╔╝█████╗     ██║   
██║   ██║██║   ██║██║   ██║██╔══██╗  ╚██╔╝  ██╔══╝       ███╔╝  ██╔══██║██╔═══╝ ██╔══██╗██╔══╝     ██║   
╚██████╔╝╚██████╔╝╚██████╔╝██████╔╝   ██║   ███████╗    ███████╗██║  ██║██║     ██║  ██║███████╗   ██║   
 ╚═════╝  ╚═════╝  ╚═════╝ ╚═════╝    ╚═╝   ╚══════╝    ╚══════╝╚═╝  ╚═╝╚═╝     ╚═╝  ╚═╝╚══════╝   ╚═╝   
                                                                                                                    
                    DPI bypass for Windows | github.com/ALFiX01/GoodbyeZapret
"@

# Fancy output function
function Write-Styled {
    param (
        [string]$Message,
        [string]$Color = $Theme.Info,
        [string]$Prefix = ""
    )
    $symbol = switch ($Color) {
        $Theme.Success { "[OK]" }
        $Theme.Error   { "[ERROR]" }
        $Theme.Warning { "[!]" }
        default        { "[*]" }
    }
    $output = if ($Prefix) { "$symbol $Prefix :: $Message" } else { "$symbol $Message" }
    Write-Host $output -ForegroundColor $Color
}

# Get latest release function
function Get-LatestRelease {
    try {
        $api = "https://api.github.com/repos/ALFiX01/GoodbyeZapret/releases/latest"
        $latestRelease = Invoke-RestMethod -Uri $api
        return @{
            Version = $latestRelease.tag_name
            Assets = $latestRelease.assets
        }
    } catch {
        Write-Styled $_.Exception.Message -Color $Theme.Error -Prefix "Error"
        throw "Could not fetch latest release info."
    }
}

# Main install function
function Install-GoodbyeZapret {
    Write-Styled "Starting GoodbyeZapret setup" -Color $Theme.Primary -Prefix "Install"
    $SystemDrive = $env:SystemDrive
    $TargetPath = "$SystemDrive\GoodbyeZapret"
    $ZipFileName = "GoodbyeZapret.zip"
    $LauncherPath = "$TargetPath\Launcher.bat"

    # Get release info
    Write-Styled "Getting latest release info..." -Color $Theme.Primary -Prefix "Update"
    $releaseInfo = Get-LatestRelease
    $asset = $releaseInfo.Assets | Where-Object { $_.name -eq $ZipFileName }
    if (!$asset) {
        Write-Styled "$ZipFileName not found in releases!" -Color $Theme.Error -Prefix "Error"
        Write-Styled "Available files:" -Color $Theme.Warning -Prefix "List"
        $releaseInfo.Assets | ForEach-Object { Write-Styled $_.name -Color $Theme.Info }
        throw "Target archive not found."
    }
    $zipUrl = $asset.browser_download_url
    Write-Styled "Download link: $zipUrl" -Color $Theme.Info -Prefix "Download"

    # Cleanup previous folder
    if (Test-Path $TargetPath) {
        Write-Styled "Removing previous GoodbyeZapret folder..." -Color $Theme.Warning -Prefix "Cleanup"
        try {
            Remove-Item $TargetPath -Recurse -Force
            Write-Styled "Folder removed successfully" -Color $Theme.Success -Prefix "OK"
        } catch {
            Write-Styled "Failed to remove folder: $_" -Color $Theme.Error -Prefix "Error"
            throw
        }
    }

    # Download archive
    $tmpZipPath = "$env:TEMP\$ZipFileName"
    Write-Styled "Downloading archive..." -Color $Theme.Primary -Prefix "Download"
    try {
        Invoke-WebRequest -Uri $zipUrl -OutFile $tmpZipPath
        Write-Styled "Archive downloaded: $tmpZipPath" -Color $Theme.Success -Prefix "Downloaded"
    } catch {
        Write-Styled "Download failed: $_" -Color $Theme.Error -Prefix "Error"
        throw
    }

    # Extract archive
    Write-Styled "Extracting archive to $TargetPath..." -Color $Theme.Primary -Prefix "Extract"
    try {
        if (-not (Test-Path $TargetPath)) { New-Item -ItemType Directory -Force -Path $TargetPath | Out-Null }
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        [System.IO.Compression.ZipFile]::ExtractToDirectory($tmpZipPath, $TargetPath)
        Write-Styled "Archive extracted successfully" -Color $Theme.Success -Prefix "OK"
    } catch {
        Write-Styled "Extracting failed: $_" -Color $Theme.Error -Prefix "Error"
        throw
    }
    try { Remove-Item $tmpZipPath -Force } catch {}

    # Launch Launcher.bat as administrator
    if (Test-Path $LauncherPath) {
        Write-Styled "Launching Launcher.bat..." -Color $Theme.Primary -Prefix "Start"
        $startInfo = New-Object System.Diagnostics.ProcessStartInfo
        $startInfo.FileName = $LauncherPath
        $startInfo.UseShellExecute = $true
        $startInfo.Verb = "runas"
        try {
            [System.Diagnostics.Process]::Start($startInfo) | Out-Null
            Write-Styled "Launcher started" -Color $Theme.Success -Prefix "OK"
        } catch {
            Write-Styled "Failed to launch with administrator! Starting normally..." -Color $Theme.Warning -Prefix "Warning"
            Start-Process $LauncherPath
        }
    } else {
        Write-Styled "Launcher.bat not found!" -Color $Theme.Error -Prefix "Error"
    }
}

# Print logo
Write-Host $Logo -ForegroundColor $Theme.Primary

# Run installation
try {
    Install-GoodbyeZapret
} catch {
    Write-Styled "Setup failed" -Color $Theme.Error -Prefix "Error"
    Write-Styled $_.Exception.Message -Color $Theme.Error
}
