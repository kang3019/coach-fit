# ADR-0002: Java Spring Boot + Python FastAPI 폴리글랏 백엔드 아키텍처 채택

- **상태**: Accepted
- **날짜**: 2026-09-30
- **결정자**: 2인 프로젝트 팀
- **관련 파일**: `java-backend/`, `python-ai-backend/`

---

## 배경

CoachFit은 **"트랜잭션 기반의 안정적인 운동 기록 관리(CRUD/통계)"**와 **"최신 LLM 기반의 AI 맞춤형 운동 루틴 추천"**이라는 서로 다른 성격의 두 가지 핵심 요구사항을 동시에 만족해야 합니다. 이를 단일 서버로 구축할지, 역할별로 분리할지 결정이 필요했습니다.

---

## 고려한 대안

### 대안 A: 단일 Java Spring Boot 백엔드 (OpenAI Java SDK 연동)
- **장점**: 단일 서버로 배포 및 프로세스 관리가 단순함
- **단점**: Java 환경에서 LLM 프롬프트 엔지니어링, 데이터 조작 및 AI 실험 생태계가 Python에 비해 매우 제한적임

### 대안 B: 단일 Python FastAPI 백엔드
- **장점**: AI 연동과 백엔드를 하나의 언어로 통일 가능
- **단점**: 엔터프라이즈급 JPA/트랜잭션 관리와 안정적인 비즈니스 로직 확장성에서 Spring Boot보다 레퍼런스가 부족함

### 대안 C: Java Spring Boot(메인 비즈니스) + Python FastAPI(AI 전담) 폴리글랏 구조
- **장점**: 
  - 백엔드 데이터 영속화와 주간 볼륨 집계는 Java(Spring Boot)가 안정적으로 담당
  - 복잡한 AI 프롬프트 튜닝, Pydantic 검증, LLM 호출은 Python(FastAPI)이 최적화하여 담당
  - 2인 팀의 협업 시 모바일과 백엔드/AI 역할을 나누거나 백엔드 내부에서도 명확한 책임 분리 가능
- **단점**: 
  - 로컬 구동 시 2개의 서버 포트(8080, 8000)를 관리해야 함

---

## 결정

**대안 C (Java Spring Boot + Python FastAPI 폴리글랏 구조)**를 최종 채택한다.

---

## 이유

1. **AI 생태계 활용성**: Python의 풍부한 LLM 및 데이터 분석 라이브러리를 직접 활용하여 수준 높은 코칭 추천 제공 가능.
2. **관심사의 분리(Separation of Concerns)**: 비즈니스 트랜잭션 장애가 AI 추천에 영향을 주지 않고, AI 서버의 장애가 핵심 운동 기록 저장에 영향을 주지 않도록 격리.
3. **학습 및 포트폴리오 가치**: 모바일 중심 서비스이면서도 실무에서 널리 쓰이는 마이크로서비스/멀티 서비스 아키텍처 경험을 입증할 수 있음.

---

## 결과 (예상되는 영향)

### 긍정:
- Spring Boot의 `RestTemplate`을 통해 Python 서버와 느슨한 결합(Loose Coupling) 유지.
- Python 서버 장애 시 Java 백엔드에서 즉시 룰베이스 폴백 처리 가능.

### 부정 / 제약:
- 개발 및 시연 시 Java와 Python 서버를 각각 기동해야 하므로 간편 실행 가이드(또는 일괄 실행 스크립트) 필요.

---

## 후속 작업
- [x] Java ↔ Python 간 RestTemplate 통신 클라이언트 구축 (`AiCoachingClientService.java`)
- [x] 프론트엔드/모바일에서 직접 Python 8000번 호출 및 Java 8080번 경유 호출 모두 지원하도록 CORS 설정
