import 'package:fl_chart/fl_chart.dart';
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
/// - 유사성/연속성: 민트/오렌지 포인트 색상으로 건강한 변화 강조 및 직전 기록 대비 실시간 증감량 계산
class GestaltBodyMetricsCard extends StatelessWidget {
  final BodyRecord? latestRecord;
  final List<BodyRecord> records;
  final UserProfile? profile;
  final VoidCallback onAddRecord;
  final VoidCallback? onOpenDetail;

  const GestaltBodyMetricsCard({
    super.key,
    required this.latestRecord,
    this.records = const [],
    required this.profile,
    required this.onAddRecord,
    this.onOpenDetail,
  });

  String? _formatDelta(double? current, double? previous, String unit) {
    if (current == null || previous == null) return null;
    final diff = current - previous;
    if (diff.abs() < 0.05) return '0.0$unit';
    final sign = diff > 0 ? '+' : '';
    return '$sign${diff.toStringAsFixed(1)}$unit';
  }

  void _showTrendSheet(BuildContext context) {
    if (onOpenDetail != null) {
      onOpenDetail!();
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: CoachFitColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _BodyMetricsTrendSheet(
        records: records.isNotEmpty
            ? records
            : (latestRecord != null ? [latestRecord!] : const []),
        profile: profile,
        onAddRecord: onAddRecord,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final prevRecord = records.length >= 2 ? records[1] : null;
    final weight = latestRecord?.weightKg ?? profile?.weightKg ?? 72.4;
    final muscle = latestRecord?.muscleKg ?? 34.8;
    final fat = latestRecord?.bodyFatPercent ?? 16.2;
    final dateStr = latestRecord != null
        ? DateFormat('M월 d일 기준', 'ko_KR').format(latestRecord!.date)
        : '최근 기록';

    final targetWeight = profile?.targetWeightKg ?? 68.0;
    final diff = weight - targetWeight;
    final progressText = diff.abs() < 0.1
        ? '목표 체중 달성! 🎉'
        : diff > 0
            ? '목표 체중까지 ${diff.toStringAsFixed(1)}kg 감량 남음'
            : '목표 체중까지 ${(-diff).toStringAsFixed(1)}kg 증량 남음';

    final weightBadge = _formatDelta(latestRecord?.weightKg, prevRecord?.weightKg, 'kg') ??
        (diff.abs() >= 0.1
            ? '${diff > 0 ? "-" : "+"}${diff.abs().toStringAsFixed(1)}kg 목표'
            : '목표 달성');
    final muscleBadge = _formatDelta(latestRecord?.muscleKg, prevRecord?.muscleKg, 'kg') ??
        (latestRecord?.muscleKg != null ? '측정 완료' : '기준치');
    final fatBadge = _formatDelta(latestRecord?.bodyFatPercent, prevRecord?.bodyFatPercent, '%') ??
        (latestRecord?.bodyFatPercent != null ? '측정 완료' : '기준치');

    final muscleUp = (latestRecord?.muscleKg ?? 0) >= (prevRecord?.muscleKg ?? 0);
    final fatDown = (latestRecord?.bodyFatPercent ?? 0) <= (prevRecord?.bodyFatPercent ?? 100);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CoachFitSectionHeader(
          categoryTag: 'BODY METRICS',
          title: '신체 변화',
          subtitle: '$dateStr · 카드를 탭하면 추이 그래프가 열립니다',
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
          onTap: () => _showTrendSheet(context),
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
                      badgeText: weightBadge,
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
                      badgeText: muscleBadge,
                      badgeColor: muscleUp ? CoachFitColors.mint : CoachFitColors.orange,
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
                      badgeText: fatBadge,
                      badgeColor: fatDown ? CoachFitColors.mint : CoachFitColors.orange,
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
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.show_chart_rounded,
                      color: CoachFitColors.mint,
                      size: 16,
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

class _BodyMetricsTrendSheet extends StatelessWidget {
  final List<BodyRecord> records;
  final UserProfile? profile;
  final VoidCallback onAddRecord;

  const _BodyMetricsTrendSheet({
    required this.records,
    required this.profile,
    required this.onAddRecord,
  });

  @override
  Widget build(BuildContext context) {
    final weightRecords = records
        .where((r) => r.weightKg != null)
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '신체 측정 추이 및 이력',
                  style: TextStyle(
                    color: CoachFitColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    onAddRecord();
                  },
                  icon: const Icon(Icons.add_rounded, size: 16, color: CoachFitColors.mint),
                  label: const Text(
                    '새 측정 추가',
                    style: TextStyle(color: CoachFitColors.mint, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (weightRecords.length >= 2)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: CoachFitColors.surfaceRaised,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: CoachFitColors.line),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '📉 체중 변화 추이 (kg)',
                      style: TextStyle(
                        color: CoachFitColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 150,
                      child: _buildLineChart(weightRecords),
                    ),
                  ],
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: CoachFitColors.surfaceRaised,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: CoachFitColors.line),
                ),
                alignment: Alignment.center,
                child: const Text(
                  '측정 기록이 2회 이상 쌓이면 체중 변화 추이 그래프가 표시됩니다.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: CoachFitColors.textMuted, fontSize: 12),
                ),
              ),
            const SizedBox(height: 16),
            const Text(
              '최근 측정 기록',
              style: TextStyle(
                color: CoachFitColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            if (records.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  '아직 등록된 신체 측정 기록이 없습니다.',
                  style: TextStyle(color: CoachFitColors.textMuted, fontSize: 12),
                ),
              )
            else
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 220),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: records.length,
                  separatorBuilder: (_, __) => const Divider(color: CoachFitColors.divider, height: 1),
                  itemBuilder: (_, i) {
                    final r = records[i];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            DateFormat('yyyy.MM.dd (E)', 'ko_KR').format(r.date),
                            style: const TextStyle(
                              color: CoachFitColors.textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Row(
                            children: [
                              if (r.weightKg != null)
                                _HistoryChip('체중 ${r.weightKg!.toStringAsFixed(1)}kg', CoachFitColors.mint),
                              if (r.muscleKg != null) ...[
                                const SizedBox(width: 6),
                                _HistoryChip('근육 ${r.muscleKg!.toStringAsFixed(1)}kg', CoachFitColors.orange),
                              ],
                              if (r.bodyFatPercent != null) ...[
                                const SizedBox(width: 6),
                                _HistoryChip('체지방 ${r.bodyFatPercent!.toStringAsFixed(1)}%', CoachFitColors.textSecondary),
                              ],
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLineChart(List<BodyRecord> sorted) {
    final spots = <FlSpot>[
      for (var i = 0; i < sorted.length; i++)
        FlSpot(i.toDouble(), sorted[i].weightKg!),
    ];
    final minY = spots.map((e) => e.y).reduce((a, b) => a < b ? a : b);
    final maxY = spots.map((e) => e.y).reduce((a, b) => a > b ? a : b);
    final pad = ((maxY - minY) * 0.2).clamp(1.0, 8.0);

    return LineChart(
      LineChartData(
        minY: minY - pad,
        maxY: maxY + pad,
        titlesData: const FlTitlesData(show: false),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: CoachFitColors.mint,
            barWidth: 2.5,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  CoachFitColors.mint.withValues(alpha: 0.25),
                  CoachFitColors.mint.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryChip extends StatelessWidget {
  final String text;
  final Color color;

  const _HistoryChip(this.text, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700),
      ),
    );
  }
}
