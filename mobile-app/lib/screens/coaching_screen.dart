import 'package:flutter/material.dart';

import '../models/coaching_result.dart';
import '../services/coaching_service.dart';
import '../theme/coachfit_theme.dart';
import 'ai_chat_screen.dart';

class CoachingScreen extends StatefulWidget {
  const CoachingScreen({super.key});

  @override
  State<CoachingScreen> createState() => _CoachingScreenState();
}

class _CoachingScreenState extends State<CoachingScreen> {
  final CoachingService _service = CoachingService();
  Future<CoachingResult>? _future;

  @override
  void initState() {
    super.initState();
    _future = _service.requestCoaching();
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }

  void _regenerate() {
    setState(() {
      _future = _service.requestCoaching();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI 코칭 리포트'),
        actions: [
          IconButton(
            onPressed: _regenerate,
            icon: const Icon(Icons.refresh),
            tooltip: '다시 분석',
          ),
        ],
      ),
      body: FutureBuilder<CoachingResult>(
        future: _future,
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const _LoadingView();
          }
          if (snap.hasError) {
            return _ErrorView(error: '${snap.error}', onRetry: _regenerate);
          }
          final r = snap.data!;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            children: [
              _AnalysisSummaryCard(summary: r.summary),
              _CoachAdviceCard(advice: r.coachingAdvice),
              const SizedBox(height: 8),
              const Text(
                '🎯 오늘 추천 루틴',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              ...r.recommendedRoutine.map((e) => _RoutineCard(item: e)),
              const SizedBox(height: 16),
              // AI 코치 1:1 대화하기 CTA 버튼
              SizedBox(
                height: 50,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B202A),
                    foregroundColor: Colors.white,
                    side: BorderSide(color: CoachFitColors.orange.withValues(alpha: 0.6)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 2,
                  ),
                  icon: const Icon(Icons.chat_bubble_outline_rounded, color: CoachFitColors.orange, size: 18),
                  label: const Text(
                    '이 분석에 대해 AI 코치와 1:1 대화하기',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const AiChatScreen(
                          initialMessage: '방금 생성된 AI 코칭 리포트에 대해 추가로 질문하고 싶어요.',
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '생성 시각: ${r.generatedAt}',
                style: const TextStyle(color: Colors.white38, fontSize: 11),
                textAlign: TextAlign.right,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _AnalysisSummaryCard extends StatelessWidget {
  final String summary;

  const _AnalysisSummaryCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    String cleanText = summary;
    final List<String> specBadges = [];

    final specMatch = RegExp(r'\[신체 스펙:\s*([^\]]+)\]').firstMatch(cleanText);
    if (specMatch != null) {
      final specContent = specMatch.group(1) ?? '';
      specBadges.addAll(
        specContent.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty),
      );
      cleanText = cleanText.replaceAll(specMatch.group(0)!, '').replaceAll('  ', ' ').trim();
    }

    cleanText = cleanText.replaceAll(RegExp(r'\([^)]*에러로 더미[^)]*\)'), '').trim();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF151922),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF232B38)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.analytics_outlined, color: CoachFitColors.mint, size: 18),
                  SizedBox(width: 8),
                  Text(
                    '최근 분석 요약',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: CoachFitColors.mint.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'AI 진단 완료',
                  style: TextStyle(
                    color: CoachFitColors.mint,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          if (specBadges.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: specBadges.map((badge) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Text(
                    badge,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: 12),
          Text(
            cleanText,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13.5,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

class _CoachAdviceCard extends StatelessWidget {
  final String advice;

  const _CoachAdviceCard({required this.advice});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF1D1714),
            Color(0xFF151922),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: CoachFitColors.orange.withValues(alpha: 0.35),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: CoachFitColors.orange.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.auto_awesome, color: CoachFitColors.orange, size: 15),
              ),
              const SizedBox(width: 8),
              const Text(
                'AI 코치의 조언',
                style: TextStyle(
                  color: CoachFitColors.orange,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            advice,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13.5,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

class _RoutineCard extends StatelessWidget {
  final RecommendedRoutineItem item;
  const _RoutineCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.exerciseName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: scheme.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${item.sets}세트 × ${item.reps}회',
                    style: TextStyle(
                      color: scheme.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              item.focus,
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: CoachFitColors.background,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '💡 ${item.tip}',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text(
            '최근 운동 데이터를 분석 중…',
            style: TextStyle(color: Colors.white54),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const _ErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.white24),
          const SizedBox(height: 12),
          Text(
            'AI 서버 연결 실패\n$error',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white54, height: 1.4),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: onRetry,
            child: const Text('다시 시도'),
          ),
        ],
      ),
    );
  }
}
