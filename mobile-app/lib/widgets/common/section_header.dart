import 'package:flutter/material.dart';
import '../../theme/coachfit_theme.dart';

/// CoachFit 섹션 헤더
/// - 태그(예: FOR YOU), 타이틀, 서브타이틀, 우측 액션/설명 영역 지원
class CoachFitSectionHeader extends StatelessWidget {
  final String title;
  final String? categoryTag;
  final String? subtitle;
  final Widget? trailing;

  const CoachFitSectionHeader({
    super.key,
    required this.title,
    this.categoryTag,
    this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (categoryTag != null) ...[
          Text(
            categoryTag!.toUpperCase(),
            style: const TextStyle(
              color: CoachFitColors.orange,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: CoachFitSpacing.xs),
        ],
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: CoachFitColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      subtitle!,
                      style: const TextStyle(
                        color: CoachFitColors.textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ],
    );
  }
}
