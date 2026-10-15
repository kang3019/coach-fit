import 'dart:convert';
import 'package:http/http.dart' as http;

import '../config/api_constants.dart';
import '../models/ai_chat_message.dart';
import 'auth_service.dart';
import 'goal_service.dart';

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
      throw Exception('AI 응답을 받아오지 못했습니다. (status=${res.statusCode})');
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
