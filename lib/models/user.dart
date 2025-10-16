enum UserRole {
  employee, // Nhân viên
  teamLeader, // Trưởng phòng
  deputyLeader, // Phó phòng
  admin, // Admin
}

class User {
  final String id;
  final String username;
  final String password;
  final String fullName;
  final String email;
  final String phone;
  final String department;
  final UserRole role;
  final int workYears; // Số năm công tác
  final int annualLeaveDays; // Số ngày nghỉ phép năm
  final int remainingLeaveDays; // Số ngày nghỉ còn lại
  final String? managerId; // ID của người quản lý trực tiếp
  final DateTime createdAt;
  final DateTime updatedAt;

  User({
    required this.id,
    required this.username,
    required this.password,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.department,
    required this.role,
    required this.workYears,
    required this.annualLeaveDays,
    required this.remainingLeaveDays,
    this.managerId,
    required this.createdAt,
    required this.updatedAt,
  });

  // Tính số ngày nghỉ phép năm dựa trên số năm công tác
  static int calculateAnnualLeaveDays(int workYears) {
    if (workYears < 1) return 12;
    if (workYears < 5) return 14;
    if (workYears < 10) return 16;
    return 18;
  }

  User copyWith({
    String? id,
    String? username,
    String? password,
    String? fullName,
    String? email,
    String? phone,
    String? department,
    UserRole? role,
    int? workYears,
    int? annualLeaveDays,
    int? remainingLeaveDays,
    String? managerId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      password: password ?? this.password,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      department: department ?? this.department,
      role: role ?? this.role,
      workYears: workYears ?? this.workYears,
      annualLeaveDays: annualLeaveDays ?? this.annualLeaveDays,
      remainingLeaveDays: remainingLeaveDays ?? this.remainingLeaveDays,
      managerId: managerId ?? this.managerId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'password': password,
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'department': department,
      'role': role.name,
      'workYears': workYears,
      'annualLeaveDays': annualLeaveDays,
      'remainingLeaveDays': remainingLeaveDays,
      'managerId': managerId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      username: json['username'],
      password: json['password'],
      fullName: json['fullName'],
      email: json['email'],
      phone: json['phone'],
      department: json['department'],
      role: UserRole.values.firstWhere((e) => e.name == json['role']),
      workYears: json['workYears'],
      annualLeaveDays: json['annualLeaveDays'],
      remainingLeaveDays: json['remainingLeaveDays'],
      managerId: json['managerId'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }
}
