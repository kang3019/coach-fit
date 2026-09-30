import 'dart:convert';
import 'package:http/http.dart' as http;

import '../config/api_constants.dart';
import '../models/coaching_result.dart';

/// Java 백엔드가 Python AI 서버로 중계해주는 코칭 API를 호출한다.
/// 앱은 Python(8000)을 직접 호출하지 않고 Java(8080)만 바라본다.
class CoachingService {
  final http.Client _client;
  CoachingService({http.Client? client}) : _client = client ?? http.Client();

  /// POST /api/coaching/generate
  /// Body: {"userId": "...", "goal": "..."}
  Future<CoachingResult> requestCoaching({
    String userId = ApiConstants.defaultUserId,
    String goal = '근비대 및 전신 근력 증진',
  }) async {
    final res = await _client
        .post(
          Uri.parse(ApiConstants.coachingGenerate),
          headers: {'Content-Type': 'application/json; charset=UTF-8'},
          body: jsonEncode({'userId': userId, 'goal': goal}),
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
