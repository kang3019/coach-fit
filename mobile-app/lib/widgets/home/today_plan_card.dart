import 'package:flutter/material.dart';
import '../../theme/coachfit_theme.dart';
import '../common/coachfit_card.dart';
import 'weekly_goal_ring.dart';

/// 홈 화면 최상단 '오늘의 플랜' 요약 카드 (Gestalt 공통영역)
/// - 인사말, 추천 집중 부위, 회복 상태, 주간 목표 링, 연속 운동/성장 지표를 하나의 카드로 통합
class TodayPlanCard extends StatelessWidget {
  final String userName;
  final String focusMuscle;
  final String recoveryStatus;
  final String subMessage;
  final int currentWeeklyWorkouts;
  final int targetWeeklyWorkouts;
  final int streakDays;
  final String growthRate;
  final VoidCallback? onTapStats;

  const TodayPlanCard({
    super.key,
    this.userName = '민준',
    this.focusMuscle = '가슴',
    this.recoveryStatus = '회복 완료',
    this.subMessage = '지난 운동 후 72시간이 지났어요.\n지금이 다시 자극하기 좋은 타이밍이에요.',
    this.currentWeeklyWorkouts = 3,
    this.targetWeeklyWorkouts = 4,
    this.streakDays = 12,
    this.growthRate = '+18% 성장',
    this.onTapStats,
  });

  @override
  Widget build(BuildContext context) {
    final isRecovered = recoveryStatus.contains('완료');

    return CoachFitCard(
      padding: const EdgeInsets.all(CoachFitSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. 상단 상태 배지
          Row(
            children: [
              const Text(
                '오늘의 플랜',
                style: TextStyle(
                  color: CoachFitColors.orange,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(width: CoachFitSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: CoachFitSpacing.sm,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: (isRecovered ? CoachFitColors.mint : CoachFitColors.orange)
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(CoachFitRadius.small),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: isRecovered ? CoachFitColors.mint : CoachFitColors.orange,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      recoveryStatus,
                      style: TextStyle(
                        color: isRecovered ? CoachFitColors.mint : CoachFitColors.orange,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: CoachFitSpacing.md),

          // 2. 인사말 및 주간 목표 링
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$userName님, 오늘은\n$focusMuscle에 집중해요.',
                      style: const TextStyle(
                        color: CoachFitColors.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        height: 1.25,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: CoachFitSpacing.sm),
                    Text(
                      subMessage,
                      style: const TextStyle(
                        color: CoachFitColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: CoachFitSpacing.md),
              WeeklyGoalRing(
                current: currentWeeklyWorkouts,
                target: targetWeeklyWorkouts,
                size: 84,
              ),
            ],
          ),
          const SizedBox(height: CoachFitSpacing.lg),

          // 3. 하단 서브 지표 2분할 영역 (연속 운동 / 지난주 대비 성장)
          Container(
            padding: const EdgeInsets.all(CoachFitSpacing.md),
            decoration: BoxDecoration(
              color: CoachFitColors.surfaceRaised,
              borderRadius: BorderRadius.circular(CoachFitRadius.medium),
            ),
            child: Row(
              children: [
                // 좌측: 연속 운동
                Expanded(
                  child: InkWell(
                    onTap: onTapStats,
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: CoachFitColors.orange.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(CoachFitRadius.small),
                          ),
                          child: const Icon(
                            Icons.local_fire_department_rounded,
                            color: CoachFitColors.orange,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: CoachFitSpacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '연속 운동',
                                style: TextStyle(
                                  color: CoachFitColors.textMuted,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 1),
                              Text(
                                '$streakDays일째',
                                style: const TextStyle(
                                  color: CoachFitColors.textPrimary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  width: 1,
                  height: 32,
                  color: CoachFitColors.divider,
                  margin: const EdgeInsets.symmetric(horizontal: CoachFitSpacing.sm),
                ),
                // 우측: 지난주 대비 성장
                Expanded(
                  child: InkWell(
                    onTap: onTapStats,
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: CoachFitColors.mint.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(CoachFitRadius.small),
                          ),
                          child: const Icon(
                            Icons.trending_up_rounded,
                            color: CoachFitColors.mint,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: CoachFitSpacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '지난주 대비',
                                style: TextStyle(
                                  color: CoachFitColors.textMuted,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 1),
                              Text(
                                growthRate,
                                style: const TextStyle(
                                  color: CoachFitColors.mint,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
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
