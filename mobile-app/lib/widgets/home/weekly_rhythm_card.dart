import 'package:flutter/material.dart';
import '../../theme/coachfit_theme.dart';
import '../common/coachfit_card.dart';

/// 이번 주 리듬 요약 카드 (Gestalt 연속성 및 피드백)
/// - 월~일 주간 운동 완료 상태 및 오늘 표시
class WeeklyRhythmCard extends StatelessWidget {
  final List<bool> completedDays; // 월(0) ~ 일(6)
  final int todayIndex;           // 0: 월, 6: 일
  final int remainingWorkouts;
  final VoidCallback onTapStats;

  const WeeklyRhythmCard({
    super.key,
    this.completedDays = const [true, false, true, false, true, false, false],
    this.todayIndex = 5, // 기본 토요일
    this.remainingWorkouts = 1,
    required this.onTapStats,
  });

  static const List<String> _dayLabels = ['월', '화', '수', '목', '금', '토', '일'];

  @override
  Widget build(BuildContext context) {
    return CoachFitCard(
      padding: const EdgeInsets.all(CoachFitSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. 헤더 (타이틀, 통계 보기 링크)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '이번 주 리듬',
                style: TextStyle(
                  color: CoachFitColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
              InkWell(
                onTap: onTapStats,
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '통계 보기',
                      style: TextStyle(
                        color: CoachFitColors.textSecondary,
                        fontSize: 12,
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
            ],
          ),
          const SizedBox(height: 3),
          Text(
            remainingWorkouts > 0
                ? '목표까지 운동 $remainingWorkouts회 남았어요'
                : '이번 주 목표를 모두 달성했어요! 🎉',
            style: const TextStyle(
              color: CoachFitColors.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: CoachFitSpacing.lg),

          // 2. 월~일 7개 요일 인디케이터
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (i) {
              final isCompleted = i < completedDays.length && completedDays[i];
              final isToday = i == todayIndex;
              final label = _dayLabels[i];

              return Expanded(
                child: Column(
                  children: [
                    _buildDayCircle(isCompleted, isToday),
                    const SizedBox(height: CoachFitSpacing.sm),
                    Text(
                      label,
                      style: TextStyle(
                        color: isToday ? CoachFitColors.orange : CoachFitColors.textMuted,
                        fontSize: 11,
                        fontWeight: isToday ? FontWeight.w800 : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildDayCircle(bool isCompleted, bool isToday) {
    if (isCompleted) {
      return Container(
        width: 32,
        height: 32,
        decoration: const BoxDecoration(
          color: CoachFitColors.mint,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.check_rounded,
          color: Color(0xFF0E1116),
          size: 18,
        ),
      );
    }

    if (isToday) {
      return Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: CoachFitColors.surfaceRaised,
          shape: BoxShape.circle,
          border: Border.all(
            color: CoachFitColors.orange,
            width: 1.5,
          ),
        ),
        child: Center(
          child: Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: CoachFitColors.orange,
              shape: BoxShape.circle,
            ),
          ),
        ),
      );
    }

    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: CoachFitColors.surfaceRaised.withValues(alpha: 0.5),
        shape: BoxShape.circle,
        border: Border.all(
          color: CoachFitColors.divider,
          width: 1,
        ),
      ),
    );
  }
}
