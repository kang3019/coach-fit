import 'package:flutter/material.dart';
import '../../data/exercise_guide_data.dart';
import '../../models/coaching_result.dart';
import '../../services/coaching_service.dart';
import '../../services/goal_service.dart';
import '../../services/workout_service.dart';
import '../coaching_screen.dart';
import '../routine_detail_screen.dart';
import '../widgets/home_progress_strip.dart';
import '../widgets/last_workout_card.dart';
import '../widgets/smart_suggestion_card.dart';

/// 1. 홈 탭 (Home Tab)
/// - 오늘의 AI 추천 운동 루틴
/// - 오늘의 컨디션 체크
/// - 빠른 운동/타이머 시작
class HomeTab extends StatefulWidget {
  final VoidCallback onNavigateToLog;
  final VoidCallback onNavigateToStats;

  const HomeTab({
    super.key,
    required this.onNavigateToLog,
    required this.onNavigateToStats,
  });

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  final CoachingService _coachingService = CoachingService();
  final WorkoutService _workoutService = WorkoutService();
  final GoalService _goalService = GoalService();
  late Future<CoachingResult> _coachingFuture;
  String _selectedCondition = '좋음 🔥';

  @override
  void initState() {
    super.initState();
    _coachingFuture = _coachingService.requestCoaching();
    // 메뉴 탭에서 운동 목표를 바꾸면 자동으로 AI 코칭 재호출
    _goalService.addListener(_onGoalChanged);
  }

  @override
  void dispose() {
    _goalService.removeListener(_onGoalChanged);
    _coachingService.dispose();
    _workoutService.dispose();
    super.dispose();
  }

  /// GoalService 가 변경되면 호출됨 (메뉴 탭에서 사용자가 목표 변경 시).
  /// 캐시된 AI 코칭을 폐기하고 최신 목표로 다시 요청한다.
  void _onGoalChanged() {
    if (!mounted) return;
    setState(() {
      _coachingFuture = _coachingService.requestCoaching();
    });
  }

  Future<void> _handleImportRoutine(List<RecommendedRoutineItem> items) async {
    try {
      final created = await _workoutService.importRoutine(items);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('AI 추천 루틴 ${created.length}개 종목이 오늘 기록에 추가되었습니다!'),
            backgroundColor: const Color(0xFF00E5A0),
          ),
        );
        widget.onNavigateToLog();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('루틴 담기 실패: $e')),
        );
      }
    }
  }



  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: scheme.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.bolt, color: scheme.primary, size: 20),
            ),
            const SizedBox(width: 10),
            const Text(
              'CoachFit',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {
            _coachingFuture = _coachingService.requestCoaching();
          });
          await _coachingFuture;
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            // 1. 오늘의 웰컴 & 스트릭 배너
            _StreakBanner(
              onTapStats: widget.onNavigateToStats,
            ),
            const SizedBox(height: 16),

            // 1.5 홈 진행 스트립 (A 담당: 오늘/주간/스트릭/체중)
            const HomeProgressStrip(),
            const SizedBox(height: 16),

            // 2. 오늘의 컨디션 체크
            _ConditionCheckCard(
              currentCondition: _selectedCondition,
              onChanged: (val) {
                setState(() => _selectedCondition = val);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('컨디션이 \'$val\'(으)로 반영되었습니다.'),
                    duration: const Duration(seconds: 1),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),

            // 2.5 지난 운동 복습 + progressive overload (A 담당)
            LastWorkoutCard(
              onStartRecording: widget.onNavigateToLog,
            ),
            const SizedBox(height: 16),

            // 3. 오늘의 AI 추천 운동 루틴 카드
            FutureBuilder<CoachingResult>(
              future: _coachingFuture,
              builder: (ctx, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const _AiLoadingCard();
                }
                if (snap.hasError) {
                  return _AiErrorCard(
                    error: snap.error.toString(),
                    onRetry: () {
                      setState(() {
                        _coachingFuture = _coachingService.requestCoaching();
                      });
                    },
                  );
                }
                final result = snap.data!;
                return _AiRoutineCard(
                  result: result,
                  onImportRoutine: _handleImportRoutine,
                  onStartRoutine: widget.onNavigateToLog,
                  onViewFullReport: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const CoachingScreen(),
                      ),
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 16),

            // 3.5 스마트 제안 로테이션 (휴식/랜덤/명언) (A 담당)
            const SmartSuggestionCard(),
            const SizedBox(height: 16),

            // 스크린샷 '헬스 초보 무분할 루틴' 프리셋 바로가기 배너 (플릭 뷰)
            _ScreenshotPresetBanner(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => RoutineDetailScreen(
                      title: '헬스 초보 무분할 루틴',
                      initialExercises: [
                        RoutineExerciseItem(
                          name: '머신 체스트 프레스',
                          targetMuscle: '가슴, 어깨',
                          imageUrl: 'https://cdn.jsdelivr.net/gh/omercotkd/exercises-gifs@main/assets/0577.gif',
                        ),
                        RoutineExerciseItem(
                          name: '바벨 스쿼트',
                          targetMuscle: '대퇴사두, 둔근',
                          imageUrl: 'https://cdn.jsdelivr.net/gh/omercotkd/exercises-gifs@main/assets/0043.gif',
                        ),
                        RoutineExerciseItem(
                          name: '랫 풀 다운',
                          targetMuscle: '등, 이두',
                          imageUrl: 'https://cdn.jsdelivr.net/gh/omercotkd/exercises-gifs@main/assets/2330.gif',
                        ),
                        RoutineExerciseItem(
                          name: '바벨 숄더 프레스',
                          targetMuscle: '어깨, 삼두',
                          imageUrl: 'https://cdn.jsdelivr.net/gh/omercotkd/exercises-gifs@main/assets/0086.gif',
                        ),
                      ],
                      onStartWorkout: widget.onNavigateToLog,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),

            // 4. 빠른 액션 바로가기 그리드
            _QuickActionCard(
              icon: Icons.edit_note_rounded,
              title: '세트 기록하기',
              subtitle: '오늘 한 운동 입력',
              color: scheme.primary,
              onTap: widget.onNavigateToLog,
            ),
          ],
        ),
      ),
    );
  }
}

class _StreakBanner extends StatelessWidget {
  final VoidCallback onTapStats;
  const _StreakBanner({required this.onTapStats});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E2633), Color(0xFF131822)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.local_fire_department_rounded,
              color: Color(0xFFF59E0B),
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '3일 연속 운동 달성 중! 🔥',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '이번 주 목표(주 4회)까지 1회 남았어요.',
                  style: TextStyle(color: Colors.white60, fontSize: 13),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onTapStats,
            icon: const Icon(Icons.chevron_right_rounded, color: Colors.white54),
          ),
        ],
      ),
    );
  }
}

class _ConditionCheckCard extends StatelessWidget {
  final String currentCondition;
  final ValueChanged<String> onChanged;

  const _ConditionCheckCard({
    required this.currentCondition,
    required this.onChanged,
  });

  static const _conditions = ['최상 🚀', '좋음 🔥', '보통 😐', '피로 🥱'];

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '오늘의 컨디션은 어떤가요?',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: _conditions.map((cond) {
                final isSelected = cond == currentCondition;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () => onChanged(cond),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 2),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF00E5A0).withValues(alpha: 0.2)
                              : Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF00E5A0)
                                : Colors.transparent,
                          ),
                        ),
                        child: Center(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              cond,
                              style: TextStyle(
                                color: isSelected ? const Color(0xFF00E5A0) : Colors.white70,
                                fontSize: 12,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _AiRoutineCard extends StatefulWidget {
  final CoachingResult result;
  final Future<void> Function(List<RecommendedRoutineItem> items) onImportRoutine;
  final VoidCallback onStartRoutine;
  final VoidCallback onViewFullReport;

  const _AiRoutineCard({
    required this.result,
    required this.onImportRoutine,
    required this.onStartRoutine,
    required this.onViewFullReport,
  });

  @override
  State<_AiRoutineCard> createState() => _AiRoutineCardState();
}

class _AiRoutineCardState extends State<_AiRoutineCard> {
  bool _importing = false;

  Future<void> _handleImport() async {
    setState(() => _importing = true);
    try {
      await widget.onImportRoutine(widget.result.recommendedRoutine);
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF171B22),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.primary.withValues(alpha: 0.3)),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.auto_awesome, color: scheme.primary, size: 20),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI 맞춤 오늘 추천 루틴',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '최근 운동 볼륨 및 피로도 기반 분석',
                      style: TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: widget.onViewFullReport,
                child: Text('상세 진단', style: TextStyle(color: scheme.primary, fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 코칭 요약 말풍선
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              widget.result.summary,
              style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
            ),
          ),
          const SizedBox(height: 14),

          const Text(
            '오늘 수행할 추천 운동',
            style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),

          // 추천 운동 종목 목록 — 썸네일 GIF 자동 매칭 (exercise_guide_data 재사용)
          ...widget.result.recommendedRoutine.take(3).map((item) {
            final guide = findExerciseGuide(item.exerciseName);
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  // 썸네일 (GIF 매칭 시 재생, 아니면 덤벨 아이콘)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: 44,
                      height: 44,
                      color: const Color(0xFF0E1116),
                      child: guide?.gifUrl != null
                          ? Image.network(
                              guide!.gifUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Center(
                                child: Icon(
                                  Icons.fitness_center_rounded,
                                  color: scheme.primary.withValues(alpha: 0.6),
                                  size: 22,
                                ),
                              ),
                              loadingBuilder: (ctx, child, progress) =>
                                  progress == null
                                      ? child
                                      : Center(
                                          child: SizedBox(
                                            width: 14,
                                            height: 14,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor:
                                                  AlwaysStoppedAnimation(
                                                      scheme.primary),
                                            ),
                                          ),
                                        ),
                            )
                          : Center(
                              child: Icon(
                                Icons.fitness_center_rounded,
                                color: scheme.primary.withValues(alpha: 0.6),
                                size: 22,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.exerciseName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (item.focus.isNotEmpty)
                          Text(
                            item.focus,
                            style: const TextStyle(
                                color: Colors.white38, fontSize: 11),
                          ),
                      ],
                    ),
                  ),
                  Text(
                    '${item.sets}세트 × ${item.reps}회',
                    style: TextStyle(
                      color: scheme.primary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 14),

          // 1. 3D 근육 지도 & 루틴 상세 화면 열기 버튼 (플릭 스타일)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => RoutineDetailScreen.fromCoachingResult(
                      widget.result,
                      onStartWorkout: widget.onStartRoutine,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF4820),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.accessibility_new_rounded, size: 20),
              label: const Text(
                '3D 근육 지도 & 루틴 시작 (플릭 뷰)',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // 2. 오늘 기록 일괄 담기 / 기록 탭 이동 보조 버튼
          Row(
            children: [
              Expanded(
                flex: 3,
                child: OutlinedButton.icon(
                  onPressed: _importing ? null : _handleImport,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF00E5A0),
                    side: BorderSide(color: const Color(0xFF00E5A0).withValues(alpha: 0.5)),
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: _importing
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF00E5A0)),
                        )
                      : const Icon(Icons.playlist_add_check_rounded, size: 18),
                  label: Text(
                    _importing ? '담는 중...' : '오늘 기록 담기',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: OutlinedButton(
                  onPressed: widget.onStartRoutine,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white70,
                    side: const BorderSide(color: Colors.white24),
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('기록 탭 이동', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ],
      ),
    );

  }
}

class _AiLoadingCard extends StatelessWidget {
  const _AiLoadingCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 14),
            Text(
              'AI 코치가 운동 기록을 분석 중입니다...',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

class _AiErrorCard extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const _AiErrorCard({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(Icons.info_outline, color: Colors.amberAccent, size: 28),
            const SizedBox(height: 8),
            Text(
              'AI 코칭을 불러오지 못했습니다.\n($error)',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white60, fontSize: 12),
            ),
            const SizedBox(height: 10),
            TextButton(onPressed: onRetry, child: const Text('다시 시도')),
          ],
        ),
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF171B22),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(color: Colors.white54, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScreenshotPresetBanner extends StatelessWidget {
  final VoidCallback onTap;

  const _ScreenshotPresetBanner({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF26191B), Color(0xFF161922)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFFF4820).withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFFF4820).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.accessibility_new_rounded, color: Color(0xFFFF6A3D), size: 24),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '헬스 초보 무분할 루틴',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(width: 6),
                      Text(
                        'BEST',
                        style: TextStyle(
                          color: Color(0xFFFF4820),
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 3),
                  Text(
                    '3D 인체 근육 지도 & 4종 대표 루틴 (플릭 뷰)',
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white38, size: 14),
          ],
        ),
      ),
    );
  }
}

