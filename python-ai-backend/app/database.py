import os
from sqlalchemy import create_engine
from sqlalchemy.orm import declarative_base, sessionmaker

# 데이터베이스 연결 URL 설정
# - 기본값: 로컬 개발 편의를 위한 SQLite (별도 DB 설치 없이 즉시 구동)
# - PostgreSQL 연동 시 .env 또는 환경 변수에 지정:
#     DATABASE_URL=postgresql://postgres:password@localhost:5432/coachfit
DATABASE_URL = os.getenv("DATABASE_URL", "sqlite:///./coachfit.db")

# Heroku/일부 PaaS에서 postgres:// 로 시작하는 구형 URL 형식 보정
if DATABASE_URL.startswith("postgres://"):
    DATABASE_URL = DATABASE_URL.replace("postgres://", "postgresql://", 1)

# SQLite 사용 시 스레드 체크 옵션 활성화
connect_args = {"check_same_thread": False} if DATABASE_URL.startswith("sqlite") else {}

engine = create_engine(
    DATABASE_URL,
    connect_args=connect_args,
    echo=False
)

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

Base = declarative_base()


def get_db():
    """FastAPI Depends용 데이터베이스 세션 제너레이터"""
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


def init_db():
    """테이블 자동 생성"""
    from app.models.workout_db import WorkoutRecord
    from app.models.exercise_db import ExerciseMaster
    from app.models.body_metric_db import BodyMetricRecord
    from app.models.user_profile_db import UserProfileRecord
    Base.metadata.create_all(bind=engine)

