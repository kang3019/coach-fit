# ☁️ CoachFit AWS 정석 풀스택 배포 및 운영 가이드

> **아키텍처**: AWS EC2 (FastAPI 단일 백엔드) + AWS RDS (PostgreSQL 16) + AWS Bedrock (Claude 3.5 / Nova) + AWS CDK (TypeScript IaC)

---

## 🏛️ 1. 전체 아키텍처 개요

```mermaid
flowchart TD
    subgraph Mobile ["클라이언트"]
        App["CoachFit Flutter 모바일 앱"]
    end

    subgraph AWS_Cloud ["AWS Cloud (VPC)"]
        subgraph Compute ["AWS EC2 (Ubuntu 22.04 LTS)"]
            FastAPI["FastAPI 백엔드 (:8000)<br/>- Systemd 서비스 24시간 상시 가동<br/>- deploy.sh 원터치 Git 배포"]
            IAM["EC2 IAM Role<br/>(AmazonBedrockFullAccess)"]
        end

        subgraph Database ["AWS RDS (완전 관리형)"]
            RDS[("PostgreSQL 16<br/>- 오직 EC2 인바운드(5432)만 허용<br/>- 외부 인터넷 직접 차단")]
        end

        subgraph AI ["AWS Bedrock (파운데이션 모델)"]
            Bedrock["Bedrock Runtime<br/>(Claude 3.5 Sonnet / Amazon Nova)<br/>- 무키(Zero-Key) IAM 인증"]
        end
    end

    App -->|HTTP REST (:8000)| FastAPI
    FastAPI -->|psycopg2 / 포트 5432| RDS
    FastAPI -->|boto3 converse API| Bedrock
    IAM -.->|자격증명 자동 인가| FastAPI
```

---

## 🚀 2. 방법 A: AWS CDK (TypeScript)로 원클릭 배포 (가장 추천)

인프라 전체(VPC, RDS, EC2, IAM 권한, 보안 그룹)를 TypeScript 코드로 100% 자동 생성합니다.

### 1단계: 패키지 설치
```bash
cd infra
npm install
npm run build
```

### 2단계: CDK 배포 실행
```bash
# 최초 1회 부트스트랩 (필요한 경우)
cdk bootstrap

# 전체 인프라 원클릭 프로비저닝
cdk deploy
```

배포가 완료되면 터미널에 **EC2 퍼블릭 IP**, **SSH 접속 명령어**, **RDS `DATABASE_URL`**이 자동 출력됩니다.

---

## 🛠️ 3. 방법 B: AWS 웹 콘솔에서 수동 생성하기

### 1) AWS Bedrock 모델 권한 활성화 (Model Access)
1. AWS 콘솔에서 **Amazon Bedrock** 서비스 검색
2. 좌측 메뉴 맨 아래 **Model access** (모델 액세스) 클릭
3. **Modify model access** 클릭 후:
   - **Anthropic: Claude 3.5 Sonnet** 및 **Claude 3 Haiku** 체크
   - **Amazon: Amazon Nova Lite** 체크
4. **Save changes** 클릭 (수 분 내 `Access granted` 로 전환)

### 2) AWS RDS (PostgreSQL 16) 생성
1. **RDS** > **데이터베이스 생성** 클릭
2. **PostgreSQL** 선택 (버전: 16.x)
3. 템플릿: **프리 티어(Free Tier)** 선택
4. DB 인스턴스 식별자: `coachfit-db`
5. 마스터 사용자 이름: `coachfit_admin`
6. 마스터 암호: 안전한 비밀번호 입력 (예: `CoachFit2026!Secure`)
7. 인스턴스 구성: `db.t3.micro` or `db.t4g.micro`
8. 스토리지: 20 GB (스토리지 자동 조정 활성화)
9. 연결:
   - 퍼블릭 액세스: **아니요** (보안 정석: 인터넷 노출 차단)
   - VPC 보안 그룹: **새로 생성** (`coachfit-rds-sg`)
10. 추가 구성:
    - 초기 데이터베이스 이름: `coachfit`
11. **데이터베이스 생성** 클릭

### 3) EC2 인스턴스 생성 및 pem 키 발급
1. **EC2** > **인스턴스 시작** 클릭
2. 이름: `coachfit-backend-server`
3. AMI: **Ubuntu Server 22.04 LTS** (Free Tier eligible)
4. 인스턴스 유형: `t3.micro`
5. **키 페어**: **새 키 페어 생성**
   - 키 이름: `coachfit-key`
   - 키 페어 유형: RSA
   - 프라이빗 키 파일 형식: `.pem`
   - **[중요] `coachfit-key.pem` 파일을 로컬 PC의 안전한 폴더에 보관**
6. 네트워크 설정 (보안 그룹):
   - SSH 트래픽 허용 (포트 22)
   - 위치 무관 사용자 지정 TCP: **포트 8000 허용** (FastAPI 백엔드)
7. **인스턴스 시작** 클릭

### 4) EC2에 Bedrock IAM Role 부여 (교수님 최고 가산점)
1. **IAM** > **역할(Role)** > **역할 생성**
2. 신뢰할 수 있는 엔터티 유형: **AWS 서비스** > 사용 사례: **EC2**
3. 권한 정책 추가:
   - `AmazonBedrockFullAccess` 검색 후 체크
   - `AmazonSSMManagedInstanceCore` 검색 후 체크
4. 역할 이름: `CoachFitEc2BedrockRole` 입력 후 생성
5. **EC2 콘솔**로 이동 > 방금 생성한 인스턴스 우클릭 > **보안** > **IAM 역할 수정**
6. `CoachFitEc2BedrockRole` 선택 후 **IAM 역할 업데이트** 클릭

### 5) RDS 보안 그룹에 EC2 인스턴스 인바운드 허용
1. **RDS 콘솔** > `coachfit-db` 상세 페이지 > **연결 및 보안** 탭의 보안 그룹 클릭
2. **인바운드 규칙 편집** 클릭
3. 유형: **PostgreSQL (포트 5432)**
4. 소스: EC2 인스턴스의 보안 그룹 ID (예: `sg-0abc123...`) 선택 후 저장

---

## 🔑 4. pem 키로 EC2 접속 및 배포 ("pem키로 땡겨오기")

### 1) pem 키 권한 설정 및 SSH 접속
로컬 PC 터미널(Windows PowerShell 또는 Mac/Linux)에서 pem 키가 있는 폴더로 이동:

* **Windows PowerShell**:
  ```powershell
  # pem 키 권한 상속 정리 (권한 오류 발생 시)
  icacls.exe .\coachfit-key.pem /reset
  icacls.exe .\coachfit-key.pem /grant:r "$($env:username):(R)"
  icacls.exe .\coachfit-key.pem /inheritance:r

  # SSH 접속
  ssh -i "coachfit-key.pem" ubuntu@<EC2-퍼블릭-IP>
  ```

* **Mac / Linux**:
  ```bash
  chmod 400 coachfit-key.pem
  ssh -i "coachfit-key.pem" ubuntu@<EC2-퍼블릭-IP>
  ```

---

### 2) EC2 서버 내부 초기 1회 세팅 (setup_ec2.sh)
EC2에 접속한 후 홈 디렉토리에서 아래 명령어를 실행하면 Git clone, Python 가상환경, 필수 패키지가 자동 구성됩니다:

```bash
# CoachFit 초기 환경 원클릭 자동 세팅
curl -fsSL https://raw.githubusercontent.com/kang3019/coach-fit/main/python-ai-backend/scripts/setup_ec2.sh | bash
```

---

### 3) 환경 변수(.env) 설정
EC2의 프로젝트 폴더로 이동하여 `.env` 파일을 작성합니다:

```bash
cd /home/ubuntu/coach-fit/python-ai-backend
nano .env
```

아래 내용을 기입하고 저장(`Ctrl + O` -> `Enter` -> `Ctrl + X`):
```env
# AI 코칭 공급자: 학교/기관 5만원 한도 제어 Bedrock 게이트웨이 (OpenAI 호환 규격)
AI_PROVIDER=bedrock-gateway
BEDROCK_GATEWAY_BASE_URL=<발급받은-게이트웨이-BASE-URL>
BEDROCK_GATEWAY_API_KEY=<발급받은-게이트웨이-API-KEY>
BEDROCK_GATEWAY_MODEL=bedrock-sonnet # bedrock-sonnet | bedrock-haiku | bedrock-gpt-5.6-luna

# AWS 서울 리전 (ap-northeast-2)
AWS_REGION=ap-northeast-2

# 서버 설정
HOST=0.0.0.0
PORT=8000

# AWS RDS (PostgreSQL) 연결 URL
DATABASE_URL=postgresql://coachfit_admin:CoachFit2026!Secure@<RDS-엔드포인트-주소>:5432/coachfit
```

---

### 4) 원터치 배포 및 실행 (`deploy.sh`)
이후 코드를 수정하여 GitHub에 올릴 때마다, EC2 터미널에서 다음 스크립트 하나만 실행하면 됩니다:

```bash
cd /home/ubuntu/coach-fit/python-ai-backend
bash scripts/deploy.sh
```

**스크립트 동작 내용:**
1. `git pull origin main` (최신 코드 자동 동기화)
2. Python 가상환경 의존성 업데이트 (`pip install -r requirements.txt`)
3. PostgreSQL DB 테이블 및 초기 시드 데이터 자동 초기화
4. `systemctl restart coachfit` 백엔드 데몬 무중단 재기동

---

## 📱 5. 모바일 앱(Flutter)에서 EC2 실서버 연결

모바일 앱의 [mobile-app/lib/config/api_constants.dart](file:///C:/coach%20fit/mobile-app/lib/config/api_constants.dart) 파일을 열고:

```dart
// AWS EC2 서울 리전 퍼블릭 IP를 기입합니다
static const String _ec2HostOverride = '<EC2-퍼블릭-IP>';

// AWS EC2 실서버로 원터치 전환할 때 true 로 설정
static const bool useEc2Backend = true;
```

이제 스마트폰 실기기나 에뮬레이터에서 회원가입, 운동 기록, AI 코칭을 실행하면 **AWS EC2 + AWS RDS + AWS Bedrock**으로 구성된 정석 클라우드 파이프라인을 통해 즉시 동작합니다!
