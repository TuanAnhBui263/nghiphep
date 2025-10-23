import '../models/leave_request_dto.dart';
import 'api_service.dart';

class LeaveRequestService {
  /// Tạo đơn xin nghỉ mới
  static Future<LeaveRequestResponse> createLeaveRequest(LeaveRequestDto dto) async {
    final response = await ApiService.createLeaveRequest(dto.toJson());
    return LeaveRequestResponse.fromJson(response['data']);
  }

  /// Lấy danh sách đơn của tôi
  static Future<PagedResult<LeaveRequestSummary>> getMyLeaveRequests({
    String? status,
    int? month,
    int? year,
    int pageNumber = 1,
    int pageSize = 20,
  }) async {
    final response = await ApiService.getMyLeaveRequests(
      status: status,
      month: month,
      year: year,
      pageNumber: pageNumber,
      pageSize: pageSize,
    );
    
    return PagedResult.fromJson(
      response['data'],
      (json) => LeaveRequestSummary.fromJson(json),
    );
  }

  /// Lấy chi tiết đơn
  static Future<LeaveRequestDetail> getLeaveRequestDetail(int id) async {
    final response = await ApiService.getLeaveRequestDetail(id);
    return LeaveRequestDetail.fromJson(response['data']);
  }

  /// Hủy đơn
  static Future<void> cancelLeaveRequest(int id) async {
    await ApiService.cancelLeaveRequest(id);
  }

  /// Lấy đơn chờ duyệt (Manager/Admin)
  static Future<PagedResult<LeaveRequestSummary>> getPendingApprovals({
    String? employeeName,
    int? leaveTypeId,
    DateTime? startDateFrom,
    DateTime? startDateTo,
    String? sortBy,
    String? sortDirection,
    int pageNumber = 1,
    int pageSize = 20,
  }) async {
    final response = await ApiService.getPendingApprovals(
      employeeName: employeeName,
      leaveTypeId: leaveTypeId,
      startDateFrom: startDateFrom,
      startDateTo: startDateTo,
      sortBy: sortBy,
      sortDirection: sortDirection,
      pageNumber: pageNumber,
      pageSize: pageSize,
    );
    
    return PagedResult.fromJson(
      response['data'],
      (json) => LeaveRequestSummary.fromJson(json),
    );
  }

  /// Duyệt đơn (Manager/Admin)
  static Future<LeaveRequestDetail> approveLeaveRequest(int id, String? comments) async {
    final response = await ApiService.approveLeaveRequest(id, comments);
    return LeaveRequestDetail.fromJson(response['data']);
  }

  /// Từ chối đơn (Manager/Admin)
  static Future<LeaveRequestDetail> rejectLeaveRequest(int id, String comments) async {
    final response = await ApiService.rejectLeaveRequest(id, comments);
    return LeaveRequestDetail.fromJson(response['data']);
  }

  /// Lấy thống kê cá nhân
  static Future<LeaveStatistics> getMyStatistics({int? year}) async {
    final response = await ApiService.getMyStatistics(year: year);
    return LeaveStatistics.fromJson(response['data']);
  }

  /// Lấy loại nghỉ phép
  static Future<List<LeaveType>> getLeaveTypes() async {
    final response = await ApiService.getLeaveTypes();
    return response.map((json) => LeaveType.fromJson(json)).toList();
  }
}