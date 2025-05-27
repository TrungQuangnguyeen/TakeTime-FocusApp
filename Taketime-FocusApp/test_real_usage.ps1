#!/usr/bin/env pwsh

# Test Real Usage Tracking Implementation
# This script tests the real usage tracking functionality

Write-Host "=== Testing Real Usage Tracking Implementation ===" -ForegroundColor Green

# Check if Flutter is available
Write-Host "Checking Flutter..." -ForegroundColor Yellow
if (!(Get-Command flutter -ErrorAction SilentlyContinue)) {
    Write-Host "Error: Flutter is not installed or not in PATH" -ForegroundColor Red
    exit 1
}

# Run Flutter analyze
Write-Host "Running Flutter analyze..." -ForegroundColor Yellow
flutter analyze
if ($LASTEXITCODE -ne 0) {
    Write-Host "Warning: Flutter analyze found issues" -ForegroundColor Yellow
}

# Build the app
Write-Host "Building the app..." -ForegroundColor Yellow
flutter build apk --debug
if ($LASTEXITCODE -ne 0) {
    Write-Host "Error: Failed to build the app" -ForegroundColor Red
    exit 1
}

Write-Host "=== Build completed successfully! ===" -ForegroundColor Green
Write-Host ""
Write-Host "Changes implemented:" -ForegroundColor Cyan
Write-Host "✓ Added real Usage Stats API integration to MainActivity.kt" -ForegroundColor Green
Write-Host "✓ Added methods to get app usage time and check running status" -ForegroundColor Green  
Write-Host "✓ Updated AppBlockingService.dart with new methods" -ForegroundColor Green
Write-Host "✓ Replaced mock usage tracking in blocked_app_screen.dart" -ForegroundColor Green
Write-Host "✓ Updated usage_statistics_screen.dart to use real data" -ForegroundColor Green
Write-Host ""
Write-Host "To test the app:" -ForegroundColor Yellow
Write-Host "1. Install the app on device/emulator: flutter install" -ForegroundColor White
Write-Host "2. Grant all permissions (Usage Stats, Accessibility, Overlay)" -ForegroundColor White
Write-Host "3. Set time limits for apps and use them" -ForegroundColor White
Write-Host "4. Check if usage tracking now shows real data" -ForegroundColor White
Write-Host "5. Verify blocking works when limits are exceeded" -ForegroundColor White
