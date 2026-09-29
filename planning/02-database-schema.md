# 🗄️ DB 스키마 & ERD

CoachFit 프로젝트의 데이터베이스 구조 및 향후 확장 계획입니다.
현재는 H2 인메모리 DB 기반이며, MySQL 전환 시에도 동일한 스키마가 적용됩니다.

---

## 📊 현재 테이블

### `workout_records` — 운동 기록

`java-backend/src/main/java/com/coachfit/backend/entity/WorkoutRecord.java`

| 컬럼 | 타입 | 제약 | 설명 |
| :--- | :--- | :--- | :--- |
| `id` | `BIGINT` | PK, AUTO_INCREMENT | 기록 고유 ID |
| `user_id` | `VARCHAR` | NOT NULL, default `user_01` | 사용자 식별자 (JWT 도입 전 임시값) |
| `exercise_name` | `VARCHAR` | NOT NULL | 운동 종목명 (예: 벤치프레스, 스쿼트) |
| `sets` | `INT` | NOT NULL | 세트 수 |
| `reps` | `INT` | NOT NULL | 세트당 반복 횟수 |
| `weight` | `DOUBLE` | NOT NULL | 중량 (kg) |
| `workout_date` | `DATE` | NOT NULL | 운동 수행 일자 |
| `memo` | `VARCHAR` | NULL | 자유 메모 |
| `created_at` | `DATETIME` | NOT NULL, 자동 생성 | 레코드 생성 시각 |

**DDL 예시 (MySQL 기준)**
```sql
CREATE TABLE workout_records (
    id            BIGINT       AUTO_INCREMENT PRIMARY KEY,
    user_id       VARCHAR(50)  NOT NULL DEFAULT 'user_01',
    exercise_name VARCHAR(100) NOT NULL,
    sets          INT          NOT NULL,
    reps          INT          NOT NULL,
    weight        DOUBLE       NOT NULL,
    workout_date  DATE         NOT NULL,
    memo          VARCHAR(500),
    created_at    DATETIME     NOT NULL,
    INDEX idx_user_date (user_id, workout_date DESC)
);
```

---

## 🔮 향후 확장 예정 테이블

### `users` — 회원 정보 (JWT 도입 시)

| 컬럼 | 타입 | 제약 | 설명 |
| :--- | :--- | :--- | :--- |
| `id` | `VARCHAR(50)` | PK | 사용자 ID (`user_01` 자리 대체) |
| `email` | `VARCHAR(100)` | NOT NULL, UNIQUE | 로그인 이메일 |
| `password_hash` | `VARCHAR(255)` | NOT NULL | BCrypt 암호화 비밀번호 |
| `nickname` | `VARCHAR(50)` | NOT NULL | 닉네임 |
| `goal` | `VARCHAR(200)` | NULL | 운동 목표 (근비대, 다이어트 등) |
| `created_at` | `DATETIME` | NOT NULL | 가입 일시 |

### `coaching_history` — AI 코칭 이력

| 컬럼 | 타입 | 제약 | 설명 |
| :--- | :--- | :--- | :--- |
| `id` | `BIGINT` | PK, AUTO_INCREMENT | 이력 ID |
| `user_id` | `VARCHAR(50)` | FK → users.id | 사용자 |
| `summary` | `TEXT` | NOT NULL | 분석 요약 |
| `advice` | `TEXT` | NOT NULL | 코칭 조언 |
| `routine_json` | `JSON` | NOT NULL | 추천 루틴 (JSON 원본) |
| `provider` | `VARCHAR(20)` | NOT NULL | `dummy` / `openai` / `claude` |
| `created_at` | `DATETIME` | NOT NULL | 생성 시각 |

### `body_metrics` — 체중/체지방 기록

| 컬럼 | 타입 | 제약 | 설명 |
| :--- | :--- | :--- | :--- |
| `id` | `BIGINT` | PK, AUTO_INCREMENT | 기록 ID |
| `user_id` | `VARCHAR(50)` | FK → users.id | 사용자 |
| `weight_kg` | `DOUBLE` | NOT NULL | 체중 (kg) |
| `body_fat_pct` | `DOUBLE` | NULL | 체지방률 (%) |
| `recorded_at` | `DATE` | NOT NULL | 측정 일자 |

---

## 🔗 관계도 (ERD - 텍스트 버전)

```
┌───────────────┐
│    users      │
│  ─────────    │
│  id (PK)      │
│  email        │
│  password     │
│  nickname     │
│  goal         │
└───────┬───────┘
        │ 1
        │
        │ N
        ├──────────────────┐──────────────────┐
        ▼                  ▼                  ▼
┌──────────────────┐ ┌────────────────┐ ┌────────────────┐
│ workout_records  │ │coaching_history│ │  body_metrics  │
│  ─────────────   │ │  ────────────  │ │  ────────────  │
│ id (PK)          │ │ id (PK)        │ │ id (PK)        │
│ user_id (FK)     │ │ user_id (FK)   │ │ user_id (FK)   │
│ exercise_name    │ │ summary        │ │ weight_kg      │
│ sets/reps/weight │ │ advice         │ │ body_fat_pct   │
│ workout_date     │ │ routine_json   │ │ recorded_at    │
│ memo             │ │ provider       │ └────────────────┘
│ created_at       │ │ created_at     │
└──────────────────┘ └────────────────┘
```

---

## 🛠️ 마이그레이션 전략

1. H2 → MySQL 전환 시 `application.yml`의 datasource 설정 교체
2. JPA `ddl-auto: update` 로 자동 스키마 생성 (개발 단계)
3. 운영 배포 전에는 `Flyway` 또는 `Liquibase` 도입 검토
4. 초기 유저 시딩 데이터는 `data.sql` 로 관리
