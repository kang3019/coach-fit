import 'package:flutter/material.dart';
import '../../models/coaching_result.dart';
import '../../screens/widgets/muscle_map_widget.dart';
import '../../theme/coachfit_theme.dart';
import '../common/coachfit_card.dart';
import '../common/section_header.dart';

/// 오늘의 AI 추천 운동 카드 (Gestalt 시각적 위계 및 단일 주 행동 CTA)
/// - 상단 API 연동 정밀 인체 해부도 (타겟 부위 실시간 동적 점등)
/// - 루틴 정보, 종목 리스트, 주요 액션 버튼('추천 루틴 시작하기') 및 상세 링크
class RecommendedRoutineCard extends StatelessWidget {
  final CoachingResult? result;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback? onRetry;
  final ValueChanged<List<RecommendedRoutineItem>> onImportRoutine;
  final VoidCallback onStartRoutine;
  final VoidCallback onViewFullReport;
  final VoidCallback? onOpen3dDetail;

  const RecommendedRoutineCard({
    super.key,
    required this.result,
    this.isLoading = false,
    this.errorMessage,
    this.onRetry,
    required this.onImportRoutine,
    required this.onStartRoutine,
    required this.onViewFullReport,
    this.onOpen3dDetail,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return _buildLoading(context);
    }

    if (errorMessage != null || result == null) {
      return _buildError(context);
    }

    final items = result!.recommendedRoutine;
    final totalSets = items.fold<int>(0, (sum, item) => sum + item.sets);
    final estTime = totalSets > 0 ? totalSets * 4 + 8 : 48;

    // 타겟 부위 추출 (아이템들의 focus 또는 요약문 기반)
    String targetMuscle = '가슴';
    String routineTitle = 'Chest Focus';
    if (items.isNotEmpty && items.first.focus.isNotEmpty) {
      targetMuscle = items.first.focus.split(' ').first;
      routineTitle = _formatRoutineTitle(targetMuscle);
    }

    // 루틴 아이템들로부터 실시간 타겟 근육 세트 추출
    final activeMuscles = <MuscleGroup>{};
    for (final item in items) {
      activeMuscles.addAll(
        MuscleGroupExtension.parseFromText('${item.exerciseName} ${item.focus}'),
      );
    }
    if (activeMuscles.isEmpty) {
      activeMuscles.addAll(MuscleGroupExtension.parseFromText(targetMuscle));
    }
    if (activeMuscles.isEmpty) {
      activeMuscles.add(MuscleGroup.chest);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CoachFitSectionHeader(
          categoryTag: 'FOR YOU',
          title: '오늘의 추천 운동',
          trailing: Text(
            '컨디션에 맞춰 ${totalSets > 0 ? totalSets : 10}세트로 구성했어요',
            style: const TextStyle(
              color: CoachFitColors.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(height: CoachFitSpacing.md),
        CoachFitCard(
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. API 연동 인터랙티브 벡터 인체 해부도 (앞면/뒷면)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(CoachFitRadius.large),
                ),
                child: Container(
                  width: double.infinity,
                  color: const Color(0xFF0A0C10),
                  padding: const EdgeInsets.only(top: 16, bottom: 8),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      GestureDetector(
                        onTap: onOpen3dDetail,
                        child: MuscleMapWidget(
                          activeMuscles: activeMuscles,
                          height: 230,
                          showLabels: false,
                        ),
                      ),
                      // 우측 하단 플로팅 부위 배지 (예: • 가슴 집중)
                      Positioned(
                        right: CoachFitSpacing.md,
                        bottom: CoachFitSpacing.sm,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: CoachFitSpacing.sm + 2,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(CoachFitRadius.small),
                            border: Border.all(
                              color: CoachFitColors.orange.withValues(alpha: 0.5),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: CoachFitColors.orange,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                '$targetMuscle 집중',
                                style: const TextStyle(
                                  color: CoachFitColors.textPrimary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 2. 루틴 정보 및 리스트 본문
              Padding(
                padding: const EdgeInsets.all(CoachFitSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // AI 추천 루틴 태그
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: CoachFitSpacing.sm,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: CoachFitColors.orange.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(CoachFitRadius.small),
                        border: Border.all(
                          color: CoachFitColors.orange.withValues(alpha: 0.35),
                          width: 1,
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.bolt, color: CoachFitColors.orange, size: 14),
                          SizedBox(width: 4),
                          Text(
                            'AI 추천 루틴',
                            style: TextStyle(
                              color: CoachFitColors.orange,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: CoachFitSpacing.md),

                    // 루틴 제목
                    Text(
                      routineTitle,
                      style: const TextStyle(
                        color: CoachFitColors.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: CoachFitSpacing.xs),

                    // 메타데이터 (시간, 총 세트수)
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time_rounded,
                          size: 14,
                          color: CoachFitColors.textMuted,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '약 $estTime분',
                          style: const TextStyle(
                            color: CoachFitColors.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: CoachFitSpacing.md),
                        const Icon(
                          Icons.track_changes_rounded,
                          size: 14,
                          color: CoachFitColors.textMuted,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '총 ${totalSets > 0 ? totalSets : 10}세트',
                          style: const TextStyle(
                            color: CoachFitColors.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: CoachFitSpacing.lg),

                    // 운동 종목 리스트 (최대 3개 미리보기)
                    if (items.isNotEmpty)
                      ...List.generate(
                        items.length.clamp(0, 3),
                        (index) {
                          final item = items[index];
                          final isLast = index == (items.length.clamp(0, 3) - 1);
                          final numStr = (index + 1).toString().padLeft(2, '0');

                          return Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: CoachFitSpacing.sm),
                                child: Row(
                                  children: [
                                    Text(
                                      numStr,
                                      style: const TextStyle(
                                        color: CoachFitColors.orange,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(width: CoachFitSpacing.md),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.exerciseName,
                                            style: const TextStyle(
                                              color: CoachFitColors.textPrimary,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            item.focus.isNotEmpty ? item.focus : targetMuscle,
                                            style: const TextStyle(
                                              color: CoachFitColors.textMuted,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      '${item.sets}세트 · ${item.reps}회',
                                      style: const TextStyle(
                                        color: CoachFitColors.textSecondary,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (!isLast)
                                const Divider(
                                  color: CoachFitColors.divider,
                                  height: 1,
                                ),
                            ],
                          );
                        },
                      ),

                    const SizedBox(height: CoachFitSpacing.lg),

                    // 3. 주요 액션 버튼 (단일 가장 강한 CTA)
                    Container(
                      width: double.infinity,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFFFF5A31),
                            Color(0xFFFF3B14),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(CoachFitRadius.medium),
                        boxShadow: [
                          BoxShadow(
                            color: CoachFitColors.orange.withValues(alpha: 0.35),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(CoachFitRadius.medium),
                          onTap: () {
                            if (items.isNotEmpty) {
                              onImportRoutine(items);
                            } else {
                              onStartRoutine();
                            }
                          },
                          child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: CoachFitSpacing.lg),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.play_circle_fill_rounded,
                                  color: Colors.white,
                                  size: 28,
                                ),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '추천 루틴 시작하기',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                ),
                                Icon(
                                  Icons.chevron_right_rounded,
                                  color: Colors.white,
                                  size: 22,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: CoachFitSpacing.sm),

                    // 4. 보조 액션 버튼 (루틴 상세 보기 >)
                    Center(
                      child: TextButton(
                        onPressed: onViewFullReport,
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '루틴 상세 보기',
                              style: TextStyle(
                                color: CoachFitColors.textMuted,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(width: 2),
                            Icon(
                              Icons.chevron_right_rounded,
                              size: 16,
                              color: CoachFitColors.textMuted,
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
        ),
      ],
    );
  }

  String _formatRoutineTitle(String muscle) {
    if (muscle.contains('가슴')) return 'Chest Focus';
    if (muscle.contains('등')) return 'Back Focus';
    if (muscle.contains('어깨')) return 'Shoulder Focus';
    if (muscle.contains('하체') || muscle.contains('대퇴')) return 'Leg Focus';
    if (muscle.contains('팔') || muscle.contains('이두') || muscle.contains('삼두')) return 'Arms Focus';
    return '$muscle Focus';
  }

  Widget _buildLoading(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const CoachFitSectionHeader(
          categoryTag: 'FOR YOU',
          title: '오늘의 추천 운동',
        ),
        const SizedBox(height: CoachFitSpacing.md),
        CoachFitCard(
          padding: const EdgeInsets.all(CoachFitSpacing.xl),
          child: const Center(
            child: Column(
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation(CoachFitColors.orange),
                  strokeWidth: 2.5,
                ),
                SizedBox(height: CoachFitSpacing.md),
                Text(
                  'AI가 최적의 루틴을 분석하고 있습니다...',
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

  Widget _buildError(BuildContext context) {
    return CoachFitCard(
      padding: const EdgeInsets.all(CoachFitSpacing.lg),
      child: Column(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: CoachFitColors.orange,
            size: 32,
          ),
          const SizedBox(height: CoachFitSpacing.sm),
          const Text(
            '루틴을 불러오지 못했습니다.',
            style: TextStyle(
              color: CoachFitColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: CoachFitSpacing.md),
            TextButton(
              onPressed: onRetry,
              child: const Text('다시 시도', style: TextStyle(color: CoachFitColors.orange)),
            ),
          ],
        ],
      ),
    );
  }
}
