import 'package:flutter/material.dart';
import '../../theme/coachfit_theme.dart';
import 'weekly_goal_ring.dart';

/// 홈 화면 최상단 '오늘의 플랜' 요약 카드 (Gestalt 공통영역)
/// - 스크린샷 191235 기반: 다크 그라데이션, 좌우 앰비언트 글로우, 상하 분할 디바이더
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

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(CoachFitRadius.hero),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
          width: 1,
        ),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1C222E),
            Color(0xFF13171F),
            Color(0xFF0F131A),
          ],
          stops: [0.0, 0.55, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(CoachFitRadius.hero),
        child: Stack(
          children: [
            // 좌측 상단 미세 오렌지 앰비언트 글로우
            Positioned(
              left: -50,
              top: -50,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      CoachFitColors.orange.withValues(alpha: 0.08),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // 우측 상단 미세 민트 앰비언트 글로우 (주간 목표 링 주변)
            Positioned(
              right: -30,
              top: -30,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      CoachFitColors.mint.withValues(alpha: 0.12),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // 카드 메인 콘텐츠
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. 상단 섹션 (패딩 20)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 상태 배지
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
                              horizontal: CoachFitSpacing.sm + 1,
                              vertical: 3.5,
                            ),
                            decoration: BoxDecoration(
                              color: (isRecovered ? CoachFitColors.mint : CoachFitColors.orange)
                                  .withValues(alpha: 0.14),
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
                                const SizedBox(width: 4.5),
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
                      const SizedBox(height: 16),

                      // 인사말 + 주간 목표 링
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
                                    fontSize: 23,
                                    fontWeight: FontWeight.w900,
                                    height: 1.25,
                                    letterSpacing: -0.6,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  subMessage,
                                  style: const TextStyle(
                                    color: CoachFitColors.textSecondary,
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w500,
                                    height: 1.45,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 14),
                          WeeklyGoalRing(
                            current: currentWeeklyWorkouts,
                            target: targetWeeklyWorkouts,
                            size: 88,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // 중간 구분선
                Container(
                  height: 1,
                  color: Colors.white.withValues(alpha: 0.06),
                ),

                // 2. 하단 서브 지표 2분할 영역 (스크린샷 191235 디자인)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      // 좌측: 연속 운동
                      Expanded(
                        child: InkWell(
                          onTap: onTapStats,
                          borderRadius: BorderRadius.circular(CoachFitRadius.small),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                            child: Row(
                              children: [
                                Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF281C1B),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: CoachFitColors.orange.withValues(alpha: 0.25),
                                      width: 1,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.local_fire_department_rounded,
                                    color: CoachFitColors.orange,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 12),
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
                                      const SizedBox(height: 2),
                                      Text(
                                        '$streakDays일째',
                                        style: const TextStyle(
                                          color: CoachFitColors.textPrimary,
                                          fontSize: 15,
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
                      ),

                      // 세로 구분선
                      Container(
                        width: 1,
                        height: 38,
                        color: Colors.white.withValues(alpha: 0.06),
                        margin: const EdgeInsets.symmetric(horizontal: 12),
                      ),

                      // 우측: 지난주 대비 성장
                      Expanded(
                        child: InkWell(
                          onTap: onTapStats,
                          borderRadius: BorderRadius.circular(CoachFitRadius.small),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                            child: Row(
                              children: [
                                Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF142924),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: CoachFitColors.mint.withValues(alpha: 0.25),
                                      width: 1,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.trending_up_rounded,
                                    color: CoachFitColors.mint,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 12),
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
                                      const SizedBox(height: 2),
                                      Text(
                                        growthRate,
                                        style: const TextStyle(
                                          color: CoachFitColors.textPrimary,
                                          fontSize: 15,
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
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
