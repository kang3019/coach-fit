from datetime import date, datetime
from typing import List, Optional
from pydantic import BaseModel, Field

class WorkoutItem(BaseModel):
    exercise_name: str = Field(..., description="운동 종목 이름 (예: 벤치프레스, 스쿼트 등)")
    sets: int = Field(..., ge=1, description="수행 세트 수")
    reps: int = Field(..., ge=1, description="세트당 반복 횟수")
    weight: float = Field(..., ge=0.0, description="중량 (kg)")
    date: Optional[date] = Field(default=None, description="운동 수행 일자")

class CoachingRequest(BaseModel):
    user_id: str = Field(default="user_01", description="사용자 식별자")
    user_goal: Optional[str] = Field(default="근비대 및 전신 근력 증진", description="사용자의 현재 운동 목표")
    recent_workouts: List[WorkoutItem] = Field(default_factory=list, description="Java 서버에서 전달받은 최근 운동 기록 목록")

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
    generated_at: str = Field(default_factory=lambda: datetime.now().isoformat(), description="응답 생성 시각")
