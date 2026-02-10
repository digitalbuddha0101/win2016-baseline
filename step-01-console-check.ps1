# step-01-console-check.ps1
$ErrorActionPreference = "Stop"

Write-Host "=== STEP 01: Console sanity ===" -ForegroundColor Cyan
Write-Host ("Host: {0}" -f $Host.Name)
Write-Host ("PSVersion: {0}" -f $PSVersionTable.PSVersion)

$ok = $true

if ($Host.Name -notmatch "ConsoleHost") {
  Write-Host ("WARN: Unexpected host: {0}" -f $Host.Name) -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Type this exact text, then press Enter:" -ForegroundColor Cyan
Write-Host "  abc 123 [] {} () ! @ # $ % ^ & * - _ = + ; : , . / ? \" -ForegroundColor Gray
$in = Read-Host "Input"

if (-not $in) { $ok = $false }

Write-Host ""
if ($ok) {
  Write-Host "PASS: Input and prompt behaviour appear sane." -ForegroundColor Green
} else {
  Write-Host "FAIL: Input read was empty or abnormal." -ForegroundColor Red
}

exit 0
