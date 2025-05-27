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

class AppBlockingService : AccessibilityService() {
    private val TAG = "AppBlockingService"
    private var serviceScope = CoroutineScope(Dispatchers.Main + SupervisorJob())
    private lateinit var sharedPrefs: SharedPreferences
    private val blockedPackages = mutableSetOf<String>()
    private val usageTime = mutableMapOf<String, Long>()
    private val timeLimit = mutableMapOf<String, Int>() // in minutes
    private val lastOpenTime = mutableMapOf<String, Long>()
    private var isEnabled = false
    
    // SAFETY: Define our own package name as a constant to prevent typos
    private val OWN_PACKAGE_NAME = "com.example.smartmanagementapp"
    
    private val checkInterval = 1000L // Check every 1 second (faster response)
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
                Log.d(TAG, "DEBUG EVENT: Window state changed - Package: $packageName")
                Log.d(TAG, "DEBUG EVENT: OWN_PACKAGE_NAME: $OWN_PACKAGE_NAME")
                
                // Whitelist our own app and system apps
                if (packageName != null && 
                    packageName != OWN_PACKAGE_NAME && 
                    !packageName.startsWith("com.android") &&
                    !packageName.startsWith("android") &&
                    !packageName.contains("launcher")) {
                    
                    Log.d(TAG, "DEBUG EVENT: Passing to handleAppLaunch - Package: $packageName")
                    handleAppLaunch(packageName)
                    
                    // Kiểm tra ngay lập tức nếu app này bị chặn
                    if (blockedPackages.contains(packageName)) {
                        val timeLimitMs = (timeLimit[packageName] ?: 0) * 60 * 1000L
                        val currentUsage = usageTime[packageName] ?: 0L
                        
                        if (currentUsage >= timeLimitMs) {
                            Log.d(TAG, "DEBUG EVENT: Immediate blocking for: $packageName")
                            blockApp(packageName)
                        }
                    }
                } else {
                    Log.d(TAG, "DEBUG EVENT: Filtered out - Package: $packageName (Own app or system)")
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
        Log.d(TAG, "Service destroyed")
    }

    private fun startMonitoring() {
        monitoringJob?.cancel()
        monitoringJob = serviceScope.launch {
            while (isActive) {
                try {
                    checkRunningApps()
                    updateUsageTime()
                    delay(checkInterval)
                } catch (e: Exception) {
                    Log.e(TAG, "Error in monitoring loop: ${e.message}")
                }
            }
        }
    }    private fun loadBlockedApps() {
        try {
            // Use Flutter SharedPreferences key format
            val blockedAppsKey = "flutter.blocked_apps"
            val usageTimeKey = "flutter.app_usage_time"
            
            val blockedAppsData = sharedPrefs.getString(blockedAppsKey, null)
            blockedPackages.clear()
            timeLimit.clear()
            
            // DEBUG: Log the raw data
            Log.d(TAG, "DEBUG LOAD: Raw blocked apps data: $blockedAppsData")
            
            if (blockedAppsData != null) {
                // Parse the Flutter SharedPreferences format
                val cleanJson = blockedAppsData.replace("\\\"", "\"")
                val jsonArray = JSONArray(cleanJson)
                
                Log.d(TAG, "DEBUG LOAD: Parsed JSON array length: ${jsonArray.length()}")
                
                for (i in 0 until jsonArray.length()) {
                    val appJsonString = jsonArray.getString(i)
                    val appJson = JSONObject(appJsonString)
                    val packageName = appJson.getString("packageName")
                    val timeLimitMinutes = appJson.getInt("timeLimit")
                    val isBlocked = appJson.getBoolean("isBlocked")
                    
                    Log.d(TAG, "DEBUG LOAD: Processing app - Package: $packageName, TimeLimit: $timeLimitMinutes, IsBlocked: $isBlocked")
                    
                    // SAFETY: Never add our own app to blocked list
                    if (packageName == OWN_PACKAGE_NAME) {
                        Log.w(TAG, "SAFETY: Filtering out our own app from blocked list - Package: $packageName")
                        continue
                    }
                    
                    if (isBlocked) {
                        blockedPackages.add(packageName)
                        timeLimit[packageName] = timeLimitMinutes
                        Log.d(TAG, "DEBUG LOAD: Added to blocked list - Package: $packageName, limit: $timeLimitMinutes minutes")
                    }
                }
            }
            
            // Load usage time from Flutter format
            val usageTimeData = sharedPrefs.getString(usageTimeKey, null)
            if (usageTimeData != null) {
                val cleanJson = usageTimeData.replace("\\\"", "\"")
                val jsonArray = JSONArray(cleanJson)
                for (i in 0 until jsonArray.length()) {
                    val usageJsonString = jsonArray.getString(i)
                    val usageJson = JSONObject(usageJsonString)
                    val packageName = usageJson.getString("packageName")
                    val seconds = usageJson.getLong("seconds")
                    usageTime[packageName] = seconds * 1000 // Convert to milliseconds
                }
            }
            
            isEnabled = blockedPackages.isNotEmpty()
            
            // DEBUG: Log final state
            Log.d(TAG, "DEBUG LOAD: Final blocked packages: ${blockedPackages.joinToString(", ")}")
            Log.d(TAG, "DEBUG LOAD: OWN_PACKAGE_NAME: $OWN_PACKAGE_NAME")
            Log.d(TAG, "DEBUG LOAD: Service enabled: $isEnabled")
            
        } catch (e: Exception) {
            Log.e(TAG, "Error loading blocked apps: ${e.message}")
            e.printStackTrace()
        }
    }    private fun handleAppLaunch(packageName: String) {
        // Double-check that we're not blocking our own app
        if (packageName == OWN_PACKAGE_NAME) {
            Log.d(TAG, "SAFETY: Ignoring our own app launch - Package: $packageName")
            return
        }
        
        Log.d(TAG, "DEBUG HANDLE: Processing app launch - Package: $packageName")
        Log.d(TAG, "DEBUG HANDLE: Is enabled: $isEnabled")
        Log.d(TAG, "DEBUG HANDLE: Blocked packages: ${blockedPackages.joinToString(", ")}")
        Log.d(TAG, "DEBUG HANDLE: Package in blocked list: ${blockedPackages.contains(packageName)}")
        
        if (!isEnabled || !blockedPackages.contains(packageName)) {
            Log.d(TAG, "DEBUG HANDLE: App not blocked or service disabled - Package: $packageName")
            return
        }
        
        val currentTime = System.currentTimeMillis()
        val timeLimitMs = (timeLimit[packageName] ?: 0) * 60 * 1000L
        val currentUsage = usageTime[packageName] ?: 0L
        
        Log.d(TAG, "DEBUG HANDLE: App launched: $packageName, usage: ${currentUsage/1000/60}min, limit: ${timeLimitMs/1000/60}min")
        
        if (currentUsage >= timeLimitMs) {
            Log.d(TAG, "DEBUG HANDLE: App $packageName exceeded limit, blocking...")
            blockApp(packageName)
        } else {
            // Record launch time
            lastOpenTime[packageName] = currentTime
            Log.d(TAG, "DEBUG HANDLE: App $packageName within limit, allowing...")
        }
    }    private fun checkRunningApps() {
        try {
            // Method 1: Try getRunningTasks first (works on older Android)
            val activityManager = getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
            var currentApp: String? = null
            
            try {
                val runningTasks = activityManager.getRunningTasks(1)
                if (runningTasks.isNotEmpty()) {
                    currentApp = runningTasks[0].topActivity?.packageName
                    Log.d(TAG, "Method 1 - Currently running app: $currentApp")
                }
            } catch (e: SecurityException) {
                Log.w(TAG, "Method 1 failed: getRunningTasks requires GET_TASKS permission")
            }
            
            // Method 2: Use UsageStatsManager (works on newer Android)
            if (currentApp == null) {
                try {
                    val usageStatsManager = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
                    val currentTime = System.currentTimeMillis()
                    val stats = usageStatsManager.queryUsageStats(
                        UsageStatsManager.INTERVAL_BEST,
                        currentTime - 1000, // Last 1 second
                        currentTime
                    )
                    
                    val recentApp = stats.maxByOrNull { it.lastTimeUsed }
                    if (recentApp != null && currentTime - recentApp.lastTimeUsed < 3000) {
                        currentApp = recentApp.packageName
                        Log.d(TAG, "Method 2 - Currently running app: $currentApp")
                    }
                } catch (e: Exception) {
                    Log.w(TAG, "Method 2 failed: UsageStatsManager error: ${e.message}")
                }
            }
            
            // Process the detected app
            if (currentApp != null && 
                currentApp != OWN_PACKAGE_NAME &&
                !currentApp.startsWith("com.android") &&
                !currentApp.startsWith("android") &&
                !currentApp.contains("launcher") &&
                blockedPackages.contains(currentApp)) {
                
                Log.d(TAG, "Processing blocked app: $currentApp")
                handleAppUsage(currentApp)
                
                // Also check if should be blocked immediately
                val timeLimitMs = (timeLimit[currentApp] ?: 0) * 60 * 1000L
                val currentUsage = usageTime[currentApp] ?: 0L
                
                if (currentUsage >= timeLimitMs) {
                    Log.d(TAG, "App $currentApp over limit in monitoring, force blocking")
                    blockApp(currentApp)
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error checking running apps: ${e.message}")
        }
    }private fun handleAppUsage(packageName: String) {
        // Double-check that we're not processing our own app
        if (packageName == OWN_PACKAGE_NAME) {
            Log.d(TAG, "SAFETY: Ignoring usage tracking for our own app")
            return
        }
        
        val currentTime = System.currentTimeMillis()
        val lastTime = lastOpenTime[packageName]
        
        if (lastTime != null && currentTime - lastTime > 1000) {
            // App has been running for at least 1 second
            val sessionTime = currentTime - lastTime
            val totalUsage = (usageTime[packageName] ?: 0L) + sessionTime
            usageTime[packageName] = totalUsage
            
            Log.d(TAG, "App usage update: $packageName, session: ${sessionTime/1000}s, total: ${totalUsage/1000/60}min")
            
            // Check if exceeded time limit
            val timeLimitMs = (timeLimit[packageName] ?: 0) * 60 * 1000L
            if (totalUsage >= timeLimitMs) {
                Log.d(TAG, "App $packageName exceeded limit during usage, blocking...")
                blockApp(packageName)
            }
            
            lastOpenTime[packageName] = currentTime
        }
    }

    private fun updateUsageTime() {
        // Save usage time periodically
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
                .putString("app_usage_time", jsonArray.toString())
                .apply()
                
        } catch (e: Exception) {
            Log.e(TAG, "Error saving usage time: ${e.message}")
        }
    }    private fun blockApp(packageName: String) {
        // Critical safety check: NEVER block our own app
        if (packageName == OWN_PACKAGE_NAME) {
            Log.w(TAG, "CRITICAL SAFETY CHECK: Attempted to block our own app! Package: $packageName. Ignoring.")
            return
        }
        
        Log.d(TAG, "DEBUG BLOCK: Blocking app with overlay - Package: $packageName")
        Log.d(TAG, "DEBUG BLOCK: OWN_PACKAGE_NAME: $OWN_PACKAGE_NAME")
        
        try {
            Log.d(TAG, "DEBUG BLOCK: Starting overlay blocking for: $packageName")
            
            // Hiển thị overlay che toàn bộ app
            val overlayIntent = Intent(this, OverlayBlockingService::class.java).apply {
                putExtra("blocked_package", packageName)
                putExtra("app_name", getAppName(packageName))
            }
            startService(overlayIntent)
              // Continuous monitoring để duy trì overlay
            serviceScope.launch {
                var shouldContinue = true
                repeat(30) { // Monitor 60 giây
                    if (!shouldContinue) return@repeat
                    
                    delay(2000)
                    try {
                        val currentApp = getCurrentRunningApp()
                        if (currentApp == packageName) {
                            Log.d(TAG, "DEBUG BLOCK: Maintaining overlay for blocked app: $packageName")
                            // Đảm bảo overlay vẫn hiển thị
                            val refreshIntent = Intent(this@AppBlockingService, OverlayBlockingService::class.java).apply {
                                putExtra("blocked_package", packageName)
                                putExtra("app_name", getAppName(packageName))
                            }
                            startService(refreshIntent)
                        } else {
                            // App đã được đóng, dừng overlay
                            val stopIntent = Intent(this@AppBlockingService, OverlayBlockingService::class.java)
                            stopService(stopIntent)
                            shouldContinue = false
                        }
                    } catch (e: Exception) {
                        Log.w(TAG, "Error in continuous monitoring: ${e.message}")
                    }
                }
            }
            
            // Send notification to Flutter
            sendBlockingNotificationToFlutter(packageName)
            
            Log.d(TAG, "DEBUG BLOCK: Successfully started overlay blocking for: $packageName")
            
        } catch (e: Exception) {
            Log.e(TAG, "DEBUG BLOCK: Error blocking app $packageName: ${e.message}")
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
            null
        }
    }

    private fun getAppName(packageName: String): String {
        return try {
            val packageManager = packageManager
            val applicationInfo = packageManager.getApplicationInfo(packageName, 0)
            packageManager.getApplicationLabel(applicationInfo).toString()
        } catch (e: Exception) {
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
            Log.e(TAG, "Error sending notification to Flutter: ${e.message}")
        }
    }

    // Method to refresh blocked apps list (called from Flutter)
    fun refreshBlockedApps() {
        serviceScope.launch {
            loadBlockedApps()
        }
    }

    companion object {
        fun isServiceEnabled(context: Context): Boolean {
            val enabledServices = android.provider.Settings.Secure.getString(
                context.contentResolver,
                android.provider.Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES
            )
            
            val service = ComponentName(context, AppBlockingService::class.java)
            return enabledServices?.contains(service.flattenToString()) == true
        }
    }
}
