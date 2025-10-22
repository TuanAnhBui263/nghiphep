// Leave Request Status Enum
enum LeaveRequestStatus {
  pending('PENDING', 'Chờ duyệt'),
  approved('APPROVED', 'Đã duyệt'),
  rejected('REJECTED', 'Từ chối'),
  cancelled('CANCELLED', 'Đã hủy');

  const LeaveRequestStatus(this.value, this.displayName);
  final String value;
  final String displayName;

  static LeaveRequestStatus fromString(String value) {
    return LeaveRequestStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => LeaveRequestStatus.pending,
    );
  }
}

// Session Enum
enum Session {
  morning('MORNING', 'Buổi sáng'),
  afternoon('AFTERNOON', 'Buổi chiều'),
  full('FULL', 'Cả ngày');

  const Session(this.value, this.displayName);
  final String value;
  final String displayName;

  static Session fromString(String value) {
    return Session.values.firstWhere(
      (session) => session.value == value,
      orElse: () => Session.full,
    );
  }
}

// Leave Request Summary (for lists)
class LeaveRequestSummary {
  final int id;
  final String requestCode;
  final String employeeName;
  final String leaveTypeName;
  final DateTime startDate;
  final DateTime endDate;
  final double totalDays;
  final LeaveRequestStatus status;
  final DateTime createdAt;

  LeaveRequestSummary({
    required this.id,
    required this.requestCode,
    required this.employeeName,
    required this.leaveTypeName,
    required this.startDate,
    required this.endDate,
    required this.totalDays,
    required this.status,
    required this.createdAt,
  });

  factory LeaveRequestSummary.fromJson(Map<String, dynamic> json) {
    return LeaveRequestSummary(
      id: json['id'],
      requestCode: json['requestCode'],
      employeeName: json['employeeName'],
      leaveTypeName: json['leaveTypeName'],
      startDate: DateTime.parse(json['startDate']),
      endDate: DateTime.parse(json['endDate']),
      totalDays: json['totalDays'].toDouble(),
      status: LeaveRequestStatus.fromString(json['status']),
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'requestCode': requestCode,
      'employeeName': employeeName,
      'leaveTypeName': leaveTypeName,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'totalDays': totalDays,
      'status': status.value,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

// Leave Detail (for individual days)
class LeaveDetail {
  final int id;
  final DateTime leaveDate;
  final Session session;
  final double dayValue;

  LeaveDetail({
    required this.id,
    required this.leaveDate,
    required this.session,
    required this.dayValue,
  });

  factory LeaveDetail.fromJson(Map<String, dynamic> json) {
    return LeaveDetail(
      id: json['id'],
      leaveDate: DateTime.parse(json['leaveDate']),
      session: Session.fromString(json['session']),
      dayValue: json['dayValue'].toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'leaveDate': leaveDate.toIso8601String(),
      'session': session.value,
      'dayValue': dayValue,
    };
  }
}

// Approval Info
class ApprovalInfo {
  final int id;
  final String approvalLevelName;
  final String approverName;
  final LeaveRequestStatus status;
  final String comments;
  final DateTime? approvedAt;

  ApprovalInfo({
    required this.id,
    required this.approvalLevelName,
    required this.approverName,
    required this.status,
    required this.comments,
    this.approvedAt,
  });

  factory ApprovalInfo.fromJson(Map<String, dynamic> json) {
    return ApprovalInfo(
      id: json['id'],
      approvalLevelName: json['approvalLevelName'],
      approverName: json['approverName'],
      status: LeaveRequestStatus.fromString(json['status']),
      comments: json['comments'] ?? '',
      approvedAt: json['approvedAt'] != null 
          ? DateTime.parse(json['approvedAt']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'approvalLevelName': approvalLevelName,
      'approverName': approverName,
      'status': status.value,
      'comments': comments,
      'approvedAt': approvedAt?.toIso8601String(),
    };
  }
}

// Full Leave Request (with all details)
class LeaveRequestFull {
  final int id;
  final String requestCode;
  final String employeeName;
  final String leaveTypeName;
  final DateTime startDate;
  final DateTime endDate;
  final Session startSession;
  final Session endSession;
  final double totalDays;
  final String reason;
  final LeaveRequestStatus status;
  final List<LeaveDetail> leaveDetails;
  final List<ApprovalInfo> approvals;
  final DateTime createdAt;

  LeaveRequestFull({
    required this.id,
    required this.requestCode,
    required this.employeeName,
    required this.leaveTypeName,
    required this.startDate,
    required this.endDate,
    required this.startSession,
    required this.endSession,
    required this.totalDays,
    required this.reason,
    required this.status,
    required this.leaveDetails,
    required this.approvals,
    required this.createdAt,
  });

  factory LeaveRequestFull.fromJson(Map<String, dynamic> json) {
    return LeaveRequestFull(
      id: json['id'],
      requestCode: json['requestCode'],
      employeeName: json['employeeName'],
      leaveTypeName: json['leaveTypeName'],
      startDate: DateTime.parse(json['startDate']),
      endDate: DateTime.parse(json['endDate']),
      startSession: Session.fromString(json['startSession']),
      endSession: Session.fromString(json['endSession']),
      totalDays: json['totalDays'].toDouble(),
      reason: json['reason'],
      status: LeaveRequestStatus.fromString(json['status']),
      leaveDetails: (json['leaveDetails'] as List?)
          ?.map((e) => LeaveDetail.fromJson(e))
          .toList() ?? [],
      approvals: (json['approvals'] as List?)
          ?.map((e) => ApprovalInfo.fromJson(e))
          .toList() ?? [],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'requestCode': requestCode,
      'employeeName': employeeName,
      'leaveTypeName': leaveTypeName,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'startSession': startSession.value,
      'endSession': endSession.value,
      'totalDays': totalDays,
      'reason': reason,
      'status': status.value,
      'leaveDetails': leaveDetails.map((e) => e.toJson()).toList(),
      'approvals': approvals.map((e) => e.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

// Create Leave Request DTO
class CreateLeaveRequestDto {
  final int leaveTypeId;
  final DateTime startDate;
  final DateTime endDate;
  final Session startSession;
  final Session endSession;
  final double totalDays;
  final String reason;

  CreateLeaveRequestDto({
    required this.leaveTypeId,
    required this.startDate,
    required this.endDate,
    required this.startSession,
    required this.endSession,
    required this.totalDays,
    required this.reason,
  });

  Map<String, dynamic> toJson() {
    return {
      'leaveTypeId': leaveTypeId,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'startSession': startSession.value,
      'endSession': endSession.value,
      'totalDays': totalDays,
      'reason': reason,
    };
  }
}

// Paged Result
class PagedResult<T> {
  final List<T> items;
  final int totalCount;
  final int pageNumber;
  final int pageSize;

  PagedResult({
    required this.items,
    required this.totalCount,
    required this.pageNumber,
    required this.pageSize,
  });

  factory PagedResult.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    return PagedResult(
      items: (json['items'] as List)
          .map((e) => fromJson(e as Map<String, dynamic>))
          .toList(),
      totalCount: json['totalCount'],
      pageNumber: json['pageNumber'],
      pageSize: json['pageSize'],
    );
  }
}

// Statistics Models
class MonthStatistic {
  final int month;
  final int count;
  final double totalDays;

  MonthStatistic({
    required this.month,
    required this.count,
    required this.totalDays,
  });

  factory MonthStatistic.fromJson(Map<String, dynamic> json) {
    return MonthStatistic(
      month: json['month'],
      count: json['count'],
      totalDays: json['totalDays'].toDouble(),
    );
  }
}

class LeaveTypeStatistic {
  final String leaveType;
  final int count;
  final double totalDays;

  LeaveTypeStatistic({
    required this.leaveType,
    required this.count,
    required this.totalDays,
  });

  factory LeaveTypeStatistic.fromJson(Map<String, dynamic> json) {
    return LeaveTypeStatistic(
      leaveType: json['leaveType'],
      count: json['count'],
      totalDays: json['totalDays'].toDouble(),
    );
  }
}

class LeaveStatistics {
  final int year;
  final int totalRequests;
  final int pendingCount;
  final int approvedCount;
  final int rejectedCount;
  final int cancelledCount;
  final double totalDaysRequested;
  final double totalDaysApproved;
  final List<MonthStatistic> byMonth;
  final List<LeaveTypeStatistic> byLeaveType;

  LeaveStatistics({
    required this.year,
    required this.totalRequests,
    required this.pendingCount,
    required this.approvedCount,
    required this.rejectedCount,
    required this.cancelledCount,
    required this.totalDaysRequested,
    required this.totalDaysApproved,
    required this.byMonth,
    required this.byLeaveType,
  });

  factory LeaveStatistics.fromJson(Map<String, dynamic> json) {
    return LeaveStatistics(
      year: json['year'],
      totalRequests: json['totalRequests'],
      pendingCount: json['pendingCount'],
      approvedCount: json['approvedCount'],
      rejectedCount: json['rejectedCount'],
      cancelledCount: json['cancelledCount'],
      totalDaysRequested: json['totalDaysRequested'].toDouble(),
      totalDaysApproved: json['totalDaysApproved'].toDouble(),
      byMonth: (json['byMonth'] as List?)
          ?.map((e) => MonthStatistic.fromJson(e))
          .toList() ?? [],
      byLeaveType: (json['byLeaveType'] as List?)
          ?.map((e) => LeaveTypeStatistic.fromJson(e))
          .toList() ?? [],
    );
  }
}

// Department Statistics
class StatusStatistic {
  final String status;
  final int count;
  final double totalDays;

  StatusStatistic({
    required this.status,
    required this.count,
    required this.totalDays,
  });

  factory StatusStatistic.fromJson(Map<String, dynamic> json) {
    return StatusStatistic(
      status: json['status'],
      count: json['count'],
      totalDays: json['totalDays'].toDouble(),
    );
  }
}

class EmployeeStatistic {
  final String employeeName;
  final int count;
  final double totalDays;
  final double approvedDays;

  EmployeeStatistic({
    required this.employeeName,
    required this.count,
    required this.totalDays,
    required this.approvedDays,
  });

  factory EmployeeStatistic.fromJson(Map<String, dynamic> json) {
    return EmployeeStatistic(
      employeeName: json['employeeName'],
      count: json['count'],
      totalDays: json['totalDays'].toDouble(),
      approvedDays: json['approvedDays'].toDouble(),
    );
  }
}

class DepartmentStatistics {
  final int year;
  final int? month;
  final int? departmentId;
  final int totalRequests;
  final List<StatusStatistic> byStatus;
  final List<LeaveTypeStatistic> byLeaveType;
  final List<EmployeeStatistic> byEmployee;

  DepartmentStatistics({
    required this.year,
    this.month,
    this.departmentId,
    required this.totalRequests,
    required this.byStatus,
    required this.byLeaveType,
    required this.byEmployee,
  });

  factory DepartmentStatistics.fromJson(Map<String, dynamic> json) {
    return DepartmentStatistics(
      year: json['year'],
      month: json['month'],
      departmentId: json['departmentId'],
      totalRequests: json['totalRequests'],
      byStatus: (json['byStatus'] as List?)
          ?.map((e) => StatusStatistic.fromJson(e))
          .toList() ?? [],
      byLeaveType: (json['byLeaveType'] as List?)
          ?.map((e) => LeaveTypeStatistic.fromJson(e))
          .toList() ?? [],
      byEmployee: (json['byEmployee'] as List?)
          ?.map((e) => EmployeeStatistic.fromJson(e))
          .toList() ?? [],
    );
  }
}
