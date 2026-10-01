from datetime import date, datetime
from typing import List, Dict
from sqlalchemy.orm import Session
from app.models.workout_db import WorkoutRecord
from app.models.schemas import WorkoutCreate


def create_workout(db: Session, data: WorkoutCreate) -> WorkoutRecord:
    """새로운 운동 기록 저장"""
    record = WorkoutRecord(
        user_id=data.user_id or "user_01",
        exercise_name=data.exercise_name,
        sets=data.sets,
        reps=data.reps,
        weight=data.weight,
        workout_date=data.workout_date or date.today(),
        memo=data.memo,
        created_at=datetime.utcnow()
    )
    db.add(record)
    db.commit()
    db.refresh(record)
    return record


def get_workouts_by_user(db: Session, user_id: str = "user_01") -> List[WorkoutRecord]:
    """사용자의 전체 운동 기록 조회 (최신 일자 순)"""
    return (
        db.query(WorkoutRecord)
        .filter(WorkoutRecord.user_id == user_id)
        .order_by(WorkoutRecord.workout_date.desc(), WorkoutRecord.id.desc())
        .all()
    )


def get_recent_workouts(db: Session, user_id: str = "user_01", limit: int = 10) -> List[WorkoutRecord]:
    """최근 N개 운동 기록 조회"""
    return (
        db.query(WorkoutRecord)
        .filter(WorkoutRecord.user_id == user_id)
        .order_by(WorkoutRecord.workout_date.desc(), WorkoutRecord.id.desc())
        .limit(limit)
        .all()
    )


def get_weekly_volume_stats(db: Session, user_id: str = "user_01") -> Dict:
    """
    요일별 총 볼륨 (Weight * Sets * Reps) 통계 계산
    Java 백엔드의 /api/workouts/weekly-stats와 100% 동일한 응답 규격
    """
    records = get_workouts_by_user(db, user_id)

    day_abbr_map = {
        0: "MON",
        1: "TUE",
        2: "WED",
        3: "THU",
        4: "FRI",
        5: "SAT",
        6: "SUN"
    }

    day_volume_map: Dict[str, float] = {
        "MON": 0.0,
        "TUE": 0.0,
        "WED": 0.0,
        "THU": 0.0,
        "FRI": 0.0,
        "SAT": 0.0,
        "SUN": 0.0
    }

    for item in records:
        day_str = day_abbr_map.get(item.workout_date.weekday(), "MON")
        volume = float(item.weight) * float(item.sets) * float(item.reps)
        day_volume_map[day_str] = round(day_volume_map[day_str] + volume, 2)

    return {
        "userId": user_id,
        "totalRecords": len(records),
        "weeklyVolumeByDay": day_volume_map
    }


def delete_workout(db: Session, workout_id: int, user_id: str = "user_01") -> bool:
    """운동 기록 삭제"""
    record = (
        db.query(WorkoutRecord)
        .filter(WorkoutRecord.id == workout_id, WorkoutRecord.user_id == user_id)
        .first()
    )
    if not record:
        return False
    db.delete(record)
    db.commit()
    return True


def seed_initial_workouts(db: Session, user_id: str = "user_01"):
    """
    서버 초기 기동 및 시연을 위한 5건의 기초 운동 기록 자동 생성 (WBS 3.3.1 대응)
    Java 백엔드의 @PostConstruct initDummyData()와 100% 동일한 시연 데이터셋
    """
    count = db.query(WorkoutRecord).filter(WorkoutRecord.user_id == user_id).count()
    if count == 0:
        from datetime import timedelta
        today = date.today()

        dummy_list = [
            WorkoutRecord(
                user_id=user_id,
                exercise_name="벤치프레스",
                sets=5,
                reps=10,
                weight=70.0,
                workout_date=today - timedelta(days=5),
                memo="가슴 자극 집중 및 점진적 과부하",
                created_at=datetime.utcnow()
            ),
            WorkoutRecord(
                user_id=user_id,
                exercise_name="인클라인 덤벨프레스",
                sets=4,
                reps=12,
                weight=22.0,
                workout_date=today - timedelta(days=5),
                memo="상부 가슴 타겟",
                created_at=datetime.utcnow()
            ),
            WorkoutRecord(
                user_id=user_id,
                exercise_name="스쿼트",
                sets=5,
                reps=8,
                weight=100.0,
                workout_date=today - timedelta(days=3),
                memo="하체 메인 세션 (깊은 가동범위)",
                created_at=datetime.utcnow()
            ),
            WorkoutRecord(
                user_id=user_id,
                exercise_name="레그프레스",
                sets=4,
                reps=12,
                weight=140.0,
                workout_date=today - timedelta(days=3),
                memo="대퇴사두 집중",
                created_at=datetime.utcnow()
            ),
            WorkoutRecord(
                user_id=user_id,
                exercise_name="랫 풀 다운",
                sets=4,
                reps=10,
                weight=55.0,
                workout_date=today - timedelta(days=1),
                memo="광배근 활성화",
                created_at=datetime.utcnow()
            ),
        ]
        db.add_all(dummy_list)
        db.commit()

