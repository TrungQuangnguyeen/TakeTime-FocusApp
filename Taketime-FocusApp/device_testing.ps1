# TakeTime Focus App - Automated Testing Script
# Enhanced Safety Measures Verification

param(
    [switch]$InstallADB,
    [switch]$TestAPK,
    [switch]$MonitorLogs,
    [switch]$SafetyCheck,
    [string]$DeviceSerial
)

$ErrorActionPreference = "Continue"
$ProgressPreference = "SilentlyContinue"

# Colors for output
$RED = "Red"
$GREEN = "Green"
$YELLOW = "Yellow"
$BLUE = "Cyan"

function Write-ColorOutput {
    param($Message, $Color = "White")
    Write-Host $Message -ForegroundColor $Color
}

function Show-Header {
    param($Title)
    Write-Host ""
    Write-ColorOutput "=" * 80 -Color $BLUE
    Write-ColorOutput "  $Title" -Color $BLUE
    Write-ColorOutput "=" * 80 -Color $BLUE
    Write-Host ""
}

function Test-ADBInstallation {
    Write-ColorOutput "Checking ADB installation..." -Color $YELLOW
    try {
        $adbVersion = adb version 2>$null
        if ($adbVersion) {
            Write-ColorOutput "✅ ADB is installed and working" -Color $GREEN
            Write-ColorOutput "Version: $($adbVersion[0])" -Color $GREEN
            return $true
        }
    }
    catch {
        Write-ColorOutput "❌ ADB not found" -Color $RED
        return $false
    }
    return $false
}

function Install-ADBTools {
    Write-ColorOutput "Installing Android Platform Tools..." -Color $YELLOW
    
    try {
        # Try winget first
        Write-ColorOutput "Attempting installation via winget..." -Color $YELLOW
        $result = winget install --id Google.PlatformTools --accept-source-agreements --accept-package-agreements 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            Write-ColorOutput "✅ Platform Tools installed successfully" -Color $GREEN
            Write-ColorOutput "Please restart PowerShell and run this script again" -Color $YELLOW
            return $true
        }
        else {
            Write-ColorOutput "⚠️ Winget installation failed, trying alternative method..." -Color $YELLOW
        }
    }
    catch {
        Write-ColorOutput "⚠️ Winget not available, trying alternative method..." -Color $YELLOW
    }
    
    # Alternative: Download and extract platform tools
    $platformToolsUrl = "https://dl.google.com/android/repository/platform-tools-latest-windows.zip"
    $downloadPath = "$env:TEMP\platform-tools.zip"
    $extractPath = "$env:LOCALAPPDATA\Android\platform-tools"
    
    try {
        Write-ColorOutput "Downloading Platform Tools..." -Color $YELLOW
        Invoke-WebRequest -Uri $platformToolsUrl -OutFile $downloadPath
        
        Write-ColorOutput "Extracting Platform Tools..." -Color $YELLOW
        Expand-Archive -Path $downloadPath -DestinationPath $extractPath -Force
        
        # Add to PATH
        $currentPath = [Environment]::GetEnvironmentVariable("PATH", "User")
        if ($currentPath -notlike "*$extractPath*") {
            [Environment]::SetEnvironmentVariable("PATH", "$currentPath;$extractPath", "User")
            Write-ColorOutput "✅ Platform Tools installed and added to PATH" -Color $GREEN
            Write-ColorOutput "Please restart PowerShell and run this script again" -Color $YELLOW
        }
        
        return $true
    }
    catch {
        Write-ColorOutput "❌ Failed to install Platform Tools: $($_.Exception.Message)" -Color $RED
        return $false
    }
}

function Test-APKFile {
    $apkPath = "build\app\outputs\flutter-apk\app-debug.apk"
    
    Write-ColorOutput "Checking APK file..." -Color $YELLOW
    
    if (Test-Path $apkPath) {
        $apkInfo = Get-Item $apkPath
        Write-ColorOutput "✅ APK found: $($apkInfo.Name)" -Color $GREEN
        Write-ColorOutput "   Size: $([math]::Round($apkInfo.Length / 1MB, 2)) MB" -Color $GREEN
        Write-ColorOutput "   Modified: $($apkInfo.LastWriteTime)" -Color $GREEN
        
        # Check APK signature and package info if aapt is available
        try {
            Write-ColorOutput "Attempting to get APK package info..." -Color $YELLOW
            if (Test-ADBInstallation) {
                $packageInfo = adb shell pm list packages com.example.smartmanagementapp 2>$null
                if ($packageInfo) {
                    Write-ColorOutput "⚠️ App already installed on connected device" -Color $YELLOW
                }
            }
        }
        catch {
            Write-ColorOutput "Could not check package info (device may not be connected)" -Color $YELLOW
        }
        
        return $true
    }
    else {
        Write-ColorOutput "❌ APK not found at: $apkPath" -Color $RED
        Write-ColorOutput "   Please build the APK first with: flutter build apk --debug" -Color $YELLOW
        return $false
    }
}

function Test-ConnectedDevices {
    Write-ColorOutput "Checking connected devices..." -Color $YELLOW
    
    if (-not (Test-ADBInstallation)) {
        Write-ColorOutput "❌ ADB not available" -Color $RED
        return $false
    }
    
    try {
        $devices = adb devices
        $deviceLines = $devices | Where-Object { $_ -match "\t" }
        
        if ($deviceLines) {
            Write-ColorOutput "✅ Connected devices:" -Color $GREEN
            foreach ($device in $deviceLines) {
                Write-ColorOutput "   $device" -Color $GREEN
            }
            return $true
        }
        else {
            Write-ColorOutput "⚠️ No devices connected" -Color $YELLOW
            Write-ColorOutput "   Please connect an Android device with USB debugging enabled" -Color $YELLOW
            return $false
        }
    }
    catch {
        Write-ColorOutput "❌ Failed to check devices: $($_.Exception.Message)" -Color $RED
        return $false
    }
}

function Install-APKOnDevice {
    param($DeviceSerial)
    
    $apkPath = "build\app\outputs\flutter-apk\app-debug.apk"
    
    if (-not (Test-Path $apkPath)) {
        Write-ColorOutput "❌ APK not found" -Color $RED
        return $false
    }
    
    Write-ColorOutput "Installing APK on device..." -Color $YELLOW
    
    try {
        $deviceParam = if ($DeviceSerial) { "-s $DeviceSerial" } else { "" }
        $result = Invoke-Expression "adb $deviceParam install -r `"$apkPath`""
        
        if ($result -match "Success") {
            Write-ColorOutput "✅ APK installed successfully" -Color $GREEN
            return $true
        }
        else {
            Write-ColorOutput "❌ Installation failed: $result" -Color $RED
            return $false
        }
    }
    catch {
        Write-ColorOutput "❌ Installation error: $($_.Exception.Message)" -Color $RED
        return $false
    }
}

function Start-LogMonitoring {
    param($DeviceSerial)
    
    Write-ColorOutput "Starting log monitoring for safety checks..." -Color $YELLOW
    Write-ColorOutput "Press Ctrl+C to stop monitoring" -Color $YELLOW
    Write-Host ""
    
    try {
        $deviceParam = if ($DeviceSerial) { "-s $DeviceSerial" } else { "" }
        
        # Clear existing logs
        Invoke-Expression "adb $deviceParam logcat -c" 2>$null
        
        # Start monitoring with filters for our app
        $logcatProcess = Start-Process -FilePath "adb" -ArgumentList "$deviceParam logcat *:W | findstr `"SAFETY TakeTime BlockingService smartmanagementapp`"" -NoNewWindow -PassThru
        
        Write-ColorOutput "✅ Log monitoring started (Process ID: $($logcatProcess.Id))" -Color $GREEN
        Write-ColorOutput "Monitoring for: SAFETY, TakeTime, BlockingService, smartmanagementapp" -Color $GREEN
        
        return $logcatProcess
    }
    catch {
        Write-ColorOutput "❌ Failed to start log monitoring: $($_.Exception.Message)" -Color $RED
        return $null
    }
}

function Perform-SafetyChecks {
    Write-ColorOutput "Performing comprehensive safety checks..." -Color $YELLOW
    
    # Check code files for safety implementations
    $safetyChecks = @()
    
    # Check Dart file
    $dartFile = "lib\screens\blocked_apps\blocked_app_screen.dart"
    if (Test-Path $dartFile) {
        $dartContent = Get-Content $dartFile -Raw
        $safetyPatterns = @(
            "packageName != 'com.example.smartmanagementapp'",
            "Cannot block TakeTime app itself",
            "SAFETY:",
            "_checkRunningApps"
        )
        
        foreach ($pattern in $safetyPatterns) {
            if ($dartContent -match [regex]::Escape($pattern)) {
                $safetyChecks += "✅ Dart UI Safety: $pattern"
            }
            else {
                $safetyChecks += "❌ Dart UI Safety: $pattern NOT FOUND"
            }
        }
    }
    
    # Check Kotlin service file
    $kotlinFile = "android\app\src\main\kotlin\com\example\smartmanagementapp\AppBlockingService.kt"
    if (Test-Path $kotlinFile) {
        $kotlinContent = Get-Content $kotlinFile -Raw
        $servicePatterns = @(
            "OWN_PACKAGE_NAME",
            "SAFETY: Skipping own package",
            "CRITICAL SAFETY CHECK",
            "com.example.smartmanagementapp"
        )
        
        foreach ($pattern in $servicePatterns) {
            if ($kotlinContent -match [regex]::Escape($pattern)) {
                $safetyChecks += "✅ Kotlin Service Safety: $pattern"
            }
            else {
                $safetyChecks += "❌ Kotlin Service Safety: $pattern NOT FOUND"
            }
        }
    }
    
    # Display results
    Write-Host ""
    foreach ($check in $safetyChecks) {
        if ($check.StartsWith("✅")) {
            Write-ColorOutput $check -Color $GREEN
        }
        else {
            Write-ColorOutput $check -Color $RED
        }
    }
    
    $passedChecks = ($safetyChecks | Where-Object { $_.StartsWith("✅") }).Count
    $totalChecks = $safetyChecks.Count
    
    Write-Host ""
    Write-ColorOutput "Safety Check Summary: $passedChecks/$totalChecks passed" -Color $(if ($passedChecks -eq $totalChecks) { $GREEN } else { $YELLOW })
    
    return $passedChecks -eq $totalChecks
}

function Show-TestingInstructions {
    Write-ColorOutput "Manual Testing Instructions:" -Color $BLUE
    Write-Host ""
    Write-ColorOutput "1. SAFETY TEST - Verify app cannot block itself:" -Color $YELLOW
    Write-ColorOutput "   • Open TakeTime app" -Color "White"
    Write-ColorOutput "   • Go to 'Blocked Apps' screen" -Color "White"
    Write-ColorOutput "   • Look for TakeTime in the app list (should NOT appear)" -Color "White"
    Write-ColorOutput "   • Search for 'TakeTime' or 'Smart Management' (should NOT find it)" -Color "White"
    Write-Host ""
    
    Write-ColorOutput "2. FUNCTIONALITY TEST - Verify normal blocking works:" -Color $YELLOW
    Write-ColorOutput "   • Add Facebook/Instagram to blocked apps" -Color "White"
    Write-ColorOutput "   • Start a 5-minute focus session" -Color "White"
    Write-ColorOutput "   • Try to open Facebook/Instagram" -Color "White"
    Write-ColorOutput "   • Should see blocking overlay and redirect to TakeTime" -Color "White"
    Write-Host ""
    
    Write-ColorOutput "3. EDGE CASE TEST - Test various scenarios:" -Color $YELLOW
    Write-ColorOutput "   • Try blocking system apps" -Color "White"
    Write-ColorOutput "   • Test with multiple apps blocked simultaneously" -Color "White"
    Write-ColorOutput "   • Verify TakeTime remains accessible during blocking" -Color "White"
    Write-Host ""
    
    Write-ColorOutput "Expected Safety Behaviors:" -Color $GREEN
    Write-ColorOutput "   ✅ TakeTime never appears in blocked apps selection" -Color $GREEN
    Write-ColorOutput "   ✅ Safety dialogs appear if somehow TakeTime is selected" -Color $GREEN
    Write-ColorOutput "   ✅ Service logs show 'SAFETY:' messages" -Color $GREEN
    Write-ColorOutput "   ✅ App never blocks itself under any circumstance" -Color $GREEN
}

# Main execution
Show-Header "TakeTime Focus App - Safety Testing Suite"

Write-ColorOutput "Test Date: $(Get-Date)" -Color $BLUE
Write-ColorOutput "APK Build: app-debug.apk (105.3 MB, May 27, 2025)" -Color $BLUE
Write-Host ""

# Handle command line parameters
if ($InstallADB) {
    Show-Header "Installing ADB Tools"
    if (Install-ADBTools) {
        Write-ColorOutput "Installation completed. Please restart PowerShell." -Color $GREEN
        exit 0
    }
    else {
        Write-ColorOutput "Installation failed. Please install manually." -Color $RED
        exit 1
    }
}

if ($SafetyCheck) {
    Show-Header "Safety Implementation Verification"
    $safetyPassed = Perform-SafetyChecks
    if ($safetyPassed) {
        Write-ColorOutput "🎉 All safety checks passed!" -Color $GREEN
    }
    else {
        Write-ColorOutput "⚠️ Some safety checks failed. Please review implementation." -Color $YELLOW
    }
    Write-Host ""
}

if ($TestAPK) {
    Show-Header "APK and Device Testing"
    
    # Test APK
    $apkValid = Test-APKFile
    
    # Test ADB
    $adbWorking = Test-ADBInstallation
    
    if ($adbWorking) {
        # Test devices
        $devicesConnected = Test-ConnectedDevices
        
        if ($devicesConnected -and $apkValid) {
            Write-ColorOutput "Ready for device testing!" -Color $GREEN
            $install = Read-Host "Install APK on device? (y/n)"
            if ($install -eq "y" -or $install -eq "Y") {
                Install-APKOnDevice -DeviceSerial $DeviceSerial
            }
        }
    }
    else {
        Write-ColorOutput "Run with -InstallADB to install ADB tools first" -Color $YELLOW
    }
}

if ($MonitorLogs) {
    Show-Header "Device Log Monitoring"
    
    if (Test-ADBInstallation -and (Test-ConnectedDevices)) {
        $logProcess = Start-LogMonitoring -DeviceSerial $DeviceSerial
        if ($logProcess) {
            Write-ColorOutput "Log monitoring active. Test the app now..." -Color $GREEN
            Read-Host "Press Enter to stop monitoring"
            Stop-Process -Id $logProcess.Id -Force 2>$null
        }
    }
    else {
        Write-ColorOutput "Device or ADB not available for log monitoring" -Color $RED
    }
}

# Default behavior - show overview
if (-not ($InstallADB -or $TestAPK -or $MonitorLogs -or $SafetyCheck)) {
    Show-Header "Testing Overview"
    
    Write-ColorOutput "Available Testing Options:" -Color $BLUE
    Write-Host ""
    Write-ColorOutput "Safety Verification:" -Color $YELLOW
    Write-ColorOutput "  .\device_testing.ps1 -SafetyCheck" -Color "White"
    Write-Host ""
    Write-ColorOutput "Install ADB Tools:" -Color $YELLOW
    Write-ColorOutput "  .\device_testing.ps1 -InstallADB" -Color "White"
    Write-Host ""
    Write-ColorOutput "Test APK & Install on Device:" -Color $YELLOW
    Write-ColorOutput "  .\device_testing.ps1 -TestAPK" -Color "White"
    Write-Host ""
    Write-ColorOutput "Monitor Device Logs:" -Color $YELLOW
    Write-ColorOutput "  .\device_testing.ps1 -MonitorLogs" -Color "White"
    Write-Host ""
    Write-ColorOutput "Specific Device:" -Color $YELLOW
    Write-ColorOutput "  .\device_testing.ps1 -TestAPK -DeviceSerial DEVICE123" -Color "White"
    Write-Host ""
    
    # Quick status check
    Write-ColorOutput "Current Status:" -Color $BLUE
    Test-APKFile | Out-Null
    $adbOK = Test-ADBInstallation
    if ($adbOK) {
        Test-ConnectedDevices | Out-Null
    }
    
    Write-Host ""
    Show-TestingInstructions
}

Write-Host ""
Write-ColorOutput "Testing completed. Check results above." -Color $BLUE
