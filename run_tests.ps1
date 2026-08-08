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

$projectRoot = $PSScriptRoot
$testArgs = @("--headless", "--path", $projectRoot, "--script", "res://tests/run_all.gd")
if ($Suite -ne "") { $testArgs += "--suite=$Suite" }
if ($Seed -ne 0)   { $testArgs += "--seed=$Seed" }

& $godot @testArgs
exit $LASTEXITCODE
