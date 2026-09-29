# 📨 API 요청/응답 JSON 예시

CoachFit의 주요 API 엔드포인트별 실제 요청·응답 JSON 샘플입니다.
Postman / Thunder Client / cURL 로 테스트할 때 그대로 복사해서 쓰세요.

---

## 1. `POST /api/workouts` — 운동 기록 등록 (Java, 8080)

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

**cURL 예시**
```bash
curl -X POST http://localhost:8080/api/workouts \
  -H "Content-Type: application/json" \
  -d '{"userId":"user_01","exerciseName":"벤치프레스","sets":4,"reps":10,"weight":60.0,"workoutDate":"2026-09-29","memo":"가슴 위주 루틴"}'
```

---

## 2. `GET /api/workouts?userId=user_01` — 운동 기록 조회 (Java)

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
  },
  {
    "id": 5,
    "userId": "user_01",
    "exerciseName": "스쿼트",
    "sets": 5,
    "reps": 5,
    "weight": 100.0,
    "workoutDate": "2026-09-27",
    "memo": null,
    "createdAt": "2026-09-27T19:12:03.456"
  }
]
```

---

## 3. `GET /api/workouts/weekly-stats` — 주간 볼륨 통계 (Java)

Chart.js 렌더링용 요일별 누적 볼륨 데이터입니다.
`volume = sets × reps × weight`

**Response `200 OK`**
```json
{
  "labels": ["월", "화", "수", "목", "금", "토", "일"],
  "volumes": [2400.0, 0.0, 1800.0, 0.0, 2100.0, 0.0, 0.0]
}
```

---

## 4. `POST /api/coaching/generate` — AI 코칭 (Java 경유, 표준 방식)

Body 없이 호출하면 DB의 최근 기록을 자동으로 Python 서버에 중계합니다.

**Request**: 빈 body

**Response `200 OK`** → 아래 5번의 응답과 동일한 스키마

---

## 5. `POST /api/coaching` — AI 코칭 (Python 직접 호출, 8000)

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
    },
    {
      "exercise_name": "스쿼트",
      "sets": 5,
      "reps": 5,
      "weight": 100.0,
      "date": "2026-09-27"
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
    },
    {
      "exercise_name": "루마니안 데드리프트",
      "sets": 3,
      "reps": 12,
      "focus": "햄스트링 · 둔근",
      "tip": "허리는 항상 중립 유지"
    }
  ],
  "generated_at": "2026-09-29T20:40:00.123456"
}
```

---

## 6. `GET /health` — Python 서버 헬스체크

**Response `200 OK`**
```json
{
  "status": "ok",
  "service": "coachfit-ai",
  "provider": "dummy"
}
```

---

## 📌 필드 네이밍 주의

- Java DTO는 **camelCase** (예: `exerciseName`, `workoutDate`)
- Python(Pydantic)은 **snake_case** (예: `exercise_name`, `user_goal`)
- Java의 `CoachingRequestDto` / `CoachingResponseDto` 는 `@JsonProperty` 로 snake_case 매핑 처리됨
