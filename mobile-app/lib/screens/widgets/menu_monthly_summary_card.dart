import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../services/workout_service.dart';

/// (D) 메뉴 상단에 보여줄 이번 달 운동 요약 미니 카드.
/// 운동 횟수 / 총 볼륨 / 가장 많이 한 종목 top 1.
class MenuMonthlySummaryCard extends StatefulWidget {
  const MenuMonthlySummaryCard({super.key});

  @override
  State<MenuMonthlySummaryCard> createState() =>
      _MenuMonthlySummaryCardState();
}

class _MenuMonthlySummaryCardState extends State<MenuMonthlySummaryCard> {
  final WorkoutService _service = WorkoutService();
  bool _loading = true;
  int _sessions = 0;
  double _volume = 0;
  String? _topExercise;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final all = await _service.fetchWorkouts();
      final now = DateTime.now();
      final current = all.where((w) =>
          w.workoutDate.year == now.year &&
          w.workoutDate.month == now.month);
      final sessionDates = current
          .map((w) => DateTime(
              w.workoutDate.year, w.workoutDate.month, w.workoutDate.day))
          .toSet();
      double totalVolume = 0;
      final freq = <String, int>{};
      for (final w in current) {
        totalVolume += w.volume;
        freq[w.exerciseName] = (freq[w.exerciseName] ?? 0) + 1;
      }
      String? top;
      if (freq.isNotEmpty) {
        top = (freq.entries.toList()
              ..sort((a, b) => b.value.compareTo(a.value)))
            .first
            .key;
      }
      if (!mounted) return;
      setState(() {
        _sessions = sessionDates.length;
        _volume = totalVolume;
        _topExercise = top;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final month = DateTime.now().month;
    final fmt = NumberFormat('#,###');
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent.withValues(alpha: 0.15),
            accent.withValues(alpha: 0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.25)),
      ),
      child: _loading
          ? const SizedBox(
              height: 70,
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.calendar_month,
                        size: 16, color: accent),
                    const SizedBox(width: 6),
                    Text(
                      '$month월 요약',
                      style: TextStyle(
                        color: accent,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _StatBox(
                      label: '운동 횟수',
                      value: '$_sessions',
                      suffix: '일',
                    ),
                    const SizedBox(width: 8),
                    _StatBox(
                      label: '총 볼륨',
                      value: fmt.format(_volume.toInt()),
                      suffix: 'kg',
                    ),
                  ],
                ),
                if (_topExercise != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.local_fire_department,
                            size: 14, color: Color(0xFFF59E0B)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            '최다 수행: $_topExercise',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final String suffix;
  const _StatBox({
    required this.label,
    required this.value,
    required this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFF171B22),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(color: Colors.white54, fontSize: 10)),
            const SizedBox(height: 4),
            RichText(
              text: TextSpan(
                text: value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
                children: [
                  TextSpan(
                    text: ' $suffix',
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
