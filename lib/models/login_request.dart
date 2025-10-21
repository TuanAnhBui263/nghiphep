class LoginRequest {
  final String email;
  final String password;
  final String deviceInfo;

  LoginRequest({
    required this.email,
    required this.password,
    this.deviceInfo = 'Flutter App',
  });

  Map<String, dynamic> toJson() {
    return {'email': email, 'password': password, 'deviceInfo': deviceInfo};
  }

  factory LoginRequest.fromJson(Map<String, dynamic> json) {
    return LoginRequest(
      email: json['email'],
      password: json['password'],
      deviceInfo: json['deviceInfo'] ?? 'Flutter App',
    );
  }
}
