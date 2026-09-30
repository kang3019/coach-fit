# 🤝 03. 팀 협업 및 Git / GitHub 운영 규칙 (Team & Git Convention)

> **프로젝트명**: CoachFit (코치핏)  
> **프로젝트 형태**: 2인 개발 사이드/포트폴리오 프로젝트  
> **핵심 목적**: `main` 브랜치 오염을 원천 차단하고, 2인 간 코드 충돌(Conflict) 없는 안전하고 일관된 Git 협업 환경을 구축합니다.

---

## 👥 1. 2인 팀 역할 분담 추천 모델

CoachFit의 모노레포 구조(Flutter + Java + Python)에서는 **클라이언트(Flutter) ↔ 서버/AI(Backend) 계층형 분업**을 강력히 권장합니다.

```
┌──────────────────────────────────────┐     ┌──────────────────────────────────────┐
│        팀원 A (Client Lead)          │     │        팀원 B (Backend Lead)         │
├──────────────────────────────────────┤     ├──────────────────────────────────────┤
│ • Flutter 모바일 앱 UI/UX            │     │ • Java Spring Boot 운동 CRUD & 통계  │
│ • 세트 기록 테이블 & 휴식 타이머     │ ──▶ │ • Python FastAPI AI 코칭 로직/프롬프트│
│ • 주간 볼륨 차트 (fl_chart)         │ ◀── │ • H2/MySQL 데이터베이스 영속화       │
│ • 백엔드 REST API 연동               │     │ • 룰베이스 폴백 엔진 & API 문서화    │
│ • 11/20 모바일 시연 및 발표 자료(PPT)│     │ • 데모 시연용 시드 데이터 준비       │
└──────────────────────────────────────┘     └──────────────────────────────────────┘
```

> **협업 이점**: 두 팀원이 작업하는 폴더(`mobile-app/` vs `java-backend/`, `python-ai-backend/`)가 완전히 분리되어 **코드 병합 충돌(Conflict)이 발생하지 않습니다.**

---

## 🚫 2. Git 협업 3대 절대 원칙 (Golden Rules)

1. **`main` 브랜치에 직접 `add`, `commit`, `push` 절대 금지!**
   - `main` 브랜치는 언제든 시연 및 배포가 가능한 **가장 안전한 상태**로만 유지해야 합니다.
   - 로컬에서 `main` 브랜치에 직접 커밋하거나 푸시하는 행위는 엄격히 제한합니다.
2. **모든 작업은 반드시 새로운 기능 브랜치(`feature/...`)에서 진행!**
   - 사소한 오타 수정이나 간단한 UI 작업이라도 반드시 별도 브랜치를 생성하여 작업합니다.
3. **병합(Merge)은 오직 GitHub Pull Request (PR)를 통해서만 진행!**
   - 작업 브랜치를 원격에 푸시한 뒤 PR을 생성하고, 상대 팀원의 검토(Approve)를 거쳐 머지합니다.

---

## 🌿 3. 브랜치 전략 및 명명 규칙

```
main (최종 안정 브랜치 / 언제든 데모 가능한 상태)
  ▲
develop (팀 개발 통합 브랜치)
  ├── feature/app-workout-logging  (팀원 A 작업 브랜치)
  └── feature/ai-coaching-prompt   (팀원 B 작업 브랜치)
```

### 1) 브랜치 종류 및 역할
- **`main`**: 최종 안정화 브랜치. 데모 발표 및 포트폴리오 릴리즈 시에만 머지.
- **`develop`**: 평소 개발 작업들이 1차로 통합되는 기본 브랜치.
- **`feature/{파트}-{기능명}`**: 새로운 기능 개발 브랜치.
  - 모바일 예시: `feature/app-workout-form`, `feature/app-timer`, `feature/app-volume-chart`
  - 백엔드 예시: `feature/java-workout-api`, `feature/ai-rule-engine`, `feature/ai-prompt`
- **`fix/{파트}-{버그명}`**: 버그 수정 브랜치.
  - 예시: `fix/app-overflow-error`, `fix/java-cors-issue`

---

## 🔄 4. 표준 Git 작업 흐름 (Step-by-Step 터미널 가이드)

모든 팀원은 작업 시 아래의 8단계를 반드시 준수합니다.

```
[1. 최신 pull] ➔ [2. 브랜치 생성] ➔ [3. 작업 & 커밋] ➔ [4. 원격 push] ➔ [5. PR 생성 및 머지]
```

### 1단계: 최신 `develop` 코드 동기화
새 작업을 시작하기 전, 항상 기준 브랜치를 최신 상태로 업데이트합니다.
```bash
git checkout develop
git pull origin develop
```

### 2단계: 작업 브랜치 생성 및 이동
규칙에 맞는 이름으로 새 브랜치를 만들어 이동합니다.
```bash
# 형식: git checkout -b feature/{파트}-{기능명}
git checkout -b feature/app-timer
```

### 3단계: 코드 작업 및 변경사항 확인
코드를 수정한 후 어떤 파일이 변경되었는지 확인합니다.
```bash
git status
git diff
```

### 4단계: 스테이징 및 커밋 (컨벤션 준수)
변경한 파일을 추가하고 정해진 커밋 규칙에 맞춰 커밋합니다.
```bash
git add .
git commit -m "feat: 세트 완료 시 카운트다운 휴식 타이머 위젯 추가"
```

### 5단계: 원격 저장소(GitHub)로 브랜치 푸시
작업한 브랜치를 본인의 원격 저장소로 올립니다.
```bash
git push origin feature/app-timer
```

### 6단계: GitHub에서 Pull Request (PR) 생성
1. GitHub 리포지토리 페이지에 접속합니다.
2. 상단에 뜨는 **`Compare & pull request`** 노란색 버튼을 클릭합니다.
3. **Base(받는 브랜치)**: `develop` | **Compare(작업 브랜치)**: `feature/app-timer` 로 지정합니다.
4. 작업 내용 요약과 스크린샷(UI 변경 시)을 첨부하여 PR을 생성합니다.

### 7단계: 상대 팀원 코드 리뷰 및 머지
1. 상대 팀원에게 카카오톡/디스코드로 PR 검토를 요청합니다.
2. 상대 팀원은 코드를 확인하고 이상이 없으면 **`Approve`**를 누릅니다.
3. 머지 방식은 커밋 히스토리가 깔끔해지는 **`Squash and merge`**를 권장합니다.

### 8단계: 로컬 환경 정리
머지가 끝난 후 로컬 브랜치를 정리하고 다시 `develop` 최신 상태로 돌아옵니다.
```bash
git checkout develop
git pull origin develop

# 로컬에서 다 쓴 작업 브랜치 삭제
git branch -d feature/app-timer
```

---

## ✍️ 5. Git 커밋 메시지 컨벤션 (Commit Convention)

커밋 히스토리만 보고도 어떤 변경이 일어났는지 즉시 파악할 수 있도록 **Conventional Commits** 표준을 따릅니다.

### 1) 기본 형식
```text
<타입>: <한 줄 요약 (한국어 명사형/명령조, 50자 이내, 마침표 생략)>

[선택 사항: 상세 설명 본문]
- 무엇을 왜 변경했는지 상세히 기술
```

### 2) 커밋 태그(Type) 목록
| 타입 | 의미 | 사용 예시 |
| :---: | :--- | :--- |
| `feat` | 새로운 기능 추가 | `feat: 운동 기록 삭제 API 엔드포인트 구현` |
| `fix` | 버그 수정 | `fix: 주간 볼륨 차트 일요일 데이터 누락 오류 수정` |
| `docs` | 문서 추가 및 수정 | `docs: Git 협업 규칙 및 WBS 일정표 갱신` |
| `style` | 코드 포맷팅, 세미콜론 수정 (로직 변경 없음) | `style: Flutter 코드 들여쓰기 및 dartfmt 적용` |
| `refactor`| 코드 리팩토링 (기능 변화 없는 구조 개선) | `refactor: WorkoutService 중복 쿼리 제거 및 모듈화` |
| `test` | 테스트 코드 추가 및 수정 | `test: Python AI 스마트 룰베이스 응답 유닛 테스트 추가` |
| `chore` | 빌드 스크립트 수정, 패키지 설치 등 잡무 | `chore: pubspec.yaml에 fl_chart 라이브러리 추가` |

### 3) 좋은 커밋 vs 나쁜 커밋 예시
- ❌ **나쁜 예**:
  - `git commit -m "수정함"` (무엇을 수정했는지 알 수 없음)
  - `git commit -m "asdf"` (무의미한 텍스트)
  - `git commit -m "feat: 로그인 화면 만들고 버그 고치고 DB도 바꿈"` (여러 작업이 하나로 뭉쳐짐)
- ⭕ **좋은 예**:
  - `feat: 운동 기록 세트별 무게 및 횟수 입력 폼 UI 구현`
  - `fix: Android 에뮬레이터 HTTP 통신 보안 차단 오류 해결`
  - `chore: gradle 의존성에 lombok 추가`

---

## 🚨 6. 긴급 상황 대처법 (Troubleshooting Git)

### Q1. 실수로 `main` 브랜치에서 코드를 수정하고 아직 커밋을 안 했어요!
> 당황하지 마시고 수정한 코드를 임시 보관한 뒤 새 브랜치로 가져오면 됩니다:
```bash
# 1. 수정사항 임시 보관함에 저장
git stash

# 2. 새 작업 브랜치 생성 및 이동
git checkout -b feature/내작업-이름

# 3. 임시 보관한 작업 불러오기
git stash pop

# 4. 이제 안전하게 커밋!
git add .
git commit -m "feat: ..."
```

### Q2. 실수로 `main` 브랜치에 커밋(`commit`)까지 해버렸어요! (아직 push는 안 함)
```bash
# 1. 방금 한 커밋을 취소하고 코드 변경 상태는 유지 (soft reset)
git reset --soft HEAD~1

# 2. 새 작업 브랜치 생성 및 이동
git checkout -b feature/내작업-이름

# 3. 안전하게 커밋
git commit -m "feat: ..."
```

---

## 📋 7. Pull Request (PR) 작성 템플릿

GitHub에서 PR을 올릴 때 아래 양식을 복사하여 작성하면 상호 리뷰가 훨씬 수월해집니다:

```markdown
## 📌 작업 개요
- [예: 운동 세트 완료 시 카운트다운 휴식 타이머 기능 구현]

## 🛠️ 주요 변경 사항
- `mobile-app/lib/screens/home_screen.dart`: 타이머 모달 위젯 추가
- 60초 / 90초 기본 프리셋 버튼 및 시작/정지/리셋 로직 구현

## 📸 스크린샷 (UI 변경 시)
| 타이머 동작 화면 | 완료 팝업 |
| :---: | :---: |
| (이미지 첨부) | (이미지 첨부) |

## ✅ 셀프 체크리스트
- [ ] 로컬에서 빌드 및 구동 에러가 없는지 확인했나요?
- [ ] 불필요한 `print`문이나 주석을 정리했나요?
- [ ] `main`이 아닌 `develop`을 Base로 지정했나요?
```
