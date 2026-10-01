from sqlalchemy import Column, Integer, String, Text
from app.database import Base


class ExerciseMaster(Base):
    """
    운동 종목 마스터 사전 엔티티 (사진, 부위, 장비, 자세 가이드 포함)
    """
    __tablename__ = "exercise_masters"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    name = Column(String(100), nullable=False, index=True)
    english_name = Column(String(100), nullable=True)
    category = Column(String(50), nullable=False, index=True) # 가슴, 등, 하체, 어깨, 팔, 복근/유산소
    equipment = Column(String(50), nullable=False) # 바벨, 덤벨, 머신, 케이블, 맨몸
    target_muscle = Column(String(100), nullable=False) # 대흉근, 광배근, 대퇴사두 등
    image_url = Column(String(500), nullable=True) # 고해상도 운동 사진/일러스트 URL
    instructions = Column(Text, nullable=True) # 운동 핵심 자세 및 팁
