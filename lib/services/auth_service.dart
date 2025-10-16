import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';

class AuthService {
  static const String _userKey = 'current_user';
  static const String _isLoggedInKey = 'is_logged_in';

  // Danh sách người dùng mẫu (seed data)
  static final List<User> _sampleUsers = [
    User(
      id: '1',
      username: 'admin',
      password: 'admin123',
      fullName: 'Nguyễn Văn Admin',
      email: 'admin@company.com',
      phone: '0123456789',
      department: 'IT',
      role: UserRole.admin,
      workYears: 10,
      annualLeaveDays: 18,
      remainingLeaveDays: 18,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    User(
      id: '2',
      username: 'truongphong',
      password: 'truongphong123',
      fullName: 'Trần Thị Trưởng Phòng',
      email: 'truongphong@company.com',
      phone: '0123456790',
      department: 'Nhân sự',
      role: UserRole.teamLeader,
      workYears: 8,
      annualLeaveDays: 16,
      remainingLeaveDays: 16,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    User(
      id: '3',
      username: 'phophong',
      password: 'phophong123',
      fullName: 'Lê Văn Phó Phòng',
      email: 'phophong@company.com',
      phone: '0123456791',
      department: 'Kế toán',
      role: UserRole.deputyLeader,
      workYears: 6,
      annualLeaveDays: 16,
      remainingLeaveDays: 16,
      managerId: '2',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    User(
      id: '4',
      username: 'nhanvien1',
      password: 'nhanvien123',
      fullName: 'Phạm Thị Nhân Viên',
      email: 'nhanvien1@company.com',
      phone: '0123456792',
      department: 'Nhân sự',
      role: UserRole.employee,
      workYears: 3,
      annualLeaveDays: 14,
      remainingLeaveDays: 14,
      managerId: '2',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    User(
      id: '5',
      username: 'nhanvien2',
      password: 'nhanvien123',
      fullName: 'Hoàng Văn Nhân Viên',
      email: 'nhanvien2@company.com',
      phone: '0123456793',
      department: 'Kế toán',
      role: UserRole.employee,
      workYears: 1,
      annualLeaveDays: 12,
      remainingLeaveDays: 12,
      managerId: '3',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    User(
      id: '6',
      username: 'nhanvien3',
      password: 'nhanvien123',
      fullName: 'Vũ Thị Nhân Viên',
      email: 'nhanvien3@company.com',
      phone: '0123456794',
      department: 'IT',
      role: UserRole.employee,
      workYears: 5,
      annualLeaveDays: 14,
      remainingLeaveDays: 14,
      managerId: '1',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
  ];

  // Đăng nhập
  Future<User?> login(String username, String password) async {
    try {
      // Tìm user trong danh sách mẫu
      final user = _sampleUsers.firstWhere(
        (u) => u.username == username && u.password == password,
        orElse: () => throw Exception('Tài khoản hoặc mật khẩu không đúng'),
      );

      // Lưu thông tin user vào SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userKey, jsonEncode(user.toJson()));
      await prefs.setBool(_isLoggedInKey, true);

      return user;
    } catch (e) {
      throw Exception('Đăng nhập thất bại: ${e.toString()}');
    }
  }

  // Đăng xuất
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
    await prefs.setBool(_isLoggedInKey, false);
  }

  // Lấy thông tin user hiện tại
  Future<User?> getCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getBool(_isLoggedInKey) ?? false;

      if (!isLoggedIn) return null;

      final userJson = prefs.getString(_userKey);
      if (userJson == null) return null;

      final userMap = jsonDecode(userJson) as Map<String, dynamic>;
      return User.fromJson(userMap);
    } catch (e) {
      return null;
    }
  }

  // Kiểm tra trạng thái đăng nhập
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isLoggedInKey) ?? false;
  }

  // Lấy danh sách tất cả users (cho admin)
  List<User> getAllUsers() {
    return List.from(_sampleUsers);
  }

  // Lấy danh sách users theo phòng ban
  List<User> getUsersByDepartment(String department) {
    return _sampleUsers.where((user) => user.department == department).toList();
  }

  // Lấy danh sách users theo vai trò
  List<User> getUsersByRole(UserRole role) {
    return _sampleUsers.where((user) => user.role == role).toList();
  }

  // Lấy danh sách nhân viên dưới quyền quản lý
  List<User> getSubordinates(String managerId) {
    return _sampleUsers.where((user) => user.managerId == managerId).toList();
  }

  // Cập nhật thông tin user
  Future<User> updateUser(User updatedUser) async {
    final index = _sampleUsers.indexWhere((user) => user.id == updatedUser.id);
    if (index != -1) {
      _sampleUsers[index] = updatedUser;

      // Cập nhật trong SharedPreferences nếu là user hiện tại
      final currentUser = await getCurrentUser();
      if (currentUser?.id == updatedUser.id) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_userKey, jsonEncode(updatedUser.toJson()));
      }

      return updatedUser;
    }
    throw Exception('Không tìm thấy user');
  }

  // Tạo user mới (chỉ admin)
  Future<User> createUser(User newUser) async {
    // Kiểm tra username đã tồn tại chưa
    final existingUser = _sampleUsers.any(
      (user) => user.username == newUser.username,
    );
    if (existingUser) {
      throw Exception('Tên đăng nhập đã tồn tại');
    }

    _sampleUsers.add(newUser);
    return newUser;
  }

  // Xóa user (chỉ admin)
  Future<void> deleteUser(String userId) async {
    _sampleUsers.removeWhere((user) => user.id == userId);
  }
}
