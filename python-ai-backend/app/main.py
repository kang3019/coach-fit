import os
import uvicorn
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from dotenv import load_dotenv

from app.models.schemas import CoachingRequest, CoachingResponse
from app.services.ai_coach import generate_coaching_advice

# .env 환경 변수 로드
load_dotenv()

app = FastAPI(
    title="CoachFit AI Coaching Engine",
    description="Java 백엔드로부터 운동 기록을 전달받아 AI 분석 및 맞춤 루틴을 생성하는 마이크로서비스",
    version="1.0.0"
)

# CORS 설정: Java 서버 및 프론트엔드 직접 호출 모두 허용
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/")
def read_root():
    return {
        "service": "CoachFit AI Service",
        "status": "online",
        "docs_url": "/docs",
        "endpoints": {
            "coaching": "POST /api/coaching",
            "health": "GET /health"
        }
    }


@app.get("/health")
def health_check():
    return {"status": "healthy"}


@app.post("/api/coaching", response_model=CoachingResponse)
def get_ai_coaching(request: CoachingRequest):
    """
    운동 기록 데이터를 입력받아 AI 코칭 피드백과 오늘 추천 루틴을 생성하여 반환합니다.
    """
    try:
        response = generate_coaching_advice(request)
        return response
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"AI 코칭 생성 실패: {str(e)}")


if __name__ == "__main__":
    host = os.getenv("HOST", "0.0.0.0")
    port = int(os.getenv("PORT", 8000))
    print(f"Starting CoachFit AI Server on {host}:{port}...")
    uvicorn.run("app.main:app", host=host, port=port, reload=True)
