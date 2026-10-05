from datetime import date as dt_date, datetime as dt_datetime
from typing import List, Optional, Dict, Any
from pydantic import BaseModel, Field


# ==========================================
# 1. 운동 기록(Workout) 관련 스키마 (CRUD)
# ==========================================

class WorkoutCreate(BaseModel):
    user_id: str = Field(default="user_01", validation_alias="userId", serialization_alias="userId")
    exercise_name: str = Field(..., validation_alias="exerciseName", serialization_alias="exerciseName")
    sets: int = Field(..., ge=1)
    reps: int = Field(..., ge=1)
    weight: float = Field(..., ge=0.0)
    workout_date: Optional[dt_date] = Field(default=None, validation_alias="workoutDate", serialization_alias="workoutDate")
    memo: Optional[str] = None

    model_config = {
        "populate_by_name": True,
        "from_attributes": True,
    }


class WorkoutResponse(BaseModel):
    id: int
    user_id: str = Field(..., validation_alias="userId", serialization_alias="userId")
    exercise_name: str = Field(..., validation_alias="exerciseName", serialization_alias="exerciseName")
    sets: int
    reps: int
    weight: float
    workout_date: dt_date = Field(..., validation_alias="workoutDate", serialization_alias="workoutDate")
    memo: Optional[str] = None
    created_at: Optional[dt_datetime] = Field(default=None, validation_alias="createdAt", serialization_alias="createdAt")

    model_config = {
        "populate_by_name": True,
        "from_attributes": True,
    }


class WeeklyStatsResponse(BaseModel):
    user_id: str = Field(..., validation_alias="userId", serialization_alias="userId")
    total_records: int = Field(..., validation_alias="totalRecords", serialization_alias="totalRecords")
    weekly_volume_by_day: Dict[str, float] = Field(..., validation_alias="weeklyVolumeByDay", serialization_alias="weeklyVolumeByDay")

    model_config = {
        "populate_by_name": True,
    }


# ==========================================
# 2. AI 코칭 관련 스키마
# ==========================================

class WorkoutItem(BaseModel):
    exercise_name: str = Field(..., description="운동 종목 이름 (예: 벤치프레스, 스쿼트 등)")
    sets: int = Field(..., ge=1, description="수행 세트 수")
    reps: int = Field(..., ge=1, description="세트당 반복 횟수")
    weight: float = Field(..., ge=0.0, description="중량 (kg)")
    date: Optional[dt_date] = Field(default=None, description="운동 수행 일자")


class CoachingGenerateRequest(BaseModel):
    user_id: Optional[str] = Field(default="user_01", validation_alias="userId")
    goal: Optional[str] = Field(default="근비대 및 전신 근력 증진")

    model_config = {
        "populate_by_name": True,
    }


class CoachingRequest(BaseModel):
    user_id: str = Field(default="user_01", description="사용자 식별자")
    user_goal: Optional[str] = Field(default="근비대 및 전신 근력 증진", description="사용자의 현재 운동 목표")
    user_profile: Optional[Dict[str, Any]] = Field(
        default=None,
        description="사용자 신체 스펙 (키, 체중, 골격근량, 체지방률, 경력 등)"
    )
    recent_workouts: List[WorkoutItem] = Field(default_factory=list, description="최근 운동 기록 목록")


class RecommendedRoutineItem(BaseModel):
    exercise_name: str = Field(..., description="추천 운동 종목")
    sets: int = Field(..., description="권장 세트 수")
    reps: int = Field(..., description="권장 횟수")
    focus: str = Field(..., description="타겟 부위 및 운동 목적")
    tip: str = Field(..., description="코치의 자세 및 안전 팁")


class CoachingResponse(BaseModel):
    summary: str = Field(..., description="최근 운동 기록 분석 및 상태 요약")
    coaching_advice: str = Field(..., description="AI 코치의 개인 맞춤 피드백 및 조언")
    recommended_routine: List[RecommendedRoutineItem] = Field(..., description="오늘 수행할 추천 운동 루틴 목록")
    generated_at: str = Field(default_factory=lambda: dt_datetime.now().isoformat(), description="응답 생성 시각")


# ==========================================
# 3. 신체 측정(BodyMetric) 관련 스키마
# ==========================================

class BodyMetricCreate(BaseModel):
    user_id: str = Field(default="user_01", validation_alias="userId", serialization_alias="userId")
    metric_date: Optional[dt_date] = Field(default=None, validation_alias="date", serialization_alias="date")
    weight_kg: Optional[float] = Field(default=None, validation_alias="weightKg", serialization_alias="weightKg")
    muscle_kg: Optional[float] = Field(default=None, validation_alias="muscleKg", serialization_alias="muscleKg")
    body_fat_percent: Optional[float] = Field(default=None, validation_alias="bodyFatPercent", serialization_alias="bodyFatPercent")

    model_config = {
        "populate_by_name": True,
        "from_attributes": True,
    }


class BodyMetricResponse(BaseModel):
    id: int
    user_id: str = Field(..., validation_alias="userId", serialization_alias="userId")
    metric_date: dt_date = Field(..., validation_alias="date", serialization_alias="date")
    weight_kg: Optional[float] = Field(default=None, validation_alias="weightKg", serialization_alias="weightKg")
    muscle_kg: Optional[float] = Field(default=None, validation_alias="muscleKg", serialization_alias="muscleKg")
    body_fat_percent: Optional[float] = Field(default=None, validation_alias="bodyFatPercent", serialization_alias="bodyFatPercent")
    created_at: Optional[dt_datetime] = Field(default=None, validation_alias="createdAt", serialization_alias="createdAt")

    model_config = {
        "populate_by_name": True,
        "from_attributes": True,
    }


# ==========================================
# 4. 사용자 프로필(UserProfile) 관련 스키마
# ==========================================

class UserProfileUpdate(BaseModel):
    user_id: str = Field(default="user_01", validation_alias="userId", serialization_alias="userId")
    nickname: Optional[str] = None
    gender: Optional[str] = None
    height_cm: Optional[float] = Field(default=None, validation_alias="heightCm", serialization_alias="heightCm")
    weight_kg: Optional[float] = Field(default=None, validation_alias="weightKg", serialization_alias="weightKg")
    target_weight_kg: Optional[float] = Field(default=None, validation_alias="targetWeightKg", serialization_alias="targetWeightKg")
    experience: Optional[str] = None
    workout_goal: Optional[str] = Field(default=None, validation_alias="workoutGoal", serialization_alias="workoutGoal")

    model_config = {
        "populate_by_name": True,
        "from_attributes": True,
    }


class UserProfileResponse(BaseModel):
    user_id: str = Field(..., validation_alias="userId", serialization_alias="userId")
    nickname: str
    gender: str
    height_cm: Optional[float] = Field(default=None, validation_alias="heightCm", serialization_alias="heightCm")
    weight_kg: Optional[float] = Field(default=None, validation_alias="weightKg", serialization_alias="weightKg")
    target_weight_kg: Optional[float] = Field(default=None, validation_alias="targetWeightKg", serialization_alias="targetWeightKg")
    experience: str
    workout_goal: str = Field(..., validation_alias="workoutGoal", serialization_alias="workoutGoal")
    updated_at: Optional[dt_datetime] = Field(default=None, validation_alias="updatedAt", serialization_alias="updatedAt")

    model_config = {
        "populate_by_name": True,
        "from_attributes": True,
    }


# ==========================================
# 5. 운동 종목 마스터(Exercise Master) 스키마
# ==========================================

class ExerciseResponse(BaseModel):
    id: int
    name: str
    english_name: Optional[str] = Field(default=None, validation_alias="englishName", serialization_alias="englishName")
    category: str
    equipment: str
    target_muscle: str = Field(..., validation_alias="targetMuscle", serialization_alias="targetMuscle")
    image_url: Optional[str] = Field(default=None, validation_alias="imageUrl", serialization_alias="imageUrl")
    instructions: Optional[str] = None

    model_config = {
        "populate_by_name": True,
        "from_attributes": True,
    }


# ==========================================
# 6. 사용자 인증(Auth) 및 계정 관리 스키마
# ==========================================

class UserRegisterRequest(BaseModel):
    email: str
    password: str
    nickname: str = "운동인"
    height_cm: Optional[float] = Field(default=None, validation_alias="heightCm", serialization_alias="heightCm")
    weight_kg: Optional[float] = Field(default=None, validation_alias="weightKg", serialization_alias="weightKg")
    target_weight_kg: Optional[float] = Field(default=None, validation_alias="targetWeightKg", serialization_alias="targetWeightKg")
    experience: Optional[str] = "beginner"
    workout_goal: Optional[str] = Field(default="근비대 및 전신 근력 증진", validation_alias="workoutGoal", serialization_alias="workoutGoal")

    model_config = {
        "populate_by_name": True,
    }


class UserLoginRequest(BaseModel):
    email: str
    password: str


class TokenResponse(BaseModel):
    access_token: str = Field(..., validation_alias="accessToken", serialization_alias="accessToken")
    token_type: str = Field(default="bearer", validation_alias="tokenType", serialization_alias="tokenType")
    user_id: str = Field(..., validation_alias="userId", serialization_alias="userId")
    email: str
    nickname: str

    model_config = {
        "populate_by_name": True,
    }


class UserResponse(BaseModel):
    user_id: str = Field(..., validation_alias="userId", serialization_alias="userId")
    email: str
    nickname: str
    created_at: Optional[dt_datetime] = Field(default=None, validation_alias="createdAt", serialization_alias="createdAt")

    model_config = {
        "populate_by_name": True,
        "from_attributes": True,
    }

