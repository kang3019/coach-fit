# 📜 라이선스 안내

CoachFit 프로젝트의 라이선스 정책 및 제3자 라이브러리 라이선스 정리입니다.

---

## 🏫 프로젝트 라이선스 (현재)

**학교 협업 프로젝트 (Educational Use)**

- 목적: 학교 수업/팀 프로젝트용 학습 및 포트폴리오 용도
- 상업적 배포 및 재사용은 팀원 협의 후 결정
- 정식 라이선스는 v1.0 릴리즈 시점에 확정 예정

---

## 📝 라이선스 선택 가이드 (참고)

향후 오픈소스로 공개할 경우 아래 중 하나를 선택하면 됩니다.

### 1. MIT License (권장)
- 가장 널리 쓰이는 관대한(permissive) 라이선스
- 상업적 이용, 수정, 배포 모두 자유
- 사용자는 저작권 고지만 유지하면 됨
- **추천 케이스**: 최대한 많은 사람이 자유롭게 쓰길 원할 때

### 2. Apache License 2.0
- MIT와 비슷하지만 **특허권 명시** 조항 포함
- 기업 프로젝트에서 선호
- **추천 케이스**: 특허 관련 이슈까지 고려하고 싶을 때

### 3. GPL v3
- **강한 카피레프트** — 이 코드를 쓴 파생 제품도 GPL로 공개해야 함
- **추천 케이스**: 코드가 폐쇄 소프트웨어에 흡수되는 걸 원치 않을 때

### 4. 비공개 유지 (Proprietary)
- 라이선스 파일 없이 그대로 두면 기본적으로 **모든 권리 보유(All Rights Reserved)**
- **추천 케이스**: 상업 서비스로 발전시킬 계획일 때

---

## 🔒 v1.0 이전 임시 정책

정식 라이선스 확정 전까지 다음과 같이 취급:

1. **저장소 fork / clone 은 자유** — GitHub 공개 저장소 특성상 열려있음
2. **코드 재사용은 팀원 허락 필요** — 팀장(친구)에게 문의
3. **포트폴리오 게재는 자유** — 참여자 본인의 이력서/포트폴리오 사용은 OK
4. **상업적 이용 금지** — 정식 라이선스 결정 전까지

---

## 📦 사용 중인 제3자 라이브러리 라이선스

주요 의존성의 라이선스 목록입니다. `LICENSE` 파일 작성 시 참고.

### Java 백엔드
| 라이브러리 | 라이선스 |
| :--- | :--- |
| Spring Boot 3.x | Apache 2.0 |
| Spring Data JPA | Apache 2.0 |
| H2 Database | MPL 2.0 / EPL 1.0 |
| MySQL Connector | GPL 2.0 (with FOSS exception) |
| Lombok | MIT |
| JWT (jjwt) | Apache 2.0 |

### Python AI 서버
| 라이브러리 | 라이선스 |
| :--- | :--- |
| FastAPI | MIT |
| Uvicorn | BSD 3-Clause |
| Pydantic | MIT |
| OpenAI SDK | Apache 2.0 |
| Anthropic SDK | MIT |
| python-dotenv | BSD 3-Clause |

### 프론트엔드
| 라이브러리 | 라이선스 |
| :--- | :--- |
| Chart.js | MIT |

### Flutter 모바일
| 라이브러리 | 라이선스 |
| :--- | :--- |
| Flutter SDK | BSD 3-Clause |
| (기타 pub.dev 패키지) | 각 패키지별 상이 |

---

## 📄 정식 LICENSE 파일 템플릿 (MIT 예시)

v1.0 릴리즈 시점에 프로젝트 루트에 `LICENSE` 파일로 생성:

```
MIT License

Copyright (c) 2026 CoachFit Team (kang3019, [팀원 리스트])

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

---

## 🤝 기여자 및 저작권

| 역할 | 이름 / GitHub | 기여 영역 |
| :--- | :--- | :--- |
| 팀장 / 프로젝트 오너 | [@kang3019](https://github.com/kang3019) | 초기 스켈레톤, 모바일, 인프라 |
| 팀원 | (본인) | 문서화, ... |
| 팀원 | ? | ? |

> 팀원 정보는 확정 후 위 표에 추가해 주세요.
