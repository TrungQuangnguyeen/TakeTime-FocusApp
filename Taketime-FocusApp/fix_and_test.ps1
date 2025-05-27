# Script để kiểm tra và sửa lỗi compilation
Write-Host "=== KIỂM TRA VÀ SỬA LỖI COMPILATION ===" -ForegroundColor Cyan

Write-Host "`nBước 1: Làm sạch build cache..." -ForegroundColor Yellow
flutter clean

Write-Host "`nBước 2: Kiểm tra lỗi cú pháp..." -ForegroundColor Yellow
flutter analyze

Write-Host "`nBước 3: Thử build ứng dụng..." -ForegroundColor Yellow
flutter build apk --debug

if ($LASTEXITCODE -eq 0) {
    Write-Host "`n✅ BUILD THÀNH CÔNG!" -ForegroundColor Green
    Write-Host "Lỗi Kotlin đã được sửa thành công!" -ForegroundColor Green
    
    Write-Host "`nCài đặt ứng dụng..." -ForegroundColor Yellow
    flutter install
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "`n✅ CÀI ĐẶT THÀNH CÔNG!" -ForegroundColor Green
        Write-Host "`nHướng dẫn test nhanh:" -ForegroundColor Cyan
        Write-Host "1. Mở ứng dụng TakeTime trên thiết bị" -ForegroundColor White
        Write-Host "2. Vào mục 'Ứng dụng bị chặn'" -ForegroundColor White
        Write-Host "3. Thêm một ứng dụng test với giới hạn 1 phút" -ForegroundColor White
        Write-Host "4. Sử dụng ứng dụng đó hơn 1 phút" -ForegroundColor White
        Write-Host "5. Thử mở lại ứng dụng đó -> sẽ thấy overlay chặn" -ForegroundColor White
    } else {
        Write-Host "`n❌ Lỗi cài đặt ứng dụng" -ForegroundColor Red
    }
} else {
    Write-Host "`n❌ VẪN CÒN LỖI BUILD!" -ForegroundColor Red
    Write-Host "Vui lòng kiểm tra thông báo lỗi ở trên" -ForegroundColor Yellow
}
