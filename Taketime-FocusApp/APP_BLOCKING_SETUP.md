# App Blocking Feature Setup Guide

## Overview
This guide will help you set up and test the app blocking functionality in the Take Time Focus App.

## What's Been Implemented

### 1. Native Android Components
- **AppBlockingService.kt**: Accessibility Service that monitors app launches and enforces time limits
- **AppBlockedActivity.kt**: Full-screen blocking overlay that prevents app usage when limits are exceeded
- **MainActivity.kt**: Enhanced with method channels for Flutter-Android communication

### 2. Flutter Components
- **AppBlockingService**: Flutter service class for communicating with native Android code
- **Enhanced BlockedAppScreen**: Updated with permission management and native blocking integration
- **Permission Management**: Automatic checking and requesting of required permissions

### 3. Required Permissions
- **Accessibility Service**: To monitor and control app launches
- **Usage Stats**: To track real app usage time
- **System Alert Window**: To display blocking overlays

## Setup Instructions

### 1. Build and Install the App
```bash
cd "d:\DACS\TakeTime-FocusApp\Taketime-FocusApp"
flutter clean
flutter pub get
flutter build apk --debug
# Or run directly on device
flutter run
```

### 2. Grant Required Permissions

#### Step 1: Accessibility Service
1. Open the app and go to "Blocked Apps" screen
2. You'll see a permission dialog or orange warning icon
3. Tap "Grant Permissions" or the warning icon
4. This will open Android Settings > Accessibility
5. Find "Take Time - Time manager app" service
6. Enable the service

#### Step 2: Usage Access Permission
1. The app will also open Usage Access settings
2. Find "Take Time - Time manager app"
3. Enable usage access

#### Step 3: Display Over Other Apps
1. The app will open overlay permission settings
2. Enable "Display over other apps" for Take Time

### 3. Test the App Blocking

#### Setup Test Apps
1. Go to "Blocked Apps" screen
2. Tap "Add App" button (+)
3. Select apps like Chrome, Instagram, or YouTube
4. Set low time limits (e.g., 1-2 minutes) for testing
5. Enable blocking for these apps (toggle switch)

#### Test Blocking
1. Open one of the blocked apps
2. Use it for the set time limit
3. The app should automatically be blocked with a full-screen overlay
4. Try to bypass the blocking (it should prevent access)

## Features

### Real-time Monitoring
- The Accessibility Service continuously monitors app launches
- Usage time is tracked and synced with Flutter app data
- Time limits are enforced automatically

### Blocking Mechanism
- When an app exceeds its time limit, a full-screen blocking activity is launched
- The blocking screen shows usage statistics and prevents app access
- Users can only go to home screen or app settings

### Permission Management
- Automatic permission checking on app startup
- Visual indicators showing permission status
- Easy permission request flow with instructions

## Troubleshooting

### Service Not Working
1. Check if Accessibility Service is enabled in Android Settings
2. Restart the app after enabling permissions
3. Check Android logs for any errors

### Apps Not Being Blocked
1. Ensure all three permissions are granted
2. Check that the app is in the blocked list with blocking enabled
3. Verify time limits are set correctly

### Permission Issues
1. Some devices may require additional steps for accessibility permission
2. Usage stats permission might need to be granted from Android Settings manually
3. Overlay permission is required for blocking to work

## Technical Details

### Data Flow
1. Flutter app manages blocked apps list and time limits
2. Data is shared with Android service via SharedPreferences
3. Accessibility Service monitors app launches and enforces limits
4. Blocking activity displays when limits are exceeded

### Key Files
- `AppBlockingService.kt`: Main monitoring and blocking logic
- `AppBlockedActivity.kt`: Blocking UI
- `app_blocking_service.dart`: Flutter-Android communication
- `blocked_app_screen.dart`: Main UI with permission management

## Next Steps

### Enhancements
1. Add schedule-based blocking
2. Implement break time functionality
3. Add usage statistics sync
4. Improve blocking bypass prevention
5. Add parent/admin controls

### Testing
1. Test on different Android versions
2. Test with various apps
3. Performance testing for battery usage
4. Edge case handling

## Known Limitations
1. Some system apps cannot be blocked
2. Requires manual permission setup
3. May be affected by battery optimization settings
4. Some apps might find ways to bypass accessibility service monitoring

## Support
If you encounter issues:
1. Check Android version compatibility (Android 5.0+)
2. Verify all permissions are granted
3. Restart the device if accessibility service seems unresponsive
4. Check device manufacturer-specific accessibility settings
