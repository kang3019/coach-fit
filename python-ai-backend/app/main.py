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

from app.database import get_db, init_db
from app.models.schemas import (
    WorkoutCreate,
    WorkoutResponse,
    WeeklyStatsResponse,
    CoachingGenerateRequest,
    CoachingRequest,
    CoachingResponse,
    WorkoutItem,
)
from app.services.ai_coach import generate_coaching_advice
from app.services.workout_service import (
    create_workout,
    get_workouts_by_user,
    get_recent_workouts,
    get_weekly_volume_stats,
)

from contextlib import asynccontextmanager

# .env 환경 변수 로드
load_dotenv()

# 데이터베이스 테이블 초기화 (앱 로드 시 즉시 생성)
init_db()

@asynccontextmanager
async def lifespan(app: FastAPI):
    init_db()
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
# 1. 운동 기록(Workout) CRUD API
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
    DB에 저장된 사용자의 최근 운동 기록을 직접 조회하여
    AI 코칭 피드백 및 맞춤 루틴을 생성합니다. (단일 서버에서 DB 직결)
    """
    target_user_id = request.user_id if request and request.user_id else "user_01"
    target_goal = request.goal if request and request.goal else "근비대 및 전신 근력 증진"

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

    coaching_req = CoachingRequest(
        user_id=target_user_id,
        user_goal=target_goal,
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


if __name__ == "__main__":
    import uvicorn
    host = os.getenv("HOST", "0.0.0.0")
    port = int(os.getenv("PORT", 8000))
    print(f"Starting CoachFit Unified Backend Server on {host}:{port}...")
    uvicorn.run("app.main:app", host=host, port=port, reload=True)
