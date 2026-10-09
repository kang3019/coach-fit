import 'package:flutter/material.dart';
import '../../theme/coachfit_theme.dart';

/// 3D 인체 해부도 다중 레이어 위젯
/// - 인위적 블러(drawOval 등)를 사용하지 않고 실제 3D 해부도 베이스 및 부위별 오버레이 투명 PNG 결합
/// - AGENTS.md 무결성 원칙 준수
class Anatomy3dDisplay extends StatelessWidget {
  final String focusMuscle;
  final double height;

  const Anatomy3dDisplay({
    super.key,
    required this.focusMuscle,
    this.height = 240,
  });

  @override
  Widget build(BuildContext context) {
    final overlays = _getOverlayAssets(focusMuscle);

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(CoachFitRadius.large),
      ),
      child: Container(
        height: height,
        width: double.infinity,
        color: const Color(0xFF0A0C10),
        child: Stack(
          alignment: Alignment.center,
          fit: StackFit.expand,
          children: [
            // 1. 베이스 3D 중립 인체 모델 (앞면/뒷면)
            Image.asset(
              'assets/images/body_base_neutral.png',
              fit: BoxFit.contain,
              alignment: Alignment.center,
              errorBuilder: (_, __, ___) => const Center(
                child: Icon(
                  Icons.accessibility_new_rounded,
                  color: CoachFitColors.textMuted,
                  size: 48,
                ),
              ),
            ),

            // 2. 타겟 부위 오버레이 동적 점등 레이어
            for (final asset in overlays)
              Image.asset(
                asset,
                fit: BoxFit.contain,
                alignment: Alignment.center,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),

            // 3. 우측 하단 플로팅 부위 배지 (예: • 가슴 집중)
            Positioned(
              right: CoachFitSpacing.md,
              bottom: CoachFitSpacing.md,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: CoachFitSpacing.sm + 2,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(CoachFitRadius.small),
                  border: Border.all(
                    color: CoachFitColors.orange.withValues(alpha: 0.4),
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
                      '$focusMuscle 집중',
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
    );
  }

  List<String> _getOverlayAssets(String muscle) {
    final lower = muscle.toLowerCase();
    final assets = <String>[];

    if (lower.contains('가슴') || lower.contains('대흉근') || lower.contains('chest')) {
      assets.add('assets/images/overlay_chest.png');
    }
    if (lower.contains('등') || lower.contains('광배') || lower.contains('back')) {
      assets.add('assets/images/overlay_back.png');
    }
    if (lower.contains('어깨') || lower.contains('shoulder')) {
      assets.add('assets/images/overlay_shoulders.png');
    }
    if (lower.contains('이두') || lower.contains('biceps')) {
      assets.add('assets/images/overlay_biceps.png');
    }
    if (lower.contains('삼두') || lower.contains('triceps')) {
      assets.add('assets/images/overlay_triceps.png');
    }
    if (lower.contains('복근') || lower.contains('abs') || lower.contains('코어')) {
      assets.add('assets/images/overlay_abs.png');
    }
    if (lower.contains('하체') || lower.contains('대퇴') || lower.contains('스쿼트')) {
      assets.add('assets/images/overlay_quads.png');
      assets.add('assets/images/overlay_glutes.png');
    }
    if (lower.contains('둔근') || lower.contains('엉덩이')) {
      assets.add('assets/images/overlay_glutes.png');
    }
    if (lower.contains('햄스트링')) {
      assets.add('assets/images/overlay_hamstrings.png');
    }
    if (lower.contains('종아리')) {
      assets.add('assets/images/overlay_calves.png');
    }

    if (assets.isEmpty) {
      // 기본값 가슴 오버레이
      assets.add('assets/images/overlay_chest.png');
    }

    return assets;
  }
}
