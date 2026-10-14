import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/workout.dart';
import '../../services/workout_service.dart';
import '../../theme/coachfit_theme.dart';
import '../../widgets/common/coachfit_card.dart';
import '../../widgets/common/section_header.dart';
import '../widgets/monthly_calendar_card.dart';
import '../widgets/muscle_map_widget.dart';
import '../widgets/weekly_volume_chart.dart';

/// 요일별 볼륨 맵 + 부위별 집계 결과 묶음.
typedef _StatsData = ({
  Map<String, double> weekly,
  Map<_BodyGroup, double> byBody,
});

/// 3. 통계 탭 (Statistics Tab)
/// - 피그마 게슈탈트 시각 위계 기반 성장 통계 UI
/// - 주간 누적 볼륨 바 차트 (fl_chart)
/// - 운동 부위별 비율 분석 (가슴, 등, 하체 등)
/// - 코치핏 인사이트 카드 및 월간 잔디 스트릭
class StatsTab extends StatefulWidget {
  const StatsTab({super.key});

  @override
  State<StatsTab> createState() => _StatsTabState();
}

class _StatsTabState extends State<StatsTab> {
  final WorkoutService _workoutService = WorkoutService();
  late Future<_StatsData> _future;
  String _selectedPeriod = '주간';

  @override
  void initState() {
    super.initState();
    _future = _loadAll();
  }

  /// 주간 요일별 볼륨 + 전체 운동 리스트를 병렬로 받고
  /// 운동 종목명에서 부위를 추출해 볼륨을 집계한다.
  Future<_StatsData> _loadAll() async {
    final results = await Future.wait([
      _workoutService.fetchWeeklyVolume(),
      _workoutService.fetchWorkouts(),
    ]);
    final weekly = results[0] as Map<String, double>;
    final workouts = results[1] as List<Workout>;
    return (weekly: weekly, byBody: _aggregateByBodyGroup(workouts));
  }

  /// 각 운동의 종목명을 `MuscleGroup.parseFromText` 로 분석해
  /// 해당하는 부위 그룹(가슴/등/어깨/팔/하체/코어) 들에 볼륨을 등분배한다.
  /// 예: "데드리프트" → {back, hamstrings, glutes} → 각 1/3 씩.
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

  @override
  void dispose() {
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
              final volumeMap = data?.weekly ?? const <String, double>{};
              final totalWeeklyVolume = volumeMap.values.fold<double>(0.0, (a, b) => a + b);
              final bodyVolumes = data?.byBody ?? const <_BodyGroup, double>{};
              final totalBodyVolume = bodyVolumes.values.fold<double>(0.0, (a, b) => a + b);

              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: CoachFitSpacing.lg,
                  vertical: CoachFitSpacing.md,
                ),
                children: [
                  // 1. MY PROGRESS 헤더 (Figma 게슈탈트 3단 위계)
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'MY PROGRESS',
                        style: TextStyle(
                          color: CoachFitColors.textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '성장 통계',
                        style: TextStyle(
                          color: CoachFitColors.textPrimary,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.6,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        '지난주보다 총 볼륨이 18.2% 늘었어요.',
                        style: TextStyle(
                          color: CoachFitColors.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
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
                              color: isSelected ? CoachFitColors.orange : const Color(0xFF171B22),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isSelected
                                    ? CoachFitColors.orange
                                    : Colors.white.withValues(alpha: 0.08),
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

                  // 3. 주간 총 볼륨 카드 (Figma surface-card volume-card)
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
                                const Text(
                                  '주간 총 볼륨',
                                  style: TextStyle(
                                    color: CoachFitColors.textMuted,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                RichText(
                                  text: TextSpan(
                                    text: NumberFormat('#,###').format(totalWeeklyVolume.round()),
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
                                color: CoachFitColors.mint.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: CoachFitColors.mint.withValues(alpha: 0.3),
                                ),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.trending_up_rounded, color: CoachFitColors.mint, size: 16),
                                  SizedBox(width: 4),
                                  Text(
                                    '+18.2%',
                                    style: TextStyle(
                                      color: CoachFitColors.mint,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: CoachFitSpacing.lg),
                        WeeklyVolumeChart(volumeByDay: volumeMap, isFlat: true),
                      ],
                    ),
                  ),
                  const SizedBox(height: CoachFitSpacing.lg),

                  // 4. 2단 메트릭 카드 (현재 체중 & 이번 달 운동)
                  const Row(
                    children: [
                      Expanded(
                        child: CoachFitCard(
                          padding: EdgeInsets.all(CoachFitSpacing.md),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Icon(Icons.fitness_center_rounded, color: CoachFitColors.mint, size: 20),
                                  Text(
                                    '-0.8 kg',
                                    style: TextStyle(
                                      color: CoachFitColors.mint,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 10),
                              Text(
                                '현재 체중',
                                style: TextStyle(
                                  color: CoachFitColors.textMuted,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                '71.2 kg',
                                style: TextStyle(
                                  color: CoachFitColors.textPrimary,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(width: CoachFitSpacing.md),
                      Expanded(
                        child: CoachFitCard(
                          padding: EdgeInsets.all(CoachFitSpacing.md),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Icon(Icons.emoji_events_rounded, color: CoachFitColors.orange, size: 20),
                                  Text(
                                    '목표 16회',
                                    style: TextStyle(
                                      color: CoachFitColors.orange,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 10),
                              Text(
                                '이번 달 운동',
                                style: TextStyle(
                                  color: CoachFitColors.textMuted,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                '14 회',
                                style: TextStyle(
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
                        ? '전체 운동 기록 기준 · 종목명 자동 분류'
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

                  // 6. 코치핏 인사이트 카드 (Figma insight-card)
                  CoachFitCard(
                    padding: const EdgeInsets.all(CoachFitSpacing.md),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: CoachFitColors.orange.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.bolt_rounded,
                            color: CoachFitColors.orange,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '코치핏 인사이트',
                                style: TextStyle(
                                  color: CoachFitColors.textPrimary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                '등 운동 비중을 10% 높이면 상체 균형이 더 좋아져요.',
                                style: TextStyle(
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
                          color: CoachFitColors.textMuted,
                          size: 18,
                        ),
                      ],
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
      if (widgets.isNotEmpty) widgets.add(const SizedBox(height: 12));
      widgets.add(_MuscleRatioBar(
        label: e.key.label,
        amount: '${NumberFormat('#,###').format(e.value.round())}kg',
        percentage: percentage,
        color: e.key.color,
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

  Color get color {
    switch (this) {
      case _BodyGroup.chest:
        return const Color(0xFF00E5A0);
      case _BodyGroup.back:
        return const Color(0xFF60A5FA);
      case _BodyGroup.shoulders:
        return const Color(0xFFF59E0B);
      case _BodyGroup.arms:
        return const Color(0xFFEF4444);
      case _BodyGroup.legs:
        return const Color(0xFFA855F7);
      case _BodyGroup.core:
        return const Color(0xFFEC4899);
    }
  }
}


class _MuscleRatioBar extends StatelessWidget {
  final String label;
  final String amount;
  final int percentage;
  final Color color;

  const _MuscleRatioBar({
    required this.label,
    required this.amount,
    required this.percentage,
    required this.color,
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
                fontWeight: FontWeight.w600,
              ),
            ),
            Row(
              children: [
                Text(
                  amount,
                  style: const TextStyle(
                    color: CoachFitColors.textSecondary,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '$percentage%',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percentage / 100.0,
            minHeight: 7,
            backgroundColor: Colors.white.withValues(alpha: 0.08),
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      ],
    );
  }
}
