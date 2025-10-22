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
      id: json['id'],
      leaveTypeName: json['leaveTypeName'],
      leaveTypeCode: json['leaveTypeCode'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'leaveTypeName': leaveTypeName,
      'leaveTypeCode': leaveTypeCode,
    };
  }
}
