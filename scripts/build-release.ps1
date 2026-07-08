# Improvy Release Build Script (Windows)
# Builds iOS (IPA) and Android (AAB) for store submission

$ErrorActionPreference = "Stop"

Write-Host "🚀 Improvy Release Build" -ForegroundColor Green
Write-Host "========================" -ForegroundColor Green
Write-Host ""

# Get version from pubspec.yaml
$version = (Select-String -Path "pubspec.yaml" -Pattern "^version:" | ForEach-Object { $_.Line -split ":" | Select-Object -Last 1 }).Trim()

# Build date
$buildDate = Get-Date -Format "yyyyMMdd"

Write-Host "Version: $version" -ForegroundColor Yellow
Write-Host "Build: $buildDate" -ForegroundColor Yellow
Write-Host ""

# Step 1: Clean
Write-Host "[1/5] Cleaning build directories..." -ForegroundColor Green
flutter clean
Remove-Item -Recurse -Force -ErrorAction SilentlyContinue build
Remove-Item -Recurse -Force -ErrorAction SilentlyContinue ios\build
Remove-Item -Recurse -Force -ErrorAction SilentlyContinue android\.gradle

# Step 2: Get dependencies
Write-Host "[2/5] Getting dependencies..." -ForegroundColor Green
flutter pub get

# Step 3: Build iOS
Write-Host "[3/5] Building iOS (release)..." -ForegroundColor Green
flutter build ios --release --no-codesign

Write-Host ""
Write-Host "✅ iOS build complete!" -ForegroundColor Green
Write-Host "Location: build\ios\iphoneos\Runner.app"
Write-Host "Next: Archive in Xcode and upload to TestFlight"
Write-Host ""

# Step 4: Build Android
Write-Host "[4/5] Building Android App Bundle (release)..." -ForegroundColor Green
flutter build appbundle --release

Write-Host ""
Write-Host "✅ Android App Bundle complete!" -ForegroundColor Green
Write-Host "Location: build\app\outputs\bundle\release\app-release.aab"
Write-Host "Next: Upload to Play Console"
Write-Host ""

# Step 5: Summary
Write-Host "[5/5] Build Summary" -ForegroundColor Green
Write-Host "==================" -ForegroundColor Green
Write-Host ""

$aabPath = "build\app\outputs\bundle\release\app-release.aab"
if (Test-Path $aabPath) {
    $aabSize = (Get-Item $aabPath).Length / 1MB
    Write-Host "✓ Android AAB: $([Math]::Round($aabSize, 2)) MB" -ForegroundColor Green
    Write-Host "  → Upload to: play.google.com/console"
} else {
    Write-Host "✗ Android AAB not found" -ForegroundColor Red
}

Write-Host ""
Write-Host "✅ Build completed successfully!" -ForegroundColor Green
Write-Host ""

Write-Host "NEXT STEPS:" -ForegroundColor Yellow
Write-Host ""
Write-Host "iOS (TestFlight):"
Write-Host "  1. Open ios\Runner.xcworkspace in Xcode"
Write-Host "  2. Product → Archive"
Write-Host "  3. Distribute to TestFlight"
Write-Host "  4. Internal testing (verify no crashes, RevenueCat works)"
Write-Host ""
Write-Host "Android (Play Console):"
Write-Host "  1. Go to play.google.com/console"
Write-Host "  2. Select Improvy app"
Write-Host "  3. Release → Internal testing"
Write-Host "  4. Upload AAB: build\app\outputs\bundle\release\app-release.aab"
Write-Host "  5. Review and submit"
Write-Host ""
Write-Host "Documentation: See COMPLETION_PLAN.md" -ForegroundColor Cyan
Write-Host ""
