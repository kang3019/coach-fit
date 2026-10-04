from datetime import date, datetime, timedelta
from typing import List, Optional
from sqlalchemy.orm import Session
from app.models.body_metric_db import BodyMetricRecord
from app.models.schemas import BodyMetricCreate


def create_or_update_body_metric(db: Session, data: BodyMetricCreate) -> BodyMetricRecord:
    """
    신체 측정 기록 등록 또는 당일 데이터 갱신
    (동일 날짜 입력 시 덮어쓰기)
    """
    target_date = data.metric_date or date.today()
    user_id = data.user_id or "user_01"

    existing = (
        db.query(BodyMetricRecord)
        .filter(
            BodyMetricRecord.user_id == user_id,
            BodyMetricRecord.metric_date == target_date
        )
        .first()
    )

    if existing:
        if data.weight_kg is not None:
            existing.weight_kg = data.weight_kg
        if data.muscle_kg is not None:
            existing.muscle_kg = data.muscle_kg
        if data.body_fat_percent is not None:
            existing.body_fat_percent = data.body_fat_percent
        db.commit()
        db.refresh(existing)
        return existing

    record = BodyMetricRecord(
        user_id=user_id,
        metric_date=target_date,
        weight_kg=data.weight_kg,
        muscle_kg=data.muscle_kg,
        body_fat_percent=data.body_fat_percent,
        created_at=datetime.utcnow()
    )
    db.add(record)
    db.commit()
    db.refresh(record)
    return record


def get_body_metrics(db: Session, user_id: str = "user_01") -> List[BodyMetricRecord]:
    """사용자의 신체 측정 기록 전체 조회 (최신 일자 순)"""
    return (
        db.query(BodyMetricRecord)
        .filter(BodyMetricRecord.user_id == user_id)
        .order_by(BodyMetricRecord.metric_date.desc(), BodyMetricRecord.id.desc())
        .all()
    )


def get_latest_body_metric(db: Session, user_id: str = "user_01") -> Optional[BodyMetricRecord]:
    """가장 최근 신체 측정 1건 조회"""
    return (
        db.query(BodyMetricRecord)
        .filter(BodyMetricRecord.user_id == user_id)
        .order_by(BodyMetricRecord.metric_date.desc(), BodyMetricRecord.id.desc())
        .first()
    )


def seed_initial_body_metrics(db: Session):
    """초기 데모용 인바디 측정 데이터 시딩"""
    count = db.query(BodyMetricRecord).count()
    if count > 0:
        return

    today = date.today()
    demo_metrics = [
        BodyMetricRecord(
            user_id="user_01",
            metric_date=today - timedelta(days=14),
            weight_kg=76.2,
            muscle_kg=34.1,
            body_fat_percent=18.5,
            created_at=datetime.utcnow() - timedelta(days=14)
        ),
        BodyMetricRecord(
            user_id="user_01",
            metric_date=today - timedelta(days=7),
            weight_kg=75.3,
            muscle_kg=34.8,
            body_fat_percent=17.2,
            created_at=datetime.utcnow() - timedelta(days=7)
        ),
        BodyMetricRecord(
            user_id="user_01",
            metric_date=today,
            weight_kg=74.5,
            muscle_kg=35.2,
            body_fat_percent=16.0,
            created_at=datetime.utcnow()
        ),
    ]

    for m in demo_metrics:
        db.add(m)
    db.commit()
    print(f"[*] Seeded {len(demo_metrics)} body metric records into database.")
