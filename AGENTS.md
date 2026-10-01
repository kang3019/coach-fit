# Coach Fit 프로젝트 AI 에이전트 행동 규칙 (AGENTS.md)

이 파일은 Antigravity AI 에이전트가 Coach Fit 프로젝트 내에서 작업을 수행할 때 반드시 준수해야 하는 규칙과 가이드라인을 정의합니다.

---

## 🚨 1. Git 브랜치 및 커밋 엄격 규칙 (최우선 원칙)

1. **`main` 브랜치 직접 커밋 절대 금지**:
   - `main` 브랜치에서 직접 `git add` 및 `git commit`을 실행하는 것은 엄격히 금지됩니다.

2. **항상 작업 브랜치 생성 후 커밋**:
   - 새로운 기능 개발, UI 수정, 버그 패치, 문서 작업 등 모든 작업은 반드시 목적에 맞는 별도 브랜치를 생성(`git checkout -b <branch-name>`)하여 진행합니다.
   - 브랜치 네이밍 규칙:
     - 기능 개발: `feature/<feature-name>` (예: `feature/muscle-map-hd`)
     - 버그 수정: `fix/<issue-name>` (예: `fix/routine-tile-overflow`)
     - 리팩토링 및 개선: `refactor/<target-name>`
     - 문서 및 설정: `docs/<doc-name>` 또는 `chore/<task-name>`

3. **검증 후 병합(Merge) 및 원격 푸시**:
   - 작업 브랜치에서 코드 수정 및 린트/빌드 검증(`flutter analyze` 등)을 통과한 후 `main`에 병합(Merge)합니다.
   - 병합 완료 후 `main` 브랜치를 원격 저장소(`origin/main`)에 푸시하고, 사용이 끝난 작업 브랜치는 깔끔하게 정리합니다.

---

## 🛠️ 2. 코드 품질 및 프레임워크 규칙

### Flutter 모바일 앱 (`mobile-app/`)
- **AMOLED 다크 테마 유지**:
  - 배경색: `#0E1116`
  - 카드/타일 배경: `#151922`
  - 포인트 악센트: 오렌지-레드 `#FF4820` / 민트 `#00E5A0`
- **린트 제로(0) 원칙**:
  - 코드 변경 후 반드시 `flutter analyze`를 실행하여 0 warning / 0 error 상태를 확인합니다.
- **3D 해부도 및 근육 맵 무결성**:
  - 인위적인 원형 번짐 블러 효과(`drawOval` 등) 사용 금지.
  - 실제 3D 인체 해부도 에셋(`body_base_neutral.png` 및 `overlay_*.png`)의 다중 레이어 구조를 준수.
  - 루틴의 타겟 근육에 맞춰 실시간으로 동적 점등되도록 유지.

### AI 백엔드 (`python-ai-backend/`)
- **단일 백엔드 원칙 (FastAPI)**:
  - 모든 API 및 DB 처리는 FastAPI (포트 8000) 단일 백엔드를 기준으로 동작.
  - PostgreSQL 연동 및 Pydantic v2 데이터 검증 준수.

---

## 💬 3. 커뮤니케이션 스타일
- **간결하고 명확한 보고**: 불필요하게 장황한 미사여구는 배제하고 핵심 결과와 상태를 중심으로 명료하게 요약합니다.
- **클릭 가능한 파일 링크 제공**: 언급되는 모든 파일 및 주요 함수는 마크다운 링크(`file:///...`) 형식으로 제공합니다.
