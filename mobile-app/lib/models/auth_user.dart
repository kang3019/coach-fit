class AuthUser {
  final String accessToken;
  final String tokenType;
  final String userId;
  final String email;
  final String nickname;

  const AuthUser({
    required this.accessToken,
    this.tokenType = 'bearer',
    required this.userId,
    required this.email,
    required this.nickname,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      accessToken: json['accessToken'] as String? ?? json['access_token'] as String? ?? '',
      tokenType: json['tokenType'] as String? ?? json['token_type'] as String? ?? 'bearer',
      userId: json['userId'] as String? ?? json['user_id'] as String? ?? '',
      email: json['email'] as String? ?? '',
      nickname: json['nickname'] as String? ?? '운동인',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'accessToken': accessToken,
      'tokenType': tokenType,
      'userId': userId,
      'email': email,
      'nickname': nickname,
    };
  }
}
