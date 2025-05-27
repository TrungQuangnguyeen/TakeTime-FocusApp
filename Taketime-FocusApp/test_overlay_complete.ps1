# =================================================================
# OVERLAY BLOCKING SYSTEM - LIVE TESTING SCRIPT
# =================================================================

Write-Host "=== TESTING OVERLAY BLOCKING FUNCTIONALITY ===" -ForegroundColor Cyan
Write-Host "Date: $(Get-Date)" -ForegroundColor Gray

# Function to check if app is installed
function Test-AppInstalled {
    Write-Host "`n🔍 Checking if TakeTime app is installed..." -ForegroundColor Yellow
    try {
        $result = flutter devices 2>&1
        if ($result -match "emulator|device") {
            Write-Host "✅ Device detected" -ForegroundColor Green
            return $true
        } else {
            Write-Host "❌ No device detected" -ForegroundColor Red
            return $false
        }
    } catch {
        Write-Host "❌ Error checking devices: $_" -ForegroundColor Red
        return $false
    }
}

# Function to install app
function Install-App {
    Write-Host "`n📱 Installing latest version of TakeTime app..." -ForegroundColor Yellow
    try {
        flutter install
        Write-Host "✅ App installed successfully" -ForegroundColor Green
        return $true
    } catch {
        Write-Host "❌ Error installing app: $_" -ForegroundColor Red
        return $false
    }
}

# Function to show testing instructions
function Show-TestingInstructions {
    Write-Host "`n📋 MANUAL TESTING INSTRUCTIONS" -ForegroundColor Cyan
    Write-Host "================================" -ForegroundColor Cyan
    
    Write-Host "`n1️⃣ SETUP TEST APP:" -ForegroundColor Yellow
    Write-Host "   • Open TakeTime app on your device"
    Write-Host "   • Go to 'Ứng dụng bị chặn' (Blocked Apps) section"
    Write-Host "   • Add a test app (Facebook, Instagram, Chrome, etc.)"
    Write-Host "   • Set time limit to 1 minute"
    Write-Host "   • Enable blocking for that app"
    
    Write-Host "`n2️⃣ TRIGGER TIME LIMIT:" -ForegroundColor Yellow
    Write-Host "   • Use the test app for more than 1 minute"
    Write-Host "   • OR manually add usage time in TakeTime settings"
    Write-Host "   • Wait for usage to exceed the limit"
    
    Write-Host "`n3️⃣ TEST OVERLAY BLOCKING:" -ForegroundColor Yellow
    Write-Host "   • Try to open the blocked app"
    Write-Host "   • EXPECTED: Full-screen overlay should appear"
    Write-Host "   • Should show Vietnamese message about time limit"
    Write-Host "   • Should have 'Thoát ứng dụng' button"
    
    Write-Host "`n4️⃣ TEST EXIT FUNCTIONALITY:" -ForegroundColor Yellow
    Write-Host "   • Tap the 'Thoát ứng dụng' button"
    Write-Host "   • EXPECTED: App should close and return to home"
    
    Write-Host "`n🔍 WHAT TO LOOK FOR:" -ForegroundColor Cyan
    Write-Host "   ✅ App opens briefly then overlay covers it completely"
    Write-Host "   ✅ Overlay shows: 'Ứng dụng này đã được sử dụng vượt quá thời gian...'"
    Write-Host "   ✅ Red 'Thoát ứng dụng' button is visible and clickable"
    Write-Host "   ✅ Tapping button closes app and returns to home screen"
    Write-Host "   ✅ Cannot access app underneath the overlay"
}

# Function to check permissions
function Check-Permissions {
    Write-Host "`n🔐 PERMISSION CHECKLIST:" -ForegroundColor Cyan
    Write-Host "Please verify these permissions are granted:"
    Write-Host "   1. Accessibility Service: Settings > Accessibility > TakeTime > ON"
    Write-Host "   2. Display over apps: Settings > Apps > TakeTime > Display over other apps > Allow"
    Write-Host "   3. Usage access: Settings > Apps > Special access > Usage access > TakeTime > ON"
    
    $response = Read-Host "`nHave you verified all permissions are granted? (y/n)"
    return $response -eq 'y' -or $response -eq 'Y'
}

# Function to monitor logs (using Flutter instead of ADB)
function Start-LogMonitoring {
    Write-Host "`n📊 Starting log monitoring..." -ForegroundColor Yellow
    Write-Host "This will show overlay blocking activity in real-time" -ForegroundColor Gray
    Write-Host "Press Ctrl+C to stop monitoring" -ForegroundColor Gray
    
    try {
        flutter logs | Select-String -Pattern "(OverlayBlockingService|DEBUG BLOCK|DEBUG EVENT|Overlay|blocked_package)"
    } catch {
        Write-Host "❌ Error starting log monitoring: $_" -ForegroundColor Red
        Write-Host "You can test manually without log monitoring" -ForegroundColor Yellow
    }
}

# Main execution
Write-Host "`n🚀 Starting overlay blocking test sequence..." -ForegroundColor Green

# Step 1: Check device
if (-not (Test-AppInstalled)) {
    Write-Host "❌ Please connect your Android device or start emulator first" -ForegroundColor Red
    exit 1
}

# Step 2: Install app
if (-not (Install-App)) {
    Write-Host "❌ Failed to install app. Please check for errors above." -ForegroundColor Red
    exit 1
}

# Step 3: Check permissions
if (-not (Check-Permissions)) {
    Write-Host "❌ Please grant all required permissions before testing" -ForegroundColor Red
    Write-Host "Refer to OVERLAY_TESTING_GUIDE.md for detailed permission setup" -ForegroundColor Yellow
    exit 1
}

# Step 4: Show testing instructions
Show-TestingInstructions

# Step 5: Start monitoring
Write-Host "`n🔄 Ready to start testing!" -ForegroundColor Green
$startMonitoring = Read-Host "Start log monitoring? (y/n)"

if ($startMonitoring -eq 'y' -or $startMonitoring -eq 'Y') {
    Start-LogMonitoring
} else {
    Write-Host "`n✨ Testing setup complete!" -ForegroundColor Green
    Write-Host "Follow the manual testing instructions above" -ForegroundColor Yellow
    Write-Host "Check OVERLAY_TESTING_GUIDE.md for troubleshooting" -ForegroundColor Gray
}

Write-Host "`n📝 TROUBLESHOOTING TIPS:" -ForegroundColor Cyan
Write-Host "   • If overlay doesn't appear: Check 'Display over other apps' permission"
Write-Host "   • If app not detected: Check Accessibility Service is enabled"
Write-Host "   • If time limits not working: Verify app is in blocked list"
Write-Host "   • For detailed help: See OVERLAY_TESTING_GUIDE.md"
