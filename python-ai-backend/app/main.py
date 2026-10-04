import os
from typing import List, Optional
from fastapi import FastAPI, HTTPException, Depends, Query, status
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.orm import Session
from dotenv import load_dotenv

try:
    from mangum import Mangum
except ImportError:
    Mangum = None

from app.database import get_db, init_db, SessionLocal
from app.models.schemas import (
    WorkoutCreate,
    WorkoutResponse,
    WeeklyStatsResponse,
    CoachingGenerateRequest,
    CoachingRequest,
    CoachingResponse,
    WorkoutItem,
    ExerciseResponse,
    BodyMetricCreate,
    BodyMetricResponse,
    UserProfileUpdate,
    UserProfileResponse,
)
from app.services.ai_coach import generate_coaching_advice
from app.services.workout_service import (
    create_workout,
    get_workouts_by_user,
    get_recent_workouts,
    get_weekly_volume_stats,
    delete_workout,
    seed_initial_workouts,
)
from app.services.exercise_service import (
    get_exercise_masters,
    seed_exercise_masters,
)
from app.services.body_metric_service import (
    create_or_update_body_metric,
    get_body_metrics,
    get_latest_body_metric,
    seed_initial_body_metrics,
)
from app.services.user_profile_service import (
    get_or_create_user_profile,
    update_user_profile,
    seed_initial_user_profile,
)

from contextlib import asynccontextmanager

# .env 환경 변수 로드
load_dotenv()

# 데이터베이스 테이블 초기화 및 시드 데이터 적재
init_db()
_db = SessionLocal()
try:
    seed_initial_workouts(_db)
    seed_exercise_masters(_db)
    seed_initial_body_metrics(_db)
    seed_initial_user_profile(_db)
finally:
    _db.close()

@asynccontextmanager
async def lifespan(app: FastAPI):
    init_db()
    db = SessionLocal()
    try:
        seed_initial_workouts(db)
        seed_exercise_masters(db)
        seed_initial_body_metrics(db)
        seed_initial_user_profile(db)
    finally:
        db.close()
    yield




app = FastAPI(
    title="CoachFit Unified Backend API",
    description="FastAPI + PostgreSQL 기반 단일 백엔드 (운동 기록 CRUD, 주간 볼륨 통계, AI 맞춤형 코칭)",
    version="2.0.0",
    lifespan=lifespan
)


# CORS 설정: Flutter 모바일 및 프론트엔드 연동
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# AWS Lambda 핸들러 (서버리스 배포 지원)
handler = Mangum(app) if Mangum else None


# ==========================================
# 0. 헬스체크 및 루트 엔드포인트
# ==========================================

@app.get("/")
def read_root():
    return {
        "service": "CoachFit Unified Backend",
        "stack": "FastAPI + PostgreSQL (SQLAlchemy)",
        "status": "online",
        "docs_url": "/docs",
        "endpoints": {
            "workouts": "/api/workouts",
            "weekly_stats": "/api/workouts/weekly-stats",
            "coaching_generate": "POST /api/coaching/generate",
            "health": "/health"
        }
    }


@app.get("/health")
def health_check():
    return {"status": "healthy"}


# ==========================================
# 1. 운동 종목 마스터 사전 API (사진 & 부위 정보)
# ==========================================

@app.get(
    "/api/exercises",
    response_model=List[ExerciseResponse],
    summary="운동 종목 마스터 사전 목록 조회 (부위별 필터 및 검색)"
)
def api_get_exercises(
    category: Optional[str] = Query(default=None, description="가슴, 등, 하체, 어깨, 팔, 복근 등 부위 필터"),
    search: Optional[str] = Query(default=None, description="운동명 검색어"),
    db: Session = Depends(get_db)
):
    """
    한국 헬스장 대표 운동 25선 마스터 데이터 반환 (사진 URL, 장비, 타겟 근육, 자세 가이드 포함)
    """
    return get_exercise_masters(db, category=category, search=search)


# ==========================================
# 2. 운동 기록(Workout) CRUD API
# ==========================================


@app.post(
    "/api/workouts",
    response_model=WorkoutResponse,
    status_code=status.HTTP_201_CREATED,
    summary="운동 기록 등록"
)
def api_create_workout(
    workout_in: WorkoutCreate,
    db: Session = Depends(get_db)
):
    """
    운동 기록 등록 API
    - Flutter 모바일 앱 및 웹 클라이언트에서 호출
    - PostgreSQL / SQLite DB에 즉시 영구 저장
    """
    try:
        record = create_workout(db, workout_in)
        return record
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"운동 기록 저장 실패: {str(e)}")


@app.get(
    "/api/workouts",
    response_model=List[WorkoutResponse],
    summary="운동 기록 목록 조회"
)
def api_get_workouts(
    userId: str = Query(default="user_01", alias="userId"),
    db: Session = Depends(get_db)
):
    """
    사용자의 전체 운동 기록 목록 조회 API (최신 일자 순 정렬)
    """
    return get_workouts_by_user(db, user_id=userId)


@app.delete(
    "/api/workouts/{workout_id}",
    summary="운동 기록 삭제"
)
def api_delete_workout(
    workout_id: int,
    userId: str = Query(default="user_01", alias="userId"),
    db: Session = Depends(get_db)
):
    """
    운동 기록 단건 삭제 API
    """
    success = delete_workout(db, workout_id=workout_id, user_id=userId)
    if not success:
        raise HTTPException(status_code=404, detail="해당 운동 기록을 찾을 수 없습니다.")
    return {"message": "운동 기록이 성공적으로 삭제되었습니다.", "deletedId": workout_id}



@app.get(
    "/api/workouts/weekly-stats",
    response_model=WeeklyStatsResponse,
    summary="주간 볼륨 차트 통계 조회"
)
def api_get_weekly_stats(
    userId: str = Query(default="user_01", alias="userId"),
    db: Session = Depends(get_db)
):
    """
    모바일 주간 볼륨 차트(fl_chart)용 요일별 누적 볼륨 통계 반환
    """
    return get_weekly_volume_stats(db, user_id=userId)


# ==========================================
# 2. AI 코칭(Coaching) API
# ==========================================

@app.post(
    "/api/coaching/generate",
    response_model=CoachingResponse,
    summary="DB 기반 AI 코칭 및 오늘 추천 루틴 생성"
)
def api_generate_coaching(
    request: Optional[CoachingGenerateRequest] = None,
    db: Session = Depends(get_db)
):
    """
    DB에 저장된 사용자의 최근 운동 기록, 인바디 신체 측정치, 프로필 목표를
    직접 종합 조회하여 초개인화 AI 코칭 피드백 및 맞춤 루틴을 생성합니다.
    """
    target_user_id = request.user_id if request and request.user_id else "user_01"

    # DB에서 사용자 프로필 및 최신 신체 측정치 조회
    user_profile = get_or_create_user_profile(db, user_id=target_user_id)
    latest_metric = get_latest_body_metric(db, user_id=target_user_id)

    target_goal = (
        request.goal
        if request and request.goal
        else user_profile.workout_goal
    )

    # DB에서 최근 10개 운동 기록 조회
    recent_db_records = get_recent_workouts(db, user_id=target_user_id, limit=10)

    workout_items = [
        WorkoutItem(
            exercise_name=r.exercise_name,
            sets=r.sets,
            reps=r.reps,
            weight=r.weight,
            date=r.workout_date
        )
        for r in recent_db_records
    ]

    profile_dict = {
        "height_cm": user_profile.height_cm,
        "weight_kg": latest_metric.weight_kg if latest_metric and latest_metric.weight_kg else user_profile.weight_kg,
        "muscle_kg": latest_metric.muscle_kg if latest_metric else None,
        "body_fat_percent": latest_metric.body_fat_percent if latest_metric else None,
        "target_weight_kg": user_profile.target_weight_kg,
        "experience": user_profile.experience,
    }

    coaching_req = CoachingRequest(
        user_id=target_user_id,
        user_goal=target_goal,
        user_profile=profile_dict,
        recent_workouts=workout_items
    )

    try:
        return generate_coaching_advice(coaching_req)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"AI 코칭 생성 실패: {str(e)}")


@app.post(
    "/api/coaching",
    response_model=CoachingResponse,
    summary="수동 운동 목록 기반 AI 코칭 생성 (직접 페이로드 전달)"
)
def api_coaching_direct(request: CoachingRequest):
    """
    요청 본문에 직접 포함된 최근 운동 데이터를 바탕으로 코칭 생성
    """
    try:
        return generate_coaching_advice(request)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"AI 코칭 생성 실패: {str(e)}")


# ==========================================
# 3. 신체 측정(Body Metrics / Inbody) API
# ==========================================

@app.get(
    "/api/body-metrics",
    response_model=List[BodyMetricResponse],
    summary="신체 측정(인바디) 기록 전체 목록 조회"
)
def api_get_body_metrics(
    userId: str = Query(default="user_01", alias="userId"),
    db: Session = Depends(get_db)
):
    """
    사용자의 체중, 골격근량, 체지방률 측정 이력 전체를 최신순으로 조회
    """
    return get_body_metrics(db, user_id=userId)


@app.post(
    "/api/body-metrics",
    response_model=BodyMetricResponse,
    status_code=status.HTTP_201_CREATED,
    summary="신체 측정(체중, 골격근량, 체지방률) 기록 저장/수정"
)
def api_create_body_metric(
    metric: BodyMetricCreate,
    db: Session = Depends(get_db)
):
    """
    새로운 신체 측정 기록 등록 (동일 날짜 존재 시 자동 업데이트)
    """
    return create_or_update_body_metric(db, metric)


# ==========================================
# 4. 사용자 프로필 및 운동 목표 API
# ==========================================

@app.get(
    "/api/profile",
    response_model=UserProfileResponse,
    summary="사용자 프로필 및 운동 목표 조회"
)
def api_get_profile(
    userId: str = Query(default="user_01", alias="userId"),
    db: Session = Depends(get_db)
):
    """
    사용자의 신체 기본 스펙(키, 체중, 목표 체중) 및 운동 경력, 설정된 목표 조회
    """
    return get_or_create_user_profile(db, user_id=userId)


@app.put(
    "/api/profile",
    response_model=UserProfileResponse,
    summary="사용자 프로필 및 운동 목표 수정"
)
def api_update_profile(
    profile: UserProfileUpdate,
    db: Session = Depends(get_db)
):
    """
    사용자의 프로필 정보(닉네임, 키, 체중, 경력, 운동 목표)를 DB에 반영
    """
    return update_user_profile(db, profile)



if __name__ == "__main__":
    import uvicorn
    host = os.getenv("HOST", "0.0.0.0")
    port = int(os.getenv("PORT", 8000))
    print(f"Starting CoachFit Unified Backend Server on {host}:{port}...")
    uvicorn.run("app.main:app", host=host, port=port, reload=True)
