param(
    [string]$GameDataPath
)

$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$projectRoot = Join-Path $root ".."

if (-not $GameDataPath) {
    $candidates = @(
        "D:\SteamLibrary\steamapps\common\Skyrim Special Edition\Data",
        "C:\Program Files (x86)\Steam\steamapps\common\Skyrim Special Edition\Data",
        "C:\Program Files\Steam\steamapps\common\Skyrim Special Edition\Data"
    )
    foreach ($candidate in $candidates) {
        if (Test-Path $candidate) {
            $GameDataPath = $candidate
            break
        }
    }
    if (-not $GameDataPath) {
        throw "Could not find Skyrim Data folder automatically. Pass -GameDataPath to specify it."
    }
}

$sourcePath = Join-Path $GameDataPath "SaveReminderSSE.esp"
$destDir = Join-Path $projectRoot "plugin"
$destPath = Join-Path $destDir "SaveReminderSSE.esp"

if (-not (Test-Path $sourcePath)) {
    throw "Plugin not found at: $sourcePath"
}

New-Item -ItemType Directory -Path $destDir -Force | Out-Null
Copy-Item -Path $sourcePath -Destination $destPath -Force

Write-Host "Canonical plugin updated: $destPath"
