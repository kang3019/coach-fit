# 🔐 환경 변수 안내

CoachFit 실행에 필요한 환경 변수 및 설정 파일 정리입니다.

---

## 🐍 Python AI 서버 (`python-ai-backend/.env`)

파일이 없어도 스마트 더미 코칭 엔진으로 정상 동작합니다.
실제 LLM을 사용하려면 `.env.example`을 복사해 `.env`로 만들고 아래 값을 채워주세요.

| 변수명 | 필수 여부 | 기본값 | 설명 |
| :--- | :---: | :--- | :--- |
| `AI_PROVIDER` | ⭕ | `dummy` | `dummy` / `openai` / `claude` 중 선택 |
| `OPENAI_API_KEY` | △ | — | `AI_PROVIDER=openai` 일 때 필수. `sk-...` 형태 |
| `ANTHROPIC_API_KEY` | △ | — | `AI_PROVIDER=claude` 일 때 필수. `sk-ant-...` 형태 |
| `HOST` | ❌ | `0.0.0.0` | FastAPI 바인딩 호스트 |
| `PORT` | ❌ | `8000` | FastAPI 포트 |

⭕ 필수 · △ 조건부 필수 · ❌ 선택

### `.env` 파일 예시

```env
# 지능형 더미 모드 (API 키 없이 개발)
AI_PROVIDER=dummy

# OpenAI 모드
# AI_PROVIDER=openai
# OPENAI_API_KEY=sk-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

# Claude 모드
# AI_PROVIDER=claude
# ANTHROPIC_API_KEY=sk-ant-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

HOST=0.0.0.0
PORT=8000
```

---

## ☕ Java Spring Boot 서버 (`java-backend/src/main/resources/application.yml`)

| 설정 키 | 기본값 | 설명 |
| :--- | :--- | :--- |
| `server.port` | `8080` | Java 서버 포트 |
| `spring.datasource.url` | H2 인메모리 | DB 접속 URL (MySQL 전환 시 교체) |
| `spring.datasource.username` | `sa` | DB 사용자 |
| `spring.datasource.password` | (빈 값) | DB 비밀번호 |
| `spring.jpa.hibernate.ddl-auto` | `update` | 스키마 자동 갱신 정책 |
| `spring.h2.console.enabled` | `true` | H2 웹 콘솔 활성화 |
| `ai-service.url` | `http://localhost:8000` | Python AI 서버 주소 |

### MySQL 전환 시 교체 예시

```yaml
spring:
  datasource:
    driver-class-name: com.mysql.cj.jdbc.Driver
    url: jdbc:mysql://localhost:3306/coachfit?useSSL=false&serverTimezone=UTC&allowPublicKeyRetrieval=true
    username: root
    password: your_password
```

---

## 🌐 프론트엔드 (`frontend/app.js`)

현재는 하드코딩된 URL을 사용합니다. 추후 `config.js` 로 분리 예정.

| 상수 | 기본값 | 용도 |
| :--- | :--- | :--- |
| `JAVA_API_BASE` | `http://localhost:8080` | Java 백엔드 API 베이스 URL |
| `PYTHON_API_BASE` | `http://localhost:8000` | Python AI 서버 베이스 URL |

---

## ⚠️ 보안 주의사항

1. **`.env` 파일은 절대 커밋 금지** — 이미 `.gitignore` 에 등록되어 있습니다
2. **API 키는 팀 채팅방/노션 등 안전한 채널로 공유** — Slack DM, 카톡 등
3. **커밋 전 항상 확인** — `git status` 로 `.env` 가 스테이지에 없는지 체크
4. **API 키 노출 시** — 즉시 해당 제공자 대시보드에서 키 폐기(revoke) 후 재발급
5. **운영 배포 시** — AWS Secrets Manager / GitHub Actions Secrets 사용 권장

---

## 🚨 실수로 `.env` 를 커밋했다면?

```bash
# 1. 파일을 git 이력에서 완전 제거
git rm --cached python-ai-backend/.env
git commit -m "chore: .env 실수 커밋 제거"

# 2. .gitignore 재확인
git check-ignore -v python-ai-backend/.env

# 3. API 키는 반드시 폐기 후 재발급 (푸시된 순간 이미 유출된 것으로 간주)
```
