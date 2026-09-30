# 📚 CoachFit 프로젝트 기획 및 협업 가이드 (Planning Hub)

본 문서는 CoachFit(코치핏) 프로젝트의 공식 기획 및 2인 개발 협업 문서 저장소입니다.

- **프로젝트 목표**: 혼자서도 지속 가능한 AI 맞춤형 피트니스 코칭 앱 (Google Play Store 'Fleek' 벤치마킹)
- **팀 구성**: 2인 개발 팀 (모바일 클라이언트 ↔ 서버/AI 백엔드 분업)
- **최종 목표/데모 발표일**: **2026년 11월 20일 (금)**
- **정기 마일스톤**: 2회 스프린트 리뷰 (10월 하순 1차 프로토타입 / 11월 초순 2차 AI 통합 데모)

---

## 📁 기획 문서 전체 체계

| 번호 | 문서 파일 | 주요 내용 및 목적 |
| :---: | :--- | :--- |
| **01** | [01-vision-and-scope.md](./01-vision-and-scope.md) | **비전 & 범위 정의서**: 한 줄 주제, 3대 사용자 시나리오, MoSCoW 요구사항 분류, 기획 검증 |
| **02** | [02-wbs-and-schedule.md](./02-wbs-and-schedule.md) | **WBS & 마일스톤**: 11/20 데모 발표 역산 일정, 주차별 계획, 1~3d 단위 작업 분해, 20% 버퍼 |
| **03** | [03-team-and-git-convention.md](./03-team-and-git-convention.md) | **팀 규칙 & Git 협업 컨벤션**: `main` 직접 커밋 금지, 브랜치 전략, 단계별 명령어, 커밋/PR 룰 |
| **04** | [04-risk-management.md](./04-risk-management.md) | **위험 관리 & Q&A 대비**: 5대 리스크(기술, 일정, 협업, AI, 데모) 식별 및 데모 Q&A 모범 답변 |

---

## 🏛️ 아키텍처 의사결정 레코드 (ADR - Architecture Decision Records)

기술 스택 선정 및 아키텍처 설계 배경을 기록하여 향후 포트폴리오 정리 및 기술 면접 시 설득력 있는 근거 자료로 활용합니다.

- [ADR-0001: 모바일 클라이언트 프레임워크로 Flutter(Dart) 선정](./decisions/ADR-0001-flutter-mobile-framework.md)
- [ADR-0002: Java Spring Boot + Python FastAPI 폴리글랏 백엔드 아키텍처 채택](./decisions/ADR-0002-polyglot-backend-architecture.md)
- [ADR-0003: LLM과 로컬 룰베이스를 결합한 하이브리드 AI 코칭 엔진 설계](./decisions/ADR-0003-hybrid-ai-coaching-engine.md)

---

## 💡 문서 활용 및 업데이트 가이드

1. **작업 진행 시**: [02-wbs-and-schedule.md](./02-wbs-and-schedule.md)의 체크박스(`- [ ]` ➔ `- [x]`)를 갱신하여 진척도를 관리합니다.
2. **Git 작업 시**: 반드시 [03-team-and-git-convention.md](./03-team-and-git-convention.md)의 `feature/...` 브랜치 생성 및 PR 머지 절차를 준수합니다.
3. **새로운 기술 결정 시**: `planning/decisions/` 디렉터리에 `ADR-0004-{제목}.md` 형태로 새 결정을 추가합니다.
