from datetime import datetime
from sqlalchemy import Column, Integer, String, DateTime
from app.database import Base


class UserRecord(Base):
    """
    사용자 인증 및 계정 DB 엔티티 (PostgreSQL / SQLite 호환)
    """
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    user_id = Column(String(50), unique=True, nullable=False, index=True)
    email = Column(String(100), unique=True, nullable=False, index=True)
    hashed_password = Column(String(255), nullable=False)
    nickname = Column(String(50), nullable=False, default="운동인")
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
