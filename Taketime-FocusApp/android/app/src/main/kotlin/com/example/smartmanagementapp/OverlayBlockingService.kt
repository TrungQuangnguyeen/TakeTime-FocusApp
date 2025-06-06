package com.example.smartmanagementapp

import android.app.Service
import android.content.Intent
import android.graphics.PixelFormat
import android.os.IBinder
import android.view.Gravity
import android.view.LayoutInflater
import android.view.View
import android.view.WindowManager
import android.widget.Button
import android.widget.TextView
import android.util.Log
import android.app.ActivityManager
import android.content.Context
import android.graphics.Color
import android.os.Handler
import android.os.Looper
import kotlinx.coroutines.*

class OverlayBlockingService : Service() {
    private var windowManager: WindowManager? = null
    private var overlayView: View? = null
    private val TAG = "OverlayBlockingService"
    private var blockedPackageName: String? = null
    private var appName: String? = null
    private var monitoringJob: Job? = null
    private val serviceScope = CoroutineScope(Dispatchers.Main + SupervisorJob())

    override fun onBind(intent: Intent?): IBinder? {
        return null
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        blockedPackageName = intent?.getStringExtra("blocked_package")
        appName = intent?.getStringExtra("app_name") ?: "Ứng dụng"
        
        Log.d(TAG, "Starting overlay for package: $blockedPackageName")
          if (blockedPackageName != null) {
            showOverlay()
            startMonitoring()
        }
        
        return START_STICKY
    }

    private fun showOverlay() {
        if (overlayView != null) {
            removeOverlay()
        }

        windowManager = getSystemService(Context.WINDOW_SERVICE) as WindowManager

        // Tạo overlay view
        overlayView = createOverlayView()        // Cấu hình layout parameters với flags để chặn hoàn toàn
        val params = WindowManager.LayoutParams(
            WindowManager.LayoutParams.MATCH_PARENT,
            WindowManager.LayoutParams.MATCH_PARENT,
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY,
            WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN or
                    WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                    WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON or
                    WindowManager.LayoutParams.FLAG_DISMISS_KEYGUARD or
                    WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON,
            PixelFormat.TRANSLUCENT
        )

        params.gravity = Gravity.CENTER

        try {
            windowManager?.addView(overlayView, params)
            Log.d(TAG, "Overlay added successfully")
        } catch (e: Exception) {
            Log.e(TAG, "Error adding overlay: ${e.message}")
        }
    }

    private fun createOverlayView(): View {
        // Tạo layout chính
        val layout = android.widget.LinearLayout(this).apply {
            orientation = android.widget.LinearLayout.VERTICAL
            setBackgroundColor(Color.parseColor("#CC000000")) // Nền đen trong suốt
            setPadding(60, 60, 60, 60)
            gravity = android.view.Gravity.CENTER
        }

        // Container nội dung chính
        val contentContainer = android.widget.LinearLayout(this).apply {
            orientation = android.widget.LinearLayout.VERTICAL
            setBackgroundColor(Color.WHITE)
            setPadding(40, 40, 40, 40)
            gravity = android.view.Gravity.CENTER
        }

        // Icon cảnh báo
        val iconView = android.widget.ImageView(this).apply {
            setImageResource(android.R.drawable.ic_dialog_alert)
            layoutParams = android.widget.LinearLayout.LayoutParams(120, 120).apply {
                gravity = android.view.Gravity.CENTER
                bottomMargin = 24
            }
        }

        // Tiêu đề
        val titleView = TextView(this).apply {
            text = "Thời gian sử dụng đã hết"
            textSize = 22f
            setTextColor(Color.parseColor("#D32F2F"))
            gravity = android.view.Gravity.CENTER
            typeface = android.graphics.Typeface.DEFAULT_BOLD
            layoutParams = android.widget.LinearLayout.LayoutParams(
                android.widget.LinearLayout.LayoutParams.WRAP_CONTENT,
                android.widget.LinearLayout.LayoutParams.WRAP_CONTENT
            ).apply {
                bottomMargin = 20
                gravity = android.view.Gravity.CENTER
            }
        }

        // Message chính
        val messageView = TextView(this).apply {
            text = "Ứng dụng \"$appName\" đã được sử dụng vượt quá thời gian cho phép trong hôm nay.\n\nHãy tập trung làm việc khác nhé!"
            textSize = 16f
            setTextColor(Color.parseColor("#424242"))
            gravity = android.view.Gravity.CENTER
            layoutParams = android.widget.LinearLayout.LayoutParams(
                android.widget.LinearLayout.LayoutParams.MATCH_PARENT,
                android.widget.LinearLayout.LayoutParams.WRAP_CONTENT
            ).apply {
                bottomMargin = 30
            }
        }

        // Nút thoát
        val exitButton = Button(this).apply {
            text = "Thoát ứng dụng"
            textSize = 16f
            setBackgroundColor(Color.parseColor("#D32F2F"))
            setTextColor(Color.WHITE)
            setPadding(40, 20, 40, 20)
            
            layoutParams = android.widget.LinearLayout.LayoutParams(
                android.widget.LinearLayout.LayoutParams.WRAP_CONTENT,
                android.widget.LinearLayout.LayoutParams.WRAP_CONTENT
            ).apply {
                gravity = android.view.Gravity.CENTER
            }
            
            setOnClickListener {
                Log.d(TAG, "Exit button clicked for package: $blockedPackageName")
                closeBlockedApp()
                removeOverlay()
            }
        }

        // Thêm các view vào container
        contentContainer.addView(iconView)
        contentContainer.addView(titleView)
        contentContainer.addView(messageView)
        contentContainer.addView(exitButton)
        
        layout.addView(contentContainer)

        return layout
    }

    private fun closeBlockedApp() {
        try {
            if (blockedPackageName != null) {
                // Force close app
                val activityManager = getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
                activityManager.killBackgroundProcesses(blockedPackageName!!)
                
                // Về home screen
                val homeIntent = Intent(Intent.ACTION_MAIN).apply {
                    addCategory(Intent.CATEGORY_HOME)
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK
                }
                startActivity(homeIntent)
                
                Log.d(TAG, "Closed blocked app: $blockedPackageName")
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error closing blocked app: ${e.message}")
        }    }

    private fun startMonitoring() {
        monitoringJob?.cancel()
        monitoringJob = serviceScope.launch {
            while (isActive) {
                try {
                    if (blockedPackageName != null && !isAppRunning(blockedPackageName!!)) {
                        Log.d(TAG, "Blocked app $blockedPackageName is no longer running, removing overlay")
                        removeOverlay()
                        stopSelf()
                        break
                    }
                    delay(2000) // Check every 2 seconds
                } catch (e: Exception) {
                    Log.e(TAG, "Error in monitoring: ${e.message}")
                }
            }
        }
    }

    private fun isAppRunning(packageName: String): Boolean {
        return try {
            val activityManager = getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
            val runningTasks = activityManager.getRunningTasks(10)
            runningTasks.any { it.topActivity?.packageName == packageName }
        } catch (e: Exception) {
            false
        }
    }

    private fun removeOverlay() {
        try {
            if (overlayView != null && windowManager != null) {
                windowManager?.removeView(overlayView)
                overlayView = null
                Log.d(TAG, "Overlay removed")
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error removing overlay: ${e.message}")
        }
    }    override fun onDestroy() {
        super.onDestroy()
        monitoringJob?.cancel()
        serviceScope.cancel()
        removeOverlay()
        Log.d(TAG, "OverlayBlockingService destroyed")
    }
}
