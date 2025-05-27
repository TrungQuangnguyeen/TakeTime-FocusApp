# OVERLAY BLOCKING SYSTEM - TESTING GUIDE

## Testing Overview
The new overlay blocking system has been implemented to replace the previous force-close approach with a user-friendly full-screen overlay.

## How It Works
1. When user opens a blocked app that has exceeded time limits
2. The app is allowed to open normally  
3. Immediately, a full-screen overlay covers the entire app
4. User sees the message: "Ứng dụng này đã được sử dụng vượt quá thời gian cho phép trong hôm nay, hãy tập trung làm việc khác nhé!"
5. User must tap "Thoát ứng dụng" to exit the app

## Testing Steps

### Prerequisites
1. ✅ App installed with latest overlay implementation
2. ✅ Accessibility Service enabled for TakeTime app
3. ✅ System Alert Window permission granted

### Test Procedure

#### Step 1: Setup Test App
1. Open TakeTime app
2. Go to Blocked Apps section
3. Add a test app (e.g., Facebook, Instagram, etc.)
4. Set a very low time limit (e.g., 1 minute)
5. Enable blocking for that app

#### Step 2: Trigger Time Limit
1. Use the test app for more than the set time limit
2. Close the app and wait for usage data to update
3. Or manually set usage time to exceed limit through app settings

#### Step 3: Test Overlay Blocking
1. Try to open the blocked app
2. **Expected Result**: 
   - App opens normally for a brief moment
   - Full-screen overlay appears immediately
   - Overlay shows Vietnamese warning message
   - "Thoát ứng dụng" button is visible
   - Overlay completely covers the app underneath

#### Step 4: Test Exit Functionality  
1. Tap the "Thoát ứng dụng" button
2. **Expected Result**:
   - App is force-closed
   - User returns to home screen
   - Overlay disappears

### Verification Commands

#### Monitor Overlay Service
```powershell
adb logcat -v time | Select-String -Pattern "OverlayBlockingService"
```

#### Monitor App Blocking Triggers
```powershell
adb logcat -v time | Select-String -Pattern "DEBUG BLOCK"
```

#### Monitor Accessibility Events
```powershell
adb logcat -v time | Select-String -Pattern "DEBUG EVENT"
```

## Troubleshooting

### If Overlay Doesn't Appear
1. Check System Alert Window permission:
   - Settings > Apps > TakeTime > Permissions > Display over other apps
2. Check Accessibility Service:
   - Settings > Accessibility > TakeTime > Enable
3. Check logs for errors:
   ```powershell
   adb logcat -v time | Select-String -Pattern "Error.*overlay"
   ```

### If App Doesn't Detect Time Limits
1. Verify app is in blocked list:
   ```powershell
   adb logcat -v time | Select-String -Pattern "DEBUG LOAD"
   ```
2. Check usage time tracking:
   ```powershell
   adb logcat -v time | Select-String -Pattern "App usage update"
   ```

## Key Improvements Made

### OverlayBlockingService.kt
- ✅ Fixed window flags for proper blocking
- ✅ Added automatic monitoring to remove overlay when app closes
- ✅ Enhanced error handling
- ✅ Added Vietnamese warning message

### AppBlockingService.kt  
- ✅ Faster detection with 1-second intervals
- ✅ Dual detection methods (getRunningTasks + UsageStats)
- ✅ Immediate blocking check in onAccessibilityEvent
- ✅ Safety checks to prevent blocking own app
- ✅ Continuous monitoring to maintain overlay

## Expected Behavior
- **More User Friendly**: No sudden app closures
- **Harder to Bypass**: Full-screen overlay that must be acknowledged
- **Clear Messaging**: Vietnamese instructions for users
- **Reliable**: Multiple detection methods and continuous monitoring

## Next Steps for Testing
1. Test with different apps (social media, games, etc.)
2. Test with different time limits
3. Test edge cases (switching apps quickly, using back button, etc.)
4. Verify performance impact on device
5. Test on different Android versions if possible
