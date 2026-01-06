package com.example.smartmanagementapp

import android.app.Activity
import android.content.Intent
import android.content.SharedPreferences
import android.os.Bundle
import android.view.WindowManager
import android.widget.Button
import android.widget.FrameLayout
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.TextView
import android.graphics.Color
import java.text.SimpleDateFormat
import java.util.*

class AppBlockedActivity : Activity() {
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        val blockedPackage = intent.getStringExtra("blocked_package")
        
        // Kiểm tra xem ứng dụng này đã show popup hôm nay chưa
        if (blockedPackage != null && isAlreadyShownToday(blockedPackage)) {
            // Nếu đã show rồi, đóng activity và quay về home
            val homeIntent = Intent(Intent.ACTION_MAIN).apply {
                addCategory(Intent.CATEGORY_HOME)
                flags = Intent.FLAG_ACTIVITY_NEW_TASK
            }
            startActivity(homeIntent)
            finish()
            return
        }
        
        // Lưu trạng thái đã show popup
        if (blockedPackage != null) {
            markAsShownToday(blockedPackage)
        }
        
        // Make this a full-screen overlay
        window.setFlags(
            WindowManager.LayoutParams.FLAG_FULLSCREEN or
            WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
            WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON or
            WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON or
            WindowManager.LayoutParams.FLAG_DISMISS_KEYGUARD,
            WindowManager.LayoutParams.FLAG_FULLSCREEN or
            WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
            WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON or
            WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON or
            WindowManager.LayoutParams.FLAG_DISMISS_KEYGUARD
        )
        
        setContentView(createBlockingView())
        overridePendingTransition(0, 0)
        
        android.util.Log.d("AppBlockedActivity", "Blocking screen shown for: $blockedPackage")
    }

    private fun createBlockingView(): LinearLayout {
        val layout = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setBackgroundColor(Color.WHITE)
            setPadding(32, 48, 32, 48)
            gravity = android.view.Gravity.CENTER
        }

        // Icon container with rounded background
        val iconContainer = FrameLayout(this).apply {
            setBackgroundColor(Color.parseColor("#FFE5E5"))
            layoutParams = LinearLayout.LayoutParams(100, 100).apply {
                gravity = android.view.Gravity.CENTER
                bottomMargin = 24
            }
            clipToOutline = true
            // Create rounded outline manually
            outlineProvider = object : android.view.ViewOutlineProvider() {
                override fun getOutline(view: android.view.View, outline: android.graphics.Outline) {
                    outline.setRoundRect(0, 0, view.width, view.height, 50f)
                }
            }
        }
        
        val iconView = ImageView(this).apply {
            setImageResource(android.R.drawable.ic_menu_view)
            setColorFilter(Color.parseColor("#E53935"))
            layoutParams = FrameLayout.LayoutParams(60, 60).apply {
                gravity = android.view.Gravity.CENTER
            }
        }
        iconContainer.addView(iconView)

        // Title
        val titleView = TextView(this).apply {
            text = "Ứng dụng đã khóa"
            textSize = 20f
            setTextColor(Color.parseColor("#212121"))
            gravity = android.view.Gravity.CENTER
            typeface = android.graphics.Typeface.DEFAULT_BOLD
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            ).apply {
                bottomMargin = 12
            }
        }

        val appName = intent.getStringExtra("app_name") ?: "Ứng dụng"
        val timeLimit = intent.getIntExtra("time_limit", 0)
        
        // Message
        val messageView = TextView(this).apply {
            text = "Bạn đã sử dụng \"$appName\" hết thời gian cho phép ($timeLimit phút)"
            textSize = 14f
            setTextColor(Color.parseColor("#616161"))
            gravity = android.view.Gravity.CENTER
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            ).apply {
                bottomMargin = 8
            }
        }
        
        // Subtitle
        val subtitleView = TextView(this).apply {
            text = "Quay lại TakeTime để đặt lại thời gian"
            textSize = 13f
            setTextColor(Color.parseColor("#9E9E9E"))
            gravity = android.view.Gravity.CENTER
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            ).apply {
                bottomMargin = 32
            }
        }

        // OK Button
        val okButton = Button(this).apply {
            text = "Được rồi"
            setBackgroundColor(Color.parseColor("#6C5CE7"))
            setTextColor(Color.WHITE)
            textSize = 15f
            setPadding(0, 14, 0, 14)
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            )
            setOnClickListener {
                val homeIntent = Intent(Intent.ACTION_MAIN).apply {
                    addCategory(Intent.CATEGORY_HOME)
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK
                }
                startActivity(homeIntent)
                finish()
            }
        }

        layout.addView(iconContainer)
        layout.addView(titleView)
        layout.addView(messageView)
        layout.addView(subtitleView)
        layout.addView(okButton)

        return layout
    }

    private fun isAlreadyShownToday(packageName: String): Boolean {
        val prefs = getSharedPreferences("BlockedAppsState", MODE_PRIVATE)
        val today = SimpleDateFormat("yyyy-MM-dd", Locale.US).format(Date())
        val key = "blocked_$packageName"
        val lastDate = prefs.getString(key, "")
        return lastDate == today
    }

    private fun markAsShownToday(packageName: String) {
        val prefs = getSharedPreferences("BlockedAppsState", MODE_PRIVATE)
        val today = SimpleDateFormat("yyyy-MM-dd", Locale.US).format(Date())
        val key = "blocked_$packageName"
        prefs.edit().putString(key, today).apply()
    }

    override fun onBackPressed() {
        val homeIntent = Intent(Intent.ACTION_MAIN).apply {
            addCategory(Intent.CATEGORY_HOME)
            flags = Intent.FLAG_ACTIVITY_NEW_TASK
        }
        startActivity(homeIntent)
        finish()
    }

    override fun onPause() {
        super.onPause()
        finish()
    }

    override fun onWindowFocusChanged(hasFocus: Boolean) {
        super.onWindowFocusChanged(hasFocus)
        if (!hasFocus) {
            val intent = Intent(this, AppBlockedActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or 
                        Intent.FLAG_ACTIVITY_CLEAR_TOP or
                        Intent.FLAG_ACTIVITY_SINGLE_TOP
                putExtras(getIntent().extras ?: Bundle())
            }
            startActivity(intent)
        }
    }
}
