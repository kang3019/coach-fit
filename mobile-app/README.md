# 📱 CoachFit Mobile App (Flutter)

CoachFit의 **모바일 클라이언트**. Java 백엔드(:8080)와 통신하여 운동 기록 CRUD, 주간 볼륨 시각화, AI 코칭 리포트, 세트 사이 휴식 타이머를 제공한다.

- **프레임워크**: Flutter (Dart SDK ^3.9.2)
- **담당자**: 팀원 A (Client Lead)
- **관련 ADR**: [ADR-0001 Flutter 선정](../planning/decisions/ADR-0001-flutter-mobile-framework.md)

---

## ✨ 주요 기능

| 상태 | 기능 | MoSCoW | 구현 파일 |
|:---:|---|:---:|---|
| ✅ | 운동 기록 등록/조회 CRUD | Must | `screens/home_screen.dart` + `services/workout_service.dart` |
| ✅ | 주간 볼륨 막대그래프 (요일별) | Must | `screens/widgets/weekly_volume_chart.dart` |
| ✅ | AI 코칭 리포트 (요약·조언·추천 루틴) | Must | `screens/coaching_screen.dart` + `services/coaching_service.dart` |
| ✅ | 세트 완료 후 자동 휴식 타이머 (60/90/120s) | Should | `screens/widgets/rest_timer.dart` |
| ✅ | Fleek 스타일 다크 테마 (`#00E5A0` 시드) | Must | `main.dart` |
| ⏳ | 사용자 목표/프로필 설정 | Should | 미구현 |
| ⏳ | 부위별 볼륨 비율 카드 | Should | 미구현 |

---

## 🖼️ 화면 구성

```
┌─────────────────────────────────────────┐
│  HomeScreen (홈)                        │
│  ├─ AppBar: [⏱️ 타이머] [⭐ AI 코칭]     │
│  ├─ 통계 3칸 (누적 세션/총 세트/총 볼륨) │
│  ├─ 주간 볼륨 차트 (월~일 막대)         │
│  ├─ 운동 기록 카드 리스트               │
│  └─ FAB [+ 세트 기록] → 등록 바텀시트   │
│      └─ 저장 완료 시 자동 타이머 오픈   │
├─────────────────────────────────────────┤
│  CoachingScreen (AI 코칭)               │
│  ├─ 📊 최근 분석 요약                   │
│  ├─ 💬 AI 코치의 조언                   │
│  └─ 🎯 오늘 추천 루틴 카드              │
└─────────────────────────────────────────┘
```

---

## 📁 폴더 구조

```
mobile-app/lib/
├── main.dart                              # 앱 진입점 + 다크 테마 + ko_KR 로케일
├── config/
│   └── api_constants.dart                 # Android 에뮬(10.0.2.2)/iOS/Web/실기기 baseUrl 자동 분기
├── models/                                # Java DTO ↔ Flutter 모델 매핑 (JSON 직렬화)
│   ├── workout.dart                       # WorkoutResponse 대응
│   └── coaching_result.dart               # CoachingResponse 대응 (snake_case 파싱)
├── services/                              # Java 백엔드 REST 호출 계층
│   ├── workout_service.dart               # /api/workouts CRUD + /weekly-stats
│   └── coaching_service.dart              # /api/coaching/generate
└── screens/                               # UI 화면 계층
    ├── home_screen.dart                   # 홈 (리스트 + 등록 + 통계)
    ├── coaching_screen.dart               # AI 코칭 리포트
    └── widgets/
        ├── weekly_volume_chart.dart       # fl_chart 요일별 막대그래프
        └── rest_timer.dart                # 원형 카운트다운 타이머 바텀시트
```

강의(week-11)에서 배운 **레이어드 아키텍처** 원칙에 따라 계층 분리:

- `config/` — 환경 설정
- `models/` — 도메인 데이터 구조 (Domain)
- `services/` — 데이터 계층 (Data / API)
- `screens/` — 화면 계층 (Presentation)

---

## 🔌 Java 백엔드 API 연동

모바일 앱은 **Java 서버(:8080)만 바라본다**. Python AI 서버(:8000)는 Java가 내부적으로 중계.

| 화면 | 호출 | 목적 |
|---|---|---|
| 홈 로드 | `GET /api/workouts?userId=user_01` | 운동 기록 리스트 |
| 홈 로드 | `GET /api/workouts/weekly-stats?userId=user_01` | 요일별 볼륨 통계 |
| 세트 등록 | `POST /api/workouts` | 새 운동 기록 저장 |
| AI 코칭 | `POST /api/coaching/generate` | Java → Python 중계 → AI 리포트 |

`config/api_constants.dart` 에서 실행 환경별 baseUrl을 자동 결정:
- Android 에뮬레이터: `http://10.0.2.2:8080`
- iOS 시뮬레이터 / macOS / Windows / Linux 데스크톱: `http://localhost:8080`
- Web (Chrome): `http://localhost:8080`
- 실기기: `_physicalDeviceHostOverride` 상수만 노트북 IP로 교체하면 됨

---

## 🚀 로컬 실행

### 사전 준비

- Flutter SDK ^3.9.2 (`flutter --version` 확인)
- **Java 백엔드(:8080) + Python AI 서버(:8000) 먼저 실행 필요** — 프로젝트 루트 `README.md` 참고

### 실행 명령

```bash
cd mobile-app

# 1. 의존성 설치
flutter pub get

# 2-a. Chrome 웹 모드로 즉시 확인 (가장 빠름)
flutter run -d chrome --web-port 3000

# 2-b. Android 에뮬레이터
flutter run

# 2-c. 실기기 (USB 디버깅 활성화된 스마트폰)
flutter run -d <device-id>
```

`flutter run -d chrome --web-port 3000` 실행 시 브라우저가 자동으로 열리며 http://localhost:3000 에 앱이 뜬다.

### 정적 분석

```bash
flutter analyze
```
현재 커밋 기준 `No issues found!` 통과.

---

## 📦 기술 스택

| 카테고리 | 라이브러리 | 버전 | 용도 |
|---|---|---|---|
| 프레임워크 | Flutter / Dart | ^3.9.2 | UI 및 상태 관리 |
| HTTP 클라이언트 | `http` | ^1.6.0 | Java REST 호출 |
| 국제화 | `intl` | ^0.20.3 | 날짜 포맷팅 (ko_KR) |
| 차트 | `fl_chart` | ^0.69.0 | 주간 볼륨 막대그래프 |
| 디자인 시스템 | Material 3 | 내장 | 다크 테마 (seed=`#00E5A0`) |

---

## ⚠️ 알려진 로컬 이슈 (개발 환경 세팅용)

Flutter 앱을 처음 실행하려면 **Java 백엔드와 Python AI 서버가 함께 켜져야** 하는데, 그 과정에서 백엔드 코드 세 곳에 걸림돌이 있어 A 로컬에서만 임시로 우회함. 다른 개발 환경에서도 동작하려면 B(백엔드 담당)가 원본 리포지토리에 반영 필요.

| # | 파일 | 이슈 | A 로컬 우회 |
|---|---|---|---|
| 1 | `python-ai-backend/app/models/schemas.py` | `date: Optional[date]` 필드명이 import 타입을 가려 Python 3.13 + Pydantic 2.13에서 uvicorn 부팅 크래시 | `from datetime import date as _date` alias 처리 |
| 2 | `java-backend/gradle.properties` | `org.gradle.java.home` 이 B의 로컬 Adoptium JDK 17 절대경로로 하드코딩되어 다른 환경에서 gradle 빌드 실패 | 해당 라인 주석 처리, 시스템 기본 Java 사용 |
| 3 | 프로젝트 루트 `.gitignore` | Python virtualenv용 `lib/` 규칙이 Flutter `mobile-app/lib/` 도 매치하여 앱 소스가 git 추적 제외 | `!mobile-app/lib/**` 예외 추가 (본 브랜치 커밋 `73c574f`) |

이슈 #1, #2는 커밋에 포함되지 않고 A 로컬에만 반영됨 (`git update-index --skip-worktree`). 이슈 #3만 이 브랜치에서 fix 커밋됨.

---

## 🛣️ 다음 스프린트 (미구현)

WBS 기준 남은 항목:

- **Should**: 사용자 프로필 (닉네임/신체정보/운동 목표), 부위별 볼륨 비율 카드
- **Could**: 라이트 테마 토글, 운동 부위별 필터, 월간 캘린더 스트릭
- **테스트**: 위젯 테스트 / 통합 테스트 (강의 week-13 기준)
- **문서**: `docs/setup.md`, `docs/architecture.md`, `docs/testing.md`, `docs/deploy.md` (팀 협의 필요)

---

## 📖 참고 문서 (프로젝트 루트)

- [`README.md`](../README.md) — 프로젝트 전체 아키텍처 및 실행 가이드
- [`planning/01-vision-and-scope.md`](../planning/01-vision-and-scope.md) — MoSCoW 요구사항
- [`planning/02-wbs-and-schedule.md`](../planning/02-wbs-and-schedule.md) — 전체 일정
- [`planning/03-team-and-git-convention.md`](../planning/03-team-and-git-convention.md) — Git 협업 규칙
- [`planning/decisions/`](../planning/decisions/) — ADR 3개 (Flutter/폴리글랏/하이브리드 AI)
