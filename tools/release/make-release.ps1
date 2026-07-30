param(
    [string]$Version = "0.2.2",
    [string]$Configuration = "Release",
    [string]$Triplet = "x64-windows-static",
    [switch]$Fresh,
    [string]$GameDataPath,
    [string]$EspSourcePath,
    [string]$DllSourcePath,
    [string]$PexSourceDir,
    [switch]$NoArchive,
    [switch]$SkipVcpkgInstall
)

$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$projectRoot = Join-Path $root ".."
$buildScript = Join-Path $projectRoot "tools\build\build-native.ps1"
$papyrusBuildScript = Join-Path $projectRoot "tools\build\build-papyrus.ps1"
$packageScript = Join-Path $projectRoot "tools\release\package.ps1"

if (-not (Test-Path $buildScript)) {
    throw "Build script not found: $buildScript"
}

if (-not (Test-Path $packageScript)) {
    throw "Package script not found: $packageScript"
}

if (-not (Test-Path $papyrusBuildScript)) {
    throw "Papyrus build script not found: $papyrusBuildScript"
}

Write-Host "Step 1/3: Building native plugin ($Configuration, $Triplet)..."

$buildArgs = @{
    Configuration = $Configuration
    Triplet = $Triplet
}
if ($Fresh) {
    $buildArgs.Fresh = $true
}
if ($SkipVcpkgInstall) {
    $buildArgs.SkipVcpkgInstall = $true
}

& $buildScript @buildArgs
if ($LASTEXITCODE -ne 0) {
    throw "Native build failed."
}

Write-Host "Step 2/3: Building Papyrus scripts..."

$papyrusBuildArgs = @{}
if ($GameDataPath) {
    $papyrusBuildArgs.GameDataPath = $GameDataPath
}

& $papyrusBuildScript @papyrusBuildArgs
if ($LASTEXITCODE -ne 0) {
    throw "Papyrus build failed."
}

Write-Host "Step 3/3: Creating release package and archive..."

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
