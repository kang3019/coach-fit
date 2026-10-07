// 종목별 자세/주의사항 가이드 데이터 (오프라인 정적 데이터).
//
// 사용자가 운동 기록 카드의 info 아이콘을 누르면 ExerciseGuideSheet 에서
// 이 데이터를 조회하여 모달로 표시한다. 종목명은 운동 기록(exerciseName)과
// 부분 일치로 매칭.

class ExerciseGuide {
  final String name;
  final List<String> matchKeywords;
  final String targetMuscles;
  final String emoji;
  final List<String> formPoints;
  final List<String> mistakes;

  /// omercotkd/exercises-gifs CDN 의 GIF ID (예: '0043' → 바벨 스쿼트).
  /// 값이 있으면 가이드 모달 상단에 애니메이션 GIF 표시.
  /// 민권이 홈 탭 프리셋 루틴 상세에서 쓰는 동일 CDN 재사용.
  final String? gifId;

  const ExerciseGuide({
    required this.name,
    required this.matchKeywords,
    required this.targetMuscles,
    required this.emoji,
    required this.formPoints,
    required this.mistakes,
    this.gifId,
  });

  /// 전체 CDN URL — gifId 가 있을 때만 유효.
  String? get gifUrl => gifId == null
      ? null
      : 'https://cdn.jsdelivr.net/gh/omercotkd/exercises-gifs@main/assets/$gifId.gif';
}

/// 20개 핵심 종목 가이드.
const List<ExerciseGuide> kExerciseGuides = [
  // ===== 가슴 =====
  ExerciseGuide(
    name: '벤치 프레스',
    matchKeywords: ['벤치', '벤치프레스', 'bench'],
    targetMuscles: '대흉근 · 삼두근 · 전면 삼각근',
    emoji: '🏋️',
    gifId: '0025',
    formPoints: [
      '어깨뼈를 벤치에 꽉 눌러 고정 후 가슴을 살짝 들어올립니다',
      '바가 쇄골 아래 가슴 중앙에 닿을 때까지 천천히 내립니다',
      '팔꿈치가 45도 각도를 유지하며 바를 밀어올립니다',
    ],
    mistakes: [
      '엉덩이가 벤치에서 뜨지 않도록 주의',
      '팔꿈치가 90도로 벌어지면 어깨 부상 위험',
    ],
  ),
  ExerciseGuide(
    name: '덤벨 플라이',
    matchKeywords: ['플라이', '플라'],
    targetMuscles: '대흉근 (스트레치 자극)',
    emoji: '🤸',
    gifId: '0315',
    formPoints: [
      '팔꿈치를 약간 굽힌 상태로 각도 고정',
      '가슴이 늘어나는 느낌이 들 때까지 벌리고 수축하며 모읍니다',
    ],
    mistakes: [
      '너무 무거운 중량은 어깨 관절에 부담',
      '팔꿈치가 완전히 펴지면 이두 인대 손상 위험',
    ],
  ),
  ExerciseGuide(
    name: '푸시업',
    matchKeywords: ['푸시업', '푸쉬업', 'push'],
    targetMuscles: '대흉근 · 삼두근 · 코어',
    emoji: '💪',
    gifId: '0974',
    formPoints: [
      '손은 어깨너비보다 약간 넓게',
      '머리-엉덩이-발뒤꿈치가 일직선 유지',
      '가슴이 바닥에 거의 닿을 때까지 내립니다',
    ],
    mistakes: [
      '엉덩이 처짐 → 허리 통증',
      '팔꿈치가 완전히 벌어지면 어깨 부상',
    ],
  ),

  // ===== 등 =====
  ExerciseGuide(
    name: '데드리프트',
    matchKeywords: ['데드', '데드리프트', 'dead'],
    targetMuscles: '척추기립근 · 둔근 · 햄스트링 · 광배근',
    emoji: '🏋️‍♂️',
    gifId: '0032',
    formPoints: [
      '발은 어깨너비, 바는 발등 중간 위에 위치',
      '엉덩이를 뒤로 빼면서 상체를 숙여 바를 잡습니다',
      '등은 평평하게 유지한 채 발뒤꿈치로 바닥을 밀며 일어섭니다',
    ],
    mistakes: [
      '등이 둥글게 말리면 디스크 손상 위험',
      '바가 몸에서 멀어지면 허리에 과부하',
    ],
  ),
  ExerciseGuide(
    name: '랫 풀 다운',
    matchKeywords: ['랫풀', '랫 풀', '풀다운', 'lat'],
    targetMuscles: '광배근 · 승모근 하부 · 이두근',
    emoji: '🏋️',
    gifId: '2330',
    formPoints: [
      '바를 어깨너비보다 조금 넓게 오버그립',
      '가슴을 들고 어깨뼈를 내리며 쇄골 쪽으로 당깁니다',
      '정점에서 1초 수축 후 천천히 복귀',
    ],
    mistakes: [
      '상체가 뒤로 과도하게 눕지 않도록 주의',
      '팔로만 당기면 이두에만 자극이 집중됨',
    ],
  ),
  ExerciseGuide(
    name: '바벨 로우',
    matchKeywords: ['로우', '바벨로우', 'row'],
    targetMuscles: '광배근 · 승모근 중부 · 능형근',
    emoji: '🏋️',
    gifId: '0304',
    formPoints: [
      '상체를 45도 숙이고 허리는 평평하게 유지',
      '바를 명치 쪽으로 끌어당깁니다',
      '등 근육의 수축을 느끼며 천천히 복귀',
    ],
    mistakes: [
      '허리로 반동 주면 척추 부상 위험',
      '팔꿈치가 몸에서 멀어지면 등 자극 감소',
    ],
  ),
  ExerciseGuide(
    name: '풀업',
    matchKeywords: ['풀업', '턱걸이', 'pull-up', 'pullup'],
    targetMuscles: '광배근 · 이두근 · 코어',
    emoji: '🤸',
    gifId: '1817',
    formPoints: [
      '오버그립으로 어깨너비보다 약간 넓게',
      '턱이 바를 넘을 때까지 당기고 천천히 내려옵니다',
    ],
    mistakes: [
      '반동으로 올라가면 자극 분산',
      '어깨가 올라가면 승모근에만 집중됨',
    ],
  ),

  // ===== 어깨 =====
  ExerciseGuide(
    name: '오버헤드 프레스',
    matchKeywords: ['오버헤드', '밀리터리', '숄더프레스', '숄더 프레스', 'overhead'],
    targetMuscles: '삼각근 · 삼두근 · 상부 승모근',
    emoji: '🏋️',
    gifId: '0086',
    formPoints: [
      '발은 어깨너비, 코어를 단단히 조입니다',
      '바가 머리 위로 수직 궤적을 그리며 올라갑니다',
      '정점에서 어깨가 귀 옆에 오도록 유지',
    ],
    mistakes: [
      '허리를 과도하게 뒤로 젖히면 허리 부상',
      '바가 앞으로 치우치면 어깨 부상 위험',
    ],
  ),
  ExerciseGuide(
    name: '사이드 레터럴 레이즈',
    matchKeywords: ['사레레', '사이드레이즈', '사이드 레이즈', '레터럴', 'lateral'],
    targetMuscles: '측면 삼각근',
    emoji: '💪',
    gifId: '0313',
    formPoints: [
      '팔꿈치를 약간 굽히고 손목보다 약간 높게 유지',
      '어깨까지 들어올리며 측면 삼각근 수축을 느낍니다',
    ],
    mistakes: [
      '반동으로 올리면 삼각근 자극 X',
      '어깨가 올라가면 승모근 개입',
    ],
  ),

  // ===== 하체 =====
  ExerciseGuide(
    name: '스쿼트',
    matchKeywords: ['스쿼트', 'squat'],
    targetMuscles: '대퇴사두근 · 둔근 · 햄스트링',
    emoji: '🦵',
    gifId: '0043',
    formPoints: [
      '발은 어깨너비, 발끝은 15도 바깥을 향합니다',
      '엉덩이를 뒤로 빼면서 허벅지가 바닥과 평행이 될 때까지 앉습니다',
      '발뒤꿈치로 바닥을 밀며 일어섭니다',
    ],
    mistakes: [
      '무릎이 발끝보다 앞으로 과도하게 나가면 무릎 부상',
      '등이 둥글게 말리면 척추 부상',
    ],
  ),
  ExerciseGuide(
    name: '레그 프레스',
    matchKeywords: ['레그프레스', '레그 프레스', 'leg press'],
    targetMuscles: '대퇴사두근 · 둔근 · 햄스트링',
    emoji: '🦵',
    gifId: '1457',
    formPoints: [
      '발은 어깨너비, 발판 중앙에 위치',
      '무릎이 90도가 될 때까지 천천히 내립니다',
    ],
    mistakes: [
      '무릎이 완전히 펴지면 관절에 부담',
      '엉덩이가 뜨면 허리 부상 위험',
    ],
  ),
  ExerciseGuide(
    name: '런지',
    matchKeywords: ['런지', 'lunge'],
    targetMuscles: '대퇴사두근 · 둔근 · 햄스트링',
    emoji: '🦵',
    gifId: '0607',
    formPoints: [
      '한쪽 발을 크게 앞으로 내딛습니다',
      '뒷무릎이 바닥에 거의 닿을 때까지 내립니다',
      '앞발 발뒤꿈치로 밀어 원위치',
    ],
    mistakes: [
      '앞무릎이 발끝보다 앞으로 나가면 무릎 부상',
      '상체가 앞으로 숙여지면 균형 상실',
    ],
  ),
  ExerciseGuide(
    name: '카프 레이즈',
    matchKeywords: ['카프', '카프레이즈', 'calf'],
    targetMuscles: '비복근 · 가자미근',
    emoji: '🦵',
    gifId: '0968',
    formPoints: [
      '발뒤꿈치를 최대한 높이 들어올립니다',
      '정점에서 1초 수축 후 천천히 내립니다',
    ],
    mistakes: [
      '반동으로 하면 종아리 자극 분산',
    ],
  ),

  // ===== 팔 =====
  ExerciseGuide(
    name: '덤벨 컬',
    matchKeywords: ['덤벨컬', '덤벨 컬', '바이셉'],
    targetMuscles: '이두근 · 전완근',
    emoji: '💪',
    gifId: '0290',
    formPoints: [
      '팔꿈치를 몸통에 고정',
      '손목을 뒤집으며 어깨 쪽으로 들어올립니다',
      '천천히 내리며 원심성 수축에 집중',
    ],
    mistakes: [
      '반동 사용 X',
      '팔꿈치가 앞으로 나오면 전면 삼각근으로 자극 분산',
    ],
  ),
  ExerciseGuide(
    name: '바벨 컬',
    matchKeywords: ['바벨컬', '바벨 컬', 'barbell curl'],
    targetMuscles: '이두근',
    emoji: '💪',
    gifId: '0033',
    formPoints: [
      '어깨너비 언더그립으로 바를 잡습니다',
      '팔꿈치 고정하고 들어올립니다',
    ],
    mistakes: [
      '허리로 반동 금지',
    ],
  ),
  ExerciseGuide(
    name: '트라이셉스 익스텐션',
    matchKeywords: ['트라이셉스', '익스텐션', '삼두', 'tricep'],
    targetMuscles: '삼두근',
    emoji: '💪',
    gifId: '0351',
    formPoints: [
      '팔꿈치를 머리 옆에 고정',
      '팔꿈치만 굽혔다 펴며 삼두를 수축합니다',
    ],
    mistakes: [
      '팔꿈치가 벌어지면 삼두 자극 X',
    ],
  ),
  ExerciseGuide(
    name: '딥스',
    matchKeywords: ['딥스', 'dips'],
    targetMuscles: '삼두근 · 대흉근 하부',
    emoji: '💪',
    gifId: '0287',
    formPoints: [
      '팔꿈치가 90도가 될 때까지 내립니다',
      '어깨가 올라가지 않도록 유지',
    ],
    mistakes: [
      '너무 깊이 내리면 어깨 부상 위험',
    ],
  ),

  // ===== 코어 =====
  ExerciseGuide(
    name: '플랭크',
    matchKeywords: ['플랭크', 'plank'],
    targetMuscles: '복근 · 코어 전체',
    emoji: '🧘',
    gifId: '0973',
    formPoints: [
      '머리-엉덩이-발뒤꿈치가 일직선',
      '배꼽을 척추 쪽으로 당기듯 코어 유지',
    ],
    mistakes: [
      '엉덩이 올라감 → 자극 분산',
      '허리 처짐 → 척추 부상',
    ],
  ),
  ExerciseGuide(
    name: '크런치',
    matchKeywords: ['크런치', 'crunch'],
    targetMuscles: '복직근 상부',
    emoji: '🧘',
    gifId: '0233',
    formPoints: [
      '손은 머리 뒤 또는 가슴 위',
      '복근 수축으로 상체를 들어올립니다',
    ],
    mistakes: [
      '목으로 당기면 경추 부상',
    ],
  ),

  // ===== 유산소 =====
  ExerciseGuide(
    name: '러닝',
    matchKeywords: ['러닝', '달리기', 'running', 'run'],
    targetMuscles: '하체 전반 · 심폐지구력',
    emoji: '🏃',
    gifId: '1660',
    formPoints: [
      '발 전체로 착지, 발뒤꿈치부터 발끝 순서',
      '팔을 90도로 가볍게 흔듭니다',
      '시선은 전방 10m 앞',
    ],
    mistakes: [
      '발뒤꿈치만 착지 → 무릎 충격',
      '상체 흔들림 → 에너지 낭비',
    ],
  ),
];

/// 운동 종목명으로 가이드 매칭 (대소문자 무시, 부분 일치).
ExerciseGuide? findExerciseGuide(String exerciseName) {
  final lower = exerciseName.toLowerCase();
  for (final guide in kExerciseGuides) {
    for (final keyword in guide.matchKeywords) {
      if (lower.contains(keyword.toLowerCase())) {
        return guide;
      }
    }
  }
  return null;
}
