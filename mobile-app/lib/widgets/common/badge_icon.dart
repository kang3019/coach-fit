import 'package:flutter/material.dart';
import '../../theme/coachfit_theme.dart';

enum CoachFitBadgeVariant { orange, mint, neutral }

/// Figma 기반 표준 아이콘 배지 컴포넌트
/// - 크기: 30px × 30px (기본) / 32px × 32px
/// - 곡률: 10px
/// - 듀얼 악센트 소프트 배경 (orangeSoft / mintSoft)
class CoachFitBadgeIcon extends StatelessWidget {
  final IconData icon;
  final CoachFitBadgeVariant variant;
  final double size;
  final double iconSize;

  const CoachFitBadgeIcon({
    super.key,
    required this.icon,
    this.variant = CoachFitBadgeVariant.orange,
    this.size = 30,
    this.iconSize = 16,
  });

  const CoachFitBadgeIcon.mint({
    super.key,
    required this.icon,
    this.size = 30,
    this.iconSize = 16,
  }) : variant = CoachFitBadgeVariant.mint;

  const CoachFitBadgeIcon.orange({
    super.key,
    required this.icon,
    this.size = 30,
    this.iconSize = 16,
  }) : variant = CoachFitBadgeVariant.orange;

  const CoachFitBadgeIcon.neutral({
    super.key,
    required this.icon,
    this.size = 30,
    this.iconSize = 16,
  }) : variant = CoachFitBadgeVariant.neutral;

  @override
  Widget build(BuildContext context) {
    final (bgColor, iconColor) = switch (variant) {
      CoachFitBadgeVariant.orange => (
          CoachFitColors.orangeSoft,
          CoachFitColors.orange,
        ),
      CoachFitBadgeVariant.mint => (
          CoachFitColors.mintSoft,
          CoachFitColors.mint,
        ),
      CoachFitBadgeVariant.neutral => (
          CoachFitColors.surfaceSoft,
          CoachFitColors.textSoft,
        ),
    };

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(CoachFitRadius.small),
      ),
      child: Center(
        child: Icon(
          icon,
          size: iconSize,
          color: iconColor,
        ),
      ),
    );
  }
}
