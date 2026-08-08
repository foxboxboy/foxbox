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

# Running --script skips the import pass, so without a class cache every class_name in the
# project is unknown and every suite fails to parse. A fresh clone always hits this.
$classCache = Join-Path $projectRoot ".godot\global_script_class_cache.cfg"
if (-not (Test-Path $classCache)) {
    Write-Host "No class cache yet, running a one-time import pass..."
    $null = & $godot --headless --path $projectRoot --editor --quit
}

& $godot @testArgs
exit $LASTEXITCODE
