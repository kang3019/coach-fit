import 'package:flutter/material.dart';
import '../../theme/coachfit_theme.dart';
import '../common/coachfit_card.dart';

/// 운동 전 컨디션 선택 카드 (Gestalt 유사성 및 근접성 원칙)
/// - 피곤해요 / 보통이에요 / 좋아요 / 최상이에요 4단계 선택
class ConditionSelector extends StatelessWidget {
  final String selectedCondition;
  final ValueChanged<String> onConditionSelected;

  const ConditionSelector({
    super.key,
    required this.selectedCondition,
    required this.onConditionSelected,
  });

  static const List<_ConditionOption> _options = [
    _ConditionOption(label: '피곤해요', symbol: '•'),
    _ConditionOption(label: '보통이에요', symbol: '—'),
    _ConditionOption(label: '좋아요', symbol: '—'),
    _ConditionOption(label: '최상이에요', symbol: '—'),
  ];

  @override
  Widget build(BuildContext context) {
    return CoachFitCard(
      padding: const EdgeInsets.all(CoachFitSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '운동 전 체크인',
            style: TextStyle(
              color: CoachFitColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 3),
          const Text(
            '선택하면 루틴 강도를 바로 맞춰드려요',
            style: TextStyle(
              color: CoachFitColors.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: CoachFitSpacing.md),
          Row(
            children: _options.map((opt) {
              final isSelected = selectedCondition.contains(opt.label);
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: _buildItem(context, opt, isSelected),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildItem(BuildContext context, _ConditionOption opt, bool isSelected) {
    return Semantics(
      button: true,
      selected: isSelected,
      label: '컨디션 ${opt.label}',
      child: InkWell(
        onTap: () => onConditionSelected(opt.label),
        borderRadius: BorderRadius.circular(CoachFitRadius.small),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: CoachFitSpacing.md),
          decoration: BoxDecoration(
            color: isSelected ? CoachFitColors.surfaceRaised : Colors.transparent,
            borderRadius: BorderRadius.circular(CoachFitRadius.small),
            border: Border.all(
              color: isSelected ? CoachFitColors.mint.withValues(alpha: 0.3) : Colors.transparent,
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 14,
                height: 3,
                decoration: BoxDecoration(
                  color: isSelected ? CoachFitColors.mint : CoachFitColors.textMuted.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: CoachFitSpacing.sm),
              Text(
                opt.label,
                style: TextStyle(
                  color: isSelected ? CoachFitColors.textPrimary : CoachFitColors.textMuted,
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                  letterSpacing: -0.2,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConditionOption {
  final String label;
  final String symbol;

  const _ConditionOption({
    required this.label,
    required this.symbol,
  });
}
