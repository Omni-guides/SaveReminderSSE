param(
    [string]$GameDataPath,
    [string]$PapyrusCompilerPath,
    [string]$SkyUiSourcePath,
    [string]$Configuration = "Release",
    [switch]$SkipDeploy
)

$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$projectRoot = Join-Path $root ".."
$buildPapyrusScript = Join-Path $projectRoot "tools\build\build-papyrus.ps1"
$deployScript = Join-Path $projectRoot "tools\build\deploy-data.ps1"

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

if (-not (Test-Path $buildPapyrusScript)) {
    throw "Papyrus build script not found: $buildPapyrusScript"
}

if (-not (Test-Path $deployScript)) {
    throw "Deploy script not found: $deployScript"
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

Write-Host "Using GameDataPath: $GameDataPath"
Write-Host "Using PapyrusCompilerPath: $PapyrusCompilerPath"

$buildArgs = @{
    PapyrusCompilerPath = $PapyrusCompilerPath
    GameDataPath = $GameDataPath
}

if ($SkyUiSourcePath) {
    $buildArgs.SkyUiSourcePath = $SkyUiSourcePath
}

Write-Host "Step 1/2: Recompiling Papyrus scripts..."
& $buildPapyrusScript @buildArgs
if ($LASTEXITCODE -ne 0) {
    throw "Papyrus compilation failed."
}

if (-not $SkipDeploy) {
    Write-Host "Step 2/2: Deploying DLL and scripts to the game Data folder..."
    & $deployScript -GameDataPath $GameDataPath -Configuration $Configuration
    if ($LASTEXITCODE -ne 0) {
        throw "Deployment failed."
    }
} else {
    Write-Host "Step 2/2: Deployment skipped."
}

Write-Host "Recompile flow complete."
