#!/bin/bash
# ==============================================================================
# CoachFit EC2 원터치 자동 배포 스크립트 (deploy.sh)
# 
# 사용법 (EC2 인스턴스 내부):
#   cd /home/ubuntu/coach-fit/python-ai-backend
#   bash scripts/deploy.sh
# ==============================================================================

set -e

echo "🚀 [1/5] 최신 소스코드 동기화 (Git Pull)..."
git fetch origin main
git checkout main
git pull origin main

echo "📦 [2/5] 파이썬 가상환경 점검 및 의존성 패키지 설치..."
if [ ! -d ".venv" ]; then
    echo "  -> 가상환경(.venv) 신규 생성 중..."
    python3 -m venv .venv
fi
source .venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt

echo "🗄️ [3/5] 데이터베이스 스키마 및 초기 시드 데이터 점검..."
python3 -c "from app.database import init_db; init_db(); print('  -> DB 초기화 및 테이블 연결 완료')"

echo "🔄 [4/5] CoachFit 백엔드 서비스(Systemd) 재가동..."
if systemctl is-active --quiet coachfit; then
    sudo systemctl restart coachfit
    echo "  -> coachfit 서비스 재시작 완료"
else
    echo "  -> coachfit 서비스가 등록되어 있지 않거나 비활성 상태입니다."
    echo "  -> 서비스 파일 등록을 시도합니다..."
    sudo cp scripts/coachfit.service /etc/systemd/system/
    sudo systemctl daemon-reload
    sudo systemctl enable coachfit
    sudo systemctl start coachfit
fi

echo "✅ [5/5] 서비스 구동 상태 확인..."
sudo systemctl status coachfit --no-pager -l

echo "===================================================================="
echo "🎉 배포 성공! CoachFit 백엔드가 포트 8000에서 정상 구동 중입니다."
echo "===================================================================="
