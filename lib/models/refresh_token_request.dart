class RefreshTokenRequest {
  final String refreshToken;

  RefreshTokenRequest({
    required this.refreshToken,
  });

  Map<String, dynamic> toJson() {
    return {
      'refreshToken': refreshToken,
    };
  }

  factory RefreshTokenRequest.fromJson(Map<String, dynamic> json) {
    return RefreshTokenRequest(
      refreshToken: json['refreshToken'],
    );
  }
}
