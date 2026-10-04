# 🏋️ CoachFit - 피트니스 트래킹 & 맞춤형 AI 코칭 서비스

'플릭(Flik)'과 유사한 피트니스 트래킹 및 맞춤형 AI 코칭 서비스의 모노레포(Monorepo) 초기 뼈대(Skeleton) 프로젝트입니다.

---

## 🏗️ 1. 전체 아키텍처 및 데이터 흐름 (FastAPI + PostgreSQL 단일 백엔드)

> **교수님 피드백 반영**: 2인 프로젝트의 오버엔지니어링(Java + Python 이원화)을 해소하고, 지도 교수님의 권고 스택인 **FastAPI + PostgreSQL**로 백엔드를 단일 통합하였습니다. ([ADR-0004](./planning/decisions/ADR-0004-unify-fastapi-postgresql-backend.md))

```
[모바일 앱 (iOS/Android)] (Flutter)  OR  [웹 대시보드] (Chart.js)
        │
        ▼ REST API (포트 8000 단일 통합)
[FastAPI 통합 백엔드] (FastAPI, SQLAlchemy, Pydantic, OpenAI)
    ├── 1. 운동 기록 CRUD & 주간 볼륨 집계 (/api/workouts)
    ├── 2. DB 기반 AI 맞춤 코칭 생성 (/api/coaching/generate)
    └── 3. 자동 완성 인터랙티브 API 명세 (/docs)
        │
        ├──▶ [PostgreSQL 데이터베이스] (운동 기록 영구 보관)
        └──▶ [OpenAI LLM API] (맞춤 루틴 및 코칭 피드백 생성)
```

> **참고**: 기존 `java-backend/`는 학습 및 아키텍처 비교용 레퍼런스로 보존되며, 실제 서비스 운영 및 모바일 연동은 `python-ai-backend(포트 8000)` 단일 서버로 실행됩니다.

---

## 📁 2. 전체 디렉토리 구조 트리

```text
coach fit/
├── mobile-app/                        # Flutter 스마트폰 앱 (iOS/Android)
│   ├── pubspec.yaml                   # Flutter 의존성 (http, intl 등)
│   └── lib/
│       ├── main.dart                  # 플러터 앱 진입점 (다크 테마)
│       ├── config/
│       │   └── api_constants.dart     # 에뮬레이터(10.0.2.2)/실기기/iOS URL 자동 분기
│       ├── models/
│       │   ├── workout.dart           # 운동 기록 데이터 모델
│       │   └── coaching_result.dart   # AI 코칭 결과 데이터 모델
│       ├── services/
│       │   ├── workout_service.dart   # Java 서버 연동 서비스
│       │   └── coaching_service.dart  # AI 코칭 연동 서비스
│       └── screens/
│           ├── home_screen.dart       # 운동 기록 조회/추가 대시보드 화면
│           └── coaching_screen.dart   # AI 분석 진단 및 추천 루틴 화면
│
├── java-backend/                      # Java Spring Boot 서버 (담당자 A)
│   ├── build.gradle                   # Gradle 빌드 스크립트 (Web, JPA, MySQL, JWT, Lombok)
│   ├── settings.gradle
│   └── src/
│       └── main/
│           ├── java/com/coachfit/backend/
│           │   ├── CoachFitApplication.java         # 메인 애플리케이션 클래스
│           │   ├── config/
│           │   │   ├── CorsConfig.java              # 프론트엔드 연동 CORS 허용 설정
│           │   │   └── RestTemplateConfig.java      # Python 서버 연동 HTTP 클라이언트
│           │   ├── controller/
│           │   │   ├── WorkoutController.java       # 운동 기록 CRUD 및 주간 통계 API
│           │   │   └── CoachingController.java      # Python AI 서버 중계 엔드포인트
│           │   ├── dto/
│           │   │   ├── WorkoutRequest.java          # 운동 기록 등록 요청 DTO
│           │   │   ├── WorkoutResponse.java         # 운동 기록 응답 DTO
│           │   │   ├── CoachingRequestDto.java      # Python AI 서버 전달 DTO
│           │   │   └── CoachingResponseDto.java     # AI 코칭 응답 매핑 DTO
│           │   ├── entity/
│           │   │   └── WorkoutRecord.java           # 운동 기록 JPA 엔티티
│           │   ├── repository/
│           │   │   └── WorkoutRepository.java       # 운동 기록 JPA 레포지토리
│           │   └── service/
│           │       ├── WorkoutService.java          # 비즈니스 로직 및 초기 더미 데이터 시드
│           │       └── AiCoachingClientService.java # Python AI 서버 통신 & 폴백 처리
│           └── resources/
│               └── application.yml                  # H2(기본)/MySQL DB 및 포트(8080) 설정
│
├── python-ai-backend/                 # Python FastAPI AI 서버 (담당자 B)
│   ├── requirements.txt               # 필수 라이브러리 (fastapi, uvicorn, openai 등)
│   ├── .env.example                   # 환경 변수 템플릿 (OPENAI_API_KEY 등)
│   └── app/
│       ├── __init__.py
│       ├── main.py                    # FastAPI 메인 엔트리포인트 (포트 8000, CORS)
│       ├── models/
│       │   ├── __init__.py
│       │   └── schemas.py             # Pydantic 스키마 (요청/응답 모델)
│       └── services/
│           ├── __init__.py
│           └── ai_coach.py            # 스마트 더미 코칭 엔진 및 OpenAI 연동 함수
│
├── frontend/                          # 프론트엔드 대시보드 화면
│   ├── index.html                     # 대시보드 마크업 (차트 + 폼 + AI 카드)
│   ├── style.css                      # 다크 테마 플릭 스타일 CSS
│   └── app.js                         # Java & Python API 비동기 통신 및 Chart.js 렌더링
│
├── setup.md                           # 🚀 로컬 개발 및 서버 실행 상세 가이드
└── README.md                          # 프로젝트 종합 가이드 문서
```

---

## 🚀 3. 로컬 실행 방법

> 💡 **자세한 단계별 실행 및 트러블슈팅 가이드는 [setup.md](./setup.md)에서 확인하실 수 있습니다.**

### (1) Java Spring Boot 서버 실행 (포트 8080)

> 초기 실행 시 별도의 DB 설치 없이 바로 구동될 수 있도록 **H2 인메모리 DB**가 기본 적용되어 있으며, 서버 시작 시 5개의 기초 운동 더미 데이터가 자동 생성됩니다.

```bash
cd java-backend

# Gradle 빌드 및 실행 (Windows)
./gradlew bootRun

# 또는 IntelliJ IDEA / Eclipse / VSCode에서 CoachFitApplication.java 실행
```
- 서버 URL: `http://localhost:8080`
- H2 콘솔: `http://localhost:8080/h2-console` (JDBC URL: `jdbc:h2:mem:coachfitdb`, User: `sa`, Password: 빈값)

---

### (2) Python FastAPI 서버 실행 (포트 8000)

```bash
cd python-ai-backend

# 1. 가상환경 생성 및 활성화 (Windows PowerShell 기준)
python -m venv venv
.\venv\Scripts\Activate.ps1

# 2. 필수 의존성 패키지 설치
pip install -r requirements.txt

# 3. 환경 변수 파일 생성 (선택 사항 - 설정하지 않아도 스마트 더미 엔진으로 동작)
copy .env.example .env

# 4. FastAPI 서버 실행
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
# 또는: python -m app.main
```
- 서버 URL: `http://localhost:8000`
- Swagger API 문서: `http://localhost:8000/docs`

---

### (3) Flutter 모바일 앱 실행 (iOS / Android / Chrome)

```bash
cd mobile-app

# 1. 의존성 패키지 설치
flutter pub get

# 2. 앱 실행 (에뮬레이터, 연결된 스마트폰, 또는 크롬 브라우저)
flutter run
# 또는: flutter run -d chrome (웹 모드로 즉시 실행)
```
- Android 에뮬레이터 구동 시 `http://10.0.2.2:8080`(Java)로 자동 연결됩니다.
- 모바일 화면에서 운동 기록 등록 및 "분석" 버튼을 눌러 AI 코칭을 받아볼 수 있습니다.

---

### (4) 웹 프론트엔드 대시보드 열기 (선택 사항)

`frontend/index.html` 파일을 크롬 등 웹 브라우저에서 직접 더블 클릭하여 열거나, VS Code의 `Live Server` 확장 등을 이용해 실행할 수 있습니다.
- 상단 서버 상태 배지에 `Java 서버 (8080)` 및 `Python AI 서버 (8000)`가 녹색으로 켜지는지 확인합니다.
- 운동 기록을 추가하면 실시간으로 하단 테이블과 주간 운동량 그래프가 갱신됩니다.
- "⚡ AI 코칭 분석 및 오늘의 맞춤 루틴 생성하기" 버튼을 클릭하여 AI 분석 결과를 확인합니다.

---

## 📡 4. 주요 API 명세 요약

### [Java 서버: http://localhost:8080]
| Method | Endpoint | 설명 |
| :--- | :--- | :--- |
| `POST` | `/api/workouts` | 운동 기록 등록 (종목, 세트, 횟수, 중량, 날짜, 메모) |
| `GET` | `/api/workouts?userId=user_01` | 사용자의 전체 운동 기록 최신순 조회 |
| `GET` | `/api/workouts/weekly-stats` | Chart.js 렌더링용 요일별 누적 볼륨 통계 |
| `POST` | `/api/coaching/generate` | DB의 운동 기록을 추출해 Python AI 서버로 중계 호출 |

### [Python AI 서버: http://localhost:8000]
| Method | Endpoint | 설명 |
| :--- | :--- | :--- |
| `GET` | `/health` | 서버 헬스체크 |
| `POST` | `/api/coaching` | 운동 기록 목록을 받아 분석 요약, 피드백, 오늘 추천 루틴 반환 |

---

## ⚙️ 5. 확장 가이드 (MySQL 및 실제 LLM 연동)

1. **MySQL / AWS RDS 연동**:
   - `java-backend/src/main/resources/application.yml` 파일에서 MySQL 설정 주석을 해제하고 접속 주소와 비밀번호를 입력합니다.
2. **OpenAI / Claude API 연동**:
   - `python-ai-backend/.env` 파일에 `OPENAI_API_KEY=sk-...` 및 `AI_PROVIDER=openai`를 지정하면 실제 최신 LLM(`gpt-4o-mini` 등)을 통한 개인 맞춤 코칭이 활성화됩니다.
