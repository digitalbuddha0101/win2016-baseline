# step-02-openssh.ps1  (Windows Server 2016 compatible)
# Installs Win32-OpenSSH from the latest GitHub release, registers sshd, opens firewall.

$ErrorActionPreference = "Stop"

Write-Host "=== STEP 02: Install + enable OpenSSH Server (Win32-OpenSSH) ===" -ForegroundColor Cyan

# Server 2016 often needs TLS 1.2 for GitHub endpoints
try {
  [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
} catch {}

function Assert-Admin {
  $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()
    ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
  if (-not $isAdmin) { throw "Run PowerShell as Administrator." }
}

function Download-OpenSSHZip {
  $api = "https://api.github.com/repos/PowerShell/Win32-OpenSSH/releases/latest"
  Write-Host "Fetching latest release metadata..." -ForegroundColor Gray
  $rel = Invoke-RestMethod -Uri $api -UseBasicParsing

  $asset = $rel.assets | Where-Object { $_.name -match "OpenSSH-Win64\.zip$" } | Select-Object -First 1
  if (-not $asset) { throw "Could not find OpenSSH-Win64.zip in latest release assets." }

  $zipPath = Join-Path $env:TEMP $asset.name
  Write-Host ("Downloading {0} ..." -f $asset.name) -ForegroundColor Gray
  Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $zipPath -UseBasicParsing

  return $zipPath
}

Assert-Admin

$installDir = "C:\Program Files\OpenSSH"
$tempDir    = Join-Path $env:TEMP ("openssh_" + [Guid]::NewGuid().ToString("N"))
New-Item -ItemType Directory -Path $tempDir | Out-Null

if (Test-Path $installDir) {
  Write-Host "OpenSSH appears to already exist at: $installDir" -ForegroundColor Yellow
} else {
  $zip = Download-OpenSSHZip
  Expand-Archive -Path $zip -DestinationPath $tempDir -Force

  $extracted = Join-Path $tempDir "OpenSSH-Win64"
  if (-not (Test-Path $extracted)) { throw "Unexpected zip layout; OpenSSH-Win64 folder not found." }

  New-Item -ItemType Directory -Path $installDir | Out-Null
  Copy-Item -Path (Join-Path $extracted "*") -Destination $installDir -Recurse -Force
  Write-Host "Copied OpenSSH to $installDir" -ForegroundColor Green
}

# Install sshd service using the bundled script
$installScript = Join-Path $installDir "install-sshd.ps1"
if (-not (Test-Path $installScript)) { throw "Missing install script: $installScript" }

Write-Host "Registering sshd service..." -ForegroundColor Gray
powershell.exe -NoProfile -ExecutionPolicy Bypass -File $installScript

# Set services to start automatically and start them
foreach ($svc in @("sshd","ssh-agent")) {
  $s = Get-Service -Name $svc -ErrorAction SilentlyContinue
  if ($s) {
    Set-Service -Name $svc -StartupType Automatic
    if ($s.Status -ne "Running") { Start-Service -Name $svc }
  }
}

# Firewall rule for TCP 22
$ruleName = "OpenSSH-Server-In-TCP"
$rule = Get-NetFirewallRule -DisplayName $ruleName -ErrorAction SilentlyContinue
if (-not $rule) {
  Write-Host "Creating firewall rule for TCP 22..." -ForegroundColor Gray
  New-NetFirewallRule -Name "sshd" -DisplayName $ruleName -Enabled True -Direction Inbound `
    -Protocol TCP -Action Allow -LocalPort 22 | Out-Null
}

# Verify sshd is listening
Write-Host "Verifying listener on TCP 22..." -ForegroundColor Gray
$listen = netstat -ano | Select-String ":22" | Select-String "LISTENING"
if (-not $listen) {
  Write-Host "WARN: sshd not seen listening on :22 yet. Check service/logs." -ForegroundColor Yellow
} else {
  Write-Host "PASS: sshd appears to be listening on TCP 22." -ForegroundColor Green
}

Write-Host "SSHD status:" -ForegroundColor Cyan
Get-Service sshd | Format-Table -AutoSize

Write-Host "Done." -ForegroundColor Green
