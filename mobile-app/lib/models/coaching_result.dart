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
