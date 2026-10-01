/// 사용자 프로필 (로컬 저장용 — 백엔드에 전송 X).
/// 메뉴 탭 상단 카드 및 "신체 스펙" 그리드를 이 모델로 바인딩한다.
class UserProfile {
  final String nickname;
  final Gender gender;
  final double? heightCm;
  final double? weightKg;
  final double? targetWeightKg;
  final ExperienceLevel experience;

  const UserProfile({
    required this.nickname,
    this.gender = Gender.undisclosed,
    this.heightCm,
    this.weightKg,
    this.targetWeightKg,
    this.experience = ExperienceLevel.beginner,
  });

  /// 저장된 프로필이 없을 때 사용할 기본 값.
  factory UserProfile.defaultProfile() => const UserProfile(nickname: '김운동');

  UserProfile copyWith({
    String? nickname,
    Gender? gender,
    double? heightCm,
    double? weightKg,
    double? targetWeightKg,
    ExperienceLevel? experience,
  }) {
    return UserProfile(
      nickname: nickname ?? this.nickname,
      gender: gender ?? this.gender,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      targetWeightKg: targetWeightKg ?? this.targetWeightKg,
      experience: experience ?? this.experience,
    );
  }

  Map<String, dynamic> toJson() => {
        'nickname': nickname,
        'gender': gender.name,
        if (heightCm != null) 'heightCm': heightCm,
        if (weightKg != null) 'weightKg': weightKg,
        if (targetWeightKg != null) 'targetWeightKg': targetWeightKg,
        'experience': experience.name,
      };

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      nickname: (json['nickname'] as String?)?.trim().isNotEmpty == true
          ? json['nickname'] as String
          : '김운동',
      gender: Gender.values.firstWhere(
        (g) => g.name == json['gender'],
        orElse: () => Gender.undisclosed,
      ),
      heightCm: (json['heightCm'] as num?)?.toDouble(),
      weightKg: (json['weightKg'] as num?)?.toDouble(),
      targetWeightKg: (json['targetWeightKg'] as num?)?.toDouble(),
      experience: ExperienceLevel.values.firstWhere(
        (e) => e.name == json['experience'],
        orElse: () => ExperienceLevel.beginner,
      ),
    );
  }
}

enum Gender { male, female, undisclosed }

extension GenderExtension on Gender {
  String get label {
    switch (this) {
      case Gender.male:
        return '남성';
      case Gender.female:
        return '여성';
      case Gender.undisclosed:
        return '비공개';
    }
  }
}

enum ExperienceLevel { beginner, intermediate, advanced }

extension ExperienceLevelExtension on ExperienceLevel {
  String get label {
    switch (this) {
      case ExperienceLevel.beginner:
        return '초급';
      case ExperienceLevel.intermediate:
        return '중급';
      case ExperienceLevel.advanced:
        return '고급';
    }
  }

  String get description {
    switch (this) {
      case ExperienceLevel.beginner:
        return '6개월 미만';
      case ExperienceLevel.intermediate:
        return '6개월 ~ 2년';
      case ExperienceLevel.advanced:
        return '2년 이상';
    }
  }
}
