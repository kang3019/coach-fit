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
            style: CoachFitTypography.kicker,
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
                    style: CoachFitTypography.sectionTitle,
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      subtitle!,
                      style: CoachFitTypography.caption,
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
