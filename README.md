# 🏋️ CoachFit - 피트니스 트래킹 & 맞춤형 AI 코칭 서비스

'플릭(Fleek)'을 벤치마킹한 고도화된 피트니스 트래킹 및 맞춤형 AI 코칭 서비스 모노레포(Monorepo) 프로젝트입니다.

---

## 🏗️ 1. 전체 아키텍처 및 기술 스택

> **💡 지도 교수님 피드백 반영 및 단일 백엔드 통합 ([ADR-0004](./planning/decisions/ADR-0004-unify-fastapi-postgresql-backend.md))**  
> 2인 팀 규모 대비 불필요했던 **Java + Python 서버 이원화의 오버엔지니어링을 해소**하고, 교수님 권고 스택인 **`FastAPI + PostgreSQL` 단일 백엔드**로 통합하였습니다.  
> 기존 `java-backend/`는 학습 및 아키텍처 비교용 레퍼런스로 보존되며, 실제 서비스 운영 및 모바일 연동은 `python-ai-backend(포트 8000)` 단일 서버로 실행됩니다.

```mermaid
flowchart TD
    subgraph Client["📱 모바일 / 웹 클라이언트 (Flutter)"]
        UI["AMOLED 다크 테마 UI<br/>(3D 근육 맵 · 운동 테이블 · 볼륨 차트)"]
        LocalStore["SharedPreferences<br/>(JWT 토큰 · 로컬 캐시)"]
        UI <--> LocalStore
    end

    subgraph Backend["⚡ 통합 백엔드 서버 (FastAPI: 포트 8000)"]
        AuthLayer["🔐 JWT 인증 & 암호화<br/>(Bcrypt / PyJWT)"]
        Router["RESTful API 라우터<br/>(Pydantic v2 검증)"]
        
        subgraph Services["비즈니스 서비스 레이어"]
            S_Auth["AuthService<br/>(가입/로그인/세션)"]
            S_Workout["WorkoutService<br/>(운동 기록 CRUD & 주간 볼륨)"]
            S_Metric["BodyMetricService<br/>(체중/골격근/체지방)"]
            S_Profile["UserProfileService<br/>(신체 스펙 & 목표)"]
            S_AI["AICoachService<br/>(개인화 추천 루틴 생성)"]
        end

        AuthLayer --> Router
        Router --> Services
    end

    subgraph Database["🗄️ 데이터 영속성 계층 (SQLAlchemy ORM)"]
        DB_Dev[("로컬 개발: SQLite<br/>coachfit.db")]
        DB_Prod[("실제 배포: PostgreSQL<br/>(AWS RDS / Supabase / EC2)")]
    end

    subgraph External["🤖 외부 AI 서비스"]
        OpenAI["OpenAI API<br/>(GPT-4o 맞춤 코칭)"]
    end

    Client -- "HTTP/REST (Bearer JWT 토큰)" --> AuthLayer
    Services -- "SQLAlchemy ORM (유저별 격리)" --> Database
    S_AI -- "프롬프트 & 신체/운동 컨텍스트" --> OpenAI
```

### 기술 스택 세부 구성

| 계층 (Layer) | 기술 스택 | 적용 목적 및 특징 |
| :--- | :--- | :--- |
| **모바일/클라이언트** | **Flutter 3.x (Dart)** | iOS, Android, Windows, Web 멀티플랫폼 지원. AMOLED 다크 테마(`#0E1116`), 3D 해부도 다중 레이어 점등 근육 맵, `fl_chart` 볼륨 시각화 |
| **통합 백엔드** | **Python FastAPI (단일 백엔드)** | 고성능 비동기 처리, Pydantic v2 기반 엄격한 데이터 검증, 인터랙티브 API 문서 자동 생성(`/docs`) |
| **인증 & 보안** | **JWT (JSON Web Token) + Bcrypt** | 비밀번호 단방향 솔팅 해시 암호화, Stateless Bearer 토큰 인증, 완벽한 사용자별 데이터 격리(Multi-tenancy) 지원 |
| **데이터베이스 & ORM** | **PostgreSQL + SQLAlchemy** | 관계형 데이터 영속성 보장. 로컬 개발 시에는 무설정 `SQLite(coachfit.db)`로 자동 폴백, 배포 시 환경변수(`DATABASE_URL`) 하나로 PostgreSQL 즉시 전환 |
| **AI 코칭 엔진** | **OpenAI GPT-4o + 스마트 룰베이스** | 사용자의 최근 10회 운동 기록, 체성분(골격근/체지방), 신체 스펙, 운동 목표를 종합 프롬프팅하여 개인화 맞춤 루틴 및 팁 생성 |

---

## 💡 2. 왜 이 아키텍처를 선택했는가? (설계 결정 배경)

### (1) 2인 개발 팀의 생산성 극대화 (오버엔지니어링 해소)
- 기존에는 Java Spring Boot(메인)와 Python FastAPI(AI)로 서버 2개를 동시에 돌리는 구조였습니다.
- 하지만 2인 프로젝트에서 서버 2개를 동시에 관리하는 것은 **DTO 이중 작성(Java DTO ↔ Pydantic Schema)**, **포트 이원화(8080, 8000)**, **서버 간 네트워크 통신 오류 처리** 등 심각한 유지보수 비용을 초래했습니다.
- 이에 지도 교수님의 권고를 수용하여 **FastAPI 단일 백엔드로 통합**함으로써 핵심 기능 개발 속도를 3배 이상 향상시켰습니다.

### (2) AWS 프리티어(EC2 t2.micro) 인프라 비용 및 메모리 최적화
- AWS 프리티어 인스턴스(`t2.micro`)는 **RAM이 1GB**에 불과합니다.
- 무거운 JVM 기반 Spring Boot와 DB, AI 서버를 함께 올리면 메모리 부족(OOM: Out Of Memory)으로 서버가 다운되는 현상이 빈번합니다.
- 반면 FastAPI는 **메모리 점유율이 100MB 안팎**으로 매우 가벼워, 저사양 클라우드 인스턴스에서도 다운 없이 안정적으로 구동됩니다.

### (3) 다중 사용자(Multi-tenancy) 데이터 격리 및 영속성 보장
- 각 사용자의 운동 기록, 체성분, 프로필은 고유한 `user_id`를 기준으로 분리 저장됩니다.
- 로그인 시 발급받은 **JWT Access Token**을 모든 API 요청 헤더(`Authorization: Bearer <token>`)에 첨부하여, 다른 사용자의 데이터와 철저히 분리된 안전한 CRUD 환경을 제공합니다.
- 발표 및 시연 시 편의를 위해 **1초 원터치 데모 로그인(`demo@coachfit.com`)**도 함께 지원합니다.

---

## 📁 3. 전체 디렉토리 구조 트리

```text
coach fit/
├── mobile-app/                        # Flutter 스마트폰 및 데스크톱 앱 (iOS/Android/Windows/Web)
│   ├── pubspec.yaml                   # Flutter 의존성 (fl_chart, shared_preferences 등)
│   └── lib/
│       ├── main.dart                  # 플러터 앱 진입점 (세션 검사 후 자동 라우팅)
│       ├── config/
│       │   └── api_constants.dart     # 접속 URL 자동 분기 (에뮬레이터 10.0.2.2 / PC localhost / 실기기 IP)
│       ├── models/                    # 데이터 모델 (Workout, AuthUser, UserProfile, CoachingResult 등)
│       ├── services/                  # REST API 연동 서비스
│       │   ├── auth_service.dart      # JWT 회원가입 / 로그인 / 토큰 SharedPreferences 관리
│       │   ├── workout_service.dart   # 운동 기록 CRUD & 주간 통계 연동 (JWT 헤더 자동 첨부)
│       │   ├── coaching_service.dart  # AI 코칭 생성 연동 서비스
│       │   └── profile_service.dart   # 신체 프로필 DB 동기화 서비스
│       └── screens/
│           ├── auth/                  # 사용자 인증 화면
│           │   ├── login_screen.dart  # AMOLED 다크 테마 로그인 화면 (데모 1초 로그인 포함)
│           │   └── register_screen.dart # 신규 회원가입 및 초기 신체 스펙 설정
│           ├── tabs/                  # 하단 5대 메인 탭 화면
│           │   ├── home_tab.dart      # 홈 (3D 인터랙티브 근육 맵, AI 추천 루틴)
│           │   ├── history_tab.dart   # 기록 (원터치 복사 칩, 날짜별 운동 히스토리)
│           │   ├── stats_tab.dart     # 통계 (주간 볼륨 차트, 부위별 볼륨 배분)
│           │   ├── community_tab.dart # 커뮤니티 탭
│           │   └── menu_tab.dart      # 메뉴 (프로필 카드, 목표 설정, 로그아웃)
│           └── profile_edit_screen.dart # 신체 정보 및 경력 편집 화면
│
├── python-ai-backend/                 # Python FastAPI 통합 백엔드 서버 (포트 8000)
│   ├── requirements.txt               # 필수 라이브러리 (fastapi, uvicorn, sqlalchemy, pyjwt, bcrypt 등)
│   ├── .env.example                   # 환경 변수 템플릿 (DATABASE_URL, OPENAI_API_KEY 등)
│   ├── coachfit.db                    # 로컬 SQLite 기본 데이터베이스
│   └── app/
│       ├── main.py                    # FastAPI 메인 엔트리포인트 (CORS, 라우팅, 초기 시드)
│       ├── database.py                # DB 엔진 (PostgreSQL / SQLite 자동 전환)
│       ├── utils/
│       │   └── security.py            # Bcrypt 비밀번호 해싱 및 JWT 토큰 발급/검증
│       ├── dependencies/
│       │   └── auth.py                # Bearer JWT 검증 FastAPI 의존성 주입 (get_current_user)
│       ├── models/                    # DB 테이블 엔티티 및 Pydantic v2 스키마
│       │   ├── user_db.py             # 회원 계정 DB 모델 (users)
│       │   ├── workout_db.py          # 운동 기록 DB 모델 (workout_records)
│       │   ├── body_metric_db.py      # 체성분 인바디 DB 모델 (body_metrics)
│       │   ├── user_profile_db.py     # 프로필 DB 모델 (user_profiles)
│       │   └── schemas.py             # Pydantic 요청/응답 검증 스키마
│       └── services/                  # 비즈니스 로직 (CRUD, 인증, 통계, AI 코칭)
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

## 🚀 4. 로컬 실행 방법

> 💡 **자세한 단계별 실행 및 트러블슈팅 가이드는 [setup.md](./setup.md)에서 확인하실 수 있습니다.**

### (1) Python FastAPI 백엔드 서버 실행 (포트 8000)

```powershell
cd "C:\coach fit\python-ai-backend"

# 가상환경 활성화 없이도 프로젝트 전용 venv로 즉시 실행
.\venv\Scripts\python.exe -m uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```
- **서버 기본 접속**: [http://localhost:8000](http://localhost:8000)
- **인터랙티브 API 명세서 (Swagger UI)**: [http://localhost:8000/docs](http://localhost:8000/docs)
- 기본 데모 계정이 자동 생성됩니다: `demo@coachfit.com` / `password123`

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
- 로그인 화면에서 **[시연용 데모 계정으로 1초 로그인]**을 누르면 즉시 시연 데이터를 확인할 수 있습니다.

---

## 📡 5. 주요 API 명세 요약 (FastAPI: 포트 8000)

### 🔐 인증(Auth) API
| Method | Endpoint | 설명 |
| :--- | :--- | :--- |
| `POST` | `/api/auth/register` | 신규 회원가입 (비밀번호 Bcrypt 암호화 + JWT 토큰 즉시 발급) |
| `POST` | `/api/auth/login` | 이메일/비밀번호 로그인 및 JWT 토큰 반환 |
| `GET` | `/api/auth/me` | 현재 로그인된 사용자의 계정 정보 조회 (`Bearer <token>` 필수) |

### 🏋️ 운동 기록 및 코칭 API
| Method | Endpoint | 설명 |
| :--- | :--- | :--- |
| `GET` | `/docs` | OpenAPI 기반 인터랙티브 Swagger UI |
| `POST` | `/api/workouts` | 운동 기록 등록 (종목, 세트, 횟수, 중량, 날짜, 메모) |
| `GET` | `/api/workouts` | 사용자의 전체 운동 기록 최신순 조회 (유저별 격리) |
| `DELETE`| `/api/workouts/{workout_id}` | 특정 운동 기록 삭제 |
| `GET` | `/api/workouts/weekly-stats` | 요일별 누적 볼륨 통계 (차트 시각화용) |
| `POST` | `/api/coaching/generate` | DB 운동 기록 기반 AI 맞춤 코칭 및 추천 루틴 실시간 생성 |
| `GET` | `/api/exercises` | 운동 종목 마스터 사전 및 타겟 근육 부위 리스트 조회 |
| `GET` | `/api/profile` | 사용자 신체 스펙 및 맞춤 운동 목표 조회 |
| `PUT` | `/api/profile` | 사용자 신체 스펙 및 맞춤 운동 목표 수정 |
| `GET` | `/api/body-metrics` | 신체 측정(인바디: 체중/골격근/체지방) 이력 전체 조회 |

---

## ☁️ 6. 클라우드 배포 가이드 (AWS EC2 + PostgreSQL)

실제 외부 사용자를 대상으로 앱을 서비스하거나 발표 시연할 때의 배포 구성입니다:

```text
[스마트폰 클라이언트 (Flutter App)]
       │
       ▼ (HTTPS / HTTP)
[AWS EC2 인스턴스 (Ubuntu, t2.micro 프리티어)]
       ├── Uvicorn + FastAPI (포트 8000)
       └── Systemd 또는 Docker 컨테이너 데몬 실행
              │
              ▼ (PostgreSQL 접속)
[PostgreSQL DB] (AWS RDS PostgreSQL 또는 Supabase 무료 클라우드 DB)
```

1. **클라우드 데이터베이스 생성 (Supabase or AWS RDS)**:
   - Supabase(무료) 또는 AWS RDS에서 PostgreSQL 데이터베이스를 생성하고 접속 URL을 확인합니다.
2. **백엔드 환경 변수(`.env`) 설정**:
   ```env
   DATABASE_URL=postgresql://postgres:password@your-db-host:5432/coachfit
   JWT_SECRET_KEY=your-production-secret-key
   OPENAI_API_KEY=your-openai-api-key
   ```
3. **모바일 앱 접속 호스트 연결**:
   - `mobile-app/lib/config/api_constants.dart`의 `baseUrl`에 EC2 공인 IP(`http://<EC2-IP>:8000`)를 설정하여 빌드/배포합니다.
