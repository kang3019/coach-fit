# ☁️ CoachFit AWS CDK (TypeScript) 인프라 프로젝트

이 프로젝트는 **AWS EC2, AWS RDS (PostgreSQL 16), AWS Bedrock IAM 권한, VPC 보안 그룹**을 코드(IaC)로 정의하고 원클릭으로 자동 프로비저닝하는 **TypeScript 기반 AWS CDK 스택**입니다.

---

## 🏗️ 구성 아키텍처 (Infrastructure as Code)

1. **VPC (`CoachFitVpc`)**:
   - 2개 가용 영역 (AZ)
   - 퍼블릭 서브넷 (EC2 인스턴스 위치)
   - 격리형 프라이빗 서브넷 (RDS PostgreSQL 위치)
2. **보안 그룹 (Security Groups)**:
   - `EC2 Security Group`: SSH (포트 22), FastAPI 백엔드 (포트 8000), 웹 (포트 80) 허용
   - `RDS Security Group`: 외부 인터넷 완전 차단, **오직 EC2 인스턴스의 트래픽(포트 5432)만 허용**
3. **AWS RDS (PostgreSQL 16)**:
   - 인스턴스: `db.t3.micro` (AWS 프리티어 적격)
   - DB명: `coachfit`, 계정: `coachfit_admin`
4. **AWS EC2 (Ubuntu 22.04 LTS)**:
   - 인스턴스: `t3.micro`
   - 키 페어: `.pem` 파일 연동
   - **IAM Role (`AmazonBedrockFullAccess`)**: EC2 내부에서 API 키 없이 Bedrock AI 코칭 자동 호출
5. **출력 (Outputs)**:
   - EC2 퍼블릭 IP 및 SSH 접속 명령어 (`ssh -i "coachfit-key.pem" ubuntu@<IP>`)
   - Swagger 문서 URL (`http://<IP>:8000/docs`)
   - `.env`에 바로 붙여넣는 `DATABASE_URL` 연결 문자열

---

## 🚀 배포 방법 (Deployment)

### 1. 사전 요구사항
* Node.js (v18 이상)
* AWS CLI 설치 및 자격증명 구성 (`aws configure`)
* AWS CDK 전역 설치:
  ```bash
  npm install -g aws-cdk
  ```

### 2. 패키지 설치 및 빌드
```bash
cd infra
npm install
npm run build
```

### 3. 인프라 배포 (원클릭)
```bash
# 최초 1회 CDK 부트스트랩 (필요한 경우)
cdk bootstrap

# 인프라 자동 생성 및 배포
cdk deploy
```

배포가 완료되면 터미널에 EC2 퍼블릭 IP와 SSH 접속 명령어, RDS `DATABASE_URL`이 출력됩니다.

### 4. 인프라 삭제 (프로젝트 종료 시 비용 방지)
```bash
cdk destroy
```
