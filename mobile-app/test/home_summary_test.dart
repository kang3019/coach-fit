import 'package:coachfit_mobile/models/workout.dart';
import 'package:coachfit_mobile/widgets/home/home_summary.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Workout workout(DateTime date, double weight) {
    return Workout(
      userId: 'test-user',
      exerciseName: '테스트 운동',
      sets: 1,
      reps: 10,
      weight: weight,
      workoutDate: date,
    );
  }

  test('실제 운동 기록으로 주간 리듬과 성장률을 계산한다', () {
    final summary = HomeSummary.fromWorkouts(
      nickname: '코치핏',
      now: DateTime(2025, 6, 15),
      workouts: [
        workout(DateTime(2025, 6, 9), 10),
        workout(DateTime(2025, 6, 11), 10),
        workout(DateTime(2025, 6, 14), 10),
        workout(DateTime(2025, 6, 2), 10),
      ],
    );

    expect(summary.nickname, '코치핏');
    expect(summary.completedDays, [true, false, true, false, false, true, false]);
    expect(summary.currentWeeklyWorkouts, 3);
    expect(summary.remainingWorkouts, 1);
    expect(summary.streakDays, 1);
    expect(summary.growthLabel, '+200% 성장');
    expect(summary.recoveryStatus, '회복 중');
  });

  test('운동 기록이 없는 신규 사용자를 안전하게 표시한다', () {
    final summary = HomeSummary.fromWorkouts(
      nickname: '',
      workouts: const [],
      now: DateTime(2025, 6, 15),
    );

    expect(summary.nickname, '회원');
    expect(summary.currentWeeklyWorkouts, 0);
    expect(summary.streakDays, 0);
    expect(summary.growthLabel, '기록 쌓는 중');
    expect(summary.recoveryStatus, '첫 운동 준비');
  });
}
