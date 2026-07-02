param(
  [Parameter(Mandatory = $true)]
  [string]$ApiBaseUrl
)

$ErrorActionPreference = "Stop"
$root = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
Set-Location $root

if (-not $ApiBaseUrl.StartsWith("http")) {
  throw "ApiBaseUrl must start with http:// or https://"
}

Write-Host "Building Flutter web for API: $ApiBaseUrl"
flutter build web --release --dart-define=API_BASE_URL=$ApiBaseUrl

Write-Host "Deploying to Firebase Hosting..."
firebase deploy --only hosting
