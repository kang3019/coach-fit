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

/// 인체 전면 / 후면 근육 해부도 위젯 (타겟 근육 핫오렌지 하이라이트)
class MuscleMapWidget extends StatelessWidget {
  final Set<MuscleGroup> activeMuscles;
  final double height;
  final bool showLabels;

  const MuscleMapWidget({
    super.key,
    required this.activeMuscles,
    this.height = 260,
    this.showLabels = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1218),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                // 1. 전면 (Front View)
                Expanded(
                  child: Column(
                    children: [
                      if (showLabels)
                        const Padding(
                          padding: EdgeInsets.only(bottom: 4),
                          child: Text(
                            'FRONT',
                            style: TextStyle(
                              color: Colors.white38,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                      Expanded(
                        child: CustomPaint(
                          size: Size.infinite,
                          painter: _FrontAnatomyPainter(activeMuscles: activeMuscles),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 1,
                  height: height * 0.7,
                  color: Colors.white.withValues(alpha: 0.05),
                ),
                // 2. 후면 (Back View)
                Expanded(
                  child: Column(
                    children: [
                      if (showLabels)
                        const Padding(
                          padding: EdgeInsets.only(bottom: 4),
                          child: Text(
                            'BACK',
                            style: TextStyle(
                              color: Colors.white38,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                      Expanded(
                        child: CustomPaint(
                          size: Size.infinite,
                          painter: _BackAnatomyPainter(activeMuscles: activeMuscles),
                        ),
                      ),
                    ],
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

// -------------------------------------------------------------
// 전면 (Front View) Custom Painter
// -------------------------------------------------------------
class _FrontAnatomyPainter extends CustomPainter {
  final Set<MuscleGroup> activeMuscles;

  _FrontAnatomyPainter({required this.activeMuscles});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final scale = size.height / 250.0;

    final inactivePaint = Paint()
      ..color = const Color(0xFF262D3B)
      ..style = PaintingStyle.fill;

    final inactiveStroke = Paint()
      ..color = const Color(0xFF384357)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final activePaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFF6A3D), Color(0xFFE53935)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final activeGlow = Paint()
      ..color = const Color(0xFFFF4820).withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

    void drawPart(Path path, bool isActive) {
      if (isActive) {
        canvas.drawPath(path, activePaint);
        canvas.drawPath(path, activeGlow);
      } else {
        canvas.drawPath(path, inactivePaint);
        canvas.drawPath(path, inactiveStroke);
      }
    }

    // 1. 머리 및 목
    final headPath = Path()
      ..addOval(Rect.fromCenter(center: Offset(cx, 16 * scale), width: 18 * scale, height: 22 * scale));
    final neckPath = Path()
      ..moveTo(cx - 6 * scale, 26 * scale)
      ..lineTo(cx + 6 * scale, 26 * scale)
      ..lineTo(cx + 8 * scale, 34 * scale)
      ..lineTo(cx - 8 * scale, 34 * scale)
      ..close();
    canvas.drawPath(headPath, inactivePaint);
    canvas.drawPath(headPath, inactiveStroke);
    canvas.drawPath(neckPath, inactivePaint);
    canvas.drawPath(neckPath, inactiveStroke);

    // 2. 가슴 (Chest)
    final isChest = activeMuscles.contains(MuscleGroup.chest);
    final leftPec = Path()
      ..moveTo(cx - 2 * scale, 37 * scale)
      ..lineTo(cx - 20 * scale, 37 * scale)
      ..quadraticBezierTo(cx - 24 * scale, 48 * scale, cx - 18 * scale, 56 * scale)
      ..quadraticBezierTo(cx - 8 * scale, 59 * scale, cx - 2 * scale, 55 * scale)
      ..close();
    final rightPec = Path()
      ..moveTo(cx + 2 * scale, 37 * scale)
      ..lineTo(cx + 20 * scale, 37 * scale)
      ..quadraticBezierTo(cx + 24 * scale, 48 * scale, cx + 18 * scale, 56 * scale)
      ..quadraticBezierTo(cx + 8 * scale, 59 * scale, cx + 2 * scale, 55 * scale)
      ..close();
    drawPart(leftPec, isChest);
    drawPart(rightPec, isChest);

    // 3. 어깨 (Front Deltoids)
    final isShoulder = activeMuscles.contains(MuscleGroup.shoulders);
    final leftDelt = Path()
      ..moveTo(cx - 21 * scale, 36 * scale)
      ..quadraticBezierTo(cx - 32 * scale, 39 * scale, cx - 30 * scale, 54 * scale)
      ..quadraticBezierTo(cx - 24 * scale, 53 * scale, cx - 21 * scale, 47 * scale)
      ..close();
    final rightDelt = Path()
      ..moveTo(cx + 21 * scale, 36 * scale)
      ..quadraticBezierTo(cx + 32 * scale, 39 * scale, cx + 30 * scale, 54 * scale)
      ..quadraticBezierTo(cx + 24 * scale, 53 * scale, cx + 21 * scale, 47 * scale)
      ..close();
    drawPart(leftDelt, isShoulder);
    drawPart(rightDelt, isShoulder);

    // 4. 이두근 (Biceps)
    final isBiceps = activeMuscles.contains(MuscleGroup.biceps);
    final leftBicep = Path()
      ..moveTo(cx - 30 * scale, 55 * scale)
      ..quadraticBezierTo(cx - 34 * scale, 68 * scale, cx - 28 * scale, 80 * scale)
      ..lineTo(cx - 23 * scale, 77 * scale)
      ..quadraticBezierTo(cx - 25 * scale, 65 * scale, cx - 26 * scale, 54 * scale)
      ..close();
    final rightBicep = Path()
      ..moveTo(cx + 30 * scale, 55 * scale)
      ..quadraticBezierTo(cx + 34 * scale, 68 * scale, cx + 28 * scale, 80 * scale)
      ..lineTo(cx + 23 * scale, 77 * scale)
      ..quadraticBezierTo(cx + 25 * scale, 65 * scale, cx + 26 * scale, 54 * scale)
      ..close();
    drawPart(leftBicep, isBiceps);
    drawPart(rightBicep, isBiceps);

    // 5. 전완근 (Forearms)
    final leftForearm = Path()
      ..moveTo(cx - 28 * scale, 81 * scale)
      ..lineTo(cx - 34 * scale, 110 * scale)
      ..lineTo(cx - 28 * scale, 112 * scale)
      ..lineTo(cx - 23 * scale, 82 * scale)
      ..close();
    final rightForearm = Path()
      ..moveTo(cx + 28 * scale, 81 * scale)
      ..lineTo(cx + 34 * scale, 110 * scale)
      ..lineTo(cx + 28 * scale, 112 * scale)
      ..lineTo(cx + 23 * scale, 82 * scale)
      ..close();
    drawPart(leftForearm, false);
    drawPart(rightForearm, false);

    // 6. 복근 (Abs / Six-pack)
    final isAbs = activeMuscles.contains(MuscleGroup.abs);
    final absPath = Path()
      ..moveTo(cx - 10 * scale, 58 * scale)
      ..lineTo(cx + 10 * scale, 58 * scale)
      ..lineTo(cx + 8 * scale, 98 * scale)
      ..lineTo(cx - 8 * scale, 98 * scale)
      ..close();
    drawPart(absPath, isAbs);

    // 7. 대퇴사두 (Quads / 허벅지 앞)
    final isQuads = activeMuscles.contains(MuscleGroup.quads);
    final leftQuad = Path()
      ..moveTo(cx - 2 * scale, 102 * scale)
      ..lineTo(cx - 18 * scale, 102 * scale)
      ..quadraticBezierTo(cx - 24 * scale, 130 * scale, cx - 18 * scale, 162 * scale)
      ..lineTo(cx - 6 * scale, 162 * scale)
      ..quadraticBezierTo(cx - 2 * scale, 130 * scale, cx - 2 * scale, 102 * scale)
      ..close();
    final rightQuad = Path()
      ..moveTo(cx + 2 * scale, 102 * scale)
      ..lineTo(cx + 18 * scale, 102 * scale)
      ..quadraticBezierTo(cx + 24 * scale, 130 * scale, cx + 18 * scale, 162 * scale)
      ..lineTo(cx + 6 * scale, 162 * scale)
      ..quadraticBezierTo(cx + 2 * scale, 130 * scale, cx + 2 * scale, 102 * scale)
      ..close();
    drawPart(leftQuad, isQuads);
    drawPart(rightQuad, isQuads);

    // 8. 무릎
    final leftKnee = Path()
      ..addOval(Rect.fromCenter(center: Offset(cx - 12 * scale, 167 * scale), width: 10 * scale, height: 8 * scale));
    final rightKnee = Path()
      ..addOval(Rect.fromCenter(center: Offset(cx + 12 * scale, 167 * scale), width: 10 * scale, height: 8 * scale));
    drawPart(leftKnee, false);
    drawPart(rightKnee, false);

    // 9. 종아리 / 정강이 (Calves Front)
    final isCalves = activeMuscles.contains(MuscleGroup.calves);
    final leftShin = Path()
      ..moveTo(cx - 16 * scale, 172 * scale)
      ..quadraticBezierTo(cx - 19 * scale, 195 * scale, cx - 14 * scale, 225 * scale)
      ..lineTo(cx - 9 * scale, 225 * scale)
      ..quadraticBezierTo(cx - 8 * scale, 195 * scale, cx - 8 * scale, 172 * scale)
      ..close();
    final rightShin = Path()
      ..moveTo(cx + 16 * scale, 172 * scale)
      ..quadraticBezierTo(cx + 19 * scale, 195 * scale, cx + 14 * scale, 225 * scale)
      ..lineTo(cx + 9 * scale, 225 * scale)
      ..quadraticBezierTo(cx + 8 * scale, 195 * scale, cx + 8 * scale, 172 * scale)
      ..close();
    drawPart(leftShin, isCalves);
    drawPart(rightShin, isCalves);

    // 10. 발
    final leftFoot = Path()
      ..moveTo(cx - 14 * scale, 226 * scale)
      ..lineTo(cx - 17 * scale, 240 * scale)
      ..lineTo(cx - 7 * scale, 240 * scale)
      ..lineTo(cx - 9 * scale, 226 * scale)
      ..close();
    final rightFoot = Path()
      ..moveTo(cx + 14 * scale, 226 * scale)
      ..lineTo(cx + 17 * scale, 240 * scale)
      ..lineTo(cx + 7 * scale, 240 * scale)
      ..lineTo(cx + 9 * scale, 226 * scale)
      ..close();
    drawPart(leftFoot, false);
    drawPart(rightFoot, false);
  }

  @override
  bool shouldRepaint(covariant _FrontAnatomyPainter oldDelegate) {
    return oldDelegate.activeMuscles != activeMuscles;
  }
}

// -------------------------------------------------------------
// 후면 (Back View) Custom Painter
// -------------------------------------------------------------
class _BackAnatomyPainter extends CustomPainter {
  final Set<MuscleGroup> activeMuscles;

  _BackAnatomyPainter({required this.activeMuscles});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final scale = size.height / 250.0;

    final inactivePaint = Paint()
      ..color = const Color(0xFF262D3B)
      ..style = PaintingStyle.fill;

    final inactiveStroke = Paint()
      ..color = const Color(0xFF384357)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final activePaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFF6A3D), Color(0xFFE53935)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final activeGlow = Paint()
      ..color = const Color(0xFFFF4820).withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

    void drawPart(Path path, bool isActive) {
      if (isActive) {
        canvas.drawPath(path, activePaint);
        canvas.drawPath(path, activeGlow);
      } else {
        canvas.drawPath(path, inactivePaint);
        canvas.drawPath(path, inactiveStroke);
      }
    }

    // 1. 머리 및 목 뒤편
    final headPath = Path()
      ..addOval(Rect.fromCenter(center: Offset(cx, 16 * scale), width: 18 * scale, height: 22 * scale));
    final neckPath = Path()
      ..moveTo(cx - 7 * scale, 26 * scale)
      ..lineTo(cx + 7 * scale, 26 * scale)
      ..lineTo(cx + 9 * scale, 34 * scale)
      ..lineTo(cx - 9 * scale, 34 * scale)
      ..close();
    canvas.drawPath(headPath, inactivePaint);
    canvas.drawPath(headPath, inactiveStroke);
    canvas.drawPath(neckPath, inactivePaint);
    canvas.drawPath(neckPath, inactiveStroke);

    // 2. 승모근 및 상부 등 (Traps & Upper Back)
    final isBack = activeMuscles.contains(MuscleGroup.back);
    final traps = Path()
      ..moveTo(cx, 32 * scale)
      ..lineTo(cx + 20 * scale, 38 * scale)
      ..lineTo(cx + 12 * scale, 58 * scale)
      ..lineTo(cx, 68 * scale)
      ..lineTo(cx - 12 * scale, 58 * scale)
      ..lineTo(cx - 20 * scale, 38 * scale)
      ..close();
    drawPart(traps, isBack);

    // 3. 후면 삼각근 (Rear Delts)
    final isShoulders = activeMuscles.contains(MuscleGroup.shoulders);
    final leftRearDelt = Path()
      ..moveTo(cx - 21 * scale, 38 * scale)
      ..quadraticBezierTo(cx - 31 * scale, 41 * scale, cx - 29 * scale, 55 * scale)
      ..lineTo(cx - 21 * scale, 50 * scale)
      ..close();
    final rightRearDelt = Path()
      ..moveTo(cx + 21 * scale, 38 * scale)
      ..quadraticBezierTo(cx + 31 * scale, 41 * scale, cx + 29 * scale, 55 * scale)
      ..lineTo(cx + 21 * scale, 50 * scale)
      ..close();
    drawPart(leftRearDelt, isShoulders);
    drawPart(rightRearDelt, isShoulders);

    // 4. 광배근 (Lats / 등 양쪽)
    final leftLat = Path()
      ..moveTo(cx - 12 * scale, 58 * scale)
      ..quadraticBezierTo(cx - 26 * scale, 64 * scale, cx - 22 * scale, 84 * scale)
      ..lineTo(cx - 8 * scale, 94 * scale)
      ..lineTo(cx - 2 * scale, 70 * scale)
      ..close();
    final rightLat = Path()
      ..moveTo(cx + 12 * scale, 58 * scale)
      ..quadraticBezierTo(cx + 26 * scale, 64 * scale, cx + 22 * scale, 84 * scale)
      ..lineTo(cx + 8 * scale, 94 * scale)
      ..lineTo(cx + 2 * scale, 70 * scale)
      ..close();
    drawPart(leftLat, isBack);
    drawPart(rightLat, isBack);

    // 5. 삼두근 (Triceps)
    final isTriceps = activeMuscles.contains(MuscleGroup.triceps);
    final leftTricep = Path()
      ..moveTo(cx - 29 * scale, 56 * scale)
      ..quadraticBezierTo(cx - 34 * scale, 70 * scale, cx - 27 * scale, 82 * scale)
      ..lineTo(cx - 23 * scale, 79 * scale)
      ..quadraticBezierTo(cx - 25 * scale, 66 * scale, cx - 24 * scale, 54 * scale)
      ..close();
    final rightTricep = Path()
      ..moveTo(cx + 29 * scale, 56 * scale)
      ..quadraticBezierTo(cx + 34 * scale, 70 * scale, cx + 27 * scale, 82 * scale)
      ..lineTo(cx + 23 * scale, 79 * scale)
      ..quadraticBezierTo(cx + 25 * scale, 66 * scale, cx + 24 * scale, 54 * scale)
      ..close();
    drawPart(leftTricep, isTriceps);
    drawPart(rightTricep, isTriceps);

    // 6. 전완근 뒤편
    final leftForearmBack = Path()
      ..moveTo(cx - 27 * scale, 83 * scale)
      ..lineTo(cx - 33 * scale, 110 * scale)
      ..lineTo(cx - 27 * scale, 112 * scale)
      ..lineTo(cx - 22 * scale, 84 * scale)
      ..close();
    final rightForearmBack = Path()
      ..moveTo(cx + 27 * scale, 83 * scale)
      ..lineTo(cx + 33 * scale, 110 * scale)
      ..lineTo(cx + 27 * scale, 112 * scale)
      ..lineTo(cx + 22 * scale, 84 * scale)
      ..close();
    drawPart(leftForearmBack, false);
    drawPart(rightForearmBack, false);

    // 7. 둔근 (Glutes / 엉덩이)
    final isGlutes = activeMuscles.contains(MuscleGroup.glutes);
    final leftGlute = Path()
      ..moveTo(cx - 2 * scale, 98 * scale)
      ..quadraticBezierTo(cx - 24 * scale, 102 * scale, cx - 20 * scale, 126 * scale)
      ..quadraticBezierTo(cx - 12 * scale, 132 * scale, cx - 2 * scale, 128 * scale)
      ..close();
    final rightGlute = Path()
      ..moveTo(cx + 2 * scale, 98 * scale)
      ..quadraticBezierTo(cx + 24 * scale, 102 * scale, cx + 20 * scale, 126 * scale)
      ..quadraticBezierTo(cx + 12 * scale, 132 * scale, cx + 2 * scale, 128 * scale)
      ..close();
    drawPart(leftGlute, isGlutes);
    drawPart(rightGlute, isGlutes);

    // 8. 햄스트링 (Hamstrings / 허벅지 뒤)
    final isHamstrings = activeMuscles.contains(MuscleGroup.hamstrings);
    final leftHam = Path()
      ..moveTo(cx - 3 * scale, 130 * scale)
      ..lineTo(cx - 19 * scale, 129 * scale)
      ..quadraticBezierTo(cx - 22 * scale, 146 * scale, cx - 17 * scale, 162 * scale)
      ..lineTo(cx - 6 * scale, 162 * scale)
      ..close();
    final rightHam = Path()
      ..moveTo(cx + 3 * scale, 130 * scale)
      ..lineTo(cx + 19 * scale, 129 * scale)
      ..quadraticBezierTo(cx + 22 * scale, 146 * scale, cx + 17 * scale, 162 * scale)
      ..lineTo(cx + 6 * scale, 162 * scale)
      ..close();
    drawPart(leftHam, isHamstrings);
    drawPart(rightHam, isHamstrings);

    // 9. 종아리 뒤 (Calves / 비복근)
    final isCalves = activeMuscles.contains(MuscleGroup.calves);
    final leftCalf = Path()
      ..moveTo(cx - 7 * scale, 168 * scale)
      ..quadraticBezierTo(cx - 20 * scale, 185 * scale, cx - 16 * scale, 206 * scale)
      ..lineTo(cx - 12 * scale, 225 * scale)
      ..lineTo(cx - 8 * scale, 225 * scale)
      ..quadraticBezierTo(cx - 7 * scale, 195 * scale, cx - 7 * scale, 168 * scale)
      ..close();
    final rightCalf = Path()
      ..moveTo(cx + 7 * scale, 168 * scale)
      ..quadraticBezierTo(cx + 20 * scale, 185 * scale, cx + 16 * scale, 206 * scale)
      ..lineTo(cx + 12 * scale, 225 * scale)
      ..lineTo(cx + 8 * scale, 225 * scale)
      ..quadraticBezierTo(cx + 7 * scale, 195 * scale, cx + 7 * scale, 168 * scale)
      ..close();
    drawPart(leftCalf, isCalves);
    drawPart(rightCalf, isCalves);

    // 10. 발 뒤꿈치
    final leftHeel = Path()
      ..moveTo(cx - 12 * scale, 226 * scale)
      ..lineTo(cx - 15 * scale, 240 * scale)
      ..lineTo(cx - 8 * scale, 240 * scale)
      ..lineTo(cx - 8 * scale, 226 * scale)
      ..close();
    final rightHeel = Path()
      ..moveTo(cx + 12 * scale, 226 * scale)
      ..lineTo(cx + 15 * scale, 240 * scale)
      ..lineTo(cx + 8 * scale, 240 * scale)
      ..lineTo(cx + 8 * scale, 226 * scale)
      ..close();
    drawPart(leftHeel, false);
    drawPart(rightHeel, false);
  }

  @override
  bool shouldRepaint(covariant _BackAnatomyPainter oldDelegate) {
    return oldDelegate.activeMuscles != activeMuscles;
  }
}
