# App Blocking System - Testing Guide

## Overview
This guide provides comprehensive testing instructions for the app blocking functionality in the TakeTime Focus App.

## Build Status
✅ **APK Build**: Successful  
✅ **Code Analysis**: 411 style/deprecation warnings (non-critical)  
✅ **Compilation**: No errors found

## Prerequisites for Testing

### 1. Device Requirements
- Android device with API level 23+ (Android 6.0+)
- Physical device recommended (accessibility services may not work well in emulator)
- Developer options enabled
- USB debugging enabled

### 2. Installation
1. Install the debug APK: `build/app/outputs/flutter-apk/app-debug.apk`
2. Enable "Install from unknown sources" if prompted

## Testing Phases

### Phase 1: Permission Setup Testing

#### 1.1 Initial App Launch
1. **Launch the app** and navigate to "Blocked Apps" section
2. **Expected**: Permission setup dialog should appear
3. **Verify**: 
   - Usage Stats permission status indicator
   - Overlay permission status indicator
   - Accessibility service status indicator

#### 1.2 Usage Stats Permission
1. **Tap "Enable Usage Stats"**
2. **Expected**: System settings opens to "Usage access" page
3. **Grant permission** to TakeTime app
4. **Return to app**
5. **Verify**: Usage Stats indicator turns green

#### 1.3 Overlay Permission
1. **Tap "Enable Overlay"**
2. **Expected**: System settings opens to "Display over other apps"
3. **Grant permission** to TakeTime app
4. **Return to app**
5. **Verify**: Overlay indicator turns green

#### 1.4 Accessibility Service
1. **Tap "Enable Accessibility Service"**
2. **Expected**: Accessibility settings opens
3. **Find "TakeTime" in accessibility services**
4. **Enable the service**
5. **Return to app**
6. **Verify**: Accessibility indicator turns green

### Phase 2: App Blocking Configuration

#### 2.1 Add Apps to Block List
1. **Navigate to blocked apps screen**
2. **Tap "Add App" button**
3. **Select apps** from the installed apps list
4. **Set time limits** for each app (e.g., 5 minutes for testing)
5. **Save configuration**

#### 2.2 Verify Block Configuration
1. **Check that apps appear** in the blocked list
2. **Verify time limits** are displayed correctly
3. **Test "Block All" functionality**

### Phase 3: App Blocking Functionality Testing

#### 3.1 Basic Blocking Test
1. **Configure a test app** (e.g., Calculator) with 1-minute limit
2. **Open the test app**
3. **Use it for the configured time**
4. **Expected**: App should be blocked after time limit
5. **Verify**: Blocking overlay appears with app info

#### 3.2 Blocking Overlay Testing
1. **When an app is blocked**:
   - Verify app name and icon are displayed
   - Check usage time information
   - Test "Go to Home" button
   - Test "Open Settings" button
   - Verify user cannot bypass the block

#### 3.3 Background Service Testing
1. **Check service persistence**:
   - Block an app, then minimize TakeTime
   - Open the blocked app from launcher
   - Verify blocking still works
2. **Test after device restart**:
   - Restart device
   - Try opening blocked apps
   - Verify service restarts automatically

### Phase 4: Edge Cases and Stress Testing

#### 4.1 Multiple Apps Testing
1. **Block multiple apps** with different time limits
2. **Switch between apps rapidly**
3. **Verify each app tracks time independently**
4. **Test simultaneous app launches**

#### 4.2 System Integration Testing
1. **Test with system apps** (Settings, Phone)
2. **Test during incoming calls**
3. **Test with notification interactions**
4. **Test with other accessibility services**

#### 4.3 Data Persistence Testing
1. **Close and reopen TakeTime app**
2. **Verify usage data persists**
3. **Test after clearing app cache**
4. **Test after device restart**

## Debugging Tools

### Logcat Monitoring
```bash
# Monitor app blocking service logs
adb logcat | grep "AppBlocking"

# Monitor Flutter logs
adb logcat | grep "flutter"
```

### Service Status Check
1. **Settings > Accessibility > TakeTime**
2. **Verify service is running**
3. **Check service description**

### Usage Stats Verification
1. **Settings > Apps > Special access > Usage access**
2. **Verify TakeTime has access**

## Common Issues and Solutions

### Issue 1: Service Not Starting
**Symptoms**: Apps not being blocked despite setup
**Solutions**:
- Restart accessibility service
- Check all permissions granted
- Restart device
- Reinstall app

### Issue 2: Blocking Overlay Not Appearing
**Symptoms**: Service detects app but no overlay shows
**Solutions**:
- Check overlay permission
- Verify no other overlays are interfering
- Test in safe mode

### Issue 3: Permission Requests Not Working
**Symptoms**: Buttons don't open system settings
**Solutions**:
- Check method channel communication
- Verify Android manifest permissions
- Test on different Android versions

### Issue 4: High Battery Usage
**Symptoms**: App drains battery quickly
**Solutions**:
- Monitor coroutine behavior
- Check polling frequency
- Optimize usage tracking

## Performance Benchmarks

### Expected Performance
- **Battery usage**: < 5% per day
- **Memory usage**: < 50MB
- **CPU usage**: < 1% average
- **Block detection time**: < 1 second

### Monitoring Commands
```bash
# Check memory usage
adb shell dumpsys meminfo com.example.smartmanagementapp

# Check battery usage
adb shell dumpsys batterystats | grep smartmanagementapp

# Check running services
adb shell dumpsys activity services | grep AppBlocking
```

## Test Results Template

### Test Session: [Date/Time]
**Device**: [Model and Android version]
**App Version**: [Version number]

#### Permission Setup
- [ ] Usage Stats: ✅/❌
- [ ] Overlay: ✅/❌  
- [ ] Accessibility: ✅/❌

#### Basic Functionality
- [ ] App detection: ✅/❌
- [ ] Time tracking: ✅/❌
- [ ] Blocking activation: ✅/❌
- [ ] Overlay display: ✅/❌

#### Performance
- [ ] Service stability: ✅/❌
- [ ] Battery usage: ✅/❌
- [ ] Response time: ✅/❌

#### Issues Found
[List any issues with details]

#### Notes
[Additional observations]

## Next Steps After Testing

1. **Fix any critical issues found**
2. **Optimize performance bottlenecks**
3. **Improve user experience**
4. **Add more advanced features**:
   - Schedule-based blocking
   - App categories
   - Break time allowances
   - Parent controls

## Advanced Features to Implement

### Device Admin Integration
- Stronger app blocking
- Remote management
- Enterprise features

### Smart Blocking
- AI-based usage pattern detection
- Adaptive time limits
- Context-aware blocking

### Social Features
- Friend accountability
- Usage sharing
- Competitive elements

---

## Contact for Issues
Report any issues found during testing with:
- Device information
- Detailed steps to reproduce
- Screenshots/logs if available
- Expected vs actual behavior
