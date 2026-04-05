param(
    [string]$Version = "0.1.2",
    [string]$Configuration = "Release",
    [string]$Triplet = "x64-windows-static",
    [switch]$Fresh,
    [string]$GameDataPath,
    [string]$EspSourcePath,
    [string]$DllSourcePath,
    [string]$PexSourceDir,
    [switch]$NoArchive
)

$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$projectRoot = Join-Path $root ".."
$buildScript = Join-Path $projectRoot "tools\build\build-native.ps1"
$packageScript = Join-Path $projectRoot "tools\release\package.ps1"

if (-not (Test-Path $buildScript)) {
    throw "Build script not found: $buildScript"
}

if (-not (Test-Path $packageScript)) {
    throw "Package script not found: $packageScript"
}

Write-Host "Step 1/2: Building native plugin ($Configuration, $Triplet)..."

$buildArgs = @{
    Configuration = $Configuration
    Triplet = $Triplet
}
if ($Fresh) {
    $buildArgs.Fresh = $true
}

& $buildScript @buildArgs
if ($LASTEXITCODE -ne 0) {
    throw "Native build failed."
}

Write-Host "Step 2/2: Creating release package and archive..."

$packageArgs = @{
    Version = $Version
    Configuration = $Configuration
    CreateArchive = (-not $NoArchive)
}

if ($GameDataPath) {
    $packageArgs.GameDataPath = $GameDataPath
}

if ($EspSourcePath) {
    $packageArgs.EspSourcePath = $EspSourcePath
}
if ($DllSourcePath) {
    $packageArgs.DllSourcePath = $DllSourcePath
}
if ($PexSourceDir) {
    $packageArgs.PexSourceDir = $PexSourceDir
}

& $packageScript @packageArgs
if ($LASTEXITCODE -ne 0) {
    throw "Packaging failed."
}

Write-Host "Release flow complete."
