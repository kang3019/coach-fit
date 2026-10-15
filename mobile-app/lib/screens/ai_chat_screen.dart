import 'package:flutter/material.dart';

import '../models/ai_chat_message.dart';
import '../services/ai_chat_service.dart';
import '../theme/coachfit_theme.dart';

class AiChatScreen extends StatefulWidget {
  final String? initialMessage;

  const AiChatScreen({super.key, this.initialMessage});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final AiChatService _chatService = AiChatService();
  final TextEditingController _inputCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  final List<AiChatMessage> _messages = [];
  bool _isLoading = false;

  final List<String> _quickPrompts = [
    '오늘 30분 전신 루틴 추천해줘',
    '벤치프레스 어깨 안 아프게 하는 법',
    '체중 대비 하루 단백질 권장량',
    '정체기 뚫는 점진적 과부하 팁',
    '허리 부담 적은 하체 운동 추천',
  ];

  @override
  void initState() {
    super.initState();
    _addInitialGreeting();
    if (widget.initialMessage != null && widget.initialMessage!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleSend(widget.initialMessage!);
      });
    }
  }

  void _addInitialGreeting() {
    _messages.add(
      AiChatMessage(
        id: 'welcome',
        role: 'assistant',
        content:
            '안녕하세요! 회원님의 1:1 전담 AI 피트니스 코치입니다. 💪\n\n'
            '운동 루틴 설계, 자세 교정 포인트, 점진적 과부하 주기화, 그리고 식단/단백질 가이드까지 무엇이든 물어보세요!',
        suggestedQuestions: [
          '오늘 가슴 & 삼두 집중 루틴 알려줘',
          '스쿼트 무릎 통증 줄이는 발 위치',
          '다이어트 중 단백질 식단 추천',
        ],
      ),
    );
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    _chatService.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _handleSend(String text) async {
    final query = text.trim();
    if (query.isEmpty || _isLoading) return;

    _inputCtrl.clear();
    setState(() {
      _messages.add(
        AiChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          role: 'user',
          content: query,
        ),
      );
      _isLoading = true;
    });
    _scrollToBottom();

    try {
      final res = await _chatService.sendMessage(
        message: query,
        history: _messages,
      );

      if (!mounted) return;
      setState(() {
        _messages.add(
          AiChatMessage(
            id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
            role: 'assistant',
            content: res.reply,
            suggestedQuestions: res.suggestions,
          ),
        );
        _isLoading = false;
      });
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.add(
          AiChatMessage(
            id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
            role: 'assistant',
            content: '일시적인 연결 문제로 답변을 생성하지 못했습니다. 다시 시도해 주세요.',
            suggestedQuestions: [
              '다시 시도하기',
              '오늘 추천 운동 루틴 알려줘',
            ],
          ),
        );
        _isLoading = false;
      });
      _scrollToBottom();
    }
  }

  void _confirmClearChat() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: CoachFitColors.surfaceRaised,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('대화 내역 초기화', style: TextStyle(color: Colors.white, fontSize: 16)),
        content: const Text('현재 대화 내역을 모두 지우고 처음 상태로 돌아갈까요?',
            style: TextStyle(color: Colors.white70, fontSize: 13)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: CoachFitColors.orange,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _messages.clear();
                _addInitialGreeting();
              });
            },
            child: const Text('초기화'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CoachFitColors.background,
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: CoachFitColors.orange.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.auto_awesome, color: CoachFitColors.orange, size: 18),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CoachFit AI 1:1 코치',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  '⚡ AWS Bedrock Claude 3.5 Sonnet',
                  style: TextStyle(
                    color: CoachFitColors.mint,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: '대화 초기화',
            onPressed: _confirmClearChat,
            icon: const Icon(Icons.delete_sweep_outlined, color: Colors.white54),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 메시지 리스트
            Expanded(
              child: ListView.builder(
                controller: _scrollCtrl,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                itemCount: _messages.length + (_isLoading ? 1 : 0),
                itemBuilder: (ctx, idx) {
                  if (idx == _messages.length && _isLoading) {
                    return _buildLoadingBubble();
                  }
                  final msg = _messages[idx];
                  return _buildMessageItem(msg);
                },
              ),
            ),

            // 빠른 질문 추천 칩 (메시지 수가 적을 때)
            if (_messages.length <= 3 && !_isLoading)
              Container(
                height: 38,
                margin: const EdgeInsets.only(bottom: 6),
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _quickPrompts.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (ctx, i) {
                    final prompt = _quickPrompts[i];
                    return ActionChip(
                      backgroundColor: const Color(0xFF1B202A),
                      side: const BorderSide(color: CoachFitColors.line),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      label: Text(
                        prompt,
                        style: const TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                      onPressed: () => _handleSend(prompt),
                    );
                  },
                ),
              ),

            // 하단 입력 바
            _buildInputBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageItem(AiChatMessage msg) {
    if (msg.isUser) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12, left: 40),
        child: Align(
          alignment: Alignment.centerRight,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFF5722), Color(0xFFFF3D00)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(4),
                bottomLeft: Radius.circular(18),
                bottomRight: Radius.circular(18),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Text(
              msg.content,
              style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.4),
            ),
          ),
        ),
      );
    }

    // AI 어시스턴트 메시지
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, right: 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: CoachFitColors.mint.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(Icons.fitness_center, size: 12, color: CoachFitColors.mint),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'CoachFit AI',
                style: TextStyle(
                  color: CoachFitColors.mint,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF151922),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(18),
                bottomLeft: Radius.circular(18),
                bottomRight: Radius.circular(18),
              ),
              border: Border.all(color: const Color(0xFF232B38)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Text(
              msg.content,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                height: 1.55,
              ),
            ),
          ),

          // 추천 질문 리스트 (있는 경우 칩 형태로 제공)
          if (msg.suggestedQuestions.isNotEmpty) ...[
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: msg.suggestedQuestions.map((q) {
                  return InkWell(
                    onTap: () => _handleSend(q),
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: CoachFitColors.mint.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: CoachFitColors.mint.withValues(alpha: 0.3),
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.chat_bubble_outline_rounded,
                              size: 11, color: CoachFitColors.mint),
                          const SizedBox(width: 5),
                          Text(
                            q,
                            style: const TextStyle(
                              color: CoachFitColors.mint,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLoadingBubble() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF151922),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF232B38)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(CoachFitColors.mint),
                  ),
                ),
                SizedBox(width: 10),
                Text(
                  'AI 코치가 분석 중입니다...',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      decoration: const BoxDecoration(
        color: Color(0xFF11141B),
        border: Border(top: BorderSide(color: CoachFitColors.line)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _inputCtrl,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              textInputAction: TextInputAction.send,
              onSubmitted: _handleSend,
              decoration: InputDecoration(
                hintText: 'AI 코치에게 운동이나 식단을 질문해 보세요...',
                hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                filled: true,
                fillColor: const Color(0xFF181C26),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(color: CoachFitColors.line),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(color: CoachFitColors.line),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(color: CoachFitColors.orange),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: const BoxDecoration(
              color: CoachFitColors.orange,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_upward_rounded, color: Colors.white),
              onPressed: () => _handleSend(_inputCtrl.text),
            ),
          ),
        ],
      ),
    );
  }
}
