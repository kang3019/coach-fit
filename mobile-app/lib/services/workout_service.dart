import 'dart:convert';
import 'package:http/http.dart' as http;

import '../config/api_constants.dart';
import '../models/coaching_result.dart';
import '../models/exercise_master.dart';
import '../models/workout.dart';

/// FastAPI 백엔드(8000) 운동 기록 CRUD 및 운동 마스터 REST 호출.
class WorkoutService {
  final http.Client _client;
  WorkoutService({http.Client? client}) : _client = client ?? http.Client();

  /// GET /api/exercises?category=...&search=...
  Future<List<ExerciseMaster>> fetchExercises({
    String? category,
    String? search,
  }) async {
    final queryParams = <String, String>{};
    if (category != null && category.isNotEmpty && category != '전체') {
      queryParams['category'] = category;
    }
    if (search != null && search.trim().isNotEmpty) {
      queryParams['search'] = search.trim();
    }

    final uri = Uri.parse(ApiConstants.exercises).replace(
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );

    final res = await _client.get(uri).timeout(const Duration(seconds: 8));
    if (res.statusCode != 200) {
      throw Exception('운동 마스터 목록 조회 실패 (status=${res.statusCode})');
    }

    final decoded = jsonDecode(utf8.decode(res.bodyBytes)) as List<dynamic>;
    return decoded
        .map((e) => ExerciseMaster.fromJson(e as Map<String, dynamic>))
        .toList();
  }


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

  /// DELETE /api/workouts/{id}
  Future<void> deleteWorkout(int id, {String userId = ApiConstants.defaultUserId}) async {
    final uri = Uri.parse('${ApiConstants.workouts}/$id?userId=$userId');
    final res = await _client.delete(uri).timeout(const Duration(seconds: 8));
    if (res.statusCode != 200 && res.statusCode != 204) {
      throw Exception('운동 기록 삭제 실패 (status=${res.statusCode})');
    }
  }

  /// AI 추천 루틴의 종목들을 오늘 운동 기록으로 일괄 등록
  Future<List<Workout>> importRoutine(
    List<RecommendedRoutineItem> items, {
    String userId = ApiConstants.defaultUserId,
    DateTime? date,
  }) async {
    final targetDate = date ?? DateTime.now();
    final results = <Workout>[];
    for (final item in items) {
      final workout = Workout(
        userId: userId,
        exerciseName: item.exerciseName,
        sets: item.sets > 0 ? item.sets : 3,
        reps: item.reps > 0 ? item.reps : 10,
        weight: 30.0,
        workoutDate: targetDate,
        memo: 'AI 추천 루틴 [${item.focus}] - ${item.tip}',
      );
      final created = await createWorkout(workout);
      results.add(created);
    }
    return results;
  }

  void dispose() => _client.close();
}

