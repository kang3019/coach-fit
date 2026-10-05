import '../models/workout.dart';

/// 1개 업적 정의.
class Achievement {
  final String id;
  final String emoji;
  final String title;
  final String description;
  final bool unlocked;
  final int progress;
  final int target;

  const Achievement({
    required this.id,
    required this.emoji,
    required this.title,
    required this.description,
    required this.unlocked,
    required this.progress,
    required this.target,
  });

  double get ratio => target == 0 ? 0 : (progress / target).clamp(0.0, 1.0);
}

/// (E) 업적/뱃지 계산 서비스.
/// 운동 기록 리스트를 입력받아 10개 업적의 달성 여부와 진행도를 반환.
///
/// stateless 유틸 — 저장소 안 씀. 호출 시마다 즉시 계산.
class AchievementService {
  static List<Achievement> computeAll(List<Workout> workouts) {
    final totalCount = workouts.length;
    final totalVolume =
        workouts.fold<double>(0, (sum, w) => sum + w.volume);
    final maxBench = _maxWeightOf(workouts, ['벤치', 'bench', '벤치프레스']);
    final maxSquat = _maxWeightOf(workouts, ['스쿼트', 'squat']);
    final maxDead = _maxWeightOf(workouts, ['데드', 'dead', '데드리프트']);
    final longestStreak = _computeLongestStreak(workouts);
    final currentStreak = _computeCurrentStreak(workouts);
    final uniqueExercises =
        workouts.map((w) => w.exerciseName.trim()).toSet().length;
    final morningCount =
        workouts.where((w) => _isMorning(w.createdAt ?? w.workoutDate)).length;
    final nightCount =
        workouts.where((w) => _isNight(w.createdAt ?? w.workoutDate)).length;

    return [
      _ach(
        id: 'first_workout',
        emoji: '🎉',
        title: '첫 운동 시작',
        description: '첫 번째 운동 기록 작성',
        progress: totalCount.clamp(0, 1),
        target: 1,
      ),
      _ach(
        id: 'ten_workouts',
        emoji: '💪',
        title: '꾸준한 열정',
        description: '총 10회 운동 완료',
        progress: totalCount,
        target: 10,
      ),
      _ach(
        id: 'hundred_workouts',
        emoji: '🏆',
        title: '백번의 땀',
        description: '총 100회 운동 완료',
        progress: totalCount,
        target: 100,
      ),
      _ach(
        id: 'streak_7',
        emoji: '🔥',
        title: '불타는 일주일',
        description: '7일 연속 운동',
        progress: longestStreak,
        target: 7,
      ),
      _ach(
        id: 'streak_30',
        emoji: '🚀',
        title: '한 달 연속의 신',
        description: '30일 연속 운동',
        progress: longestStreak,
        target: 30,
      ),
      _ach(
        id: 'volume_100k',
        emoji: '📈',
        title: '총 10만kg 돌파',
        description: '누적 볼륨 100,000kg',
        progress: totalVolume.toInt(),
        target: 100000,
      ),
      _ach(
        id: 'bench_100',
        emoji: '💯',
        title: '벤치 100kg 클럽',
        description: '벤치프레스 100kg 1회 성공',
        progress: maxBench.toInt(),
        target: 100,
      ),
      _ach(
        id: 'squat_140',
        emoji: '🦵',
        title: '스쿼트 140kg',
        description: '스쿼트 140kg 1회 성공',
        progress: maxSquat.toInt(),
        target: 140,
      ),
      _ach(
        id: 'dead_180',
        emoji: '🏋️',
        title: '데드 180kg',
        description: '데드리프트 180kg 1회 성공',
        progress: maxDead.toInt(),
        target: 180,
      ),
      _ach(
        id: 'variety_20',
        emoji: '🎨',
        title: '다재다능',
        description: '서로 다른 종목 20개 수행',
        progress: uniqueExercises,
        target: 20,
      ),
      _ach(
        id: 'early_bird',
        emoji: '🌅',
        title: '아침형 인간',
        description: '오전 6~9시 운동 5회',
        progress: morningCount,
        target: 5,
      ),
      _ach(
        id: 'night_owl',
        emoji: '🌙',
        title: '야행성',
        description: '밤 10시 이후 운동 5회',
        progress: nightCount,
        target: 5,
      ),
      _ach(
        id: 'current_streak_3',
        emoji: '⚡',
        title: '리듬 유지',
        description: '현재 3일 연속 운동 중',
        progress: currentStreak,
        target: 3,
      ),
    ];
  }

  // ===== helpers =====

  static Achievement _ach({
    required String id,
    required String emoji,
    required String title,
    required String description,
    required int progress,
    required int target,
  }) {
    final p = progress.clamp(0, target);
    return Achievement(
      id: id,
      emoji: emoji,
      title: title,
      description: description,
      unlocked: p >= target,
      progress: p,
      target: target,
    );
  }

  static double _maxWeightOf(List<Workout> ws, List<String> keywords) {
    double best = 0;
    for (final w in ws) {
      final lower = w.exerciseName.toLowerCase();
      if (keywords.any((k) => lower.contains(k.toLowerCase()))) {
        if (w.weight > best) best = w.weight;
      }
    }
    return best;
  }

  static bool _isMorning(DateTime t) => t.hour >= 6 && t.hour < 9;
  static bool _isNight(DateTime t) => t.hour >= 22 || t.hour < 2;

  static int _computeLongestStreak(List<Workout> workouts) {
    if (workouts.isEmpty) return 0;
    final days = workouts
        .map((w) => DateTime(
            w.workoutDate.year, w.workoutDate.month, w.workoutDate.day))
        .toSet()
        .toList()
      ..sort();
    if (days.isEmpty) return 0;
    int best = 1;
    int cur = 1;
    for (int i = 1; i < days.length; i++) {
      if (days[i].difference(days[i - 1]).inDays == 1) {
        cur++;
        if (cur > best) best = cur;
      } else {
        cur = 1;
      }
    }
    return best;
  }

  static int _computeCurrentStreak(List<Workout> workouts) {
    if (workouts.isEmpty) return 0;
    final today = DateTime.now();
    final today0 = DateTime(today.year, today.month, today.day);
    final daySet = workouts
        .map((w) => DateTime(
            w.workoutDate.year, w.workoutDate.month, w.workoutDate.day))
        .toSet();
    if (!daySet.contains(today0) &&
        !daySet.contains(today0.subtract(const Duration(days: 1)))) {
      return 0;
    }
    int streak = 0;
    DateTime cursor = daySet.contains(today0)
        ? today0
        : today0.subtract(const Duration(days: 1));
    while (daySet.contains(cursor)) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }
}
