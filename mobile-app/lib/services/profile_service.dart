import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_profile.dart';

/// UserProfile 을 로컬(SharedPreferences)에 영속화하는 싱글톤 ChangeNotifier.
/// 변경 발생 시 리스너(메뉴 탭 프로필 카드 등) 가 즉시 반응하도록 한다.
class ProfileService extends ChangeNotifier {
  static const String _prefKey = 'user.profile.v1';
  static final ProfileService _instance = ProfileService._internal();

  factory ProfileService() => _instance;
  ProfileService._internal();

  UserProfile? _cached;

  /// 저장된 프로필 로드. 없으면 기본 프로필 반환.
  Future<UserProfile> load() async {
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
      // 저장 포맷이 깨졌으면 기본값으로 복구 (손실보다 안전 우선)
      _cached = UserProfile.defaultProfile();
    }
    return _cached!;
  }

  /// 프로필 저장 후 캐시 갱신 + 리스너에게 알림.
  Future<void> save(UserProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, jsonEncode(profile.toJson()));
    _cached = profile;
    notifyListeners();
  }
}
