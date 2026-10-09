import '../../models/workout.dart';

/// 홈 화면에서 사용하는 프로필 및 운동 기록 기반 요약 데이터.
class HomeSummary {
  static const int defaultWeeklyTarget = 4;

  final String nickname;
  final List<bool> completedDays;
  final int todayIndex;
  final int currentWeeklyWorkouts;
  final int targetWeeklyWorkouts;
  final int streakDays;
  final String growthLabel;
  final String recoveryStatus;
  final String recoveryMessage;

  const HomeSummary({
    required this.nickname,
    required this.completedDays,
    required this.todayIndex,
    required this.currentWeeklyWorkouts,
    required this.targetWeeklyWorkouts,
    required this.streakDays,
    required this.growthLabel,
    required this.recoveryStatus,
    required this.recoveryMessage,
  });

  int get remainingWorkouts => (targetWeeklyWorkouts - currentWeeklyWorkouts)
      .clamp(0, targetWeeklyWorkouts)
      .toInt();

  factory HomeSummary.loading({DateTime? now}) {
    final currentDate = now ?? DateTime.now();
    return HomeSummary(
      nickname: '회원',
      completedDays: const [false, false, false, false, false, false, false],
      todayIndex: currentDate.weekday - 1,
      currentWeeklyWorkouts: 0,
      targetWeeklyWorkouts: defaultWeeklyTarget,
      streakDays: 0,
      growthLabel: '기록 확인 중',
      recoveryStatus: '상태 확인 중',
      recoveryMessage: '운동 기록을 바탕으로 오늘의 플랜을 준비하고 있어요.',
    );
  }

  factory HomeSummary.fromWorkouts({
    required String nickname,
    required List<Workout> workouts,
    required DateTime now,
  }) {
    final today = DateTime(now.year, now.month, now.day);
    final startOfWeek = today.subtract(Duration(days: now.weekday - 1));
    final startOfPreviousWeek = startOfWeek.subtract(const Duration(days: 7));
    final workoutDates = workouts
        .map(
          (workout) => DateTime(
            workout.workoutDate.year,
            workout.workoutDate.month,
            workout.workoutDate.day,
          ),
        )
        .toSet();
    final completedDays = List<bool>.generate(
      7,
      (index) => workoutDates.contains(startOfWeek.add(Duration(days: index))),
    );
    final currentVolume = _volumeBetween(
      workouts,
      startOfWeek,
      startOfWeek.add(const Duration(days: 7)),
    );
    final previousVolume = _volumeBetween(
      workouts,
      startOfPreviousWeek,
      startOfWeek,
    );
    final latestDate = workoutDates.isEmpty
        ? null
        : workoutDates.reduce((a, b) => a.isAfter(b) ? a : b);
    final daysSinceWorkout =
        latestDate == null ? null : today.difference(latestDate).inDays;

    return HomeSummary(
      nickname: nickname.trim().isEmpty ? '회원' : nickname.trim(),
      completedDays: completedDays,
      todayIndex: now.weekday - 1,
      currentWeeklyWorkouts:
          completedDays.where((completed) => completed).length,
      targetWeeklyWorkouts: defaultWeeklyTarget,
      streakDays: _calculateStreak(workoutDates, today),
      growthLabel: _growthLabel(currentVolume, previousVolume),
      recoveryStatus: _recoveryStatus(daysSinceWorkout),
      recoveryMessage: _recoveryMessage(daysSinceWorkout),
    );
  }

  static double _volumeBetween(
    List<Workout> workouts,
    DateTime start,
    DateTime end,
  ) {
    return workouts.where((workout) {
      final date = workout.workoutDate;
      return !date.isBefore(start) && date.isBefore(end);
    }).fold(0, (sum, workout) => sum + workout.volume);
  }

  static int _calculateStreak(Set<DateTime> workoutDates, DateTime today) {
    if (workoutDates.isEmpty) return 0;
    var cursor = workoutDates.contains(today)
        ? today
        : today.subtract(const Duration(days: 1));
    var streak = 0;
    while (workoutDates.contains(cursor)) {
      streak += 1;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  static String _growthLabel(double current, double previous) {
    if (previous <= 0) return current > 0 ? '이번 주 시작' : '기록 쌓는 중';
    final rate = ((current - previous) / previous * 100).round();
    return '${rate >= 0 ? '+' : ''}$rate% ${rate >= 0 ? '성장' : '조절'}';
  }

  static String _recoveryStatus(int? days) {
    if (days == null) return '첫 운동 준비';
    if (days >= 2) return '회복 완료';
    if (days == 1) return '회복 중';
    return '오늘 운동 완료';
  }

  static String _recoveryMessage(int? days) {
    if (days == null) return '첫 기록을 시작하면 회복 리듬을 함께 분석해 드려요.';
    if (days >= 2) {
      return '지난 운동 후 ${days * 24}시간이 지났어요.\n'
          '지금이 다시 자극하기 좋은 타이밍이에요.';
    }
    if (days == 1) {
      return '어제 운동을 잘 마쳤어요.\n'
          '오늘 컨디션에 맞춰 강도를 조절해 보세요.';
    }
    return '오늘 운동을 완료했어요.\n충분한 휴식과 영양으로 회복해 주세요.';
  }
}
