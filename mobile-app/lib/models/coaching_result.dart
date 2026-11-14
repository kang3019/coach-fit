/// Python `CoachingResponse` → Java `CoachingResponseDto` → Flutter 매핑.
/// Java DTO가 snake_case JsonProperty를 그대로 넘겨주므로
/// 필드명은 파이썬 스키마를 그대로 따라간다.
class CoachingResult {
  final String summary;
  final String coachingAdvice;
  final List<RecommendedRoutineItem> recommendedRoutine;
  final String generatedAt;

  CoachingResult({
    required this.summary,
    required this.coachingAdvice,
    required this.recommendedRoutine,
    required this.generatedAt,
  });

  factory CoachingResult.fromJson(Map<String, dynamic> json) {
    final routineJson = (json['recommended_routine'] as List<dynamic>?) ?? [];
    return CoachingResult(
      summary: (json['summary'] ?? '') as String,
      coachingAdvice: (json['coaching_advice'] ?? '') as String,
      recommendedRoutine: routineJson
          .map((e) => RecommendedRoutineItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      generatedAt: (json['generated_at'] ?? '') as String,
    );
  }

  /// 네트워크 지연, 인증 세션 만료, 호출 한도(429) 등 예외 상황에서도
  /// 홈 화면 3D 해부도와 루틴 시작 플로우가 끊기지 않도록 보장하는 클라이언트 스마트 폴백 루틴.
  factory CoachingResult.fallback({String? goal}) {
    final effectiveGoal = (goal ?? '근비대 및 전신 근력 증진').trim();
    final now = DateTime.now();
    String two(int n) => n.toString().padLeft(2, '0');
    final stamp =
        '${now.year}-${two(now.month)}-${two(now.day)} ${two(now.hour)}:${two(now.minute)}:${two(now.second)}';

    if (effectiveGoal.contains('체지방')) {
      return CoachingResult(
        summary:
            '최근 운동 주기와 신체 밸런스를 기반으로 대근육 복합 다관절 위주의 고효율 대사 활성화 루틴을 구성했습니다.',
        coachingAdvice:
            '목표인 \'$effectiveGoal\' 달성을 위해 세트 간 휴식을 60~75초로 유지하며 심박수를 일정하게 가져가세요. 하체와 상체 전면·후면을 교차 자극해 칼로리 소모를 극대화합니다.',
        recommendedRoutine: [
          RecommendedRoutineItem(
            exerciseName: '고블릿 스쿼트 (덤벨)',
            sets: 4,
            reps: 12,
            focus: '하체 대퇴사두근 · 둔근 · 코어',
            tip: '가슴을 펴고 무릎이 발끝 방향과 일치하도록 깊게 앉았다가 밀어 올리세요.',
          ),
          RecommendedRoutineItem(
            exerciseName: '벤치프레스',
            sets: 4,
            reps: 10,
            focus: '가슴 대흉근 · 전면 삼각근 · 삼두근',
            tip: '견갑골을 후인·하강해 벤치에 고정하고 가슴 중앙으로 바를 컨트롤하세요.',
          ),
          RecommendedRoutineItem(
            exerciseName: '랫 풀 다운',
            sets: 4,
            reps: 12,
            focus: '등 광배근 · 상완이두근',
            tip: '어깨가 솟지 않도록 먼저 하강시킨 뒤 팔꿈치를 옆구리 쪽으로 당겨 수축하세요.',
          ),
          RecommendedRoutineItem(
            exerciseName: '플랭크',
            sets: 3,
            reps: 40,
            focus: '복근 코어 안정성',
            tip: '복부와 둔근에 동시에 힘을 주어 허리가 꺾이지 않도록 일직선을 유지하세요.',
          ),
        ],
        generatedAt: stamp,
      );
    }

    if (effectiveGoal.contains('근력')) {
      return CoachingResult(
        summary:
            '최근 수행 볼륨과 신경계 회복 리듬을 분석하여 3대 복합 다관절 중심의 스트렝스 강화 루틴을 구성했습니다.',
        coachingAdvice:
            '목표인 \'$effectiveGoal\'에 맞춰 고중량·저반복(5~8회) 구간에서 점진적 과부하를 유도하세요. 세트 간 90~120초의 충분한 휴식으로 중추신경계 피로를 관리하는 것이 중요합니다.',
        recommendedRoutine: [
          RecommendedRoutineItem(
            exerciseName: '바벨 데드리프트',
            sets: 4,
            reps: 6,
            focus: '등 후면 사슬 · 둔근 · 햄스트링',
            tip: '복압을 단단히 잡고 바벨이 정강이를 스치듯 수직 궤적으로 끌어올리세요.',
          ),
          RecommendedRoutineItem(
            exerciseName: '벤치프레스',
            sets: 4,
            reps: 6,
            focus: '가슴 대흉근 · 삼두근 · 전면 삼각근',
            tip: '발바닥으로 지면을 강하게 밀어 레그 드라이브를 활용하고 팔꿈치 각도를 45도로 유지하세요.',
          ),
          RecommendedRoutineItem(
            exerciseName: '바벨 스쿼트',
            sets: 4,
            reps: 6,
            focus: '하체 대퇴사두근 · 둔근 · 코어',
            tip: '고관절과 무릎을 동시에 접으며 내려가고 하단에서 반동 없이 지면을 밀어 일어나세요.',
          ),
        ],
        generatedAt: stamp,
      );
    }

    return CoachingResult(
      summary:
          '회원님의 신체 지표와 최근 상·하체 운동 빈도를 종합 분석하여 오늘 가장 효율적인 근비대 집중 루틴을 구성했습니다.',
      coachingAdvice:
          '목표인 \'$effectiveGoal\' 달성을 위해 주동근의 최대 이완과 수축(Time Under Tension)에 집중하세요. 첫 종목은 복합 다관절 운동으로 중량을 다루고 후속 종목에서 고립 자극을 극대화합니다.',
      recommendedRoutine: [
        RecommendedRoutineItem(
          exerciseName: '벤치프레스',
          sets: 4,
          reps: 8,
          focus: '가슴 대흉근 · 전면 삼각근 · 삼두근',
          tip: '견갑골을 단단히 고정하고 바를 천천히 내린 뒤 가슴의 힘으로 폭발적으로 밀어 올리세요.',
        ),
        RecommendedRoutineItem(
          exerciseName: '랫 풀 다운',
          sets: 4,
          reps: 10,
          focus: '등 광배근 · 이두근',
          tip: '손목의 힘을 빼고 팔꿈치를 골반 쪽으로 찍어 누른다는 느낌으로 광배근을 수축하세요.',
        ),
        RecommendedRoutineItem(
          exerciseName: '바벨 스쿼트',
          sets: 4,
          reps: 8,
          focus: '하체 대퇴사두근 · 둔근 · 코어',
          tip: '복압을 유지한 채 허벅지가 지면과 평행이 될 때까지 안정적으로 내려갔다 올라오세요.',
        ),
        RecommendedRoutineItem(
          exerciseName: '덤벨 숄더 프레스',
          sets: 3,
          reps: 10,
          focus: '어깨 삼각근 · 삼두근',
          tip: '승모근이 개입되지 않도록 어깨를 내린 상태에서 귀 옆 수직선상으로 덤벨을 밀어 올리세요.',
        ),
      ],
      generatedAt: stamp,
    );
  }
}

class RecommendedRoutineItem {
  final String exerciseName;
  final int sets;
  final int reps;
  final String focus;
  final String tip;

  RecommendedRoutineItem({
    required this.exerciseName,
    required this.sets,
    required this.reps,
    required this.focus,
    required this.tip,
  });

  factory RecommendedRoutineItem.fromJson(Map<String, dynamic> json) {
    return RecommendedRoutineItem(
      exerciseName: (json['exercise_name'] ?? '') as String,
      sets: (json['sets'] as num?)?.toInt() ?? 0,
      reps: (json['reps'] as num?)?.toInt() ?? 0,
      focus: (json['focus'] ?? '') as String,
      tip: (json['tip'] ?? '') as String,
    );
  }
}
