import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/workout_service.dart';
import '../widgets/weekly_volume_chart.dart';

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
  late Future<Map<String, double>> _weeklyStatsFuture;

  @override
  void initState() {
    super.initState();
    _weeklyStatsFuture = _workoutService.fetchWeeklyVolume();
  }

  @override
  void dispose() {
    _workoutService.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    setState(() {
      _weeklyStatsFuture = _workoutService.fetchWeeklyVolume();
    });
    await _weeklyStatsFuture;
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
        child: FutureBuilder<Map<String, double>>(
          future: _weeklyStatsFuture,
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

            final volumeMap = snap.data ?? {};
            final totalWeeklyVolume = volumeMap.values.fold<double>(0.0, (a, b) => a + b);

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

                // 4. 부위별 볼륨 비율 분석
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
                        const SizedBox(height: 14),
                        _MuscleRatioBar(label: '가슴 (Chest)', percentage: 42, color: const Color(0xFF00E5A0)),
                        const SizedBox(height: 10),
                        _MuscleRatioBar(label: '등 (Back)', percentage: 28, color: const Color(0xFF60A5FA)),
                        const SizedBox(height: 10),
                        _MuscleRatioBar(label: '하체 (Legs)', percentage: 30, color: const Color(0xFFF59E0B)),
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
