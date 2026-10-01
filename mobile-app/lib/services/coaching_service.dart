import 'dart:convert';
import 'package:http/http.dart' as http;

import '../config/api_constants.dart';
import '../models/coaching_result.dart';
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
  ///
  /// [goal] 생략 시 사용자가 메뉴에서 설정한 운동 목표(SharedPreferences)
  /// 를 자동으로 불러와 전달한다. 기존 호출부(home_tab, coaching_screen)
  /// 는 수정 없이 자동으로 사용자 설정값을 반영받는다.
  Future<CoachingResult> requestCoaching({
    String userId = ApiConstants.defaultUserId,
    String? goal,
  }) async {
    final effectiveGoal = goal ?? (await _goalService.load()).aiPromptPhrase;
    final res = await _client
        .post(
          Uri.parse(ApiConstants.coachingGenerate),
          headers: {'Content-Type': 'application/json; charset=UTF-8'},
          body: jsonEncode({'userId': userId, 'goal': effectiveGoal}),
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
