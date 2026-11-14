import 'dart:convert';
import 'package:http/http.dart' as http;

import '../config/api_constants.dart';
import '../models/coaching_result.dart';
import 'api_error.dart';
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
  /// - 401(만료/세션 불일치) 발생 시 데모 세션 자동 재발급 후 1회 재시도
  /// - 네트워크 지연/오프라인/호출 제한(429) 등 예외 발생 시 목표 맞춤형 스마트 폴백 루틴 즉시 반환
  Future<CoachingResult> requestCoaching({
    String? userId,
    String? goal,
  }) async {
    final effectiveGoal = goal ?? (await _goalService.load()).aiPromptPhrase;
    try {
      var effectiveUserId = userId ?? await AuthService.instance.getCurrentUserId();
      var headers = await AuthService.instance.getAuthHeaders();

      // 토큰이 아예 없는 상태라면 데모 세션 자동 발급 시도
      if (!headers.containsKey('Authorization')) {
        headers = await AuthService.instance.refreshDemoSessionHeaders();
        effectiveUserId = userId ?? await AuthService.instance.getCurrentUserId();
      }

      var res = await _client
          .post(
            Uri.parse(ApiConstants.coachingGenerate),
            headers: headers,
            body: jsonEncode({'userId': effectiveUserId, 'goal': effectiveGoal}),
          )
          .timeout(const Duration(seconds: 25));

      // 기존 로컬 토큰이 만료되었거나 서버 재배포로 무효화된 경우 자동 재로그인 후 1회 재시도
      if (res.statusCode == 401 || res.statusCode == 403) {
        headers = await AuthService.instance.refreshDemoSessionHeaders();
        effectiveUserId = userId ?? await AuthService.instance.getCurrentUserId();
        res = await _client
            .post(
              Uri.parse(ApiConstants.coachingGenerate),
              headers: headers,
              body: jsonEncode({'userId': effectiveUserId, 'goal': effectiveGoal}),
            )
            .timeout(const Duration(seconds: 25));
      }

      if (res.statusCode != 200) {
        throw Exception(apiErrorMessage(res, 'AI 코칭 요청 실패'));
      }

      final decoded = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      final parsed = CoachingResult.fromJson(decoded);
      if (parsed.recommendedRoutine.isEmpty) {
        return CoachingResult.fallback(goal: effectiveGoal);
      }
      return parsed;
    } catch (_) {
      return CoachingResult.fallback(goal: effectiveGoal);
    }
  }

  void dispose() => _client.close();
}
