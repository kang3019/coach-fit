from datetime import datetime
from sqlalchemy.orm import Session
from app.models.user_profile_db import UserProfileRecord
from app.models.schemas import UserProfileUpdate


def get_or_create_user_profile(db: Session, user_id: str = "user_01") -> UserProfileRecord:
    """사용자 프로필 조회 (없으면 기본값으로 생성)"""
    profile = (
        db.query(UserProfileRecord)
        .filter(UserProfileRecord.user_id == user_id)
        .first()
    )
    if not profile:
        profile = UserProfileRecord(
            user_id=user_id,
            nickname="김운동",
            gender="undisclosed",
            height_cm=178.0,
            weight_kg=74.5,
            target_weight_kg=72.0,
            experience="beginner",
            workout_goal="근비대 및 전신 근력 증진",
            updated_at=datetime.utcnow()
        )
        db.add(profile)
        db.commit()
        db.refresh(profile)
    return profile


def update_user_profile(db: Session, data: UserProfileUpdate) -> UserProfileRecord:
    """사용자 프로필 및 운동 목표 갱신"""
    user_id = data.user_id or "user_01"
    profile = get_or_create_user_profile(db, user_id)

    if data.nickname is not None:
        profile.nickname = data.nickname
    if data.gender is not None:
        profile.gender = data.gender
    if data.height_cm is not None:
        profile.height_cm = data.height_cm
    if data.weight_kg is not None:
        profile.weight_kg = data.weight_kg
    if data.target_weight_kg is not None:
        profile.target_weight_kg = data.target_weight_kg
    if data.experience is not None:
        profile.experience = data.experience
    if data.workout_goal is not None:
        profile.workout_goal = data.workout_goal

    profile.updated_at = datetime.utcnow()
    db.commit()
    db.refresh(profile)
    return profile


def seed_initial_user_profile(db: Session):
    """기본 사용자 프로필 시딩"""
    get_or_create_user_profile(db, "user_01")
