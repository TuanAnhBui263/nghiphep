# Hệ thống quản lý nghỉ phép

Ứng dụng Flutter quản lý nghỉ phép cho công chức với các vai trò khác nhau.

## Tính năng chính

### 🔐 Đăng nhập đa vai trò
- **Admin**: Quản lý toàn bộ hệ thống
- **Trưởng phòng**: Duyệt đơn nghỉ phép của nhân viên
- **Phó phòng**: Duyệt đơn nghỉ phép của nhân viên
- **Nhân viên**: Xin nghỉ phép và xem lịch sử

### 📋 Quản lý nghỉ phép
- Xin nghỉ phép theo ngày hoặc nửa ngày
- Nghỉ ốm (có thể xin sau, duyệt sau)
- Tính toán tự động số ngày nghỉ còn lại
- Lịch sử nghỉ phép

### 👥 Quản lý người dùng (Admin)
- Thêm/sửa/xóa người dùng
- Phân quyền theo vai trò
- Quản lý phòng ban
- Cấu hình người quản lý trực tiếp

## Tài khoản mẫu

| Vai trò | Tên đăng nhập | Mật khẩu | Mô tả |
|---------|---------------|----------|-------|
| Admin | admin | admin123 | Quản trị viên hệ thống |
| Trưởng phòng | truongphong | truongphong123 | Trưởng phòng Nhân sự |
| Phó phòng | phophong | phophong123 | Phó phòng Kế toán |
| Nhân viên | nhanvien1 | nhanvien123 | Nhân viên Nhân sự |
| Nhân viên | nhanvien2 | nhanvien123 | Nhân viên Kế toán |
| Nhân viên | nhanvien3 | nhanvien123 | Nhân viên IT |

## Quy tắc nghỉ phép

### Số ngày nghỉ phép năm
- Dưới 1 năm: 12 ngày
- 1-5 năm: 14 ngày  
- 5-10 năm: 16 ngày
- Trên 10 năm: 18 ngày

### Loại nghỉ phép
- **Nghỉ cả ngày**: Nghỉ từ sáng đến chiều
- **Nghỉ nửa ngày**: Nghỉ sáng hoặc chiều (0.5 ngày)
- **Nghỉ ốm**: Có thể xin sau, duyệt sau

### Quy trình duyệt
1. Nhân viên gửi đơn nghỉ phép
2. Trưởng phòng/Phó phòng duyệt
3. Hệ thống tự động cập nhật số ngày nghỉ còn lại

## Cài đặt và chạy

### Yêu cầu hệ thống
- Flutter SDK 3.7.0+
- Dart SDK
- Windows/macOS/Linux

### Cài đặt
```bash
# Clone repository
git clone <repository-url>
cd nghiphep

# Cài đặt dependencies
flutter pub get

# Chạy ứng dụng
flutter run
```

### Chạy trên các platform
```bash
# Windows
flutter run -d windows

# macOS
flutter run -d macos

# Linux
flutter run -d linux

# Web
flutter run -d web
```

## Cấu trúc dự án

```
lib/
├── models/           # Data models
│   ├── user.dart
│   └── leave_request.dart
├── providers/        # State management
│   └── auth_provider.dart
├── services/         # Business logic
│   └── auth_service.dart
└── screens/          # UI screens
    ├── login_screen.dart
    ├── dashboard_screen.dart
    ├── employee/
    ├── manager/
    ├── admin/
    └── ...
```

## Công nghệ sử dụng

- **Flutter**: Framework UI
- **Provider**: State management
- **SharedPreferences**: Local storage
- **Material Design 3**: UI/UX design

## Tính năng đang phát triển

- [ ] Kết nối API backend
- [ ] Push notification
- [ ] Báo cáo thống kê
- [ ] Export dữ liệu
- [ ] Backup/Restore
- [ ] Cấu hình hệ thống

## Đóng góp

1. Fork repository
2. Tạo feature branch
3. Commit changes
4. Push to branch
5. Tạo Pull Request

## License

MIT License - xem file LICENSE để biết thêm chi tiết.