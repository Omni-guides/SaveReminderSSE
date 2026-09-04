$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
$translationRoot = Join-Path $projectRoot "interface\translations"
$languages = @(
    "ENGLISH",
    "FRENCH",
    "GERMAN",
    "ITALIAN",
    "SPANISH",
    "POLISH",
    "RUSSIAN",
    "JAPANESE",
    "CHINESE"
)
$key = '$SRSSE_ReminderMessage'

foreach ($language in $languages) {
    $path = Join-Path $translationRoot ("SaveReminderSSE_" + $language + ".txt")
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        throw "Missing translation file: $path"
    }

    $bytes = [System.IO.File]::ReadAllBytes($path)
    if ($bytes.Length -lt 2 -or $bytes[0] -ne 0xFF -or $bytes[1] -ne 0xFE) {
        throw "Translation file must use UTF-16 LE with a byte-order mark: $path"
    }

    $lines = @(Get-Content -LiteralPath $path -Encoding Unicode | Where-Object { $_ -ne "" })
    if ($lines.Count -ne 1) {
        throw "Translation file must contain exactly one non-empty entry: $path"
    }

    $parts = $lines[0] -split "`t", 2
    if ($parts.Count -ne 2 -or $parts[0] -ne $key -or [string]::IsNullOrWhiteSpace($parts[1])) {
        throw "Invalid translation entry: $path"
    }

    $placeholderCount = ([regex]::Matches($parts[1], [regex]::Escape("{minutes}"))).Count
    if ($placeholderCount -ne 1) {
        throw "Translation must contain {minutes} exactly once: $path"
    }

    if ($parts[1].Contains([char]0x2013) -or $parts[1].Contains([char]0x2014)) {
        throw "Translation contains a forbidden dash character: $path"
    }
}

Write-Host "Validated $($languages.Count) reminder translations."
