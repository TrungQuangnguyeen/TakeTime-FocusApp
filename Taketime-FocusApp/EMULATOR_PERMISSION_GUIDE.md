# 📱 Hướng Dẫn Cấp Quyền Trên Giả Lập Android

## 🎯 Vấn đề: Khó tìm chỗ cấp quyền trên Android Emulator

### ⚠️ Lưu ý quan trọng về Giả lập
- **Accessibility Services** có thể không hoạt động đầy đủ trên emulator
- **Usage Stats permission** có thể bị hạn chế trên một số emulator
- **System overlay** có thể không hiển thị đúng cách
- **Khuyến nghị**: Sử dụng thiết bị thật để test đầy đủ tính năng

## 🔍 Cách Tìm và Cấp Quyền Trên Giả Lập

### 1. Usage Stats Permission (Quyền Thống Kê Sử Dụng)

#### Đường dẫn trên Android 10+:
```
Settings → Apps & notifications → Special app access → Usage access
```

#### Đường dẫn trên Android 9 và cũ hơn:
```
Settings → Security & privacy → Device admin apps → Usage access
```

#### Các bước chi tiết:
1. **Mở Settings** (Cài đặt)
2. **Tìm "Apps"** hoặc **"Application Manager"**
3. **Tìm "Special access"** hoặc **"Special app access"**
4. **Chọn "Usage access"** hoặc **"Usage data access"**
5. **Tìm "TakeTime"** trong danh sách
6. **Bật toggle** để cấp quyền

### 2. Display Over Other Apps (Quyền Hiển Thị Trên Ứng Dụng Khác)

#### Đường dẫn:
```
Settings → Apps → Special access → Display over other apps
```

#### Các bước chi tiết:
1. **Mở Settings**
2. **Apps** → **Special access**
3. **"Display over other apps"** hoặc **"Draw over other apps"**
4. **Tìm "TakeTime"**
5. **Bật toggle**

### 3. Accessibility Service (Dịch Vụ Hỗ Trợ Tiếp Cận)

#### Đường dẫn:
```
Settings → Accessibility → Downloaded apps → TakeTime
```

#### Các bước chi tiết:
1. **Mở Settings**
2. **Accessibility** (Khả năng tiếp cận)
3. **Tìm "Downloaded apps"** hoặc **"Installed services"**
4. **Chọn "TakeTime"**
5. **Bật toggle** và **xác nhận**

## 🛠️ Cải Thiện UX: Tự Động Mở Settings

Tôi sẽ cải thiện ứng dụng để tự động mở đúng trang settings khi bạn nhấn nút cấp quyền.

### Cập nhật MainActivity.kt để mở đúng trang settings:
