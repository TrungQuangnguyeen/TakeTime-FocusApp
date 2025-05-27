# 🎯 TakeTime App - Hướng Dẫn Toàn Diện

## 🚀 Bắt Đầu Nhanh

### 1. Chạy Test Script
```powershell
# Trong thư mục Taketime-FocusApp
.\quick_test.ps1
```

### 2. Cấp Quyền Dễ Dàng
1. Mở ứng dụng TakeTime
2. Vào **Blocked Apps** 
3. Nhấn icon **⚙️** (màu cam/xanh)
4. Màn hình setup quyền sẽ mở ra
5. Nhấn từng nút **"Cấp Quyền"**
6. Làm theo hướng dẫn trên màn hình

## 📱 Cấp Quyền Trên Emulator

### Quyền 1: Usage Stats
**Khi nhấn "Cấp quyền":**
- Settings sẽ mở → Apps → Special access → Usage access
- Tìm "TakeTime" và bật toggle

**Nếu không mở đúng trang:**
```
Settings → Apps & notifications → Special app access → Usage access
```

### Quyền 2: Display Over Other Apps  
**Khi nhấn "Cấp quyền":**
- Settings sẽ mở → Display over other apps
- Tìm "TakeTime" và bật "Allow display over other apps"

**Nếu không mở đúng trang:**
```
Settings → Apps → Special access → Display over other apps
```

### Quyền 3: Accessibility Service
**Khi nhấn "Cấp quyền":**
- Settings sẽ mở → Accessibility
- Tìm "TakeTime" hoặc "App Blocking Service"
- Nhấn vào và bật "Use service"

**Nếu không mở đúng trang:**
```
Settings → Accessibility → Downloaded apps → TakeTime
```

## 🎮 Test Chức Năng

### Sau khi cấp đủ quyền:

1. **Thêm ứng dụng để chặn:**
   - Nhấn nút **"+"** 
   - Chọn ứng dụng (ví dụ: Chrome, Instagram)
   - Đặt thời gian giới hạn (ví dụ: 1 phút)
   - Nhấn **"Lưu"**

2. **Test blocking:**
   - Mở ứng dụng vừa thêm vào danh sách
   - Sau 1 phút → Ứng dụng sẽ bị đóng ngay lập tức
   - Màn hình cảnh báo sẽ hiện ra

3. **Kiểm tra thống kê:**
   - Vào **"Xem thống kê"** 
   - Xem biểu đồ thời gian sử dụng

## 🔧 Troubleshooting

### Vấn đề 1: Không tìm thấy TakeTime trong Settings
**Giải pháp:**
- Scroll xuống dưới danh sách
- Tìm trong tab "Downloaded apps" hoặc "Third-party apps"
- Sử dụng chức năng Search nếu có

### Vấn đề 2: Settings không mở đúng trang
**Giải pháp:**
- Nhấn **"Open App Settings"** trong ứng dụng
- Từ trang app settings, tìm "Permissions"
- Hoặc nhấn **"Open General Settings"** và tự tìm

### Vấn đề 3: Accessibility không hoạt động
**Giải pháp:**
- Restart ứng dụng sau khi cấp quyền
- Kiểm tra trong **Settings → Accessibility** xem service có đang bật
- Thử tắt và bật lại service

### Vấn đề 4: Ứng dụng không bị chặn
**Kiểm tra:**
- Tất cả 3 quyền đã được cấp? (icon ⚙️ phải màu xanh)
- Thời gian giới hạn đã hết chưa?
- Restart ứng dụng TakeTime

## 📂 File Tham Khảo

- `EMULATOR_PERMISSION_STEP_BY_STEP.md` - Hướng dẫn chi tiết từng bước
- `quick_test.ps1` - Script test nhanh
- `TESTING_GUIDE.md` - Hướng dẫn test toàn diện
- `APP_BLOCKING_SUMMARY.md` - Tổng quan kỹ thuật

## 🎯 Tóm Tắt

1. **Chạy script:** `.\quick_test.ps1`
2. **Cấp 3 quyền** qua màn hình setup trong ứng dụng
3. **Test blocking** bằng cách thêm ứng dụng và đặt giới hạn thời gian
4. **Kiểm tra log** nếu có vấn đề: `flutter logs`

---
**Lưu ý:** Trên emulator có thể mất 5-10 giây để quyền có hiệu lực. Hãy đợi một chút sau khi cấp quyền.
