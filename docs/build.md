# Build Notes

## First-time setup
Run once after cloning to copy `TESV_Papyrus_Flags.flg` from your local Skyrim SE install:

`powershell -ExecutionPolicy Bypass -File tools/setup.ps1`

Pass `-SkyrimPath` if your install is not in a standard Steam location.

## Release (build + package + .7z)

`powershell -ExecutionPolicy Bypass -File tools/release/make-release.ps1 -Configuration Release -Fresh`

## Local test sync

1. Copy `tools/build/sync-local.ps1.example` to `tools/build/sync-local.ps1`
2. Set `$ModPath` to your local test mod folder
3. Run: `powershell -ExecutionPolicy Bypass -File tools/build/sync-local.ps1`

`sync-local.ps1` is gitignored.

## Native plugin

`powershell -ExecutionPolicy Bypass -File tools/build/build-native.ps1 -Configuration Release -Fresh`

Requires:
- Visual Studio 2022 C++ build tools
- CMake
- vcpkg (`VCPKG_ROOT` env var, or installed at `C:\dev\vcpkg`)
- Skyrim SE + Creation Kit installed (required for Papyrus compiler)

Default triplet: `x64-windows-static`. Override with `-Triplet x64-windows` if needed.

## Papyrus

`powershell -ExecutionPolicy Bypass -File tools/build/build-papyrus.ps1`

Deploy compiled scripts and DLL to a Skyrim `Data` folder:

`powershell -ExecutionPolicy Bypass -File tools/build/deploy-data.ps1`

## Creation Kit

Treat `plugin/SaveReminderSSE.esp` as the canonical plugin. After saving changes in the CK:

`powershell -ExecutionPolicy Bypass -File tools/build/sync-plugin-from-game.ps1`

If you use a mod manager (e.g. MO2), xEdit may save to the mod manager's folder rather than the game Data folder. Pass `-SourcePath` to specify the ESP location directly:

`powershell -ExecutionPolicy Bypass -File tools/build/sync-plugin-from-game.ps1 -SourcePath "path\to\SaveReminderSSE.esp"`
