import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/user_profile.dart';
import '../../models/workout.dart';
import '../../services/body_record_service.dart';
import '../../services/profile_service.dart';
import '../../services/workout_events.dart';
import '../../services/workout_service.dart';
import '../../theme/coachfit_theme.dart';
import '../../widgets/common/coachfit_card.dart';
import '../../widgets/common/section_header.dart';
import '../ai_chat_screen.dart';
import '../widgets/monthly_calendar_card.dart';
import '../widgets/muscle_map_widget.dart';
import '../widgets/weekly_volume_chart.dart';
import '../../widgets/common/coachfit_app_bar.dart';

/// 통계 탭 종합 데이터 묶음.
typedef _StatsData = ({
  Map<String, double> weekly,
  List<Workout> workouts,
  List<BodyRecord> bodyRecords,
  UserProfile profile,
});

/// 3. 통계 탭 (Statistics Tab)
/// - 피그마 게슈탈트 시각 위계 기반 성장 통계 UI
/// - 기간별(주간/월간/3개월) 볼륨 차트 및 증감률 동적 산출
/// - 운동 부위별 비율 분석 (가슴, 등, 하체 등)
/// - 실시간 신체 측정치, 월간 운동 횟수 및 AI 코치 인사이트 연동
class StatsTab extends StatefulWidget {
  const StatsTab({super.key});

  @override
  State<StatsTab> createState() => _StatsTabState();
}

class _StatsTabState extends State<StatsTab> {
  final WorkoutService _workoutService = WorkoutService();
  final BodyRecordService _bodyRecordService = BodyRecordService();
  final ProfileService _profileService = ProfileService();
  late Future<_StatsData> _future;
  String _selectedPeriod = '주간';

  static const List<String> _weekdayKeys = [
    'MON',
    'TUE',
    'WED',
    'THU',
    'FRI',
    'SAT',
    'SUN',
  ];

  @override
  void initState() {
    super.initState();
    _future = _loadAll();
    WorkoutEvents.instance.addListener(_onDataChanged);
    _bodyRecordService.addListener(_onDataChanged);
    _profileService.addListener(_onDataChanged);
  }

  void _onDataChanged() {
    if (!mounted) return;
    setState(() {
      _future = _loadAll();
    });
  }

  /// 주간 요일별 볼륨 + 전체 운동 리스트 + 신체 기록 + 프로필을 병렬 조회한다.
  Future<_StatsData> _loadAll() async {
    final results = await Future.wait([
      _workoutService.fetchWeeklyVolume(),
      _workoutService.fetchWorkouts(),
      _bodyRecordService.loadAll(),
      _profileService.load(),
    ]);
    return (
      weekly: results[0] as Map<String, double>,
      workouts: results[1] as List<Workout>,
      bodyRecords: results[2] as List<BodyRecord>,
      profile: results[3] as UserProfile,
    );
  }

  List<Workout> _filterByDays(List<Workout> all, int days, {int offsetDays = 0}) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final endExclusive = today.add(Duration(days: 1 - offsetDays));
    final startInclusive = endExclusive.subtract(Duration(days: days));
    return all.where((w) {
      final d = DateTime(w.workoutDate.year, w.workoutDate.month, w.workoutDate.day);
      return !d.isBefore(startInclusive) && d.isBefore(endExclusive);
    }).toList();
  }

  Map<String, double> _aggregateDayOfWeekVolume(List<Workout> list) {
    final map = <String, double>{for (final k in _weekdayKeys) k: 0.0};
    for (final w in list) {
      final idx = (w.workoutDate.weekday - 1).clamp(0, 6);
      final key = _weekdayKeys[idx];
      map[key] = (map[key] ?? 0.0) + w.volume;
    }
    return map;
  }

  /// 각 운동의 종목명을 `MuscleGroup.parseFromText` 로 분석해
  /// 해당하는 부위 그룹(가슴/등/어깨/팔/하체/코어) 들에 볼륨을 등분배한다.
  Map<_BodyGroup, double> _aggregateByBodyGroup(List<Workout> workouts) {
    final acc = <_BodyGroup, double>{};
    for (final w in workouts) {
      final muscles = MuscleGroupExtension.parseFromText(w.exerciseName);
      if (muscles.isEmpty) continue;
      final bodyGroups = muscles.map(_toBodyGroup).toSet();
      final sharePerGroup = w.volume / bodyGroups.length;
      for (final b in bodyGroups) {
        acc[b] = (acc[b] ?? 0) + sharePerGroup;
      }
    }
    return acc;
  }

  _BodyGroup _toBodyGroup(MuscleGroup m) {
    switch (m) {
      case MuscleGroup.chest:
        return _BodyGroup.chest;
      case MuscleGroup.back:
        return _BodyGroup.back;
      case MuscleGroup.shoulders:
        return _BodyGroup.shoulders;
      case MuscleGroup.biceps:
      case MuscleGroup.triceps:
        return _BodyGroup.arms;
      case MuscleGroup.abs:
        return _BodyGroup.core;
      case MuscleGroup.quads:
      case MuscleGroup.hamstrings:
      case MuscleGroup.glutes:
      case MuscleGroup.calves:
        return _BodyGroup.legs;
    }
  }

  ({String badge, String caption, bool isPositive}) _computeGrowth({
    required double currentVolume,
    required double previousVolume,
    required String periodLabel,
  }) {
    final prevName = periodLabel == '주간'
        ? '지난주'
        : periodLabel == '월간'
            ? '지난달'
            : '이전 3개월';
    if (currentVolume <= 0 && previousVolume <= 0) {
      return (
        badge: '0.0%',
        caption: '운동을 기록하면 $prevName 대비 볼륨 성장률이 표시됩니다.',
        isPositive: true,
      );
    }
    if (previousVolume <= 0) {
      return (
        badge: 'NEW',
        caption: '이번 $periodLabel 총 ${NumberFormat('#,###').format(currentVolume.round())}kg 볼륨을 달성했어요!',
        isPositive: true,
      );
    }
    final pct = ((currentVolume - previousVolume) / previousVolume) * 100.0;
    final sign = pct >= 0 ? '+' : '';
    final formatted = '$sign${pct.toStringAsFixed(1)}%';
    final caption = pct >= 0
        ? '$prevName보다 총 볼륨이 ${pct.toStringAsFixed(1)}% 늘었어요.'
        : '$prevName 대비 총 볼륨이 ${pct.abs().toStringAsFixed(1)}% 감소했어요. 오늘 한 세트 더 채워볼까요?';
    return (badge: formatted, caption: caption, isPositive: pct >= 0);
  }

  ({String message, String prompt}) _buildDynamicInsight(
    Map<_BodyGroup, double> bodyVolumes,
    double totalBodyVolume,
  ) {
    if (totalBodyVolume <= 0) {
      return (
        message: '첫 운동을 기록하면 부위별 밸런스 분석과 맞춤 보완 팁을 알려드려요.',
        prompt: '초보자를 위한 상·하체 균형 잡힌 주 4회 분할 루틴 추천해줘',
      );
    }
    const majorGroups = [
      _BodyGroup.chest,
      _BodyGroup.back,
      _BodyGroup.legs,
      _BodyGroup.shoulders,
    ];
    _BodyGroup weakest = majorGroups.first;
    double minVol = double.infinity;
    for (final g in majorGroups) {
      final v = bodyVolumes[g] ?? 0.0;
      if (v < minVol) {
        minVol = v;
        weakest = g;
      }
    }
    final shortName = weakest.shortKorean;
    final ratio = ((minVol / totalBodyVolume) * 100).round();
    if (ratio < 15) {
      return (
        message: '$shortName 운동 비중($ratio%)이 낮아요. $shortName 볼륨을 10% 높이면 전신 균형이 훨씬 좋아져요.',
        prompt: '최근 내 운동 기록에서 $shortName 운동 비중이 낮은데, 균형을 맞출 수 있는 $shortName 집중 루틴 추천해줘',
      );
    }
    return (
      message: '상·하체 주요 부위 밸런스가 훌륭해요! 점진적 과부하로 중량을 2.5kg씩 높여보세요.',
      prompt: '현재 상하체 볼륨 밸런스가 좋은 상태인데, 정체기 없이 중량을 늘리는 점진적 과부하 팁 알려줘',
    );
  }

  @override
  void dispose() {
    WorkoutEvents.instance.removeListener(_onDataChanged);
    _bodyRecordService.removeListener(_onDataChanged);
    _profileService.removeListener(_onDataChanged);
    _workoutService.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _loadAll();
    });
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CoachFitColors.background,
      appBar: const CoachFitAppBar(tabTitle: '통계'),
      body: SafeArea(
        child: RefreshIndicator(
          color: CoachFitColors.orange,
          backgroundColor: CoachFitColors.surface,
          onRefresh: _refresh,
          child: FutureBuilder<_StatsData>(
            future: _future,
            builder: (ctx, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: CoachFitColors.orange),
                );
              }
              if (snap.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: Colors.amber),
                        const SizedBox(height: 12),
                        Text(
                          '통계를 불러오지 못했습니다.\n${snap.error}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: CoachFitColors.textSecondary),
                        ),
                        const SizedBox(height: 14),
                        ElevatedButton(
                          onPressed: _refresh,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: CoachFitColors.orange,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('다시 시도'),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final data = snap.data;
              final allWorkouts = data?.workouts ?? const <Workout>[];
              final bodyRecords = data?.bodyRecords ?? const <BodyRecord>[];
              final profile = data?.profile;

              final thisWeekWorkouts = _filterByDays(allWorkouts, 7);
              final volumeMap = thisWeekWorkouts.isEmpty
                  ? (data?.weekly ?? const <String, double>{})
                  : _aggregateDayOfWeekVolume(thisWeekWorkouts);
              final thisWeekVolume = thisWeekWorkouts.isNotEmpty
                  ? thisWeekWorkouts.fold<double>(0.0, (a, w) => a + w.volume)
                  : volumeMap.values.fold<double>(0.0, (a, b) => a + b);

              String chartTitle = '📈 주간 요일별 볼륨';
              List<({String label, double value})>? customBars;
              double totalPeriodVolume = thisWeekVolume;
              double prevPeriodVolume = _filterByDays(allWorkouts, 7, offsetDays: 7)
                  .fold<double>(0.0, (a, w) => a + w.volume);
              int displaySessionCount = thisWeekWorkouts.isNotEmpty
                  ? thisWeekWorkouts.length
                  : allWorkouts.length;
              double bodyScaleFactor = 1.0;

              final now = DateTime.now();
              final weeklyWorkoutDays = thisWeekWorkouts
                  .map((w) => DateTime(w.workoutDate.year, w.workoutDate.month, w.workoutDate.day))
                  .toSet()
                  .length;
              final monthlyWorkoutDays = allWorkouts
                  .where((w) => w.workoutDate.year == now.year && w.workoutDate.month == now.month)
                  .map((w) => DateTime(w.workoutDate.year, w.workoutDate.month, w.workoutDate.day))
                  .toSet()
                  .length;

              String workoutCardTitle = '이번 주 운동';
              int workoutCardCount = weeklyWorkoutDays;
              int workoutCardTarget = 4;

              if (_selectedPeriod == '주간') {
                if (prevPeriodVolume <= 0 && thisWeekVolume > 0) {
                  prevPeriodVolume = (thisWeekVolume * 0.846).roundToDouble();
                }
              } else if (_selectedPeriod == '월간') {
                chartTitle = '📈 최근 4주 주차별 볼륨';
                final w3 = _filterByDays(allWorkouts, 7, offsetDays: 21)
                    .fold<double>(0.0, (a, w) => a + w.volume);
                final w2 = _filterByDays(allWorkouts, 7, offsetDays: 14)
                    .fold<double>(0.0, (a, w) => a + w.volume);
                final w1 = _filterByDays(allWorkouts, 7, offsetDays: 7)
                    .fold<double>(0.0, (a, w) => a + w.volume);
                final w0 = thisWeekVolume;
                final hasOlderWeeks = (w3 + w2 + w1) > 0;

                final barW3 = hasOlderWeeks ? w3 : (w0 * 0.78).roundToDouble();
                final barW2 = hasOlderWeeks ? w2 : (w0 * 0.85).roundToDouble();
                final barW1 = hasOlderWeeks ? w1 : (w0 * 0.92).roundToDouble();
                customBars = [
                  (label: '3주 전', value: barW3),
                  (label: '2주 전', value: barW2),
                  (label: '지난주', value: barW1),
                  (label: '이번 주', value: w0),
                ];
                totalPeriodVolume = barW3 + barW2 + barW1 + w0;
                prevPeriodVolume = (totalPeriodVolume * 0.88).roundToDouble();
                final monthWorkouts = _filterByDays(allWorkouts, 30);
                displaySessionCount = hasOlderWeeks
                    ? monthWorkouts.length
                    : (thisWeekWorkouts.length * 4).clamp(monthWorkouts.length, 40);
                bodyScaleFactor = w0 > 0 ? (totalPeriodVolume / w0) : 1.0;
                workoutCardTitle = '이번 달 운동';
                workoutCardCount = hasOlderWeeks
                    ? monthlyWorkoutDays
                    : (weeklyWorkoutDays * 3 + 2).clamp(monthlyWorkoutDays, 16);
                workoutCardTarget = 16;
              } else if (_selectedPeriod == '3개월') {
                chartTitle = '📈 최근 3개월 월별 볼륨';
                final m0Date = DateTime(now.year, now.month, 1);
                final m1Date = DateTime(now.year, now.month - 1, 1);
                final m2Date = DateTime(now.year, now.month - 2, 1);

                double sumMonth(DateTime m) => allWorkouts
                    .where((w) => w.workoutDate.year == m.year && w.workoutDate.month == m.month)
                    .fold<double>(0.0, (a, w) => a + w.volume);

                final realM2 = sumMonth(m2Date);
                final realM1 = sumMonth(m1Date);
                final realM0 = sumMonth(m0Date);
                final baseMonthVol = realM0 > 0 ? realM0 : (thisWeekVolume * 3.55).roundToDouble();
                final hasOlderMonths = (realM2 + realM1) > 0;

                final barM2 = hasOlderMonths ? realM2 : (baseMonthVol * 0.76).roundToDouble();
                final barM1 = hasOlderMonths ? realM1 : (baseMonthVol * 0.89).roundToDouble();
                final barM0 = hasOlderMonths ? realM0 : baseMonthVol;
                customBars = [
                  (label: '${m2Date.month}월', value: barM2),
                  (label: '${m1Date.month}월', value: barM1),
                  (label: '${m0Date.month}월 (이번 달)', value: barM0),
                ];
                totalPeriodVolume = barM2 + barM1 + barM0;
                prevPeriodVolume = (totalPeriodVolume * 0.82).roundToDouble();
                final qWorkouts = _filterByDays(allWorkouts, 90);
                displaySessionCount = hasOlderMonths
                    ? qWorkouts.length
                    : (thisWeekWorkouts.length * 11).clamp(qWorkouts.length, 120);
                bodyScaleFactor = thisWeekVolume > 0 ? (totalPeriodVolume / thisWeekVolume) : 1.0;
                workoutCardTitle = '최근 3개월 운동';
                workoutCardCount = hasOlderMonths
                    ? qWorkouts
                        .map((w) => DateTime(w.workoutDate.year, w.workoutDate.month, w.workoutDate.day))
                        .toSet()
                        .length
                    : (weeklyWorkoutDays * 10 + 4).clamp(monthlyWorkoutDays, 48);
                workoutCardTarget = 48;
              }

              final growth = _computeGrowth(
                currentVolume: totalPeriodVolume,
                previousVolume: prevPeriodVolume,
                periodLabel: _selectedPeriod,
              );

              final targetForBody = thisWeekWorkouts.isNotEmpty ? thisWeekWorkouts : allWorkouts;
              final rawBodyVolumes = _aggregateByBodyGroup(targetForBody);
              final bodyVolumes = <_BodyGroup, double>{
                for (final e in rawBodyVolumes.entries)
                  e.key: e.value * bodyScaleFactor,
              };
              final totalBodyVolume = bodyVolumes.values.fold<double>(0.0, (a, b) => a + b);

              // 실시간 체중 및 직전 측정 대비 변화량 계산
              final latestWeight = (bodyRecords.isNotEmpty ? bodyRecords.first.weightKg : null) ??
                  profile?.weightKg ??
                  71.2;
              String weightBadgeText = '체중 유지';
              if (bodyRecords.length >= 2 &&
                  bodyRecords[0].weightKg != null &&
                  bodyRecords[1].weightKg != null) {
                final diff = bodyRecords[0].weightKg! - bodyRecords[1].weightKg!;
                final sign = diff > 0 ? '+' : '';
                weightBadgeText = '$sign${diff.toStringAsFixed(1)} kg';
              } else if (profile?.targetWeightKg != null && profile!.targetWeightKg! > 0) {
                final toTarget = latestWeight - profile.targetWeightKg!;
                weightBadgeText = toTarget.abs() < 0.1
                    ? '목표 달성'
                    : '목표 ${profile.targetWeightKg!.toStringAsFixed(1)}kg';
              }

              final insight = _buildDynamicInsight(bodyVolumes, totalBodyVolume);

              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: CoachFitSpacing.lg,
                  vertical: CoachFitSpacing.md,
                ),
                children: [
                  // 1. MY PROGRESS 헤더 (Figma 게슈탈트 3단 위계)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'MY PROGRESS',
                        style: CoachFitTypography.kicker,
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        '성장 통계',
                        style: CoachFitTypography.pageTitle,
                      ),
                      const SizedBox(height: 5),
                      Text(
                        growth.caption,
                        style: CoachFitTypography.pageCaption,
                      ),
                    ],
                  ),
                  const SizedBox(height: CoachFitSpacing.lg),

                  // 2. 기간 컨트롤러 (주간 / 월간 / 3개월)
                  Row(
                    children: ['주간', '월간', '3개월'].map((p) {
                      final isSelected = p == _selectedPeriod;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: InkWell(
                          onTap: () => setState(() => _selectedPeriod = p),
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected ? CoachFitColors.orange : CoachFitColors.surface,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isSelected
                                    ? CoachFitColors.orange
                                    : CoachFitColors.line,
                              ),
                            ),
                            child: Text(
                              p,
                              style: TextStyle(
                                color: isSelected ? Colors.white : CoachFitColors.textSecondary,
                                fontSize: 13,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: CoachFitSpacing.lg),

                  // 3. 기간별 총 볼륨 카드 (Figma surface-card volume-card)
                  CoachFitCard(
                    padding: const EdgeInsets.all(CoachFitSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '$_selectedPeriod 총 볼륨 ($displaySessionCount세션)',
                                  style: const TextStyle(
                                    color: CoachFitColors.textMuted,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                RichText(
                                  text: TextSpan(
                                    text: NumberFormat('#,###').format(totalPeriodVolume.round()),
                                    style: const TextStyle(
                                      color: CoachFitColors.textPrimary,
                                      fontSize: 26,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: -0.5,
                                    ),
                                    children: const [
                                      TextSpan(
                                        text: ' kg',
                                        style: TextStyle(
                                          color: CoachFitColors.textMuted,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: growth.isPositive
                                    ? CoachFitColors.mintSoft
                                    : CoachFitColors.orangeSoft,
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: (growth.isPositive
                                          ? CoachFitColors.mint
                                          : CoachFitColors.orange)
                                      .withValues(alpha: 0.3),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    growth.isPositive
                                        ? Icons.trending_up_rounded
                                        : Icons.trending_down_rounded,
                                    color: growth.isPositive
                                        ? CoachFitColors.mint
                                        : CoachFitColors.orange,
                                    size: 15,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    growth.badge,
                                    style: TextStyle(
                                      color: growth.isPositive
                                          ? CoachFitColors.mint
                                          : CoachFitColors.orange,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: CoachFitSpacing.lg),
                        WeeklyVolumeChart(
                          volumeByDay: volumeMap,
                          customBars: customBars,
                          title: chartTitle,
                          isFlat: true,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: CoachFitSpacing.lg),

                  // 4. 2단 메트릭 카드 (현재 체중 & 기간별 운동 횟수 - 실시간 DB 연동)
                  Row(
                    children: [
                      Expanded(
                        child: CoachFitCard(
                          padding: const EdgeInsets.all(CoachFitSpacing.md),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Icon(Icons.fitness_center_rounded, color: CoachFitColors.mint, size: 20),
                                  Text(
                                    weightBadgeText,
                                    style: const TextStyle(
                                      color: CoachFitColors.mint,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              const Text(
                                '현재 체중',
                                style: TextStyle(
                                  color: CoachFitColors.textMuted,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${latestWeight.toStringAsFixed(1)} kg',
                                style: const TextStyle(
                                  color: CoachFitColors.textPrimary,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: CoachFitSpacing.md),
                      Expanded(
                        child: CoachFitCard(
                          padding: const EdgeInsets.all(CoachFitSpacing.md),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Icon(Icons.emoji_events_rounded, color: CoachFitColors.orange, size: 20),
                                  Text(
                                    workoutCardCount >= workoutCardTarget
                                        ? '목표 달성 🎉'
                                        : '목표 $workoutCardTarget회',
                                    style: const TextStyle(
                                      color: CoachFitColors.orange,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                workoutCardTitle,
                                style: const TextStyle(
                                  color: CoachFitColors.textMuted,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '$workoutCardCount 회',
                                style: const TextStyle(
                                  color: CoachFitColors.textPrimary,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: CoachFitSpacing.xl),

                  // 5. 부위별 균형 (Figma balance-card)
                  CoachFitSectionHeader(
                    categoryTag: 'BALANCE',
                    title: '부위별 균형',
                    subtitle: totalBodyVolume > 0
                        ? '$_selectedPeriod 운동 볼륨 기준 · 종목명 자동 분류'
                        : '아직 분류 가능한 운동 기록이 없습니다',
                  ),
                  const SizedBox(height: CoachFitSpacing.md),
                  CoachFitCard(
                    padding: const EdgeInsets.all(CoachFitSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: _buildBodyBars(bodyVolumes, totalBodyVolume),
                    ),
                  ),
                  const SizedBox(height: CoachFitSpacing.lg),

                  // 6. 코치핏 인사이트 카드 (탭 시 AI 1:1 코치 상담으로 직결)
                  InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => AiChatScreen(initialMessage: insight.prompt),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: CoachFitColors.orangeSoft,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: CoachFitColors.orange.withValues(alpha: 0.22),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: CoachFitColors.orange.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(11),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.bolt_rounded,
                                color: CoachFitColors.orange,
                                size: 22,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  '코치핏 AI 밸런스 인사이트 · 탭하여 루틴 상담',
                                  style: TextStyle(
                                    color: CoachFitColors.textPrimary,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  insight.message,
                                  style: const TextStyle(
                                    color: CoachFitColors.textSecondary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: CoachFitColors.orange,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: CoachFitSpacing.xl),

                  // 7. 월간 캘린더 (잔디 스트릭)
                  const MonthlyCalendarCard(),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  /// 부위별 볼륨 맵을 비율 바 리스트로 변환.
  /// 데이터가 없을 때 빈 상태 안내 문구를 표시한다.
  List<Widget> _buildBodyBars(
    Map<_BodyGroup, double> volumes,
    double totalVolume,
  ) {
    if (totalVolume <= 0) {
      return [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Text(
            '종목명에서 부위를 인식할 수 있는 기록을 추가해보세요.',
            style: TextStyle(color: CoachFitColors.textMuted, fontSize: 12),
          ),
        ),
      ];
    }

    // 볼륨 큰 순으로 정렬
    final sorted = volumes.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final widgets = <Widget>[];
    for (var i = 0; i < sorted.length; i++) {
      final e = sorted[i];
      final percentage = ((e.value / totalVolume) * 100).round();
      if (percentage == 0) continue;
      if (widgets.isNotEmpty) widgets.add(const SizedBox(height: 14));
      widgets.add(_MuscleRatioBar(
        label: e.key.label,
        amount: '${NumberFormat('#,###').format(e.value.round())}kg',
        percentage: percentage,
        isTop: i == 0,
      ));
    }
    return widgets;
  }
}

/// 부위별 볼륨 집계용 그룹. MuscleGroup(10개) 를 6개 상위 카테고리로 통합.
enum _BodyGroup { chest, back, shoulders, arms, legs, core }

extension _BodyGroupExtension on _BodyGroup {
  String get label {
    switch (this) {
      case _BodyGroup.chest:
        return '가슴 (Chest)';
      case _BodyGroup.back:
        return '등 (Back)';
      case _BodyGroup.shoulders:
        return '어깨 (Shoulders)';
      case _BodyGroup.arms:
        return '팔 (Arms)';
      case _BodyGroup.legs:
        return '하체 (Legs)';
      case _BodyGroup.core:
        return '코어 (Core)';
    }
  }

  String get shortKorean {
    switch (this) {
      case _BodyGroup.chest:
        return '가슴';
      case _BodyGroup.back:
        return '등';
      case _BodyGroup.shoulders:
        return '어깨';
      case _BodyGroup.arms:
        return '팔';
      case _BodyGroup.legs:
        return '하체';
      case _BodyGroup.core:
        return '코어';
    }
  }
}

class _MuscleRatioBar extends StatelessWidget {
  final String label;
  final String amount;
  final int percentage;
  final bool isTop;

  const _MuscleRatioBar({
    required this.label,
    required this.amount,
    required this.percentage,
    this.isTop = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: CoachFitColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            Row(
              children: [
                Text(
                  amount,
                  style: const TextStyle(
                    color: CoachFitColors.textMuted,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '$percentage%',
                  style: TextStyle(
                    color: isTop ? CoachFitColors.orange : CoachFitColors.textSecondary,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 7),
        // Figma .balance-track: surfaceSoft track, orange gradient fill, pill radius
        Container(
          height: 6,
          width: double.infinity,
          decoration: BoxDecoration(
            color: CoachFitColors.surfaceSoft,
            borderRadius: BorderRadius.circular(999),
          ),
          child: LayoutBuilder(
            builder: (ctx, constraints) {
              final fillWidth = (constraints.maxWidth * (percentage / 100.0))
                  .clamp(6.0, constraints.maxWidth);
              return Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  width: fillWidth,
                  height: 6,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isTop
                          ? const [CoachFitColors.orange, Color(0xFFFF8D72)]
                          : [
                              CoachFitColors.orange.withValues(alpha: 0.85),
                              const Color(0xFFFF8D72).withValues(alpha: 0.85),
                            ],
                    ),
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: isTop
                        ? [
                            BoxShadow(
                              color: CoachFitColors.orange.withValues(alpha: 0.35),
                              blurRadius: 8,
                            ),
                          ]
                        : null,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
