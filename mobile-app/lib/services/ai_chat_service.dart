import 'dart:convert';
import 'package:http/http.dart' as http;

import '../config/api_constants.dart';
import '../models/ai_chat_message.dart';
import 'api_error.dart';
import 'auth_service.dart';
import 'goal_service.dart';

/// 서버가 거절 사유(한도 초과, 로그인 만료 등)를 알려준 경우의 채팅 실패.
class AiChatException implements Exception {
  final String message;
  const AiChatException(this.message);

  @override
  String toString() => message;
}

class AiChatService {
  final http.Client _client;
  final GoalService _goalService;

  AiChatService({http.Client? client, GoalService? goalService})
      : _client = client ?? http.Client(),
        _goalService = goalService ?? GoalService();

  Future<({String reply, List<String> suggestions})> sendMessage({
    required String message,
    required List<AiChatMessage> history,
  }) async {
    final userId = await AuthService.instance.getCurrentUserId();
    final goal = (await _goalService.load()).aiPromptPhrase;
    final headers = await AuthService.instance.getAuthHeaders();

    final payload = {
      'message': message,
      'userId': userId,
      'user_goal': goal,
      'history': history
          .map((m) => m.toHistoryJson())
          .toList(),
    };

    final res = await _client
        .post(
          Uri.parse(ApiConstants.aiChat),
          headers: headers,
          body: jsonEncode(payload),
        )
        .timeout(const Duration(seconds: 25));

    if (res.statusCode != 200) {
      throw AiChatException(apiErrorMessage(res, 'AI 응답을 받아오지 못했습니다.'));
    }

    final decoded = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    final reply = decoded['reply'] as String? ?? '답변을 불러오지 못했습니다.';
    final suggestions = ((decoded['suggested_questions'] as List<dynamic>?) ?? [])
        .map((e) => e.toString())
        .toList();

    return (reply: reply, suggestions: suggestions);
  }

  void dispose() => _client.close();
}
