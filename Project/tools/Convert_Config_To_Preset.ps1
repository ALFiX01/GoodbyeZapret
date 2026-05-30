param(
    [string]$ConfigRoot,
    [string]$SourceFile
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Split-CmdArguments {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Text
    )

    $tokens = New-Object System.Collections.Generic.List[string]
    $buffer = New-Object System.Text.StringBuilder
    $inQuotes = $false

    foreach ($char in $Text.ToCharArray()) {
        if ($char -eq '"') {
            $inQuotes = -not $inQuotes
            [void]$buffer.Append($char)
            continue
        }

        if ([char]::IsWhiteSpace($char) -and -not $inQuotes) {
            if ($buffer.Length -gt 0) {
                $tokens.Add($buffer.ToString())
                [void]$buffer.Clear()
            }
            continue
        }

        [void]$buffer.Append($char)
    }

    if ($buffer.Length -gt 0) {
        $tokens.Add($buffer.ToString())
    }

    return $tokens
}

function Get-DefaultValueMap {
    param(
        $Lines
    )

    $defaults = @{
        "CDN_BypassLevel" = "base"
    }

    foreach ($line in $Lines) {
        if ($line -match 'if\s+not\s+defined\s+([A-Za-z_][A-Za-z0-9_]*)\s+set\s+"?[A-Za-z_][A-Za-z0-9_]*=(.*?)(?:"?)\s*$') {
            $defaults[$matches[1]] = $matches[2]
        }
    }

    return $defaults
}

function Convert-LegacyConfig {
    param(
        [Parameter(Mandatory = $true)]
        [System.IO.FileInfo]$Source
    )

    if ($Source.BaseName -ieq "smart-config") {
        return
    }

    $lines = Get-Content -LiteralPath $Source.FullName -Encoding UTF8
    $defaults = Get-DefaultValueMap -Lines $lines
    $launches = @()

    for ($i = 0; $i -lt $lines.Count; $i++) {
        $trimmed = $lines[$i].Trim()
        if ($trimmed -notmatch '^(?i)start\s+".*?"\s+/(?:min|b)\s+"%BIN%(winws2?|winws)\.exe"\s*(.*)$') {
            continue
        }

        $engine = if ($matches[1].ToLowerInvariant() -eq "winws2") { "winws2.exe" } else { "winws.exe" }
        $parts = New-Object System.Collections.Generic.List[string]
        $fragment = $matches[2].Trim()
        if ($fragment.EndsWith("^")) {
            $fragment = $fragment.Substring(0, $fragment.Length - 1).TrimEnd()
        }
        if ($fragment.Length -gt 0) {
            $parts.Add($fragment)
        }

        while (($i + 1) -lt $lines.Count) {
            $nextTrimmed = $lines[$i + 1].Trim()

            if (-not $nextTrimmed) {
                $i++
                continue
            }

            if ($nextTrimmed.StartsWith("REM ", [System.StringComparison]::OrdinalIgnoreCase) -or $nextTrimmed.StartsWith("::")) {
                $i++
                continue
            }

            if (-not $nextTrimmed.StartsWith("--")) {
                break
            }

            $i++
            if ($nextTrimmed.EndsWith("^")) {
                $nextTrimmed = $nextTrimmed.Substring(0, $nextTrimmed.Length - 1).TrimEnd()
            }

            if ($nextTrimmed.Length -gt 0) {
                $parts.Add($nextTrimmed)
            }
        }

        if ($parts.Count -gt 0) {
            $launches += [pscustomobject]@{
                Engine = $engine
                CommandLine = ($parts -join " ")
            }
        }
    }

    if ($launches.Count -ne 1) {
        return
    }

    $args = Split-CmdArguments -Text $launches[0].CommandLine |
        Where-Object { $_ -and $_ -ne "%log%" }

    if (@($args).Count -eq 0) {
        return
    }

    $normalizedArgs = foreach ($arg in $args) {
        $value = $arg

        foreach ($key in $defaults.Keys) {
            $pattern = [regex]::Escape("%$key%")
            $regex = [regex]::new($pattern, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
            $value = $regex.Replace($value, [System.Text.RegularExpressions.MatchEvaluator]{ param($m) $defaults[$key] })
        }

        $value = $value.Replace("%BIN%", "{{BIN}}")
        $value = $value.Replace("%LISTS%", "{{LISTS}}")
        $value = $value.Replace("%FAKE%", "{{FAKE}}")
        $value = $value.Replace("%ProjectDir%", "{{PROJECT}}")
        $value
    }

    $targetPath = Join-Path $Source.DirectoryName ($Source.BaseName + ".txt")
    if (Test-Path -LiteralPath $targetPath) {
        $existing = Get-Content -LiteralPath $targetPath -Raw -Encoding UTF8
        $expectedMarker = "# GeneratedFrom: $($Source.Name)"
        $escapedMarker = [regex]::Escape($expectedMarker)
        if ($existing -notmatch "(?im)^$escapedMarker\s*$") {
            return
        }
    }

    $content = @(
        "# Preset: $($Source.BaseName)"
        "# Engine: $($launches[0].Engine)"
        "# GeneratedFrom: $($Source.Name)"
        ""
        $normalizedArgs
    ) -join [Environment]::NewLine

    Set-Content -LiteralPath $targetPath -Value ($content + [Environment]::NewLine) -Encoding UTF8
}

$sources = @()
if ($SourceFile) {
    $sources += Get-Item -LiteralPath $SourceFile
} elseif ($ConfigRoot) {
    $sources += Get-ChildItem -LiteralPath $ConfigRoot -Recurse -File -ErrorAction SilentlyContinue |
        Where-Object { $_.Extension -in ".bat", ".cmd" }
}

foreach ($source in $sources) {
    Convert-LegacyConfig -Source $source
}
