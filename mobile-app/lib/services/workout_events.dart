import 'dart:async';

import 'package:flutter/foundation.dart';

/// 운동 기록 생성/삭제를 탭 간에 즉시 전파하는 싱글톤 허브.
/// 여러 건이 연달아 저장되어도 250ms 안에 한 번만 알린다.
class WorkoutEvents extends ChangeNotifier {
  WorkoutEvents._();
  static final WorkoutEvents instance = WorkoutEvents._();

  Timer? _debounce;
  DateTime? _pendingFocus;
  DateTime? _focusDate;
  DateTime? _sessionStart;

  /// 마지막 알림에 포함된, 기록 탭이 이동해야 할 날짜 (없으면 null).
  DateTime? get focusDate => _focusDate;

  /// 오늘 운동 세션의 시작 시각 (앱 실행 중에만 유지).
  DateTime? get sessionStart => _sessionStart;

  void notifyChanged({DateTime? focusDate}) {
    _pendingFocus = focusDate ?? _pendingFocus;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      _focusDate = _pendingFocus;
      _pendingFocus = null;
      notifyListeners();
    });
  }

  void ensureSessionStarted() {
    final now = DateTime.now();
    final start = _sessionStart;
    final isToday = start != null &&
        start.year == now.year &&
        start.month == now.month &&
        start.day == now.day;
    if (!isToday) _sessionStart = now;
  }

  void endSession() => _sessionStart = null;
}
