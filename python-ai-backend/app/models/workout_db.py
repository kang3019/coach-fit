from datetime import date, datetime
from sqlalchemy import Column, Integer, String, Float, Date, DateTime, Text
from app.database import Base


class WorkoutRecord(Base):
    """
    운동 기록 DB 엔티티 (PostgreSQL / SQLite 호환)
    Java 백엔드의 WorkoutRecord 엔티티와 1:1 대응
    """
    __tablename__ = "workout_records"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    user_id = Column(String(50), default="user_01", nullable=False, index=True)
    exercise_name = Column(String(100), nullable=False)
    sets = Column(Integer, nullable=False)
    reps = Column(Integer, nullable=False)
    weight = Column(Float, nullable=False)
    workout_date = Column(Date, default=date.today, nullable=False)
    memo = Column(Text, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
