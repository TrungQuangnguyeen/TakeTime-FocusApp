#!/bin/bash

# TakeTime Focus App - Installation and Testing Script
# This script helps you install and test the app blocking functionality

echo "🎯 TakeTime Focus App - App Blocking Testing"
echo "=============================================="

# Check if ADB is available
if ! command -v adb &> /dev/null; then
    echo "❌ ADB not found. Please install Android SDK Platform Tools."
    exit 1
fi

# Check if device is connected
DEVICE_COUNT=$(adb devices | grep -v "List of devices attached" | grep "device" | wc -l)
if [ "$DEVICE_COUNT" -eq 0 ]; then
    echo "❌ No Android device connected. Please connect your device and enable USB debugging."
    exit 1
fi

echo "✅ Found $DEVICE_COUNT connected device(s)"

# Check if APK exists
APK_PATH="build/app/outputs/flutter-apk/app-debug.apk"
if [ ! -f "$APK_PATH" ]; then
    echo "❌ APK not found at $APK_PATH"
    echo "   Please run: flutter build apk --debug"
    exit 1
fi

echo "✅ APK found at $APK_PATH"

# Install APK
echo "📱 Installing APK..."
adb install -r "$APK_PATH"

if [ $? -eq 0 ]; then
    echo "✅ APK installed successfully"
else
    echo "❌ Failed to install APK"
    exit 1
fi

# Launch app
echo "🚀 Launching TakeTime app..."
adb shell am start -n com.example.smartmanagementapp/.MainActivity

echo ""
echo "📋 Testing Checklist:"
echo "===================="
echo "1. ✓ Navigate to 'Blocked Apps' section"
echo "2. ✓ Set up permissions (Usage Stats, Overlay, Accessibility)"
echo "3. ✓ Add test apps with short time limits (1-2 minutes)"
echo "4. ✓ Use test apps until blocked"
echo "5. ✓ Verify blocking overlay appears"
echo "6. ✓ Test 'Go Home' and 'Settings' buttons"
echo ""
echo "📊 Monitoring Commands:"
echo "======================"
echo "# Monitor app blocking logs:"
echo "adb logcat | grep 'AppBlocking'"
echo ""
echo "# Monitor Flutter logs:"
echo "adb logcat | grep 'flutter'"
echo ""
echo "# Check service status:"
echo "adb shell dumpsys activity services | grep AppBlocking"
echo ""
echo "🔧 Troubleshooting:"
echo "=================="
echo "If blocking doesn't work:"
echo "- Ensure all permissions are granted"
echo "- Restart accessibility service in Settings"
echo "- Check that TakeTime appears in Accessibility services"
echo "- Verify 'Display over other apps' permission"
echo ""
echo "Happy testing! 🎉"
