import 'dart:convert';
import 'package:http/http.dart' as http;

import '../config/api_constants.dart';
import '../models/workout.dart';

/// FastAPI 백엔드(8000) 운동 기록 CRUD REST 호출.
class WorkoutService {
  final http.Client _client;
  WorkoutService({http.Client? client}) : _client = client ?? http.Client();

  /// GET /api/workouts?userId=user_01
  Future<List<Workout>> fetchWorkouts({
    String userId = ApiConstants.defaultUserId,
  }) async {
    final uri = Uri.parse('${ApiConstants.workouts}?userId=$userId');
    final res = await _client.get(uri).timeout(const Duration(seconds: 8));

    if (res.statusCode != 200) {
      throw Exception('운동 기록 조회 실패 (status=${res.statusCode})');
    }
    final decoded = jsonDecode(utf8.decode(res.bodyBytes)) as List<dynamic>;
    return decoded
        .map((e) => Workout.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// POST /api/workouts
  Future<Workout> createWorkout(Workout workout) async {
    final res = await _client
        .post(
          Uri.parse(ApiConstants.workouts),
          headers: {'Content-Type': 'application/json; charset=UTF-8'},
          body: jsonEncode(workout.toCreateJson()),
        )
        .timeout(const Duration(seconds: 8));

    if (res.statusCode != 201 && res.statusCode != 200) {
      throw Exception('운동 기록 등록 실패 (status=${res.statusCode})');
    }
    final decoded = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    return Workout.fromJson(decoded);
  }

  /// GET /api/workouts/weekly-stats
  /// 응답 예: { userId, totalRecords, weeklyVolumeByDay: {"MON": 3500.0, ...} }
  Future<Map<String, double>> fetchWeeklyVolume({
    String userId = ApiConstants.defaultUserId,
  }) async {
    final uri = Uri.parse('${ApiConstants.weeklyStats}?userId=$userId');
    final res = await _client.get(uri).timeout(const Duration(seconds: 8));
    if (res.statusCode != 200) {
      throw Exception('주간 통계 조회 실패 (status=${res.statusCode})');
    }
    final decoded = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    final volumeMap = (decoded['weeklyVolumeByDay'] as Map<String, dynamic>?) ?? {};
    return volumeMap.map(
      (day, value) => MapEntry(day, (value as num).toDouble()),
    );
  }

  void dispose() => _client.close();
}
