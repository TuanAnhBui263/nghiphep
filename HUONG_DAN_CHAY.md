# Hướng dẫn chạy ứng dụng

## ⚠️ LƯU Ý QUAN TRỌNG

**Phải chạy từ đúng thư mục `nghiphep`**

## 🚀 Cách chạy ứng dụng

### 1. Mở Terminal/Command Prompt
```bash
# Di chuyển vào thư mục nghiphep
cd nghiphep
```

### 2. Cài đặt dependencies
```bash
flutter pub get
```

### 3. Chạy ứng dụng
```bash
# Chạy trên Windows
flutter run -d windows

# Hoặc chạy trên web
flutter run -d chrome

# Hoặc chọn device khi có menu
flutter run
```

## ❌ LỖI THƯỜNG GẶP

### Lỗi: "No pubspec.yaml file found"
**Nguyên nhân**: Đang chạy từ thư mục sai
**Giải pháp**: 
```bash
cd nghiphep
flutter run
```

### Lỗi: "CardTheme can't be assigned"
**Nguyên nhân**: Đang chạy file main.dart từ thư mục khác
**Giải pháp**: Đảm bảo chạy từ thư mục `nghiphep`

## 📁 CẤU TRÚC THƯ MỤC

```
NghiPhep/
├── nghiphep/          ← CHẠY TỪ ĐÂY
│   ├── lib/
│   │   └── main.dart  ← File chính đã sửa lỗi
│   ├── pubspec.yaml
│   └── ...
└── nghiphep_app/      ← KHÔNG chạy từ đây
    └── lib/
        └── main.dart  ← File cũ có lỗi
```

## ✅ KIỂM TRA

Để kiểm tra đang ở đúng thư mục:
```bash
# Phải thấy file pubspec.yaml
ls pubspec.yaml

# Phải thấy thư mục lib
ls lib/
```
