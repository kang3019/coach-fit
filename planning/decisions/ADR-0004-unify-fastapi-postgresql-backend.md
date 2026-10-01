# ADR-0004: Python FastAPI + PostgreSQL 단일 백엔드 아키텍처로의 통합

- **상태**: Accepted (ADR-0002를 대체함)
- **날짜**: 2026-10-01
- **결정자**: 2인 프로젝트 팀
- **관련 파일**: `python-ai-backend/`, `mobile-app/lib/config/api_constants.dart`, `frontend/app.js`

---

## 배경 및 교수님 피드백 분석

초기 아키텍처([ADR-0002](./ADR-0002-polyglot-backend-architecture.md))에서는 Java Spring Boot(메인 비즈니스)와 Python FastAPI(AI 코칭)를 각각 분리하여 2개의 서버를 구동하는 폴리글랏 마이크로서비스 구조를 채택했습니다.

그러나 지도 교수님 중간 피드백 과정에서 다음과 같은 핵심적인 공학적 지적이 제기되었습니다:

1. **2인 팀 규모 대비 오버엔지니어링(Over-engineering)**:
   - 2인 사이드 프로젝트 규모에서 백엔드 서버를 2개(Java + Python)나 상시 운용하는 것은 유지보수 비용과 복잡도만 가중시킴.
2. **개발 생산성 저하 및 중복 비용**:
   - 자바와 파이썬 간 네트워크 통신(`RestTemplate`), DTO 이중 정의(Java DTO ↔ Pydantic Schema), 포트 이원화(8080, 8000)로 인해 정작 핵심 기능 개발에 쏟을 리소스가 분산됨.
3. **교수님 권고 방향**:
   - 불필요하게 서버를 2개로 쪼개지 말고, **FastAPI + PostgreSQL(포스트그레스)** 하나로 통일하여 단일 백엔드 구조로 단순화하고 안정적인 데이터 영속성을 갖출 것.

---

## 고려한 대안

### 대안 A: 기존 폴리글랏 구조 유지 (서버리스 Lambda 추가 도입)
- **장점**: 분리된 책임 모델 유지.
- **단점**: 2인 팀 입장에서 여전히 Java 빌드/환경과 Python 가상환경을 동시에 관리해야 하므로 팀 생산성 향상에 한계가 있음.

### 대안 B: Java Spring Boot + MySQL 단일화 (Python 제거)
- **장점**: 엔터프라이즈 Java 생태계 올인 가능.
- **단점**: CoachFit의 핵심인 AI 맞춤형 운동 코칭 기능의 확장성(프롬프트 엔지니어링, LLM 생태계 라이브러리 연동, 데이터 분석)에서 Python보다 생산성이 현저히 떨어짐.

### 대안 C: Python FastAPI + PostgreSQL 단일화 (최종 채택)
- **장점**:
  - **단일 서버/단일 언어**: 포트 8000 하나로 운동 기록 CRUD, 통계 분석, AI 코칭을 모두 처리하여 아키텍처가 극도로 단순해짐.
  - **개발 속도 3배 향상**: 보일러플레이트 코드 제거 및 Swagger UI(`/docs`) 자동 생성으로 모바일 클라이언트(Flutter)와의 협업 효율 극대화.
  - **AI 도메인 적합성**: 코치핏의 핵심인 AI 프롬프트 튜닝 및 운동 데이터 분석 모듈 확장에 최적화.
  - **인프라 안정성**: JVM의 과도한 메모리 사용이 배제되어 AWS 프리티어 EC2(RAM 1GB)에서도 OOM 다운 없이 안정적으로 구동.
  - **교수님 피드백 100% 수용**: 권고 스택인 FastAPI + PostgreSQL을 온전히 반영.

---

## 결정

**대안 C (Python FastAPI + PostgreSQL 단일 백엔드 통합)**를 최종 아키텍처로 채택하며, 기존 ADR-0002의 폴리글랏 결정을 본 결정으로 대체(Supersede)한다.

---

## 구현 내역

### 1. 백엔드 통합 (`python-ai-backend/`)
- **데이터베이스 연동 (`app/database.py`)**:
  - SQLAlchemy 기반 DB 엔진 및 세션 관리 (`DATABASE_URL`).
  - PostgreSQL 프로덕션 연동을 지원하며, 로컬 무설정 개발을 위해 SQLite 자동 폴백 지원.
- **ORM 엔티티 (`app/models/workout_db.py`)**:
  - `WorkoutRecord` 테이블 정의 (Java 엔티티와 1:1 대응).
- **데이터 검증 및 DTO (`app/models/schemas.py`)**:
  - Pydantic V2 기반 운동 등록(`WorkoutCreate`), 조회(`WorkoutResponse`), 주간 통계(`WeeklyStatsResponse`) 정의.
- **비즈니스 로직 및 CRUD (`app/services/workout_service.py`)**:
  - Java 백엔드에 있던 운동 기록 저장/조회 및 요일별 볼륨 집계 로직을 Python으로 완벽 이관.
- **통합 API 라우트 (`app/main.py`)**:
  - `POST /api/workouts`: 운동 기록 생성 (201 Created)
  - `GET /api/workouts`: 전체 운동 기록 목록 조회
  - `GET /api/workouts/weekly-stats`: 주간 요일별 볼륨 집계 반환
  - `POST /api/coaching/generate`: DB 연동 기반 AI 맞춤 루틴 생성
  - `GET /docs`: 모바일 개발용 자동 생성 Swagger 문서 제공

### 2. 모바일 클라이언트 연동 (`mobile-app/`)
- `mobile-app/lib/config/api_constants.dart`의 접속 포트를 기존 8080에서 **8000 단일 백엔드**로 변경.
- Flutter 앱의 운동 기록 CRUD, 주간 볼륨 차트, AI 코칭 요청이 모두 FastAPI 단일 서버로 직접 연결됨.

### 3. 웹 데모 클라이언트 연동 (`frontend/`)
- `frontend/app.js`의 API 엔드포인트를 8000 단일 포트로 통합.

---

## 결과 및 기대 효과

1. **아키텍처 단순화**: 관리해야 할 서버 인스턴스가 2개에서 1개로 줄어들어 배포 및 로컬 실행의 피로도 대폭 감소.
2. **교수님 피드백 완벽 대응**: "왜 굳이 2개 쓰냐"는 질문에 명확하고 실용적인 해답 제시.
3. **남은 스프린트 개발 가속화**: 11/20 최종 발표 전까지 백엔드 통신 이슈 없이 Flutter UI 및 AI 코칭 정밀도 향상에 전념 가능.
