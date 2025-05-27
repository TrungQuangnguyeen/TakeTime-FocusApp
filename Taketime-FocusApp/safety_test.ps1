# TakeTime Focus App - Safety Implementation Test
# Tests the comprehensive safety measures against self-blocking

Write-Host "🛡️  TakeTime Focus App - Safety Measures Test" -ForegroundColor Cyan
Write-Host "=============================================`n" -ForegroundColor Cyan

$allTests = @()

# Test 1: Check UI-level protection in blocked_app_screen.dart
Write-Host "🔍 Testing UI-level Protection..." -ForegroundColor Yellow

$uiFile = "lib\screens\blocked_apps\blocked_app_screen.dart"
if (Test-Path $uiFile) {
    $content = Get-Content $uiFile -Raw
    
    # Test 1a: App selection filtering
    if ($content -match "app\.packageName != 'com\.example\.smartmanagementapp'") {
        Write-Host "  ✅ App selection filtering: IMPLEMENTED" -ForegroundColor Green
        $allTests += $true
    } else {
        Write-Host "  ❌ App selection filtering: MISSING" -ForegroundColor Red
        $allTests += $false
    }
    
    # Test 1b: onTap safety check
    if ($content -match "SAFETY CHECK.*com\.example\.smartmanagementapp") {
        Write-Host "  ✅ onTap safety check: IMPLEMENTED" -ForegroundColor Green
        $allTests += $true
    } else {
        Write-Host "  ❌ onTap safety check: MISSING" -ForegroundColor Red
        $allTests += $false
    }
    
    # Test 1c: _checkRunningApps safety
    if ($content -match "_checkRunningApps.*SAFETY.*com\.example\.smartmanagementapp") {
        Write-Host "  ✅ _checkRunningApps safety: IMPLEMENTED" -ForegroundColor Green
        $allTests += $true
    } else {
        Write-Host "  ❌ _checkRunningApps safety: MISSING" -ForegroundColor Red
        $allTests += $false
    }
} else {
    Write-Host "  ❌ UI file not found" -ForegroundColor Red
    $allTests += @($false, $false, $false)
}

# Test 2: Check Service-level protection in AppBlockingService.kt
Write-Host "`n🔍 Testing Service-level Protection..." -ForegroundColor Yellow

$serviceFile = "android\app\src\main\kotlin\com\example\smartmanagementapp\AppBlockingService.kt"
if (Test-Path $serviceFile) {
    $content = Get-Content $serviceFile -Raw
    
    # Test 2a: Package name constant
    if ($content -match "OWN_PACKAGE_NAME.*com\.example\.smartmanagementapp") {
        Write-Host "  ✅ Package name constant: IMPLEMENTED" -ForegroundColor Green
        $allTests += $true
    } else {
        Write-Host "  ❌ Package name constant: MISSING" -ForegroundColor Red
        $allTests += $false
    }
    
    # Test 2b: onAccessibilityEvent filtering
    if ($content -match "onAccessibilityEvent.*OWN_PACKAGE_NAME") {
        Write-Host "  ✅ onAccessibilityEvent filtering: IMPLEMENTED" -ForegroundColor Green
        $allTests += $true
    } else {
        Write-Host "  ❌ onAccessibilityEvent filtering: MISSING" -ForegroundColor Red
        $allTests += $false
    }
    
    # Test 2c: loadBlockedApps safety
    if ($content -match "loadBlockedApps.*SAFETY.*OWN_PACKAGE_NAME") {
        Write-Host "  ✅ loadBlockedApps safety: IMPLEMENTED" -ForegroundColor Green
        $allTests += $true
    } else {
        Write-Host "  ❌ loadBlockedApps safety: MISSING" -ForegroundColor Red
        $allTests += $false
    }
    
    # Test 2d: handleAppLaunch safety
    if ($content -match "handleAppLaunch.*OWN_PACKAGE_NAME") {
        Write-Host "  ✅ handleAppLaunch safety: IMPLEMENTED" -ForegroundColor Green
        $allTests += $true
    } else {
        Write-Host "  ❌ handleAppLaunch safety: MISSING" -ForegroundColor Red
        $allTests += $false
    }
    
    # Test 2e: checkRunningApps filtering
    if ($content -match "checkRunningApps.*OWN_PACKAGE_NAME") {
        Write-Host "  ✅ checkRunningApps filtering: IMPLEMENTED" -ForegroundColor Green
        $allTests += $true
    } else {
        Write-Host "  ❌ checkRunningApps filtering: MISSING" -ForegroundColor Red
        $allTests += $false
    }
    
    # Test 2f: handleAppUsage safety
    if ($content -match "handleAppUsage.*OWN_PACKAGE_NAME") {
        Write-Host "  ✅ handleAppUsage safety: IMPLEMENTED" -ForegroundColor Green
        $allTests += $true
    } else {
        Write-Host "  ❌ handleAppUsage safety: MISSING" -ForegroundColor Red
        $allTests += $false
    }
    
    # Test 2g: blockApp critical safety
    if ($content -match "blockApp.*CRITICAL SAFETY.*OWN_PACKAGE_NAME") {
        Write-Host "  ✅ blockApp critical safety: IMPLEMENTED" -ForegroundColor Green
        $allTests += $true
    } else {
        Write-Host "  ❌ blockApp critical safety: MISSING" -ForegroundColor Red
        $allTests += $false
    }
} else {
    Write-Host "  ❌ Service file not found" -ForegroundColor Red
    $allTests += @($false, $false, $false, $false, $false, $false, $false)
}

# Test 3: Check APK build status
Write-Host "`n🔍 Testing Build Status..." -ForegroundColor Yellow

$apkPath = "build\app\outputs\flutter-apk\app-debug.apk"
if (Test-Path $apkPath) {
    $apkSize = [math]::Round((Get-Item $apkPath).Length / 1MB, 1)
    $buildTime = (Get-Item $apkPath).LastWriteTime
    Write-Host "  ✅ APK Build: $apkSize MB (Built: $buildTime)" -ForegroundColor Green
    $allTests += $true
} else {
    Write-Host "  ❌ APK not found - needs rebuild" -ForegroundColor Red
    $allTests += $false
}

# Calculate results
$passedTests = ($allTests | Where-Object {$_ -eq $true}).Count
$totalTests = $allTests.Count
$successRate = [math]::Round(($passedTests / $totalTests) * 100, 1)

Write-Host "`n📊 Safety Test Results:" -ForegroundColor Cyan
Write-Host "Passed: $passedTests/$totalTests ($successRate%)" -ForegroundColor $(if($successRate -eq 100) {"Green"} elseif($successRate -ge 80) {"Yellow"} else {"Red"})

if ($successRate -eq 100) {
    Write-Host "`n🎉 EXCELLENT! All safety measures implemented correctly." -ForegroundColor Green
    Write-Host "🛡️  The app has comprehensive protection against self-blocking." -ForegroundColor Green
} elseif ($successRate -ge 80) {
    Write-Host "`n⚠️  GOOD! Most safety measures implemented." -ForegroundColor Yellow
    Write-Host "🔧 Review any missing components before testing." -ForegroundColor Yellow
} else {
    Write-Host "`n❌ INCOMPLETE! Critical safety measures are missing." -ForegroundColor Red
    Write-Host "🔧 Fix missing safety checks before proceeding." -ForegroundColor Red
}

Write-Host "`n🚀 Next Steps:" -ForegroundColor Cyan
Write-Host "1. Install APK on Android device" -ForegroundColor White
Write-Host "2. Grant required permissions" -ForegroundColor White
Write-Host "3. Test self-blocking prevention" -ForegroundColor White
Write-Host "4. Test normal app blocking works" -ForegroundColor White
Write-Host "5. Verify performance impact" -ForegroundColor White
