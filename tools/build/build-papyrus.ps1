param(
    [string]$PapyrusCompilerPath,
    [string]$GameDataPath,
    [string]$SkyUiSourcePath,
    [string]$OutputPath,
    [switch]$UseOnlyAvailableScripts
)

$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$projectRoot = Join-Path $root ".."
$sourcePath = Join-Path $projectRoot "papyrus\source"
$compilerSupportPath = Join-Path $projectRoot "papyrus\_compiler\Source\Scripts"
$mcmHelperSupportPath = Join-Path $projectRoot "papyrus\_compiler\MCMHelper\scripts"
$flagsPath = Join-Path $compilerSupportPath "TESV_Papyrus_Flags.flg"

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

if (-not $PapyrusCompilerPath) {
    $compilerCandidates = @(
        (Join-Path (Split-Path $GameDataPath -Parent) "Papyrus Compiler\PapyrusCompiler.exe"),
        "D:\SteamLibrary\steamapps\common\Skyrim Special Edition\Papyrus Compiler\PapyrusCompiler.exe",
        "C:\Program Files (x86)\Steam\steamapps\common\Skyrim Special Edition\Papyrus Compiler\PapyrusCompiler.exe",
        "C:\Program Files\Steam\steamapps\common\Skyrim Special Edition\Papyrus Compiler\PapyrusCompiler.exe"
    )
    $PapyrusCompilerPath = Resolve-FirstExistingPath -Candidates $compilerCandidates -Description "PapyrusCompiler.exe"
}

$vanillaSourcePath = Join-Path $GameDataPath "Source\Scripts"

if (-not $SkyUiSourcePath) {
    $SkyUiSourcePath = Join-Path $compilerSupportPath "Source"
}

if (-not $OutputPath) {
    $OutputPath = Join-Path $projectRoot "papyrus\compiled"
}

if (-not (Test-Path $PapyrusCompilerPath)) {
    throw "Papyrus compiler not found at: $PapyrusCompilerPath"
}

if (-not (Test-Path $sourcePath)) {
    throw "Papyrus source folder not found: $sourcePath"
}

if (-not (Test-Path $flagsPath)) {
    throw "Papyrus flags file not found: $flagsPath`nRun tools/setup.ps1 to copy it from your Skyrim SE install."
}

if (-not (Test-Path $vanillaSourcePath)) {
    throw "Vanilla source path not found: $vanillaSourcePath"
}

if (-not (Test-Path $SkyUiSourcePath)) {
    throw "SkyUI source path not found: $SkyUiSourcePath"
}

if (-not (Test-Path $OutputPath)) {
    New-Item -ItemType Directory -Path $OutputPath | Out-Null
}

$scripts = @(
    "SRSSE_Native.psc",
    "SRSSE_ReminderController.psc",
    "SRSSE_MCM.psc"
)

if ($UseOnlyAvailableScripts) {
    $scripts = $scripts | Where-Object { Test-Path (Join-Path $sourcePath $_) }
}

$imports = "$sourcePath;$SkyUiSourcePath;$vanillaSourcePath"
if (Test-Path $mcmHelperSupportPath) {
    $imports += ";$mcmHelperSupportPath"
}
$failed = @()

Push-Location $sourcePath
try {
    foreach ($script in $scripts) {
        if (-not (Test-Path (Join-Path $sourcePath $script))) {
            throw "Missing script source: $script"
        }

        & $PapyrusCompilerPath $script "-f=$flagsPath" "-i=$imports" "-o=$OutputPath"
        if ($LASTEXITCODE -ne 0) {
            $failed += $script
        }
    }
}
finally {
    Pop-Location
}

if ($failed.Count -gt 0) {
    throw ("Papyrus compile failed for: " + ($failed -join ", "))
}

Write-Host "Papyrus build completed."
Write-Host "Output: $OutputPath"
