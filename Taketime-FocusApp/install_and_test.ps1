# TakeTime Focus App - Installation and Testing Script (Windows PowerShell)
# This script helps you install and test the app blocking functionality

Write-Host "🎯 TakeTime Focus App - App Blocking Testing" -ForegroundColor Cyan
Write-Host "==============================================`n" -ForegroundColor Cyan

# Check if ADB is available
$adbPath = Get-Command adb -ErrorAction SilentlyContinue
if (-not $adbPath) {
    Write-Host "❌ ADB not found. Please install Android SDK Platform Tools." -ForegroundColor Red
    Write-Host "   Download from: https://developer.android.com/studio/releases/platform-tools" -ForegroundColor Yellow
    exit 1
}

Write-Host "✅ ADB found at: $($adbPath.Source)" -ForegroundColor Green

# Check if device is connected
$devices = adb devices | Where-Object { $_ -match "device$" }
if ($devices.Count -eq 0) {
    Write-Host "❌ No Android device connected. Please:" -ForegroundColor Red
    Write-Host "   1. Connect your Android device via USB" -ForegroundColor Yellow
    Write-Host "   2. Enable USB debugging in Developer Options" -ForegroundColor Yellow
    Write-Host "   3. Accept USB debugging prompt on device" -ForegroundColor Yellow
    exit 1
}

Write-Host "✅ Found $($devices.Count) connected device(s)" -ForegroundColor Green

# Check if APK exists
$apkPath = "build\app\outputs\flutter-apk\app-debug.apk"
if (-not (Test-Path $apkPath)) {
    Write-Host "❌ APK not found at $apkPath" -ForegroundColor Red
    Write-Host "   Building APK now..." -ForegroundColor Yellow
    flutter build apk --debug
    
    if (-not (Test-Path $apkPath)) {
        Write-Host "❌ Failed to build APK" -ForegroundColor Red
        exit 1
    }
}

Write-Host "✅ APK found at $apkPath" -ForegroundColor Green

# Get APK size
$apkSize = [math]::Round((Get-Item $apkPath).Length / 1MB, 2)
Write-Host "📦 APK size: $apkSize MB" -ForegroundColor Blue

# Install APK
Write-Host "`n📱 Installing APK..." -ForegroundColor Cyan
$installResult = adb install -r $apkPath

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ APK installed successfully" -ForegroundColor Green
} else {
    Write-Host "❌ Failed to install APK" -ForegroundColor Red
    Write-Host "   Try: adb uninstall com.example.smartmanagementapp" -ForegroundColor Yellow
    exit 1
}

# Launch app
Write-Host "`n🚀 Launching TakeTime app..." -ForegroundColor Cyan
adb shell am start -n com.example.smartmanagementapp/.MainActivity

Start-Sleep -Seconds 2

Write-Host "`n📋 Testing Checklist:" -ForegroundColor Yellow
Write-Host "=====================" -ForegroundColor Yellow
Write-Host "1. ✓ Navigate to 'Blocked Apps' section" -ForegroundColor White
Write-Host "2. ✓ Set up permissions (Usage Stats, Overlay, Accessibility)" -ForegroundColor White
Write-Host "3. ✓ Add test apps with short time limits (1-2 minutes)" -ForegroundColor White
Write-Host "4. ✓ Use test apps until blocked" -ForegroundColor White
Write-Host "5. ✓ Verify blocking overlay appears" -ForegroundColor White
Write-Host "6. ✓ Test 'Go Home' and 'Settings' buttons" -ForegroundColor White

Write-Host "`n📊 Monitoring Commands:" -ForegroundColor Yellow
Write-Host "=======================" -ForegroundColor Yellow
Write-Host "# Monitor app blocking logs:" -ForegroundColor Cyan
Write-Host "adb logcat | Select-String 'AppBlocking'" -ForegroundColor Gray
Write-Host "`n# Monitor Flutter logs:" -ForegroundColor Cyan
Write-Host "adb logcat | Select-String 'flutter'" -ForegroundColor Gray
Write-Host "`n# Check service status:" -ForegroundColor Cyan
Write-Host "adb shell dumpsys activity services | Select-String 'AppBlocking'" -ForegroundColor Gray

Write-Host "`n🔧 Troubleshooting:" -ForegroundColor Yellow
Write-Host "==================" -ForegroundColor Yellow
Write-Host "If blocking doesn't work:" -ForegroundColor White
Write-Host "- Ensure all permissions are granted" -ForegroundColor Gray
Write-Host "- Restart accessibility service in Settings" -ForegroundColor Gray
Write-Host "- Check that TakeTime appears in Accessibility services" -ForegroundColor Gray
Write-Host "- Verify 'Display over other apps' permission" -ForegroundColor Gray

Write-Host "`n🎉 Happy testing!" -ForegroundColor Green

# Offer to start monitoring
Write-Host "`nWould you like to start monitoring logs? (Y/N): " -ForegroundColor Cyan -NoNewline
$response = Read-Host
if ($response -eq 'Y' -or $response -eq 'y') {
    Write-Host "`n📡 Starting log monitoring... (Press Ctrl+C to stop)" -ForegroundColor Blue
    adb logcat | Select-String "AppBlocking|flutter|TakeTime"
}
