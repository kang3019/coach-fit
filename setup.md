# 🚀 Coach Fit 로컬 개발 및 서버 실행 가이드 (setup.md)

Coach Fit 프로젝트의 **FastAPI 백엔드** 및 **Flutter 앱**을 로컬 환경에서 실행하고 테스트하는 단계별 가이드입니다.

---

## 📋 목차
1. [시스템 요구 사항](#1-시스템-요구-사항)
2. [백엔드 서버 실행 (FastAPI, 포트 8000)](#2-백엔드-서버-실행-fastapi-포트-8000)
3. [프론트엔드/앱 실행 (Flutter 모바일·웹·데스크톱)](#3-프론트엔드앱-실행-flutter-모바일웹데스크톱)
4. [네트워크 및 접속 주소 분기 안내](#4-네트워크-및-접속-주소-분기-안내)
5. [자주 발생하는 문제 및 해결 방법 (FAQ)](#5-자주-발생하는-문제-및-해결-방법-faq)

---

## 1. 시스템 요구 사항

- **Python**: 3.10 이상
- **Flutter SDK**: 3.24.0 이상 (Dart 3.5.0 이상)
- **Git**
- (선택) Google Chrome / Android Studio 에뮬레이터 / VS Code / Cursor

---

## 2. 백엔드 서버 실행 (FastAPI, 포트 8000)

Coach Fit은 **FastAPI 단일 백엔드** 원칙으로 모든 운동 기록 CRUD 및 AI 코칭을 단일 포트(`8000`)에서 처리합니다.

### 2-1. 백엔드 폴더 이동
```powershell
cd "C:\coach fit\python-ai-backend"
```

### 2-2. 가상환경(venv) 활성화 및 의존성 확인
이미 프로젝트 내에 `venv`가 구성되어 있습니다.

- **PowerShell**:
  ```powershell
  # 스크립트 실행 권한 허용 (필요한 경우 1회 실행)
  Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass

  .\venv\Scripts\Activate.ps1
  ```
- **명령 프롬프트 (CMD)**:
  ```cmd
  venv\Scripts\activate.bat
  ```

> 💡 **가상환경이 없거나 새로 만들 경우**:
> ```powershell
> python -m venv venv
> .\venv\Scripts\Activate.ps1
> pip install -r requirements.txt
> ```

### 2-3. 환경 변수 설정 (선택 사항)
`.env` 파일이 없어도 **스마트 더미 AI 모드**와 **로컬 SQLite DB(`coachfit.db`)**로 즉시 작동합니다.
OpenAI API를 직접 테스트하려면 `.env` 파일을 생성합니다.

```powershell
copy .env.example .env
```
*(필요 시 `.env` 내 `OPENAI_API_KEY`를 입력)*

### 2-4. 서버 시작 (Uvicorn)
가상환경이 활성화된 상태에서 아래 명령어를 실행합니다:

```powershell
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```

> **단축 원라인 실행 (가상환경 활성화 없이 바로 실행)**:
> ```powershell
> .\venv\Scripts\python.exe -m uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
> ```

### 2-5. 서버 정상 구동 확인
- **기본 API 헬스체크**: [http://localhost:8000](http://localhost:8000)
- **인터랙티브 API 명세서 (Swagger)**: [http://localhost:8000/docs](http://localhost:8000/docs)
- **대체 API 명세서 (ReDoc)**: [http://localhost:8000/redoc](http://localhost:8000/redoc)

---

## 3. 프론트엔드/앱 실행 (Flutter 모바일·웹·데스크톱)

### 3-1. 새 터미널 열기 및 앱 폴더 이동
백엔드 서버 터미널은 켜둔 상태로, **새 터미널**을 엽니다.

```powershell
cd "C:\coach fit\mobile-app"
```

### 3-2. 패키지 의존성 최신화
```powershell
flutter pub get
```

### 3-3. 실행 디바이스 선택 및 실행

사용 가능한 기기 목록을 확인합니다:
```powershell
flutter devices
```

원하는 플랫폼에 맞춰 실행 명령을 입력합니다:

- **Windows 데스크톱 앱 (추천 - 가장 빠르고 직관적)**:
  ```powershell
  flutter run -d windows
  ```

- **웹 브라우저 (Chrome)**:
  ```powershell
  flutter run -d chrome
  ```

- **Android 에뮬레이터**:
  ```powershell
  flutter run -d <emulator-id>
  ```

---

## 4. 네트워크 및 접속 주소 분기 안내

Flutter 앱의 [api_constants.dart](file:///C:/coach%20fit/mobile-app/lib/config/api_constants.dart)에서 실행 환경에 따라 백엔드 URL을 자동으로 분기합니다.

| 실행 환경 | 접속 백엔드 주소 | 설명 |
| :--- | :--- | :--- |
| **Windows 데스크톱** | `http://localhost:8000` | 로컬 루프백 통신 (기본) |
| **Chrome 웹 브라우저** | `http://localhost:8000` | 브라우저 직접 통신 (CORS 허용됨) |
| **Android 에뮬레이터** | `http://10.0.2.2:8000` | Android 에뮬레이터 호스트 루프백 자동 변환 |
| **실제 스마트폰 (Wi-Fi)** | `http://<노트북_IP>:8000` | 아래 안내 참고 |

### 📱 실제 스마트폰 디바이스에서 테스트할 때
1. PC와 스마트폰을 **동일한 Wi-Fi 공유기**에 연결합니다.
2. PC의 IP 주소 확인 (`ipconfig` 실행 -> `IPv4 주소` 확인, 예: `192.168.0.25`).
3. [mobile-app/lib/config/api_constants.dart](file:///C:/coach%20fit/mobile-app/lib/config/api_constants.dart)의 `_physicalDeviceHostOverride`에 IP 입력:
   ```dart
   static const String _physicalDeviceHostOverride = '192.168.0.25';
   ```

---

## 5. 자주 발생하는 문제 및 해결 방법 (FAQ)

### Q1. 포트 8000이 이미 사용 중이라는 오류가 뜹니다 (`address already in use`)
이전에 켜둔 Uvicorn 프로세스가 백그라운드에 남아있을 수 있습니다.
```powershell
# 8000 포트 점유 프로세스 PID 찾기
netstat -ano | findstr :8000

# 프로세스 종료 (예: PID가 12345일 경우)
taskkill /F /PID 12345
```

### Q2. PowerShell에서 `Activate.ps1` 실행 시 보안 오류가 발생합니다
스크립트 실행 권한이 제한되어 있는 경우 발생합니다.
```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
.\venv\Scripts\Activate.ps1
```

### Q3. Flutter 코드 분석(Lint)을 확인하고 싶습니다
`AGENTS.md`의 제로 린트 원칙에 따라 코드 수정 전후 항상 아래 명령을 수행합니다:
```powershell
cd mobile-app
flutter analyze
```
`No issues found!` 상태가 유지되어야 합니다.
