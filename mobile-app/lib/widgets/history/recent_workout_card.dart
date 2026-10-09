import 'package:flutter/material.dart';
import '../../models/workout.dart';
import '../../theme/coachfit_theme.dart';
import '../common/coachfit_card.dart';
import '../common/section_header.dart';

/// 기록 탭의 최근 운동 상세 카드 (나의 기록.png 디자인)
/// - 루틴 헤더, 종목별 무게/세트/완료체크 리스트, [이 루틴 다시 시작] 버튼
class RecentWorkoutCard extends StatelessWidget {
  final List<Workout> workouts;
  final String dateSubtitle;
  final VoidCallback onEdit;
  final VoidCallback onRestartRoutine;
  final void Function(Workout workout)? onDeleteWorkout;

  const RecentWorkoutCard({
    super.key,
    required this.workouts,
    required this.dateSubtitle,
    required this.onEdit,
    required this.onRestartRoutine,
    this.onDeleteWorkout,
  });

  @override
  Widget build(BuildContext context) {
    if (workouts.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CoachFitSectionHeader(
            title: '최근 운동',
            subtitle: dateSubtitle,
          ),
          const SizedBox(height: CoachFitSpacing.md),
          CoachFitCard(
            padding: const EdgeInsets.all(CoachFitSpacing.xl),
            child: const Center(
              child: Column(
                children: [
                  Icon(
                    Icons.fitness_center_rounded,
                    color: CoachFitColors.textMuted,
                    size: 36,
                  ),
                  SizedBox(height: CoachFitSpacing.md),
                  Text(
                    '이 날짜에 기록된 운동이 없습니다.',
                    style: TextStyle(
                      color: CoachFitColors.textSecondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '우측 하단의 + 버튼을 눌러 운동을 기록해 보세요.',
                    style: TextStyle(
                      color: CoachFitColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    // 종목별로 그룹화
    final grouped = <String, List<Workout>>{};
    for (final w in workouts) {
      grouped.putIfAbsent(w.exerciseName, () => []).add(w);
    }

    final routineTitle = workouts.first.memo?.contains('루틴') == true
        ? workouts.first.memo!.split('-').first.replaceAll(RegExp(r'[\[\]]'), '').trim()
        : '맞춤 운동 루틴';

    final totalSets = workouts.length;
    final estMinutes = (totalSets * 3.5 + 10).toInt();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CoachFitSectionHeader(
          title: '최근 운동',
          subtitle: dateSubtitle,
          trailing: InkWell(
            onTap: onEdit,
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '편집',
                  style: TextStyle(
                    color: CoachFitColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(width: 2),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 16,
                  color: CoachFitColors.textSecondary,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: CoachFitSpacing.md),
        CoachFitCard(
          padding: const EdgeInsets.all(CoachFitSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. 루틴 타이틀 바
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFF281C1B),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: CoachFitColors.orange.withValues(alpha: 0.25),
                      ),
                    ),
                    child: const Icon(
                      Icons.fitness_center_rounded,
                      color: CoachFitColors.orange,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          routineTitle,
                          style: const TextStyle(
                            color: CoachFitColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '총 $totalSets세트 · 약 $estMinutes분',
                          style: const TextStyle(
                            color: CoachFitColors.textMuted,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.more_horiz_rounded,
                      color: CoachFitColors.textMuted,
                    ),
                    onPressed: onEdit,
                  ),
                ],
              ),
              const SizedBox(height: CoachFitSpacing.lg),
              const Divider(color: CoachFitColors.divider, height: 1),
              const SizedBox(height: CoachFitSpacing.sm),

              // 2. 운동 종목 목록
              ...grouped.entries.map((entry) {
                final name = entry.key;
                final items = entry.value;
                final setsCount = items.length;
                final repsText = '${items.first.reps}회';
                final maxWeight = items.fold<double>(
                  0.0,
                  (max, item) => item.weight > max ? item.weight : max,
                );

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: CoachFitSpacing.md),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              name,
                              style: const TextStyle(
                                color: CoachFitColors.textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Text(
                            maxWeight > 0 ? '${maxWeight.toInt()}kg' : '맨몸',
                            style: const TextStyle(
                              color: CoachFitColors.orange,
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '$setsCount세트 × $repsText',
                            style: const TextStyle(
                              color: CoachFitColors.textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            width: 22,
                            height: 22,
                            decoration: const BoxDecoration(
                              color: CoachFitColors.mint,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check_rounded,
                              color: Color(0xFF0E1116),
                              size: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(color: CoachFitColors.divider, height: 1),
                  ],
                );
              }),

              const SizedBox(height: CoachFitSpacing.md),

              // 3. [▶ 이 루틴 다시 시작] 버튼
              Container(
                width: double.infinity,
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(CoachFitRadius.small),
                  border: Border.all(
                    color: CoachFitColors.orange.withValues(alpha: 0.35),
                  ),
                  color: CoachFitColors.orange.withValues(alpha: 0.08),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(CoachFitRadius.small),
                    onTap: onRestartRoutine,
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.play_arrow_rounded,
                          color: CoachFitColors.orange,
                          size: 20,
                        ),
                        SizedBox(width: 6),
                        Text(
                          '이 루틴 다시 시작',
                          style: TextStyle(
                            color: CoachFitColors.orange,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
