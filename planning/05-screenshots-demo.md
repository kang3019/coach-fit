# 🖼️ 스크린샷 & 데모 가이드

CoachFit의 대시보드 화면과 데모 영상 관리 가이드입니다.
이미지/GIF는 `docs/screenshots/` 폴더에 저장하고 아래 경로로 참조합니다.

---

## 📸 필요한 스크린샷 목록

### 1. 웹 대시보드 (프론트엔드)

| 화면 | 파일명 | 상태 | 미리보기 |
| :--- | :--- | :---: | :--- |
| 메인 대시보드 (전체) | `dashboard-main.png` | ⏳ 준비중 | `![dashboard](../docs/screenshots/dashboard-main.png)` |
| 주간 볼륨 차트 (Chart.js) | `weekly-chart.png` | ⏳ 준비중 | `![weekly-chart](../docs/screenshots/weekly-chart.png)` |
| AI 코칭 결과 카드 | `ai-coaching-card.png` | ⏳ 준비중 | `![ai-coach](../docs/screenshots/ai-coaching-card.png)` |
| 운동 기록 등록 폼 | `workout-form.png` | ⏳ 준비중 | `![form](../docs/screenshots/workout-form.png)` |
| 운동 기록 테이블 | `workout-table.png` | ⏳ 준비중 | `![table](../docs/screenshots/workout-table.png)` |
| 서버 상태 배지 (green/red) | `server-status-badge.png` | ⏳ 준비중 | `![status](../docs/screenshots/server-status-badge.png)` |

### 2. 모바일 앱 (Flutter)

| 화면 | 파일명 | 상태 |
| :--- | :--- | :---: |
| 스플래시 스크린 | `mobile-splash.png` | ⏳ 준비중 |
| 홈 화면 | `mobile-home.png` | ⏳ 준비중 |
| 운동 기록 등록 | `mobile-add-workout.png` | ⏳ 준비중 |
| AI 코칭 화면 | `mobile-coaching.png` | ⏳ 준비중 |

### 3. 백엔드 (개발자용)

| 화면 | 파일명 | 상태 |
| :--- | :--- | :---: |
| Swagger UI (Python `/docs`) | `swagger-python.png` | ⏳ 준비중 |
| H2 콘솔 (Java) | `h2-console.png` | ⏳ 준비중 |

---

## 🎬 데모 GIF / 동영상

| 항목 | 파일명 | 길이 | 상태 |
| :--- | :--- | :---: | :---: |
| 전체 사용 흐름 하이라이트 | `docs/demo-full.gif` | ~30초 | ⏳ |
| 운동 기록 등록 → 차트 갱신 | `docs/demo-workout-add.gif` | ~10초 | ⏳ |
| AI 코칭 요청 → 결과 표시 | `docs/demo-ai-coach.gif` | ~15초 | ⏳ |

---

## 📐 촬영 가이드

### 이미지 규격
- **해상도**: 1920×1080 이상 권장, 최소 1280×720
- **포맷**: PNG (스크린샷) / GIF (짧은 애니메이션) / MP4 (긴 데모)
- **파일 크기**: PNG 500KB 이하, GIF 5MB 이하 (README 로딩 속도 위해)
- **압축 도구**: TinyPNG (https://tinypng.com), Squoosh (https://squoosh.app)

### 촬영 팁
1. **더미 데이터로 이쁘게** — 운동 기록 5~10개 정도 미리 입력 후 촬영
2. **다크 모드 통일** — 프론트가 다크 테마라서 밝은 화면 스샷은 지양
3. **브라우저 창 정리** — 북마크 바 숨기고, 확장 프로그램 아이콘 최소화
4. **개인정보 마스킹** — 실제 이메일/이름 나오지 않게 주의
5. **크롭 통일** — 화면 전체가 아닌 관심 영역만 잘라내기

### 추천 도구
- **Windows**: Snipping Tool (Win+Shift+S), ShareX (GIF 녹화)
- **Mac**: Cmd+Shift+4, Kap (GIF 녹화)
- **크로스플랫폼**: OBS Studio (영상), LICEcap (GIF)

---

## 📂 폴더 구조

```
coach-fit/
└── docs/
    ├── screenshots/
    │   ├── dashboard-main.png
    │   ├── weekly-chart.png
    │   ├── ai-coaching-card.png
    │   └── ... (기타 스크린샷)
    └── demos/
        ├── demo-full.gif
        └── demo-workout-add.gif
```

---

## 🔗 README 삽입 예시

루트 `README.md` 에 아래처럼 삽입:

```markdown
## 🖼️ 미리보기

![CoachFit 대시보드](docs/screenshots/dashboard-main.png)

### 주요 기능
| 운동 기록 등록 | AI 코칭 분석 |
| :---: | :---: |
| ![](docs/screenshots/workout-form.png) | ![](docs/screenshots/ai-coaching-card.png) |

### 데모
![데모 영상](docs/demos/demo-full.gif)
```

---

## ✅ 체크리스트 (스크린샷 추가 시)

- [ ] 파일명이 위 목록의 규칙과 일치하는가
- [ ] 이미지 압축했는가 (500KB 이하)
- [ ] 개인정보 노출 없는가
- [ ] 이 문서의 "상태" 컬럼을 ✅ 로 업데이트했는가
- [ ] 루트 `README.md` 에 삽입했는가
