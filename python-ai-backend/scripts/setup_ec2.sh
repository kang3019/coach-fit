#!/bin/bash
# ==============================================================================
# CoachFit EC2 최초 1회 초기 환경 구성 스크립트 (Ubuntu 22.04 / 24.04 LTS)
# 
# 사용법 (EC2 인스턴스 접속 직후 홈 디렉토리에서):
#   curl -fsSL https://raw.githubusercontent.com/kang3019/coach-fit/main/python-ai-backend/scripts/setup_ec2.sh | bash
# 또는 git clone 후:
#   bash /home/ubuntu/coach-fit/python-ai-backend/scripts/setup_ec2.sh
# ==============================================================================

set -e

echo "📦 [1/4] Ubuntu 시스템 패키지 업데이트 및 필수 패키지 설치..."
sudo apt-get update -y
sudo apt-get install -y python3 python3-pip python3-venv git curl libpq-dev build-essential

echo "📂 [2/4] CoachFit 저장소 확인 및 디렉토리 설정..."
cd /home/ubuntu
if [ ! -d "coach-fit" ]; then
    echo "  -> GitHub 저장소 Clone 중..."
    git clone https://github.com/kang3019/coach-fit.git
fi

cd /home/ubuntu/coach-fit/python-ai-backend

echo "🐍 [3/4] 파이썬 가상환경 생성 및 라이브러리 설치..."
python3 -m venv .venv
source .venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt

echo "⚙️ [4/4] Systemd 서비스 등록..."
sudo cp scripts/coachfit.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable coachfit

echo "===================================================================="
echo "✅ EC2 기본 환경 세팅 완료!"
echo "다음 단계:"
echo " 1. nano /home/ubuntu/coach-fit/python-ai-backend/.env 파일을 열어"
echo "    DATABASE_URL (RDS PostgreSQL 엔드포인트) 및 AI_PROVIDER=bedrock 설정"
echo " 2. bash scripts/deploy.sh 실행하여 백엔드 가동"
echo "===================================================================="
