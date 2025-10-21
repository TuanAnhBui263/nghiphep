class LoginResponse {
  final String accessToken;
  final String refreshToken;
  final DateTime expiresAt;
  final UserInfo user;

  LoginResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAt,
    required this.user,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      accessToken: json['accessToken'],
      refreshToken: json['refreshToken'],
      expiresAt: DateTime.parse(json['expiresAt']),
      user: UserInfo.fromJson(json['user']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'accessToken': accessToken,
      'refreshToken': refreshToken,
      'expiresAt': expiresAt.toIso8601String(),
      'user': user.toJson(),
    };
  }
}

class UserInfo {
  final int id;
  final String email;
  final String fullName;
  final String? phoneNumber;
  final DateTime? dateOfBirth;
  final DateTime joinDate;
  final bool isActive;
  final List<String> roles;
  final List<DepartmentInfo> departments;

  UserInfo({
    required this.id,
    required this.email,
    required this.fullName,
    this.phoneNumber,
    this.dateOfBirth,
    required this.joinDate,
    required this.isActive,
    required this.roles,
    required this.departments,
  });

  factory UserInfo.fromJson(Map<String, dynamic> json) {
    return UserInfo(
      id: json['id'],
      email: json['email'],
      fullName: json['fullName'],
      phoneNumber: json['phoneNumber'],
      dateOfBirth: json['dateOfBirth'] != null ? DateTime.parse(json['dateOfBirth']) : null,
      joinDate: DateTime.parse(json['joinDate']),
      isActive: json['isActive'],
      roles: List<String>.from(json['roles'] ?? []),
      departments: (json['departments'] as List<dynamic>?)
          ?.map((d) => DepartmentInfo.fromJson(d))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'fullName': fullName,
      'phoneNumber': phoneNumber,
      'dateOfBirth': dateOfBirth?.toIso8601String(),
      'joinDate': joinDate.toIso8601String(),
      'isActive': isActive,
      'roles': roles,
      'departments': departments.map((d) => d.toJson()).toList(),
    };
  }
}

class DepartmentInfo {
  final int id;
  final String departmentCode;
  final String departmentName;
  final String positionName;
  final bool isPrimary;

  DepartmentInfo({
    required this.id,
    required this.departmentCode,
    required this.departmentName,
    required this.positionName,
    required this.isPrimary,
  });

  factory DepartmentInfo.fromJson(Map<String, dynamic> json) {
    return DepartmentInfo(
      id: json['id'],
      departmentCode: json['departmentCode'],
      departmentName: json['departmentName'],
      positionName: json['positionName'],
      isPrimary: json['isPrimary'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'departmentCode': departmentCode,
      'departmentName': departmentName,
      'positionName': positionName,
      'isPrimary': isPrimary,
    };
  }
}
