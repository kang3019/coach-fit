from typing import List, Optional
from sqlalchemy.orm import Session
from app.models.exercise_db import ExerciseMaster


def get_exercise_masters(
    db: Session,
    category: Optional[str] = None,
    search: Optional[str] = None
) -> List[ExerciseMaster]:
    """운동 종목 목록 조회 (부위별 필터 및 검색어 지원)"""
    query = db.query(ExerciseMaster)

    if category and category != "전체":
        query = query.filter(ExerciseMaster.category == category)

    if search and search.strip():
        term = f"%{search.strip()}%"
        query = query.filter(
            (ExerciseMaster.name.ilike(term)) |
            (ExerciseMaster.english_name.ilike(term)) |
            (ExerciseMaster.target_muscle.ilike(term))
        )

    return query.order_by(ExerciseMaster.category, ExerciseMaster.id).all()


def seed_exercise_masters(db: Session):
    """
    한국 헬스장에서 가장 많이 수행하는 대표 운동 25선 마스터 데이터 시딩
    - 고해상도 운동 사진 URL
    - 영문 명칭
    - 부위 분류 (가슴, 등, 하체, 어깨, 팔, 복근)
    - 사용 장비 (바벨, 덤벨, 머신, 케이블, 맨몸)
    - 타겟 근육 및 핵심 팁
    """
    if db.query(ExerciseMaster).count() > 0:
        return

    exercises = [
        # --- 가슴 (Chest) ---
        ExerciseMaster(
            name="바벨 벤치프레스",
            english_name="Barbell Bench Press",
            category="가슴",
            equipment="바벨",
            target_muscle="대흉근, 전면 삼각근, 삼두근",
            image_url="https://images.unsplash.com/photo-1517838277536-f5f99be501cd?w=400&auto=format&fit=crop&q=80",
            instructions="견갑골을 모아 벤치에 단단히 밀착시키고, 바를 젖꼭지 아래 지점으로 수직 하강 후 가슴으로 밀어올립니다."
        ),
        ExerciseMaster(
            name="인클라인 덤벨프레스",
            english_name="Incline Dumbbell Press",
            category="가슴",
            equipment="덤벨",
            target_muscle="상부 대흉근, 전면 삼각근",
            image_url="https://images.unsplash.com/photo-1581009146145-b5ef050c2e1e?w=400&auto=format&fit=crop&q=80",
            instructions="벤치 각도를 30~45도로 맞추고, 팔꿈치가 어깨보다 과도하게 올라가지 않도록 주의하며 덤벨을 모아줍니다."
        ),
        ExerciseMaster(
            name="시티드 체스트프레스 (머신)",
            english_name="Chest Press Machine",
            category="가슴",
            equipment="머신",
            target_muscle="대흉근 전반",
            image_url="https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=400&auto=format&fit=crop&q=80",
            instructions="안장 높이를 조절하여 손잡이가 가슴 중앙에 오도록 하고, 어깨가 솟지 않게 고정하고 밀어냅니다."
        ),
        ExerciseMaster(
            name="케이블 플라이 (펙덱)",
            english_name="Cable / Pec Deck Fly",
            category="가슴",
            equipment="케이블",
            target_muscle="대흉근 안쪽(내측) 고립",
            image_url="https://images.unsplash.com/photo-1574680096145-d05b474e2155?w=400&auto=format&fit=crop&q=80",
            instructions="팔꿈치 각도를 살짝 굽힌 채 고정하고, 큰 나무를 안는다는 느낌으로 가슴 안쪽을 쥐어짜듯 모읍니다."
        ),
        ExerciseMaster(
            name="딥스 (맨몸/어시스트)",
            english_name="Chest Dips",
            category="가슴",
            equipment="맨몸",
            target_muscle="하부 대흉근, 삼두근",
            image_url="https://images.unsplash.com/photo-1598971639058-fab3c3109a00?w=400&auto=format&fit=crop&q=80",
            instructions="상체를 앞으로 30도 정도 기울여 가슴 하부에 체중을 실으며 팔꿈치가 90도가 될 때까지 내려갑니다."
        ),

        # --- 등 (Back) ---
        ExerciseMaster(
            name="컨벤셔널 데드리프트",
            english_name="Conventional Deadlift",
            category="등",
            equipment="바벨",
            target_muscle="척추기립근, 광배근, 둔근, 햄스트링",
            image_url="https://images.unsplash.com/photo-1517838277536-f5f99be501cd?w=400&auto=format&fit=crop&q=80",
            instructions="발을 골반 너비로 벌리고 바를 정강이에 붙인 뒤, 복압을 채우고 바닥을 밀어내며 일어납니다."
        ),
        ExerciseMaster(
            name="랫 풀 다운",
            english_name="Lat Pull Down",
            category="등",
            equipment="머신",
            target_muscle="광배근(외측), 대원근",
            image_url="https://images.unsplash.com/photo-1605296867304-46d5465a13f1?w=400&auto=format&fit=crop&q=80",
            instructions="어깨 너비보다 넓게 오버그립으로 잡고, 팔꿈치를 옆구리 쪽으로 지그시 찍어 누르듯 쇄골 쪽으로 당깁니다."
        ),
        ExerciseMaster(
            name="바벨 벤트오버 로우",
            english_name="Barbell Bent-Over Row",
            category="등",
            equipment="바벨",
            target_muscle="광배근, 승모근 중하부, 능형근",
            image_url="https://images.unsplash.com/photo-1541534741688-6078c6bfb5c5?w=400&auto=format&fit=crop&q=80",
            instructions="상체를 45도 숙이고 허리를 곧게 편 뒤, 바벨을 아랫배(배꼽) 쪽으로 당겨 견갑골을 강하게 수축합니다."
        ),
        ExerciseMaster(
            name="시티드 케이블 로우",
            english_name="Seated Cable Row",
            category="등",
            equipment="케이블",
            target_muscle="등 중앙부, 광배근 하부",
            image_url="https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=400&auto=format&fit=crop&q=80",
            instructions="허리를 펴고 가슴을 든 상태에서 어깨가 말리지 않도록 팔꿈치를 뒤로 길게 당겨 수축합니다."
        ),
        ExerciseMaster(
            name="풀업 (턱걸이)",
            english_name="Pull Up",
            category="등",
            equipment="맨몸",
            target_muscle="광배근, 소원근, 상완이두근",
            image_url="https://images.unsplash.com/photo-1598971639058-fab3c3109a00?w=400&auto=format&fit=crop&q=80",
            instructions="숄더팩킹으로 어깨를 안정화한 뒤, 가슴을 바에 닿게 한다는 느낌으로 당겨 올라갑니다."
        ),

        # --- 하체 (Legs) ---
        ExerciseMaster(
            name="바벨 백스쿼트",
            english_name="Barbell Back Squat",
            category="하체",
            equipment="바벨",
            target_muscle="대퇴사두근, 대둔근, 코어",
            image_url="https://images.unsplash.com/photo-1574680096145-d05b474e2155?w=400&auto=format&fit=crop&q=80",
            instructions="바벨을 승모근 상단에 얹고, 무릎과 발끝의 방향을 일치시킨 채 고관절을 접으며 깊게 앉습니다."
        ),
        ExerciseMaster(
            name="파워 레그프레스",
            english_name="45 Degree Leg Press",
            category="하체",
            equipment="머신",
            target_muscle="대퇴사두근, 둔근",
            image_url="https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=400&auto=format&fit=crop&q=80",
            instructions="허리가 패드에서 뜨지 않도록 손잡이를 단단히 쥐고, 발판 중앙에 발을 두고 천천히 밀어냅니다."
        ),
        ExerciseMaster(
            name="레그 익스텐션",
            english_name="Leg Extension",
            category="하체",
            equipment="머신",
            target_muscle="대퇴사두근(허벅지 앞쪽) 고립",
            image_url="https://images.unsplash.com/photo-1581009146145-b5ef050c2e1e?w=400&auto=format&fit=crop&q=80",
            instructions="엉덩이를 시트에 밀착시키고 정강이 패드를 발목 윗부분에 둔 뒤, 무릎을 펴 정점에서 1초간 수축합니다."
        ),
        ExerciseMaster(
            name="라잉 레그 컬",
            english_name="Lying Leg Curl",
            category="하체",
            equipment="머신",
            target_muscle="햄스트링(허벅지 뒤쪽)",
            image_url="https://images.unsplash.com/photo-1517838277536-f5f99be501cd?w=400&auto=format&fit=crop&q=80",
            instructions="골반이 패드에서 들리지 않게 복압을 유지하며, 뒤꿈치를 엉덩이 쪽으로 끌어당겨 햄스트링을 수축합니다."
        ),
        ExerciseMaster(
            name="워킹 런지",
            english_name="Walking Lunge",
            category="하체",
            equipment="덤벨",
            target_muscle="대둔근, 대퇴사두근, 밸런스",
            image_url="https://images.unsplash.com/photo-1605296867304-46d5465a13f1?w=400&auto=format&fit=crop&q=80",
            instructions="보폭을 크게 딛고 앞뒤 무릎 각도가 90도가 되도록 수직으로 앉았다가 앞발 뒤꿈치로 밀고 일어납니다."
        ),

        # --- 어깨 (Shoulders) ---
        ExerciseMaster(
            name="오버헤드 프레스 (OHP)",
            english_name="Overhead Press",
            category="어깨",
            equipment="바벨",
            target_muscle="전면 및 측면 삼각근, 상부 승모근",
            image_url="https://images.unsplash.com/photo-1581009146145-b5ef050c2e1e?w=400&auto=format&fit=crop&q=80",
            instructions="코어와 둔근을 단단히 조이고, 바벨을 턱을 스쳐 머리 위로 수직으로 곧게 밀어올립니다."
        ),
        ExerciseMaster(
            name="사이드 레터럴 레이즈 (사레레)",
            english_name="Side Lateral Raise",
            category="어깨",
            equipment="덤벨",
            target_muscle="측면 삼각근 고립",
            image_url="https://images.unsplash.com/photo-1574680096145-d05b474e2155?w=400&auto=format&fit=crop&q=80",
            instructions="승모근 개입을 줄이기 위해 어깨를 하강시키고, 팔꿈치를 살짝 들어 주전자로 물을 따르듯 옆으로 벌립니다."
        ),
        ExerciseMaster(
            name="페이스 풀",
            english_name="Face Pull",
            category="어깨",
            equipment="케이블",
            target_muscle="후면 삼각근, 회전근개",
            image_url="https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=400&auto=format&fit=crop&q=80",
            instructions="로프를 눈높이에 세팅하고 엄지가 뒤를 향하도록 외회전하면서 로프를 이마/눈 쪽으로 당깁니다."
        ),

        # --- 팔 (Arms) ---
        ExerciseMaster(
            name="바벨 / 이지바 컬",
            english_name="EZ-Bar Biceps Curl",
            category="팔",
            equipment="바벨",
            target_muscle="상완이두근",
            image_url="https://images.unsplash.com/photo-1581009146145-b5ef050c2e1e?w=400&auto=format&fit=crop&q=80",
            instructions="팔꿈치를 옆구리에 고정하고 반동을 최소화하며 이두근의 힘으로만 바를 가슴 쪽으로 끌어올립니다."
        ),
        ExerciseMaster(
            name="케이블 트라이셉스 푸시다운",
            english_name="Triceps Pushdown",
            category="팔",
            equipment="케이블",
            target_muscle="상완삼두근 (외측두/장두)",
            image_url="https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=400&auto=format&fit=crop&q=80",
            instructions="팔꿈치 위치를 고정한 뒤 손목이 꺾이지 않게 아래로 쭉 펴서 삼두근을 강하게 쥐어짭니다."
        ),

        # --- 복근 & 유산소 (Core & Cardio) ---
        ExerciseMaster(
            name="행잉 레그 레이즈",
            english_name="Hanging Leg Raise",
            category="복근",
            equipment="맨몸",
            target_muscle="복직근 하부, 장요근",
            image_url="https://images.unsplash.com/photo-1598971639058-fab3c3109a00?w=400&auto=format&fit=crop&q=80",
            instructions="철봉에 매달려 반동 없이 골반을 말아 올린다는 느낌으로 다리를 90도 이상 들어 올립니다."
        ),
        ExerciseMaster(
            name="트레드밀 인클라인 워킹",
            english_name="Incline Treadmill",
            category="복근",
            equipment="머신",
            target_muscle="심폐지구력, 하체 후면 사슬",
            image_url="https://images.unsplash.com/photo-1517838277536-f5f99be501cd?w=400&auto=format&fit=crop&q=80",
            instructions="경사도 8~12%, 속도 4.5~5.5km/h로 설정하고 손잡이를 잡지 않은 채 바른 자세로 걷습니다."
        ),
    ]

    db.add_all(exercises)
    db.commit()
