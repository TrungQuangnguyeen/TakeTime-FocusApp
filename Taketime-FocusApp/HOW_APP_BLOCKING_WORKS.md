# CÁCH THỨC HOẠT ĐỘNG HỆ THỐNG CHẶN ỨNG DỤNG TAKETIME

## 📋 TỔNG QUAN KIẾN TRÚC

Hệ thống chặn ứng dụng của TakeTime sử dụng **Android Accessibility Service** kết hợp với **Usage Stats API** để theo dõi và chặn các ứng dụng khi vượt quá thời gian sử dụng.

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Flutter App   │◄──►│ Method Channel   │◄──►│ Android Native  │
│ (Dart/Flutter)  │    │   (Bridge)       │    │ (Kotlin/Java)   │
└─────────────────┘    └──────────────────┘    └─────────────────┘
         │                                               │
         ▼                                               ▼
┌─────────────────┐                            ┌─────────────────┐
│  UI Components  │                            │ AppBlocking     │
│ - Blocked Apps  │                            │ Service         │
│ - Time Limits   │                            │ (Accessibility) │
│ - Settings      │                            └─────────────────┘
└─────────────────┘                                     │
                                                        ▼
                                               ┌─────────────────┐
                                               │ AppBlocked      │
                                               │ Activity        │
                                               │ (Blocking UI)   │
                                               └─────────────────┘
```

---

## 🔧 CÁC THÀNH PHẦN CHÍNH

### 1. **Flutter Layer (Dart)**
- **`blocked_app_screen.dart`**: Giao diện quản lý ứng dụng bị chặn
- **`AppBlockingService.dart`**: Bridge để giao tiếp với Android native
- **Shared Preferences**: Lưu trữ cài đặt thời gian và trạng thái

### 2. **Android Native Layer (Kotlin)**
- **`MainActivity.kt`**: Method channel handler
- **`AppBlockingService.kt`**: Accessibility Service chính
- **`AppBlockedActivity.kt`**: Màn hình chặn ứng dụng
- **`AndroidManifest.xml`**: Khai báo permissions và services

---

## 🚀 QUY TRÌNH HOẠT ĐỘNG CHI TIẾT

### **BƯỚC 1: Khởi tạo và cấu hình**

```dart
// 1. User thiết lập thời gian giới hạn cho ứng dụng
timeLimit[packageName] = 60; // 60 phút

// 2. Bật chặn cho ứng dụng
blockedPackages.add(packageName);

// 3. Lưu vào SharedPreferences
await _saveBlockedApps();

// 4. Khởi động Accessibility Service
await AppBlockingService.startAppBlockingService();
```

### **BƯỚC 2: Accessibility Service khởi động**

```kotlin
// AppBlockingService.kt
override fun onServiceConnected() {
    // Cấu hình service để lắng nghe sự kiện
    val info = AccessibilityServiceInfo().apply {
        eventTypes = AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED or 
                    AccessibilityEvent.TYPE_WINDOW_CONTENT_CHANGED
        feedbackType = AccessibilityServiceInfo.FEEDBACK_GENERIC
    }
    
    // Load danh sách ứng dụng bị chặn từ SharedPreferences
    loadBlockedApps()
    
    // Bắt đầu monitoring
    startMonitoring()
}
```

### **BƯỚC 3: Monitoring liên tục**

```kotlin
private fun startMonitoring() {
    monitoringJob = serviceScope.launch {
        while (isActive) {
            try {
                checkRunningApps()     // Kiểm tra ứng dụng đang chạy
                updateUsageTime()      // Cập nhật thời gian sử dụng
                delay(1000)           // Check mỗi 1 giây
            } catch (e: Exception) {
                Log.e(TAG, "Error in monitoring: ${e.message}")
            }
        }
    }
}
```

### **BƯỚC 4: Phát hiện ứng dụng (Dual Detection)**

```kotlin
private fun checkRunningApps() {
    var currentApp: String? = null
    
    // PHƯƠNG THỨC 1: getRunningTasks (Android cũ)
    try {
        val runningTasks = activityManager.getRunningTasks(1)
        if (runningTasks.isNotEmpty()) {
            currentApp = runningTasks[0].topActivity?.packageName
        }
    } catch (e: SecurityException) {
        // Fallback sang phương thức 2
    }
    
    // PHƯƠNG THỨC 2: UsageStatsManager (Android mới)
    if (currentApp == null) {
        val usageStatsManager = getSystemService(Context.USAGE_STATS_SERVICE)
        val stats = usageStatsManager.queryUsageStats(
            UsageStatsManager.INTERVAL_BEST,
            System.currentTimeMillis() - 1000,
            System.currentTimeMillis()
        )
        currentApp = stats.maxByOrNull { it.lastTimeUsed }?.packageName
    }
    
    // Xử lý ứng dụng được phát hiện
    if (currentApp != null && blockedPackages.contains(currentApp)) {
        handleAppUsage(currentApp)
    }
}
```

### **BƯỚC 5: Tracking thời gian sử dụng**

```kotlin
private fun handleAppUsage(packageName: String) {
    val currentTime = System.currentTimeMillis()
    val lastTime = lastOpenTime[packageName]
    
    if (lastTime != null && currentTime - lastTime > 1000) {
        // Tính thời gian session
        val sessionTime = currentTime - lastTime
        val totalUsage = (usageTime[packageName] ?: 0L) + sessionTime
        usageTime[packageName] = totalUsage
        
        // Kiểm tra có vượt giới hạn không
        val timeLimitMs = (timeLimit[packageName] ?: 0) * 60 * 1000L
        if (totalUsage >= timeLimitMs) {
            blockApp(packageName)  // CHẶN NGAY
        }
        
        lastOpenTime[packageName] = currentTime
    }
}
```

### **BƯỚC 6: Chặn ứng dụng (Multi-layer Blocking)**

```kotlin
private fun blockApp(packageName: String) {
    // LAYER 1: Force kill ứng dụng
    try {
        activityManager.killBackgroundProcesses(packageName)
    } catch (e: Exception) { /* Ignore */ }
    
    // LAYER 2: Đưa về home screen
    val homeIntent = Intent(Intent.ACTION_MAIN).apply {
        addCategory(Intent.CATEGORY_HOME)
        flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
    }
    startActivity(homeIntent)
    
    // LAYER 3: Hiển thị màn hình chặn
    val blockIntent = Intent(this, AppBlockedActivity::class.java).apply {
        flags = Intent.FLAG_ACTIVITY_NEW_TASK or 
                Intent.FLAG_ACTIVITY_CLEAR_TOP or
                Intent.FLAG_ACTIVITY_SINGLE_TOP or
                Intent.FLAG_ACTIVITY_NO_HISTORY
        putExtra("blocked_package", packageName)
        putExtra("app_name", getAppName(packageName))
        putExtra("time_limit", timeLimit[packageName])
    }
    startActivity(blockIntent)
    
    // LAYER 4: Continuous monitoring (ngăn reopen)
    serviceScope.launch {
        repeat(10) { // Monitor 20 giây
            delay(2000)
            val current = getCurrentRunningApp()
            if (current == packageName) {
                // Force close lại nếu user cố mở
                startActivity(homeIntent)
                startActivity(blockIntent)
            }
        }
    }
}
```

### **BƯỚC 7: Màn hình chặn (Protected Overlay)**

```kotlin
// AppBlockedActivity.kt
override fun onCreate(savedInstanceState: Bundle?) {
    // Thiết lập window flags mạnh mẽ
    window.setFlags(
        WindowManager.LayoutParams.FLAG_FULLSCREEN or
        WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
        WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON or
        WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON or
        WindowManager.LayoutParams.FLAG_DISMISS_KEYGUARD
    )
    
    setContentView(createBlockingView())
}

// Ngăn bypass qua recent apps
override fun onWindowFocusChanged(hasFocus: Boolean) {
    if (!hasFocus) {
        // Tự động restart activity
        val intent = Intent(this, AppBlockedActivity::class.java)
        startActivity(intent)
    }
}

// Ngăn back button
override fun onBackPressed() {
    val homeIntent = Intent(Intent.ACTION_MAIN).apply {
        addCategory(Intent.CATEGORY_HOME)
        flags = Intent.FLAG_ACTIVITY_NEW_TASK
    }
    startActivity(homeIntent)
    finish()
}
```

---

## 🔑 PERMISSIONS CẦN THIẾT

### 1. **Usage Stats Permission**
```xml
<uses-permission android:name="android.permission.PACKAGE_USAGE_STATS" />
```
- **Mục đích**: Truy cập thống kê sử dụng ứng dụng
- **Cách cấp**: Settings → Apps → Special Access → Usage Access

### 2. **Accessibility Service Permission**
```xml
<uses-permission android:name="android.permission.BIND_ACCESSIBILITY_SERVICE" />
```
- **Mục đích**: Chạy background service, nhận sự kiện hệ thống
- **Cách cấp**: Settings → Accessibility → TakeTime App Blocking

### 3. **System Alert Window Permission**
```xml
<uses-permission android:name="android.permission.SYSTEM_ALERT_WINDOW" />
```
- **Mục đích**: Hiển thị overlay trên các ứng dụng khác
- **Cách cấp**: Settings → Apps → Special Permissions → Display over other apps

---

## ⚡ CÁC CẢI TIẾN ĐÃ THỰC HIỆN

### **Vấn đề cũ:**
- ❌ Chỉ dùng `getRunningTasks()` (không hoạt động trên Android mới)
- ❌ Chặn yếu (chỉ về home screen)
- ❌ Check chậm (2 giây/lần)
- ❌ Overlay dễ bypass

### **Giải pháp mới:**
- ✅ **Dual Detection**: `getRunningTasks()` + `UsageStatsManager`
- ✅ **Multi-layer Blocking**: Force kill + Home + Overlay + Continuous monitoring
- ✅ **Faster Response**: 1 giây/lần thay vì 2 giây
- ✅ **Protected Overlay**: Window focus protection + bypass prevention

---

## 🔍 CÁCH DEBUG

```bash
# Xem logs của AppBlockingService
adb logcat | findstr AppBlockingService

# Xem logs của AppBlockedActivity  
adb logcat | findstr AppBlockedActivity

# Xem tất cả logs của app
adb logcat | findstr com.example.smartmanagementapp
```

---

## 📊 FLOW CHART TỔNG THỂ

```
[User sets time limit] 
        ↓
[App saves to SharedPreferences]
        ↓
[Accessibility Service loads settings]
        ↓
[Service monitors running apps every 1s]
        ↓
[Detects target app launch]
        ↓
[Tracks usage time]
        ↓
[Usage > Limit?] ──No──► [Continue monitoring]
        ↓ Yes
[Multi-layer blocking:]
├─ Force kill app
├─ Go to home screen  
├─ Show blocking overlay
└─ Continuous monitoring (20s)
        ↓
[User sees red blocking screen]
        ↓
[User can only go to home or TakeTime app]
```

Đây là cách hệ thống chặn ứng dụng hoạt động một cách chi tiết và mạnh mẽ!
