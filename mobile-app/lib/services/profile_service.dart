import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_constants.dart';
import '../models/user_profile.dart';

/// UserProfile 을 백엔드 DB(FastAPI) 및 로컬(SharedPreferences)에 동기화하는 싱글톤.
/// - 온라인 시: FastAPI 백엔드 DB와 양방향 동기화
/// - 오프라인 시: 로컬 캐시 자동 폴백
class ProfileService extends ChangeNotifier {
  static const String _prefKey = 'user.profile.v1';
  static final ProfileService _instance = ProfileService._internal();

  factory ProfileService() => _instance;
  ProfileService._internal();

  final http.Client _client = http.Client();
  UserProfile? _cached;

  /// 저장된 프로필 로드 (백엔드 DB 우선 조회, 실패 시 로컬 캐시 복구).
  Future<UserProfile> load({String userId = ApiConstants.defaultUserId}) async {
    // 1. 백엔드 DB 조회 시도
    try {
      final uri = Uri.parse('${ApiConstants.profile}?userId=$userId');
      final res = await _client.get(uri).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
        final profile = UserProfile.fromJson(decoded);
        _cached = profile;

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_prefKey, jsonEncode(profile.toJson()));
        return profile;
      }
    } catch (_) {
      // 서버 미응답 시 로컬 캐시 폴백 진행
    }

    if (_cached != null) return _cached!;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefKey);
    if (raw == null) {
      _cached = UserProfile.defaultProfile();
      return _cached!;
    }
    try {
      _cached = UserProfile.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      _cached = UserProfile.defaultProfile();
    }
    return _cached!;
  }

  /// 프로필 저장 (로컬 캐시 즉시 갱신 + 백엔드 DB 동기화).
  Future<void> save(
    UserProfile profile, {
    String userId = ApiConstants.defaultUserId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, jsonEncode(profile.toJson()));
    _cached = profile;
    notifyListeners();

    try {
      final uri = Uri.parse(ApiConstants.profile);
      final body = {
        'userId': userId,
        'nickname': profile.nickname,
        'gender': profile.gender.name,
        if (profile.heightCm != null) 'heightCm': profile.heightCm,
        if (profile.weightKg != null) 'weightKg': profile.weightKg,
        if (profile.targetWeightKg != null) 'targetWeightKg': profile.targetWeightKg,
        'experience': profile.experience.name,
      };
      await _client
          .put(
            uri,
            headers: {'Content-Type': 'application/json; charset=UTF-8'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 5));
    } catch (_) {
      // 네트워크 장애 시 로컬 캐시로 안전 유지
    }
  }
}

