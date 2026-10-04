from datetime import date, datetime
from sqlalchemy import Column, Integer, String, Float, Date, DateTime
from app.database import Base


class BodyMetricRecord(Base):
    """
    신체 측정 DB 엔티티 (체중, 골격근량, 체지방률)
    PostgreSQL / SQLite 호환
    """
    __tablename__ = "body_metrics"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    user_id = Column(String(50), default="user_01", nullable=False, index=True)
    metric_date = Column(Date, default=date.today, nullable=False)
    weight_kg = Column(Float, nullable=True)
    muscle_kg = Column(Float, nullable=True)
    body_fat_percent = Column(Float, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
