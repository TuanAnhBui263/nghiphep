class UserRegistrationRequest {
  final String email;
  final String password;
  final String fullName;
  final String phoneNumber;
  final String dateOfBirth;
  final String joinDate;
  final int departmentId;
  final int positionTypeId;
  final List<int> roleIds;

  UserRegistrationRequest({
    required this.email,
    required this.password,
    required this.fullName,
    required this.phoneNumber,
    required this.dateOfBirth,
    required this.joinDate,
    required this.departmentId,
    required this.positionTypeId,
    required this.roleIds,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
      'fullName': fullName,
      'phoneNumber': phoneNumber,
      'dateOfBirth': dateOfBirth,
      'joinDate': joinDate,
      'departmentId': departmentId,
      'positionTypeId': positionTypeId,
      'roleIds': roleIds,
    };
  }

  factory UserRegistrationRequest.fromJson(Map<String, dynamic> json) {
    return UserRegistrationRequest(
      email: json['email'],
      password: json['password'],
      fullName: json['fullName'],
      phoneNumber: json['phoneNumber'],
      dateOfBirth: json['dateOfBirth'],
      joinDate: json['joinDate'],
      departmentId: json['departmentId'],
      positionTypeId: json['positionTypeId'],
      roleIds: List<int>.from(json['roleIds']),
    );
  }
}

class Department {
  final int id;
  final String departmentName;
  final String? description;
  final bool isActive;

  Department({
    required this.id,
    required this.departmentName,
    this.description,
    required this.isActive,
  });

  factory Department.fromJson(Map<String, dynamic> json) {
    return Department(
      id: json['id'],
      departmentName: json['departmentName'],
      description: json['description'],
      isActive: json['isActive'] ?? true,
    );
  }
}

class PositionType {
  final int id;
  final String positionName;
  final String? description;
  final bool isActive;

  PositionType({
    required this.id,
    required this.positionName,
    this.description,
    required this.isActive,
  });

  factory PositionType.fromJson(Map<String, dynamic> json) {
    return PositionType(
      id: json['id'],
      positionName: json['positionName'],
      description: json['description'],
      isActive: json['isActive'] ?? true,
    );
  }
}

class Role {
  final int id;
  final String roleName;
  final String? description;
  final bool isActive;

  Role({
    required this.id,
    required this.roleName,
    this.description,
    required this.isActive,
  });

  factory Role.fromJson(Map<String, dynamic> json) {
    return Role(
      id: json['id'],
      roleName: json['roleName'],
      description: json['description'],
      isActive: json['isActive'] ?? true,
    );
  }
}
