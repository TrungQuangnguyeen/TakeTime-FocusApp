# Build and Test Script for Infinite Loop Fix
# ==========================================

Write-Host "🔨 TakeTime Focus App - Build and Test Infinite Loop Fix" -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

# Set location
Set-Location "d:\DACS\TakeTime-FocusApp\Taketime-FocusApp"

Write-Host "📍 Current directory: $(Get-Location)" -ForegroundColor Yellow

# Check current APK
Write-Host "`n📦 Checking existing APK..." -ForegroundColor Green
$apkPath = "build\app\outputs\flutter-apk\app-debug.apk"
if (Test-Path $apkPath) {
    $apkInfo = Get-Item $apkPath
    Write-Host "✅ Found APK: $($apkInfo.Name)" -ForegroundColor Green
    Write-Host "   Size: $([math]::Round($apkInfo.Length / 1MB, 1)) MB" -ForegroundColor Yellow
    Write-Host "   Modified: $($apkInfo.LastWriteTime)" -ForegroundColor Yellow
} else {
    Write-Host "❌ No APK found" -ForegroundColor Red
}

# Build new APK
Write-Host "`n🔨 Building new APK with infinite loop fix..." -ForegroundColor Green
try {
    flutter build apk --debug
    Write-Host "✅ APK build completed!" -ForegroundColor Green
} catch {
    Write-Host "❌ APK build failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Check new APK
Write-Host "`n📦 Checking new APK..." -ForegroundColor Green
if (Test-Path $apkPath) {
    $newApkInfo = Get-Item $apkPath
    Write-Host "✅ New APK: $($newApkInfo.Name)" -ForegroundColor Green
    Write-Host "   Size: $([math]::Round($newApkInfo.Length / 1MB, 1)) MB" -ForegroundColor Yellow
    Write-Host "   Modified: $($newApkInfo.LastWriteTime)" -ForegroundColor Yellow
} else {
    Write-Host "❌ New APK not found" -ForegroundColor Red
    exit 1
}

Write-Host "`n✅ INFINITE LOOP FIX IMPLEMENTED" -ForegroundColor Green
Write-Host "=================================" -ForegroundColor Green
Write-Host "Changes made:" -ForegroundColor Cyan
Write-Host "1. ✅ Added tracking variables _appAlreadyBlocked and _lastLogTime" -ForegroundColor White
Write-Host "2. ✅ Modified _checkRunningApps() to prevent spam logs and repeated blocking" -ForegroundColor White
Write-Host "3. ✅ Only log every 30 seconds maximum" -ForegroundColor White
Write-Host "4. ✅ Only block each app once when limit exceeded" -ForegroundColor White
Write-Host "5. ✅ Reset tracking when blocking state changes" -ForegroundColor White

Write-Host "`n📱 NEXT STEPS:" -ForegroundColor Magenta
Write-Host "1. Install the new APK on Android device" -ForegroundColor White
Write-Host "2. Navigate to 'Blocked Apps' section" -ForegroundColor White
Write-Host "3. Check that 'App Lite has exceeded limit' logs no longer spam" -ForegroundColor White
Write-Host "4. Verify blocking still works for real target apps" -ForegroundColor White

Write-Host "`n🚀 Ready for device testing!" -ForegroundColor Green
