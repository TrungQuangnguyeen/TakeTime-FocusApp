package com.example.smartmanagementapp

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.AccessibilityServiceInfo
import android.app.ActivityManager
import android.app.usage.UsageStatsManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.util.Log
import android.view.accessibility.AccessibilityEvent
import kotlinx.coroutines.*
import org.json.JSONArray
import org.json.JSONObject
import java.util.*
import android.content.SharedPreferences.OnSharedPreferenceChangeListener
import java.util.Calendar
import android.provider.Settings

class AppBlockingService : AccessibilityService(), OnSharedPreferenceChangeListener {
    private val TAG = "AppBlockingService"
    private var serviceScope = CoroutineScope(Dispatchers.Main + SupervisorJob())
    private lateinit var sharedPrefs: SharedPreferences
    private val blockedPackages = mutableSetOf<String>()
    private val usageTime = mutableMapOf<String, Long>() // Usage time in milliseconds for today
    private val timeLimit = mutableMapOf<String, Int>() // in minutes
    private val lastOpenTime = mutableMapOf<String, Long>() 
    private var isEnabled = false
    
    // SAFETY: Define our own package name as a constant to prevent typos
    private val OWN_PACKAGE_NAME = "com.example.smartmanagementapp"
    
    private val checkIntervalMs = 2000L // Check every 2 seconds
    private var monitoringJob: Job? = null

    override fun onServiceConnected() {
        super.onServiceConnected()
        Log.d(TAG, "App Blocking Service Connected")
        
        // Configure service
        val info = AccessibilityServiceInfo().apply {
            eventTypes = AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED or 
                         AccessibilityEvent.TYPE_WINDOW_CONTENT_CHANGED
            feedbackType = AccessibilityServiceInfo.FEEDBACK_GENERIC
            flags = AccessibilityServiceInfo.FLAG_INCLUDE_NOT_IMPORTANT_VIEWS
            notificationTimeout = 100
        }
        serviceInfo = info
          // Initialize shared preferences
        sharedPrefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        
        // Register the preference change listener
        sharedPrefs.registerOnSharedPreferenceChangeListener(this)
        
        // Load blocked apps data
        loadBlockedApps()
        
        // Start monitoring
        startMonitoring()
        
        // Send broadcast that service is ready
        val intent = Intent("com.example.smartmanagementapp.SERVICE_CONNECTED")
        sendBroadcast(intent)
    }    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (!isEnabled || event == null) return
        
        when (event.eventType) {
            AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED -> {
                val packageName = event.packageName?.toString()
                val className = event.className?.toString()
                Log.d(TAG, "DEBUG EVENT: Window state changed - Package: $packageName, Class: $className")
                
                // Filter out non-activity window changes and system packages/our own app
                if (packageName != null && className != null &&
                    packageName != OWN_PACKAGE_NAME &&
                    !packageName.startsWith("com.android") &&
                    !packageName.startsWith("android") &&
                    !packageName.contains("launcher")) {
                    
                    Log.d(TAG, "DEBUG EVENT: Processing app launch/switch: $packageName")
                    // Check if this launched app is in our blocked list
                    if (blockedPackages.contains(packageName)) {
                        Log.d(TAG, "DEBUG EVENT: Detected blocked app launch: $packageName")
                        // Immediately check usage and block if needed
                        checkAndBlockIfOverLimit(packageName)
                    } else {
                         Log.d(TAG, "DEBUG EVENT: App $packageName is not in blocked list. Ignoring.")
                    }
                } else {
                    Log.d(TAG, "DEBUG EVENT: Filtered out event. Package: $packageName, Class: $className")
                }
            }
        }
    }

    override fun onInterrupt() {
        Log.d(TAG, "Service interrupted")
    }

    override fun onDestroy() {
        super.onDestroy()
        monitoringJob?.cancel()
        serviceScope.cancel()
        // Unregister the preference change listener
        sharedPrefs.unregisterOnSharedPreferenceChangeListener(this)
        Log.d(TAG, "Service destroyed")
    }

    private fun startMonitoring() {
        monitoringJob?.cancel()
        monitoringJob = serviceScope.launch {
            while (isActive) {
                Log.d(TAG, "DEBUG MONITOR: Monitoring loop active.")
                try {
                    // Periodically update usage stats for all blocked apps
                    updateUsageStatsForBlockedApps()
                    
                    // Save updated usage stats to shared preferences
                    saveUsageTime()

                    // Check if any currently running blocked app is over limit (redundant with onAccessibilityEvent, but good fallback)
                    val foregroundApp = getCurrentRunningApp()
                    if (foregroundApp != null && blockedPackages.contains(foregroundApp)) {
                         Log.d(TAG, "DEBUG MONITOR: Foreground app $foregroundApp is blocked. Checking limit.")
                         checkAndBlockIfOverLimit(foregroundApp)
                    } else {
                         Log.d(TAG, "DEBUG MONITOR: Foreground app is not blocked or is null.")
                    }

                    delay(checkIntervalMs)
                } catch (e: Exception) {
                    Log.e(TAG, "Error in monitoring loop: ${e.message}", e)
                }
            }
        }
    }

    // New method to update usage stats for all blocked apps using UsageStatsManager
    private fun updateUsageStatsForBlockedApps() {
        Log.d(TAG, "DEBUG USAGE: Updating usage stats for blocked apps.")
        if (blockedPackages.isEmpty()) {
            Log.d(TAG, "DEBUG USAGE: No blocked packages to update.")
            return
        }

        try {
            val usageStatsManager = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
            val calendar = Calendar.getInstance()
            calendar.set(Calendar.HOUR_OF_DAY, 0)
            calendar.set(Calendar.MINUTE, 0)
            calendar.set(Calendar.SECOND, 0)
            calendar.set(Calendar.MILLISECOND, 0)
            val startTime = calendar.timeInMillis
            val endTime = System.currentTimeMillis()

            val stats = usageStatsManager.queryUsageStats(
                UsageStatsManager.INTERVAL_DAILY, startTime, endTime
            )

            // Clear current usage times and repopulate from fresh stats
            usageTime.clear()
            
            for (usageStat in stats) {
                if (blockedPackages.contains(usageStat.packageName) && usageStat.totalTimeInForeground > 0) {
                    usageTime[usageStat.packageName] = usageStat.totalTimeInForeground
                    Log.d(TAG, "DEBUG USAGE: Updated usage for ${usageStat.packageName}: ${usageStat.totalTimeInForeground / 1000 / 60} min")
                }
            }

            Log.d(TAG, "DEBUG USAGE: Finished updating usage stats. Current usageTime map size: ${usageTime.size}")
            // Log all updated usage times
            usageTime.forEach { (pkg, time) ->
                Log.d(TAG, "DEBUG USAGE: Final usage for $pkg: ${time / 1000 / 60} min")
            }

        } catch (e: Exception) {
            Log.e(TAG, "Error updating usage stats for blocked apps: ${e.message}", e)
        }
    }

    // Helper to get usage stats for a specific package today
    private fun getUsageStatsForPackageToday(packageName: String): Long {
        Log.d(TAG, "DEBUG USAGE: Querying usage for $packageName today.")
        try {
            val usageStatsManager = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
            val calendar = Calendar.getInstance()
            calendar.set(Calendar.HOUR_OF_DAY, 0)
            calendar.set(Calendar.MINUTE, 0)
            calendar.set(Calendar.SECOND, 0)
            calendar.set(Calendar.MILLISECOND, 0)
            val startTime = calendar.timeInMillis
            val endTime = System.currentTimeMillis()

            val stats = usageStatsManager.queryUsageStats(
                UsageStatsManager.INTERVAL_DAILY, startTime, endTime
            )

            var totalTimeInForeground = 0L
            for (usageStat in stats) {
                if (usageStat.packageName == packageName) {
                    totalTimeInForeground = usageStat.totalTimeInForeground
                    Log.d(TAG, "DEBUG USAGE: Found usage for $packageName: ${totalTimeInForeground / 1000 / 60} min")
                    break // Found the package, no need to continue loop
                }
            }
            Log.d(TAG, "DEBUG USAGE: Returning usage for $packageName: ${totalTimeInForeground / 1000 / 60} min")
            return totalTimeInForeground

        } catch (e: Exception) {
            Log.e(TAG, "Error getting usage stats for package $packageName: ${e.message}", e)
            return 0L
        }
    }

    // Helper to check usage and block if over limit
    private fun checkAndBlockIfOverLimit(packageName: String) {
        Log.d(TAG, "DEBUG CHECK: Checking and potentially blocking $packageName.")
        // Ensure package is in our blocked list
        if (!blockedPackages.contains(packageName)) {
             Log.d(TAG, "DEBUG CHECK: $packageName not in blocked list. No blocking.")
             return
        }

        // Get latest usage time (either from map or a quick query)
        val currentUsageMs = getUsageStatsForPackageToday(packageName) // Query on demand for immediate check
        val timeLimitMinutes = timeLimit[packageName] ?: 0
        val timeLimitMs = timeLimitMinutes * 60 * 1000L

        Log.d(TAG, "DEBUG CHECK: App: $packageName, Current Usage: ${currentUsageMs / 1000 / 60} min, Limit: $timeLimitMinutes min.")

        if (timeLimitMinutes > 0 && currentUsageMs >= timeLimitMs) {
            Log.d(TAG, "DEBUG CHECK: App $packageName is over limit. Blocking.")
            blockApp(packageName)
        } else {
            Log.d(TAG, "DEBUG CHECK: App $packageName is within limit.")
        }
    }

    private fun saveUsageTime() {
        // Save usage time periodically to shared preferences using the correct key
        Log.d(TAG, "DEBUG SAVE: Saving usage time to SharedPreferences.")
        try {
            val jsonArray = JSONArray()
            for ((packageName, usage) in usageTime) {
                val jsonObject = JSONObject().apply {
                    put("packageName", packageName)
                    put("seconds", usage / 1000) // Convert back to seconds
                }
                jsonArray.put(jsonObject.toString())
            }

            sharedPrefs.edit()
                .putString("flutter.app_usage_time", jsonArray.toString())
                .apply()

            Log.d(TAG, "DEBUG SAVE: Usage time saved successfully.")

        } catch (e: Exception) {
            Log.e(TAG, "Error saving usage time: ${e.message}", e)
        }
    }    private fun blockApp(packageName: String) {
        // Critical safety check: NEVER block our own app
        if (packageName == OWN_PACKAGE_NAME) {
            Log.w(TAG, "CRITICAL SAFETY CHECK: Attempted to block our own app! Package: $packageName. Ignoring.")
            return
        }
        
        Log.d(TAG, "DEBUG BLOCK: Blocking app with activity - Package: $packageName")
        Log.d(TAG, "DEBUG BLOCK: OWN_PACKAGE_NAME: $OWN_PACKAGE_NAME")
        
        try {
            Log.d(TAG, "DEBUG BLOCK: Starting blocking activity for: $packageName")
            
            // Lấy thông tin thời gian sử dụng và giới hạn MỚI NHẤT từ UsageStatsManager
            val currentUsageMs = getUsageStatsForPackageToday(packageName)
            val timeLimitMinutes = timeLimit[packageName] ?: 0
            
            // Double check limit here before blocking
            if (timeLimitMinutes <= 0 || currentUsageMs < (timeLimitMinutes * 60 * 1000L)) {
                 Log.d(TAG, "DEBUG BLOCK: App $packageName is now within limit or has no limit after final check. Aborting block.")
                 return
            }
            
            // Khởi động AppBlockedActivity
            val blockedIntent = Intent(this, AppBlockedActivity::class.java).apply {
                putExtra("blocked_package", packageName)
                putExtra("app_name", getAppName(packageName))
                putExtra("usage_time", currentUsageMs / (1000 * 60)) // Pass usage in minutes
                putExtra("time_limit", timeLimitMinutes) // Pass limit in minutes
                // Flags để đưa activity lên top và tạo task mới nếu cần
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                addFlags(Intent.FLAG_ACTIVITY_CLEAR_TASK)
                addFlags(Intent.FLAG_ACTIVITY_EXCLUDE_FROM_RECENTS)
            }
            startActivity(blockedIntent)

            // Có thể dừng OverlayBlockingService nếu nó đang chạy từ lần chặn trước
            val stopOverlayIntent = Intent(this, OverlayBlockingService::class.java)
            stopService(stopOverlayIntent)

            // Send notification to Flutter (optional, maybe AppBlockedActivity handles this)
            // sendBlockingNotificationToFlutter(packageName)

            Log.d(TAG, "DEBUG BLOCK: Successfully started blocking activity for: $packageName")

        } catch (e: Exception) {
            Log.e(TAG, "DEBUG BLOCK: Error starting blocking activity for app $packageName: ${e.message}", e)
        }
    }
    
    private fun getCurrentRunningApp(): String? {
        return try {
            val activityManager = getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
            val runningTasks = activityManager.getRunningTasks(1)
            if (runningTasks.isNotEmpty()) {
                runningTasks[0].topActivity?.packageName
            } else {
                null
            }
        } catch (e: Exception) {
            Log.w(TAG, "Error getting current running app (ActivityManager): ${e.message}")
            null
        }
    }

    private fun getAppName(packageName: String): String {
        return try {
            val packageManager = packageManager
            val applicationInfo = packageManager.getApplicationInfo(packageName, 0)
            packageManager.getApplicationLabel(applicationInfo).toString()
        } catch (e: Exception) {
            Log.e(TAG, "Error getting app name for $packageName: ${e.message}", e)
            packageName
        }
    }

    private fun sendBlockingNotificationToFlutter(packageName: String) {
        try {
            // This would be used to communicate with Flutter side
            val intent = Intent("app_blocked_notification").apply {
                putExtra("package_name", packageName)
                putExtra("timestamp", System.currentTimeMillis())
            }
            sendBroadcast(intent)
        } catch (e: Exception) {
            Log.e(TAG, "Error sending notification to Flutter: ${e.message}", e)
        }
    }

    // Method to refresh blocked apps list (called from Flutter)
    fun refreshBlockedApps() {
        serviceScope.launch {
            Log.d(TAG, "DEBUG REFRESH: Received refresh blocked apps request.")
            loadBlockedApps()
            // After loading, update usage stats immediately
            updateUsageStatsForBlockedApps()
            saveUsageTime()
        }
    }

    // Implement the OnSharedPreferenceChangeListener interface
    override fun onSharedPreferenceChanged(sharedPreferences: SharedPreferences?, key: String?) {
        when (key) {
            "flutter.blocked_apps", "flutter.app_usage_time" -> {
                Log.d(TAG, "DEBUG PREFS CHANGE: SharedPreferences changed: $key. Reloading blocked apps data.")
                loadBlockedApps() // Reload data when relevant keys change
                // Update usage stats immediately after loading new config
                updateUsageStatsForBlockedApps()
                saveUsageTime()
            }
        }
    }

    companion object {
        fun isServiceEnabled(context: Context): Boolean {
            val enabledServices = android.provider.Settings.Secure.getString(
                context.contentResolver,
                android.provider.Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES
            )
            
            val service = ComponentName(context, AppBlockingService::class.java)
            val isEnabled = enabledServices?.contains(service.flattenToString()) == true
            Log.d("AppBlockingService", "DEBUG COMPANION: isServiceEnabled check for ${service.flattenToString()}: $isEnabled")
            return isEnabled
        }
        
        // Helper to check for Usage Stats permission outside the service
        fun hasUsageStatsPermission(context: Context): Boolean {
            val appOpsManager = context.getSystemService(Context.APP_OPS_SERVICE) as android.app.AppOpsManager
            val mode = if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.KITKAT) {
                appOpsManager.checkOpNoThrow(
                    android.app.AppOpsManager.OPSTR_GET_USAGE_STATS,
                    android.os.Process.myUid(),
                    context.packageName
                )
            } else {
                android.app.AppOpsManager.MODE_ALLOWED
            }
            val hasPermission = mode == android.app.AppOpsManager.MODE_ALLOWED
            Log.d("AppBlockingService", "DEBUG COMPANION: hasUsageStatsPermission check: $hasPermission")
            return hasPermission
        }

        // Helper to check for Display Over Other Apps permission outside the service
        fun canDrawOverlays(context: Context): Boolean {
            val hasPermission = Settings.canDrawOverlays(context)
            Log.d("AppBlockingService", "DEBUG COMPANION: canDrawOverlays check: $hasPermission")
            return hasPermission
        }
    }

    // Restored loadBlockedApps method
    private fun loadBlockedApps() {
        try {
            // Use Flutter SharedPreferences key format
            val blockedAppsKey = "flutter.blocked_apps"
            val usageTimeKey = "flutter.app_usage_time"

            val blockedAppsData = sharedPrefs.getString(blockedAppsKey, null)
            blockedPackages.clear()
            timeLimit.clear()
            // usageTime.clear() // Do NOT clear usageTime here, it's handled by updateUsageStatsForBlockedApps

            // DEBUG: Log the raw data
            Log.d(TAG, "DEBUG LOAD: Raw blocked apps data: $blockedAppsData")

            if (blockedAppsData != null) {
                // Parse the Flutter SharedPreferences format
                // Assuming data is a JSON array of objects with packageName, timeLimit (minutes), isBlocked (boolean)
                // Example: [{"packageName":"com.game.app","timeLimit":30,"isBlocked":true}]

                val flutterListPrefix = "VGhpcyBpcyB0aGUgcHJlZml4IGZvciBhIGxpc3Qu!"
                val actualJsonString = if (blockedAppsData.startsWith(flutterListPrefix)) {
                    Log.d(TAG, "DEBUG LOAD: Detected Flutter list prefix, removing it.")
                    blockedAppsData.substring(flutterListPrefix.length)
                } else {
                    blockedAppsData
                }

                val cleanJson = actualJsonString.replace("\\\"", "\"").replace("\"{", "{").replace("}\"", "}")
                Log.d(TAG, "DEBUG LOAD: Cleaned JSON: $cleanJson")
                val jsonArray = try { // Sử dụng try-catch cục bộ để bắt lỗi parsing JSON
                     JSONArray(cleanJson)
                } catch (e: Exception) {
                    Log.e(TAG, "DEBUG LOAD: Error parsing JSONArray from cleaned JSON: ${e.message}", e)
                    JSONArray() // Trả về mảng rỗng nếu lỗi
                }

                if (jsonArray.length() > 0) { // Chỉ xử lý nếu mảng JSON không rỗng
                     Log.d(TAG, "DEBUG LOAD: Parsed JSON array length: ${jsonArray.length()}")

                     for (i in 0 until jsonArray.length()) {
                         val appJsonString = jsonArray.getString(i)
                          Log.d(TAG, "DEBUG LOAD: Processing app JSON string: $appJsonString")
                         val appJson = try { // Sử dụng try-catch cục bộ để bắt lỗi parsing JSONObject
                              JSONObject(appJsonString)
                         } catch (e: Exception) {
                             Log.e(TAG, "DEBUG LOAD: Error parsing JSONObject from string: ${e.message}", e)
                             continue // Bỏ qua mục bị lỗi
                         }

                         val packageName = appJson.optString("packageName") // Sử dụng optString để tránh lỗi nếu key không tồn tại
                         val timeLimitMinutes = appJson.optInt("timeLimit", 0) // Sử dụng optInt với giá trị mặc định
                         val isBlocked = appJson.optBoolean("isBlocked", false) // Sử dụng optBoolean với giá trị mặc định

                         Log.d(TAG, "DEBUG LOAD: Processed app - Package: $packageName, TimeLimit: $timeLimitMinutes, IsBlocked: $isBlocked")

                         // SAFETY: Never add our own app to blocked list
                         if (packageName == OWN_PACKAGE_NAME) {
                             Log.w(TAG, "SAFETY: Filtering out our own app from blocked list - Package: $packageName")
                             continue
                         }

                         if (isBlocked) { // Only add if isBlocked is true
                             blockedPackages.add(packageName)
                             timeLimit[packageName] = timeLimitMinutes
                             Log.d(TAG, "DEBUG LOAD: Added to blocked list - Package: $packageName, limit: $timeLimitMinutes minutes")
                         }
                     }
                } else {
                    Log.d(TAG, "DEBUG LOAD: JSONArray is empty or parsing failed.")
                }

            }

            // Usage time is now primarily managed by updateUsageStatsForBlockedApps,
            // but we can still load the last saved state if needed or just rely on the periodic update.
            // For simplicity, let's remove the old usage time loading logic here.
            // The updateUsageStatsForBlockedApps will populate usageTime map on first run and periodically.

            isEnabled = blockedPackages.isNotEmpty() // Service is effectively enabled if there are apps to block

            // DEBUG: Log final state
            Log.d(TAG, "DEBUG LOAD: Final blocked packages: ${blockedPackages.joinToString(", ")}")
            Log.d(TAG, "DEBUG LOAD: Service enabled (based on blocked list): $isEnabled")

        } catch (e: Exception) {
            Log.e(TAG, "Error loading blocked apps (outer catch): ${e.message}", e)
            e.printStackTrace()
        }
    }
}
