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
  final Gradient? gradient;
  final Color? borderColor;
  final List<BoxShadow>? boxShadow;
  final VoidCallback? onTap;

  const CoachFitCard({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius,
    this.backgroundColor,
    this.gradient,
    this.borderColor,
    this.boxShadow,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveRadius = BorderRadius.circular(
      borderRadius ?? CoachFitRadius.large,
    );

    final card = Container(
      decoration: BoxDecoration(
        color: (gradient == null && backgroundColor != null) ? backgroundColor : null,
        gradient: gradient ??
            (backgroundColor == null
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF1A1F2B),
                      Color(0xFF141822),
                      Color(0xFF10131B),
                    ],
                    stops: [0.0, 0.6, 1.0],
                  )
                : null),
        borderRadius: effectiveRadius,
        border: Border.all(
          color: borderColor ?? Colors.white.withValues(alpha: 0.08),
          width: 1,
        ),
        boxShadow: boxShadow ??
            [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.28),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
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
