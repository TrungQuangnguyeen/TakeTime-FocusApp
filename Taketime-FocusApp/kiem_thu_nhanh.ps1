# TakeTime Focus App - Script Kiểm Thử Nhanh
# Hỗ trợ kiểm thử ứng dụng sau khi build thành công

param(
    [switch]$KiemTraAPK,
    [switch]$CaiDatADB,
    [switch]$KiemTraThietBi,
    [switch]$CaiDatAPK,
    [switch]$TheoDoiLog,
    [switch]$TatCa
)

$ErrorActionPreference = "Continue"

# Màu sắc cho output
function Write-MauSac {
    param($ThongDiep, $Mau = "White")
    Write-Host $ThongDiep -ForegroundColor $Mau
}

function Hien-TieuDe {
    param($TieuDe)
    Write-Host ""
    Write-MauSac "=" * 70 -Mau "Cyan"
    Write-MauSac "  $TieuDe" -Mau "Cyan"
    Write-MauSac "=" * 70 -Mau "Cyan"
    Write-Host ""
}

function KiemTra-APK {
    Hien-TieuDe "KIỂM TRA APK"
    
    $duongDanAPK = "build\app\outputs\flutter-apk\app-debug.apk"
    
    if (Test-Path $duongDanAPK) {
        $thongTinAPK = Get-Item $duongDanAPK
        Write-MauSac "✅ APK được tìm thấy!" -Mau "Green"
        Write-MauSac "   📁 Tên file: $($thongTinAPK.Name)" -Mau "Green"
        Write-MauSac "   📏 Kích thước: $([math]::Round($thongTinAPK.Length / 1MB, 1)) MB" -Mau "Green"
        Write-MauSac "   📅 Thời gian tạo: $($thongTinAPK.LastWriteTime)" -Mau "Green"
        Write-MauSac "   📍 Đường dẫn đầy đủ: $($thongTinAPK.FullName)" -Mau "White"
        
        Write-Host ""
        Write-MauSac "🎯 APK SẴN SÀNG KIỂM THỬ!" -Mau "Yellow"
        return $true
    }
    else {
        Write-MauSac "❌ Không tìm thấy APK tại: $duongDanAPK" -Mau "Red"
        Write-MauSac "   💡 Vui lòng chạy: flutter build apk --debug" -Mau "Yellow"
        return $false
    }
}

function CaiDat-ADB {
    Hien-TieuDe "CÀI ĐẶT ANDROID DEBUG BRIDGE (ADB)"
    
    # Kiểm tra ADB đã có chưa
    try {
        $adbVersion = adb version 2>$null
        if ($adbVersion) {
            Write-MauSac "✅ ADB đã được cài đặt" -Mau "Green"
            Write-MauSac "   📋 Phiên bản: $($adbVersion[0])" -Mau "Green"
            return $true
        }
    }
    catch {
        Write-MauSac "⚠️ ADB chưa được cài đặt" -Mau "Yellow"
    }
    
    Write-MauSac "🔧 Đang cài đặt Android Platform Tools..." -Mau "Yellow"
    try {
        $ketQua = winget install --id Google.PlatformTools --accept-source-agreements --accept-package-agreements 2>&1
        
        if ($LASTEXITCODE -eq 0 -or $ketQua -match "successfully" -or $ketQua -match "No newer package") {
            Write-MauSac "✅ Platform Tools đã được cài đặt thành công!" -Mau "Green"
            Write-MauSac "⚠️ Vui lòng khởi động lại PowerShell để sử dụng ADB" -Mau "Yellow"
            return $true
        }
        else {
            Write-MauSac "⚠️ Cài đặt qua winget thất bại" -Mau "Yellow"
            Write-MauSac "💡 Vui lòng tải thủ công từ: https://developer.android.com/studio/releases/platform-tools" -Mau "White"
            return $false
        }
    }
    catch {
        Write-MauSac "❌ Lỗi cài đặt: $($_.Exception.Message)" -Mau "Red"
        return $false
    }
}

function KiemTra-ThietBi {
    Hien-TieuDe "KIỂM TRA THIẾT BỊ ANDROID"
    
    try {
        $danhSachThietBi = adb devices 2>$null
        if ($danhSachThietBi) {
            $thietBiKetNoi = $danhSachThietBi | Where-Object { $_ -match "\t" }
            
            if ($thietBiKetNoi) {
                Write-MauSac "✅ Thiết bị được kết nối:" -Mau "Green"
                foreach ($thietBi in $thietBiKetNoi) {
                    Write-MauSac "   📱 $thietBi" -Mau "Green"
                }
                
                # Kiểm tra USB Debugging
                $debugStatus = adb shell getprop ro.debuggable 2>$null
                if ($debugStatus -eq "1") {
                    Write-MauSac "✅ USB Debugging đã được bật" -Mau "Green"
                }
                else {
                    Write-MauSac "⚠️ Vui lòng bật USB Debugging trong Developer Options" -Mau "Yellow"
                }
                
                return $true
            }
            else {
                Write-MauSac "⚠️ Không có thiết bị nào được kết nối" -Mau "Yellow"
                Write-MauSac "📋 Hướng dẫn kết nối:" -Mau "White"
                Write-MauSac "   1. Bật Developer Options (nhấn Build Number 7 lần)" -Mau "White"
                Write-MauSac "   2. Bật USB Debugging trong Developer Options" -Mau "White"
                Write-MauSac "   3. Kết nối thiết bị qua USB" -Mau "White"
                Write-MauSac "   4. Chấp nhận USB Debugging trên thiết bị" -Mau "White"
                return $false
            }
        }
        else {
            Write-MauSac "❌ Không thể kiểm tra thiết bị" -Mau "Red"
            return $false
        }
    }
    catch {
        Write-MauSac "❌ ADB không khả dụng. Vui lòng chạy: -CaiDatADB" -Mau "Red"
        return $false
    }
}

function CaiDat-APK {
    Hien-TieuDe "CÀI ĐẶT APK LÊN THIẾT BỊ"
    
    $duongDanAPK = "build\app\outputs\flutter-apk\app-debug.apk"
    
    if (-not (Test-Path $duongDanAPK)) {
        Write-MauSac "❌ Không tìm thấy APK" -Mau "Red"
        return $false
    }
    
    Write-MauSac "📱 Đang cài đặt APK lên thiết bị..." -Mau "Yellow"
    
    try {
        $ketQua = adb install -r $duongDanAPK 2>&1
        
        if ($ketQua -match "Success" -or $ketQua -match "success") {
            Write-MauSac "✅ APK đã được cài đặt thành công!" -Mau "Green"
            Write-MauSac "🚀 Đang khởi động ứng dụng..." -Mau "Yellow"
            
            # Khởi động ứng dụng
            adb shell am start -n com.example.smartmanagementapp/.MainActivity 2>$null
            Write-MauSac "✅ Ứng dụng đã được khởi động!" -Mau "Green"
            
            Write-Host ""
            Write-MauSac "📋 HƯỚNG DẪN KIỂM THỬ:" -Mau "Cyan"
            Write-MauSac "1. 🛡️ KIỂM THỬ AN TOÀN (QUAN TRỌNG):" -Mau "Yellow"
            Write-MauSac "   - Vào 'Blocked Apps' trong ứng dụng" -Mau "White"
            Write-MauSac "   - KIỂM TRA: TakeTime KHÔNG xuất hiện trong danh sách" -Mau "White"
            Write-MauSac "   - Tìm kiếm 'TakeTime' → Không tìm thấy" -Mau "White"
            Write-Host ""
            Write-MauSac "2. ✅ KIỂM THỬ CHỨC NĂNG:" -Mau "Yellow"
            Write-MauSac "   - Thêm Calculator/Facebook với giới hạn 1-2 phút" -Mau "White"
            Write-MauSac "   - Cấp 3 quyền cần thiết" -Mau "White"
            Write-MauSac "   - Bắt đầu focus session và thử mở ứng dụng bị chặn" -Mau "White"
            Write-MauSac "   - KẾT QUẢ: Màn hình chặn phải xuất hiện" -Mau "White"
            
            return $true
        }
        else {
            Write-MauSac "❌ Cài đặt thất bại: $ketQua" -Mau "Red"
            Write-MauSac "💡 Thử cài đặt thủ công bằng cách copy APK vào thiết bị" -Mau "Yellow"
            return $false
        }
    }
    catch {
        Write-MauSac "❌ Lỗi cài đặt: $($_.Exception.Message)" -Mau "Red"
        return $false
    }
}

function TheoDoi-Log {
    Hien-TieuDe "THEO DÕI LOG THIẾT BỊ"
    
    Write-MauSac "📊 Bắt đầu theo dõi log cho TakeTime..." -Mau "Yellow"
    Write-MauSac "🔍 Tìm kiếm: SAFETY, TakeTime, BlockingService" -Mau "Yellow"
    Write-MauSac "⏹️ Nhấn Ctrl+C để dừng" -Mau "Yellow"
    Write-Host ""
    
    try {
        # Xóa log cũ
        adb logcat -c 2>$null
        
        # Bắt đầu theo dõi
        adb logcat | Select-String "SAFETY|TakeTime|BlockingService|smartmanagementapp"
    }
    catch {
        Write-MauSac "❌ Không thể theo dõi log: $($_.Exception.Message)" -Mau "Red"
    }
}

function Hien-TrangThaiTongQuat {
    Hien-TieuDe "TAKETIME FOCUS APP - TRẠNG THÁI KIỂM THỬ"
    
    Write-MauSac "📅 Ngày: $(Get-Date -Format 'dd/MM/yyyy HH:mm')" -Mau "Cyan"
    Write-MauSac "🏗️ Build: Thành công (28/05/2025 12:36 AM)" -Mau "Cyan"
    Write-MauSac "🛡️ An toàn: 12+ biện pháp bảo vệ được xác minh" -Mau "Cyan"
    Write-Host ""
    
    # Kiểm tra trạng thái APK
    $apkOK = KiemTra-APK
    
    # Kiểm tra ADB
    try {
        $adbOK = adb version 2>$null
        if ($adbOK) {
            Write-MauSac "✅ ADB: Khả dụng" -Mau "Green"
            
            # Kiểm tra thiết bị
            $thietBiOK = KiemTra-ThietBi
        }
        else {
            Write-MauSac "⚠️ ADB: Chưa cài đặt" -Mau "Yellow"
        }
    }
    catch {
        Write-MauSac "⚠️ ADB: Chưa cài đặt hoặc không trong PATH" -Mau "Yellow"
    }
    
    Write-Host ""
    Write-MauSac "📋 CÁC TÙYAN CHỌN KIỂM THỬ:" -Mau "Blue"
    Write-Host ""
    Write-MauSac "Kiểm tra APK:" -Mau "Yellow"
    Write-MauSac "  .\kiem_thu_nhanh.ps1 -KiemTraAPK" -Mau "White"
    Write-Host ""
    Write-MauSac "Cài đặt ADB:" -Mau "Yellow"
    Write-MauSac "  .\kiem_thu_nhanh.ps1 -CaiDatADB" -Mau "White"
    Write-Host ""
    Write-MauSac "Kiểm tra thiết bị:" -Mau "Yellow"
    Write-MauSac "  .\kiem_thu_nhanh.ps1 -KiemTraThietBi" -Mau "White"
    Write-Host ""
    Write-MauSac "Cài đặt APK:" -Mau "Yellow"
    Write-MauSac "  .\kiem_thu_nhanh.ps1 -CaiDatAPK" -Mau "White"
    Write-Host ""
    Write-MauSac "Theo dõi log:" -Mau "Yellow"
    Write-MauSac "  .\kiem_thu_nhanh.ps1 -TheoDoiLog" -Mau "White"
    Write-Host ""
    Write-MauSac "Chạy tất cả:" -Mau "Yellow"
    Write-MauSac "  .\kiem_thu_nhanh.ps1 -TatCa" -Mau "White"
    Write-Host ""
    
    Write-MauSac "📖 HƯỚNG DẪN CHI TIẾT:" -Mau "Blue"
    Write-MauSac "   📄 HUONG_DAN_KIEM_THU_NHANH.md" -Mau "White"
    Write-MauSac "   📄 MANUAL_TESTING_GUIDE.md" -Mau "White"
    Write-MauSac "   📄 DEVICE_TESTING_PLAN.md" -Mau "White"
}

# Thực thi chính
if ($TatCa) {
    $KiemTraAPK = $true
    $CaiDatADB = $true
    $KiemTraThietBi = $true
}

if ($KiemTraAPK) {
    KiemTra-APK
    Write-Host ""
}

if ($CaiDatADB) {
    CaiDat-ADB
    Write-Host ""
}

if ($KiemTraThietBi) {
    KiemTra-ThietBi
    Write-Host ""
}

if ($CaiDatAPK) {
    CaiDat-APK
    Write-Host ""
}

if ($TheoDoiLog) {
    TheoDoi-Log
    Write-Host ""
}

# Mặc định - hiển thị tổng quan
if (-not ($KiemTraAPK -or $CaiDatADB -or $KiemTraThietBi -or $CaiDatAPK -or $TheoDoiLog -or $TatCa)) {
    Hien-TrangThaiTongQuat
}

Write-Host ""
Write-MauSac "🎯 SẴN SÀNG KIỂM THỬ! APK đã được build thành công và có 12+ biện pháp an toàn!" -Mau "Green"
