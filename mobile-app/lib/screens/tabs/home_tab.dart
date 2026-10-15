import 'package:flutter/material.dart';
import '../../models/coaching_result.dart';
import '../../models/workout.dart';
import '../../services/coaching_service.dart';
import '../../services/goal_service.dart';
import '../../services/profile_service.dart';
import '../../services/workout_events.dart';
import '../../services/workout_service.dart';
import '../../theme/coachfit_theme.dart';
import '../../widgets/home/condition_selector.dart';
import '../../widgets/home/home_summary.dart';
import '../../widgets/home/recommended_routine_card.dart';
import '../../widgets/home/today_plan_card.dart';
import '../../widgets/home/weekly_rhythm_card.dart';
import '../coaching_screen.dart';
import '../routine_detail_screen.dart';
import '../ai_chat_screen.dart';
import '../widgets/last_workout_card.dart';
import '../widgets/smart_suggestion_card.dart';
import '../../widgets/common/coachfit_app_bar.dart';
import '../../widgets/home/routine_start_modal.dart';

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
  final ProfileService _profileService = ProfileService();
  late Future<CoachingResult> _coachingFuture;
  late Future<HomeSummary> _summaryFuture;
  String _selectedCondition = '좋아요';

  @override
  void initState() {
    super.initState();
    _coachingFuture = _coachingService.requestCoaching();
    _summaryFuture = _loadHomeSummary();
    // 메뉴 탭에서 운동 목표를 바꾸면 자동으로 AI 코칭 재호출
    _goalService.addListener(_onGoalChanged);
    WorkoutEvents.instance.addListener(_onWorkoutsChanged);
  }

  @override
  void dispose() {
    _goalService.removeListener(_onGoalChanged);
    WorkoutEvents.instance.removeListener(_onWorkoutsChanged);
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

  /// 세트 저장/삭제 시 홈 요약(3D 근육, 주간 볼륨)만 즉시 갱신.
  void _onWorkoutsChanged() {
    if (!mounted) return;
    setState(() {
      _summaryFuture = _loadHomeSummary();
    });
  }

  Future<HomeSummary> _loadHomeSummary() async {
    final profile = await _profileService.load();
    List<Workout> workouts;
    try {
      workouts = await _workoutService.fetchWorkouts();
    } catch (_) {
      workouts = const [];
    }
    return HomeSummary.fromWorkouts(
      nickname: profile.nickname,
      workouts: workouts,
      now: DateTime.now(),
    );
  }

  void _refreshHome() {
    setState(() {
      _coachingFuture = _coachingService.requestCoaching();
      _summaryFuture = _loadHomeSummary();
    });
  }

  String _focusMuscle(CoachingResult? result) {
    final items = result?.recommendedRoutine ?? const <RecommendedRoutineItem>[];
    if (items.isEmpty || items.first.focus.trim().isEmpty) return '전신';
    return items.first.focus.trim().split(RegExp(r'\s+')).first;
  }

  Future<void> _handleImportRoutine(List<RecommendedRoutineItem> items) async {
    try {
      final created = await _workoutService.importRoutine(items);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('AI 추천 루틴 ${created.length}개 종목이 오늘 기록에 추가되었습니다!'),
            backgroundColor: CoachFitColors.mint,
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

  Future<void> _showStartRoutineModal(CoachingResult result) async {
    final items = result.recommendedRoutine;
    if (items.isEmpty) {
      widget.onNavigateToLog();
      return;
    }

    final focus = _focusMuscle(result);

    await RoutineStartModal.show(
      context: context,
      title: '오늘의 AI 추천 루틴',
      subtitle: '$focus 집중 공략',
      tag: 'AI 실시간 분석',
      tagColor: CoachFitColors.orange,
      items: items.map((e) => RoutinePreviewItem.fromRecommended(e)).toList(),
      onConfirm: (timerSec) async {
        final created = await _workoutService.importRoutine(items);
        WorkoutEvents.instance.ensureSessionStarted();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: CoachFitColors.mint, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('AI 추천 루틴 ${created.length}개 종목이 오늘 기록에 추가되었습니다! (휴식 $timerSec초)'),
                  ),
                ],
              ),
              backgroundColor: const Color(0xFF151922),
            ),
          );
          widget.onNavigateToLog();
        }
      },
      onOpenFullDetail: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => RoutineDetailScreen.fromCoachingResult(
              result,
              onStartWorkout: () => _handleImportRoutine(items),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CoachFitAppBar(),
      body: RefreshIndicator(
        onRefresh: () async {
          _refreshHome();
          await Future.wait([_coachingFuture, _summaryFuture]);
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            // 1. 오늘의 플랜 카드 (Gestalt 공통영역: 인사말, 회복 완료, 주간 목표 링, 지표)
            FutureBuilder<HomeSummary>(
              future: _summaryFuture,
              builder: (context, summarySnapshot) {
                final summary = summarySnapshot.data ?? HomeSummary.loading();
                return FutureBuilder<CoachingResult>(
                  future: _coachingFuture,
                  builder: (context, coachingSnapshot) {
                    return TodayPlanCard(
                      userName: summary.nickname,
                      focusMuscle: _focusMuscle(coachingSnapshot.data),
                      recoveryStatus: summary.recoveryStatus,
                      subMessage: summary.recoveryMessage,
                      currentWeeklyWorkouts: summary.currentWeeklyWorkouts,
                      targetWeeklyWorkouts: summary.targetWeeklyWorkouts,
                      streakDays: summary.streakDays,
                      growthRate: summary.growthLabel,
                      onTapStats: widget.onNavigateToStats,
                    );
                  },
                );
              },
            ),
            const SizedBox(height: CoachFitSpacing.lg),

            // 2. 운동 전 체크인 (컨디션 선택기)
            ConditionSelector(
              selectedCondition: _selectedCondition,
              onConditionSelected: (val) {
                setState(() => _selectedCondition = val);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('컨디션이 \'$val\'(으)로 반영되었습니다.'),
                    duration: const Duration(seconds: 1),
                  ),
                );
              },
            ),
            const SizedBox(height: CoachFitSpacing.lg),

            // 3. 오늘의 추천 운동 (3D 해부도 동적 점등 + AI 추천 루틴 + 단일 주 행동 CTA)
            FutureBuilder<CoachingResult>(
              future: _coachingFuture,
              builder: (ctx, snap) {
                return RecommendedRoutineCard(
                  result: snap.data,
                  isLoading: snap.connectionState == ConnectionState.waiting,
                  errorMessage: snap.hasError ? snap.error.toString() : null,
                  onRetry: () {
                    _refreshHome();
                  },
                  onImportRoutine: (items) {
                    if (snap.data != null) {
                      _showStartRoutineModal(snap.data!);
                    } else {
                      _handleImportRoutine(items);
                    }
                  },
                  onStartRoutine: () {
                    if (snap.data != null) {
                      _showStartRoutineModal(snap.data!);
                    } else {
                      widget.onNavigateToLog();
                    }
                  },
                  onViewFullReport: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const CoachingScreen(),
                      ),
                    );
                  },
                  onOpen3dDetail: snap.hasData
                      ? () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => RoutineDetailScreen.fromCoachingResult(
                                snap.data!,
                                onStartWorkout: widget.onNavigateToLog,
                              ),
                            ),
                          );
                        }
                      : null,
                );
              },
            ),
            const SizedBox(height: CoachFitSpacing.lg),

            // AI 전담 코치 1:1 상담 배너
            _buildAiCoachBanner(context),
            const SizedBox(height: CoachFitSpacing.lg),

            // 4. 이번 주 리듬
            FutureBuilder<HomeSummary>(
              future: _summaryFuture,
              builder: (context, snapshot) {
                final summary = snapshot.data ?? HomeSummary.loading();
                return WeeklyRhythmCard(
                  completedDays: summary.completedDays,
                  todayIndex: summary.todayIndex,
                  remainingWorkouts: summary.remainingWorkouts,
                  onTapStats: widget.onNavigateToStats,
                );
              },
            ),
            const SizedBox(height: CoachFitSpacing.lg),

            // 5. 지난 운동 복습 (기존 Progressive Overload 기능 보존)
            LastWorkoutCard(
              onStartRecording: widget.onNavigateToLog,
            ),
            const SizedBox(height: CoachFitSpacing.lg),

            // 6. 스마트 제안 카드 (기존 기능 보존)
            const SmartSuggestionCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildAiCoachBanner(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const AiChatScreen()),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFF1B202A),
              Color(0xFF141822),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: CoachFitColors.orange.withValues(alpha: 0.35),
            width: 1,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1A000000),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: CoachFitColors.orange.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Center(
                child: Icon(Icons.auto_awesome, color: CoachFitColors.orange, size: 22),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        '1:1 AI 전담 코치 상담',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: CoachFitColors.mint.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Bedrock Sonnet',
                          style: TextStyle(
                            color: CoachFitColors.mint,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '자세 교정, 맞춤 루틴, 식단/단백질 가이드 실시간 질문',
                    style: TextStyle(color: Colors.white60, fontSize: 11),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.white54, size: 22),
          ],
        ),
      ),
    );
  }
}
