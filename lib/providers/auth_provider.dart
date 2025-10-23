import 'package:flutter/foundation.dart';
import '../models/login_response.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  UserInfo? _currentUser;
  bool _isLoading = false;
  String? _error;

  UserInfo? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;

  AuthProvider() {
    _loadUserFromStorage();
  }

  Future<void> _loadUserFromStorage() async {
    _isLoading = true;
    try {
      final user = await ApiService.getStoredUserInfo();
      if (user != null) {
        _currentUser = user;
      }
    } catch (e) {
      debugPrint('Error loading user from storage: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> login(String email, String password) async {
    debugPrint('AuthProvider: Starting login for $email');
    _setLoading(true);
    _clearError();

    try {
      final loginResponse = await ApiService.login(email, password);
      debugPrint(
        'AuthProvider: Login successful, user roles: ${loginResponse.user.roles}',
      );
      _currentUser = loginResponse.user;
      // Tokens đã được lưu trong ApiService.login()
      notifyListeners();
      debugPrint('AuthProvider: User state updated, isLoggedIn: $isLoggedIn');
    } catch (e) {
      debugPrint('AuthProvider: Login failed: $e');
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    try {
      await ApiService.logout();
      _currentUser = null;
      notifyListeners();
    } catch (e) {
      debugPrint('Error during logout: $e');
    }
  }

  Future<void> refreshUserInfo() async {
    try {
      final user = await ApiService.getCurrentUser();
      if (user != null) {
        _currentUser = user;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error refreshing user info: $e');
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }

  // Helper methods
  bool get isLoggedIn => _currentUser != null;
  bool get isAdmin => _currentUser?.roles.contains('Admin') ?? false;
  bool get isManager => _currentUser?.roles.contains('Manager') ?? false;
  bool get isEmployee => _currentUser?.roles.contains('Employee') ?? false;

  String get userDisplayName => _currentUser?.fullName ?? 'Người dùng';
  String get userEmail => _currentUser?.email ?? '';
  String get userRole =>
      _currentUser?.roles.isNotEmpty == true
          ? _currentUser!.roles.first
          : 'Employee';
  String get userDepartment =>
      _currentUser?.departments.isNotEmpty == true
          ? _currentUser!.departments.first.departmentName
          : 'Chưa xác định';

  List<String> get userRoles => _currentUser?.roles ?? [];
  List<DepartmentInfo> get userDepartments => _currentUser?.departments ?? [];

  // ==================== USER MANAGEMENT METHODS ====================

  /// Lấy danh sách users theo phòng ban
  Future<List<Map<String, dynamic>>> getUsersByDepartment(
    String department,
  ) async {
    try {
      final allUsers = await getAllUsers();
      return allUsers
          .where((user) => user['departmentName'] == department)
          .toList();
    } catch (e) {
      debugPrint('Error getting users by department: $e');
      return [];
    }
  }

  /// Lấy danh sách users theo vai trò
  Future<List<Map<String, dynamic>>> getUsersByRole(String role) async {
    try {
      final allUsers = await getAllUsers();
      return allUsers
          .where((user) => (user['roles'] as List?)?.contains(role) == true)
          .toList();
    } catch (e) {
      debugPrint('Error getting users by role: $e');
      return [];
    }
  }

  // ==================== LEAVE STATISTICS METHODS ====================

  /// Lấy thống kê nghỉ phép của user hiện tại
  Future<Map<String, dynamic>> getMyLeaveStatistics() async {
    try {
      return await ApiService.getMyStatistics();
    } catch (e) {
      debugPrint('Error getting leave statistics: $e');
      // Return default values if API fails
      return {
        'TotalRequests': 0,
        'PendingCount': 0,
        'ApprovedCount': 0,
        'RejectedCount': 0,
        'CancelledCount': 0,
        'TotalDaysRequested': 0,
        'TotalDaysApproved': 0,
      };
    }
  }

  /// Lấy danh sách đơn nghỉ phép của tôi
  Future<Map<String, dynamic>> getMyLeaveRequests({
    String? status,
    int? month,
    int? year,
    int pageNumber = 1,
    int pageSize = 10,
  }) async {
    try {
      return await ApiService.getMyLeaveRequests(
        status: status,
        month: month,
        year: year,
        pageNumber: pageNumber,
        pageSize: pageSize,
      );
    } catch (e) {
      debugPrint('Error getting my leave requests: $e');
      return {
        'items': [],
        'totalCount': 0,
        'pageNumber': pageNumber,
        'pageSize': pageSize,
        'hasMore': false,
      };
    }
  }

  /// Lấy danh sách đơn nghỉ phép chờ duyệt (cho Manager/Admin)
  Future<Map<String, dynamic>> getPendingApprovals({
    int pageNumber = 1,
    int pageSize = 10,
  }) async {
    try {
      return await ApiService.getPendingApprovals(
        pageNumber: pageNumber,
        pageSize: pageSize,
      );
    } catch (e) {
      debugPrint('Error getting pending approvals: $e');
      return {
        'items': [],
        'totalCount': 0,
        'pageNumber': pageNumber,
        'pageSize': pageSize,
      };
    }
  }

  // ==================== USER MANAGEMENT METHODS ====================

  /// Test API connection
  Future<void> testApiConnection() async {
    try {
      debugPrint('AuthProvider: Testing API connection...');

      // Test 1: Get my info
      try {
        final myInfo = await ApiService.getMyInfo();
        debugPrint('AuthProvider: My info test successful: $myInfo');
      } catch (e) {
        debugPrint('AuthProvider: My info test failed: $e');
      }

      // Test 2: Get employees with debug
      try {
        debugPrint('AuthProvider: Testing getEmployees...');
        final result = await ApiService.getEmployees(
          pageNumber: 1,
          pageSize: 5,
        );
        debugPrint('AuthProvider: GetEmployees test successful: $result');
      } catch (e) {
        debugPrint('AuthProvider: GetEmployees test failed: $e');
      }
    } catch (e) {
      debugPrint('AuthProvider: API connection test failed: $e');
    }
  }

  /// Lấy danh sách tất cả users
  Future<List<Map<String, dynamic>>> getAllUsers({
    int pageNumber = 1,
    int pageSize = 10,
    String? search,
  }) async {
    try {
      debugPrint('AuthProvider: Getting all users...');
      final result = await ApiService.getEmployees(
        pageNumber: pageNumber,
        pageSize: pageSize,
        searchTerm: search,
      );
      debugPrint('AuthProvider: API response: $result');

      // Kiểm tra cấu trúc response
      // Nếu có items
      if (result.containsKey('items')) {
        final items = result['items'] ?? [];
        debugPrint('AuthProvider: Found ${items.length} users in items');
        return List<Map<String, dynamic>>.from(items);
      }
      // Nếu có data field
      else if (result.containsKey('data')) {
        final data = result['data'] ?? [];
        debugPrint('AuthProvider: Found ${data.length} users in data');
        return List<Map<String, dynamic>>.from(data);
      }
      // Nếu có results field
      else if (result.containsKey('results')) {
        final results = result['results'] ?? [];
        debugPrint('AuthProvider: Found ${results.length} users in results');
        return List<Map<String, dynamic>>.from(results);
      } else {
        debugPrint('AuthProvider: Unknown response structure: ${result.keys}');
        return [];
      }
    } catch (e) {
      debugPrint('Error getting all users: $e');
      return [];
    }
  }

  /// Tạo user mới
  Future<bool> createUser(Map<String, dynamic> userData) async {
    try {
      await ApiService.createUser(userData);
      return true;
    } catch (e) {
      debugPrint('Error creating user: $e');
      return false;
    }
  }

  /// Cập nhật user
  Future<bool> updateUser(int userId, Map<String, dynamic> userData) async {
    try {
      await ApiService.updateEmployee(userId, userData);
      return true;
    } catch (e) {
      debugPrint('Error updating user: $e');
      return false;
    }
  }

  /// Xóa user
  Future<bool> deleteUser(int userId) async {
    try {
      await ApiService.deactivateEmployee(userId);
      return true;
    } catch (e) {
      debugPrint('Error deleting user: $e');
      return false;
    }
  }

  // ==================== LEAVE REQUEST METHODS ====================

  /// Tạo yêu cầu nghỉ phép
  Future<bool> createLeaveRequest(Map<String, dynamic> requestData) async {
    try {
      await ApiService.createLeaveRequest(requestData);
      return true;
    } catch (e) {
      debugPrint('Error creating leave request: $e');
      return false;
    }
  }

  /// Duyệt yêu cầu nghỉ phép
  Future<bool> approveLeaveRequest(
    int id,
    Map<String, dynamic> approvalData,
  ) async {
    try {
      await ApiService.approveLeaveRequest(id, approvalData);
      return true;
    } catch (e) {
      debugPrint('Error approving leave request: $e');
      return false;
    }
  }

  /// Từ chối yêu cầu nghỉ phép
  Future<bool> rejectLeaveRequest(
    int id,
    Map<String, dynamic> rejectionData,
  ) async {
    try {
      await ApiService.rejectLeaveRequest(id, rejectionData);
      return true;
    } catch (e) {
      debugPrint('Error rejecting leave request: $e');
      return false;
    }
  }

  /// Hủy yêu cầu nghỉ phép
  Future<bool> cancelLeaveRequest(int id) async {
    try {
      await ApiService.cancelLeaveRequest(id);
      return true;
    } catch (e) {
      debugPrint('Error cancelling leave request: $e');
      return false;
    }
  }

  // ==================== DEPARTMENT METHODS ====================

  /// Lấy danh sách phòng ban
  Future<List<Map<String, dynamic>>> getDepartments() async {
    try {
      return await ApiService.getDepartmentsForDropdown();
    } catch (e) {
      debugPrint('Error getting departments: $e');
      return [];
    }
  }

  /// Tạo phòng ban mới
  Future<bool> createDepartment(Map<String, dynamic> departmentData) async {
    try {
      await ApiService.createDepartment(departmentData);
      return true;
    } catch (e) {
      debugPrint('Error creating department: $e');
      return false;
    }
  }

  /// Cập nhật phòng ban
  Future<bool> updateDepartment(
    int id,
    Map<String, dynamic> departmentData,
  ) async {
    try {
      await ApiService.updateDepartment(id, departmentData);
      return true;
    } catch (e) {
      debugPrint('Error updating department: $e');
      return false;
    }
  }

  // ==================== LEAVE TYPE METHODS ====================

  /// Lấy danh sách loại nghỉ phép
  Future<List<Map<String, dynamic>>> getLeaveTypes() async {
    try {
      return await ApiService.getLeaveTypes();
    } catch (e) {
      debugPrint('Error getting leave types: $e');
      return [];
    }
  }

  /// Tạo loại nghỉ phép mới
  Future<bool> createLeaveType(Map<String, dynamic> leaveTypeData) async {
    try {
      await ApiService.createLeaveType(leaveTypeData);
      return true;
    } catch (e) {
      debugPrint('Error creating leave type: $e');
      return false;
    }
  }

  /// Cập nhật loại nghỉ phép
  Future<bool> updateLeaveType(
    int id,
    Map<String, dynamic> leaveTypeData,
  ) async {
    try {
      await ApiService.updateLeaveType(id, leaveTypeData);
      return true;
    } catch (e) {
      debugPrint('Error updating leave type: $e');
      return false;
    }
  }

  // ==================== APPROVAL CONFIG METHODS ====================

  /// Lấy danh sách cấu hình duyệt
  Future<List<Map<String, dynamic>>> getApprovalConfigs() async {
    try {
      return await ApiService.getApprovalConfigs();
    } catch (e) {
      debugPrint('Error getting approval configs: $e');
      return [];
    }
  }

  /// Tạo cấu hình duyệt mới
  Future<bool> createApprovalConfig(Map<String, dynamic> configData) async {
    try {
      await ApiService.createApprovalConfig(configData);
      return true;
    } catch (e) {
      debugPrint('Error creating approval config: $e');
      return false;
    }
  }

  /// Cập nhật cấu hình duyệt
  Future<bool> updateApprovalConfig(
    int id,
    Map<String, dynamic> configData,
  ) async {
    try {
      await ApiService.updateApprovalConfig(id, configData);
      return true;
    } catch (e) {
      debugPrint('Error updating approval config: $e');
      return false;
    }
  }

  // ==================== ROLES & POSITION TYPES METHODS ====================

  /// Lấy danh sách Roles
  Future<List<Map<String, dynamic>>> getRoles() async {
    try {
      return await ApiService.getRoles();
    } catch (e) {
      debugPrint('Error getting roles: $e');
      return [];
    }
  }

  /// Lấy danh sách Position Types
  Future<List<Map<String, dynamic>>> getPositionTypes() async {
    try {
      return await ApiService.getPositionTypes();
    } catch (e) {
      debugPrint('Error getting position types: $e');
      return [];
    }
  }

  /// Lấy danh sách chức vụ có quyền duyệt
  Future<List<Map<String, dynamic>>> getApprovalPositions() async {
    try {
      return await ApiService.getApprovalPositions();
    } catch (e) {
      debugPrint('Error getting approval positions: $e');
      return [];
    }
  }
}
