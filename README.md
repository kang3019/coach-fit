# 🏋️ CoachFit - 피트니스 트래킹 & 맞춤형 AI 코칭 서비스

'플릭(Flik)'과 유사한 피트니스 트래킹 및 맞춤형 AI 코칭 서비스의 모노레포(Monorepo) 초기 뼈대(Skeleton) 프로젝트입니다.

---

## 🏗️ 1. 전체 아키텍처 및 데이터 흐름

```
[사용자 대시보드 화면] (Frontend: HTML, CSS, Vanilla JS, Chart.js)
        │
        ▼ 1. 운동 기록 등록 / 통계 조회 / AI 코칭 요청
[Java 백엔드 서버] (Spring Boot 3.2.x, JPA, MySQL/H2, JWT 뼈대)
   - 포트: 8080
   - 역할: 운동 기록 CRUD, 주간 볼륨 집계, 회원 관리 및 데이터 영속화
        │
        ▼ 2. 최근 운동 기록 전달 및 코칭 요청 (POST /api/coaching)
[Python AI 서버] (FastAPI, Pydantic, OpenAI/Claude Stub)
   - 포트: 8000
   - 역할: 운동 데이터 분석, 볼륨/부위별 피로도 분석, LLM 코칭 및 맞춤 루틴 추천
        │
        ▼ 3. 코칭 결과(JSON) 반환
[Java 백엔드 서버] ➔ [프론트엔드 대시보드 화면에 피드백 & 추천 루틴 표시]
```

> **참고**: 프론트엔드에서 개발/테스트 편의를 위해 `Java 경유(표준)` 방식과 `Python 직접 호출` 방식을 자유롭게 선택하여 테스트할 수 있도록 지원합니다.

---

## 📁 2. 전체 디렉토리 구조 트리

```text
coach fit/
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
└── README.md                          # 프로젝트 종합 가이드 문서
```

---

## 🚀 3. 로컬 실행 방법

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

### (3) 프론트엔드 화면 열기

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

## 📨 5. API 요청/응답 JSON 예시

### 5-1. `POST /api/workouts` — 운동 기록 등록 (Java)

**Request Body**
```json
{
  "userId": "user_01",
  "exerciseName": "벤치프레스",
  "sets": 4,
  "reps": 10,
  "weight": 60.0,
  "workoutDate": "2026-09-29",
  "memo": "가슴 위주 루틴"
}
```

**Response `200 OK`**
```json
{
  "id": 6,
  "userId": "user_01",
  "exerciseName": "벤치프레스",
  "sets": 4,
  "reps": 10,
  "weight": 60.0,
  "workoutDate": "2026-09-29",
  "memo": "가슴 위주 루틴",
  "createdAt": "2026-09-29T20:35:12.123"
}
```

---

### 5-2. `GET /api/workouts?userId=user_01` — 운동 기록 조회 (Java)

**Response `200 OK`**
```json
[
  {
    "id": 6,
    "userId": "user_01",
    "exerciseName": "벤치프레스",
    "sets": 4,
    "reps": 10,
    "weight": 60.0,
    "workoutDate": "2026-09-29",
    "memo": "가슴 위주 루틴",
    "createdAt": "2026-09-29T20:35:12.123"
  }
]
```

---

### 5-3. `GET /api/workouts/weekly-stats` — 주간 볼륨 통계 (Java, Chart.js용)

**Response `200 OK`**
```json
{
  "labels": ["월", "화", "수", "목", "금", "토", "일"],
  "volumes": [2400.0, 0.0, 1800.0, 0.0, 2100.0, 0.0, 0.0]
}
```
> `volume = sets × reps × weight` 의 요일별 합계

---

### 5-4. `POST /api/coaching` — AI 코칭 (Python 직접 호출)

**Request Body**
```json
{
  "user_id": "user_01",
  "user_goal": "근비대 및 전신 근력 증진",
  "recent_workouts": [
    {
      "exercise_name": "벤치프레스",
      "sets": 4,
      "reps": 10,
      "weight": 60.0,
      "date": "2026-09-29"
    }
  ]
}
```

**Response `200 OK`**
```json
{
  "summary": "최근 7일간 총 3회 운동, 상체 볼륨이 하체보다 2.3배 높음",
  "coaching_advice": "상체 편중이 감지됩니다. 오늘은 하체 세션을 권장합니다.",
  "recommended_routine": [
    {
      "exercise_name": "바벨 스쿼트",
      "sets": 4,
      "reps": 8,
      "focus": "대퇴사두근 · 둔근",
      "tip": "무릎이 발끝을 넘지 않도록 유지"
    }
  ],
  "generated_at": "2026-09-29T20:40:00.123456"
}
```

> Java 경유(`POST /api/coaching/generate`)는 body 없이 호출하면 DB의 최근 기록을 자동으로 Python 서버에 중계합니다.

---

## 🗄️ 6. DB 스키마 (ERD)

### `workout_records` 테이블

| 컬럼 | 타입 | 제약 | 설명 |
| :--- | :--- | :--- | :--- |
| `id` | `BIGINT` | PK, AUTO_INCREMENT | 기록 고유 ID |
| `user_id` | `VARCHAR` | NOT NULL, default `user_01` | 사용자 식별자 (JWT 도입 전 임시값) |
| `exercise_name` | `VARCHAR` | NOT NULL | 운동 종목명 (벤치프레스, 스쿼트 등) |
| `sets` | `INT` | NOT NULL | 세트 수 |
| `reps` | `INT` | NOT NULL | 세트당 반복 횟수 |
| `weight` | `DOUBLE` | NOT NULL | 중량 (kg) |
| `workout_date` | `DATE` | NOT NULL | 운동 수행 일자 |
| `memo` | `VARCHAR` | NULL | 자유 메모 |
| `created_at` | `DATETIME` | NOT NULL, 자동 생성 | 레코드 생성 시각 |

### 향후 확장 예정 테이블
- `users` — 회원가입/JWT 도입 시 (id, email, password_hash, nickname, goal, created_at)
- `coaching_history` — AI 코칭 응답 이력 보관 (id, user_id, summary, advice, routine_json, created_at)
- `body_metrics` — 체중/체지방 기록 (id, user_id, weight_kg, body_fat_pct, recorded_at)

---

## 🔐 7. 환경 변수(.env) 안내

`python-ai-backend/.env` — 없어도 스마트 더미 코칭 엔진으로 정상 작동합니다.

| 변수명 | 필수 | 기본값 | 설명 |
| :--- | :---: | :--- | :--- |
| `AI_PROVIDER` | ⭕ | `dummy` | `dummy` / `openai` / `claude` 중 선택 |
| `OPENAI_API_KEY` | △ | — | `AI_PROVIDER=openai` 일 때 필수 (sk-... 형태) |
| `ANTHROPIC_API_KEY` | △ | — | `AI_PROVIDER=claude` 일 때 필수 |
| `HOST` | ❌ | `0.0.0.0` | FastAPI 바인딩 호스트 |
| `PORT` | ❌ | `8000` | FastAPI 포트 |

> ⚠️ `.env` 파일은 절대 커밋 금지 (이미 `.gitignore` 등록됨). 실제 키는 팀 채팅방/노션 등 안전한 채널로 공유하세요.

Java 서버의 DB/포트 설정은 `java-backend/src/main/resources/application.yml`에서 관리합니다.

---

## 🛠️ 8. 트러블슈팅 & FAQ

<details>
<summary><b>Q1. 프론트 상단 배지에 "Java 서버 (8080)"가 빨간색이에요.</b></summary>

- `java-backend/` 폴더에서 `./gradlew bootRun` 실행됐는지 확인
- 8080 포트 충돌 시: `netstat -ano | findstr :8080` 으로 점유 프로세스 확인 후 종료, 또는 `application.yml`에서 `server.port` 변경
</details>

<details>
<summary><b>Q2. Python 서버에서 <code>ModuleNotFoundError</code>가 떠요.</b></summary>

- 가상환경 활성화 확인: `.\venv\Scripts\Activate.ps1` (터미널 앞에 `(venv)` 표시되어야 함)
- 의존성 재설치: `pip install -r requirements.txt`
</details>

<details>
<summary><b>Q3. CORS 에러 (Access-Control-Allow-Origin) 가 발생해요.</b></summary>

- Java: `config/CorsConfig.java` 의 허용 origin 확인
- Python: `app/main.py` 의 `CORSMiddleware` 설정 확인
- 프론트를 `file://` 로 열지 말고 VS Code Live Server로 열 것 (예: `http://127.0.0.1:5500`)
</details>

<details>
<summary><b>Q4. H2 콘솔에 접속했는데 테이블이 안 보여요.</b></summary>

- JDBC URL을 정확히 `jdbc:h2:mem:coachfitdb` 로 입력 (기본값과 다름)
- User: `sa`, Password: 빈 값
</details>

<details>
<summary><b>Q5. PowerShell에서 <code>Activate.ps1</code> 실행 정책 오류가 나요.</b></summary>

- 관리자 PowerShell에서: `Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser`
</details>

<details>
<summary><b>Q6. AI 코칭 응답이 계속 똑같은 더미 텍스트예요.</b></summary>

- `.env`에 `AI_PROVIDER=openai` (또는 `claude`) 로 변경했는지 확인
- API 키가 유효한지, 크레딧이 남아있는지 확인
- 서버 재시작 필수 (`.env`는 실행 시점에만 로드됨)
</details>

---

## 🖼️ 9. 스크린샷 & 데모

> 스크린샷은 `docs/screenshots/` 폴더에 저장 후 아래 경로 참조로 교체해 주세요.

| 화면 | 미리보기 |
| :--- | :--- |
| 대시보드 메인 | `![dashboard](docs/screenshots/dashboard.png)` |
| 주간 볼륨 차트 | `![weekly-chart](docs/screenshots/weekly-chart.png)` |
| AI 코칭 결과 카드 | `![ai-coach](docs/screenshots/ai-coach.png)` |
| 운동 기록 등록 폼 | `![workout-form](docs/screenshots/workout-form.png)` |

🎬 **데모 영상**: `docs/demo.gif` (30초 내 하이라이트) — 추후 추가 예정

---

## 🗺️ 10. 로드맵 / TODO

### ✅ v0.1 (현재 - 스켈레톤 완료)
- [x] 모노레포 구조 세팅 (Java + Python + Frontend)
- [x] 운동 기록 CRUD API
- [x] 주간 볼륨 통계 (Chart.js)
- [x] Python AI 서버 스마트 더미 코칭
- [x] Java ↔ Python 연동 및 폴백 처리

### 🔨 v0.2 (진행 예정)
- [ ] 실제 LLM 연동 완성 (OpenAI `gpt-4o-mini` / Claude Sonnet)
- [ ] MySQL 전환 및 마이그레이션 스크립트
- [ ] 회원가입 / 로그인 (Spring Security + JWT 실구현)
- [ ] 운동 부위(가슴/등/하체 등) 태그 자동 분류
- [ ] 코칭 히스토리 저장 및 조회

### 🚀 v0.3 (희망 사항)
- [ ] 체중/체지방 트래킹 및 그래프
- [ ] 소셜 로그인 (Google / Kakao)
- [ ] PWA 지원 (모바일 홈화면 추가)
- [ ] 운동 영상/GIF 자세 참고 링크
- [ ] Docker Compose 배포 스크립트
- [ ] AWS EC2 / RDS 배포 및 CI/CD (GitHub Actions)

### 💡 아이디어 풀
- 친구와 운동 볼륨 비교하기
- 목표 달성 뱃지 시스템
- Apple Health / Google Fit 연동

---

## ⚙️ 11. 확장 가이드 (MySQL 및 실제 LLM 연동)

1. **MySQL / AWS RDS 연동**:
   - `java-backend/src/main/resources/application.yml` 파일에서 MySQL 설정 주석을 해제하고 접속 주소와 비밀번호를 입력합니다.
2. **OpenAI / Claude API 연동**:
   - `python-ai-backend/.env` 파일에 `OPENAI_API_KEY=sk-...` 및 `AI_PROVIDER=openai`를 지정하면 실제 최신 LLM(`gpt-4o-mini` 등)을 통한 개인 맞춤 코칭이 활성화됩니다.
