# App Blocking Implementation Verification Script
# Checks all components are properly implemented

Write-Host "🔍 TakeTime App Blocking - Implementation Verification" -ForegroundColor Cyan
Write-Host "==================================================`n" -ForegroundColor Cyan

$allChecks = @()

# Check APK exists and size
$apkPath = "build\app\outputs\flutter-apk\app-debug.apk"
if (Test-Path $apkPath) {
    $apkSize = [math]::Round((Get-Item $apkPath).Length / 1MB, 1)
    Write-Host "✅ APK Build: $apkSize MB ($(Get-Item $apkPath | Select-Object -ExpandProperty LastWriteTime))" -ForegroundColor Green
    $allChecks += $true
} else {
    Write-Host "❌ APK not found - Run: flutter build apk --debug" -ForegroundColor Red
    $allChecks += $false
}

# Check Android native files
$androidFiles = @(
    @{Path="android\app\src\main\kotlin\com\example\smartmanagementapp\MainActivity.kt"; Name="MainActivity (Method Channels)"},
    @{Path="android\app\src\main\kotlin\com\example\smartmanagementapp\AppBlockingService.kt"; Name="Accessibility Service"},
    @{Path="android\app\src\main\kotlin\com\example\smartmanagementapp\AppBlockedActivity.kt"; Name="Blocking Overlay"},
    @{Path="android\app\src\main\AndroidManifest.xml"; Name="Android Manifest"},
    @{Path="android\app\src\main\res\xml\accessibility_service_config.xml"; Name="Service Config"},
    @{Path="android\app\src\main\res\values\strings.xml"; Name="String Resources"}
)

Write-Host "`n📱 Android Native Components:" -ForegroundColor Yellow
foreach ($file in $androidFiles) {
    if (Test-Path $file.Path) {
        $size = [math]::Round((Get-Item $file.Path).Length / 1KB, 1)
        Write-Host "  ✅ $($file.Name): ${size}KB" -ForegroundColor Green
        $allChecks += $true
    } else {
        Write-Host "  ❌ $($file.Name): Missing" -ForegroundColor Red
        $allChecks += $false
    }
}

# Check Flutter files
$flutterFiles = @(
    @{Path="lib\services\app_blocking_service.dart"; Name="Flutter Service Bridge"},
    @{Path="lib\screens\blocked_apps\blocked_app_screen.dart"; Name="Enhanced UI Screen"}
)

Write-Host "`n🎯 Flutter Components:" -ForegroundColor Yellow
foreach ($file in $flutterFiles) {
    if (Test-Path $file.Path) {
        $size = [math]::Round((Get-Item $file.Path).Length / 1KB, 1)
        Write-Host "  ✅ $($file.Name): ${size}KB" -ForegroundColor Green
        $allChecks += $true
    } else {
        Write-Host "  ❌ $($file.Name): Missing" -ForegroundColor Red
        $allChecks += $false
    }
}

# Check documentation
$docFiles = @(
    "APP_BLOCKING_SETUP.md",
    "APP_BLOCKING_SUMMARY.md", 
    "TESTING_GUIDE.md",
    "COMPLETE_SETUP_GUIDE.md"
)

Write-Host "`n📚 Documentation:" -ForegroundColor Yellow
foreach ($file in $docFiles) {
    if (Test-Path $file) {
        $size = [math]::Round((Get-Item $file).Length / 1KB, 1)
        Write-Host "  ✅ ${file}: ${size}KB" -ForegroundColor Green
        $allChecks += $true
    } else {
        Write-Host "  ❌ ${file}: Missing" -ForegroundColor Red
        $allChecks += $false
    }
}

# Verify key permissions in AndroidManifest.xml
Write-Host "`n🔐 Permission Verification:" -ForegroundColor Yellow
$manifestContent = Get-Content "android\app\src\main\AndroidManifest.xml" -Raw
$requiredPermissions = @(
    "android.permission.PACKAGE_USAGE_STATS",
    "android.permission.SYSTEM_ALERT_WINDOW", 
    "android.permission.BIND_ACCESSIBILITY_SERVICE"
)

foreach ($permission in $requiredPermissions) {
    if ($manifestContent -match $permission) {
        Write-Host "  ✅ $permission" -ForegroundColor Green
        $allChecks += $true
    } else {
        Write-Host "  ❌ $permission: Missing" -ForegroundColor Red
        $allChecks += $false
    }
}

# Check if service is declared in manifest
if ($manifestContent -match "AppBlockingService") {
    Write-Host "  ✅ AppBlockingService declared" -ForegroundColor Green
    $allChecks += $true
} else {
    Write-Host "  ❌ AppBlockingService: Not declared" -ForegroundColor Red
    $allChecks += $false
}

if ($manifestContent -match "AppBlockedActivity") {
    Write-Host "  ✅ AppBlockedActivity declared" -ForegroundColor Green
    $allChecks += $true
} else {
    Write-Host "  ❌ AppBlockedActivity: Not declared" -ForegroundColor Red
    $allChecks += $false
}

# Summary
$passedChecks = ($allChecks | Where-Object {$_ -eq $true}).Count
$totalChecks = $allChecks.Count
$successRate = [math]::Round(($passedChecks / $totalChecks) * 100, 1)

Write-Host "`n📊 Implementation Status:" -ForegroundColor Cyan
Write-Host "=========================" -ForegroundColor Cyan
Write-Host "Passed: $passedChecks/$totalChecks ($successRate%)" -ForegroundColor $(if($successRate -ge 90) {"Green"} elseif($successRate -ge 70) {"Yellow"} else {"Red"})

if ($successRate -eq 100) {
    Write-Host "`n🎉 Perfect! All components implemented correctly." -ForegroundColor Green
    Write-Host "📱 Ready for device testing with ADB." -ForegroundColor Green
} elseif ($successRate -ge 90) {
    Write-Host "`n✅ Excellent! Implementation is nearly complete." -ForegroundColor Green
    Write-Host "🔧 Fix any missing components before testing." -ForegroundColor Yellow
} elseif ($successRate -ge 70) {
    Write-Host "`n⚠️ Good progress, but some components are missing." -ForegroundColor Yellow
    Write-Host "🔧 Review and fix missing files before testing." -ForegroundColor Yellow
} else {
    Write-Host "`n❌ Implementation incomplete." -ForegroundColor Red
    Write-Host "🔧 Several critical components are missing." -ForegroundColor Red
}

Write-Host "`n🚀 Next Steps:" -ForegroundColor Cyan
Write-Host "1. Install ADB (Android SDK Platform Tools)" -ForegroundColor White
Write-Host "2. Connect Android device with USB debugging" -ForegroundColor White
Write-Host "3. Run: flutter build apk --debug (if APK is old)" -ForegroundColor White
Write-Host "4. Install APK: adb install -r build\app\outputs\flutter-apk\app-debug.apk" -ForegroundColor White
Write-Host "5. Test app blocking functionality" -ForegroundColor White

Write-Host "`n📖 See COMPLETE_SETUP_GUIDE.md for detailed instructions." -ForegroundColor Blue
