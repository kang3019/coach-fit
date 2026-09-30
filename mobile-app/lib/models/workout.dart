import 'package:intl/intl.dart';

/// Java `WorkoutResponse` DTO에 대응하는 클라이언트 모델.
/// 등록(POST)과 조회(GET) 양쪽에서 재사용한다.
class Workout {
  final int? id;
  final String userId;
  final String exerciseName;
  final int sets;
  final int reps;
  final double weight;
  final DateTime workoutDate;
  final String? memo;
  final DateTime? createdAt;

  Workout({
    this.id,
    required this.userId,
    required this.exerciseName,
    required this.sets,
    required this.reps,
    required this.weight,
    required this.workoutDate,
    this.memo,
    this.createdAt,
  });

  double get volume => weight * sets * reps;

  static final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');

  factory Workout.fromJson(Map<String, dynamic> json) {
    return Workout(
      id: json['id'] as int?,
      userId: (json['userId'] ?? 'user_01') as String,
      exerciseName: json['exerciseName'] as String,
      sets: (json['sets'] as num).toInt(),
      reps: (json['reps'] as num).toInt(),
      weight: (json['weight'] as num).toDouble(),
      workoutDate: DateTime.parse(json['workoutDate'] as String),
      memo: json['memo'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
    );
  }

  /// POST /api/workouts 요청 바디용 (id / createdAt 제외).
  Map<String, dynamic> toCreateJson() {
    return {
      'userId': userId,
      'exerciseName': exerciseName,
      'sets': sets,
      'reps': reps,
      'weight': weight,
      'workoutDate': _dateFormat.format(workoutDate),
      if (memo != null && memo!.isNotEmpty) 'memo': memo,
    };
  }
}
