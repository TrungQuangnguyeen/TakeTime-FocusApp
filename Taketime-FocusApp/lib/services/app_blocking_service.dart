import 'package:flutter/services.dart';

class AppBlockingService {
  static const MethodChannel _channel = MethodChannel('app_blocking_channel');

  // Private constructor
  AppBlockingService._internal();

  // Comprehensive diagnostic method to check entire blocking system
  static Future<Map<String, dynamic>> runDiagnostics() async {
    final diagnostics = <String, dynamic>{};

    try {
      // Check all permissions
      diagnostics['accessibility_permission'] =
          await checkAccessibilityPermission();
      diagnostics['usage_stats_permission'] = await checkUsageStatsPermission();
      diagnostics['overlay_permission'] = await checkOverlayPermission();

      // Check service status
      diagnostics['service_running'] = await isAppBlockingServiceRunning();
      diagnostics['accessibility_service_enabled'] =
          await isAccessibilityServiceEnabled();

      // Check blocked apps data
      diagnostics['blocked_apps_count'] = await getBlockedAppsCount();
      diagnostics['blocked_apps_data'] = await getBlockedAppsData();

      // Check usage monitoring
      diagnostics['usage_monitoring_active'] = await isUsageMonitoringActive();
      diagnostics['current_foreground_app'] = await getCurrentForegroundApp();

      // Test overlay functionality
      diagnostics['overlay_test_result'] = await testOverlayDisplay();

      return diagnostics;
    } catch (e) {
      diagnostics['error'] = e.toString();
      return diagnostics;
    }
  }

  // Check if app blocking service is currently running
  static Future<bool> isAppBlockingServiceRunning() async {
    try {
      final result = await _channel.invokeMethod('isAppBlockingServiceRunning');
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  // Check if accessibility service is enabled in system settings
  static Future<bool> isAccessibilityServiceEnabled() async {
    try {
      final result = await _channel.invokeMethod(
        'isAccessibilityServiceEnabled',
      );
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  // Get count of currently blocked apps
  static Future<int> getBlockedAppsCount() async {
    try {
      final result = await _channel.invokeMethod('getBlockedAppsCount');
      return result ?? 0;
    } catch (e) {
      return 0;
    }
  }

  // Get detailed blocked apps data for debugging
  static Future<List<Map<String, dynamic>>> getBlockedAppsData() async {
    try {
      final result = await _channel.invokeMethod('getBlockedAppsData');
      final List<Map<String, dynamic>> blockedApps =
          (result as List?)?.cast<Map<String, dynamic>>() ?? [];
      return blockedApps;
    } catch (e) {
      return [];
    }
  }

  // Check if usage monitoring is actively working
  static Future<bool> isUsageMonitoringActive() async {
    try {
      final result = await _channel.invokeMethod('isUsageMonitoringActive');
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  // Get current foreground app for debugging
  static Future<String?> getCurrentForegroundApp() async {
    try {
      final result = await _channel.invokeMethod('getCurrentForegroundApp');
      return result;
    } catch (e) {
      return null;
    }
  }

  // Test if overlay can be displayed
  static Future<bool> testOverlayDisplay() async {
    try {
      final result = await _channel.invokeMethod('testOverlayDisplay');
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  // Force trigger blocking for testing (for specific app)
  static Future<bool> forceBlockApp(String packageName) async {
    try {
      final result = await _channel.invokeMethod('forceBlockApp', {
        'packageName': packageName,
      });
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  // Get detailed usage stats for debugging
  static Future<Map<String, dynamic>> getUsageStatsDebug() async {
    try {
      final result = await _channel.invokeMethod('getUsageStatsDebug');
      final Map<String, dynamic> usageStats =
          (result as Map?)?.cast<String, dynamic>() ?? {};
      return usageStats;
    } catch (e) {
      return {};
    }
  }

  // Get service logs for debugging
  static Future<List<String>> getServiceLogs() async {
    try {
      final result = await _channel.invokeMethod('getServiceLogs');
      final List<String> logs = (result as List?)?.cast<String>() ?? [];
      return logs;
    } catch (e) {
      return [];
    }
  }

  // Clear service logs
  static Future<bool> clearServiceLogs() async {
    try {
      final result = await _channel.invokeMethod('clearServiceLogs');
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  // Start the app blocking service
  static Future<bool> startAppBlockingService() async {
    try {
      final result = await _channel.invokeMethod('startAppBlockingService');
      return result ?? false;
    } catch (e) {
      print('Error starting app blocking service: $e');
      return false;
    }
  }

  // Stop the app blocking service
  static Future<bool> stopAppBlockingService() async {
    try {
      final result = await _channel.invokeMethod('stopAppBlockingService');
      return result ?? false;
    } catch (e) {
      print('Error stopping app blocking service: $e');
      return false;
    }
  }

  // Check if accessibility permission is granted
  static Future<bool> checkAccessibilityPermission() async {
    try {
      final result = await _channel.invokeMethod(
        'checkAccessibilityPermission',
      );
      return result ?? false;
    } catch (e) {
      print('Error checking accessibility permission: $e');
      return false;
    }
  }

  // Request accessibility permission
  static Future<bool> requestAccessibilityPermission() async {
    try {
      final result = await _channel.invokeMethod(
        'requestAccessibilityPermission',
      );
      return result ?? false;
    } catch (e) {
      print('Error requesting accessibility permission: $e');
      return false;
    }
  }

  // Check if usage stats permission is granted
  static Future<bool> checkUsageStatsPermission() async {
    try {
      final result = await _channel.invokeMethod('checkUsageStatsPermission');
      return result ?? false;
    } catch (e) {
      print('Error checking usage stats permission: $e');
      return false;
    }
  }

  // Request usage stats permission
  static Future<bool> requestUsageStatsPermission() async {
    try {
      final result = await _channel.invokeMethod('requestUsageStatsPermission');
      return result ?? false;
    } catch (e) {
      print('Error requesting usage stats permission: $e');
      return false;
    }
  }

  // Check if overlay permission is granted
  static Future<bool> checkOverlayPermission() async {
    try {
      final result = await _channel.invokeMethod('checkOverlayPermission');
      return result ?? false;
    } catch (e) {
      print('Error checking overlay permission: $e');
      return false;
    }
  }

  // Request overlay permission
  static Future<bool> requestOverlayPermission() async {
    try {
      final result = await _channel.invokeMethod('requestOverlayPermission');
      return result ?? false;
    } catch (e) {
      print('Error requesting overlay permission: $e');
      return false;
    }
  }

  // Open app settings
  static Future<bool> openAppSettings() async {
    try {
      final result = await _channel.invokeMethod('openAppSettings');
      return result ?? false;
    } catch (e) {
      print('Error opening app settings: $e');
      return false;
    }
  }

  // Open general settings
  static Future<bool> openGeneralSettings() async {
    try {
      final result = await _channel.invokeMethod('openGeneralSettings');
      return result ?? false;
    } catch (e) {
      print('Error opening general settings: $e');
      return false;
    }
  }

  // Check all required permissions
  static Future<Map<String, bool>> checkAllPermissions() async {
    final accessibility = await checkAccessibilityPermission();
    final usageStats = await checkUsageStatsPermission();
    final overlay = await checkOverlayPermission();

    return {
      'accessibility': accessibility,
      'usageStats': usageStats,
      'overlay': overlay,
    };
  }

  // Check if all permissions are granted
  static Future<bool> areAllPermissionsGranted() async {
    final permissions = await checkAllPermissions();
    return permissions.values.every((granted) => granted);
  }

  // Get detailed accessibility service debug info
  static Future<Map<String, dynamic>> getAccessibilityDebugInfo() async {
    try {
      final result = await _channel.invokeMethod(
        'checkAccessibilityPermissionDetailed',
      );
      return Map<String, dynamic>.from(result ?? {});
    } catch (e) {
      print('Error getting accessibility debug info: $e');
      return {'error': e.toString()};
    }
  }

  // Get usage time for a specific app (in seconds) for today
  static Future<int> getAppUsageTime(String packageName) async {
    try {
      final result = await _channel.invokeMethod('getAppUsageStats', {
        'packageName': packageName,
      });
      return result ?? 0;
    } catch (e) {
      print('Error getting app usage time: $e');
      return 0;
    }
  }

  // Get usage time for all apps (returns Map<String, int> where key is package name and value is seconds)
  static Future<Map<String, int>> getAllAppsUsageTime() async {
    try {
      final result = await _channel.invokeMethod('getAllAppsUsageStats');
      final Map<String, dynamic> resultMap = Map<String, dynamic>.from(
        result ?? {},
      );

      // Convert dynamic values to int
      final Map<String, int> usageMap = {};
      resultMap.forEach((key, value) {
        usageMap[key] = (value as num).toInt();
      });

      return usageMap;
    } catch (e) {
      print('Error getting all apps usage time: $e');
      return {};
    }
  }

  // Check if an app is currently running in foreground
  static Future<bool> isAppCurrentlyRunning(String packageName) async {
    try {
      final result = await _channel.invokeMethod('isAppCurrentlyRunning', {
        'packageName': packageName,
      });
      return result ?? false;
    } catch (e) {
      print('Error checking if app is running: $e');
      return false;
    }
  }

  // Reset app usage tracking (for testing purposes)
  static Future<bool> resetAppUsageTime(String packageName) async {
    try {
      final result = await _channel.invokeMethod('resetAppUsageTime', {
        'packageName': packageName,
      });
      return result ?? false;
    } catch (e) {
      print('Error resetting app usage time: $e');
      return false;
    }
  }

  // Get usage time for a specific date range (in minutes)
  static Future<Map<String, int>> getUsageTimeForDateRange(
    DateTime startTime,
    DateTime endTime,
  ) async {
    try {
      // Convert DateTime to milliseconds since epoch
      final int startTimeMillis = startTime.millisecondsSinceEpoch;
      final int endTimeMillis = endTime.millisecondsSinceEpoch;

      final result = await _channel.invokeMethod('getUsageTimeForDateRange', {
        'startTime': startTimeMillis,
        'endTime': endTimeMillis,
      });

      // The native side returns Map<String, String> where value is usage time in milliseconds as String
      final Map<String, String> usageStatsString =
          (result as Map?)?.cast<String, String>() ?? {};

      // Convert milliseconds string to minutes int
      final Map<String, int> usageStatsMinutes = {};
      usageStatsString.forEach((packageName, usageMsString) {
        try {
          final int usageMs = int.parse(usageMsString);
          final int usageMinutes =
              (usageMs / (1000 * 60)).round(); // Convert ms to minutes, round
          if (usageMinutes > 0) {
            // Only include apps with usage > 0 minutes
            usageStatsMinutes[packageName] = usageMinutes;
          }
        } catch (e) {
          print('Error parsing usage time for $packageName: $e');
        }
      });

      return usageStatsMinutes;
    } catch (e) {
      return {}; // Return empty map on error
    }
  }
}
