import os
import json
from datetime import datetime
from typing import List
from app.models.schemas import CoachingRequest, CoachingResponse, RecommendedRoutineItem

def generate_coaching_advice(request: CoachingRequest) -> CoachingResponse:
    """
    Java 서버로부터 전달받은 최근 운동 기록을 분석하여
    AI 코칭 조언과 오늘의 맞춤 추천 루틴을 생성합니다.
    (API 키 설정 시 LLM 연동, 기본 상태에서는 정교한 규칙 기반 더미 코칭 제공)
    """
    openai_key = os.getenv("OPENAI_API_KEY")
    ai_provider = os.getenv("AI_PROVIDER", "dummy").lower()

    if openai_key and ai_provider == "openai":
        return _call_openai_coaching(request, openai_key)

    return _generate_smart_dummy_coaching(request)


def _generate_smart_dummy_coaching(request: CoachingRequest) -> CoachingResponse:
    workouts = request.recent_workouts
    count = len(workouts)

    if count == 0:
        summary = "최근 운동 기록이 없습니다. 새로운 시작을 위해 기초 전신 루틴을 권장합니다."
        advice = "운동을 오랜만에 시작하거나 처음이시라면 무리한 중량보다 정확한 가동 범위와 자세 정렬에 집중해주세요."
        routine = [
            RecommendedRoutineItem(
                exercise_name="고블릿 스쿼트 (덤벨)",
                sets=4,
                reps=12,
                focus="하체 기초 근력 & 코어 밸런스",
                tip="가슴을 펴고 팔꿈치가 무릎 안쪽을 살짝 스치도록 깊게 앉아보세요."
            ),
            RecommendedRoutineItem(
                exercise_name="시티드 체스트 프레스",
                sets=4,
                reps=10,
                focus="대흉근 자극 및 푸시 근력",
                tip="어깨가 위로 솟지 않도록 하강 고정 후 가슴으로 밀어내세요."
            ),
            RecommendedRoutineItem(
                exercise_name="랫 풀 다운",
                sets=4,
                reps=12,
                focus="등 전체(광배근) 활성화",
                tip="바를 쇄골 쪽으로 당길 때 상체가 너무 뒤로 눕지 않도록 주의합니다."
            )
        ]
    else:
        # 최근 기록 분석
        recent_names = [w.exercise_name for w in workouts]
        total_sets = sum(w.sets for w in workouts)
        total_volume = sum(w.weight * w.sets * w.reps for w in workouts)

        summary = (
            f"최근 {count}개 세션 동안 총 {total_sets}세트, "
            f"누적 볼륨 약 {int(total_volume):,}kg을 달성하셨습니다. "
            f"(최근 운동: {', '.join(recent_names[:3])})"
        )

        advice = (
            f"회원님의 목표인 '{request.user_goal}'에 맞추어 점진적 과부하를 적용하기에 적절한 페이스입니다. "
            "최근 상체 밀기 및 하체 운동의 빈도가 높았으므로, 오늘은 등(풀 계열)과 후면 사슬을 보강하여 "
            "체형 밸런스를 잡고 부상을 예방하는 루틴을 추천드립니다."
        )

        routine = [
            RecommendedRoutineItem(
                exercise_name="바벨 데드리프트",
                sets=4,
                reps=8,
                focus="후면 사슬(등 하부, 둔근, 햄스트링) 강화",
                tip="바가 정강이와 허벅지에 밀착되도록 수직 궤적을 유지하세요."
            ),
            RecommendedRoutineItem(
                exercise_name="원 암 덤벨 로우",
                sets=4,
                reps=10,
                focus="광배근 편측 고립 및 불균형 교정",
                tip="골반이 틀어지지 않게 코어를 잡고 팔꿈치를 골반 쪽으로 끌어올리세요."
            ),
            RecommendedRoutineItem(
                exercise_name="페이스 풀 (케이블)",
                sets=4,
                reps=15,
                focus="후면 삼각근 및 회전근개 보호",
                tip="외회전 동작을 더해 엄지손가락이 뒤쪽을 향하도록 마무리 수축을 만드세요."
            )
        ]

    return CoachingResponse(
        summary=summary,
        coaching_advice=advice,
        recommended_routine=routine,
        generated_at=datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    )


def _call_openai_coaching(request: CoachingRequest, api_key: str) -> CoachingResponse:
    """
    OpenAI ChatCompletion (gpt-4o / gpt-3.5-turbo) 연동 예시
    """
    try:
        from openai import OpenAI
        client = OpenAI(api_key=api_key)

        prompt_data = {
            "user_goal": request.user_goal,
            "workouts": [w.model_dump() for w in request.recent_workouts]
        }

        system_prompt = """
        당신은 전문 피트니스 트레이너이자 재활 코치입니다.
        사용자의 최근 운동 기록과 목표를 바탕으로 JSON 규격에 맞춰 코칭 리포트를 작성하세요.
        응답은 다음 JSON 스키마를 만족해야 합니다:
        {
            "summary": "운동 요약 문자열",
            "coaching_advice": "코칭 조언 문자열",
            "recommended_routine": [
                {
                    "exercise_name": "운동명",
                    "sets": 4,
                    "reps": 10,
                    "focus": "타겟 부위",
                    "tip": "자세 팁"
                }
            ]
        }
        """

        response = client.chat.completions.create(
            model="gpt-4o-mini",
            response_format={"type": "json_object"},
            messages=[
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": f"기록 데이터: {json.dumps(prompt_data, ensure_ascii=False)}"}
            ],
            temperature=0.7
        )

        content = response.choices[0].message.content
        parsed = json.loads(content)

        return CoachingResponse(
            summary=parsed.get("summary", ""),
            coaching_advice=parsed.get("coaching_advice", ""),
            recommended_routine=[RecommendedRoutineItem(**item) for item in parsed.get("recommended_routine", [])],
            generated_at=datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        )
    except Exception as e:
        # API 오류 발생 시 스마트 더미로 폴백
        fallback = _generate_smart_dummy_coaching(request)
        fallback.summary += f" (OpenAI API 호출 에러로 더미 엔진 적용됨: {str(e)})"
        return fallback
