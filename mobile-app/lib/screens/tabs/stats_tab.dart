import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/workout.dart';
import '../../services/workout_service.dart';
import '../widgets/muscle_map_widget.dart';
import '../widgets/weekly_volume_chart.dart';

/// 요일별 볼륨 맵 + 부위별 집계 결과 묶음.
typedef _StatsData = ({
  Map<String, double> weekly,
  Map<_BodyGroup, double> byBody,
});

/// 3. 통계 탭 (Statistics Tab)
/// - 주간 누적 볼륨 바 차트 (fl_chart)
/// - 운동 부위별 비율 분석 (가슴, 등, 하체 등)
/// - 주간 목표 달성 게이지
class StatsTab extends StatefulWidget {
  const StatsTab({super.key});

  @override
  State<StatsTab> createState() => _StatsTabState();
}

class _StatsTabState extends State<StatsTab> {
  final WorkoutService _workoutService = WorkoutService();
  late Future<_StatsData> _future;

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
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '운동 통계 & 볼륨 분석',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<_StatsData>(
          future: _future,
          builder: (ctx, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
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
                        style: const TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 14),
                      ElevatedButton(onPressed: _refresh, child: const Text('다시 시도')),
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
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              children: [
                // 1. 이번 주 요약 대시보드 타일
                Row(
                  children: [
                    Expanded(
                      child: _StatsSummaryCard(
                        title: '이번 주 총 볼륨',
                        value: NumberFormat('#,###').format(totalWeeklyVolume.round()),
                        suffix: 'kg',
                        color: scheme.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: _StatsSummaryCard(
                        title: '운동 세션',
                        value: '4',
                        suffix: '회',
                        color: Color(0xFF60A5FA),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 2. 주간 볼륨 차트 카드
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.bar_chart_rounded, color: Color(0xFF00E5A0), size: 20),
                            SizedBox(width: 8),
                            Text(
                              '요일별 총 볼륨 (Weight × Sets × Reps)',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        WeeklyVolumeChart(volumeByDay: volumeMap),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 3. 주간 운동 목표 달성 게이지
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              '주간 목표 달성률',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                            ),
                            Text(
                              '75% 달성 (3 / 4회)',
                              style: TextStyle(color: scheme.primary, fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: LinearProgressIndicator(
                            value: 0.75,
                            minHeight: 10,
                            backgroundColor: Colors.white10,
                            valueColor: AlwaysStoppedAnimation(scheme.primary),
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          '목표까지 단 1회 남았습니다! 이번 주도 꾸준히 달리고 있어요 💪',
                          style: TextStyle(color: Colors.white54, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 4. 부위별 볼륨 비율 분석 (A 담당: WBS 2.2.4 — 실데이터 집계)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '부위별 볼륨 배분 비율',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          totalBodyVolume > 0
                              ? '전체 운동 기록 기준 · 종목명 자동 분류'
                              : '아직 분류 가능한 운동 기록이 없습니다',
                          style: const TextStyle(color: Colors.white38, fontSize: 11),
                        ),
                        const SizedBox(height: 14),
                        ..._buildBodyBars(bodyVolumes, totalBodyVolume),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
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
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Text(
            '종목명에서 부위를 인식할 수 있는 기록을 추가해보세요.',
            style: const TextStyle(color: Colors.white54, fontSize: 12),
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
      if (widgets.isNotEmpty) widgets.add(const SizedBox(height: 10));
      widgets.add(_MuscleRatioBar(
        label: e.key.label,
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

class _StatsSummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final String suffix;
  final Color color;

  const _StatsSummaryCard({
    required this.title,
    required this.value,
    required this.suffix,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF171B22),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.white54, fontSize: 12)),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 4),
              Text(suffix, style: const TextStyle(color: Colors.white54, fontSize: 13)),
            ],
          ),
        ],
      ),
    );
  }
}

class _MuscleRatioBar extends StatelessWidget {
  final String label;
  final int percentage;
  final Color color;

  const _MuscleRatioBar({
    required this.label,
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
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13)),
            Text('$percentage%', style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 13)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: percentage / 100.0,
            minHeight: 6,
            backgroundColor: Colors.white10,
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      ],
    );
  }
}
