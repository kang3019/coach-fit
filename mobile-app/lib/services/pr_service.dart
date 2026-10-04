import '../models/workout.dart';

/// Personal Record (개인 최고기록) 계산 유틸리티.
/// 운동 기록 리스트에서 종목별 역대 최고 중량 / 1세트 최대 볼륨 을 산출한다.
///
/// 서버에 저장하지 않고 매번 전체 기록을 재집계 — 2인 프로젝트 규모에선
/// 충분히 빠르고 백엔드 변경이 필요 없다.
class PrService {
  /// 종목별 역대 최고 중량.
  /// 예: { "벤치프레스": 80.0, "스쿼트": 120.0, ... }
  Map<String, double> maxWeightByExercise(List<Workout> all) {
    final map = <String, double>{};
    for (final w in all) {
      final cur = map[w.exerciseName] ?? 0;
      if (w.weight > cur) map[w.exerciseName] = w.weight;
    }
    return map;
  }

  /// 종목별 역대 최대 세트 볼륨 (단일 세트의 weight × reps 가 아니라
  /// 전체 세션의 볼륨 weight × sets × reps 기준).
  Map<String, double> maxVolumeByExercise(List<Workout> all) {
    final map = <String, double>{};
    for (final w in all) {
      final cur = map[w.exerciseName] ?? 0;
      if (w.volume > cur) map[w.exerciseName] = w.volume;
    }
    return map;
  }

  /// 주어진 workout 이 해당 종목의 역대 PR 인지 판정.
  /// 반환값:
  ///   - PrResult.record : 역대 최고 중량 갱신
  ///   - PrResult.volumeRecord : 중량 PR 은 아니지만 볼륨 PR
  ///   - PrResult.none : 신기록 아님
  PrResult evaluate(Workout newWorkout, List<Workout> history) {
    final sameName = history
        .where((w) =>
            w.exerciseName == newWorkout.exerciseName && w.id != newWorkout.id)
        .toList();
    if (sameName.isEmpty) return PrResult.firstTime;
    final prevMaxWeight =
        sameName.map((w) => w.weight).fold<double>(0, (a, b) => a > b ? a : b);
    final prevMaxVolume =
        sameName.map((w) => w.volume).fold<double>(0, (a, b) => a > b ? a : b);
    if (newWorkout.weight > prevMaxWeight) {
      return PrResult.weightRecord(previous: prevMaxWeight);
    }
    if (newWorkout.volume > prevMaxVolume) {
      return PrResult.volumeRecord(previous: prevMaxVolume);
    }
    return PrResult.none;
  }
}

/// PR 평가 결과.
sealed class PrResult {
  const PrResult();
  static const PrResult none = _PrNone();
  static const PrResult firstTime = _PrFirst();
  // ignore: non_constant_identifier_names
  static PrResult weightRecord({required double previous}) =>
      _PrWeightRecord(previous: previous);
  static PrResult volumeRecord({required double previous}) =>
      _PrVolumeRecord(previous: previous);
}

class _PrNone extends PrResult {
  const _PrNone();
}

class _PrFirst extends PrResult {
  const _PrFirst();
}

class _PrWeightRecord extends PrResult {
  final double previous;
  const _PrWeightRecord({required this.previous});
}

class _PrVolumeRecord extends PrResult {
  final double previous;
  const _PrVolumeRecord({required this.previous});
}

/// UI 레이어가 쉽게 쓸 수 있도록 PrResult 를 한국어 메시지로 변환.
extension PrResultMessage on PrResult {
  bool get isRecord =>
      this is _PrWeightRecord || this is _PrVolumeRecord || this is _PrFirst;

  String get title {
    switch (this) {
      case _PrWeightRecord():
        return '🏆 역대 최고 중량!';
      case _PrVolumeRecord():
        return '🥇 역대 최고 볼륨!';
      case _PrFirst():
        return '🎉 첫 기록!';
      case _PrNone():
        return '';
    }
  }

  String? get subtitle {
    switch (this) {
      case _PrWeightRecord(:final previous):
        return '이전 최고: ${_fmt(previous)} kg';
      case _PrVolumeRecord(:final previous):
        return '이전 최고 볼륨: ${_fmt(previous)} kg';
      case _PrFirst():
        return '이 종목 첫 기록이에요';
      case _PrNone():
        return null;
    }
  }

  static String _fmt(double v) =>
      v % 1 == 0 ? v.toInt().toString() : v.toStringAsFixed(1);
}
