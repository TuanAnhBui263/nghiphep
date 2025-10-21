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

  /// Lấy danh sách yêu cầu nghỉ phép (có phân trang, tìm kiếm, lọc theo phòng ban)
  static Future<Map<String, dynamic>> getLeaveRequests({
    int pageNumber = 1,
    int pageSize = 100,
    int? userId,
    String? status,
    DateTime? startDateFrom,
    DateTime? startDateTo,
    int? departmentId,
  }) async {
    final queryParams = <String, String>{
      'pageNumber': pageNumber.toString(),
      'pageSize': pageSize.toString(),
    };

    if (userId != null) {
      queryParams['userId'] = userId.toString();
    }
    if (status != null && status.isNotEmpty) {
      queryParams['status'] = status;
    }
    if (startDateFrom != null) {
      queryParams['startDateFrom'] = startDateFrom.toIso8601String();
    }
    if (startDateTo != null) {
      queryParams['startDateTo'] = startDateTo.toIso8601String();
    }
    if (departmentId != null) {
      queryParams['departmentId'] = departmentId.toString();
    }

    final uri = Uri.parse(
      '$baseUrl/LeaveRequests',
    ).replace(queryParameters: queryParams);

    final response = await _makeRequest(
      'GET',
      uri.toString().replaceFirst(baseUrl, ''),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Không thể lấy danh sách yêu cầu nghỉ phép');
    }
  }

  /// Lấy chi tiết yêu cầu nghỉ phép theo ID
  static Future<Map<String, dynamic>> getLeaveRequestById(int id) async {
    final response = await _makeRequest('GET', '/LeaveRequests/$id');

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else if (response.statusCode == 404) {
      throw Exception('Không tìm thấy yêu cầu nghỉ phép');
    } else if (response.statusCode == 403) {
      throw Exception('Bạn không có quyền truy cập yêu cầu nghỉ phép này');
    } else {
      throw Exception('Không thể lấy thông tin yêu cầu nghỉ phép');
    }
  }

  /// Lấy danh sách yêu cầu nghỉ phép của tôi
  static Future<Map<String, dynamic>> getMyLeaveRequests({
    int pageNumber = 1,
    int pageSize = 10,
  }) async {
    final queryParams = <String, String>{
      'pageNumber': pageNumber.toString(),
      'pageSize': pageSize.toString(),
    };

    final uri = Uri.parse(
      '$baseUrl/LeaveRequests/my-requests',
    ).replace(queryParameters: queryParams);

    final response = await _makeRequest(
      'GET',
      uri.toString().replaceFirst(baseUrl, ''),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Không thể lấy danh sách yêu cầu nghỉ phép');
    }
  }

  /// Lấy danh sách yêu cầu cần duyệt
  static Future<Map<String, dynamic>> getPendingApprovals({
    int pageNumber = 1,
    int pageSize = 10,
  }) async {
    final queryParams = <String, String>{
      'pageNumber': pageNumber.toString(),
      'pageSize': pageSize.toString(),
    };

    final uri = Uri.parse(
      '$baseUrl/LeaveRequests/pending-approvals',
    ).replace(queryParameters: queryParams);

    final response = await _makeRequest(
      'GET',
      uri.toString().replaceFirst(baseUrl, ''),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Không thể lấy danh sách yêu cầu cần duyệt');
    }
  }

  /// Lấy thống kê yêu cầu nghỉ phép của tôi
  static Future<Map<String, dynamic>> getMyStatistics() async {
    final response = await _makeRequest('GET', '/LeaveRequests/my-statistics');

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Không thể lấy thống kê');
    }
  }

  /// Tạo yêu cầu nghỉ phép mới
  static Future<Map<String, dynamic>> createLeaveRequest(
    Map<String, dynamic> requestData,
  ) async {
    final response = await _makeRequest(
      'POST',
      '/LeaveRequests',
      body: requestData,
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else if (response.statusCode == 400) {
      final errorBody = jsonDecode(response.body);
      throw Exception(errorBody['message'] ?? 'Dữ liệu không hợp lệ');
    } else {
      throw Exception('Không thể tạo yêu cầu nghỉ phép');
    }
  }

  /// Duyệt yêu cầu nghỉ phép
  static Future<void> approveLeaveRequest(
    int id,
    Map<String, dynamic> approvalData,
  ) async {
    final response = await _makeRequest(
      'POST',
      '/LeaveRequests/$id/approve',
      body: approvalData,
    );

    if (response.statusCode == 200) {
      return;
    } else if (response.statusCode == 400) {
      final errorBody = jsonDecode(response.body);
      throw Exception(
        errorBody['message'] ?? 'Không thể duyệt yêu cầu nghỉ phép',
      );
    } else {
      throw Exception('Không thể duyệt yêu cầu nghỉ phép');
    }
  }

  /// Từ chối yêu cầu nghỉ phép
  static Future<void> rejectLeaveRequest(
    int id,
    Map<String, dynamic> rejectionData,
  ) async {
    final response = await _makeRequest(
      'POST',
      '/LeaveRequests/$id/reject',
      body: rejectionData,
    );

    if (response.statusCode == 200) {
      return;
    } else if (response.statusCode == 400) {
      final errorBody = jsonDecode(response.body);
      throw Exception(
        errorBody['message'] ?? 'Không thể từ chối yêu cầu nghỉ phép',
      );
    } else {
      throw Exception('Không thể từ chối yêu cầu nghỉ phép');
    }
  }

  /// Hủy yêu cầu nghỉ phép
  static Future<void> cancelLeaveRequest(int id) async {
    final response = await _makeRequest('POST', '/LeaveRequests/$id/cancel');

    if (response.statusCode == 200) {
      return;
    } else if (response.statusCode == 400) {
      final errorBody = jsonDecode(response.body);
      throw Exception(
        errorBody['message'] ?? 'Không thể hủy yêu cầu nghỉ phép',
      );
    } else {
      throw Exception('Không thể hủy yêu cầu nghỉ phép');
    }
  }

  /// Lấy thống kê theo phòng ban
  static Future<Map<String, dynamic>> getDepartmentStatistics({
    int? departmentId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final queryParams = <String, String>{};

    if (departmentId != null) {
      queryParams['departmentId'] = departmentId.toString();
    }
    if (startDate != null) {
      queryParams['startDate'] = startDate.toIso8601String();
    }
    if (endDate != null) {
      queryParams['endDate'] = endDate.toIso8601String();
    }

    final uri = Uri.parse(
      '$baseUrl/LeaveRequests/department-statistics',
    ).replace(queryParameters: queryParams);

    final response = await _makeRequest(
      'GET',
      uri.toString().replaceFirst(baseUrl, ''),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Không thể lấy thống kê phòng ban');
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

  /// Lấy danh sách loại nghỉ phép
  static Future<List<Map<String, dynamic>>> getLeaveTypes() async {
    final response = await _makeRequest('GET', '/LeaveTypes');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data);
    } else {
      throw Exception('Không thể lấy danh sách loại nghỉ phép');
    }
  }

  /// Tạo loại nghỉ phép mới
  static Future<Map<String, dynamic>> createLeaveType(
    Map<String, dynamic> leaveTypeData,
  ) async {
    final response = await _makeRequest(
      'POST',
      '/LeaveTypes',
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
      '/LeaveTypes/$id',
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
    final response = await _makeRequest('GET', '/ApprovalConfigs');

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
      '/ApprovalConfigs',
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
      '/ApprovalConfigs/$id',
      body: configData,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Không thể cập nhật cấu hình duyệt');
    }
  }
}
