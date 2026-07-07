# The Peyton Files — "play anywhere" launcher.
# Starts the local game server AND a Cloudflare tunnel, then prints the public link.
# Double-click PLAY-PEYTON-PHONE.bat (which runs this). Keep this window open while you play.

$root = 'C:\Users\pschl\peyton-files'
$port = 8078
$node = 'C:\Users\pschl\nodejs\node.exe'
$cf   = Join-Path $root 'tools\cloudflared.exe'

Write-Host ''
Write-Host '  THE PEYTON FILES - starting your private link...' -ForegroundColor Yellow
Write-Host ''

# 1. Start the local static server (if nothing is already listening on 8078)
$listening = Get-NetTCPConnection -LocalPort $port -State Listen -ErrorAction SilentlyContinue
if (-not $listening) {
  Start-Process -FilePath $node -ArgumentList (Join-Path $root 'server.js') -WorkingDirectory $root -WindowStyle Minimized
  Start-Sleep -Seconds 2
  Write-Host ('  Game server running on http://localhost:{0}' -f $port) -ForegroundColor Green
} else {
  Write-Host ('  Game server already running on port {0}' -f $port) -ForegroundColor Green
}

# 2. Start the Cloudflare tunnel and capture the public URL
$log = Join-Path $root 'tools\tunnel.log'
if (Test-Path $log) { Remove-Item $log -Force }
Start-Process -FilePath $cf -ArgumentList @('tunnel','--url',("http://localhost:{0}" -f $port),'--no-autoupdate') `
  -WorkingDirectory $root -WindowStyle Minimized -RedirectStandardError $log -RedirectStandardOutput ($log + '.out')

Write-Host '  Opening secure tunnel (about 10 seconds)...' -ForegroundColor Gray
$url = $null
for ($i = 0; $i -lt 30; $i++) {
  Start-Sleep -Seconds 1
  if (Test-Path $log) {
    $m = Select-String -Path $log -Pattern 'https://[a-z0-9-]+\.trycloudflare\.com' -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($m) { $url = $m.Matches[0].Value; break }
  }
}

Write-Host ''
if ($url) {
  Write-Host '  ================================================================' -ForegroundColor Cyan
  Write-Host '   OPEN THIS ON YOUR PHONE:' -ForegroundColor Cyan
  Write-Host ('   {0}' -f $url) -ForegroundColor White
  Write-Host '  ================================================================' -ForegroundColor Cyan
  Set-Content -Path (Join-Path $root 'CURRENT-PHONE-LINK.txt') -Value $url -Encoding UTF8
  Write-Host ''
  Write-Host '  (Also saved to CURRENT-PHONE-LINK.txt)' -ForegroundColor Gray
} else {
  Write-Host '  Could not read the tunnel link. See tools\tunnel.log' -ForegroundColor Red
}
Write-Host ''
Write-Host '  KEEP THIS WINDOW OPEN while you play. Close it to stop the link.' -ForegroundColor Yellow
Write-Host '  Press Enter to stop everything and exit...'
[void][System.Console]::ReadLine()

# Cleanup: stop the tunnel (and the server we started)
Get-Process cloudflared -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
Write-Host '  Stopped. Bye.' -ForegroundColor Gray
