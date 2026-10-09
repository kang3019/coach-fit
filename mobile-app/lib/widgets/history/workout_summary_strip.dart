import 'package:flutter/material.dart';
import '../../theme/coachfit_theme.dart';
import '../common/coachfit_card.dart';

/// 오늘의 운동 요약 3분할 스트립 카드 (나의 기록.png 디자인)
/// - 총 볼륨 / 운동 시간 / 소모 열량
class WorkoutSummaryStrip extends StatelessWidget {
  final double totalVolumeKg;
  final int durationMinutes;
  final int caloriesKcal;

  const WorkoutSummaryStrip({
    super.key,
    required this.totalVolumeKg,
    required this.durationMinutes,
    required this.caloriesKcal,
  });

  factory WorkoutSummaryStrip.fromWorkouts({
    Key? key,
    required List<dynamic> workouts,
  }) {
    if (workouts.isEmpty) {
      return WorkoutSummaryStrip(
        key: key,
        totalVolumeKg: 0,
        durationMinutes: 0,
        caloriesKcal: 0,
      );
    }
    double volume = 0;
    for (final w in workouts) {
      volume += (w.volume as num).toDouble();
    }
    final setsCount = workouts.length;
    final minutes = setsCount > 0 ? (setsCount * 3 + 10).clamp(10, 180) : 0;
    final calories = (volume * 0.04 + minutes * 5.5).round();

    return WorkoutSummaryStrip(
      key: key,
      totalVolumeKg: volume,
      durationMinutes: minutes,
      caloriesKcal: calories,
    );
  }

  @override
  Widget build(BuildContext context) {
    final volumeText = totalVolumeKg >= 1000
        ? '${(totalVolumeKg / 1000).toStringAsFixed(1)}t'
        : '${totalVolumeKg.toInt()} kg';

    return CoachFitCard(
      padding: const EdgeInsets.symmetric(
        horizontal: CoachFitSpacing.md,
        vertical: CoachFitSpacing.lg,
      ),
      child: Row(
        children: [
          // 1. 총 볼륨
          Expanded(
            child: _buildItem(
              icon: Icons.fitness_center_rounded,
              label: '총 볼륨',
              value: totalVolumeKg > 0 ? volumeText : '0 kg',
            ),
          ),
          Container(
            width: 1,
            height: 36,
            color: CoachFitColors.divider,
            margin: const EdgeInsets.symmetric(horizontal: 4),
          ),

          // 2. 운동 시간
          Expanded(
            child: _buildItem(
              icon: Icons.access_time_rounded,
              label: '운동 시간',
              value: durationMinutes > 0 ? '$durationMinutes분' : '0분',
            ),
          ),
          Container(
            width: 1,
            height: 36,
            color: CoachFitColors.divider,
            margin: const EdgeInsets.symmetric(horizontal: 4),
          ),

          // 3. 소모 열량
          Expanded(
            child: _buildItem(
              icon: Icons.local_fire_department_rounded,
              label: '소모 열량',
              value: caloriesKcal > 0 ? '$caloriesKcal kcal' : '0 kcal',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: CoachFitColors.orange, size: 20),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: CoachFitColors.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(
                color: CoachFitColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
