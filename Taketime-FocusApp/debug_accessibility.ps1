# 🐛 Test Accessibility Service Debug Script

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "🔍 Accessibility Service Debug Test" -ForegroundColor Yellow
Write-Host "============================================" -ForegroundColor Cyan

# Kiểm tra devices
Write-Host "`n📲 Kiểm tra thiết bị..." -ForegroundColor Green
flutter devices
$devices = flutter devices --machine | ConvertFrom-Json
$androidDevices = $devices | Where-Object { $_.platformType -eq "android" }

if ($androidDevices.Count -eq 0) {
    Write-Host "❌ Không tìm thấy thiết bị Android!" -ForegroundColor Red
    Write-Host "💡 Hãy khởi chạy emulator hoặc kết nối thiết bị thật" -ForegroundColor Yellow
    exit 1
}

Write-Host "✅ Tìm thấy $($androidDevices.Count) thiết bị Android" -ForegroundColor Green

# Install APK
Write-Host "`n📦 Cài đặt ứng dụng..." -ForegroundColor Green
$apkPath = "build\app\outputs\flutter-apk\app-debug.apk"

if (Test-Path $apkPath) {
    flutter install
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Cài đặt thành công!" -ForegroundColor Green
        
        # Launch app
        Write-Host "`n🚀 Khởi chạy ứng dụng..." -ForegroundColor Green
        adb shell am start -n com.example.smartmanagementapp/.MainActivity
        
        Write-Host "`n============================================" -ForegroundColor Cyan
        Write-Host "🎯 TEST ACCESSIBILITY SERVICE" -ForegroundColor Yellow
        Write-Host "============================================" -ForegroundColor Cyan
        
        Write-Host "`n📋 HƯỚNG DẪN TEST TỪNG BƯỚC:" -ForegroundColor Green
        Write-Host "1. Ứng dụng TakeTime đã được mở" -ForegroundColor White
        Write-Host "2. Vào màn hình 'Blocked Apps'" -ForegroundColor White
        Write-Host "3. Nhấn icon ⚙️ ở góc trên phải" -ForegroundColor White
        Write-Host "4. Trong Permission Setup:" -ForegroundColor White
        Write-Host "   - Cấp Usage Stats Permission" -ForegroundColor Yellow
        Write-Host "   - Cấp Display Over Other Apps" -ForegroundColor Yellow
        Write-Host "   - Cấp Accessibility Service" -ForegroundColor Yellow
        
        Write-Host "`n🔧 NẾU GẶP VẤN ĐỀ VỚI ACCESSIBILITY:" -ForegroundColor Red
        Write-Host "1. Scroll xuống cuối Permission Setup screen" -ForegroundColor White
        Write-Host "2. Nhấn 'Debug Accessibility Service'" -ForegroundColor Yellow
        Write-Host "3. Xem thông tin debug chi tiết:" -ForegroundColor White
        Write-Host "   - Package name" -ForegroundColor Gray
        Write-Host "   - Service name" -ForegroundColor Gray
        Write-Host "   - Enabled services" -ForegroundColor Gray
        Write-Host "   - Check results" -ForegroundColor Gray
        Write-Host "4. Làm theo hướng dẫn trong debug screen" -ForegroundColor White
        
        Write-Host "`n🎯 CÁC BƯỚC KHẮC PHỤC THÔNG THƯỜNG:" -ForegroundColor Green
        Write-Host "1. Settings → Accessibility" -ForegroundColor White
        Write-Host "2. Tìm 'TakeTime' hoặc 'App Blocking Service'" -ForegroundColor White
        Write-Host "3. TẮT toggle → Đợi 3 giây → BẬT lại" -ForegroundColor Yellow
        Write-Host "4. Force close TakeTime app → Mở lại" -ForegroundColor White
        Write-Host "5. Kiểm tra icon ⚙️ chuyển từ 🟠 sang 🟢" -ForegroundColor White
        
        Write-Host "`n✅ KIỂM TRA THÀNH CÔNG KHI:" -ForegroundColor Green
        Write-Host "- Icon ⚙️ màu xanh trong Blocked Apps" -ForegroundColor White
        Write-Host "- Tất cả 3 quyền hiện 'Enabled' trong Debug screen" -ForegroundColor White
        Write-Host "- Có thể thêm ứng dụng vào danh sách chặn" -ForegroundColor White
        
        Write-Host "`n🔍 MONITOR LOG (Terminal mới):" -ForegroundColor Green
        Write-Host "flutter logs --device-id=$($androidDevices[0].id)" -ForegroundColor Yellow
        
        Write-Host "`n📂 TÀI LIỆU THAM KHẢO:" -ForegroundColor Green
        Write-Host "- ACCESSIBILITY_TROUBLESHOOTING.md" -ForegroundColor Yellow
        Write-Host "- EMULATOR_PERMISSION_STEP_BY_STEP.md" -ForegroundColor Yellow
        
    } else {
        Write-Host "❌ Cài đặt thất bại!" -ForegroundColor Red
    }
} else {
    Write-Host "❌ Không tìm thấy APK!" -ForegroundColor Red
    Write-Host "💡 Chạy: flutter build apk --debug" -ForegroundColor Yellow
}

Write-Host "`n============================================" -ForegroundColor Cyan
Write-Host "🔍 Debug Test Hoàn Tất" -ForegroundColor Yellow
Write-Host "============================================" -ForegroundColor Cyan
