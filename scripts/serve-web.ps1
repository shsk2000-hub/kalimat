$ErrorActionPreference = "Stop"

$root = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
Set-Location $root

Write-Host "Building Flutter web..."
flutter build web --release

$publicDir = Join-Path $root "server\public"
if (Test-Path $publicDir) {
  Remove-Item $publicDir -Recurse -Force
}
Copy-Item (Join-Path $root "build\web") $publicDir -Recurse

Write-Host "Starting unified web + multiplayer server on http://localhost:3000"
Set-Location (Join-Path $root "server")
npm start
