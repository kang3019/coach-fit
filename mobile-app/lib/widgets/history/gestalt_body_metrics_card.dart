import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/user_profile.dart';
import '../../services/body_record_service.dart';
import '../../theme/coachfit_theme.dart';
import '../common/coachfit_card.dart';
import '../common/section_header.dart';

/// 게슈탈트 시각 원칙 기반 신체 변화 요약 카드
/// - 공통 영역: 체중, 골격근량, 체지방률, 목표 달성도를 하나의 세련된 카드로 통합
/// - 시각적 위계: 큰 수치와 작은 레이블의 극적인 대비
/// - 유사성/연속성: 민트/오렌지 포인트 색상으로 건강한 변화 강조
class GestaltBodyMetricsCard extends StatelessWidget {
  final BodyRecord? latestRecord;
  final UserProfile? profile;
  final VoidCallback onAddRecord;
  final VoidCallback? onOpenDetail;

  const GestaltBodyMetricsCard({
    super.key,
    required this.latestRecord,
    required this.profile,
    required this.onAddRecord,
    this.onOpenDetail,
  });

  @override
  Widget build(BuildContext context) {
    final weight = latestRecord?.weightKg ?? profile?.weightKg ?? 72.4;
    final muscle = latestRecord?.muscleKg ?? 34.8;
    final fat = latestRecord?.bodyFatPercent ?? 16.2;
    final dateStr = latestRecord != null
        ? DateFormat('M월 d일 기준', 'ko_KR').format(latestRecord!.date)
        : '최근 기록';

    final targetWeight = profile?.targetWeightKg ?? 68.0;
    final diff = weight - targetWeight;
    final progressText = diff > 0
        ? '목표 체중까지 ${(diff).toStringAsFixed(1)}kg 감량 남음'
        : diff < 0
            ? '목표 체중까지 ${(-diff).toStringAsFixed(1)}kg 증량 남음'
            : '목표 체중 달성! 🎉';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CoachFitSectionHeader(
          categoryTag: 'BODY METRICS',
          title: '신체 변화',
          subtitle: dateStr,
          trailing: TextButton.icon(
            onPressed: onAddRecord,
            icon: const Icon(Icons.add_rounded, size: 16, color: CoachFitColors.mint),
            label: const Text(
              '기록 추가',
              style: TextStyle(
                color: CoachFitColors.mint,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              visualDensity: VisualDensity.compact,
            ),
          ),
        ),
        const SizedBox(height: CoachFitSpacing.md),
        CoachFitCard(
          padding: const EdgeInsets.all(CoachFitSpacing.lg),
          onTap: onOpenDetail,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. 체중 / 골격근량 / 체지방률 3대 지표 수평 카드
              Row(
                children: [
                  // 체중
                  Expanded(
                    child: _buildMetricTile(
                      label: '체중',
                      value: weight.toStringAsFixed(1),
                      unit: 'kg',
                      badgeText: diff > 0 ? '-${diff.toStringAsFixed(1)}kg' : null,
                      badgeColor: CoachFitColors.orange,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 52,
                    color: CoachFitColors.divider,
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  // 골격근량
                  Expanded(
                    child: _buildMetricTile(
                      label: '골격근량',
                      value: muscle.toStringAsFixed(1),
                      unit: 'kg',
                      badgeText: '+0.3kg',
                      badgeColor: CoachFitColors.mint,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 52,
                    color: CoachFitColors.divider,
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  // 체지방률
                  Expanded(
                    child: _buildMetricTile(
                      label: '체지방률',
                      value: fat.toStringAsFixed(1),
                      unit: '%',
                      badgeText: '-0.8%',
                      badgeColor: CoachFitColors.mint,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: CoachFitSpacing.lg),

              // 2. 하단 목표 체중 진행도 스트립
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: CoachFitSpacing.md,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: CoachFitColors.surfaceRaised,
                  borderRadius: BorderRadius.circular(CoachFitRadius.small),
                  border: Border.all(color: CoachFitColors.divider),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.flag_rounded,
                      color: CoachFitColors.orange,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        progressText,
                        style: const TextStyle(
                          color: CoachFitColors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      '목표 ${targetWeight.toStringAsFixed(1)}kg',
                      style: const TextStyle(
                        color: CoachFitColors.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
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

  Widget _buildMetricTile({
    required String label,
    required String value,
    required String unit,
    String? badgeText,
    Color? badgeColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: CoachFitColors.textMuted,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        RichText(
          text: TextSpan(
            text: value,
            style: const TextStyle(
              color: CoachFitColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
            children: [
              TextSpan(
                text: ' $unit',
                style: const TextStyle(
                  color: CoachFitColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        if (badgeText != null) ...[
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
            decoration: BoxDecoration(
              color: (badgeColor ?? CoachFitColors.mint).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              badgeText,
              style: TextStyle(
                color: badgeColor ?? CoachFitColors.mint,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
