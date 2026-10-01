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


def seed_exercise_masters(db: Session, force: bool = False):
    """
    3D 인체 해부도 렌더/GIF 애니메이션이 포함된 운동 마스터 24선 데이터 시딩
    - 플릭(Fleek), Hevy 스타일의 3D 회색 모델 + 타겟 근육(빨간색) 하이라이트 그래픽 에셋
    """
    first_item = db.query(ExerciseMaster).first()
    # 이미 3D CDN GIF 데이터가 세팅되어 있고 force가 아니면 스킵
    if not force and first_item and "exercises-gifs" in (first_item.image_url or ""):
        return

    # 기존 데이터가 있으면 삭제 후 3D 데이터로 갱신
    if first_item:
        db.query(ExerciseMaster).delete()
        db.commit()

    base_cdn = "https://cdn.jsdelivr.net/gh/omercotkd/exercises-gifs@main/assets"

    exercises = [
        # --- 가슴 (Chest) ---
        ExerciseMaster(
            name="머신 체스트 프레스",
            english_name="Lever Chest Press",
            category="가슴",
            equipment="머신",
            target_muscle="가슴, 어깨",
            image_url=f"{base_cdn}/0577.gif",
            instructions="안장 높이를 조절하여 손잡이가 가슴 중앙에 오도록 하고, 어깨가 솟지 않게 견갑을 고정한 채 밀어냅니다."
        ),
        ExerciseMaster(
            name="바벨 벤치프레스",
            english_name="Barbell Bench Press",
            category="가슴",
            equipment="바벨",
            target_muscle="가슴, 어깨, 삼두",
            image_url=f"{base_cdn}/0025.gif",
            instructions="견갑골을 모아 벤치에 단단히 밀착시키고, 바를 젖꼭지 아래 지점으로 수직 하강 후 가슴으로 밀어올립니다."
        ),
        ExerciseMaster(
            name="인클라인 덤벨 프레스",
            english_name="Incline Dumbbell Press",
            category="가슴",
            equipment="덤벨",
            target_muscle="가슴(상부), 어깨",
            image_url=f"{base_cdn}/0314.gif",
            instructions="벤치 각도를 30~45도로 맞추고, 팔꿈치가 어깨보다 과도하게 올라가지 않도록 주의하며 덤벨을 모아줍니다."
        ),
        ExerciseMaster(
            name="케이블 플라이",
            english_name="Cable Incline Fly",
            category="가슴",
            equipment="케이블",
            target_muscle="가슴(안쪽), 어깨",
            image_url=f"{base_cdn}/0172.gif",
            instructions="팔꿈치 각도를 살짝 굽힌 채 고정하고, 큰 나무를 안는다는 느낌으로 가슴 안쪽을 쥐어짜듯 모읍니다."
        ),
        ExerciseMaster(
            name="딥스 (가슴/삼두)",
            english_name="Chest Dips",
            category="가슴",
            equipment="맨몸",
            target_muscle="가슴(하부), 삼두",
            image_url=f"{base_cdn}/0009.gif",
            instructions="상체를 앞으로 30도 정도 기울여 가슴 하부에 체중을 실으며 팔꿈치가 90도가 될 때까지 내려갑니다."
        ),

        # --- 하체 (Legs) ---
        ExerciseMaster(
            name="바벨 스쿼트",
            english_name="Barbell Full Squat",
            category="하체",
            equipment="바벨",
            target_muscle="대퇴사두, 둔근",
            image_url=f"{base_cdn}/0043.gif",
            instructions="바벨을 승모근 상단에 얹고, 무릎과 발끝의 방향을 일치시킨 채 고관절을 접으며 깊게 앉습니다."
        ),
        ExerciseMaster(
            name="레그 프레스",
            english_name="Lever Leg Press",
            category="하체",
            equipment="머신",
            target_muscle="대퇴사두, 둔근",
            image_url=f"{base_cdn}/2287.gif",
            instructions="허리가 패드에서 뜨지 않도록 손잡이를 단단히 쥐고, 발판 중앙에 발을 두고 천천히 밀어냅니다."
        ),
        ExerciseMaster(
            name="레그 익스텐션",
            english_name="Lever Leg Extension",
            category="하체",
            equipment="머신",
            target_muscle="대퇴사두",
            image_url=f"{base_cdn}/0585.gif",
            instructions="엉덩이를 시트에 밀착시키고 정강이 패드를 발목 윗부분에 둔 뒤, 무릎을 펴 정점에서 1초간 수축합니다."
        ),
        ExerciseMaster(
            name="덤벨 런지",
            english_name="Dumbbell Lunge",
            category="하체",
            equipment="덤벨",
            target_muscle="대퇴사두, 둔근",
            image_url=f"{base_cdn}/0336.gif",
            instructions="보폭을 크게 딛고 앞뒤 무릎 각도가 90도가 되도록 수직으로 앉았다가 앞발 뒤꿈치로 밀고 일어납니다."
        ),
        ExerciseMaster(
            name="스탠딩 카프 레이즈",
            english_name="Standing Calf Raise",
            category="하체",
            equipment="머신",
            target_muscle="종아리",
            image_url=f"{base_cdn}/1372.gif",
            instructions="발끝으로 서서 발목을 최대한 높이 들어 올려 종아리(비복근)를 강하게 쥐어짭니다."
        ),

        # --- 등 (Back) ---
        ExerciseMaster(
            name="랫 풀 다운",
            english_name="Cable Lat Pulldown",
            category="등",
            equipment="머신",
            target_muscle="등, 이두",
            image_url=f"{base_cdn}/2330.gif",
            instructions="어깨 너비보다 넓게 오버그립으로 잡고, 팔꿈치를 옆구리 쪽으로 지그시 찍어 누르듯 쇄골 쪽으로 당깁니다."
        ),
        ExerciseMaster(
            name="컨벤셔널 데드리프트",
            english_name="Barbell Deadlift",
            category="등",
            equipment="바벨",
            target_muscle="등, 둔근, 햄스트링",
            image_url=f"{base_cdn}/0032.gif",
            instructions="발을 골반 너비로 벌리고 바를 정강이에 붙인 뒤, 복압을 채우고 바닥을 밀어내며 일어납니다."
        ),
        ExerciseMaster(
            name="바벨 벤트오버 로우",
            english_name="Barbell Bent-Over Row",
            category="등",
            equipment="바벨",
            target_muscle="등, 이두",
            image_url=f"{base_cdn}/0027.gif",
            instructions="상체를 45도 숙이고 허리를 곧게 편 뒤, 바벨을 아랫배(배꼽) 쪽으로 당겨 견갑골을 강하게 수축합니다."
        ),
        ExerciseMaster(
            name="시티드 케이블 로우",
            english_name="Seated Cable Row",
            category="등",
            equipment="케이블",
            target_muscle="등, 이두",
            image_url=f"{base_cdn}/0198.gif",
            instructions="허리를 펴고 가슴을 든 상태에서 어깨가 말리지 않도록 팔꿈치를 뒤로 길게 당겨 수축합니다."
        ),
        ExerciseMaster(
            name="풀업 (턱걸이)",
            english_name="Pull-Up",
            category="등",
            equipment="맨몸",
            target_muscle="등, 이두",
            image_url=f"{base_cdn}/0015.gif",
            instructions="숄더팩킹으로 어깨를 안정화한 뒤, 가슴을 바에 닿게 한다는 느낌으로 당겨 올라갑니다."
        ),

        # --- 어깨 (Shoulders) ---
        ExerciseMaster(
            name="바벨 숄더 프레스(오버헤드 프레스, 밀리터리 프레스)",
            english_name="Barbell Military Press",
            category="어깨",
            equipment="바벨",
            target_muscle="어깨, 삼두",
            image_url=f"{base_cdn}/0086.gif",
            instructions="코어와 둔근을 단단히 조이고, 바벨을 턱을 스쳐 머리 위로 수직으로 곧게 밀어올립니다."
        ),
        ExerciseMaster(
            name="덤벨 숄더 프레스",
            english_name="Dumbbell Shoulder Press",
            category="어깨",
            equipment="덤벨",
            target_muscle="어깨, 삼두",
            image_url=f"{base_cdn}/0405.gif",
            instructions="귀 높이에서 덤벨을 잡고 팔꿈치가 수직이 되도록 머리 위로 아치를 그리며 밀어 올립니다."
        ),
        ExerciseMaster(
            name="사이드 레터럴 레이즈",
            english_name="Dumbbell Lateral Raise",
            category="어깨",
            equipment="덤벨",
            target_muscle="어깨",
            image_url=f"{base_cdn}/0334.gif",
            instructions="승모근 개입을 줄이기 위해 어깨를 하강시키고, 팔꿈치를 살짝 들어 주전자로 물을 따르듯 옆으로 벌립니다."
        ),
        ExerciseMaster(
            name="페이스 풀",
            english_name="Cable Face Pull",
            category="어깨",
            equipment="케이블",
            target_muscle="어깨, 등",
            image_url=f"{base_cdn}/0179.gif",
            instructions="로프를 눈높이에 세팅하고 엄지가 뒤를 향하도록 외회전하면서 로프를 이마/눈 쪽으로 당깁니다."
        ),

        # --- 팔 (Arms) ---
        ExerciseMaster(
            name="바벨 바이셉 컬",
            english_name="Barbell Curl",
            category="팔",
            equipment="바벨",
            target_muscle="이두",
            image_url=f"{base_cdn}/0031.gif",
            instructions="팔꿈치를 옆구리에 고정하고 반동을 최소화하며 이두근의 힘으로만 바를 가슴 쪽으로 끌어올립니다."
        ),
        ExerciseMaster(
            name="케이블 트라이셉스 푸쉬다운",
            english_name="Cable Pushdown",
            category="팔",
            equipment="케이블",
            target_muscle="삼두",
            image_url=f"{base_cdn}/0201.gif",
            instructions="팔꿈치 위치를 고정한 뒤 손목이 꺾이지 않게 아래로 쭉 펴서 삼두근을 강하게 쥐어짭니다."
        ),

        # --- 복근 (Core) ---
        ExerciseMaster(
            name="행잉 레그 레이즈",
            english_name="Hanging Leg Raise",
            category="복근",
            equipment="맨몸",
            target_muscle="복근",
            image_url=f"{base_cdn}/0472.gif",
            instructions="철봉에 매달려 반동 없이 골반을 말아 올린다는 느낌으로 다리를 90도 이상 들어 올립니다."
        ),
        ExerciseMaster(
            name="플랭크",
            english_name="Front Plank",
            category="복근",
            equipment="맨몸",
            target_muscle="복근",
            image_url=f"{base_cdn}/0466.gif",
            instructions="팔꿈치를 어깨너비로 대고 머리부터 발끝까지 일직선을 만든 채 복부에 강한 긴장을 유지합니다."
        ),
    ]

    db.add_all(exercises)
    db.commit()
