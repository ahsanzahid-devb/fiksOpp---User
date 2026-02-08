# Script to automatically accept all Android SDK licenses
$sdkmanagerPath = "$env:LOCALAPPDATA\Android\sdk\cmdline-tools\latest\bin\sdkmanager.bat"

if (-not (Test-Path $sdkmanagerPath)) {
    Write-Host "Error: sdkmanager.bat not found!" -ForegroundColor Red
    Write-Host "Please install Android SDK Command-line Tools first." -ForegroundColor Yellow
    exit 1
}

Write-Host "Accepting all Android SDK licenses..." -ForegroundColor Cyan
Write-Host ""

# Accept all licenses by piping 'y' responses
$yes = "y" * 20  # Create a string with multiple 'y' responses
$yes | & $sdkmanagerPath --licenses

Write-Host ""
Write-Host "License acceptance complete!" -ForegroundColor Green

