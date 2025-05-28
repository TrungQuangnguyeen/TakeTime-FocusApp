package com.example.smartmanagementapp

import android.app.usage.UsageStats
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.provider.Settings
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.*

class MainActivity : FlutterActivity() {
    private val CHANNEL = "app_blocking_channel"
    
    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "startAppBlockingService" -> {
                    val intent = Intent(this, AppBlockingService::class.java)
                    startService(intent)
                    result.success(true)
                }
                "stopAppBlockingService" -> {
                    val intent = Intent(this, AppBlockingService::class.java)
                    stopService(intent)
                    result.success(true)
                }
                "checkAccessibilityPermission" -> {
                    val isEnabled = isAccessibilityServiceEnabled()
                    result.success(isEnabled)
                }
                "checkAccessibilityPermissionDetailed" -> {
                    val result_map = checkAccessibilityServiceDetailed()
                    result.success(result_map)
                }
                "requestAccessibilityPermission" -> {
                    openAccessibilitySettings()
                    result.success(true)
                }
                "checkUsageStatsPermission" -> {
                    val isEnabled = isUsageStatsPermissionGranted()
                    result.success(isEnabled)
                }
                "requestUsageStatsPermission" -> {
                    openUsageStatsSettings()
                    result.success(true)
                }
                "checkOverlayPermission" -> {
                    val isEnabled = Settings.canDrawOverlays(this)
                    result.success(isEnabled)
                }
                "requestOverlayPermission" -> {
                    requestOverlayPermission()
                    result.success(true)
                }
                "openAppSettings" -> {
                    openAppSettings()
                    result.success(true)
                }
                "openGeneralSettings" -> {
                    openGeneralSettings()
                    result.success(true)
                }
                "getAppUsageStats" -> {
                    val packageName = call.argument<String>("packageName")
                    if (packageName != null) {
                        val usageTime = getAppUsageTime(packageName)
                        result.success(usageTime)
                    } else {
                        result.error("INVALID_ARGUMENT", "Package name is required", null)
                    }
                }
                "getAllAppsUsageStats" -> {
                    val usageStats = getAllAppsUsageTime()
                    result.success(usageStats)
                }
                "isAppCurrentlyRunning" -> {
                    val packageName = call.argument<String>("packageName")
                    if (packageName != null) {
                        val isRunning = isAppRunning(packageName)
                        result.success(isRunning)
                    } else {
                        result.error("INVALID_ARGUMENT", "Package name is required", null)
                    }
                }
                "resetAppUsageTime" -> {
                    val packageName = call.argument<String>("packageName")
                    if (packageName != null) {
                        val success = resetAppUsage(packageName)
                        result.success(success)
                    } else {
                        result.error("INVALID_ARGUMENT", "Package name is required", null)
                    }
                }
                // Add method to update blocked apps list and time limits from Flutter
                "updateBlockedApps" -> {
                    val blockedAppsJson = call.argument<String>("blockedAppsJson")
                    if (blockedAppsJson != null) {
                        val success = updateBlockedAppsData(blockedAppsJson)
                        result.success(success)
                    } else {
                        result.error("INVALID_ARGUMENT", "Blocked apps JSON is required", null)
                    }
                }
                // Add method to update app usage time from Flutter
                "updateAppUsageTime" -> {
                    val usageTimeJson = call.argument<String>("usageTimeJson")
                    if (usageTimeJson != null) {
                        val success = updateAppUsageTimeData(usageTimeJson)
                        result.success(success)
                    } else {
                        result.error("INVALID_ARGUMENT", "Usage time JSON is required", null)
                    }
                }
                // Debug methods
                "isAppBlockingServiceRunning" -> {
                    val isRunning = isAppBlockingServiceRunning()
                    result.success(isRunning)
                }
                "isAccessibilityServiceEnabled" -> {
                    val isEnabled = isAccessibilityServiceEnabled()
                    result.success(isEnabled)
                }
                "getBlockedAppsCount" -> {
                    val count = getBlockedAppsCount()
                    result.success(count)
                }
                "getBlockedAppsData" -> {
                    val data = getBlockedAppsData()
                    result.success(data)
                }
                "isUsageMonitoringActive" -> {
                    val isActive = isUsageMonitoringActive()
                    result.success(isActive)
                }
                "getCurrentForegroundApp" -> {
                    val app = getCurrentForegroundApp()
                    result.success(app)
                }
                "testOverlayDisplay" -> {
                    val success = testOverlayDisplay()
                    result.success(success)
                }
                "forceBlockApp" -> {
                    val packageName = call.argument<String>("packageName")
                    if (packageName != null) {
                        val success = forceBlockApp(packageName)
                        result.success(success)
                    } else {
                        result.error("INVALID_ARGUMENT", "Package name is required", null)
                    }
                }
                "getUsageStatsDebug" -> {
                    val debugData = getUsageStatsDebug()
                    result.success(debugData)
                }
                "getServiceLogs" -> {
                    val logs = getServiceLogs()
                    result.success(logs)
                }
                "clearServiceLogs" -> {
                    val success = clearServiceLogs()
                    result.success(success)
                }
                else -> result.notImplemented()
            }
        }
    }
    
    private fun isAccessibilityServiceEnabled(): Boolean {
        try {
            val accessibilityServiceName = "$packageName/.AppBlockingService"
            val accessibilityServices = Settings.Secure.getString(
                contentResolver,
                Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES
            )
            
            // Log để debug
            println("DEBUG: Package name: $packageName")
            println("DEBUG: Service name: $accessibilityServiceName")
            println("DEBUG: Enabled services: $accessibilityServices")
            
            // Kiểm tra nhiều cách khác nhau
            val isEnabled = when {
                accessibilityServices == null -> false
                accessibilityServices.contains(accessibilityServiceName) -> true
                accessibilityServices.contains("AppBlockingService") -> true
                accessibilityServices.contains(packageName) -> true
                else -> {
                    // Kiểm tra bằng cách split và tìm
                    val servicesList = accessibilityServices.split(":").filter { it.isNotEmpty() }
                    servicesList.any { service ->
                        service.contains("AppBlockingService") || 
                        service.endsWith("/.AppBlockingService") ||
                        service.contains(packageName)
                    }
                }
            }
            
            println("DEBUG: Accessibility service enabled: $isEnabled")
            return isEnabled
            
        } catch (e: Exception) {
            println("DEBUG: Error checking accessibility service: ${e.message}")
            return false
        }
    }
    
    private fun openAccessibilitySettings() {
        try {
            // Thử mở trực tiếp trang accessibility
            val intent = Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS)
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            startActivity(intent)
        } catch (e: Exception) {
            // Nếu không được, mở settings chính
            try {
                val intent = Intent(Settings.ACTION_SETTINGS)
                intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                startActivity(intent)
            } catch (e2: Exception) {
                // Cuối cùng, mở app settings của ứng dụng
                openAppSettings()
            }
        }
    }
    
    private fun isUsageStatsPermissionGranted(): Boolean {
        val appOps = getSystemService(ACTIVITY_SERVICE) as android.app.ActivityManager
        val mode = appOps.let {
            if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.KITKAT) {
                val appOpsManager = getSystemService(APP_OPS_SERVICE) as android.app.AppOpsManager
                appOpsManager.checkOpNoThrow(
                    android.app.AppOpsManager.OPSTR_GET_USAGE_STATS,
                    android.os.Process.myUid(),
                    packageName
                )
            } else {
                android.app.AppOpsManager.MODE_ALLOWED
            }
        }
        return mode == android.app.AppOpsManager.MODE_ALLOWED
    }
    
    private fun openUsageStatsSettings() {
        try {
            // Thử mở trực tiếp trang usage access
            val intent = Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS)
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            startActivity(intent)
        } catch (e: Exception) {
            // Nếu không được, thử mở special app access
            try {
                val intent = Intent()
                intent.action = "android.settings.SPECIAL_ACCESS"
                intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                startActivity(intent)
            } catch (e2: Exception) {
                // Cuối cùng, mở settings chính
                try {
                    val intent = Intent(Settings.ACTION_SETTINGS)
                    intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    startActivity(intent)
                } catch (e3: Exception) {
                    openAppSettings()
                }
            }
        }
    }
    
    private fun requestOverlayPermission() {
        if (!Settings.canDrawOverlays(this)) {
            try {
                // Thử mở trực tiếp trang overlay của ứng dụng
                val intent = Intent(
                    Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                    Uri.parse("package:$packageName")
                )
                intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                startActivity(intent)
            } catch (e: Exception) {
                // Nếu không được, mở trang overlay chung
                try {
                    val intent = Intent(Settings.ACTION_MANAGE_OVERLAY_PERMISSION)
                    intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    startActivity(intent)
                } catch (e2: Exception) {
                    // Cuối cùng, mở app settings
                    openAppSettings()
                }
            }
        }
    }
    
    private fun openAppSettings() {
        try {
            val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS)
            intent.data = Uri.parse("package:$packageName")
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            startActivity(intent)
        } catch (e: Exception) {
            // Nếu tất cả đều thất bại, mở settings chính
            val intent = Intent(Settings.ACTION_SETTINGS)
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            startActivity(intent)
        }
    }
    
    private fun openGeneralSettings() {
        try {
            val intent = Intent(Settings.ACTION_SETTINGS)
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            startActivity(intent)
        } catch (e: Exception) {
            // Nếu không thể mở settings, thông báo lỗi
            println("Không thể mở Settings: ${e.message}")
        }
    }
    
    private fun checkAccessibilityServiceDetailed(): Map<String, Any> {
        val result = mutableMapOf<String, Any>()
        
        try {
            val packageName = this.packageName
            val serviceName = "$packageName/.AppBlockingService"
            val accessibilityServices = Settings.Secure.getString(
                contentResolver,
                Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES
            )
            
            result["packageName"] = packageName
            result["serviceName"] = serviceName
            result["enabledServices"] = accessibilityServices ?: "null"
            
            // Multiple checks
            val directCheck = accessibilityServices?.contains(serviceName) == true
            val simpleCheck = accessibilityServices?.contains("AppBlockingService") == true
            val packageCheck = accessibilityServices?.contains(packageName) == true
            
            result["directCheck"] = directCheck
            result["simpleCheck"] = simpleCheck
            result["packageCheck"] = packageCheck
            
            // Final result
            result["isEnabled"] = directCheck || simpleCheck || packageCheck
            
            // Additional check using AccessibilityManager
            try {
                val accessibilityManager = getSystemService(ACCESSIBILITY_SERVICE) as android.view.accessibility.AccessibilityManager
                val runningServices = accessibilityManager.getEnabledAccessibilityServiceList(android.accessibilityservice.AccessibilityServiceInfo.FEEDBACK_ALL_MASK)
                
                val serviceFound = runningServices.any { serviceInfo ->
                    val id = serviceInfo.id
                    id.contains("AppBlockingService") || id.contains(packageName)
                }
                
                result["accessibilityManagerCheck"] = serviceFound
                result["runningServicesCount"] = runningServices.size
                result["runningServiceIds"] = runningServices.map { it.id }
                
            } catch (e: Exception) {
                result["accessibilityManagerError"] = e.message ?: "Unknown error"
            }
            
        } catch (e: Exception) {
            result["error"] = e.message ?: "Unknown error"
        }
        
        return result
    }

    // Get usage time for a specific app in minutes for today
    private fun getAppUsageTime(packageName: String): Long {
        if (!isUsageStatsPermissionGranted()) {
            return 0
        }

        try {
            val usageStatsManager = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
            
            // Get usage stats for today
            val calendar = Calendar.getInstance()
            calendar.set(Calendar.HOUR_OF_DAY, 0)
            calendar.set(Calendar.MINUTE, 0)
            calendar.set(Calendar.SECOND, 0)
            calendar.set(Calendar.MILLISECOND, 0)
            val startTime = calendar.timeInMillis
            val endTime = System.currentTimeMillis()

            val usageStats = usageStatsManager.queryUsageStats(
                UsageStatsManager.INTERVAL_DAILY, startTime, endTime
            )

            var totalTimeInForeground = 0L
            for (usageStat in usageStats) {
                if (usageStat.packageName == packageName) {
                    totalTimeInForeground += usageStat.totalTimeInForeground
                }
            }

            // Convert from milliseconds to seconds
            return totalTimeInForeground / 1000
        } catch (e: Exception) {
            println("Error getting app usage time: ${e.message}")
            return 0
        }
    }

    // Get usage time for all apps for today
    private fun getAllAppsUsageTime(): Map<String, Long> {
        if (!isUsageStatsPermissionGranted()) {
            return emptyMap()
        }

        try {
            val usageStatsManager = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
            
            // Get usage stats for today
            val calendar = Calendar.getInstance()
            calendar.set(Calendar.HOUR_OF_DAY, 0)
            calendar.set(Calendar.MINUTE, 0)
            calendar.set(Calendar.SECOND, 0)
            calendar.set(Calendar.MILLISECOND, 0)
            val startTime = calendar.timeInMillis
            val endTime = System.currentTimeMillis()

            val usageStats = usageStatsManager.queryUsageStats(
                UsageStatsManager.INTERVAL_DAILY, startTime, endTime
            )

            val appUsageMap = mutableMapOf<String, Long>()
            for (usageStat in usageStats) {
                if (usageStat.totalTimeInForeground > 0) {
                    // Convert from milliseconds to seconds
                    appUsageMap[usageStat.packageName] = usageStat.totalTimeInForeground / 1000
                }
            }

            return appUsageMap
        } catch (e: Exception) {
            println("Error getting all apps usage time: ${e.message}")
            return emptyMap()
        }
    }

    // Check if an app is currently running in foreground
    private fun isAppRunning(packageName: String): Boolean {
        if (!isUsageStatsPermissionGranted()) {
            return false
        }

        try {
            val usageStatsManager = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
            
            // Check usage in the last 1 minute to see if app is currently active
            val endTime = System.currentTimeMillis()
            val startTime = endTime - (60 * 1000) // 1 minute ago

            val usageStats = usageStatsManager.queryUsageStats(
                UsageStatsManager.INTERVAL_BEST, startTime, endTime
            )

            // Find the most recently used app
            var mostRecentApp: UsageStats? = null
            var mostRecentTime = 0L

            for (usageStat in usageStats) {
                if (usageStat.lastTimeUsed > mostRecentTime) {
                    mostRecentTime = usageStat.lastTimeUsed
                    mostRecentApp = usageStat
                }
            }

            return mostRecentApp?.packageName == packageName && 
                   (System.currentTimeMillis() - mostRecentTime) < 30000 // Active within last 30 seconds
        } catch (e: Exception) {
            println("Error checking if app is running: ${e.message}")
            return false
        }
    }

    // Reset/clear usage tracking for an app (for testing purposes)
    private fun resetAppUsage(packageName: String): Boolean {
        // Note: We cannot actually reset system usage stats
        // This method is for future use or can be used to reset our own tracking
        // For now, just return true to indicate the request was received
        println("Reset usage request for package: $packageName")
        return true
    }
    
    // Debug methods for troubleshooting blocking functionality
    
    private fun isAppBlockingServiceRunning(): Boolean {
        try {
            // Check if the accessibility service is running by checking if it's enabled
            return isAccessibilityServiceEnabled()
        } catch (e: Exception) {
            println("Error checking if AppBlockingService is running: ${e.message}")
            return false
        }
    }
    
    private fun getBlockedAppsCount(): Int {
        try {
            val sharedPrefs = getSharedPreferences("app_blocking_prefs", Context.MODE_PRIVATE)
            val blockedAppsJson = sharedPrefs.getString("blocked_apps", "[]")
            // Parse JSON to count apps (simplified - in real implementation should parse properly)
            val count = if (blockedAppsJson == "[]") 0 else {
                // Count commas + 1 for a rough estimate, or implement proper JSON parsing
                blockedAppsJson?.split(",")?.size ?: 0
            }
            println("DEBUG: Blocked apps count: $count")
            return count
        } catch (e: Exception) {
            println("Error getting blocked apps count: ${e.message}")
            return 0
        }
    }
    
    private fun getBlockedAppsData(): List<Map<String, Any>> {
        try {
            val sharedPrefs = getSharedPreferences("app_blocking_prefs", Context.MODE_PRIVATE)
            val blockedAppsJson = sharedPrefs.getString("blocked_apps", "[]")
            println("DEBUG: Blocked apps JSON: $blockedAppsJson")
            
            // For now, return basic info - in real implementation should parse JSON properly
            val blockedApps = mutableListOf<Map<String, Any>>()
            if (blockedAppsJson != "[]" && blockedAppsJson != null && blockedAppsJson.isNotEmpty()) {
                // Create dummy data for debugging - replace with proper JSON parsing
                blockedApps.add(mapOf(
                    "packageName" to "example.app",
                    "appName" to "Example App",
                    "timeLimit" to 3600,
                    "usageTime" to 0
                ))
            }
            
            return blockedApps
        } catch (e: Exception) {
            println("Error getting blocked apps data: ${e.message}")
            return emptyList()
        }
    }
    
    private fun isUsageMonitoringActive(): Boolean {
        try {
            // Check if we have usage stats permission
            val hasUsageStatsPermission = isUsageStatsPermissionGranted()
            
            // Check if accessibility service is enabled
            val hasAccessibilityPermission = isAccessibilityServiceEnabled()
            
            val isActive = hasUsageStatsPermission && hasAccessibilityPermission
            println("DEBUG: Usage monitoring active: $isActive (UsageStats: $hasUsageStatsPermission, Accessibility: $hasAccessibilityPermission)")
            
            return isActive
        } catch (e: Exception) {
            println("Error checking usage monitoring status: ${e.message}")
            return false
        }
    }
    
    private fun getCurrentForegroundApp(): String? {
        try {
            val usageStatsManager = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
            val currentTime = System.currentTimeMillis()
            
            // Get usage stats for the last minute
            val usageStats = usageStatsManager.queryUsageStats(
                UsageStatsManager.INTERVAL_BEST, currentTime - 60000, currentTime
            )
            
            var mostRecentApp: UsageStats? = null
            var mostRecentTime = 0L
            
            for (usageStat in usageStats) {
                if (usageStat.lastTimeUsed > mostRecentTime) {
                    mostRecentTime = usageStat.lastTimeUsed
                    mostRecentApp = usageStat
                }
            }
            
            val foregroundApp = mostRecentApp?.packageName
            println("DEBUG: Current foreground app: $foregroundApp (last used: $mostRecentTime)")
            return foregroundApp
            
        } catch (e: Exception) {
            println("Error getting current foreground app: ${e.message}")
            return null
        }
    }
    
    private fun testOverlayDisplay(): Boolean {
        try {
            if (!Settings.canDrawOverlays(this)) {
                println("DEBUG: Overlay permission not granted")
                return false
            }
            
            // Start the overlay service for testing
            val intent = Intent(this, OverlayBlockingService::class.java)
            intent.putExtra("packageName", "test.overlay.display")
            intent.putExtra("appName", "Test Overlay")
            startService(intent)
            
            println("DEBUG: Test overlay display started")
            return true
            
        } catch (e: Exception) {
            println("Error testing overlay display: ${e.message}")
            return false
        }
    }
    
    private fun forceBlockApp(packageName: String): Boolean {
        try {
            if (!Settings.canDrawOverlays(this)) {
                println("DEBUG: Cannot force block - overlay permission not granted")
                return false
            }
            
            // Start the overlay service to block the specified app
            val intent = Intent(this, OverlayBlockingService::class.java)
            intent.putExtra("packageName", packageName)
            intent.putExtra("appName", "Force Blocked App")
            startService(intent)
            
            println("DEBUG: Force blocking app: $packageName")
            return true
            
        } catch (e: Exception) {
            println("Error force blocking app: ${e.message}")
            return false
        }
    }
    
    private fun getUsageStatsDebug(): Map<String, Any> {
        try {
            val debugData = mutableMapOf<String, Any>()
            
            val usageStatsManager = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
            val currentTime = System.currentTimeMillis()
            
            // Get today's usage stats
            val calendar = Calendar.getInstance()
            calendar.set(Calendar.HOUR_OF_DAY, 0)
            calendar.set(Calendar.MINUTE, 0)
            calendar.set(Calendar.SECOND, 0)
            calendar.set(Calendar.MILLISECOND, 0)
            val startTime = calendar.timeInMillis
            
            val usageStats = usageStatsManager.queryUsageStats(
                UsageStatsManager.INTERVAL_DAILY, startTime, currentTime
            )
            
            debugData["permission_granted"] = isUsageStatsPermissionGranted()
            debugData["stats_count"] = usageStats.size
            debugData["query_start_time"] = startTime
            debugData["query_end_time"] = currentTime
            debugData["current_time"] = currentTime
            
            // Get top 5 most used apps for debugging
            val topApps = usageStats
                .filter { it.totalTimeInForeground > 0 }
                .sortedByDescending { it.totalTimeInForeground }
                .take(5)
                .map { mapOf(
                    "packageName" to it.packageName,
                    "totalTime" to it.totalTimeInForeground,
                    "lastTimeUsed" to it.lastTimeUsed
                )}
            
            debugData["top_apps"] = topApps
            
            println("DEBUG: Usage stats debug data: $debugData")
            return debugData
            
        } catch (e: Exception) {
            println("Error getting usage stats debug: ${e.message}")
            return mapOf("error" to e.message.toString())
        }
    }
    
    private fun getServiceLogs(): List<String> {
        try {
            // In a real implementation, this would read logs from the AppBlockingService
            // For now, return some debug information
            val logs = mutableListOf<String>()
            logs.add("[${Date()}] MainActivity: Getting service logs")
            logs.add("[${Date()}] Accessibility Service Enabled: ${isAccessibilityServiceEnabled()}")
            logs.add("[${Date()}] Usage Stats Permission: ${isUsageStatsPermissionGranted()}")
            logs.add("[${Date()}] Overlay Permission: ${Settings.canDrawOverlays(this)}")
            logs.add("[${Date()}] Current Foreground App: ${getCurrentForegroundApp()}")
            
            println("DEBUG: Service logs count: ${logs.size}")
            return logs
            
        } catch (e: Exception) {
            println("Error getting service logs: ${e.message}")
            return listOf("Error getting logs: ${e.message}")
        }
    }
    
    private fun clearServiceLogs(): Boolean {
        try {
            // In a real implementation, this would clear logs from the AppBlockingService
            // For now, just return true
            println("DEBUG: Service logs cleared")
            return true
        } catch (e: Exception) {
            println("Error clearing service logs: ${e.message}")
            return false
        }
    }

    // Method to update blocked apps data in SharedPreferences
    private fun updateBlockedAppsData(blockedAppsJson: String): Boolean {
        try {
            val sharedPrefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            // Store the raw JSON string received from Flutter
            sharedPrefs.edit().putString("flutter.blocked_apps", blockedAppsJson).apply()
            // Log for debugging
            println("DEBUG: Updated blocked apps data in SharedPreferences: $blockedAppsJson")
            // Note: AppBlockingService needs to reload this data after update
            // This might require restarting the service or sending a broadcast
            // For now, we just update the prefs. Reload logic needs to be in service.
            return true
        } catch (e: Exception) {
            println("DEBUG: Error updating blocked apps data: ${e.message}")
            return false
        }
    }

    // Method to update app usage time data in SharedPreferences
    private fun updateAppUsageTimeData(usageTimeJson: String): Boolean {
        try {
            val sharedPrefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            // Store the raw JSON string received from Flutter
            sharedPrefs.edit().putString("flutter.app_usage_time", usageTimeJson).apply()
             // Log for debugging
            println("DEBUG: Updated usage time data in SharedPreferences: $usageTimeJson")
            // Note: AppBlockingService needs to reload this data after update
            // This might require restarting the service or sending a broadcast
            // For now, we just update the prefs. Reload logic needs to be in service.
            return true
        } catch (e: Exception) {
            println("DEBUG: Error updating usage time data: ${e.message}")
            return false
        }
    }
}
