# 🏋️ CoachFit - 피트니스 트래킹 & 맞춤형 AI 코칭 서비스

'플릭(Fleek)'을 벤치마킹한 고도화된 피트니스 트래킹 및 맞춤형 AI 코칭 서비스 모노레포(Monorepo) 프로젝트입니다.

---

## 🏗️ 1. 전체 아키텍처 및 데이터 흐름 (FastAPI + PostgreSQL 단일 백엔드)

> **교수님 피드백 반영 (ADR-0004)**: 2인 프로젝트의 오버엔지니어링(Java + Python 이원화)을 해소하고, 지도 교수님의 권고 스택인 **FastAPI + PostgreSQL**로 백엔드를 단일 통합하였습니다. ([ADR-0004](./planning/decisions/ADR-0004-unify-fastapi-postgresql-backend.md))  
> 기존 `java-backend/`는 학습 및 아키텍처 비교용 레퍼런스로 보존되며, 실제 서비스 운영 및 모바일 연동은 `python-ai-backend(포트 8000)` 단일 서버로 실행됩니다.

```
[모바일 앱 (iOS/Android/Windows/Web)] (Flutter)
        │
        ▼ REST API (포트 8000 단일 통합)
[FastAPI 통합 백엔드] (FastAPI, SQLAlchemy, Pydantic v2, OpenAI)
    ├── 1. 운동 기록 CRUD & 주간 볼륨 집계 (/api/workouts)
    ├── 2. DB 기반 AI 맞춤 코칭 생성 (/api/coaching/generate)
    ├── 3. 운동 종목 마스터 & 3D 근육 맵 타겟 부위 (/api/exercises)
    └── 4. 자동 완성 인터랙티브 API 명세 (/docs)
        │
        ├──▶ [PostgreSQL / SQLite 데이터베이스] (운동 기록 영구 보관)
        └──▶ [OpenAI LLM API] (맞춤 루틴 및 코칭 피드백 생성)
```

---

## 📁 2. 전체 디렉토리 구조 트리

```text
coach fit/
├── mobile-app/                        # Flutter 스마트폰 및 데스크톱 앱 (iOS/Android/Windows/Web)
│   ├── pubspec.yaml                   # Flutter 의존성 (fl_chart, shared_preferences 등)
│   └── lib/
│       ├── main.dart                  # 플러터 앱 진입점 (AMOLED 다크 테마)
│       ├── config/
│       │   └── api_constants.dart     # 에뮬레이터(10.0.2.2)/실기기/PC(localhost) URL 자동 분기
│       ├── models/
│       │   ├── workout.dart           # 운동 기록 데이터 모델
│       │   ├── user_profile.dart      # 사용자 신체 스펙 및 프로필 모델
│       │   └── coaching_result.dart   # AI 코칭 결과 데이터 모델
│       ├── services/
│       │   ├── workout_service.dart   # FastAPI 백엔드 운동 기록 CRUD & 주간 통계 연동
│       │   ├── coaching_service.dart  # AI 코칭 생성 연동 서비스
│       │   ├── profile_service.dart   # SharedPreferences 기반 프로필 로컬 영속화
│       │   └── goal_service.dart      # 운동 목표(근비대/감량/근력) 로컬 영속화 & 실시간 반영
│       └── screens/
│           ├── tabs/                  # 하단 5개 탭 화면
│           │   ├── home_tab.dart      # 홈 (3D 인터랙티브 근육 맵, AI 추천 루틴)
│           │   ├── history_tab.dart   # 기록 (원터치 복사 칩, 날짜별 운동 히스토리)
│           │   ├── stats_tab.dart     # 통계 (주간 볼륨 차트, 부위별 볼륨 배분)
│           │   ├── community_tab.dart # 커뮤니티 탭
│           │   └── menu_tab.dart      # 메뉴 (프로필 카드, 목표 설정, 환경 설정)
│           └── profile_edit_screen.dart # 신체 정보 및 경력 편집 화면
│
├── python-ai-backend/                 # Python FastAPI 통합 백엔드 서버 (포트 8000)
│   ├── requirements.txt               # 필수 라이브러리 (fastapi, uvicorn, openai, sqlalchemy 등)
│   ├── .env.example                   # 환경 변수 템플릿 (OPENAI_API_KEY, DATABASE_URL 등)
│   ├── coachfit.db                    # 로컬 SQLite 기본 데이터베이스
│   └── app/
│       ├── main.py                    # FastAPI 메인 엔트리포인트 (CORS, 라우팅, 초기 시드)
│       ├── database.py                # DB 연결 및 테이블 생성
│       ├── models/
│       │   ├── models.py              # SQLAlchemy DB 테이블 모델 (WorkoutRecord, ExerciseMaster)
│       │   └── schemas.py             # Pydantic v2 스키마 (요청/응답 모델)
│       └── services/
│           ├── workout_service.py     # 운동 기록 CRUD 및 주간 볼륨 집계 비즈니스 로직
│           ├── exercise_service.py    # 운동 종목 마스터 및 시드 데이터
│           └── ai_coach.py            # 스마트 더미 코칭 엔진 및 OpenAI GPT-4o 연동
│
├── docs/                              # 🌐 GitHub Pages 온라인 웹 문서 포털 (Docsify)
│   ├── index.html                     # 다크 테마 및 인터랙티브 Mermaid 렌더링
│   ├── _sidebar.md                    # 문서 사이드바 네비게이션
│   └── *.md                           # 웹 포털 렌더링용 기획 및 기술 문서
│
├── planning/                          # 프로젝트 공식 기획 및 아키텍처 문서
│   ├── 01-vision-and-scope.md         # 비전 및 범위 정의서 (MoSCoW)
│   ├── 02-wbs-and-schedule.md         # WBS 및 로드맵 간트 차트
│   ├── 03-team-and-git-convention.md  # Git 협업 규칙 및 브랜치 전략
│   ├── 04-risk-management.md          # 5대 리스크 관리 및 발표장 대응
│   └── decisions/                     # 아키텍처 결정 레코드 (ADR-0001 ~ 0004)
│
├── java-backend/                      # (참고용 레퍼런스 보존) 초기 Java Spring Boot 프로토타입
├── setup.md                           # 🚀 로컬 개발 및 서버 실행 상세 가이드
├── AGENTS.md                          # AI 에이전트 행동 및 Git 작업 규칙
└── README.md                          # 프로젝트 종합 가이드 문서
```

---

## 🚀 3. 로컬 실행 방법

> 💡 **자세한 단계별 실행 및 트러블슈팅 가이드는 [setup.md](./setup.md)에서 확인하실 수 있습니다.**

### (1) Python FastAPI 백엔드 서버 실행 (포트 8000)

```powershell
cd "C:\coach fit\python-ai-backend"

# 가상환경 활성화 없이도 프로젝트 전용 venv로 즉시 실행
.\venv\Scripts\python.exe -m uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```
- **서버 기본 접속**: [http://localhost:8000](http://localhost:8000)
- **인터랙티브 API 명세서 (Swagger)**: [http://localhost:8000/docs](http://localhost:8000/docs)
- **대체 API 명세서 (ReDoc)**: [http://localhost:8000/redoc](http://localhost:8000/redoc)

---

### (2) Flutter 모바일/웹/데스크톱 앱 실행

새 터미널을 열고 아래 명령어를 실행합니다:

```powershell
cd "C:\coach fit\mobile-app"

# 1. 의존성 패키지 설치
flutter pub get

# 2-a. Windows 데스크톱 앱으로 실행 (추천 - 가장 빠르고 직관적)
flutter run -d windows

# 2-b. Chrome 웹 브라우저로 실행
flutter run -d chrome

# 2-c. Android 에뮬레이터 또는 스마트폰 실기기
flutter run
```
- Android 에뮬레이터 구동 시 `http://10.0.2.2:8000`으로 자동 연결됩니다.
- 모바일 화면에서 운동 기록 등록, 최근 세트 원터치 복사, 3D 근육 맵 시각화 및 AI 코칭 추천을 바로 테스트할 수 있습니다.

---

## 📡 4. 주요 API 명세 요약 (FastAPI: 포트 8000)

| Method | Endpoint | 설명 |
| :--- | :--- | :--- |
| `GET` | `/` | 서버 헬스체크 및 실행 상태 반환 |
| `GET` | `/docs` | OpenAPI 기반 인터랙티브 Swagger UI |
| `POST` | `/api/workouts` | 운동 기록 등록 (종목, 세트, 횟수, 중량, 날짜, 메모) |
| `GET` | `/api/workouts?user_id=user_01` | 사용자의 전체 운동 기록 최신순 조회 |
| `DELETE`| `/api/workouts/{workout_id}` | 특정 운동 기록 삭제 |
| `GET` | `/api/workouts/weekly-stats` | 요일별 누적 볼륨 통계 (차트 시각화용) |
| `POST` | `/api/coaching/generate` | DB 운동 기록 기반 AI 맞춤 코칭 및 추천 루틴 실시간 생성 |
| `GET` | `/api/exercises` | 운동 종목 마스터 사전 및 타겟 근육 부위 리스트 조회 |

---

## ⚙️ 5. 환경 변수 설정 (선택 사항)

기본적으로 별도 설정 없이도 **지능형 스마트 룰베이스 코칭 엔진**과 **로컬 SQLite DB(`coachfit.db`)**로 완벽하게 즉시 동작합니다.

실제 OpenAI 최신 LLM이나 PostgreSQL 연동을 원하실 경우 `python-ai-backend/.env`를 생성하여 지정할 수 있습니다:
```env
# AI API 설정 (설정하지 않으면 스마트 더미 코칭 모드로 자동 동작)
OPENAI_API_KEY=your_openai_api_key_here
AI_PROVIDER=openai # dummy | openai | claude

# PostgreSQL 연동 시 (미설정 시 로컬 coachfit.db 자동 사용)
# DATABASE_URL=postgresql://postgres:password@localhost:5432/coachfit
```
