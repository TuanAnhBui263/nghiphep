import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/api_response.dart';
import '../models/login_request.dart';
import '../models/login_response.dart';
import '../models/refresh_token_request.dart';

class ApiService {
  static const String baseUrl = 'http://10.0.2.2:5119/api';
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userKey = 'user_info';

  // HTTP client
  static final http.Client _client = http.Client();

  // Headers cho requests
  static Map<String, String> _getHeaders({bool includeAuth = true}) {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (includeAuth) {
      // Token sẽ được thêm trong interceptor
    }

    return headers;
  }

  // Lấy access token từ storage
  static Future<String?> _getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_accessTokenKey);
  }

  // Lưu tokens vào storage
  static Future<void> _saveTokens(
    String accessToken,
    String refreshToken,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accessTokenKey, accessToken);
    await prefs.setString(_refreshTokenKey, refreshToken);
  }

  // Lưu user info vào storage
  static Future<void> _saveUserInfo(UserInfo userInfo) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(userInfo.toJson()));
  }

  // Lấy user info từ storage
  static Future<UserInfo?> _getUserInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString(_userKey);
      if (userJson != null) {
        final userMap = jsonDecode(userJson) as Map<String, dynamic>;
        return UserInfo.fromJson(userMap);
      }
    } catch (e) {
      print('Error getting user info: $e');
    }
    return null;
  }

  // Xóa tất cả data khỏi storage
  static Future<void> _clearStorage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessTokenKey);
    await prefs.remove(_refreshTokenKey);
    await prefs.remove(_userKey);
  }

  // HTTP request với retry logic cho token refresh
  static Future<http.Response> _makeRequest(
    String method,
    String endpoint, {
    Map<String, dynamic>? body,
    bool retryOnAuthFailure = true,
  }) async {
    print('=== HTTP REQUEST DEBUG ===');
    print('Method: $method');
    print('Endpoint: $endpoint');
    print('Full URL: $baseUrl$endpoint');

    final url = Uri.parse('$baseUrl$endpoint');
    final headers = _getHeaders();

    // Thêm access token nếu có
    final accessToken = await _getAccessToken();
    if (accessToken != null) {
      headers['Authorization'] = 'Bearer $accessToken';
    }

    print('Headers: $headers');
    print('Body: $body');

    http.Response response;

    try {
      switch (method.toUpperCase()) {
        case 'GET':
          response = await _client.get(url, headers: headers);
          break;
        case 'POST':
          response = await _client.post(
            url,
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          );
          break;
        case 'PUT':
          response = await _client.put(
            url,
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          );
          break;
        case 'DELETE':
          response = await _client.delete(url, headers: headers);
          break;
        default:
          throw Exception('Unsupported HTTP method: $method');
      }

      // Nếu token hết hạn và có thể retry
      if (response.statusCode == 401 && retryOnAuthFailure) {
        final refreshed = await _refreshToken();
        if (refreshed) {
          // Retry request với token mới
          return _makeRequest(
            method,
            endpoint,
            body: body,
            retryOnAuthFailure: false,
          );
        }
      }

      return response;
    } catch (e) {
      print('=== HTTP REQUEST ERROR ===');
      print('Error type: ${e.runtimeType}');
      print('Error message: $e');

      if (e is SocketException) {
        throw Exception(
          'Không thể kết nối đến server. Vui lòng kiểm tra kết nối mạng.',
        );
      }
      rethrow;
    }
  }

  // Refresh token
  static Future<bool> _refreshToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final refreshToken = prefs.getString(_refreshTokenKey);

      if (refreshToken == null) return false;

      final request = RefreshTokenRequest(refreshToken: refreshToken);
      final response = await _client.post(
        Uri.parse('$baseUrl/Auth/refresh-token'),
        headers: _getHeaders(includeAuth: false),
        body: jsonEncode(request.toJson()),
      );

      if (response.statusCode == 200) {
        final apiResponse = ApiResponse<LoginResponse>.fromJson(
          jsonDecode(response.body),
          (data) => LoginResponse.fromJson(data),
        );

        if (apiResponse.success && apiResponse.data != null) {
          await _saveTokens(
            apiResponse.data!.accessToken,
            apiResponse.data!.refreshToken,
          );
          await _saveUserInfo(apiResponse.data!.user);
          return true;
        }
      }

      return false;
    } catch (e) {
      print('Error refreshing token: $e');
      return false;
    }
  }

  // ==================== AUTHENTICATION METHODS ====================

  /// Đăng nhập
  static Future<LoginResponse> login(String email, String password) async {
    try {
      print('=== LOGIN DEBUG ===');
      print('Email: $email');
      print('Password: $password');
      print('Base URL: $baseUrl');
      print('Full URL: $baseUrl/Auth/login');

      final request = LoginRequest(email: email, password: password);
      print('Request body: ${request.toJson()}');

      final response = await _makeRequest(
        'POST',
        '/Auth/login',
        body: request.toJson(),
        retryOnAuthFailure: false,
      );

      print('Login response status: ${response.statusCode}');
      print('Login response body: ${response.body}');

      if (response.statusCode == 200) {
        final apiResponse = ApiResponse<LoginResponse>.fromJson(
          jsonDecode(response.body),
          (data) => LoginResponse.fromJson(data),
        );

        if (apiResponse.success && apiResponse.data != null) {
          await _saveTokens(
            apiResponse.data!.accessToken,
            apiResponse.data!.refreshToken,
          );
          await _saveUserInfo(apiResponse.data!.user);
          return apiResponse.data!;
        } else {
          throw Exception(apiResponse.message);
        }
      } else if (response.statusCode == 401) {
        throw Exception('Email hoặc mật khẩu không đúng');
      } else {
        final errorBody = jsonDecode(response.body);
        throw Exception(errorBody['message'] ?? 'Đăng nhập thất bại');
      }
    } catch (e) {
      if (e.toString().contains('SocketException')) {
        throw Exception(
          'Không thể kết nối đến server. Vui lòng kiểm tra kết nối mạng.',
        );
      }
      rethrow;
    }
  }

  /// Đăng xuất
  static Future<void> logout() async {
    try {
      await _makeRequest('POST', '/Auth/logout');
    } catch (e) {
      print('Error during logout: $e');
    } finally {
      await _clearStorage();
    }
  }

  /// Lấy thông tin user hiện tại
  static Future<UserInfo?> getCurrentUser() async {
    try {
      final response = await _makeRequest('GET', '/Auth/me');

      if (response.statusCode == 200) {
        final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(
          jsonDecode(response.body),
          (data) => data,
        );

        if (apiResponse.success && apiResponse.data != null) {
          return UserInfo.fromJson(apiResponse.data!);
        }
      }

      return null;
    } catch (e) {
      print('Error getting current user: $e');
      return null;
    }
  }

  /// Kiểm tra trạng thái đăng nhập
  static Future<bool> isLoggedIn() async {
    final accessToken = await _getAccessToken();
    if (accessToken == null) return false;

    try {
      final user = await getCurrentUser();
      return user != null;
    } catch (e) {
      return false;
    }
  }

  /// Lấy user info từ storage (offline)
  static Future<UserInfo?> getStoredUserInfo() async {
    return _getUserInfo();
  }

  // ==================== EMPLOYEE METHODS ====================

  /// Lấy danh sách nhân viên (có phân trang, tìm kiếm, lọc theo phòng ban)
  static Future<Map<String, dynamic>> getEmployees({
    int pageNumber = 1,
    int pageSize = 100,
    String? searchTerm,
    int? departmentId,
    bool? isActive,
  }) async {
    print('=== GET EMPLOYEES DEBUG ===');
    print('PageNumber: $pageNumber');
    print('PageSize: $pageSize');
    print('SearchTerm: $searchTerm');
    print('DepartmentId: $departmentId');
    print('IsActive: $isActive');

    final queryParams = <String, String>{
      'pageNumber': pageNumber.toString(),
      'pageSize': pageSize.toString(),
    };

    if (searchTerm != null && searchTerm.isNotEmpty) {
      queryParams['searchTerm'] = searchTerm;
    }
    if (departmentId != null) {
      queryParams['departmentId'] = departmentId.toString();
    }
    if (isActive != null) {
      queryParams['isActive'] = isActive.toString();
    }

    final uri = Uri.parse(
      '$baseUrl/Employees',
    ).replace(queryParameters: queryParams);

    print('Full URL: $uri');

    final response = await _makeRequest(
      'GET',
      uri.toString().replaceFirst(baseUrl, ''),
    );

    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');

    if (response.statusCode == 200) {
      final result = jsonDecode(response.body);
      print('Parsed result: $result');
      return result;
    } else {
      print('Error response: ${response.statusCode} - ${response.body}');
      throw Exception(
        'Không thể lấy danh sách nhân viên: ${response.statusCode} - ${response.body}',
      );
    }
  }

  /// Lấy thông tin nhân viên hiện tại
  static Future<Map<String, dynamic>> getMyInfo() async {
    final response = await _makeRequest('GET', '/Employees/me');

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else if (response.statusCode == 401) {
      throw Exception('Phiên đăng nhập đã hết hạn');
    } else {
      throw Exception('Không thể lấy thông tin nhân viên');
    }
  }

  /// Lấy thông tin nhân viên theo ID
  static Future<Map<String, dynamic>> getEmployeeById(int id) async {
    final response = await _makeRequest('GET', '/Employees/$id');

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else if (response.statusCode == 404) {
      throw Exception('Không tìm thấy nhân viên');
    } else if (response.statusCode == 403) {
      throw Exception('Bạn không có quyền truy cập thông tin nhân viên này');
    } else {
      throw Exception('Không thể lấy thông tin nhân viên');
    }
  }

  // ==================== LEAVE REQUEST METHODS ====================

  /// Tạo đơn xin nghỉ mới
  static Future<Map<String, dynamic>> createLeaveRequest(
    Map<String, dynamic> requestData,
  ) async {
    final response = await _makeRequest(
      'POST',
      '/api/leaverequests',
      body: requestData,
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else if (response.statusCode == 400) {
      final errorBody = jsonDecode(response.body);
      throw Exception(errorBody['message'] ?? 'Dữ liệu không hợp lệ');
    } else {
      throw Exception('Không thể tạo đơn xin nghỉ');
    }
  }

  /// Lấy danh sách đơn của tôi
  static Future<Map<String, dynamic>> getMyLeaveRequests({
    String? status,
    int? month,
    int? year,
    int pageNumber = 1,
    int pageSize = 20,
  }) async {
    final queryParams = <String, String>{
      'pageNumber': pageNumber.toString(),
      'pageSize': pageSize.toString(),
    };

    if (status != null && status.isNotEmpty) {
      queryParams['status'] = status;
    }
    if (month != null) {
      queryParams['month'] = month.toString();
    }
    if (year != null) {
      queryParams['year'] = year.toString();
    }

    final uri = Uri.parse(
      '$baseUrl/api/leaverequests/my-requests',
    ).replace(queryParameters: queryParams);

    final response = await _makeRequest(
      'GET',
      uri.toString().replaceFirst(baseUrl, ''),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Không thể lấy danh sách đơn của tôi');
    }
  }

  /// Lấy chi tiết đơn
  static Future<Map<String, dynamic>> getLeaveRequestDetail(int id) async {
    final response = await _makeRequest('GET', '/api/leaverequests/$id');

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else if (response.statusCode == 404) {
      throw Exception('Không tìm thấy đơn xin nghỉ');
    } else if (response.statusCode == 403) {
      throw Exception('Bạn không có quyền truy cập đơn này');
    } else {
      throw Exception('Không thể lấy thông tin đơn xin nghỉ');
    }
  }

  /// Hủy đơn
  static Future<void> cancelLeaveRequest(int id) async {
    final response = await _makeRequest('POST', '/api/leaverequests/$id/cancel');

    if (response.statusCode == 200) {
      return;
    } else if (response.statusCode == 400) {
      final errorBody = jsonDecode(response.body);
      throw Exception(
        errorBody['message'] ?? 'Không thể hủy đơn',
      );
    } else {
      throw Exception('Không thể hủy đơn');
    }
  }

  /// Lấy đơn chờ duyệt (Manager/Admin)
  static Future<Map<String, dynamic>> getPendingApprovals({
    String? employeeName,
    int? leaveTypeId,
    DateTime? startDateFrom,
    DateTime? startDateTo,
    String? sortBy,
    String? sortDirection,
    int pageNumber = 1,
    int pageSize = 20,
  }) async {
    final queryParams = <String, String>{
      'pageNumber': pageNumber.toString(),
      'pageSize': pageSize.toString(),
    };

    if (employeeName != null && employeeName.isNotEmpty) {
      queryParams['employeeName'] = employeeName;
    }
    if (leaveTypeId != null) {
      queryParams['leaveTypeId'] = leaveTypeId.toString();
    }
    if (startDateFrom != null) {
      queryParams['startDateFrom'] = startDateFrom.toIso8601String().split('T')[0];
    }
    if (startDateTo != null) {
      queryParams['startDateTo'] = startDateTo.toIso8601String().split('T')[0];
    }
    if (sortBy != null && sortBy.isNotEmpty) {
      queryParams['sortBy'] = sortBy;
    }
    if (sortDirection != null && sortDirection.isNotEmpty) {
      queryParams['sortDirection'] = sortDirection;
    }

    final uri = Uri.parse(
      '$baseUrl/api/leaverequests/pending-approvals',
    ).replace(queryParameters: queryParams);

    final response = await _makeRequest(
      'GET',
      uri.toString().replaceFirst(baseUrl, ''),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Không thể lấy danh sách đơn chờ duyệt');
    }
  }

  /// Duyệt đơn (Manager/Admin)
  static Future<Map<String, dynamic>> approveLeaveRequest(
    int id,
    String? comments,
  ) async {
    final response = await _makeRequest(
      'POST',
      '/api/leaverequests/$id/approve',
      body: {'comments': comments ?? ''},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else if (response.statusCode == 400) {
      final errorBody = jsonDecode(response.body);
      throw Exception(
        errorBody['message'] ?? 'Không thể duyệt đơn',
      );
    } else {
      throw Exception('Không thể duyệt đơn');
    }
  }

  /// Từ chối đơn (Manager/Admin)
  static Future<Map<String, dynamic>> rejectLeaveRequest(
    int id,
    String comments,
  ) async {
    if (comments.isEmpty) {
      throw Exception('Vui lòng nhập lý do từ chối');
    }

    final response = await _makeRequest(
      'POST',
      '/api/leaverequests/$id/reject',
      body: {'comments': comments},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else if (response.statusCode == 400) {
      final errorBody = jsonDecode(response.body);
      throw Exception(
        errorBody['message'] ?? 'Không thể từ chối đơn',
      );
    } else {
      throw Exception('Không thể từ chối đơn');
    }
  }

  /// Lấy thống kê cá nhân
  static Future<Map<String, dynamic>> getMyStatistics({int? year}) async {
    final queryParams = <String, String>{};

    if (year != null) {
      queryParams['year'] = year.toString();
    }

    final uri = Uri.parse(
      '$baseUrl/api/leaverequests/my-statistics',
    ).replace(queryParameters: queryParams);

    final response = await _makeRequest(
      'GET',
      uri.toString().replaceFirst(baseUrl, ''),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Không thể lấy thống kê');
    }
  }

  /// Lấy loại nghỉ phép
  static Future<List<Map<String, dynamic>>> getLeaveTypes() async {
    final response = await _makeRequest('GET', '/api/leaverequests/leave-types');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data);
    } else {
      throw Exception('Không thể lấy danh sách loại nghỉ phép');
    }
  }

  /// Tạo nhân viên mới (User Registration)
  static Future<Map<String, dynamic>> createUser(
    Map<String, dynamic> userData,
  ) async {
    final response = await _makeRequest(
      'POST',
      '/api/auth/register',
      body: userData,
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else if (response.statusCode == 400) {
      final errorBody = jsonDecode(response.body);
      throw Exception(errorBody['message'] ?? 'Dữ liệu không hợp lệ');
    } else {
      throw Exception('Không thể tạo người dùng');
    }
  }

  /// Tạo nhân viên mới
  static Future<Map<String, dynamic>> createEmployee(
    Map<String, dynamic> employeeData,
  ) async {
    final response = await _makeRequest(
      'POST',
      '/Employees',
      body: employeeData,
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Không thể tạo nhân viên');
    }
  }

  /// Cập nhật thông tin nhân viên
  static Future<Map<String, dynamic>> updateEmployee(
    int id,
    Map<String, dynamic> employeeData,
  ) async {
    final response = await _makeRequest(
      'PUT',
      '/Employees/$id',
      body: employeeData,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Không thể cập nhật thông tin nhân viên');
    }
  }

  /// Vô hiệu hóa nhân viên
  static Future<void> deactivateEmployee(int id) async {
    final response = await _makeRequest('DELETE', '/Employees/$id');

    if (response.statusCode != 200) {
      throw Exception('Không thể vô hiệu hóa nhân viên');
    }
  }

  /// Kích hoạt lại nhân viên
  static Future<void> activateEmployee(int id) async {
    final response = await _makeRequest('PUT', '/Employees/$id/activate');

    if (response.statusCode != 200) {
      throw Exception('Không thể kích hoạt lại nhân viên');
    }
  }

  /// Gán nhân viên vào phòng ban
  static Future<void> assignDepartment(Map<String, dynamic> assignData) async {
    final response = await _makeRequest(
      'POST',
      '/Employees/assign-department',
      body: assignData,
    );

    if (response.statusCode != 200) {
      throw Exception('Không thể gán nhân viên vào phòng ban');
    }
  }

  /// Xóa nhân viên khỏi phòng ban
  static Future<void> removeFromDepartment(int userId, int departmentId) async {
    final response = await _makeRequest(
      'DELETE',
      '/Employees/$userId/departments/$departmentId',
    );

    if (response.statusCode != 200) {
      throw Exception('Không thể xóa nhân viên khỏi phòng ban');
    }
  }

  /// Lấy danh sách nhân viên theo phòng ban
  static Future<List<Map<String, dynamic>>> getEmployeesByDepartment(
    int departmentId,
  ) async {
    final response = await _makeRequest(
      'GET',
      '/Employees/department/$departmentId',
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data);
    } else {
      throw Exception('Không thể lấy danh sách nhân viên theo phòng ban');
    }
  }

  // ==================== DEPARTMENT METHODS ====================

  /// Lấy danh sách phòng ban cho dropdown (chỉ active)
  static Future<List<Map<String, dynamic>>> getDepartmentsForDropdown({
    bool activeOnly = true,
  }) async {
    final queryParams = <String, String>{'activeOnly': activeOnly.toString()};

    final uri = Uri.parse(
      '$baseUrl/Departments/dropdown',
    ).replace(queryParameters: queryParams);

    final response = await _makeRequest(
      'GET',
      uri.toString().replaceFirst(baseUrl, ''),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data);
    } else {
      throw Exception('Không thể lấy danh sách phòng ban cho dropdown');
    }
  }

  /// Lấy danh sách phòng ban (có phân trang, tìm kiếm, lọc)
  static Future<Map<String, dynamic>> getDepartments({
    int pageNumber = 1,
    int pageSize = 100,
    String? searchTerm,
    bool? isActive,
    int? organizationLevelId,
    int? parentDepartmentId,
  }) async {
    final queryParams = <String, String>{
      'pageNumber': pageNumber.toString(),
      'pageSize': pageSize.toString(),
    };

    if (searchTerm != null && searchTerm.isNotEmpty) {
      queryParams['searchTerm'] = searchTerm;
    }
    if (isActive != null) {
      queryParams['isActive'] = isActive.toString();
    }
    if (organizationLevelId != null) {
      queryParams['organizationLevelId'] = organizationLevelId.toString();
    }
    if (parentDepartmentId != null) {
      queryParams['parentDepartmentId'] = parentDepartmentId.toString();
    }

    final uri = Uri.parse(
      '$baseUrl/Departments',
    ).replace(queryParameters: queryParams);

    final response = await _makeRequest(
      'GET',
      uri.toString().replaceFirst(baseUrl, ''),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Không thể lấy danh sách phòng ban');
    }
  }

  /// Lấy chi tiết phòng ban theo ID
  static Future<Map<String, dynamic>> getDepartmentById(int id) async {
    final response = await _makeRequest('GET', '/Departments/$id');

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else if (response.statusCode == 404) {
      throw Exception('Không tìm thấy phòng ban');
    } else {
      throw Exception('Không thể lấy thông tin phòng ban');
    }
  }

  /// Lấy danh sách phòng ban con
  static Future<List<Map<String, dynamic>>> getSubDepartments(int id) async {
    final response = await _makeRequest(
      'GET',
      '/Departments/$id/sub-departments',
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data);
    } else if (response.statusCode == 404) {
      throw Exception('Không tìm thấy phòng ban');
    } else {
      throw Exception('Không thể lấy danh sách phòng ban con');
    }
  }

  /// Tạo phòng ban mới
  static Future<Map<String, dynamic>> createDepartment(
    Map<String, dynamic> departmentData,
  ) async {
    final response = await _makeRequest(
      'POST',
      '/Departments',
      body: departmentData,
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else if (response.statusCode == 400) {
      final errorBody = jsonDecode(response.body);
      throw Exception(errorBody['message'] ?? 'Dữ liệu không hợp lệ');
    } else {
      throw Exception('Không thể tạo phòng ban');
    }
  }

  /// Cập nhật phòng ban
  static Future<Map<String, dynamic>> updateDepartment(
    int id,
    Map<String, dynamic> departmentData,
  ) async {
    final response = await _makeRequest(
      'PUT',
      '/Departments/$id',
      body: departmentData,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else if (response.statusCode == 404) {
      throw Exception('Không tìm thấy phòng ban');
    } else if (response.statusCode == 400) {
      final errorBody = jsonDecode(response.body);
      throw Exception(errorBody['message'] ?? 'Dữ liệu không hợp lệ');
    } else {
      throw Exception('Không thể cập nhật phòng ban');
    }
  }

  /// Vô hiệu hóa phòng ban
  static Future<void> deactivateDepartment(int id) async {
    final response = await _makeRequest('DELETE', '/Departments/$id');

    if (response.statusCode == 200) {
      return;
    } else if (response.statusCode == 404) {
      throw Exception('Không tìm thấy phòng ban');
    } else if (response.statusCode == 400) {
      final errorBody = jsonDecode(response.body);
      throw Exception(
        errorBody['message'] ?? 'Không thể vô hiệu hóa phòng ban',
      );
    } else {
      throw Exception('Không thể vô hiệu hóa phòng ban');
    }
  }

  /// Kích hoạt lại phòng ban
  static Future<void> activateDepartment(int id) async {
    final response = await _makeRequest('PUT', '/Departments/$id/activate');

    if (response.statusCode == 200) {
      return;
    } else if (response.statusCode == 404) {
      throw Exception('Không tìm thấy phòng ban');
    } else if (response.statusCode == 400) {
      final errorBody = jsonDecode(response.body);
      throw Exception(errorBody['message'] ?? 'Không thể kích hoạt phòng ban');
    } else {
      throw Exception('Không thể kích hoạt phòng ban');
    }
  }

  // ==================== LEAVE TYPE METHODS ====================

  /// Tạo loại nghỉ phép mới
  static Future<Map<String, dynamic>> createLeaveType(
    Map<String, dynamic> leaveTypeData,
  ) async {
    final response = await _makeRequest(
      'POST',
      '/leaverequests/leave-types',
      body: leaveTypeData,
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Không thể tạo loại nghỉ phép');
    }
  }

  /// Cập nhật loại nghỉ phép
  static Future<Map<String, dynamic>> updateLeaveType(
    int id,
    Map<String, dynamic> leaveTypeData,
  ) async {
    final response = await _makeRequest(
      'PUT',
      '/leaverequests/leave-types/$id',
      body: leaveTypeData,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Không thể cập nhật loại nghỉ phép');
    }
  }

  // ==================== APPROVAL CONFIG METHODS ====================

  /// Lấy danh sách cấu hình duyệt
  static Future<List<Map<String, dynamic>>> getApprovalConfigs() async {
    final response = await _makeRequest('GET', '/approvalconfigs');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data);
    } else {
      throw Exception('Không thể lấy danh sách cấu hình duyệt');
    }
  }

  /// Tạo cấu hình duyệt mới
  static Future<Map<String, dynamic>> createApprovalConfig(
    Map<String, dynamic> configData,
  ) async {
    final response = await _makeRequest(
      'POST',
      '/approvalconfigs',
      body: configData,
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Không thể tạo cấu hình duyệt');
    }
  }

  /// Cập nhật cấu hình duyệt
  static Future<Map<String, dynamic>> updateApprovalConfig(
    int id,
    Map<String, dynamic> configData,
  ) async {
    final response = await _makeRequest(
      'PUT',
      '/approvalconfigs/$id',
      body: configData,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Không thể cập nhật cấu hình duyệt');
    }
  }

  // ==================== ROLES & POSITION TYPES API ====================

  /// Lấy danh sách Roles
  static Future<List<Map<String, dynamic>>> getRoles() async {
    final response = await _makeRequest('GET', '/roles');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data);
    } else {
      throw Exception('Không thể lấy danh sách roles');
    }
  }

  /// Lấy danh sách Position Types
  static Future<List<Map<String, dynamic>>> getPositionTypes() async {
    final response = await _makeRequest('GET', '/positiontypes');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data);
    } else {
      throw Exception('Không thể lấy danh sách position types');
    }
  }

  /// Lấy danh sách chức vụ có quyền duyệt
  static Future<List<Map<String, dynamic>>> getApprovalPositions() async {
    final response = await _makeRequest('GET', '/positiontypes/approval-positions');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data);
    } else {
      throw Exception('Không thể lấy danh sách chức vụ có quyền duyệt');
    }
  }
}


