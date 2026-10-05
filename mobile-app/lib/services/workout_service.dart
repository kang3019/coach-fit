import 'dart:convert';
import 'package:http/http.dart' as http;

import '../config/api_constants.dart';
import '../models/coaching_result.dart';
import '../models/exercise_master.dart';
import '../models/workout.dart';
import 'auth_service.dart';

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

  /// GET /api/workouts?userId=...
  Future<List<Workout>> fetchWorkouts({
    String? userId,
  }) async {
    final targetUserId = userId ?? await AuthService.instance.getCurrentUserId();
    final headers = await AuthService.instance.getAuthHeaders();
    final uri = Uri.parse('${ApiConstants.workouts}?userId=$targetUserId');
    final res = await _client.get(uri, headers: headers).timeout(const Duration(seconds: 8));

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
    final headers = await AuthService.instance.getAuthHeaders();
    final effectiveUserId = workout.userId.isNotEmpty && workout.userId != ApiConstants.defaultUserId
        ? workout.userId
        : await AuthService.instance.getCurrentUserId();

    final payload = workout.toCreateJson();
    payload['userId'] = effectiveUserId;

    final res = await _client
        .post(
          Uri.parse(ApiConstants.workouts),
          headers: headers,
          body: jsonEncode(payload),
        )
        .timeout(const Duration(seconds: 8));

    if (res.statusCode != 201 && res.statusCode != 200) {
      throw Exception('운동 기록 등록 실패 (status=${res.statusCode})');
    }
    final decoded = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    return Workout.fromJson(decoded);
  }

  /// GET /api/workouts/weekly-stats
  Future<Map<String, double>> fetchWeeklyVolume({
    String? userId,
  }) async {
    final targetUserId = userId ?? await AuthService.instance.getCurrentUserId();
    final headers = await AuthService.instance.getAuthHeaders();
    final uri = Uri.parse('${ApiConstants.weeklyStats}?userId=$targetUserId');
    final res = await _client.get(uri, headers: headers).timeout(const Duration(seconds: 8));
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
  Future<void> deleteWorkout(int id, {String? userId}) async {
    final targetUserId = userId ?? await AuthService.instance.getCurrentUserId();
    final headers = await AuthService.instance.getAuthHeaders();
    final uri = Uri.parse('${ApiConstants.workouts}/$id?userId=$targetUserId');
    final res = await _client.delete(uri, headers: headers).timeout(const Duration(seconds: 8));
    if (res.statusCode != 200 && res.statusCode != 204) {
      throw Exception('운동 기록 삭제 실패 (status=${res.statusCode})');
    }
  }

  /// AI 추천 루틴의 종목들을 오늘 운동 기록으로 일괄 등록
  Future<List<Workout>> importRoutine(
    List<RecommendedRoutineItem> items, {
    String? userId,
    DateTime? date,
  }) async {
    final targetUserId = userId ?? await AuthService.instance.getCurrentUserId();
    final targetDate = date ?? DateTime.now();
    final results = <Workout>[];
    for (final item in items) {
      final workout = Workout(
        userId: targetUserId,
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
