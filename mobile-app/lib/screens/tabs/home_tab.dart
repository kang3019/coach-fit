import 'package:flutter/material.dart';
import '../../models/coaching_result.dart';
import '../../models/workout.dart';
import '../../services/coaching_service.dart';
import '../../services/goal_service.dart';
import '../../services/profile_service.dart';
import '../../services/workout_service.dart';
import '../../theme/coachfit_theme.dart';
import '../../widgets/home/condition_selector.dart';
import '../../widgets/home/home_summary.dart';
import '../../widgets/home/recommended_routine_card.dart';
import '../../widgets/home/today_plan_card.dart';
import '../../widgets/home/weekly_rhythm_card.dart';
import '../coaching_screen.dart';
import '../routine_detail_screen.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: CoachFitColors.orange,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.bolt, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 10),
            const Text(
              'CoachFit',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 20,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: CoachFitColors.surfaceRaised,
              shape: BoxShape.circle,
              border: Border.all(color: CoachFitColors.border),
            ),
            child: IconButton(
              icon: const Icon(
                Icons.notifications_none_rounded,
                color: CoachFitColors.textPrimary,
                size: 20,
              ),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('새로운 알림이 없습니다.'),
                    duration: Duration(seconds: 1),
                  ),
                );
              },
            ),
          ),
        ],
      ),
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
                  onImportRoutine: _handleImportRoutine,
                  onStartRoutine: widget.onNavigateToLog,
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
}
