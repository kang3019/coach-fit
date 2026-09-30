import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// 요일별 누적 운동 볼륨(무게×세트×횟수) 막대그래프.
/// Java `/api/workouts/weekly-stats` 응답의 `weeklyVolumeByDay` 맵을 그대로 받는다.
///
/// 서버는 데이터가 있는 요일만 반환하므로, 없는 요일은 0으로 채워 항상 7일 표시.
class WeeklyVolumeChart extends StatelessWidget {
  final Map<String, double> volumeByDay;
  const WeeklyVolumeChart({super.key, required this.volumeByDay});

  static const List<String> _dayOrder = [
    'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN',
  ];
  static const List<String> _dayLabel = ['월', '화', '수', '목', '금', '토', '일'];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final values = _dayOrder.map((d) => volumeByDay[d] ?? 0.0).toList();
    final maxValue = values.fold<double>(0, (a, b) => a > b ? a : b);
    final total = values.fold<double>(0, (a, b) => a + b);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      decoration: BoxDecoration(
        color: const Color(0xFF171B22),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                '📈 주간 볼륨',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              RichText(
                text: TextSpan(
                  text: NumberFormat('#,###').format(total.round()),
                  style: TextStyle(
                    color: scheme.primary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                  children: const [
                    TextSpan(
                      text: ' kg',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 160,
            child: maxValue == 0
                ? _EmptyChart()
                : BarChart(
                    BarChartData(
                      maxY: _niceMax(maxValue),
                      alignment: BarChartAlignment.spaceAround,
                      barTouchData: BarTouchData(
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipColor: (_) => const Color(0xFF0E1116),
                          tooltipRoundedRadius: 8,
                          getTooltipItem: (group, _, rod, __) {
                            return BarTooltipItem(
                              '${_dayLabel[group.x]} · ${NumberFormat('#,###').format(rod.toY.round())}kg',
                              const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            );
                          },
                        ),
                      ),
                      titlesData: FlTitlesData(
                        leftTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 22,
                            getTitlesWidget: (v, _) {
                              final i = v.toInt();
                              if (i < 0 || i >= _dayLabel.length) {
                                return const SizedBox.shrink();
                              }
                              final isWeekend = i == 5 || i == 6;
                              return Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  _dayLabel[i],
                                  style: TextStyle(
                                    color: isWeekend
                                        ? Colors.white38
                                        : Colors.white70,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      gridData: const FlGridData(show: false),
                      borderData: FlBorderData(show: false),
                      barGroups: List.generate(7, (i) {
                        return BarChartGroupData(
                          x: i,
                          barRods: [
                            BarChartRodData(
                              toY: values[i],
                              width: 16,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(6),
                                topRight: Radius.circular(6),
                              ),
                              color: values[i] == 0
                                  ? Colors.white10
                                  : scheme.primary,
                            ),
                          ],
                        );
                      }),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  /// 축 상한을 사람이 읽기 좋은 수(500/1000/2000/…)로 반올림.
  double _niceMax(double value) {
    if (value <= 500) return 500;
    if (value <= 1000) return 1000;
    if (value <= 2000) return 2000;
    if (value <= 5000) return 5000;
    return (value / 1000).ceil() * 1000.0;
  }
}

class _EmptyChart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        '이번 주 기록이 없어요',
        style: TextStyle(color: Colors.white38, fontSize: 12),
      ),
    );
  }
}
