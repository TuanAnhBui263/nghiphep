enum LeaveType {
  fullDay, // Nghỉ cả ngày
  halfDay, // Nghỉ nửa ngày
  sickLeave, // Nghỉ ốm
}

enum LeaveStatus {
  pending, // Chờ duyệt
  approved, // Đã duyệt
  rejected, // Từ chối
  cancelled, // Đã hủy
}

class LeaveRequest {
  final String id;
  final String userId;
  final String userName;
  final String userDepartment;
  final LeaveType type;
  final DateTime startDate;
  final DateTime endDate;
  final double totalDays; // Tổng số ngày nghỉ (có thể là 0.5 cho nửa ngày)
  final String reason;
  final LeaveStatus status;
  final String? approverId; // ID người duyệt
  final String? approverName; // Tên người duyệt
  final String? rejectionReason; // Lý do từ chối
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? approvedAt; // Thời gian duyệt

  LeaveRequest({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userDepartment,
    required this.type,
    required this.startDate,
    required this.endDate,
    required this.totalDays,
    required this.reason,
    required this.status,
    this.approverId,
    this.approverName,
    this.rejectionReason,
    required this.createdAt,
    required this.updatedAt,
    this.approvedAt,
  });

  // Tính tổng số ngày nghỉ
  static double calculateTotalDays(
    LeaveType type,
    DateTime startDate,
    DateTime endDate,
  ) {
    if (type == LeaveType.halfDay) {
      return 0.5;
    }

    int days = endDate.difference(startDate).inDays + 1;
    return days.toDouble();
  }

  LeaveRequest copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userDepartment,
    LeaveType? type,
    DateTime? startDate,
    DateTime? endDate,
    double? totalDays,
    String? reason,
    LeaveStatus? status,
    String? approverId,
    String? approverName,
    String? rejectionReason,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? approvedAt,
  }) {
    return LeaveRequest(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userDepartment: userDepartment ?? this.userDepartment,
      type: type ?? this.type,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      totalDays: totalDays ?? this.totalDays,
      reason: reason ?? this.reason,
      status: status ?? this.status,
      approverId: approverId ?? this.approverId,
      approverName: approverName ?? this.approverName,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      approvedAt: approvedAt ?? this.approvedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'userDepartment': userDepartment,
      'type': type.name,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'totalDays': totalDays,
      'reason': reason,
      'status': status.name,
      'approverId': approverId,
      'approverName': approverName,
      'rejectionReason': rejectionReason,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'approvedAt': approvedAt?.toIso8601String(),
    };
  }

  factory LeaveRequest.fromJson(Map<String, dynamic> json) {
    return LeaveRequest(
      id: json['id'],
      userId: json['userId'],
      userName: json['userName'],
      userDepartment: json['userDepartment'],
      type: LeaveType.values.firstWhere((e) => e.name == json['type']),
      startDate: DateTime.parse(json['startDate']),
      endDate: DateTime.parse(json['endDate']),
      totalDays: json['totalDays'].toDouble(),
      reason: json['reason'],
      status: LeaveStatus.values.firstWhere((e) => e.name == json['status']),
      approverId: json['approverId'],
      approverName: json['approverName'],
      rejectionReason: json['rejectionReason'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      approvedAt:
          json['approvedAt'] != null
              ? DateTime.parse(json['approvedAt'])
              : null,
    );
  }
}
