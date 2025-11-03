# Задание цветовой схемы
$Theme = @{
    Primary   = 'Cyan'
    Success   = 'Green'
    Warning   = 'Yellow'
    Error     = 'Red'
    Info      = 'White'
}

# Новый ASCII-логотип GoodbyeZapret
$Logo = @"
   ██████  ██████   ██████  ██████  ██    ██ ███████     ████████  █████  ██████  ████████ 
  ██      ██    ██ ██    ██ ██   ██ ██    ██ ██             ██    ██   ██ ██   ██    ██    
  ██      ██    ██ ██    ██ ██   ██ ██    ██ █████          ██    ███████ ██████     ██    
  ██      ██    ██ ██    ██ ██   ██  ██  ██  ██             ██    ██   ██ ██   ██    ██    
   ██████  ██████   ██████  ██████    ████   ███████        ██    ██   ██ ██   ██    ██    

        Инструмент для обхода DPI-блокировок в Windows
        Репозиторий: github.com/ALFiX01/GoodbyeZapret
"@

# Функция красивого вывода
function Write-Styled {
    param (
        [string]$Message,
        [string]$Color = $Theme.Info,
        [string]$Prefix = ""
    )
    $symbol = switch ($Color) {
        $Theme.Success { "[ОК]" }
        $Theme.Error   { "[ОШИБКА]" }
        $Theme.Warning { "[!]" }
        default        { "[*]" }
    }
    $output = if ($Prefix) { "$symbol $Prefix :: $Message" } else { "$symbol $Message" }
    Write-Host $output -ForegroundColor $Color
}

# Получение информации о последнем релизе
function Get-LatestRelease {
    try {
        $api = "https://api.github.com/repos/ALFiX01/GoodbyeZapret/releases/latest"
        $latestRelease = Invoke-RestMethod -Uri $api
        return @{
            Version = $latestRelease.tag_name
            Assets = $latestRelease.assets
        }
    } catch {
        Write-Styled $_.Exception.Message -Color $Theme.Error -Prefix "Ошибка"
        throw "Не удалось получить информацию о последнем релизе"
    }
}

# Основная функция установки
function Install-GoodbyeZapret {
    Write-Styled "Начало установки GoodbyeZapret" -Color $Theme.Primary -Prefix "Установка"
    $SystemDrive = $env:SystemDrive
    $TargetPath = "$SystemDrive\GoodbyeZapret"
    $ZipFileName = "GoodbyeZapret.zip"
    $LauncherPath = "$TargetPath\Launcher.bat"

    # Получение информации о релизе
    Write-Styled "Получение информации о последнем релизе..." -Color $Theme.Primary -Prefix "Обновление"
    $releaseInfo = Get-LatestRelease
    $asset = $releaseInfo.Assets | Where-Object { $_.name -eq $ZipFileName }
    if (!$asset) {
        Write-Styled "Файл $ZipFileName не найден в релизах" -Color $Theme.Error -Prefix "Ошибка"
        Write-Styled "Доступные файлы:" -Color $Theme.Warning -Prefix "Список"
        $releaseInfo.Assets | ForEach-Object { Write-Styled $_.name -Color $Theme.Info }
        throw "Целевой архив не найден"
    }
    $zipUrl = $asset.browser_download_url
    Write-Styled "Ссылка для скачивания: $zipUrl" -Color $Theme.Info -Prefix "Скачивание"

    # Очистка/удаление старой папки
    if (Test-Path $TargetPath) {
        Write-Styled "Удаление старой версии папки GoodbyeZapret..." -Color $Theme.Warning -Prefix "Очистка"
        try {
            Remove-Item $TargetPath -Recurse -Force
            Write-Styled "Папка успешно удалена" -Color $Theme.Success -Prefix "ОК"
        } catch {
            Write-Styled "Не удалось удалить папку: $_" -Color $Theme.Error -Prefix "Ошибка"
            throw
        }
    }

    # Скачивание архива
    $tmpZipPath = "$SystemDrive\$ZipFileName"
    Write-Styled "Скачивание архива..." -Color $Theme.Primary -Prefix "Скачивание"
    try {
        Invoke-WebRequest -Uri $zipUrl -OutFile $tmpZipPath
        Write-Styled "Архив скачан: $tmpZipPath" -Color $Theme.Success -Prefix "Скачано"
    } catch {
        Write-Styled "Ошибка скачивания: $_" -Color $Theme.Error -Prefix "Ошибка"
        throw
    }

    # Распаковка архива
    Write-Styled "Распаковка архива в $TargetPath..." -Color $Theme.Primary -Prefix "Распаковка"
    try {
        if (-not (Test-Path $TargetPath)) { New-Item -ItemType Directory -Force -Path $TargetPath | Out-Null }
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        [System.IO.Compression.ZipFile]::ExtractToDirectory($tmpZipPath, $TargetPath)
        Write-Styled "Архив успешно распакован" -Color $Theme.Success -Prefix "ОК"
    } catch {
        Write-Styled "Ошибка распаковки: $_" -Color $Theme.Error -Prefix "Ошибка"
        throw
    }
    try { Remove-Item $tmpZipPath -Force } catch {}

    # Запуск Launcher.bat с правами администратора
    if (Test-Path $LauncherPath) {
        Write-Styled "Запуск Launcher.bat..." -Color $Theme.Primary -Prefix "Старт"
        $startInfo = New-Object System.Diagnostics.ProcessStartInfo
        $startInfo.FileName = $LauncherPath
        $startInfo.UseShellExecute = $true
        $startInfo.Verb = "runas"
        try {
            [System.Diagnostics.Process]::Start($startInfo) | Out-Null
            Write-Styled "Launcher запущен" -Color $Theme.Success -Prefix "ОК"
        } catch {
            Write-Styled "Не удалось запустить Launcher с правами администратора! Запуск обычным способом..." -Color $Theme.Warning -Prefix "Внимание"
            Start-Process $LauncherPath
        }
    } else {
        Write-Styled "Файл Launcher.bat не найден!" -Color $Theme.Error -Prefix "Ошибка"
    }
}

# Вывод логотипа
Write-Host $Logo -ForegroundColor $Theme.Primary

# Запуск установки
try {
    Install-GoodbyeZapret
} catch {
    Write-Styled "Установка не удалась" -Color $Theme.Error -Prefix "Ошибка"
    Write-Styled $_.Exception.Message -Color $Theme.Error
}
