param(
    [string]$GameDataPath,
    [string]$Configuration = "Release"
)

$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$projectRoot = Join-Path $root ".."

function Resolve-FirstExistingPath {
    param(
        [string[]]$Candidates,
        [string]$Description
    )

    foreach ($candidate in $Candidates) {
        if ($candidate -and (Test-Path $candidate)) {
            return $candidate
        }
    }

    $message = @(
        "Could not find $Description automatically.",
        "Checked:",
        ($Candidates | ForEach-Object { " - $_" })
    ) -join "`n"

    throw $message
}

if (-not $GameDataPath) {
    $gameDataCandidates = @(
        "D:\SteamLibrary\steamapps\common\Skyrim Special Edition\Data",
        "C:\Program Files (x86)\Steam\steamapps\common\Skyrim Special Edition\Data",
        "C:\Program Files\Steam\steamapps\common\Skyrim Special Edition\Data"
    )
    $GameDataPath = Resolve-FirstExistingPath -Candidates $gameDataCandidates -Description "Skyrim Data folder"
}

$dllSource = Join-Path $projectRoot ("cpp\build\" + $Configuration + "\SaveReminderSSE.dll")
$pexSourceDir = Join-Path $projectRoot "papyrus\compiled"
$mcmSettingsSource = Join-Path $projectRoot "mcm\settings.ini"
$mcmDefaultsExampleSource = Join-Path $projectRoot "mcm\SaveReminderSSE_defaults.ini"

if (-not (Test-Path $dllSource)) {
    throw "Native DLL not found: $dllSource"
}

if (-not (Test-Path $pexSourceDir)) {
    throw "Papyrus compiled folder not found: $pexSourceDir"
}

if (-not (Test-Path $mcmSettingsSource)) {
    throw "MCM settings defaults not found: $mcmSettingsSource"
}

if (-not (Test-Path $mcmDefaultsExampleSource)) {
    throw "MCM override example not found: $mcmDefaultsExampleSource"
}

$dllDestDir = Join-Path $GameDataPath "SKSE\Plugins"
$scriptDestDir = Join-Path $GameDataPath "Scripts"
$mcmDestDir = Join-Path $GameDataPath "MCM\Config\SaveReminderSSE"

New-Item -ItemType Directory -Path $dllDestDir -Force | Out-Null
New-Item -ItemType Directory -Path $scriptDestDir -Force | Out-Null
New-Item -ItemType Directory -Path $mcmDestDir -Force | Out-Null

Copy-Item -Path $dllSource -Destination (Join-Path $dllDestDir "SaveReminderSSE.dll") -Force

$pexFiles = @(
    "SRSSE_Native.pex",
    "SRSSE_ReminderController.pex",
    "SRSSE_MCM.pex"
)

foreach ($pex in $pexFiles) {
    $src = Join-Path $pexSourceDir $pex
    if (-not (Test-Path $src)) {
        throw "Missing compiled script: $src"
    }
    Copy-Item -Path $src -Destination (Join-Path $scriptDestDir $pex) -Force
}

Copy-Item -Path $mcmSettingsSource -Destination (Join-Path $mcmDestDir "settings.ini") -Force
Copy-Item -Path $mcmDefaultsExampleSource -Destination (Join-Path $mcmDestDir "SaveReminderSSE_defaults.ini") -Force

Write-Host "Deployment complete."
Write-Host "DLL: " (Join-Path $dllDestDir "SaveReminderSSE.dll")
Write-Host "Scripts: $scriptDestDir"
Write-Host "MCM Settings: $mcmDestDir"
