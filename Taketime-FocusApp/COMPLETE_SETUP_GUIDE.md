# Complete Setup Guide for App Blocking Testing

## 🛠️ Prerequisites Setup

### 1. Install Android SDK Platform Tools (ADB)

#### Option A: Download Platform Tools
1. **Download**: https://developer.android.com/studio/releases/platform-tools
2. **Extract** to a folder like `C:\platform-tools\`
3. **Add to PATH**:
   - Open System Properties > Environment Variables
   - Add `C:\platform-tools\` to your PATH variable
   - Restart PowerShell

#### Option B: Install via Chocolatey (if you have it)
```powershell
choco install adb
```

#### Option C: Install Android Studio
1. Download Android Studio from https://developer.android.com/studio
2. Install with SDK tools included
3. ADB will be in `%LOCALAPPDATA%\Android\Sdk\platform-tools\`

### 2. Prepare Your Android Device

#### Enable Developer Options:
1. Go to **Settings > About phone**
2. Tap **Build number** 7 times
3. You'll see "You are now a developer!"

#### Enable USB Debugging:
1. Go to **Settings > Developer options**
2. Turn on **USB debugging**
3. Connect your device to PC
4. Accept the USB debugging dialog on your phone

### 3. Verify ADB Connection
```powershell
adb devices
```
You should see your device listed as "device" (not "unauthorized")

---

## 🚀 Installation and Testing Process

### Step 1: Build and Install the App
```powershell
# Navigate to project directory
cd "d:\DACS\TakeTime-FocusApp\Taketime-FocusApp"

# Build the APK
flutter build apk --debug

# Install on device
adb install -r build\app\outputs\flutter-apk\app-debug.apk

# Launch the app
adb shell am start -n com.example.smartmanagementapp/.MainActivity
```

### Step 2: Permission Setup in App
1. **Open the TakeTime app**
2. **Navigate to "Blocked Apps"** section
3. **You should see permission setup prompts**

#### Grant Required Permissions:

##### A. Usage Stats Permission
1. Tap **"Enable Usage Stats"** button
2. System will open **Settings > Apps > Special access > Usage access**
3. Find **"TakeTime"** in the list
4. **Enable** the toggle
5. **Return to TakeTime app**

##### B. Display Over Other Apps
1. Tap **"Enable Overlay"** button  
2. System opens **Settings > Apps > Special access > Display over other apps**
3. Find **"TakeTime"** in the list
4. **Enable** the toggle
5. **Return to TakeTime app**

##### C. Accessibility Service
1. Tap **"Enable Accessibility Service"** button
2. System opens **Settings > Accessibility**
3. Find **"TakeTime"** under Downloaded apps
4. Tap it and **turn on** the service
5. Confirm the dialog
6. **Return to TakeTime app**

### Step 3: Configure App Blocking
1. **All permission indicators should be green**
2. **Tap "Add App"** to add apps to block
3. **Select test apps** (Calculator, Clock, etc.)
4. **Set short time limits** (1-2 minutes for testing)
5. **Save the configuration**

### Step 4: Test App Blocking
1. **Open a blocked app** from your home screen
2. **Use it for the configured time**
3. **After time limit**: The app should be blocked with a full-screen overlay
4. **Test overlay buttons**: "Go Home" and "Open Settings"

---

## 🔍 Troubleshooting Guide

### Issue: App Not Installing
**Solution:**
```powershell
# Uninstall existing version
adb uninstall com.example.smartmanagementapp

# Reinstall
adb install build\app\outputs\flutter-apk\app-debug.apk
```

### Issue: Permission Buttons Don't Work
**Check method channel communication:**
```powershell
# Monitor logs while testing
adb logcat | Select-String "AppBlocking|flutter|TakeTime"
```

### Issue: Apps Not Being Blocked
**Verify service status:**
1. Go to **Settings > Accessibility**
2. Check that **TakeTime service is ON**
3. If off, turn it on again

**Check service in system:**
```powershell
adb shell dumpsys activity services | Select-String "AppBlocking"
```

### Issue: Blocking Overlay Not Appearing
**Check overlay permission:**
1. **Settings > Apps > TakeTime > Permissions**
2. Ensure **"Display over other apps"** is enabled

### Issue: High Battery Usage
**Monitor performance:**
```powershell
# Check memory usage
adb shell dumpsys meminfo com.example.smartmanagementapp

# Check running services
adb shell ps | Select-String "smartmanagement"
```

---

## 📱 Testing Scenarios

### Basic Functionality Test
1. **Add Calculator app** with 1-minute limit
2. **Open Calculator** and use for 1+ minutes
3. **Verify**: Blocking overlay appears
4. **Test**: Overlay buttons work correctly

### Multi-App Test  
1. **Add multiple apps** (Calculator, Clock, Camera)
2. **Set different time limits** (1, 2, 3 minutes)
3. **Switch between apps rapidly**
4. **Verify**: Each app tracks time independently

### Persistence Test
1. **Block an app**, then minimize TakeTime
2. **Try opening blocked app from launcher**
3. **Verify**: Blocking still works
4. **Restart device** and test again

### Performance Test
1. **Monitor during normal usage**
2. **Check battery usage** in Settings
3. **Verify smooth operation** of blocked apps

---

## 📊 Log Monitoring Commands

### Real-time Log Monitoring
```powershell
# All app-related logs
adb logcat | Select-String "AppBlocking|flutter|TakeTime"

# Only blocking service logs
adb logcat | Select-String "AppBlocking"

# Flutter debug logs
adb logcat | Select-String "flutter"
```

### Service Status Checks
```powershell
# Check if accessibility service is running
adb shell dumpsys activity services | Select-String "AppBlocking"

# Check app process
adb shell ps | Select-String "smartmanagement"

# Check permissions
adb shell dumpsys package com.example.smartmanagementapp | Select-String "permission"
```

---

## 🎯 Success Indicators

### ✅ Setup Complete When:
- All permission indicators are **green**
- TakeTime appears in **Accessibility settings**
- **"Display over other apps"** permission granted
- **Usage access** permission granted

### ✅ Blocking Working When:
- Apps launch the **blocking overlay** after time limit
- Overlay shows **correct app info** and usage time
- **"Go Home"** button returns to launcher
- **"Open Settings"** button opens TakeTime
- User **cannot bypass** the blocking

### ✅ Performance Optimal When:
- **Battery usage < 5%** per day
- **Memory usage < 50MB**
- **No lag** when launching apps
- **Service persists** after reboot

---

## 🚨 Important Notes

1. **Physical Device Required**: Accessibility services may not work properly in Android emulators
2. **Android 6.0+**: Minimum Android API level 23 required
3. **Permissions Critical**: All three permissions must be granted for blocking to work
4. **Test Apps**: Use non-critical apps for testing (Calculator, Clock, etc.)
5. **Battery Optimization**: Disable battery optimization for TakeTime if blocking stops working

---

## 📞 Support

If you encounter issues:
1. **Check this guide** for troubleshooting steps
2. **Monitor logs** using the provided commands
3. **Test on different apps** to isolate issues
4. **Restart accessibility service** if blocking stops
5. **Reboot device** if persistent issues occur

The app blocking system is now ready for comprehensive testing!
