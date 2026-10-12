# ---------------------------------------------------------------------------
# run_all.ps1 - compile and run every testbench with Icarus Verilog (Windows)
#
# Usage (from the repo root):
#   powershell -ExecutionPolicy Bypass -File scripts\run_all.ps1            # all tests
#   powershell -ExecutionPolicy Bypass -File scripts\run_all.ps1 tb_cpu_branch
#   powershell -ExecutionPolicy Bypass -File scripts\run_all.ps1 -Vcd       # also dump waveforms
#
# Logs go to results\<tb>.log, waveforms (with -Vcd) to build\<tb>.vcd.
# ---------------------------------------------------------------------------
param(
    [string[]]$Tests,
    [switch]$Vcd
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

# Locate Icarus Verilog
$iverilog = (Get-Command iverilog -ErrorAction SilentlyContinue).Source
if (-not $iverilog -and (Test-Path 'C:\iverilog\bin\iverilog.exe')) { $iverilog = 'C:\iverilog\bin\iverilog.exe' }
if (-not $iverilog) { Write-Error 'iverilog not found. Install with: winget install Icarus.Verilog' }
$vvp = Join-Path (Split-Path $iverilog) 'vvp.exe'

New-Item -ItemType Directory -Force build, results | Out-Null

if (-not $Tests) {
    $Tests = Get-ChildItem tb\tb_*.v | ForEach-Object { $_.BaseName }
}
$rtl = Get-ChildItem rtl\*.v | ForEach-Object { $_.FullName }

$passed = 0; $failed = @()
foreach ($tb in $Tests) {
    $sim = "build\$tb.vvp"
    $log = "results\$tb.log"
    & $iverilog -g2012 -Wall -I rtl -I tb -o $sim @rtl "tb\$tb.v"
    if ($LASTEXITCODE -ne 0) { $failed += "$tb (compile)"; continue }

    $simArgs = @($sim)
    if ($Vcd) { $simArgs += "+vcd=build/$tb.vcd" }
    $out = & $vvp @simArgs
    $out | Where-Object { $_ -notmatch '^VCD info' } | Set-Content -Encoding utf8 $log
    $out | Where-Object { $_ -notmatch '^VCD info' } | ForEach-Object { Write-Host $_ }

    if ($out -match '^TEST PASSED') { $passed++ } else { $failed += $tb }
    Write-Host ''
}

Write-Host '=========================================='
Write-Host ("  {0} passed, {1} failed" -f $passed, $failed.Count)
foreach ($f in $failed) { Write-Host "  FAILED: $f" }
Write-Host '=========================================='
if ($failed.Count -gt 0) { exit 1 }
