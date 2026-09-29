# 🛠️ 트러블슈팅 & FAQ

CoachFit 개발 중 자주 마주치는 오류와 해결 방법 모음입니다.
새 이슈를 만나면 이곳에 추가해 주세요.

---

## 🔴 서버 실행 관련

### Q1. 프론트 상단 배지에 "Java 서버 (8080)"가 빨간색이에요.

**원인**: Java 서버가 안 떠있거나 8080 포트가 다른 프로세스에 점유됨.

**해결 방법**
```powershell
# 1. Gradle 실행 여부 확인
cd java-backend
./gradlew bootRun

# 2. 8080 포트 점유 프로세스 확인 (Windows)
netstat -ano | findstr :8080

# 3. 점유 중인 프로세스 종료 (PID 확인 후)
taskkill /PID <PID번호> /F

# 4. 포트 자체를 바꾸려면 application.yml에서
# server.port: 8081 로 수정 (프론트 app.js 도 함께 변경 필요)
```

---

### Q2. Python 서버에서 `ModuleNotFoundError: No module named 'fastapi'` 가 떠요.

**원인**: 가상환경 활성화가 안 되었거나 의존성이 설치되지 않음.

**해결 방법**
```powershell
cd python-ai-backend

# 1. 가상환경 활성화 (터미널 앞에 (venv) 표시되어야 정상)
.\venv\Scripts\Activate.ps1

# 2. 의존성 설치
pip install -r requirements.txt

# 3. 그래도 안 되면 venv 재생성
rmdir /S /Q venv
python -m venv venv
.\venv\Scripts\Activate.ps1
pip install -r requirements.txt
```

---

### Q3. PowerShell에서 `Activate.ps1` 실행 정책 오류가 발생해요.

**에러 메시지**: `... 이 시스템에서 스크립트를 실행할 수 없으므로 ...`

**해결 방법**
```powershell
# 관리자 권한 PowerShell 열고 실행
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

---

## 🌐 브라우저 / CORS 관련

### Q4. CORS 에러 (Access-Control-Allow-Origin) 가 발생해요.

**원인**
- 프론트를 `file://` 프로토콜로 직접 열면 대부분의 브라우저가 API 호출을 차단
- 또는 CORS 허용 origin에 프론트 주소가 등록되지 않음

**해결 방법**
1. VS Code `Live Server` 확장 설치 후 `index.html` 우클릭 → "Open with Live Server"
2. 그래도 안 되면 Java `config/CorsConfig.java` 의 허용 origin 확인
3. Python `app/main.py` 의 `CORSMiddleware` 허용 origin 확인

---

### Q5. 프론트에서 API 호출은 되는데 응답이 안 와요.

**체크리스트**
- [ ] 브라우저 개발자 도구(F12) → Network 탭에서 실제 요청 확인
- [ ] Console 탭에 에러 메시지 있는지 확인
- [ ] `app.js` 의 `JAVA_API_BASE` / `PYTHON_API_BASE` 값이 실행 중인 포트와 일치하는지
- [ ] 각 서버 터미널에 요청 로그가 찍히는지

---

## 🗄️ 데이터베이스 관련

### Q6. H2 콘솔(`http://localhost:8080/h2-console`)에 접속했는데 테이블이 안 보여요.

**원인**: JDBC URL을 기본값 그대로 두고 접속.

**해결 방법**
| 필드 | 값 |
| :--- | :--- |
| JDBC URL | `jdbc:h2:mem:coachfitdb` ← 기본값과 다름 주의 |
| User Name | `sa` |
| Password | (빈 값) |

---

### Q7. Java 서버 재시작하면 데이터가 다 사라져요.

**원인**: H2 인메모리 DB는 서버 종료 시 데이터 소멸됨 (정상 동작).

**해결 방법**
- 개발 중이라면 `WorkoutService`의 초기 더미 데이터 시드로 매번 5개가 자동 생성됨
- 데이터를 유지하려면 파일 모드로 전환: `application.yml` 에서 `jdbc:h2:file:./data/coachfit` 로 변경
- 또는 MySQL 로 전환 ([03-environment-variables.md](./03-environment-variables.md) 참조)

---

## 🤖 AI 코칭 관련

### Q8. AI 코칭 응답이 계속 똑같은 더미 텍스트만 나와요.

**원인**: `.env` 미설정 또는 `AI_PROVIDER=dummy` 로 되어있음.

**해결 방법**
1. `python-ai-backend/.env` 파일 열기 (없으면 `.env.example` 복사)
2. `AI_PROVIDER=openai` (또는 `claude`) 로 변경
3. 해당 API 키 입력
4. **Python 서버 재시작** (`.env` 는 실행 시점에만 로드됨)

---

### Q9. OpenAI API 호출 시 `RateLimitError` 또는 `AuthenticationError` 가 떠요.

**체크 사항**
- API 키가 유효한지 (OpenAI 대시보드에서 확인)
- 크레딧이 남아있는지 (Billing 페이지)
- 키가 `sk-` 로 시작하는지 (프로젝트 키는 `sk-proj-`)
- 서버 재시작 후 시도

---

## 🔧 Git / 협업 관련

### Q10. `git pull` 시 conflict 가 발생해요.

**해결 방법**
```bash
# 1. 현재 작업 임시 저장
git stash -u

# 2. pull
git pull origin main

# 3. 저장한 작업 복원
git stash pop

# 4. 충돌 파일 수동 편집 후
git add <파일>
git commit
```

---

### Q11. 실수로 main 브랜치에 커밋했어요.

```bash
# 1. 브랜치 새로 만들기 (현재 커밋 위치 그대로)
git checkout -b feature/my-work

# 2. main 을 원격 상태로 되돌리기
git checkout main
git reset --hard origin/main

# 3. 새 브랜치에서 계속 작업
git checkout feature/my-work
```

⚠️ `git reset --hard` 는 작업 내용을 지우므로 1번 단계로 먼저 브랜치를 만들어야 합니다.

---

## 📱 (신규) Flutter 모바일 관련

`mobile-app/` 폴더가 추가되었습니다. Flutter 관련 이슈는 아래에 추가해 주세요.

### Q12. `flutter run` 시 SDK 를 못 찾아요.

```bash
# Flutter SDK 설치 확인
flutter doctor

# 문제 있는 항목 하나씩 해결 (Android SDK, Xcode 등)
```

---

## 📝 새 이슈 등록 템플릿

```markdown
### Q?. [문제 요약]

**원인**:

**해결 방법**:
```
```
```
```
