class AiChatMessage {
  final String id;
  final String role; // 'user' | 'assistant'
  final String content;
  final List<String> suggestedQuestions;
  final DateTime timestamp;

  AiChatMessage({
    required this.id,
    required this.role,
    required this.content,
    this.suggestedQuestions = const [],
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  bool get isUser => role == 'user';

  Map<String, dynamic> toHistoryJson() => {
        'role': role,
        'content': content,
      };
}
