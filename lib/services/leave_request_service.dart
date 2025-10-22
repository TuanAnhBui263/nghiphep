import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/leave_request_models.dart';
import '../models/leave_type.dart';
import '../models/api_response.dart';
import 'api_service.dart';

class LeaveRequestService {
  static const String baseUrl = 'http://10.0.2.2:5119/api';
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';

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

  // HTTP request với retry logic cho token refresh
  static Future<http.Response> _makeRequest(
    String method,
    String endpoint, {
    Map<String, dynamic>? body,
    bool retryOnAuthFailure = true,
  }) async {
    print('=== LEAVE REQUEST API DEBUG ===');
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
      print('=== LEAVE REQUEST API ERROR ===');
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

      final response = await _client.post(
        Uri.parse('$baseUrl/Auth/refresh-token'),
        headers: _getHeaders(includeAuth: false),
        body: jsonEncode({'refreshToken': refreshToken}),
      );

      if (response.statusCode == 200) {
        final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(
          jsonDecode(response.body),
          (data) => data,
        );

        if (apiResponse.success && apiResponse.data != null) {
          await prefs.setString(_accessTokenKey, apiResponse.data!['accessToken']);
          await prefs.setString(_refreshTokenKey, apiResponse.data!['refreshToken']);
          return true;
        }
      }

      return false;
    } catch (e) {
      print('Error refreshing token: $e');
      return false;
    }
  }

  // ==================== LEAVE TYPES ====================

  /// Lấy danh sách loại nghỉ phép
  static Future<List<LeaveType>> getLeaveTypes() async {
    final response = await _makeRequest('GET', '/leave-requests/leave-types');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List;
      return data.map((e) => LeaveType.fromJson(e)).toList();
    } else {
      throw Exception('Không thể lấy danh sách loại nghỉ phép');
    }
  }

  // ==================== MY LEAVE REQUESTS (EMPLOYEE) ====================

  /// Lấy danh sách đơn nghỉ phép của tôi
  static Future<PagedResult<LeaveRequestSummary>> getMyRequests({
    String? status,
    int? month,
    int? year,
    int pageNumber = 1,
    int pageSize = 1000,
  }) async {
    final queryParams = <String, String>{
      'pageNumber': pageNumber.toString(),
      'pageSize': pageSize.toString(),
    };

    if (status != null) queryParams['status'] = status;
    if (month != null) queryParams['month'] = month.toString();
    if (year != null) queryParams['year'] = year.toString();

    final uri = Uri.parse('$baseUrl/leave-requests/my-requests')
        .replace(queryParameters: queryParams);

    final response = await _makeRequest(
      'GET',
      uri.toString().replaceFirst(baseUrl, ''),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return PagedResult.fromJson(
        data,
        (json) => LeaveRequestSummary.fromJson(json),
      );
    } else {
      throw Exception('Không thể lấy danh sách đơn nghỉ phép của tôi');
    }
  }

  // ==================== PENDING APPROVALS (MANAGER/ADMIN) ====================

  /// Lấy danh sách đơn pending cần duyệt
  static Future<PagedResult<LeaveRequestSummary>> getPendingApprovals({
    String? employeeName,
    int? leaveTypeId,
    DateTime? startDateFrom,
    DateTime? startDateTo,
    String sortBy = 'CreatedAt',
    String sortDirection = 'DESC',
    int pageNumber = 1,
    int pageSize = 1000,
  }) async {
    final queryParams = <String, String>{
      'pageNumber': pageNumber.toString(),
      'pageSize': pageSize.toString(),
      'sortBy': sortBy,
      'sortDirection': sortDirection,
    };

    if (employeeName != null) queryParams['employeeName'] = employeeName;
    if (leaveTypeId != null) queryParams['leaveTypeId'] = leaveTypeId.toString();
    if (startDateFrom != null) {
      queryParams['startDateFrom'] = startDateFrom.toIso8601String();
    }
    if (startDateTo != null) {
      queryParams['startDateTo'] = startDateTo.toIso8601String();
    }

    final uri = Uri.parse('$baseUrl/leave-requests/pending-approvals')
        .replace(queryParameters: queryParams);

    final response = await _makeRequest(
      'GET',
      uri.toString().replaceFirst(baseUrl, ''),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return PagedResult.fromJson(
        data,
        (json) => LeaveRequestSummary.fromJson(json),
      );
    } else {
      throw Exception('Không thể lấy danh sách đơn cần duyệt');
    }
  }

  // ==================== ADMIN FULL ACCESS ====================

  /// Lấy tất cả đơn nghỉ phép (Admin only)
  static Future<PagedResult<LeaveRequestSummary>> getAllRequests({
    int? userId,
    String? status,
    int? leaveTypeId,
    DateTime? startDateFrom,
    DateTime? startDateTo,
    String? employeeName,
    String sortBy = 'CreatedAt',
    String sortDirection = 'DESC',
    int pageNumber = 1,
    int pageSize = 1000,
  }) async {
    final queryParams = <String, String>{
      'pageNumber': pageNumber.toString(),
      'pageSize': pageSize.toString(),
      'sortBy': sortBy,
      'sortDirection': sortDirection,
    };

    if (userId != null) queryParams['userId'] = userId.toString();
    if (status != null) queryParams['status'] = status;
    if (leaveTypeId != null) queryParams['leaveTypeId'] = leaveTypeId.toString();
    if (startDateFrom != null) {
      queryParams['startDateFrom'] = startDateFrom.toIso8601String();
    }
    if (startDateTo != null) {
      queryParams['startDateTo'] = startDateTo.toIso8601String();
    }
    if (employeeName != null) queryParams['employeeName'] = employeeName;

    final uri = Uri.parse('$baseUrl/leave-requests/admin/all-requests')
        .replace(queryParameters: queryParams);

    final response = await _makeRequest(
      'GET',
      uri.toString().replaceFirst(baseUrl, ''),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return PagedResult.fromJson(
        data,
        (json) => LeaveRequestSummary.fromJson(json),
      );
    } else {
      throw Exception('Không thể lấy danh sách tất cả đơn nghỉ phép');
    }
  }

  // ==================== CREATE LEAVE REQUEST ====================

  /// Tạo đơn nghỉ phép mới
  static Future<LeaveRequestFull> createLeaveRequest(
    CreateLeaveRequestDto dto,
  ) async {
    final response = await _makeRequest(
      'POST',
      '/leave-requests',
      body: dto.toJson(),
    );

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return LeaveRequestFull.fromJson(data);
    } else if (response.statusCode == 400) {
      final errorBody = jsonDecode(response.body);
      throw Exception(errorBody['message'] ?? 'Dữ liệu không hợp lệ');
    } else {
      throw Exception('Không thể tạo đơn nghỉ phép');
    }
  }

  // ==================== GET SINGLE REQUEST ====================

  /// Lấy chi tiết đơn nghỉ phép theo ID
  static Future<LeaveRequestFull> getLeaveRequest(int id) async {
    final response = await _makeRequest('GET', '/leave-requests/$id');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return LeaveRequestFull.fromJson(data);
    } else if (response.statusCode == 404) {
      throw Exception('Không tìm thấy đơn nghỉ phép');
    } else if (response.statusCode == 403) {
      throw Exception('Bạn không có quyền truy cập đơn nghỉ phép này');
    } else {
      throw Exception('Không thể lấy thông tin đơn nghỉ phép');
    }
  }

  // ==================== APPROVE/REJECT/CANCEL ====================

  /// Duyệt đơn nghỉ phép
  static Future<void> approveLeaveRequest(
    int id,
    int approvalLevelId,
    String comments,
  ) async {
    final response = await _makeRequest(
      'POST',
      '/leave-requests/$id/approve',
      body: {
        'approvalLevelId': approvalLevelId,
        'comments': comments,
      },
    );

    if (response.statusCode == 200) {
      return;
    } else if (response.statusCode == 400) {
      final errorBody = jsonDecode(response.body);
      throw Exception(errorBody['message'] ?? 'Không thể duyệt đơn nghỉ phép');
    } else {
      throw Exception('Không thể duyệt đơn nghỉ phép');
    }
  }

  /// Từ chối đơn nghỉ phép
  static Future<void> rejectLeaveRequest(
    int id,
    int approvalLevelId,
    String comments,
  ) async {
    final response = await _makeRequest(
      'POST',
      '/leave-requests/$id/reject',
      body: {
        'approvalLevelId': approvalLevelId,
        'comments': comments,
      },
    );

    if (response.statusCode == 200) {
      return;
    } else if (response.statusCode == 400) {
      final errorBody = jsonDecode(response.body);
      throw Exception(errorBody['message'] ?? 'Không thể từ chối đơn nghỉ phép');
    } else {
      throw Exception('Không thể từ chối đơn nghỉ phép');
    }
  }

  /// Hủy đơn nghỉ phép
  static Future<void> cancelLeaveRequest(int id) async {
    final response = await _makeRequest('POST', '/leave-requests/$id/cancel');

    if (response.statusCode == 200) {
      return;
    } else if (response.statusCode == 400) {
      final errorBody = jsonDecode(response.body);
      throw Exception(errorBody['message'] ?? 'Không thể hủy đơn nghỉ phép');
    } else {
      throw Exception('Không thể hủy đơn nghỉ phép');
    }
  }

  // ==================== STATISTICS ====================

  /// Lấy thống kê đơn nghỉ phép của tôi
  static Future<LeaveStatistics> getMyStatistics({int? year}) async {
    final queryParams = <String, String>{};
    if (year != null) queryParams['year'] = year.toString();

    final uri = Uri.parse('$baseUrl/leave-requests/my-statistics')
        .replace(queryParameters: queryParams);

    final response = await _makeRequest(
      'GET',
      uri.toString().replaceFirst(baseUrl, ''),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return LeaveStatistics.fromJson(data);
    } else {
      throw Exception('Không thể lấy thống kê');
    }
  }

  /// Lấy thống kê theo phòng ban
  static Future<DepartmentStatistics> getDepartmentStatistics({
    int? departmentId,
    int? year,
    int? month,
  }) async {
    final queryParams = <String, String>{};
    if (departmentId != null) queryParams['departmentId'] = departmentId.toString();
    if (year != null) queryParams['year'] = year.toString();
    if (month != null) queryParams['month'] = month.toString();

    final uri = Uri.parse('$baseUrl/leave-requests/department-statistics')
        .replace(queryParameters: queryParams);

    final response = await _makeRequest(
      'GET',
      uri.toString().replaceFirst(baseUrl, ''),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return DepartmentStatistics.fromJson(data);
    } else {
      throw Exception('Không thể lấy thống kê phòng ban');
    }
  }
}
