param(
    [string]$SkyrimPath
)

$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
$flagsDest = Join-Path $projectRoot "papyrus\_compiler\Source\Scripts\TESV_Papyrus_Flags.flg"

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

if (-not $SkyrimPath) {
    $skyrimCandidates = @(
        "D:\SteamLibrary\steamapps\common\Skyrim Special Edition",
        "C:\Program Files (x86)\Steam\steamapps\common\Skyrim Special Edition",
        "C:\Program Files\Steam\steamapps\common\Skyrim Special Edition"
    )
    $SkyrimPath = Resolve-FirstExistingPath -Candidates $skyrimCandidates -Description "Skyrim Special Edition install folder"
}

$flagsSource = Join-Path $SkyrimPath "Papyrus Compiler\TESV_Papyrus_Flags.flg"

if (-not (Test-Path $flagsSource)) {
    throw "TESV_Papyrus_Flags.flg not found at: $flagsSource`nPass -SkyrimPath to specify your Skyrim SE install folder."
}

Copy-Item -Path $flagsSource -Destination $flagsDest -Force
Write-Host "Copied TESV_Papyrus_Flags.flg from: $flagsSource"
Write-Host "Setup complete. You can now build Papyrus scripts."
