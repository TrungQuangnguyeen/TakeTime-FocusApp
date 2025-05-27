# 🔧 Hướng Dẫn Chi Tiết Cấp Quyền Trên Emulator Android

## 📱 Các Quyền Cần Thiết

Ứng dụng TakeTime cần 3 quyền quan trọng để hoạt động:

1. **Usage Stats Permission** - Theo dõi thời gian sử dụng ứng dụng
2. **Display Over Other Apps** - Hiển thị cảnh báo khi chặn ứng dụng  
3. **Accessibility Service** - Chặn ứng dụng thực sự

## 🎯 Cách Cấp Quyền Từng Bước

### Bước 1: Mở Ứng Dụng TakeTime
1. Khởi chạy ứng dụng TakeTime trên emulator
2. Vào **Blocked Apps** (Ứng dụng bị chặn)
3. Nhấn vào icon **⚙️ Settings** ở góc trên bên phải
4. Nhấn **"Kiểm tra và cấp quyền"**

### Bước 2: Cấp Usage Stats Permission
Khi nhấn nút cấp quyền, ứng dụng sẽ tự động mở Settings:

**Nếu mở đúng trang Usage Access:**
1. Tìm **"TakeTime"** trong danh sách
2. Bật toggle bên cạnh tên ứng dụng
3. Nhấn **Back** để quay lại

**Nếu không mở đúng trang, tự tìm theo đường dẫn:**
```
Settings → Apps → Special access → Usage access
```

**Trên emulator cũ hơn:**
```
Settings → Security → Device admin apps → Usage access
```

### Bước 3: Cấp Display Over Other Apps Permission
1. Quay lại ứng dụng TakeTime
2. Nhấn nút cấp quyền lần nữa
3. Ứng dụng sẽ mở trang Overlay Permission

**Nếu mở đúng trang:**
1. Tìm **"TakeTime"** 
2. Bật toggle **"Allow display over other apps"**
3. Nhấn Back

**Nếu không mở đúng, tự tìm:**
```
Settings → Apps → Special access → Display over other apps
```

### Bước 4: Cấp Accessibility Service Permission
1. Quay lại ứng dụng TakeTime
2. Nhấn nút cấp quyền lần cuối
3. Ứng dụng sẽ mở trang Accessibility

**Trong trang Accessibility:**
1. Tìm **"TakeTime"** hoặc **"App Blocking Service"**
2. Nhấn vào tên service
3. Bật toggle **"Use service"**
4. Nhấn **"OK"** khi có dialog xác nhận

**Nếu không tìm thấy, đường dẫn thủ công:**
```
Settings → Accessibility → Downloaded apps → TakeTime
```

## ✅ Kiểm Tra Quyền Đã Cấp

Sau khi cấp đủ 3 quyền, quay lại ứng dụng TakeTime:

1. Vào **Blocked Apps**
2. Nhấn icon **⚙️** để kiểm tra
3. Nếu thấy ✅ màu xanh → Thành công!
4. Nếu vẫn có ⚠️ màu cam → Cần cấp thêm quyền

## 🔍 Các Vấn Đề Thường Gặp

### Vấn đề 1: Không tìm thấy TakeTime trong danh sách
**Giải pháp:**
- Scroll xuống để tìm
- Sử dụng chức năng Search (🔍) nếu có
- Kiểm tra tab "Downloaded apps" hoặc "Third-party apps"

### Vấn đề 2: Settings không mở đúng trang
**Giải pháp:**
- Trong ứng dụng TakeTime, nhấn "Open App Settings" để vào trang cài đặt ứng dụng
- Từ đó tìm "Permissions" hoặc "App permissions"

### Vấn đề 3: Emulator không có quyền Accessibility
**Giải pháp:**
- Một số emulator cũ không hỗ trợ Accessibility Service
- Thử sử dụng emulator mới hơn (Android 10+)
- Hoặc test trên thiết bị thật

### Vấn đề 4: Quyền bị reset sau khi tắt emulator
**Giải pháp:**
- Trong emulator settings, bật "Save state" để lưu quyền
- Hoặc tạo snapshot sau khi cấp quyền

## 📋 Checklist Hoàn Tất

- [ ] Usage Stats Permission ✅
- [ ] Display Over Other Apps ✅  
- [ ] Accessibility Service ✅
- [ ] Test blocking một ứng dụng
- [ ] Kiểm tra overlay hiển thị khi ứng dụng bị chặn

## 🆘 Nếu Vẫn Gặp Khó Khăn

1. **Chụp màn hình** trang Settings hiện tại
2. **Cho biết phiên bản Android** của emulator  
3. **Gửi log lỗi** từ Android Studio/VS Code
4. Tôi sẽ hướng dẫn cụ thể cho trường hợp của bạn

## 🚀 Sau Khi Cấp Đủ Quyền

Khi đã cấp đủ 3 quyền:
1. Thêm ứng dụng vào danh sách chặn
2. Đặt thời gian giới hạn
3. Test mở ứng dụng đó → Sẽ bị chặn ngay lập tức!

---
*Hướng dẫn này được tạo để giúp bạn dễ dàng cấp quyền trên emulator Android. Nếu có thắc mắc, hãy báo lại!*
