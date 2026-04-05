param(
    [Parameter(Mandatory)]
    [string]$Version
)

$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot

$files = @(
    @{ Path = Join-Path $projectRoot "CHANGELOG.md";                          Pattern = '\[Unreleased\]'; Replace = "[$Version] - $(Get-Date -Format 'yyyy-MM-dd')" },
    @{ Path = Join-Path $projectRoot "cpp\CMakeLists.txt";                    Pattern = '(?<=project\(SaveReminderSSE VERSION )\d+\.\d+\.\d+'; Replace = $Version },
    @{ Path = Join-Path $projectRoot "cpp\src\main.cpp";                      Pattern = '(?<=REL::Version\{ )0, \d+, \d+, \d+'; Replace = ($Version -replace '\.', ', ') + ', 0' },
    @{ Path = Join-Path $projectRoot "cpp\vcpkg.json";                        Pattern = '(?<="version-string": ")\d+\.\d+\.\d+'; Replace = $Version },
    @{ Path = Join-Path $projectRoot "papyrus\source\SRSSE_MCM.psc";          Pattern = '(?<=String _version = ")\d+\.\d+\.\d+'; Replace = $Version },
    @{ Path = Join-Path $projectRoot "tools\release\make-release.ps1";        Pattern = '(?<=\$Version = ")\d+\.\d+\.\d+'; Replace = $Version },
    @{ Path = Join-Path $projectRoot "tools\release\package.ps1";             Pattern = '(?<=\$Version = ")\d+\.\d+\.\d+'; Replace = $Version }
)

foreach ($file in $files) {
    $content = Get-Content $file.Path -Raw
    $updated = [Regex]::Replace($content, $file.Pattern, $file.Replace)
    if ($updated -eq $content) {
        Write-Warning "No match found in: $($file.Path)"
    } else {
        Set-Content -Path $file.Path -Value $updated -NoNewline
        Write-Host "Updated: $($file.Path)"
    }
}

Write-Host "Version bumped to $Version. Update CHANGELOG.md with release notes, then rebuild."
