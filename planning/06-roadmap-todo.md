# 🗺️ 로드맵 & TODO

CoachFit 프로젝트의 개발 로드맵과 할 일 목록입니다.
완료 시 `[ ]` → `[x]` 로 변경해 주세요.

---

## ✅ v0.1 — 스켈레톤 (완료)

MVP 뼈대와 기본 CRUD, AI 코칭 파이프라인 구축.

- [x] 모노레포 구조 세팅 (Java + Python + Frontend)
- [x] 운동 기록 CRUD API (`/api/workouts`)
- [x] 주간 볼륨 통계 API (Chart.js 렌더링)
- [x] Python AI 서버 스마트 더미 코칭 엔진
- [x] Java ↔ Python 연동 및 폴백 처리
- [x] H2 인메모리 DB + 초기 더미 데이터 5건 자동 시드
- [x] Flutter 모바일 앱 스켈레톤 (Android/iOS/Web/Desktop)
- [x] Gradle Wrapper 추가 (Java 17)

---

## 🔨 v0.2 — 실사용 기능 (진행 중)

실제 사용자가 쓸 수 있는 수준으로 완성.

### 백엔드 (Java)
- [ ] 회원가입 / 로그인 API (Spring Security)
- [ ] JWT 실제 발급 및 검증 (현재는 뼈대만)
- [ ] `user_01` 하드코딩 제거, JWT 기반 사용자 식별
- [ ] `users` / `coaching_history` 테이블 추가
- [ ] 운동 부위(가슴/등/하체 등) 자동 태그 분류
- [ ] 페이징 처리 (`GET /api/workouts?page=0&size=20`)

### AI 서버 (Python)
- [ ] 실제 LLM 연동 (OpenAI `gpt-4o-mini`)
- [ ] Claude API 연동 (Anthropic)
- [ ] 프롬프트 엔지니어링 개선 (부위별 볼륨 분석 강화)
- [ ] 코칭 응답 캐싱 (동일 입력 재요청 방지)
- [ ] 사용자 목표(`user_goal`)별 맞춤 프롬프트 분기

### 프론트엔드 (Web)
- [ ] 로그인 / 회원가입 화면
- [ ] 종목별 필터링 및 정렬
- [ ] 월간/전체 통계 뷰 추가
- [ ] 운동 기록 수정 / 삭제 UI
- [ ] 다크 모드 토글 (현재는 다크 고정)

### Flutter 모바일
- [ ] Java 백엔드 연동 (Dio / http)
- [ ] 로그인 상태 유지 (secure_storage)
- [ ] 운동 기록 CRUD 화면
- [ ] 주간 차트 (fl_chart)
- [ ] AI 코칭 화면
- [ ] 푸시 알림 (운동 리마인더)

### 인프라
- [ ] MySQL 전환 및 마이그레이션 스크립트
- [ ] `.env.example` 갱신 및 문서화

---

## 🚀 v0.3 — 확장 기능 (계획)

부가 기능 및 배포 준비.

- [ ] 체중/체지방 트래킹 (`body_metrics` 테이블 + 그래프)
- [ ] 소셜 로그인 (Google / Kakao)
- [ ] PWA 지원 (모바일 홈화면 추가)
- [ ] 운동 영상/GIF 자세 참고 링크
- [ ] 통계 리포트 PDF 다운로드
- [ ] 다국어 지원 (한/영)
- [ ] Docker Compose 배포 스크립트
- [ ] AWS EC2 / RDS 배포
- [ ] CI/CD (GitHub Actions - build/test/deploy)
- [ ] E2E 테스트 (Playwright)
- [ ] API 문서 자동 생성 (Springdoc OpenAPI + FastAPI 스키마 통합)

---

## 💡 아이디어 풀 (미확정)

당장 계획은 없지만 언젠가 해보면 좋은 것들.

- 친구와 운동 볼륨 비교 / 랭킹 시스템
- 목표 달성 뱃지 및 스트릭(연속 운동일) 시스템
- Apple Health / Google Fit 연동
- 웨어러블 기기(스마트워치) 심박수 연동
- 커뮤니티 기능 (자유 게시판, Q&A)
- 트레이너 매칭 (오프라인 PT 연결)
- 식단 기록 및 영양 분석
- AI 자세 교정 (카메라 + 포즈 인식 - MediaPipe)
- 게이미피케이션 (경험치, 레벨, 아이템)

---

## 🏁 마일스톤

| 버전 | 목표 시기 | 주요 이정표 |
| :---: | :---: | :--- |
| v0.1 | 2026-09 (완료) | MVP 스켈레톤 |
| v0.2 | 2026-11 | 실사용 가능 수준 |
| v0.3 | 2027-02 | 배포 및 확장 기능 |
| v1.0 | 2027-05 | 정식 릴리즈 |

---

## 📋 담당자 분배 (예시)

향후 확정 시 아래 표 갱신 필요.

| 영역 | 담당자 | 진행 상태 |
| :--- | :---: | :---: |
| Java 백엔드 | 담당자 A | 🟢 진행중 |
| Python AI 서버 | 담당자 B | 🟢 진행중 |
| Web 프론트엔드 | ? | 🟡 미배정 |
| Flutter 모바일 | ? | 🟡 미배정 |
| DevOps / 배포 | ? | 🟡 미배정 |
