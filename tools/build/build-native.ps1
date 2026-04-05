param(
    [string]$Configuration = "Release",
    [string]$Generator = "Visual Studio 17 2022",
    [string]$Triplet = "x64-windows-static",
    [switch]$Fresh
)

$ErrorActionPreference = "Stop"

$gitCmd = Get-Command git -ErrorAction SilentlyContinue
if (-not $gitCmd) {
    $gitFallback = "C:\Program Files\Git\cmd\git.exe"
    if (Test-Path $gitFallback) {
        $gitExe = $gitFallback
    }
} else {
    $gitExe = $gitCmd.Source
}

if ($gitExe) {
    $gitDir = Split-Path -Parent $gitExe
    if ($env:Path -notlike "*$gitDir*") {
        $env:Path = "$gitDir;$env:Path"
    }
    $env:GIT = $gitExe
    $env:GIT_EXECUTABLE = $gitExe
}

$cmakeCmd = Get-Command cmake -ErrorAction SilentlyContinue
if (-not $cmakeCmd) {
    $fallback = "C:\Program Files\CMake\bin\cmake.exe"
    if (Test-Path $fallback) {
        $cmakeExe = $fallback
    } else {
        throw "CMake is not installed or not available in PATH. Install CMake and reopen the terminal."
    }
} else {
    $cmakeExe = $cmakeCmd.Source
}

if (-not $env:VCPKG_ROOT) {
    $fallbackRoot = "C:\dev\vcpkg"
    if (Test-Path $fallbackRoot) {
        $env:VCPKG_ROOT = $fallbackRoot
    } else {
        throw "VCPKG_ROOT is not set. Install vcpkg and set VCPKG_ROOT to its folder path."
    }
}

$toolchain = Join-Path $env:VCPKG_ROOT "scripts\buildsystems\vcpkg.cmake"
if (-not (Test-Path $toolchain)) {
    throw "vcpkg toolchain not found at: $toolchain"
}

$root = Split-Path -Parent $PSScriptRoot
$cppDir = Join-Path $root "..\cpp"
$buildDir = Join-Path $cppDir "build"

if ($Fresh -and (Test-Path $buildDir)) {
    Remove-Item -Recurse -Force $buildDir
}

if (-not (Test-Path $buildDir)) {
    New-Item -ItemType Directory -Path $buildDir | Out-Null
}

$msvcRuntime = if ($Triplet -like "*-static*") {
    'MultiThreaded$<$<CONFIG:Debug>:Debug>'
} else {
    'MultiThreaded$<$<CONFIG:Debug>:Debug>DLL'
}

$configureArgs = @(
    "-S", $cppDir,
    "-B", $buildDir,
    "-G", $Generator,
    "-DCMAKE_TOOLCHAIN_FILE=$toolchain",
    "-DCMAKE_MSVC_RUNTIME_LIBRARY=$msvcRuntime",
    "-DVCPKG_MANIFEST_MODE=ON",
    "-DVCPKG_MANIFEST_DIR=$cppDir",
    "-DVCPKG_TARGET_TRIPLET=$Triplet"
)

& $cmakeExe @configureArgs
if ($LASTEXITCODE -ne 0) {
    throw "CMake configure failed. Ensure VS C++ tools and vcpkg dependencies are installed."
}

& $cmakeExe --build $buildDir --config $Configuration
if ($LASTEXITCODE -ne 0) {
    throw "CMake build failed. Review compiler/dependency errors above."
}

Write-Host "Native build completed: $Configuration"
