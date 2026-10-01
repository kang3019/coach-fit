/// 운동 종목 마스터 데이터 모델 (사진, 부위, 장비, 타겟 근육 포함)
class ExerciseMaster {
  final int id;
  final String name;
  final String? englishName;
  final String category;
  final String equipment;
  final String targetMuscle;
  final String? imageUrl;
  final String? instructions;

  ExerciseMaster({
    required this.id,
    required this.name,
    this.englishName,
    required this.category,
    required this.equipment,
    required this.targetMuscle,
    this.imageUrl,
    this.instructions,
  });

  factory ExerciseMaster.fromJson(Map<String, dynamic> json) {
    return ExerciseMaster(
      id: (json['id'] as num).toInt(),
      name: (json['name'] ?? '') as String,
      englishName: json['englishName'] as String?,
      category: (json['category'] ?? '기타') as String,
      equipment: (json['equipment'] ?? '맨몸') as String,
      targetMuscle: (json['targetMuscle'] ?? '') as String,
      imageUrl: json['imageUrl'] as String?,
      instructions: json['instructions'] as String?,
    );
  }
}
