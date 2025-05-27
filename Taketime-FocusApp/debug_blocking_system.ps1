#!/usr/bin/env pwsh

# Debug App Blocking System
# This script helps debug why app blocking is not working

Write-Host "=== Debug App Blocking System ===" -ForegroundColor Green

# Check if Flutter is available
Write-Host "Checking Flutter..." -ForegroundColor Yellow
if (!(Get-Command flutter -ErrorAction SilentlyContinue)) {
    Write-Host "Error: Flutter is not installed or not in PATH" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "=== PHASE 1: Build and Install App ===" -ForegroundColor Cyan

# Clean and build
Write-Host "Cleaning project..." -ForegroundColor Yellow
flutter clean

Write-Host "Getting dependencies..." -ForegroundColor Yellow
flutter pub get

Write-Host "Building debug APK..." -ForegroundColor Yellow
flutter build apk --debug
if ($LASTEXITCODE -ne 0) {
    Write-Host "Error: Failed to build the app" -ForegroundColor Red
    exit 1
}

Write-Host "Installing app..." -ForegroundColor Yellow
flutter install
if ($LASTEXITCODE -ne 0) {
    Write-Host "Error: Failed to install the app" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "=== PHASE 2: Check System Requirements ===" -ForegroundColor Cyan

Write-Host "App installed successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "CRITICAL DEBUGGING STEPS:" -ForegroundColor Red
Write-Host ""

Write-Host "1. CHECK PERMISSIONS (Manual Steps Required):" -ForegroundColor Yellow
Write-Host "   ✓ Open the TakeTime app" -ForegroundColor White
Write-Host "   ✓ Go to Blocked Apps screen" -ForegroundColor White
Write-Host "   ✓ Try to enable blocking for any app" -ForegroundColor White
Write-Host "   ✓ The app should guide you through permission setup:" -ForegroundColor White
Write-Host "     - Usage Stats permission" -ForegroundColor Gray
Write-Host "     - Accessibility Service permission" -ForegroundColor Gray
Write-Host "     - System Alert Window permission" -ForegroundColor Gray
Write-Host ""

Write-Host "2. VERIFY SERVICE STATUS:" -ForegroundColor Yellow
Write-Host "   ✓ After granting permissions, check if service is running" -ForegroundColor White
Write-Host "   ✓ You should see 'TakeTime App Blocking' in Accessibility Services" -ForegroundColor White
Write-Host ""

Write-Host "3. TEST BLOCKING:" -ForegroundColor Yellow
Write-Host "   ✓ Set a very low time limit (1 minute) for a test app" -ForegroundColor White
Write-Host "   ✓ Enable blocking for that app" -ForegroundColor White
Write-Host "   ✓ Use the app for more than 1 minute" -ForegroundColor White
Write-Host "   ✓ The app should be blocked with a red screen" -ForegroundColor White
Write-Host ""

Write-Host "4. DEBUG LOGS:" -ForegroundColor Yellow
Write-Host "   ✓ Keep this terminal open and run:" -ForegroundColor White
Write-Host "     adb logcat | findstr AppBlockingService" -ForegroundColor Gray
Write-Host "   ✓ This will show debug logs from the blocking service" -ForegroundColor White
Write-Host ""

Write-Host "=== PHASE 3: Start Debug Logging ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "Starting ADB logcat to monitor app blocking..." -ForegroundColor Yellow
Write-Host "Look for logs with 'AppBlockingService' tag" -ForegroundColor White
Write-Host "Press Ctrl+C to stop logging" -ForegroundColor Gray
Write-Host ""

# Start logcat with filtering
try {
    adb logcat | Select-String "AppBlockingService|TakeTime|DEBUG"
} catch {
    Write-Host "Error: ADB not found or device not connected" -ForegroundColor Red
    Write-Host "Make sure Android device is connected and ADB is in PATH" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "=== COMMON ISSUES AND SOLUTIONS ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "ISSUE 1: No blocking happens" -ForegroundColor Red
Write-Host "SOLUTION:" -ForegroundColor Green
Write-Host "  ✓ Check all 3 permissions are granted" -ForegroundColor White
Write-Host "  ✓ Accessibility Service must be ON" -ForegroundColor White
Write-Host "  ✓ App must have Usage Stats permission" -ForegroundColor White
Write-Host "  ✓ System Alert Window permission must be ON" -ForegroundColor White
Write-Host ""

Write-Host "ISSUE 2: App detects time limit but doesn't block" -ForegroundColor Red
Write-Host "SOLUTION:" -ForegroundColor Green
Write-Host "  ✓ Check if AppBlockedActivity is working" -ForegroundColor White
Write-Host "  ✓ Ensure System Alert Window permission is granted" -ForegroundColor White
Write-Host "  ✓ Try restarting the app after granting permissions" -ForegroundColor White
Write-Host ""

Write-Host "ISSUE 3: Service not starting" -ForegroundColor Red
Write-Host "SOLUTION:" -ForegroundColor Green
Write-Host "  ✓ Go to Settings > Accessibility > TakeTime App Blocking" -ForegroundColor White
Write-Host "  ✓ Turn OFF then ON the accessibility service" -ForegroundColor White
Write-Host "  ✓ Restart the TakeTime app" -ForegroundColor White
Write-Host ""

Write-Host "=== DEBUG COMPLETE ===" -ForegroundColor Green
