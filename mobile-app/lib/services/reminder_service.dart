import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// (B) 운동 리마인더 알림 시간 저장 서비스.
/// 실제 로컬 알림 발송은 flutter_local_notifications 패키지 필요 — 본 서비스는
/// 사용자 설정 저장/표시만 담당하고, 실 알림 구현은 네이티브 플랫폼 작업 포함이라
/// 실기기 테스트 단계(13주차)에서 백엔드 담당과 함께 통합.
class ReminderService extends ChangeNotifier {
  static const String _kEnabled = 'reminder.enabled.v1';
  static const String _kHour = 'reminder.hour.v1';
  static const String _kMinute = 'reminder.minute.v1';

  static final ReminderService _instance = ReminderService._internal();
  factory ReminderService() => _instance;
  ReminderService._internal();

  bool _enabled = true;
  TimeOfDay _time = const TimeOfDay(hour: 19, minute: 0);
  bool _loaded = false;

  bool get enabled => _enabled;
  TimeOfDay get time => _time;
  bool get loaded => _loaded;

  String get display =>
      '${_time.hour.toString().padLeft(2, '0')}:${_time.minute.toString().padLeft(2, '0')}';

  String get displayKorean {
    final period = _time.hour < 12 ? '오전' : '오후';
    final h = _time.hour == 0
        ? 12
        : (_time.hour > 12 ? _time.hour - 12 : _time.hour);
    return '$period $h:${_time.minute.toString().padLeft(2, '0')}';
  }

  Future<void> load() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    _enabled = prefs.getBool(_kEnabled) ?? true;
    _time = TimeOfDay(
      hour: prefs.getInt(_kHour) ?? 19,
      minute: prefs.getInt(_kMinute) ?? 0,
    );
    _loaded = true;
    notifyListeners();
  }

  Future<void> setTime(TimeOfDay t) async {
    _time = t;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kHour, t.hour);
    await prefs.setInt(_kMinute, t.minute);
    notifyListeners();
  }

  Future<void> setEnabled(bool v) async {
    _enabled = v;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kEnabled, v);
    notifyListeners();
  }
}
