import '../models/user_profile.dart';
import '../models/workout.dart';

/// 루틴 시작 시 종목별 시작 무게를 정한다.
/// 1순위: 해당 종목의 가장 최근 기록 무게, 2순위: 체중·경력 기반 추정치.
abstract final class StartWeightService {
  static const double _defaultBodyWeightKg = 65;

  static const List<String> _bodyweightKeywords = [
    '푸쉬업',
    '푸시업',
    '풀업',
    '턱걸이',
    '딥스',
    '플랭크',
    '크런치',
    '레그레이즈',
    '버피',
    '맨몸',
  ];

  // 체중 대비 초급자 기준 비율. 위에서부터 먼저 일치하는 키워드를 사용한다.
  static const Map<String, double> _ratios = {
    '데드리프트': 0.6,
    '스쿼트': 0.5,
    '레그프레스': 0.8,
    '벤치': 0.4,
    '숄더프레스': 0.25,
    '오버헤드': 0.25,
    '덤벨': 0.12,
    '랫풀다운': 0.35,
    '풀다운': 0.35,
    '로우': 0.3,
    '푸쉬다운': 0.12,
    '익스텐션': 0.12,
    '킥백': 0.08,
    '레이즈': 0.06,
    '컬': 0.1,
  };

  static Workout? latestRecord(List<Workout> history, String exerciseName) {
    Workout? latest;
    for (final w in history) {
      if (w.exerciseName != exerciseName) continue;
      if (latest == null || _isNewer(w, latest)) latest = w;
    }
    return latest;
  }

  static double? recentWeight(List<Workout> history, String exerciseName) =>
      latestRecord(history, exerciseName)?.weight;

  static bool _isNewer(Workout a, Workout b) {
    if (a.workoutDate != b.workoutDate) {
      return a.workoutDate.isAfter(b.workoutDate);
    }
    final aCreated = a.createdAt;
    final bCreated = b.createdAt;
    if (aCreated != null && bCreated != null) {
      return aCreated.isAfter(bCreated);
    }
    return (a.id ?? 0) > (b.id ?? 0);
  }

  static double fromBodySpec({
    required String exerciseName,
    required UserProfile profile,
  }) {
    for (final keyword in _bodyweightKeywords) {
      if (exerciseName.contains(keyword)) return 0;
    }

    var ratio = 0.2;
    for (final entry in _ratios.entries) {
      if (exerciseName.contains(entry.key)) {
        ratio = entry.value;
        break;
      }
    }

    final experienceFactor = switch (profile.experience) {
      ExperienceLevel.beginner => 1.0,
      ExperienceLevel.intermediate => 1.4,
      ExperienceLevel.advanced => 1.8,
    };
    final genderFactor = profile.gender == Gender.female ? 0.7 : 1.0;
    final bodyWeight = profile.weightKg ?? _defaultBodyWeightKg;

    final raw = bodyWeight * ratio * experienceFactor * genderFactor;
    final rounded = (raw / 2.5).round() * 2.5;
    return rounded.clamp(2.5, 200.0).toDouble();
  }
}
