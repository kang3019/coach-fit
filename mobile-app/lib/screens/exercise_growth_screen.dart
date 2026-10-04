import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/workout.dart';
import '../services/workout_service.dart';

/// 선택한 운동 종목의 과거 기록을 라인 차트로 시각화.
/// A 담당: 종목별 성장 그래프 (D).
///
/// X축: 날짜 (최근 기록 순)
/// Y축: 중량(kg) 토글 가능 — 볼륨(kg·reps·sets) 로 전환
class ExerciseGrowthScreen extends StatefulWidget {
  final String? initialExerciseName;
  const ExerciseGrowthScreen({super.key, this.initialExerciseName});

  @override
  State<ExerciseGrowthScreen> createState() => _ExerciseGrowthScreenState();
}

class _ExerciseGrowthScreenState extends State<ExerciseGrowthScreen> {
  final WorkoutService _service = WorkoutService();
  late Future<List<Workout>> _future;
  String? _selected;
  _Metric _metric = _Metric.weight;

  @override
  void initState() {
    super.initState();
    _future = _service.fetchWorkouts();
    _selected = widget.initialExerciseName;
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '종목별 성장 추이',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: FutureBuilder<List<Workout>>(
        future: _future,
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final all = snap.data ?? const <Workout>[];
          final names = _distinctExerciseNames(all);
          if (names.isEmpty) {
            return const Center(
              child: Text(
                '분석할 운동 기록이 없습니다',
                style: TextStyle(color: Colors.white54),
              ),
            );
          }
          final selected = _selected ?? names.first;
          final filtered = all
              .where((w) => w.exerciseName == selected)
              .toList()
            ..sort((a, b) => a.workoutDate.compareTo(b.workoutDate));

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _ExercisePicker(
                names: names,
                selected: selected,
                onChanged: (v) => setState(() => _selected = v),
              ),
              const SizedBox(height: 14),
              _MetricToggle(
                metric: _metric,
                onChanged: (m) => setState(() => _metric = m),
              ),
              const SizedBox(height: 16),
              _StatsRow(workouts: filtered, metric: _metric),
              const SizedBox(height: 16),
              _GrowthChartCard(workouts: filtered, metric: _metric),
            ],
          );
        },
      ),
    );
  }

  List<String> _distinctExerciseNames(List<Workout> all) {
    final set = <String>{};
    for (final w in all) {
      set.add(w.exerciseName);
    }
    return set.toList()..sort();
  }
}

enum _Metric { weight, volume }

extension _MetricExt on _Metric {
  String get label {
    switch (this) {
      case _Metric.weight:
        return '중량';
      case _Metric.volume:
        return '총 볼륨';
    }
  }

  String get unit {
    switch (this) {
      case _Metric.weight:
        return 'kg';
      case _Metric.volume:
        return 'kg';
    }
  }

  double valueOf(Workout w) {
    switch (this) {
      case _Metric.weight:
        return w.weight;
      case _Metric.volume:
        return w.volume;
    }
  }
}

class _ExercisePicker extends StatelessWidget {
  final List<String> names;
  final String selected;
  final ValueChanged<String> onChanged;
  const _ExercisePicker({
    required this.names,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: selected,
      items: names
          .map((n) => DropdownMenuItem(
                value: n,
                child: Text(n, style: const TextStyle(color: Colors.white)),
              ))
          .toList(),
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
      dropdownColor: const Color(0xFF171B22),
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: '운동 종목',
        filled: true,
        fillColor: const Color(0xFF171B22),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class _MetricToggle extends StatelessWidget {
  final _Metric metric;
  final ValueChanged<_Metric> onChanged;
  const _MetricToggle({required this.metric, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF00E5A0);
    return Row(
      children: _Metric.values.map((m) {
        final selected = m == metric;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: InkWell(
            onTap: () => onChanged(m),
            borderRadius: BorderRadius.circular(999),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: selected
                    ? accent.withValues(alpha: 0.2)
                    : Colors.white10,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: selected ? accent : Colors.transparent,
                  width: 1.3,
                ),
              ),
              child: Text(
                m.label,
                style: TextStyle(
                  color: selected ? accent : Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final List<Workout> workouts;
  final _Metric metric;
  const _StatsRow({required this.workouts, required this.metric});

  @override
  Widget build(BuildContext context) {
    if (workouts.isEmpty) {
      return const SizedBox.shrink();
    }
    final values = workouts.map(metric.valueOf).toList();
    final max = values.reduce((a, b) => a > b ? a : b);
    final min = values.reduce((a, b) => a < b ? a : b);
    final first = values.first;
    final last = values.last;
    final gain = last - first;
    final gainPercent = first > 0 ? (gain / first) * 100 : 0;

    return Row(
      children: [
        Expanded(
          child: _StatBox(
            label: '최고',
            value: NumberFormat('#,###').format(max.round()),
            suffix: metric.unit,
            color: const Color(0xFFF59E0B),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatBox(
            label: '최저',
            value: NumberFormat('#,###').format(min.round()),
            suffix: metric.unit,
            color: const Color(0xFF60A5FA),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatBox(
            label: '성장률',
            value:
                '${gainPercent >= 0 ? '+' : ''}${gainPercent.toStringAsFixed(0)}',
            suffix: '%',
            color: gainPercent >= 0
                ? const Color(0xFF00E5A0)
                : const Color(0xFFEF4444),
          ),
        ),
      ],
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final String suffix;
  final Color color;
  const _StatBox({
    required this.label,
    required this.value,
    required this.suffix,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF171B22),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white54, fontSize: 11),
          ),
          const SizedBox(height: 4),
          RichText(
            text: TextSpan(
              text: value,
              style: TextStyle(
                color: color,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
              children: [
                TextSpan(
                  text: ' $suffix',
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GrowthChartCard extends StatelessWidget {
  final List<Workout> workouts;
  final _Metric metric;
  const _GrowthChartCard({required this.workouts, required this.metric});

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF00E5A0);
    if (workouts.length < 2) {
      return Container(
        height: 240,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF171B22),
          borderRadius: BorderRadius.circular(14),
        ),
        alignment: Alignment.center,
        child: const Text(
          '그래프를 그리려면 최소 2회 이상의 기록이 필요해요',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white54, fontSize: 12),
        ),
      );
    }

    final spots = <FlSpot>[];
    for (var i = 0; i < workouts.length; i++) {
      spots.add(FlSpot(i.toDouble(), metric.valueOf(workouts[i])));
    }
    final yValues = spots.map((s) => s.y).toList();
    final minY = yValues.reduce((a, b) => a < b ? a : b);
    final maxY = yValues.reduce((a, b) => a > b ? a : b);
    final pad = ((maxY - minY) * 0.15).clamp(1.0, 1000.0);

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 14, 14, 10),
      decoration: BoxDecoration(
        color: const Color(0xFF171B22),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 6),
            child: Text(
              '${metric.label} 추이',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          SizedBox(
            height: 220,
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: (workouts.length - 1).toDouble(),
                minY: (minY - pad).clamp(0.0, double.infinity),
                maxY: maxY + pad,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) =>
                      const FlLine(color: Colors.white10, strokeWidth: 1),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 36,
                      getTitlesWidget: (v, _) => Text(
                        '${v.round()}',
                        style:
                            const TextStyle(color: Colors.white38, fontSize: 10),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      interval:
                          (workouts.length / 5).ceil().toDouble().clamp(1, 999),
                      getTitlesWidget: (v, _) {
                        final idx = v.toInt();
                        if (idx < 0 || idx >= workouts.length) {
                          return const SizedBox.shrink();
                        }
                        final d = workouts[idx].workoutDate;
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            DateFormat('M/d').format(d),
                            style: const TextStyle(
                                color: Colors.white54, fontSize: 10),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => const Color(0xFF0E1116),
                    getTooltipItems: (spots) => spots.map((s) {
                      final w = workouts[s.x.toInt()];
                      final date =
                          DateFormat('yyyy-MM-dd').format(w.workoutDate);
                      return LineTooltipItem(
                        '$date\n${metric.valueOf(w).toStringAsFixed(1)} ${metric.unit}',
                        const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      );
                    }).toList(),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: accent,
                    barWidth: 2.5,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(
                        radius: 3,
                        color: accent,
                        strokeWidth: 0,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          accent.withValues(alpha: 0.25),
                          accent.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
