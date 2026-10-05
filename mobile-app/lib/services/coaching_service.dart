import 'dart:convert';
import 'package:http/http.dart' as http;

import '../config/api_constants.dart';
import '../models/coaching_result.dart';
import 'auth_service.dart';
import 'goal_service.dart';

/// FastAPI 통합 백엔드(8000)의 DB 기반 AI 코칭 생성 API를 호출한다.
class CoachingService {
  final http.Client _client;
  final GoalService _goalService;
  CoachingService({http.Client? client, GoalService? goalService})
      : _client = client ?? http.Client(),
        _goalService = goalService ?? GoalService();

  /// POST /api/coaching/generate
  /// Body: {"userId": "...", "goal": "..."}
  Future<CoachingResult> requestCoaching({
    String? userId,
    String? goal,
  }) async {
    final effectiveUserId = userId ?? await AuthService.instance.getCurrentUserId();
    final effectiveGoal = goal ?? (await _goalService.load()).aiPromptPhrase;
    final headers = await AuthService.instance.getAuthHeaders();

    final res = await _client
        .post(
          Uri.parse(ApiConstants.coachingGenerate),
          headers: headers,
          body: jsonEncode({'userId': effectiveUserId, 'goal': effectiveGoal}),
        )
        .timeout(const Duration(seconds: 20));

    if (res.statusCode != 200) {
      throw Exception('AI 코칭 요청 실패 (status=${res.statusCode})');
    }

    final decoded = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    return CoachingResult.fromJson(decoded);
  }

  void dispose() => _client.close();
}
