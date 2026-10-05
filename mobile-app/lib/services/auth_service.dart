import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_constants.dart';
import '../models/auth_user.dart';

/// JWT 인증 및 사용자 세션 관리 서비스 (싱글톤)
class AuthService {
  AuthService._internal();
  static final AuthService instance = AuthService._internal();

  static const String _keyToken = 'coachfit_jwt_token';
  static const String _keyUserId = 'coachfit_user_id';
  static const String _keyEmail = 'coachfit_email';
  static const String _keyNickname = 'coachfit_nickname';

  AuthUser? _currentUser;
  AuthUser? get currentUser => _currentUser;

  /// 앱 시작 시 SharedPreferences에 저장된 세션 복원
  Future<AuthUser?> loadSavedSession() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_keyToken);
    final userId = prefs.getString(_keyUserId);
    final email = prefs.getString(_keyEmail);
    final nickname = prefs.getString(_keyNickname);

    if (token != null && token.isNotEmpty && userId != null && userId.isNotEmpty) {
      _currentUser = AuthUser(
        accessToken: token,
        userId: userId,
        email: email ?? '',
        nickname: nickname ?? '운동인',
      );
      return _currentUser;
    }
    return null;
  }

  /// 로그인 API 호출 및 세션 영속화
  Future<AuthUser> login({
    required String email,
    required String password,
  }) async {
    final uri = Uri.parse(ApiConstants.authLogin);
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email.trim(),
        'password': password,
      }),
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      final errorBody = jsonDecode(utf8.decode(response.bodyBytes));
      final message = errorBody['detail'] ?? '로그인에 실패했습니다.';
      throw Exception(message);
    }

    final data = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    final user = AuthUser.fromJson(data);
    await _persistSession(user);
    _currentUser = user;
    return user;
  }

  /// 회원가입 API 호출 및 세션 영속화
  Future<AuthUser> register({
    required String email,
    required String password,
    required String nickname,
    double? heightCm,
    double? weightKg,
    double? targetWeightKg,
    String? experience,
    String? workoutGoal,
  }) async {
    final uri = Uri.parse(ApiConstants.authRegister);
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email.trim(),
        'password': password,
        'nickname': nickname.trim(),
        'heightCm': heightCm,
        'weightKg': weightKg,
        'targetWeightKg': targetWeightKg,
        'experience': experience ?? 'beginner',
        'workoutGoal': workoutGoal ?? '근비대 및 전신 근력 증진',
      }),
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode != 201 && response.statusCode != 200) {
      final errorBody = jsonDecode(utf8.decode(response.bodyBytes));
      final message = errorBody['detail'] ?? '회원가입에 실패했습니다.';
      throw Exception(message);
    }

    final data = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    final user = AuthUser.fromJson(data);
    await _persistSession(user);
    _currentUser = user;
    return user;
  }

  /// 로그아웃 (로컬 저장소 세션 삭제)
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyToken);
    await prefs.remove(_keyUserId);
    await prefs.remove(_keyEmail);
    await prefs.remove(_keyNickname);
    _currentUser = null;
  }

  /// 인증 토큰 반환
  Future<String?> getAccessToken() async {
    if (_currentUser?.accessToken != null && _currentUser!.accessToken.isNotEmpty) {
      return _currentUser!.accessToken;
    }
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyToken);
  }

  /// 현재 로그인된 유저 ID (로그인 안 된 경우 defaultUserId 반환)
  Future<String> getCurrentUserId() async {
    if (_currentUser?.userId != null && _currentUser!.userId.isNotEmpty) {
      return _currentUser!.userId;
    }
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserId) ?? ApiConstants.defaultUserId;
  }

  /// HTTP 요청용 Authorization 헤더 맵 생성
  Future<Map<String, String>> getAuthHeaders() async {
    final token = await getAccessToken();
    if (token != null && token.isNotEmpty) {
      return {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };
    }
    return {'Content-Type': 'application/json'};
  }

  Future<void> _persistSession(AuthUser user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyToken, user.accessToken);
    await prefs.setString(_keyUserId, user.userId);
    await prefs.setString(_keyEmail, user.email);
    await prefs.setString(_keyNickname, user.nickname);
  }
}
