# step-03-ssh-loopback.ps1
$ErrorActionPreference = "Stop"

Write-Host "=== STEP 03: SSH loopback test ===" -ForegroundColor Cyan

$svc = Get-Service sshd -ErrorAction Stop
if ($svc.Status -ne "Running") { throw "sshd is not running. Start-Service sshd" }

Write-Host "Testing SSH to localhost..." -ForegroundColor Gray
Write-Host "You should be prompted for password." -ForegroundColor Gray

ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=NUL Administrator@localhost "whoami && hostname"

Write-Host "PASS: SSH loopback command executed." -ForegroundColor Green
