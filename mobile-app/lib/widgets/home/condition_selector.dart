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
            style: CoachFitTypography.sectionTitle,
          ),
          const SizedBox(height: 3),
          const Text(
            '선택하면 루틴 강도를 바로 맞춰드려요',
            style: CoachFitTypography.caption,
          ),
          const SizedBox(height: CoachFitSpacing.md),
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: const Color(0xFF0C0F13),
              borderRadius: BorderRadius.circular(CoachFitRadius.medium),
            ),
            child: Row(
              children: _options.map((opt) {
                final isSelected = selectedCondition.contains(opt.label);
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2.5),
                    child: _buildItem(context, opt, isSelected),
                  ),
                );
              }).toList(),
            ),
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
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            gradient: isSelected
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF252D37), CoachFitColors.surfaceSoft],
                  )
                : null,
            color: isSelected ? null : Colors.transparent,
            borderRadius: BorderRadius.circular(CoachFitRadius.small),
            border: Border.all(
              color: isSelected
                  ? CoachFitColors.mint.withValues(alpha: 0.12)
                  : Colors.transparent,
              width: 1,
            ),
            boxShadow: isSelected
                ? const [
                    BoxShadow(
                      color: Color(0x38000000),
                      blurRadius: 14,
                      offset: Offset(0, 5),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 14,
                height: 4,
                decoration: BoxDecoration(
                  color: isSelected
                      ? CoachFitColors.mint
                      : CoachFitColors.textMuted.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(CoachFitRadius.pill),
                ),
              ),
              const SizedBox(height: 7),
              Text(
                opt.label,
                style: TextStyle(
                  color: isSelected ? CoachFitColors.text : CoachFitColors.textMuted,
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
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
