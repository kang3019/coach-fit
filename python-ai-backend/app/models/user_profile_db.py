from datetime import datetime
from sqlalchemy import Column, Integer, String, Float, DateTime
from app.database import Base


class UserProfileRecord(Base):
    """
    사용자 프로필 & 운동 목표 DB 엔티티
    PostgreSQL / SQLite 호환
    """
    __tablename__ = "user_profiles"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    user_id = Column(String(50), unique=True, nullable=False, index=True, default="user_01")
    nickname = Column(String(50), default="김운동", nullable=False)
    gender = Column(String(20), default="undisclosed", nullable=False)
    height_cm = Column(Float, nullable=True, default=178.0)
    weight_kg = Column(Float, nullable=True, default=74.5)
    target_weight_kg = Column(Float, nullable=True, default=72.0)
    experience = Column(String(30), default="beginner", nullable=False)
    workout_goal = Column(String(100), default="근비대 및 전신 근력 증진", nullable=False)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False)
