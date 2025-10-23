# 📝 Hướng dẫn sử dụng màn hình thêm người dùng

## 🎯 Tổng quan

Màn hình thêm người dùng đã được cập nhật với các tính năng mới:
- **Tích hợp API động**: Tải dữ liệu phòng ban, chức vụ, vai trò từ API
- **Form validation nâng cao**: Kiểm tra đầy đủ các trường bắt buộc
- **UI/UX cải tiến**: Giao diện thân thiện với người dùng
- **Xử lý lỗi thông minh**: Thông báo lỗi chi tiết và dễ hiểu

## 🚀 Cách sử dụng

### 1. Truy cập màn hình
```dart
// Navigate to add user screen
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const AddUserScreen(),
  ),
);
```

### 2. Các bước thêm người dùng

#### **Bước 1: Thông tin cơ bản**
- ✅ **Email**: Nhập email hợp lệ (có validation)
- ✅ **Mật khẩu**: Tối thiểu 6 ký tự
- ✅ **Họ và tên**: Tên đầy đủ của người dùng

#### **Bước 2: Thông tin liên hệ**
- ✅ **Số điện thoại**: 10-11 số (có validation format)

#### **Bước 3: Thông tin cá nhân**
- ✅ **Ngày sinh**: Chọn từ date picker (1900 - hiện tại)
- ✅ **Ngày vào làm**: Chọn từ date picker (2000 - tương lai)

#### **Bước 4: Thông tin công việc**
- ✅ **Phòng ban**: Dropdown tải từ API
- ✅ **Chức vụ**: Dropdown tải từ API  
- ✅ **Vai trò**: Multi-select dialog (có thể chọn nhiều vai trò)

## 🔧 Tính năng mới

### **1. Loading States**
```dart
// Hiển thị loading khi tải dữ liệu
if (_isLoadingData) {
  return Center(
    child: Column(
      children: [
        CircularProgressIndicator(),
        Text('Đang tải dữ liệu...'),
      ],
    ),
  );
}
```

### **2. Error Handling**
```dart
// Xử lý lỗi thông minh
if (e.toString().contains('email')) {
  errorMessage = 'Email đã tồn tại hoặc không hợp lệ';
} else if (e.toString().contains('phone')) {
  errorMessage = 'Số điện thoại đã tồn tại';
} else if (e.toString().contains('network')) {
  errorMessage = 'Lỗi kết nối mạng. Vui lòng thử lại';
}
```

### **3. Form Validation**
```dart
// Validation email
validator: (value) {
  if (value == null || value.isEmpty) {
    return 'Vui lòng nhập email';
  }
  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
    return 'Email không hợp lệ';
  }
  return null;
},

// Validation phone
validator: (value) {
  if (value == null || value.isEmpty) {
    return 'Vui lòng nhập số điện thoại';
  }
  if (!RegExp(r'^[0-9]{10,11}$').hasMatch(value)) {
    return 'Số điện thoại không hợp lệ';
  }
  return null;
},
```

### **4. Multi-Select Dialog**
```dart
// Dialog chọn nhiều vai trò
Future<void> _showMultiSelectDialog(
  List<Role> allItems,
  List<int> selectedItems,
  void Function(List<int>) onChanged,
) async {
  // Implementation with checkbox list
}
```

## 📱 UI Components

### **1. Section Cards**
```dart
Widget _buildSectionCard(String title, List<Widget> children) {
  return Card(
    elevation: 2,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(height: 16),
          ...children,
        ],
      ),
    ),
  );
}
```

### **2. Date Fields**
```dart
Widget _buildDateField({
  required TextEditingController controller,
  required String label,
  required IconData icon,
  required VoidCallback onTap,
  String? Function(String?)? validator,
}) {
  return TextFormField(
    controller: controller,
    readOnly: true,
    onTap: onTap,
    decoration: InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      suffixIcon: Icon(Icons.calendar_today),
    ),
    validator: validator,
  );
}
```

### **3. Dropdown Fields**
```dart
Widget _buildDropdownField<T>({
  required T? value,
  required String label,
  required IconData icon,
  required List<DropdownMenuItem<T>> items,
  required void Function(T?) onChanged,
}) {
  return DropdownButtonFormField<T>(
    value: value,
    decoration: InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
    ),
    items: items,
    onChanged: onChanged,
  );
}
```

## 🔄 Data Flow

### **1. Load Initial Data**
```dart
Future<void> _loadInitialData() async {
  try {
    // Load departments
    final departments = await ApiService.getDepartmentsForDropdown();
    
    // Load position types
    final positionTypes = await ApiService.getPositionTypes();
    
    // Load roles
    final roles = await ApiService.getRoles();

    setState(() {
      _departments = departments.map((d) => Department.fromJson(d)).toList();
      _positionTypes = positionTypes.map((p) => PositionType.fromJson(p)).toList();
      _roles = roles.map((r) => Role.fromJson(r)).toList();
      _isLoadingData = false;
    });
  } catch (e) {
    // Handle error with retry option
  }
}
```

### **2. Submit User Data**
```dart
Future<void> _addUser() async {
  // Validate form
  if (!_formKey.currentState!.validate()) return;
  
  // Validate selections
  if (_selectedDepartmentId == null) {
    _showErrorSnackBar('Vui lòng chọn phòng ban');
    return;
  }
  
  // Create user data
  final userData = UserRegistrationRequest(
    email: _emailController.text.trim(),
    password: _passwordController.text,
    fullName: _fullNameController.text.trim(),
    phoneNumber: _phoneController.text.trim(),
    dateOfBirth: _dateOfBirthController.text,
    joinDate: _joinDateController.text,
    departmentId: _selectedDepartmentId!,
    positionTypeId: _selectedPositionTypeId!,
    roleIds: _selectedRoleIds,
  );

  // Submit to API
  await ApiService.createUser(userData.toJson());
}
```

## 🎨 Styling

### **1. Color Scheme**
```dart
// Primary color from theme
backgroundColor: Theme.of(context).primaryColor,
foregroundColor: Colors.white,

// Error colors
backgroundColor: Colors.red,
backgroundColor: Colors.green, // Success
```

### **2. Layout**
```dart
// Card elevation
elevation: 2,

// Border radius
borderRadius: BorderRadius.circular(8),
borderRadius: BorderRadius.circular(12),

// Padding
padding: const EdgeInsets.all(16),
```

## 🚨 Error Handling

### **1. Network Errors**
```dart
catch (e) {
  if (e.toString().contains('network')) {
    errorMessage = 'Lỗi kết nối mạng. Vui lòng thử lại';
  }
}
```

### **2. Validation Errors**
```dart
// Email validation
if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
  return 'Email không hợp lệ';
}

// Phone validation
if (!RegExp(r'^[0-9]{10,11}$').hasMatch(value)) {
  return 'Số điện thoại không hợp lệ';
}
```

### **3. Selection Errors**
```dart
if (_selectedDepartmentId == null) {
  _showErrorSnackBar('Vui lòng chọn phòng ban');
  return;
}

if (_selectedRoleIds.isEmpty) {
  _showErrorSnackBar('Vui lòng chọn ít nhất một vai trò');
  return;
}
```

## 📊 Success Flow

### **1. Form Submission**
```dart
await ApiService.createUser(userData.toJson());

ScaffoldMessenger.of(context).showSnackBar(
  const SnackBar(
    content: Text('✅ Thêm người dùng thành công'),
    backgroundColor: Colors.green,
    duration: Duration(seconds: 3),
  ),
);
Navigator.of(context).pop(true); // Return success result
```

### **2. Navigation Result**
```dart
// In parent screen
final result = await Navigator.push<bool>(
  context,
  MaterialPageRoute(
    builder: (context) => const AddUserScreen(),
  ),
);

if (result == true) {
  // Refresh data or show success message
  setState(() {
    _userCount++;
  });
}
```

## 🔧 Customization

### **1. Add New Fields**
```dart
// Add new controller
final _newFieldController = TextEditingController();

// Add to form
_buildTextField(
  controller: _newFieldController,
  label: 'Tên trường mới',
  icon: Icons.new_icon,
  validator: (value) {
    // Add validation logic
    return null;
  },
),
```

### **2. Modify Validation**
```dart
// Custom validation
validator: (value) {
  if (value == null || value.isEmpty) {
    return 'Trường này là bắt buộc';
  }
  // Add custom validation logic
  return null;
},
```

### **3. Change API Endpoints**
```dart
// In ApiService
static Future<Map<String, dynamic>> createUser(
  Map<String, dynamic> userData,
) async {
  final response = await _makeRequest(
    'POST',
    '/api/auth/register', // Change endpoint if needed
    body: userData,
  );
  // Handle response
}
```

## 🎯 Best Practices

1. **Always validate** form data before submission
2. **Show loading states** during API calls
3. **Handle errors gracefully** with user-friendly messages
4. **Use proper navigation** with result handling
5. **Implement retry mechanisms** for failed operations
6. **Cache data** when appropriate to reduce API calls
7. **Test thoroughly** with different data scenarios

## 🚀 Next Steps

1. **Test the form** with real API endpoints
2. **Add more validation** as needed
3. **Implement user list** screen to view created users
4. **Add edit user** functionality
5. **Implement user search** and filtering
6. **Add bulk operations** for multiple users

---

**🎉 Happy Coding!** The updated add user screen provides a robust and user-friendly interface for creating new users with comprehensive validation and error handling.
