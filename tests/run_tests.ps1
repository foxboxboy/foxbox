# Runs the FoxFabric test suite headless and forwards the exit code.
#
#   .\run_tests.ps1                 run everything
#   .\run_tests.ps1 -Suite effect   run one module
#   .\run_tests.ps1 -Seed 12345     reproduce a specific random run
#
# Set FOXFABRIC_GODOT to your Godot binary if it is not on PATH.

param(
    [string]$Suite = "",
    [int]$Seed = 0
)

$godot = $env:FOXFABRIC_GODOT
if (-not $godot) {
    $cmd = Get-Command godot -ErrorAction SilentlyContinue
    if ($cmd) { $godot = $cmd.Source }
}
if (-not $godot -or -not (Test-Path $godot)) {
    Write-Host "Could not find Godot." -ForegroundColor Red
    Write-Host 'Set it with:  $env:FOXFABRIC_GODOT = "C:\path\to\Godot_console.exe"'
    exit 2
}

# this script lives in tests/, so the project root is one level up
$projectRoot = Split-Path $PSScriptRoot -Parent
$testArgs = @("--headless", "--path", $projectRoot, "--script", "res://tests/terminal/run_all.gd")
if ($Suite -ne "") { $testArgs += "--suite=$Suite" }
if ($Seed -ne 0)   { $testArgs += "--seed=$Seed" }

# Running --script skips the import pass, so every class_name the cache does not know about is
# unknown and the suites referencing it fail to parse. A fresh clone hits this, and so does
# adding a new class, since the cache is only rebuilt on import. The error it produces says
# "Parse error" and nothing about the cause, so it is worth spending a stat call to avoid.
$classCache = Join-Path $projectRoot ".godot\global_script_class_cache.cfg"
$needsImport = -not (Test-Path $classCache)

if (-not $needsImport) {
    $cacheWritten = (Get-Item $classCache).LastWriteTime
    $newer = Get-ChildItem $projectRoot -Recurse -Filter *.gd -ErrorAction SilentlyContinue |
        Where-Object { $_.FullName -notlike "*\.godot\*" -and $_.LastWriteTime -gt $cacheWritten } |
        Select-Object -First 1
    $needsImport = $null -ne $newer
}

if ($needsImport) {
    Write-Host "Scripts changed since the last import, refreshing the class cache..."
    $null = & $godot --headless --path $projectRoot --editor --quit
}

& $godot @testArgs
exit $LASTEXITCODE
