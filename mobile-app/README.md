# 📱 CoachFit Mobile App (Flutter)

CoachFit의 **크로스플랫폼 클라이언트 애플리케이션**.  
FastAPI 통합 백엔드(포트 8000)와 통신하여 운동 기록 CRUD, 3D 인터랙티브 인체 근육 맵, 실시간 주간 볼륨 시각화, AI 코칭 리포트, 그리고 운동 목표 및 프로필 설정을 제공합니다.

- **프레임워크**: Flutter 3.24+ / Dart 3.5+
- **디자인 테마**: AMOLED 다크 테마 (배경 `#0E1116`, 카드 `#151922`, 포인트 악센트 민트 `#00E5A0` / 오렌지-레드 `#FF4820`)
- **백엔드 연동**: FastAPI 단일 백엔드 (포트 8000, [ADR-0004](../planning/decisions/ADR-0004-unify-fastapi-postgresql-backend.md))

---

## ✨ 주요 기능 및 구현 현황

| 상태 | 기능 | MoSCoW | 주요 구현 파일 |
|:---:|---|:---:|---|
| ✅ | 3D 인터랙티브 인체 해부도 & 근육 맵 점등 | Must | `widgets/anatomy_painter.dart`, `tabs/home_tab.dart` |
| ✅ | 운동 기록 등록/조회/삭제 CRUD | Must | `screens/tabs/history_tab.dart`, `services/workout_service.dart` |
| ✅ | 최근 세트 원터치 복사 가로 칩 UX | Should | `screens/tabs/history_tab.dart` (`_CopyChip`) |
| ✅ | 주간 누적 볼륨 차트 (`fl_chart`) | Must | `screens/tabs/stats_tab.dart`, `widgets/weekly_volume_chart.dart` |
| ✅ | 부위별 볼륨 배분 실시간 자동 집계 | Should | `screens/tabs/stats_tab.dart` (`_buildBodyBars`) |
| ✅ | AI 맞춤 코칭 리포트 & 실시간 피드백 | Must | `services/coaching_service.dart`, `screens/tabs/home_tab.dart` |
| ✅ | 운동 목표 설정 (근비대/감량/근력) 로컬 영속화 | Should | `services/goal_service.dart`, `screens/tabs/menu_tab.dart` |
| ✅ | 사용자 프로필 편집 & 신체 스펙 로컬 저장 | Should | `models/user_profile.dart`, `screens/profile_edit_screen.dart` |
| ✅ | 카운트다운 휴식 타이머 (60s/90s/120s) | Should | `screens/widgets/rest_timer.dart` |

---

## 🖼️ 화면 구조 (하단 5개 탭 네비게이션)

```
┌───────────────────────────────────────────────────────────┐
│ CoachFit Mobile Client                                    │
├─────────┬─────────┬─────────┬─────────────┬───────────────┤
│ 🏠 홈    │ 📝 기록  │ 📊 통계  │ 👥 커뮤니티  │ ⚙️ 메뉴        │
│         │         │         │             │               │
│ - 3D    │ - 최근  │ - 요일별│ - 소통 및    │ - 프로필 카드 │
│   근육맵│   세트  │   볼륨  │   운동 인증 │   (편집 화면) │
│ - 오늘의│   복사칩│   차트  │             │ - 운동 목표   │
│   AI루틴│ - 운동  │ - 부위별│             │   선택 라디오 │
│   추천  │   리스트│   비율  │             │ - 앱 설정     │
└─────────┴─────────┴─────────┴─────────────┴───────────────┘
```

---

## 📁 폴더 구조

```text
mobile-app/lib/
├── main.dart                          # 앱 진입점 + AMOLED 다크 테마 + ko_KR 로케일
├── config/
│   └── api_constants.dart             # 플랫폼별(10.0.2.2/localhost/실기기) 포트 8000 자동 분기
├── models/                            # 도메인 데이터 모델 (JSON 직렬화)
│   ├── workout.dart                   # 운동 기록 모델
│   ├── user_profile.dart              # 프로필 & 신체 정보 모델
│   └── coaching_result.dart           # AI 코칭 결과 모델
├── services/                          # API 및 로컬 영속화 계층
│   ├── workout_service.dart           # FastAPI /api/workouts CRUD
│   ├── coaching_service.dart          # FastAPI /api/coaching/generate
│   ├── profile_service.dart           # SharedPreferences 프로필 관리
│   └── goal_service.dart              # SharedPreferences 운동 목표 관리
├── screens/
│   ├── tabs/                          # 5대 탭 화면
│   │   ├── home_tab.dart              # 홈 탭
│   │   ├── history_tab.dart           # 기록 탭
│   │   ├── stats_tab.dart             # 통계 탭
│   │   ├── community_tab.dart         # 커뮤니티 탭
│   │   └── menu_tab.dart              # 메뉴 탭
│   ├── profile_edit_screen.dart       # 프로필 수정 화면
│   └── widgets/                       # 재사용 공통 위젯
│       ├── rest_timer.dart            # 휴식 타이머
│       └── weekly_volume_chart.dart   # 볼륨 차트
└── assets/                            # 3D 해부도 및 인체 근육 에셋
```

---

## 🔌 백엔드 API 연동 (FastAPI: 포트 8000)

`config/api_constants.dart`에서 실행 디바이스에 따라 접속 URL을 자동으로 분기합니다:
- **Windows / macOS / 데스크톱 / Chrome**: `http://localhost:8000`
- **Android 에뮬레이터**: `http://10.0.2.2:8000`
- **실기기(스마트폰)**: `_physicalDeviceHostOverride`에 PC의 로컬 IP 설정

| 기능 | API 엔드포인트 | 설명 |
| :--- | :--- | :--- |
| **운동 기록 조회** | `GET /api/workouts?user_id=user_01` | 전체 운동 기록 최신순 조회 |
| **운동 기록 등록** | `POST /api/workouts` | 신규 운동 세트 저장 |
| **운동 기록 삭제** | `DELETE /api/workouts/{id}` | 특정 운동 기록 삭제 |
| **주간 통계** | `GET /api/workouts/weekly-stats` | 요일별 누적 볼륨 통계 |
| **AI 코칭 생성** | `POST /api/coaching/generate` | 사용자 목표 기반 AI 분석 및 맞춤 루틴 |
| **종목 마스터** | `GET /api/exercises` | 운동 종목 및 타겟 근육 부위 리스트 |

---

## 🚀 로컬 실행 방법

1. **사전 준비**: FastAPI 백엔드(포트 8000)가 먼저 실행되어 있어야 합니다. ([setup.md](../setup.md) 참고)
2. **실행 명령어**:
   ```powershell
   cd mobile-app
   flutter pub get

   # Windows 데스크톱 앱 (추천)
   flutter run -d windows

   # Chrome 웹 브라우저
   flutter run -d chrome

   # Android 에뮬레이터
   flutter run
   ```
3. **코드 린트 검증**:
   ```powershell
   flutter analyze
   ```
   *AGENTS.md 규칙에 따라 `No issues found!` 0 warning / 0 error 상태를 엄격히 유지합니다.*
