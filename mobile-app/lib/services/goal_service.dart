import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_constants.dart';

/// 사용자의 운동 목표를 로컬(shared_preferences) 및 백엔드 DB(FastAPI)에 영속화한다.
/// 선택한 목표는 AI 코칭 호출 시 백엔드 `goal` 파라미터에 전달되어
/// 프롬프트 분기를 유도한다 (WBS 1.1.3).
enum WorkoutGoal {
  hypertrophy,  // 근비대
  fatLoss,      // 체지방 감량
  strength,     // 근력 증가
}

extension WorkoutGoalExtension on WorkoutGoal {
  /// 사용자에게 보여줄 짧은 한국어 라벨.
  String get label {
    switch (this) {
      case WorkoutGoal.hypertrophy:
        return '근비대';
      case WorkoutGoal.fatLoss:
        return '체지방 감량';
      case WorkoutGoal.strength:
        return '근력 증가';
    }
  }

  /// AI 코칭 요청의 `goal` 파라미터로 전달될 문장.
  /// 백엔드가 프롬프트에 그대로 삽입하므로 문장형으로 다듬음.
  String get aiPromptPhrase {
    switch (this) {
      case WorkoutGoal.hypertrophy:
        return '근비대 및 전신 근력 증진';
      case WorkoutGoal.fatLoss:
        return '체지방 감량 및 유산소 지구력 향상';
      case WorkoutGoal.strength:
        return '최대 근력 증가 (3~5 repetition)';
    }
  }

  /// shared_preferences 저장용 안정 식별자 (enum.name 사용).
  String get storageKey => name;
}

/// 로컬 저장/조회 담당 싱글톤 ChangeNotifier.
/// 변경 발생 시 리스너(홈 탭 등) 들에게 알려 자동 재호출을 유도한다.
class GoalService extends ChangeNotifier {
  static const String _prefKey = 'user.workout_goal';
  static final GoalService _instance = GoalService._internal();

  factory GoalService() => _instance;
  GoalService._internal();

  final http.Client _client = http.Client();
  WorkoutGoal? _cached;

  /// 저장된 목표를 읽는다. 없으면 기본값(근비대).
  /// 캐시가 있으면 즉시 반환, 없으면 SharedPreferences 조회.
  Future<WorkoutGoal> load() async {
    if (_cached != null) return _cached!;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefKey);
    _cached = raw == null
        ? WorkoutGoal.hypertrophy
        : WorkoutGoal.values.firstWhere(
            (g) => g.storageKey == raw,
            orElse: () => WorkoutGoal.hypertrophy,
          );
    return _cached!;
  }

  /// 저장 후 캐시 갱신 + 리스너 알림 + 백엔드 DB 동기화.
  Future<void> save(
    WorkoutGoal goal, {
    String userId = ApiConstants.defaultUserId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, goal.storageKey);
    _cached = goal;
    notifyListeners();

    try {
      final uri = Uri.parse(ApiConstants.profile);
      await _client
          .put(
            uri,
            headers: {'Content-Type': 'application/json; charset=UTF-8'},
            body: jsonEncode({
              'userId': userId,
              'workoutGoal': goal.aiPromptPhrase,
            }),
          )
          .timeout(const Duration(seconds: 4));
    } catch (_) {
      // 오프라인 시 로컬 설정 유지
    }
  }
}

