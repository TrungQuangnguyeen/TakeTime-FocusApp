# 🚀 Script Test Nhanh TakeTime App

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "🎯 TakeTime App - Test Script" -ForegroundColor Yellow
Write-Host "============================================" -ForegroundColor Cyan

# Kiểm tra Flutter
Write-Host "`n📱 Kiểm tra Flutter..." -ForegroundColor Green
flutter --version
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Flutter không được cài đặt!" -ForegroundColor Red
    exit 1
}

# Kiểm tra devices
Write-Host "`n📲 Kiểm tra thiết bị Android..." -ForegroundColor Green
flutter devices
$devices = flutter devices --machine | ConvertFrom-Json
$androidDevices = $devices | Where-Object { $_.platformType -eq "android" }

if ($androidDevices.Count -eq 0) {
    Write-Host "❌ Không tìm thấy thiết bị Android!" -ForegroundColor Red
    Write-Host "💡 Hãy khởi chạy emulator hoặc kết nối thiết bị thật" -ForegroundColor Yellow
    exit 1
}

Write-Host "✅ Tìm thấy $($androidDevices.Count) thiết bị Android" -ForegroundColor Green

# Build và cài đặt ứng dụng
Write-Host "`n🔨 Building ứng dụng..." -ForegroundColor Green
flutter build apk --debug

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Build thành công!" -ForegroundColor Green
    
    # Cài đặt APK
    Write-Host "`n📦 Cài đặt ứng dụng..." -ForegroundColor Green
    flutter install
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Cài đặt thành công!" -ForegroundColor Green
        
        # Hiển thị hướng dẫn test
        Write-Host "`n============================================" -ForegroundColor Cyan
        Write-Host "🎉 ỨNG DỤNG ĐÃ SẴN SÀNG!" -ForegroundColor Yellow
        Write-Host "============================================" -ForegroundColor Cyan
          Write-Host "`n📋 HƯỚNG DẪN TEST:" -ForegroundColor Green
        Write-Host "1. Mở ứng dụng TakeTime trên thiết bị" -ForegroundColor White
        Write-Host "2. Vào màn hình 'Blocked Apps'" -ForegroundColor White  
        Write-Host "3. Nhấn icon ⚙️ (settings) ở góc trên bên phải" -ForegroundColor White
        Write-Host "4. Cấp 3 quyền cần thiết:" -ForegroundColor White
        Write-Host "   - Usage Stats Permission" -ForegroundColor Yellow
        Write-Host "   - Display Over Other Apps" -ForegroundColor Yellow
        Write-Host "   - Accessibility Service" -ForegroundColor Yellow
        Write-Host "5. Nếu Accessibility không work:" -ForegroundColor Red
        Write-Host "   - Nhấn 'Debug Accessibility Service'" -ForegroundColor Yellow
        Write-Host "   - Xem thông tin debug chi tiết" -ForegroundColor Yellow
        Write-Host "   - Làm theo hướng dẫn khắc phục" -ForegroundColor Yellow
        Write-Host "6. Thêm ứng dụng vào danh sách chặn" -ForegroundColor White
        Write-Host "7. Đặt thời gian giới hạn" -ForegroundColor White
        Write-Host "8. Test mở ứng dụng đó → Sẽ bị chặn!" -ForegroundColor White
          Write-Host "`n📂 TÀI LIỆU THAM KHẢO:" -ForegroundColor Green
        Write-Host "- ACCESSIBILITY_TROUBLESHOOTING.md" -ForegroundColor Yellow
        Write-Host "- EMULATOR_PERMISSION_STEP_BY_STEP.md" -ForegroundColor Yellow
        Write-Host "- COMPLETE_SETUP_GUIDE.md" -ForegroundColor Yellow
        Write-Host "- TESTING_GUIDE.md" -ForegroundColor Yellow
        
        Write-Host "`n🔍 KIỂM TRA LOG:" -ForegroundColor Green
        Write-Host "flutter logs --device-id=<device_id>" -ForegroundColor Yellow
        
    } else {
        Write-Host "❌ Cài đặt thất bại!" -ForegroundColor Red
    }
} else {
    Write-Host "❌ Build thất bại!" -ForegroundColor Red
    Write-Host "💡 Kiểm tra lỗi và chạy lại: flutter pub get" -ForegroundColor Yellow
}

Write-Host "`n============================================" -ForegroundColor Cyan
Write-Host "🎯 Test Script Hoàn Tất" -ForegroundColor Yellow  
Write-Host "============================================" -ForegroundColor Cyan
