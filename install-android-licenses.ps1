# Script to install Android SDK Command-line Tools and accept licenses
$ErrorActionPreference = "Stop"

$sdkPath = "$env:LOCALAPPDATA\Android\sdk"
$cmdlinePath = "$sdkPath\cmdline-tools"
$latestPath = "$cmdlinePath\latest"
$tempPath = "$env:TEMP"

Write-Host "Android SDK License Acceptance Script" -ForegroundColor Green
Write-Host "=====================================" -ForegroundColor Green
Write-Host ""

# Check if already installed
if (Test-Path "$latestPath\bin\sdkmanager.bat") {
    Write-Host "Command-line tools already installed at: $latestPath" -ForegroundColor Yellow
    Write-Host "Running license acceptance..." -ForegroundColor Yellow
    & "$latestPath\bin\sdkmanager.bat" --licenses
    exit 0
}

Write-Host "Command-line tools not found. Installing..." -ForegroundColor Yellow
Write-Host ""

# Create directories
if (-not (Test-Path $cmdlinePath)) {
    New-Item -ItemType Directory -Force -Path $cmdlinePath | Out-Null
}

# Download URL for command-line tools
$downloadUrl = "https://dl.google.com/android/repository/commandlinetools-win-11076708_latest.zip"
$zipFile = "$tempPath\commandlinetools-win.zip"

Write-Host "Downloading Android SDK Command-line Tools..." -ForegroundColor Cyan
Write-Host "This may take a few minutes..." -ForegroundColor Cyan
Write-Host ""

try {
    # Download with progress
    $ProgressPreference = 'Continue'
    Invoke-WebRequest -Uri $downloadUrl -OutFile $zipFile -UseBasicParsing
    
    Write-Host "Download complete!" -ForegroundColor Green
    Write-Host "Extracting..." -ForegroundColor Cyan
    
    # Extract to temp location first
    $extractPath = "$tempPath\cmdline-tools-extract"
    if (Test-Path $extractPath) {
        Remove-Item $extractPath -Recurse -Force
    }
    Expand-Archive -Path $zipFile -DestinationPath $extractPath -Force
    
    # Move to correct location
    if (Test-Path "$extractPath\cmdline-tools") {
        Move-Item "$extractPath\cmdline-tools\*" $latestPath -Force
        Remove-Item $extractPath -Recurse -Force
    } else {
        # If structure is different, move contents directly
        Get-ChildItem $extractPath | Move-Item -Destination $latestPath -Force
        Remove-Item $extractPath -Recurse -Force
    }
    
    Write-Host "Installation complete!" -ForegroundColor Green
    Write-Host ""
    
    # Accept licenses
    Write-Host "Accepting Android SDK licenses..." -ForegroundColor Cyan
    Write-Host "You will need to type 'y' for each license agreement." -ForegroundColor Yellow
    Write-Host ""
    
    & "$latestPath\bin\sdkmanager.bat" --licenses
    
    Write-Host ""
    Write-Host "License acceptance complete!" -ForegroundColor Green
    
    # Cleanup
    if (Test-Path $zipFile) {
        Remove-Item $zipFile -Force
    }
    
} catch {
    Write-Host ""
    Write-Host "Error occurred: $_" -ForegroundColor Red
    Write-Host ""
    Write-Host "Alternative solution:" -ForegroundColor Yellow
    Write-Host "1. Open Android Studio" -ForegroundColor White
    Write-Host "2. Go to Tools > SDK Manager" -ForegroundColor White
    Write-Host "3. Click on SDK Tools tab" -ForegroundColor White
    Write-Host "4. Check 'Android SDK Command-line Tools (latest)'" -ForegroundColor White
    Write-Host "5. Click Apply to install" -ForegroundColor White
    Write-Host "6. Then run: flutter doctor --android-licenses" -ForegroundColor White
    exit 1
}

