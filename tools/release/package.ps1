param(
    [string]$Version = "0.1.3",
    [string]$GameDataPath,
    [string]$Configuration = "Release",
    [string]$EspSourcePath,
    [string]$DllSourcePath,
    [string]$PexSourceDir,
    [bool]$CreateArchive = $true
)

$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$projectRoot = Join-Path $root ".."
$workspaceRoot = Join-Path $projectRoot ".."
$distRoot = Join-Path $workspaceRoot "dist"
$packageName = "SaveReminderSSE_v" + $Version
$packageRoot = Join-Path $distRoot $packageName
$dataRoot = Join-Path $packageRoot "Data"
$sevenZipPath = Join-Path $distRoot ($packageName + ".7z")
$readmeSource = Join-Path $projectRoot "docs\\readme.txt"
$canonicalEspPath = Join-Path $projectRoot "plugin\\SaveReminderSSE.esp"
$mcmSettingsSource = Join-Path $projectRoot "mcm\\settings.ini"
$mcmDefaultsExampleSource = Join-Path $projectRoot "mcm\\SaveReminderSSE_defaults.ini"

if (-not $EspSourcePath) {
    if (Test-Path $canonicalEspPath) {
        $EspSourcePath = $canonicalEspPath
    } elseif ($GameDataPath) {
        $EspSourcePath = Join-Path $GameDataPath "SaveReminderSSE.esp"
    } else {
        $EspSourcePath = $canonicalEspPath
    }
}
if (-not $DllSourcePath) {
    $DllSourcePath = Join-Path $projectRoot ("cpp\\build\\" + $Configuration + "\\SaveReminderSSE.dll")
}
if (-not $PexSourceDir) {
    $PexSourceDir = Join-Path $projectRoot "papyrus\\compiled"
}
$nativeBinDir = Split-Path -Parent $DllSourcePath
$FmtSourcePath = Join-Path $nativeBinDir "fmt.dll"
$SpdlogSourcePath = Join-Path $nativeBinDir "spdlog.dll"

$required = @(
    @{ Path = $EspSourcePath; Name = "SaveReminderSSE.esp" },
    @{ Path = $DllSourcePath; Name = "SaveReminderSSE.dll" },
    @{ Path = (Join-Path $PexSourceDir "SRSSE_Native.pex"); Name = "SRSSE_Native.pex" },
    @{ Path = (Join-Path $PexSourceDir "SRSSE_ReminderController.pex"); Name = "SRSSE_ReminderController.pex" },
    @{ Path = (Join-Path $PexSourceDir "SRSSE_MCM.pex"); Name = "SRSSE_MCM.pex" },
    @{ Path = $mcmSettingsSource; Name = "mcm\\settings.ini" },
    @{ Path = $mcmDefaultsExampleSource; Name = "mcm\\SaveReminderSSE_defaults.ini" },
    @{ Path = $readmeSource; Name = "readme.txt" }
)

$missing = @($required | Where-Object { -not (Test-Path $_.Path) })
if ($missing.Count -gt 0) {
    $lines = $missing | ForEach-Object { "- " + $_.Name + " expected at: " + $_.Path }
    throw ("Cannot package; missing required files:`n" + ($lines -join "`n"))
}

if (Test-Path $packageRoot) {
    Remove-Item -Recurse -Force $packageRoot
}
if (Test-Path $sevenZipPath) {
    Remove-Item -Force $sevenZipPath
}

$paths = @(
    (Join-Path $dataRoot "SKSE\\Plugins"),
    (Join-Path $dataRoot "Scripts"),
    (Join-Path $dataRoot "MCM\\Config\\SaveReminderSSE")
)
foreach ($p in $paths) {
    New-Item -ItemType Directory -Path $p -Force | Out-Null
}

Copy-Item -Path $EspSourcePath -Destination (Join-Path $dataRoot "SaveReminderSSE.esp") -Force
Copy-Item -Path $DllSourcePath -Destination (Join-Path $dataRoot "SKSE\\Plugins\\SaveReminderSSE.dll") -Force
if (Test-Path $FmtSourcePath) {
    Copy-Item -Path $FmtSourcePath -Destination (Join-Path $dataRoot "SKSE\\Plugins\\fmt.dll") -Force
}
if (Test-Path $SpdlogSourcePath) {
    Copy-Item -Path $SpdlogSourcePath -Destination (Join-Path $dataRoot "SKSE\\Plugins\\spdlog.dll") -Force
}
Copy-Item -Path (Join-Path $PexSourceDir "SRSSE_Native.pex") -Destination (Join-Path $dataRoot "Scripts\\SRSSE_Native.pex") -Force
Copy-Item -Path (Join-Path $PexSourceDir "SRSSE_ReminderController.pex") -Destination (Join-Path $dataRoot "Scripts\\SRSSE_ReminderController.pex") -Force
Copy-Item -Path (Join-Path $PexSourceDir "SRSSE_MCM.pex") -Destination (Join-Path $dataRoot "Scripts\\SRSSE_MCM.pex") -Force
Copy-Item -Path $mcmSettingsSource -Destination (Join-Path $dataRoot "MCM\\Config\\SaveReminderSSE\\settings.ini") -Force
Copy-Item -Path $mcmDefaultsExampleSource -Destination (Join-Path $dataRoot "MCM\\Config\\SaveReminderSSE\\SaveReminderSSE_defaults.ini") -Force
Copy-Item -Path $readmeSource -Destination (Join-Path $packageRoot "README.txt") -Force

if ($CreateArchive) {
    $sevenZipExe = Get-Command 7z -ErrorAction SilentlyContinue
    if (-not $sevenZipExe) {
        $sevenZipExe = Get-Command 7za -ErrorAction SilentlyContinue
    }
    if (-not $sevenZipExe) {
        $candidatePaths = @(
            "C:\Program Files\7-Zip\7z.exe",
            "C:\Program Files (x86)\7-Zip\7z.exe"
        )
        foreach ($candidate in $candidatePaths) {
            if (Test-Path $candidate) {
                $sevenZipExe = @{ Source = $candidate }
                break
            }
        }
    }
    if (-not $sevenZipExe) {
        throw "7-Zip was not found. Install 7-Zip and ensure 7z.exe is in PATH."
    }

    Push-Location $distRoot
    try {
        & $sevenZipExe.Source a -t7z -mx=9 $sevenZipPath $packageName | Out-Host
        if ($LASTEXITCODE -ne 0) {
            throw "7-Zip failed with exit code $LASTEXITCODE"
        }
    } finally {
        Pop-Location
    }

    Write-Host "Archive created: $sevenZipPath"
}

Write-Host "Package staged at: $packageRoot"
