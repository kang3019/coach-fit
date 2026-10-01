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
