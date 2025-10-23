class LeaveRequestDto {
  final int leaveTypeId;
  final String startDate;
  final String endDate;
  final String startSession;
  final String endSession;
  final double totalDays;
  final String reason;

  LeaveRequestDto({
    required this.leaveTypeId,
    required this.startDate,
    required this.endDate,
    this.startSession = 'FULL',
    this.endSession = 'FULL',
    required this.totalDays,
    required this.reason,
  });

  Map<String, dynamic> toJson() => {
    'leaveTypeId': leaveTypeId,
    'startDate': startDate,
    'endDate': endDate,
    'startSession': startSession,
    'endSession': endSession,
    'totalDays': totalDays,
    'reason': reason,
  };
}

class LeaveRequestResponse {
  final int id;
  final String requestCode;
  final String employeeName;
  final String leaveTypeName;
  final String startDate;
  final String endDate;
  final double totalDays;
  final String reason;
  final String status;
  final List<ApprovalInfo> approvals;
  final String createdAt;

  LeaveRequestResponse({
    required this.id,
    required this.requestCode,
    required this.employeeName,
    required this.leaveTypeName,
    required this.startDate,
    required this.endDate,
    required this.totalDays,
    required this.reason,
    required this.status,
    required this.approvals,
    required this.createdAt,
  });

  factory LeaveRequestResponse.fromJson(Map<String, dynamic> json) {
    return LeaveRequestResponse(
      id: json['id'],
      requestCode: json['requestCode'],
      employeeName: json['employeeName'],
      leaveTypeName: json['leaveTypeName'],
      startDate: json['startDate'],
      endDate: json['endDate'],
      totalDays: json['totalDays'].toDouble(),
      reason: json['reason'],
      status: json['status'],
      approvals: (json['approvals'] as List?)
          ?.map((e) => ApprovalInfo.fromJson(e))
          .toList() ?? [],
      createdAt: json['createdAt'],
    );
  }
}

class ApprovalInfo {
  final int id;
  final String approverName;
  final String status;
  final String? comments;
  final String? approvedAt;

  ApprovalInfo({
    required this.id,
    required this.approverName,
    required this.status,
    this.comments,
    this.approvedAt,
  });

  factory ApprovalInfo.fromJson(Map<String, dynamic> json) {
    return ApprovalInfo(
      id: json['id'],
      approverName: json['approverName'] ?? '',
      status: json['status'],
      comments: json['comments'],
      approvedAt: json['approvedAt'],
    );
  }
}

class LeaveRequestSummary {
  final int id;
  final String requestCode;
  final String employeeName;
  final String leaveTypeName;
  final String startDate;
  final String endDate;
  final double totalDays;
  final String status;
  final String createdAt;

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
      id: json['id'] ?? 0,
      requestCode: json['requestCode'] ?? '',
      employeeName: json['employeeName'] ?? '',
      leaveTypeName: json['leaveTypeName'] ?? '',
      startDate: json['startDate'] ?? '',
      endDate: json['endDate'] ?? '',
      totalDays: (json['totalDays'] ?? 0).toDouble(),
      status: json['status'] ?? 'PENDING',
      createdAt: json['createdAt'] ?? '',
    );
  }
}

class LeaveRequestDetail {
  final int id;
  final String requestCode;
  final String employeeName;
  final String leaveTypeName;
  final String startDate;
  final String endDate;
  final String startSession;
  final String endSession;
  final double totalDays;
  final String reason;
  final String status;
  final List<LeaveDetailItem> leaveDetails;
  final List<ApprovalInfo> approvals;
  final String createdAt;
  final String? updatedAt;

  LeaveRequestDetail({
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
    this.updatedAt,
  });

  factory LeaveRequestDetail.fromJson(Map<String, dynamic> json) {
    return LeaveRequestDetail(
      id: json['id'] ?? 0,
      requestCode: json['requestCode'] ?? '',
      employeeName: json['employeeName'] ?? '',
      leaveTypeName: json['leaveTypeName'] ?? '',
      startDate: json['startDate'] ?? '',
      endDate: json['endDate'] ?? '',
      startSession: json['startSession'] ?? 'FULL',
      endSession: json['endSession'] ?? 'FULL',
      totalDays: (json['totalDays'] ?? 0).toDouble(),
      reason: json['reason'] ?? '',
      status: json['status'] ?? 'PENDING',
      leaveDetails: (json['leaveDetails'] as List?)
          ?.map((e) => LeaveDetailItem.fromJson(e))
          .toList() ?? [],
      approvals: (json['approvals'] as List?)
          ?.map((e) => ApprovalInfo.fromJson(e))
          .toList() ?? [],
      createdAt: json['createdAt'] ?? '',
      updatedAt: json['updatedAt'],
    );
  }
}

class LeaveDetailItem {
  final int id;
  final String leaveDate;
  final String session;
  final double dayValue;

  LeaveDetailItem({
    required this.id,
    required this.leaveDate,
    required this.session,
    required this.dayValue,
  });

  factory LeaveDetailItem.fromJson(Map<String, dynamic> json) {
    return LeaveDetailItem(
      id: json['id'] ?? 0,
      leaveDate: json['leaveDate'] ?? '',
      session: json['session'] ?? 'FULL',
      dayValue: (json['dayValue'] ?? 0).toDouble(),
    );
  }
}

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
    T Function(Map<String, dynamic>) fromJsonT,
  ) {
    return PagedResult(
      items: (json['items'] as List).map((e) => fromJsonT(e)).toList(),
      totalCount: json['totalCount'],
      pageNumber: json['pageNumber'],
      pageSize: json['pageSize'],
    );
  }

  bool get hasMore => pageNumber * pageSize < totalCount;
  int get totalPages => (totalCount / pageSize).ceil();
}

class LeaveType {
  final int id;
  final String leaveTypeName;
  final String leaveTypeCode;

  LeaveType({
    required this.id,
    required this.leaveTypeName,
    required this.leaveTypeCode,
  });

  factory LeaveType.fromJson(Map<String, dynamic> json) {
    return LeaveType(
      id: json['id'] ?? 0,
      leaveTypeName: json['leaveTypeName'] ?? '',
      leaveTypeCode: json['leaveTypeCode'] ?? '',
    );
  }
}

class LeaveStatistics {
  final int year;
  final StatisticsSummary summary;
  final List<MonthlyStatistics> byMonth;
  final List<LeaveTypeStatistics> byLeaveType;
  final List<StatusStatistics> byStatus;

  LeaveStatistics({
    required this.year,
    required this.summary,
    required this.byMonth,
    required this.byLeaveType,
    required this.byStatus,
  });

  factory LeaveStatistics.fromJson(Map<String, dynamic> json) {
    return LeaveStatistics(
      year: json['year'],
      summary: StatisticsSummary.fromJson(json['summary']),
      byMonth: (json['byMonth'] as List)
          .map((e) => MonthlyStatistics.fromJson(e))
          .toList(),
      byLeaveType: (json['byLeaveType'] as List)
          .map((e) => LeaveTypeStatistics.fromJson(e))
          .toList(),
      byStatus: (json['byStatus'] as List)
          .map((e) => StatusStatistics.fromJson(e))
          .toList(),
    );
  }
}

class StatisticsSummary {
  final int totalRequests;
  final int pendingCount;
  final int approvedCount;
  final int rejectedCount;
  final int cancelledCount;
  final double totalDaysRequested;
  final double totalDaysApproved;

  StatisticsSummary({
    required this.totalRequests,
    required this.pendingCount,
    required this.approvedCount,
    required this.rejectedCount,
    required this.cancelledCount,
    required this.totalDaysRequested,
    required this.totalDaysApproved,
  });

  factory StatisticsSummary.fromJson(Map<String, dynamic> json) {
    return StatisticsSummary(
      totalRequests: json['totalRequests'],
      pendingCount: json['pendingCount'],
      approvedCount: json['approvedCount'],
      rejectedCount: json['rejectedCount'],
      cancelledCount: json['cancelledCount'],
      totalDaysRequested: json['totalDaysRequested'].toDouble(),
      totalDaysApproved: json['totalDaysApproved'].toDouble(),
    );
  }
}

class MonthlyStatistics {
  final int month;
  final String monthName;
  final int count;
  final double totalDays;
  final double approvedDays;

  MonthlyStatistics({
    required this.month,
    required this.monthName,
    required this.count,
    required this.totalDays,
    required this.approvedDays,
  });

  factory MonthlyStatistics.fromJson(Map<String, dynamic> json) {
    return MonthlyStatistics(
      month: json['month'],
      monthName: json['monthName'],
      count: json['count'],
      totalDays: json['totalDays'].toDouble(),
      approvedDays: json['approvedDays'].toDouble(),
    );
  }
}

class LeaveTypeStatistics {
  final String leaveType;
  final int count;
  final double totalDays;
  final double approvedDays;

  LeaveTypeStatistics({
    required this.leaveType,
    required this.count,
    required this.totalDays,
    required this.approvedDays,
  });

  factory LeaveTypeStatistics.fromJson(Map<String, dynamic> json) {
    return LeaveTypeStatistics(
      leaveType: json['leaveType'],
      count: json['count'],
      totalDays: json['totalDays'].toDouble(),
      approvedDays: json['approvedDays'].toDouble(),
    );
  }
}

class StatusStatistics {
  final String status;
  final int count;
  final double percentage;

  StatusStatistics({
    required this.status,
    required this.count,
    required this.percentage,
  });

  factory StatusStatistics.fromJson(Map<String, dynamic> json) {
    return StatusStatistics(
      status: json['status'],
      count: json['count'],
      percentage: json['percentage'].toDouble(),
    );
  }
}
