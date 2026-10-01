import 'package:flutter/material.dart';

/// 10대 주요 근육 부위 열거형
enum MuscleGroup {
  chest,       // 가슴
  back,        // 등 (광배근, 승모근)
  shoulders,   // 어깨 (삼각근)
  biceps,      // 이두근
  triceps,     // 삼두근
  abs,         // 복근 / 코어
  quads,       // 대퇴사두근 (허벅지 앞)
  hamstrings,  // 햄스트링 (허벅지 뒤)
  glutes,      // 둔근 (엉덩이)
  calves,      // 종아리
}

extension MuscleGroupExtension on MuscleGroup {
  String get koreanName {
    switch (this) {
      case MuscleGroup.chest:
        return '가슴';
      case MuscleGroup.back:
        return '등';
      case MuscleGroup.shoulders:
        return '어깨';
      case MuscleGroup.biceps:
        return '이두';
      case MuscleGroup.triceps:
        return '삼두';
      case MuscleGroup.abs:
        return '복근';
      case MuscleGroup.quads:
        return '대퇴사두';
      case MuscleGroup.hamstrings:
        return '햄스트링';
      case MuscleGroup.glutes:
        return '둔근';
      case MuscleGroup.calves:
        return '종아리';
    }
  }

  static Set<MuscleGroup> parseFromText(String text) {
    final lower = text.toLowerCase();
    final result = <MuscleGroup>{};

    if (lower.contains('가슴') || lower.contains('대흉근') || lower.contains('chest') || lower.contains('벤치')) {
      result.add(MuscleGroup.chest);
    }
    if (lower.contains('등') || lower.contains('광배') || lower.contains('승모') || lower.contains('풀다운') || lower.contains('풀업') || lower.contains('로우') || lower.contains('back')) {
      result.add(MuscleGroup.back);
    }
    if (lower.contains('어깨') || lower.contains('삼각근') || lower.contains('숄더') || lower.contains('밀리터리') || lower.contains('shoulder')) {
      result.add(MuscleGroup.shoulders);
    }
    if (lower.contains('이두') || lower.contains('바이셉') || lower.contains('biceps')) {
      result.add(MuscleGroup.biceps);
    }
    if (lower.contains('삼두') || lower.contains('트라이셉') || lower.contains('triceps') || lower.contains('딥스')) {
      result.add(MuscleGroup.triceps);
    }
    if (lower.contains('복근') || lower.contains('코어') || lower.contains('abs') || lower.contains('플랭크') || lower.contains('크런치')) {
      result.add(MuscleGroup.abs);
    }
    if (lower.contains('하체') || lower.contains('대퇴사두') || lower.contains('스쿼트') || lower.contains('레그') || lower.contains('quads') || lower.contains('런지')) {
      result.add(MuscleGroup.quads);
    }
    if (lower.contains('둔근') || lower.contains('엉덩이') || lower.contains('힙') || lower.contains('glute') || lower.contains('데드리프트')) {
      result.add(MuscleGroup.glutes);
    }
    if (lower.contains('햄스트링') || lower.contains('대퇴이두') || lower.contains('hamstring')) {
      result.add(MuscleGroup.hamstrings);
    }
    if (lower.contains('종아리') || lower.contains('카프') || lower.contains('calf') || lower.contains('calves')) {
      result.add(MuscleGroup.calves);
    }

    return result;
  }
}

/// 포토리얼리스틱 3D 인체 전면 / 후면 근육 해부도 위젯
/// - 고화질 3D 메디컬 렌더 인체 모델 베이스
/// - 타겟 근육 실시간 핫오렌지/레드 글로우 오버레이
class MuscleMapWidget extends StatelessWidget {
  final Set<MuscleGroup> activeMuscles;
  final double height;
  final bool showLabels;

  const MuscleMapWidget({
    super.key,
    required this.activeMuscles,
    this.height = 320,
    this.showLabels = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1218),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          if (showLabels)
            const Padding(
              padding: EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Expanded(
                    child: Center(
                      child: Text(
                        'FRONT',
                        style: TextStyle(
                          color: Colors.white38,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2.0,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        'BACK',
                        style: TextStyle(
                          color: Colors.white38,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2.0,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // 3D 인체 모델 및 타겟 근육 글로우 스택
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                // 1. 실감형 3D 인체 모델 베이스 이미지 (실제 사람 얼굴 & 근육결)
                AspectRatio(
                  aspectRatio: 1.0,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.asset(
                      'assets/images/fleek_anatomy_hd.jpg',
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => _FallbackVectorAnatomy(activeMuscles: activeMuscles),
                    ),
                  ),
                ),

                // 2. 근육별 3D 입체 글로우 오버레이 (BlendMode.screen)
                Positioned.fill(
                  child: Center(
                    child: AspectRatio(
                      aspectRatio: 1.0,
                      child: CustomPaint(
                        painter: _AnatomyGlowOverlayPainter(activeMuscles: activeMuscles),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (activeMuscles.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              alignment: WrapAlignment.center,
              children: activeMuscles.map((m) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF4820).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: const Color(0xFFFF4820).withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFF4820),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        m.koreanName,
                        style: const TextStyle(
                          color: Color(0xFFFF6A48),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}

/// 3D 인체 모델 위에 정확하게 겹쳐지는 사실적 타겟 근육 발광 셰이더 페인터
class _AnatomyGlowOverlayPainter extends CustomPainter {
  final Set<MuscleGroup> activeMuscles;

  _AnatomyGlowOverlayPainter({required this.activeMuscles});

  @override
  void paint(Canvas canvas, Size size) {
    if (activeMuscles.isEmpty) return;

    final w = size.width;
    final h = size.height;

    // 좌측: 전면 인체 중심 (Front Center ~0.165)
    final fcx = w * 0.165;
    // 우측: 후면 인체 중심 (Back Center ~0.745)
    final bcx = w * 0.745;

    void drawGlowSpot({
      required Offset center,
      required double radiusX,
      required double radiusY,
      double rotation = 0,
      double intensity = 0.85,
    }) {
      canvas.save();
      canvas.translate(center.dx, center.dy);
      if (rotation != 0) canvas.rotate(rotation);

      final rect = Rect.fromCenter(center: Offset.zero, width: radiusX * 2, height: radiusY * 2);
      final paint = Paint()
        ..blendMode = BlendMode.screen
        ..shader = RadialGradient(
          colors: [
            Color(0xFFFF3D00).withValues(alpha: intensity),
            Color(0xFFFF6A3D).withValues(alpha: intensity * 0.7),
            Color(0xFFFF4820).withValues(alpha: 0.0),
          ],
          stops: const [0.0, 0.55, 1.0],
        ).createShader(rect);

      canvas.drawOval(rect, paint);
      canvas.restore();
    }

    // 1. 가슴 (Chest - Front)
    if (activeMuscles.contains(MuscleGroup.chest)) {
      drawGlowSpot(center: Offset(fcx, h * 0.250), radiusX: w * 0.065, radiusY: h * 0.045);
    }

    // 2. 어깨 (Shoulders - Front & Back)
    if (activeMuscles.contains(MuscleGroup.shoulders)) {
      // 전면 어깨 (Front Delts)
      drawGlowSpot(center: Offset(w * 0.065, h * 0.225), radiusX: w * 0.040, radiusY: h * 0.045, rotation: -0.2);
      drawGlowSpot(center: Offset(w * 0.230, h * 0.245), radiusX: w * 0.038, radiusY: h * 0.045, rotation: 0.2);
      // 후면 어깨 (Rear Delts)
      drawGlowSpot(center: Offset(w * 0.640, h * 0.240), radiusX: w * 0.038, radiusY: h * 0.045, rotation: 0.2);
      drawGlowSpot(center: Offset(w * 0.825, h * 0.240), radiusX: w * 0.038, radiusY: h * 0.045, rotation: -0.2);
    }

    // 3. 복근 (Abs - Front)
    if (activeMuscles.contains(MuscleGroup.abs)) {
      drawGlowSpot(center: Offset(w * 0.160, h * 0.355), radiusX: w * 0.045, radiusY: h * 0.075);
    }

    // 4. 이두근 (Biceps - Front)
    if (activeMuscles.contains(MuscleGroup.biceps)) {
      drawGlowSpot(center: Offset(w * 0.030, h * 0.320), radiusX: w * 0.028, radiusY: h * 0.050);
      drawGlowSpot(center: Offset(w * 0.260, h * 0.350), radiusX: w * 0.028, radiusY: h * 0.050);
    }

    // 5. 삼두근 (Triceps - Back)
    if (activeMuscles.contains(MuscleGroup.triceps)) {
      drawGlowSpot(center: Offset(w * 0.620, h * 0.330), radiusX: w * 0.028, radiusY: h * 0.055);
      drawGlowSpot(center: Offset(w * 0.850, h * 0.330), radiusX: w * 0.028, radiusY: h * 0.055);
    }

    // 6. 등 (Back / Lats & Traps - Back)
    if (activeMuscles.contains(MuscleGroup.back)) {
      // 승모근 (상부 등)
      drawGlowSpot(center: Offset(bcx, h * 0.220), radiusX: w * 0.060, radiusY: h * 0.050);
      // 광배근 (등 양쪽 날개)
      drawGlowSpot(center: Offset(w * 0.685, h * 0.320), radiusX: w * 0.045, radiusY: h * 0.065, rotation: 0.15);
      drawGlowSpot(center: Offset(w * 0.785, h * 0.320), radiusX: w * 0.045, radiusY: h * 0.065, rotation: -0.15);
    }

    // 7. 둔근 (Glutes / 엉덩이 - Back)
    if (activeMuscles.contains(MuscleGroup.glutes)) {
      drawGlowSpot(center: Offset(w * 0.700, h * 0.495), radiusX: w * 0.048, radiusY: h * 0.050);
      drawGlowSpot(center: Offset(w * 0.765, h * 0.495), radiusX: w * 0.048, radiusY: h * 0.050);
    }

    // 8. 대퇴사두 (Quads / 허벅지 앞 - Front)
    if (activeMuscles.contains(MuscleGroup.quads)) {
      drawGlowSpot(center: Offset(w * 0.095, h * 0.600), radiusX: w * 0.045, radiusY: h * 0.100, rotation: 0.08);
      drawGlowSpot(center: Offset(w * 0.205, h * 0.600), radiusX: w * 0.045, radiusY: h * 0.100, rotation: -0.08);
    }

    // 9. 햄스트링 (Hamstrings / 허벅지 뒤 - Back)
    if (activeMuscles.contains(MuscleGroup.hamstrings)) {
      drawGlowSpot(center: Offset(w * 0.700, h * 0.620), radiusX: w * 0.040, radiusY: h * 0.080);
      drawGlowSpot(center: Offset(w * 0.790, h * 0.620), radiusX: w * 0.040, radiusY: h * 0.080);
    }

    // 10. 종아리 (Calves - Front & Back)
    if (activeMuscles.contains(MuscleGroup.calves)) {
      // Front
      drawGlowSpot(center: Offset(w * 0.065, h * 0.810), radiusX: w * 0.035, radiusY: h * 0.065);
      drawGlowSpot(center: Offset(w * 0.190, h * 0.810), radiusX: w * 0.035, radiusY: h * 0.065);
      // Back
      drawGlowSpot(center: Offset(w * 0.675, h * 0.810), radiusX: w * 0.035, radiusY: h * 0.065);
      drawGlowSpot(center: Offset(w * 0.810, h * 0.810), radiusX: w * 0.035, radiusY: h * 0.065);
    }
  }

  @override
  bool shouldRepaint(covariant _AnatomyGlowOverlayPainter oldDelegate) {
    return oldDelegate.activeMuscles != activeMuscles;
  }
}

/// 이미지 로드 실패 시 동작하는 벡터 해부도 폴백 위젯
class _FallbackVectorAnatomy extends StatelessWidget {
  final Set<MuscleGroup> activeMuscles;

  const _FallbackVectorAnatomy({required this.activeMuscles});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: CustomPaint(
            size: Size.infinite,
            painter: _FrontVectorPainter(activeMuscles: activeMuscles),
          ),
        ),
        Container(width: 1, color: Colors.white12),
        Expanded(
          child: CustomPaint(
            size: Size.infinite,
            painter: _BackVectorPainter(activeMuscles: activeMuscles),
          ),
        ),
      ],
    );
  }
}

class _FrontVectorPainter extends CustomPainter {
  final Set<MuscleGroup> activeMuscles;
  _FrontVectorPainter({required this.activeMuscles});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final scale = size.height / 250.0;
    final inactivePaint = Paint()..color = const Color(0xFF262D3B)..style = PaintingStyle.fill;
    final activePaint = Paint()..color = const Color(0xFFFF4820)..style = PaintingStyle.fill;

    final head = Path()..addOval(Rect.fromCenter(center: Offset(cx, 16 * scale), width: 18 * scale, height: 22 * scale));
    canvas.drawPath(head, inactivePaint);

    final isChest = activeMuscles.contains(MuscleGroup.chest);
    final pecs = Path()
      ..addRect(Rect.fromCenter(center: Offset(cx, 48 * scale), width: 36 * scale, height: 18 * scale));
    canvas.drawPath(pecs, isChest ? activePaint : inactivePaint);

    final isQuads = activeMuscles.contains(MuscleGroup.quads);
    final quads = Path()
      ..addRect(Rect.fromCenter(center: Offset(cx, 130 * scale), width: 32 * scale, height: 50 * scale));
    canvas.drawPath(quads, isQuads ? activePaint : inactivePaint);
  }

  @override
  bool shouldRepaint(covariant _FrontVectorPainter oldDelegate) => oldDelegate.activeMuscles != activeMuscles;
}

class _BackVectorPainter extends CustomPainter {
  final Set<MuscleGroup> activeMuscles;
  _BackVectorPainter({required this.activeMuscles});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final scale = size.height / 250.0;
    final inactivePaint = Paint()..color = const Color(0xFF262D3B)..style = PaintingStyle.fill;
    final activePaint = Paint()..color = const Color(0xFFFF4820)..style = PaintingStyle.fill;

    final head = Path()..addOval(Rect.fromCenter(center: Offset(cx, 16 * scale), width: 18 * scale, height: 22 * scale));
    canvas.drawPath(head, inactivePaint);

    final isBack = activeMuscles.contains(MuscleGroup.back);
    final back = Path()
      ..addRect(Rect.fromCenter(center: Offset(cx, 55 * scale), width: 38 * scale, height: 35 * scale));
    canvas.drawPath(back, isBack ? activePaint : inactivePaint);

    final isGlutes = activeMuscles.contains(MuscleGroup.glutes);
    final glutes = Path()
      ..addRect(Rect.fromCenter(center: Offset(cx, 115 * scale), width: 36 * scale, height: 25 * scale));
    canvas.drawPath(glutes, isGlutes ? activePaint : inactivePaint);
  }

  @override
  bool shouldRepaint(covariant _BackVectorPainter oldDelegate) => oldDelegate.activeMuscles != activeMuscles;
}
