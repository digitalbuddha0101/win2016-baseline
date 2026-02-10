# step-02-openssh.ps1
$ErrorActionPreference = "Stop"

Write-Host "=== STEP 02: Install + enable OpenSSH Server ===" -ForegroundColor Cyan

# Install capability if missing
$cap = Get-WindowsCapability -Online | Where-Object Name -like 'OpenSSH.Server*'
if (-not $cap) { throw "OpenSSH.Server capability not found on this OS image." }

if ($cap.State -ne "Installed") {
  Write-Host "Installing OpenSSH.Server..." -ForegroundColor Yellow
  Add-WindowsCapability -Online -Name $cap.Name | Out-Null
} else {
  Write-Host "OpenSSH.Server already installed." -ForegroundColor Green
}

# Ensure service exists
$svc = Get-Service -Name sshd -ErrorAction SilentlyContinue
if (-not $svc) { throw "sshd service not found after install." }

# Start + set automatic
Write-Host "Enabling sshd service..." -ForegroundColor Yellow
Set-Service -Name sshd -StartupType Automatic
Start-Service -Name sshd

# Optional: ssh-agent (not required, but harmless)
$agent = Get-Service -Name ssh-agent -ErrorAction SilentlyContinue
if ($agent) {
  Set-Service -Name ssh-agent -StartupType Manual
}

# Firewall rule (inbound TCP 22)
$rule = Get-NetFirewallRule -DisplayName "OpenSSH-Server-In-TCP" -ErrorAction SilentlyContinue
if (-not $rule) {
  Write-Host "Creating firewall rule for TCP/22..." -ForegroundColor Yellow
  New-NetFirewallRule -Name "OpenSSH-Server-In-TCP" `
    -DisplayName "OpenSSH-Server-In-TCP" `
    -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22 | Out-Null
} else {
  Write-Host "Firewall rule already present: OpenSSH-Server-In-TCP" -ForegroundColor Green
}

# Status report
Write-Host ""
Write-Host "sshd status:" -ForegroundColor Cyan
Get-Service sshd | Format-List Status, Name, StartType

Write-Host ""
Write-Host "Listening ports (expect :22)..." -ForegroundColor Cyan
netstat -ano | findstr ":22"

Write-Host ""
Write-Host "DONE: OpenSSH server installed and enabled." -ForegroundColor Green
exit 0
