param(
    [string]$SourcePath,
    [string]$GameDataPath
)

$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$projectRoot = Join-Path $root ".."

if (-not $SourcePath) {
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
            throw "Could not find Skyrim Data folder automatically. Pass -GameDataPath or -SourcePath to specify the ESP location."
        }
    }
    $SourcePath = Join-Path $GameDataPath "SaveReminderSSE.esp"
}

if (-not (Test-Path $SourcePath)) {
    throw "Plugin not found at: $SourcePath`nIf you use a mod manager, pass -SourcePath pointing directly to the ESP in your mod manager's folder."
}

$destDir = Join-Path $projectRoot "plugin"
$destPath = Join-Path $destDir "SaveReminderSSE.esp"

New-Item -ItemType Directory -Path $destDir -Force | Out-Null
Copy-Item -Path $SourcePath -Destination $destPath -Force

Write-Host "Canonical plugin updated: $destPath"
