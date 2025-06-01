package com.example.smartmanagementapp

import android.app.Activity
import android.content.Intent
import android.os.Bundle
import android.view.View
import android.view.WindowManager
import android.widget.Button
import android.widget.TextView

class AppBlockedActivity : Activity() {
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // Make this a full-screen overlay that can't be dismissed
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
        
        // Prevent going back
        overridePendingTransition(0, 0)
        
        // Log that blocking screen is shown
        android.util.Log.d("AppBlockedActivity", "Blocking screen shown for: ${intent.getStringExtra("blocked_package")}")
    }

    private fun createBlockingView(): View {
        // Create the blocking UI programmatically
        val layout = android.widget.LinearLayout(this).apply {
            orientation = android.widget.LinearLayout.VERTICAL
            setBackgroundColor(android.graphics.Color.parseColor("#FF1744"))
            setPadding(64, 64, 64, 64)
            gravity = android.view.Gravity.CENTER
        }

        // App blocked icon
        val iconView = android.widget.ImageView(this).apply {
            setImageResource(android.R.drawable.ic_delete) // Use system icon
            layoutParams = android.widget.LinearLayout.LayoutParams(200, 200).apply {
                gravity = android.view.Gravity.CENTER
                bottomMargin = 32
            }
        }

        // Title
        val titleView = TextView(this).apply {
            text = "Ứng dụng bị chặn"
            textSize = 24f
            setTextColor(android.graphics.Color.WHITE)
            gravity = android.view.Gravity.CENTER
            typeface = android.graphics.Typeface.DEFAULT_BOLD
            layoutParams = android.widget.LinearLayout.LayoutParams(
                android.widget.LinearLayout.LayoutParams.WRAP_CONTENT,
                android.widget.LinearLayout.LayoutParams.WRAP_CONTENT
            ).apply {
                bottomMargin = 24
                gravity = android.view.Gravity.CENTER
            }
        }

        // App info
        val appName = intent.getStringExtra("app_name") ?: "Ứng dụng"
        val timeLimit = intent.getIntExtra("time_limit", 0)
        val usageTime = intent.getLongExtra("usage_time", 0)
        
        val messageView = TextView(this).apply {
            text = "Bạn đã sử dụng \"$appName\" quá thời gian cho phép hôm nay.\n\n" +
                   "Thời gian sử dụng: $usageTime phút\n" +
                   "Giới hạn: $timeLimit phút\n\n" +
                   "Thử lại vào ngày mai hoặc thay đổi giới hạn thời gian."
            textSize = 16f
            setTextColor(android.graphics.Color.WHITE)
            gravity = android.view.Gravity.CENTER
            layoutParams = android.widget.LinearLayout.LayoutParams(
                android.widget.LinearLayout.LayoutParams.MATCH_PARENT,
                android.widget.LinearLayout.LayoutParams.WRAP_CONTENT
            ).apply {
                bottomMargin = 48
            }
        }

        // Buttons container
        val buttonContainer = android.widget.LinearLayout(this).apply {
            orientation = android.widget.LinearLayout.HORIZONTAL
            gravity = android.view.Gravity.CENTER
            layoutParams = android.widget.LinearLayout.LayoutParams(
                android.widget.LinearLayout.LayoutParams.MATCH_PARENT,
                android.widget.LinearLayout.LayoutParams.WRAP_CONTENT
            )
        }

        // OK Button
        val okButton = Button(this).apply {
            text = "Đã hiểu"
            setBackgroundColor(android.graphics.Color.WHITE)
            setTextColor(android.graphics.Color.parseColor("#FF1744"))
            layoutParams = android.widget.LinearLayout.LayoutParams(
                android.widget.LinearLayout.LayoutParams.WRAP_CONTENT,
                android.widget.LinearLayout.LayoutParams.WRAP_CONTENT
            ).apply {
                rightMargin = 24
            }
            setOnClickListener {
                // Go to home screen
                val homeIntent = Intent(Intent.ACTION_MAIN).apply {
                    addCategory(Intent.CATEGORY_HOME)
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK
                }
                startActivity(homeIntent)
                finish()
            }
        }

        // Settings Button
        val settingsButton = Button(this).apply {
            text = "Cài đặt"
            setBackgroundColor(android.graphics.Color.parseColor("#FFAB40"))
            setTextColor(android.graphics.Color.WHITE)
            layoutParams = android.widget.LinearLayout.LayoutParams(
                android.widget.LinearLayout.LayoutParams.WRAP_CONTENT,
                android.widget.LinearLayout.LayoutParams.WRAP_CONTENT
            )
            setOnClickListener {
                // Open the main app
                val mainIntent = packageManager.getLaunchIntentForPackage("com.example.smartmanagementapp")
                if (mainIntent != null) {
                    mainIntent.flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                    startActivity(mainIntent)
                }
                finish()
            }
        }

        buttonContainer.addView(okButton)
        buttonContainer.addView(settingsButton)

        layout.addView(iconView)
        layout.addView(titleView)
        layout.addView(messageView)
        layout.addView(buttonContainer)

        return layout
    }

    override fun onBackPressed() {
        // Prevent going back - do nothing
        // Or optionally go to home screen
        val homeIntent = Intent(Intent.ACTION_MAIN).apply {
            addCategory(Intent.CATEGORY_HOME)
            flags = Intent.FLAG_ACTIVITY_NEW_TASK
        }
        startActivity(homeIntent)
        finish()
    }

    override fun onPause() {
        super.onPause()
        // Don't allow this activity to be paused unless going to our main app or home
        android.util.Log.d("AppBlockedActivity", "Activity paused, finishing")
        finish()
    }

    override fun onDestroy() {
        super.onDestroy()
        android.util.Log.d("AppBlockedActivity", "Blocking activity destroyed")
    }

    // Prevent recent apps button from bypassing
    override fun onWindowFocusChanged(hasFocus: Boolean) {
        super.onWindowFocusChanged(hasFocus)
        if (!hasFocus) {
            android.util.Log.d("AppBlockedActivity", "Window lost focus, bringing to front")
            // Bring this activity back to front
            val intent = Intent(this, AppBlockedActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or 
                        Intent.FLAG_ACTIVITY_CLEAR_TOP or
                        Intent.FLAG_ACTIVITY_SINGLE_TOP
                // Copy extras from current intent
                putExtras(getIntent().extras ?: Bundle())
            }
            startActivity(intent)
        }
    }
}
