import uuid
from typing import Optional
from sqlalchemy.orm import Session
from fastapi import HTTPException, status

from app.models.user_db import UserRecord
from app.models.user_profile_db import UserProfileRecord
from app.models.body_metric_db import BodyMetricRecord
from app.models.schemas import UserRegisterRequest
from app.utils.security import hash_password, verify_password


def register_user(db: Session, req: UserRegisterRequest) -> UserRecord:
    """새 사용자 회원가입 및 기본 프로필/체성분 생성"""
    # 1. 이메일 중복 체크
    existing_user = db.query(UserRecord).filter(UserRecord.email == req.email.strip().lower()).first()
    if existing_user:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="이미 등록된 이메일 주소입니다."
        )

    # 2. 고유 user_id 생성
    user_id = f"user_{uuid.uuid4().hex[:8]}"

    # 3. 비밀번호 해싱
    hashed_pwd = hash_password(req.password)

    # 4. 사용자 레코드 생성
    new_user = UserRecord(
        user_id=user_id,
        email=req.email.strip().lower(),
        hashed_password=hashed_pwd,
        nickname=req.nickname.strip() if req.nickname else "운동인"
    )
    db.add(new_user)

    # 5. 사용자 프로필(UserProfileRecord) 생성
    new_profile = UserProfileRecord(
        user_id=user_id,
        nickname=new_user.nickname,
        height_cm=req.height_cm or 175.0,
        weight_kg=req.weight_kg or 70.0,
        target_weight_kg=req.target_weight_kg or 70.0,
        experience=req.experience or "beginner",
        workout_goal=req.workout_goal or "근비대 및 전신 근력 증진"
    )
    db.add(new_profile)

    # 6. 초기 체성분(BodyMetricRecord) 생성
    if req.weight_kg:
        new_metric = BodyMetricRecord(
            user_id=user_id,
            weight_kg=req.weight_kg,
            muscle_kg=round(req.weight_kg * 0.45, 1),
            body_fat_percent=18.0
        )
        db.add(new_metric)

    db.commit()
    db.refresh(new_user)
    return new_user


def authenticate_user(db: Session, email: str, password: str) -> Optional[UserRecord]:
    """이메일과 비밀번호로 사용자 인증"""
    user = db.query(UserRecord).filter(UserRecord.email == email.strip().lower()).first()
    if not user:
        return None
    if not verify_password(password, user.hashed_password):
        return None
    return user


def get_user_by_id(db: Session, user_id: str) -> Optional[UserRecord]:
    """user_id로 사용자 조회"""
    return db.query(UserRecord).filter(UserRecord.user_id == user_id).first()


def seed_default_users(db: Session):
    """기본 데모 사용자(demo@coachfit.com / user_01) 초기 시드 적재"""
    demo_user = db.query(UserRecord).filter(UserRecord.email == "demo@coachfit.com").first()
    if not demo_user:
        # 기존 user_01의 레코드가 있는지 확인
        user_01 = db.query(UserRecord).filter(UserRecord.user_id == "user_01").first()
        if not user_01:
            demo_user = UserRecord(
                user_id="user_01",
                email="demo@coachfit.com",
                hashed_password=hash_password("password123"),
                nickname="김운동"
            )
            db.add(demo_user)
            db.commit()
            print("Successfully seeded default demo user: demo@coachfit.com / password123 (user_01)")
