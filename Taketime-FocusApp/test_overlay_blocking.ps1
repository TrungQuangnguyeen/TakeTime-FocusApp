# Test script for overlay blocking functionality
Write-Host "=== TESTING OVERLAY BLOCKING SYSTEM ===" -ForegroundColor Cyan

Write-Host "`nStep 1: Installing the app with overlay blocking..." -ForegroundColor Yellow
flutter install

Write-Host "`nStep 2: Checking ADB logs for overlay blocking..." -ForegroundColor Yellow
Write-Host "Monitoring logs for OverlayBlockingService and overlay creation..." -ForegroundColor Green
Write-Host "Press Ctrl+C to stop monitoring" -ForegroundColor Gray

# Filter logs for our overlay blocking functionality
adb logcat -v time | Select-String -Pattern "(OverlayBlockingService|Overlay|DEBUG BLOCK|DEBUG EVENT)"
