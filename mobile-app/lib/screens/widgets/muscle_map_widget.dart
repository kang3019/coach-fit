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

/// 플릭(Fleek) 정품 3D 인체 해부도 위젯
/// - 인공적인 원형 조명 번짐 효과 없이, 실제 사람 3D 근육 라인(대흉근, 삼각근, 대퇴사두 등)이 칼같이 빨갛게 들어간 원본 3D 렌더를 큼직하게 표시
class MuscleMapWidget extends StatelessWidget {
  final Set<MuscleGroup> activeMuscles;
  final double height;
  final bool showLabels;
  final void Function(MuscleGroup muscle)? onSelectMuscle;
  final MuscleGroup? selectedMuscle;

  const MuscleMapWidget({
    super.key,
    required this.activeMuscles,
    this.height = 340,
    this.showLabels = true,
    this.onSelectMuscle,
    this.selectedMuscle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1218),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          if (showLabels)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 2),
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

          // 1. 유저 요청 고화질 3D 실사 인체 렌더 (칼같은 근육 라인 렌더링)
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Stack(
                fit: StackFit.expand,
                alignment: Alignment.center,
                children: [
                  Image.asset(
                    'assets/images/routine_muscle_target_full.png',
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Image.asset(
                      'assets/images/fleek_anatomy_hd.jpg',
                      fit: BoxFit.contain,
                    ),
                  ),
                  // 은은한 가장자리 페이드로 AMOLED 다크모드 완벽 일체화
                  IgnorePointer(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            const Color(0xFF0F1218).withValues(alpha: 0.15),
                            Colors.transparent,
                            Colors.transparent,
                            const Color(0xFF0F1218).withValues(alpha: 0.25),
                          ],
                          stops: const [0.0, 0.1, 0.9, 1.0],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 10),

          // 2. 정확하게 타겟된 주요 근육 뱃지
          if (activeMuscles.isNotEmpty)
            Wrap(
              spacing: 6,
              runSpacing: 5,
              alignment: WrapAlignment.center,
              children: activeMuscles.map((m) {
                final isSelected = selectedMuscle == m;
                return InkWell(
                  onTap: onSelectMuscle != null ? () => onSelectMuscle!(m) : null,
                  borderRadius: BorderRadius.circular(999),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFFFF4820)
                          : const Color(0xFFFF4820).withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: isSelected
                            ? Colors.white
                            : const Color(0xFFFF4820).withValues(alpha: 0.5),
                        width: isSelected ? 1.5 : 1.0,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.white : const Color(0xFFFF4820),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          m.koreanName,
                          style: TextStyle(
                            color: isSelected ? Colors.white : const Color(0xFFFF6A48),
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}
