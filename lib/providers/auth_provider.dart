import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  User? _currentUser;
  bool _isLoading = false;
  final AuthService _authService = AuthService();

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _currentUser != null;

  // Đăng nhập
  Future<void> login(String username, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      _currentUser = await _authService.login(username, password);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Đăng xuất
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _authService.logout();
      _currentUser = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Kiểm tra trạng thái đăng nhập khi khởi động app
  Future<void> checkAuthStatus() async {
    _isLoading = true;
    notifyListeners();

    try {
      _currentUser = await _authService.getCurrentUser();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Cập nhật thông tin user
  Future<void> updateUser(User updatedUser) async {
    _isLoading = true;
    notifyListeners();

    try {
      _currentUser = await _authService.updateUser(updatedUser);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Lấy danh sách tất cả users (cho admin)
  List<User> getAllUsers() {
    return _authService.getAllUsers();
  }

  // Lấy danh sách users theo phòng ban
  List<User> getUsersByDepartment(String department) {
    return _authService.getUsersByDepartment(department);
  }

  // Lấy danh sách users theo vai trò
  List<User> getUsersByRole(UserRole role) {
    return _authService.getUsersByRole(role);
  }

  // Lấy danh sách nhân viên dưới quyền quản lý
  List<User> getSubordinates(String managerId) {
    return _authService.getSubordinates(managerId);
  }

  // Tạo user mới (chỉ admin)
  Future<User> createUser(User newUser) async {
    _isLoading = true;
    notifyListeners();

    try {
      return await _authService.createUser(newUser);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Xóa user (chỉ admin)
  Future<void> deleteUser(String userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _authService.deleteUser(userId);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
