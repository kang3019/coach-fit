import os
import json
from datetime import datetime
from typing import List
from app.models.schemas import CoachingRequest, CoachingResponse, RecommendedRoutineItem

def generate_coaching_advice(request: CoachingRequest) -> CoachingResponse:
    """
    최근 운동 기록 + 신체 스펙 + 목표를 분석하여 AI 코칭 조언과
    오늘의 맞춤 추천 루틴을 생성합니다.

    AI_PROVIDER 환경변수로 공급자 선택:
    - "groq"    → Groq Llama 3.3 70B (완전 무료, 분당 30회, 카드 등록 불필요)
    - "gemini"  → Google Gemini (gemini-3.8-flash, 결제 설정 필요)
    - "claude"  → Anthropic Claude (claude-sonnet-5-5, $5 무료 크레딧)
    - "openai"  → OpenAI gpt-4o-mini
    - "dummy"   → 규칙 기반 스마트 더미 (키 없이도 동작)

    API 키가 없거나 호출 실패 시 자동으로 더미 폴백.
    """
    ai_provider = os.getenv("AI_PROVIDER", "dummy").lower()

    if ai_provider == "groq":
        groq_key = os.getenv("GROQ_API_KEY")
        if groq_key:
            # Groq Llama 3.3 70B — 완전 무료 (카드 등록 불필요).
            return _call_groq_coaching(request, groq_key)

    if ai_provider == "gemini":
        gemini_key = os.getenv("GEMINI_API_KEY")
        if gemini_key:
            return _call_gemini_coaching(request, gemini_key)

    if ai_provider == "claude":
        anthropic_key = os.getenv("ANTHROPIC_API_KEY")
        if anthropic_key:
            # Claude Sonnet 5.5 — 유료, 품질 최상.
            return _call_claude_coaching(request, anthropic_key)

    if ai_provider == "openai":
        openai_key = os.getenv("OPENAI_API_KEY")
        if openai_key:
            return _call_openai_coaching(request, openai_key)

    return _generate_smart_dummy_coaching(request)


def _generate_smart_dummy_coaching(request: CoachingRequest) -> CoachingResponse:
    workouts = request.recent_workouts
    count = len(workouts)
    profile = request.user_profile or {}

    weight = profile.get("weight_kg")
    muscle = profile.get("muscle_kg")
    body_fat = profile.get("body_fat_percent")
    height = profile.get("height_cm")

    spec_parts = []
    if height:
        spec_parts.append(f"{height:.0f}cm")
    if weight:
        spec_parts.append(f"{weight:.1f}kg")
    if muscle:
        spec_parts.append(f"골격근량 {muscle:.1f}kg")
    if body_fat:
        spec_parts.append(f"체지방률 {body_fat:.1f}%")
    spec_summary = f" [신체 스펙: {', '.join(spec_parts)}]" if spec_parts else ""

    if count == 0:
        summary = f"최근 운동 기록이 없습니다.{spec_summary} 새로운 시작을 위해 기초 전신 루틴을 권장합니다."
        advice = (
            f"회원님의 목표인 '{request.user_goal}' 달성을 위해 무리한 중량보다 정확한 가동 범위와 자세 정렬에 집중해주세요. "
            "체중과 골격근량 밸런스를 고려하여 초반에는 기초 다관절 운동으로 신경계를 활성화하는 것이 효과적입니다."
        )
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
            f"최근 {count}개 세션(총 {total_sets}세트, 누적 볼륨 약 {int(total_volume):,}kg)과 "
            f"신체 스펙{spec_summary}을 정밀 분석했습니다. (최근 운동: {', '.join(recent_names[:3])})"
        )

        advice_body = ""
        if weight and weight > 0:
            rel_strength = total_volume / (weight * max(count, 1))
            advice_body = f"체중({weight:.1f}kg) 대비 세션당 평균 볼륨 지수는 {int(rel_strength):,}kg으로 양호한 근력 수준입니다. "

        if "체지방" in (request.user_goal or ""):
            advice = (
                f"{advice_body}목표인 '{request.user_goal}'에 맞추어 대근육 복합 운동 위주로 심박수를 유지하고, "
                "세트 간 휴식 시간을 60~75초로 타이트하게 통제하여 칼로리 소모와 심폐 지구력을 극대화하는 루틴을 권장합니다."
            )
        elif "근력" in (request.user_goal or ""):
            advice = (
                f"{advice_body}목표인 '{request.user_goal}'에 맞추어 점진적 과부하(Progressive Overload)를 안전하게 유도할 수 있도록 "
                "신경계 피로를 관리하며 충분한 휴식(90~120초)과 함께 고중량 5~8회 반복 중심의 후면 사슬 강화 루틴을 추천드립니다."
            )
        else:
            advice = (
                f"{advice_body}목표인 '{request.user_goal}'에 맞추어 점진적 과부하를 적용하기에 아주 적절한 페이스입니다. "
                "최근 상체 밀기 및 하체 운동의 빈도를 감안하여, 오늘은 등(풀 계열)과 후면 사슬을 보강하여 "
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


def _call_groq_coaching(request: CoachingRequest, api_key: str) -> CoachingResponse:
    """
    Groq 연동 (openai/gpt-oss-120b).

    - 완전 무료 (카드 등록 X), 분당 30회 / 일일 거의 무제한
    - OpenAI 호환 API, response_format=json_object 지원
    - 모델: openai/gpt-oss-120b (131K context, 품질 최상)
    - 호출 실패 시 스마트 더미로 폴백
    """
    try:
        from groq import Groq
        client = Groq(api_key=api_key)

        prompt_data = {
            "user_goal": request.user_goal,
            "user_profile": request.user_profile,
            "workouts": [w.model_dump(mode="json") for w in request.recent_workouts],
        }

        system_prompt = """당신은 전문 피트니스 트레이너이자 재활 코치입니다.
사용자의 신체 스펙(키, 체중, 골격근량, 체지방률, 경력), 운동 목표, 최근 운동 기록을 종합적으로 분석하여
개인 맞춤형 코칭 피드백과 오늘 수행할 추천 운동 루틴을 작성합니다.

반드시 아래 JSON 스키마만 포함하는 응답을 작성하세요. 마크다운 코드 블록이나 설명 문구 없이 순수 JSON 만 반환합니다.

{
  "summary": "운동 및 신체 상태 요약 문자열",
  "coaching_advice": "코칭 조언 및 운동 생리학적 피드백 문자열",
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

recommended_routine 은 3~5개 종목으로 구성하고, 각 종목의 tip 은 1~2문장으로 구체적인 자세 교정 포인트를 포함합니다."""

        response = client.chat.completions.create(
            model="openai/gpt-oss-120b",
            response_format={"type": "json_object"},
            messages=[
                {"role": "system", "content": system_prompt},
                {
                    "role": "user",
                    "content": (
                        f"기록 및 프로필 데이터 (JSON): "
                        f"{json.dumps(prompt_data, ensure_ascii=False)}\n\n"
                        "위 데이터를 분석하여 지정된 JSON 스키마로 코칭 결과를 반환하세요."
                    ),
                },
            ],
            temperature=0.7,
        )

        content = response.choices[0].message.content or ""
        if not content.strip():
            raise ValueError("Groq 응답이 비어 있습니다.")

        parsed = json.loads(content)

        return CoachingResponse(
            summary=parsed.get("summary", ""),
            coaching_advice=parsed.get("coaching_advice", ""),
            recommended_routine=[
                RecommendedRoutineItem(**item)
                for item in parsed.get("recommended_routine", [])
            ],
            generated_at=datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
        )
    except Exception as e:
        # API 오류 발생 시 스마트 더미로 폴백
        fallback = _generate_smart_dummy_coaching(request)
        fallback.summary += f" (Groq API 호출 에러로 더미 엔진 적용됨: {str(e)})"
        return fallback


def _call_openai_coaching(request: CoachingRequest, api_key: str) -> CoachingResponse:
    """
    OpenAI ChatCompletion (gpt-4o-mini) 연동
    """
    try:
        from openai import OpenAI
        client = OpenAI(api_key=api_key)

        prompt_data = {
            "user_goal": request.user_goal,
            "user_profile": request.user_profile,
            "workouts": [w.model_dump(mode="json") for w in request.recent_workouts]
        }

        system_prompt = """
        당신은 전문 피트니스 트레이너이자 재활 코치입니다.
        사용자의 신체 스펙(키, 체중, 골격근량, 체지방률, 경력), 운동 목표, 그리고 최근 운동 기록을 종합적으로 분석하여
        개인 맞춤형 코칭 피드백과 오늘 수행할 추천 운동 루틴을 JSON 규격으로 작성하세요.
        응답은 다음 JSON 스키마를 만족해야 합니다:
        {
            "summary": "운동 및 신체 상태 요약 문자열",
            "coaching_advice": "코칭 조언 및 운동 생리학적 피드백 문자열",
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
                {"role": "user", "content": f"기록 및 프로필 데이터: {json.dumps(prompt_data, ensure_ascii=False)}"}
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


def _call_claude_coaching(request: CoachingRequest, api_key: str) -> CoachingResponse:
    """
    Anthropic Claude 연동 (claude-sonnet-5-5 + adaptive thinking + server-side fallback).

    - 모델: Claude Sonnet 5.5 — 가격은 Opus 의 1/2 ($2 입력 / $10 출력 per 1M tokens),
      일반 코딩/추천 작업은 Opus 와 거의 동급 품질. 학생 사이드 프로젝트에 비용 효율적.
    - OpenAI 버전과 동일한 JSON 스키마 응답을 받아 CoachingResponse 로 매핑.
    - 안전장치 2단: (1) 서버사이드 refusal fallback (안전필터 거부 시 다른 모델로 자동 전환),
                   (2) 호출 자체 실패 시 스마트 더미로 폴백.
    """
    try:
        from anthropic import Anthropic
        client = Anthropic(api_key=api_key)

        prompt_data = {
            "user_goal": request.user_goal,
            "user_profile": request.user_profile,
            "workouts": [w.model_dump(mode="json") for w in request.recent_workouts]
        }

        system_prompt = """당신은 전문 피트니스 트레이너이자 재활 코치입니다.
사용자의 신체 스펙(키, 체중, 골격근량, 체지방률, 경력), 운동 목표, 최근 운동 기록을 종합적으로 분석하여
개인 맞춤형 코칭 피드백과 오늘 수행할 추천 운동 루틴을 작성합니다.

**반드시 아래 JSON 스키마만 포함하는 응답을 작성하세요. 마크다운 코드 블록이나 설명 문구 없이 순수 JSON 만 반환합니다.**

{
  "summary": "운동 및 신체 상태 요약 문자열",
  "coaching_advice": "코칭 조언 및 운동 생리학적 피드백 문자열",
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

recommended_routine 은 3~5개 종목으로 구성하고, 각 종목의 tip 은 1~2문장으로 구체적인 자세 교정 포인트를 포함합니다."""

        user_message = (
            f"기록 및 프로필 데이터 (JSON): {json.dumps(prompt_data, ensure_ascii=False)}\n\n"
            "위 데이터를 분석하여 지정된 JSON 스키마로 코칭 결과를 반환하세요."
        )

        # streaming + get_final_message 로 긴 응답/타임아웃 안전 처리.
        # Sonnet 5.5 는 server-side fallback(refusal 발생 시 자동 다른 모델 호출) 기본 활성화 권장.
        with client.beta.messages.stream(
            model="claude-sonnet-5-5",
            max_tokens=16000,
            thinking={"type": "adaptive"},
            system=system_prompt,
            messages=[{"role": "user", "content": user_message}],
            betas=["server-side-fallback-2026-07-01"],
            fallbacks="default",
        ) as stream:
            response = stream.get_final_message()

        # 텍스트 블록만 모아서 JSON 파싱
        text_content = ""
        for block in response.content:
            if getattr(block, "type", None) == "text":
                text_content += block.text

        # 모델이 코드 블록을 둘러쌀 수도 있으니 가장 바깥 { ... } 구간만 추출
        start = text_content.find("{")
        end = text_content.rfind("}")
        if start == -1 or end == -1 or end <= start:
            raise ValueError("Claude 응답에서 JSON 객체를 찾지 못했습니다.")

        parsed = json.loads(text_content[start:end + 1])

        return CoachingResponse(
            summary=parsed.get("summary", ""),
            coaching_advice=parsed.get("coaching_advice", ""),
            recommended_routine=[
                RecommendedRoutineItem(**item)
                for item in parsed.get("recommended_routine", [])
            ],
            generated_at=datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        )
    except Exception as e:
        # API 오류 발생 시 스마트 더미로 폴백
        fallback = _generate_smart_dummy_coaching(request)
        fallback.summary += f" (Claude API 호출 에러로 더미 엔진 적용됨: {str(e)})"
        return fallback


def _call_gemini_coaching(request: CoachingRequest, api_key: str) -> CoachingResponse:
    """
    Google Gemini 연동 (gemini-2.5-flash).

    - 모델: Gemini 2.5 Flash — 무료 티어 하루 1,500회 / 분당 15회.
      데모 개발 패턴에는 추가 비용 $0 로 커버 가능.
    - response_mime_type="application/json" 으로 구조화 JSON 응답 강제.
    - 호출 실패 시 스마트 더미로 폴백.
    """
    try:
        import google.generativeai as genai

        genai.configure(api_key=api_key)

        prompt_data = {
            "user_goal": request.user_goal,
            "user_profile": request.user_profile,
            "workouts": [w.model_dump(mode="json") for w in request.recent_workouts],
        }

        system_prompt = """당신은 전문 피트니스 트레이너이자 재활 코치입니다.
사용자의 신체 스펙(키, 체중, 골격근량, 체지방률, 경력), 운동 목표, 최근 운동 기록을 종합적으로 분석하여
개인 맞춤형 코칭 피드백과 오늘 수행할 추천 운동 루틴을 작성합니다.

반드시 아래 JSON 스키마만 포함하는 응답을 작성하세요:
{
  "summary": "운동 및 신체 상태 요약 문자열",
  "coaching_advice": "코칭 조언 및 운동 생리학적 피드백 문자열",
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

recommended_routine 은 3~5개 종목으로 구성하고, 각 종목의 tip 은 1~2문장으로 구체적인 자세 교정 포인트를 포함합니다."""

        user_message = (
            f"기록 및 프로필 데이터 (JSON): {json.dumps(prompt_data, ensure_ascii=False)}\n\n"
            "위 데이터를 분석하여 지정된 JSON 스키마로 코칭 결과를 반환하세요."
        )

        model = genai.GenerativeModel(
            model_name="gemini-2.5-flash",
            system_instruction=system_prompt,
            generation_config={
                "response_mime_type": "application/json",
                "temperature": 0.7,
            },
        )

        response = model.generate_content(user_message)
        content = response.text or ""

        if not content.strip():
            raise ValueError("Gemini 응답이 비어 있습니다.")

        parsed = json.loads(content)

        return CoachingResponse(
            summary=parsed.get("summary", ""),
            coaching_advice=parsed.get("coaching_advice", ""),
            recommended_routine=[
                RecommendedRoutineItem(**item)
                for item in parsed.get("recommended_routine", [])
            ],
            generated_at=datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
        )
    except Exception as e:
        # API 오류 발생 시 스마트 더미로 폴백
        fallback = _generate_smart_dummy_coaching(request)
        fallback.summary += f" (Gemini API 호출 에러로 더미 엔진 적용됨: {str(e)})"
        return fallback

