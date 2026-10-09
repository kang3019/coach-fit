import 'package:flutter/material.dart';
import '../../theme/coachfit_theme.dart';

/// CoachFit 디자인 시스템 표준 표면 카드
/// - AMOLED 배경 위의 표면 레이어 분리 (Gestalt 공통 영역 원칙)
/// - 균일한 반경과 미세한 경계선 적용
class CoachFitCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double? borderRadius;
  final Color? backgroundColor;
  final Color? borderColor;
  final VoidCallback? onTap;

  const CoachFitCard({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius,
    this.backgroundColor,
    this.borderColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveRadius = BorderRadius.circular(
      borderRadius ?? CoachFitRadius.large,
    );

    final card = Container(
      decoration: BoxDecoration(
        color: backgroundColor ?? CoachFitColors.surface,
        borderRadius: effectiveRadius,
        border: Border.all(
          color: borderColor ?? CoachFitColors.border,
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: effectiveRadius,
        child: InkWell(
          onTap: onTap,
          borderRadius: effectiveRadius,
          child: Padding(
            padding: padding ?? const EdgeInsets.all(CoachFitSpacing.lg),
            child: child,
          ),
        ),
      ),
    );

    return card;
  }
}
