import os
import json
import logging
from datetime import datetime
from typing import List, Optional, Tuple
from app.models.schemas import (
    CoachingRequest,
    CoachingResponse,
    RecommendedRoutineItem,
    AiChatRequest,
    AiChatResponse,
    ChatMessageItem,
)

logger = logging.getLogger(__name__)


def _fallback_coaching(
    request: CoachingRequest,
    provider: str,
    error: Exception,
    annotate_summary: bool = True,
) -> CoachingResponse:
    """LLM 호출 실패 시 원인을 서버 로그에 남기고 스마트 더미 결과로 대체."""
    logger.warning("AI 코칭 %s 호출 실패, 더미 엔진으로 대체: %s", provider, error)
    fallback = _generate_smart_dummy_coaching(request)
    if annotate_summary:
        fallback.summary += f" ({provider} API 호출 에러로 더미 엔진 적용됨: {str(error)})"
    fallback.is_fallback = True
    return fallback


def _safe_routine_item(raw: dict) -> Optional[RecommendedRoutineItem]:
    """LLM 응답의 루틴 아이템을 안전하게 RecommendedRoutineItem 으로 변환.

    LLM 이 reps/sets 를 가끔 null 또는 문자열로 반환하는 케이스를 흡수.
    - exercise_name 없거나 공백: 아이템 통째로 스킵 (None 반환)
    - sets/reps 가 null 이거나 변환 불가: 안전한 기본값(3세트/10회) 적용
    """
    if not isinstance(raw, dict):
        return None
    name = (raw.get("exercise_name") or "").strip()
    if not name:
        return None

    def _as_int(value, default: int) -> int:
        if value is None:
            return default
        try:
            return int(value)
        except (TypeError, ValueError):
            return default

    return RecommendedRoutineItem(
        exercise_name=name,
        sets=_as_int(raw.get("sets"), 3),
        reps=_as_int(raw.get("reps"), 10),
        focus=(raw.get("focus") or "").strip() or "타겟 부위",
        tip=(raw.get("tip") or "").strip() or "자세를 정확히 유지하세요.",
    )


def _safe_routine_list(raw_list) -> List[RecommendedRoutineItem]:
    """루틴 리스트 전체를 안전 변환 — 유효하지 않은 아이템은 자동 제외."""
    if not isinstance(raw_list, list):
        return []
    items: List[RecommendedRoutineItem] = []
    for raw in raw_list:
        item = _safe_routine_item(raw)
        if item is not None:
            items.append(item)
    return items

def generate_coaching_advice(request: CoachingRequest) -> CoachingResponse:
    """
    최근 운동 기록 + 신체 스펙 + 목표를 분석하여 AI 코칭 조언과
    오늘의 맞춤 추천 루틴을 생성합니다.

    AI_PROVIDER 환경변수로 공급자 선택:
    - "bedrock" → AWS Bedrock (Claude 3.5 Sonnet / Nova, 교수님 권고 표준)
    - "groq"    → Groq Llama 3.3 70B (완전 무료, 분당 30회, 카드 등록 불필요)
    - "gemini"  → Google Gemini (gemini-3.8-flash, 결제 설정 필요)
    - "claude"  → Anthropic Claude (claude-sonnet-5-5, $5 무료 크레딧)
    - "openai"  → OpenAI gpt-4o-mini
    - "dummy"   → 규칙 기반 스마트 더미 (키 없이도 동작)

    API 키가 없거나 호출 실패 시 자동으로 더미 폴백.
    """
    ai_provider = os.getenv("AI_PROVIDER", "dummy").lower()

    # Bedrock LLM 게이트웨이 (학교/기관 5만원 한도 제어 OpenAI 호환 API)
    gateway_key = os.getenv("BEDROCK_GATEWAY_API_KEY")
    gateway_url = os.getenv("BEDROCK_GATEWAY_BASE_URL")
    # 형식이 고정된 JSON 코칭은 저렴한 Haiku 로 충분, 채팅만 BEDROCK_GATEWAY_MODEL(Sonnet) 사용
    gateway_model = os.getenv("BEDROCK_GATEWAY_COACHING_MODEL", "bedrock-haiku")

    if (ai_provider in ("bedrock-gateway", "bedrock")) and gateway_key and gateway_url:
        return _call_bedrock_gateway_coaching(
            request,
            api_key=gateway_key,
            base_url=gateway_url,
            model_name=gateway_model,
        )

    if ai_provider == "bedrock":
        return _call_bedrock_coaching(request)

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
        summary = f"최근 저장된 운동 기록이 없어 회원의 신체 지표{spec_summary}를 기반으로 초기 진단을 진행했습니다. 기초 근신경계 활성화 및 전신 자세 정렬을 위한 스타터 루틴을 구성했습니다."
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
            f"최근 {count}개 세션 동안 총 {total_sets}세트(누적 볼륨 약 {int(total_volume):,}kg)를 꾸준히 완주하셨습니다. "
            f"신체 지표{spec_summary}와 최근 선호 종목({', '.join(recent_names[:3]) if recent_names else '주요 복합 운동'})의 근육 부하를 고려할 때, "
            "타깃 부위의 충분한 회복과 안전한 점진적 과부하를 적용하기에 아주 좋은 컨디션입니다."
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
            recommended_routine=_safe_routine_list(parsed.get("recommended_routine")),
            generated_at=datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
        )
    except Exception as e:
        return _fallback_coaching(request, "Groq", e)


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
            recommended_routine=_safe_routine_list(parsed.get("recommended_routine")),
            generated_at=datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        )
    except Exception as e:
        return _fallback_coaching(request, "OpenAI", e)


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
            recommended_routine=_safe_routine_list(parsed.get("recommended_routine")),
            generated_at=datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        )
    except Exception as e:
        return _fallback_coaching(request, "Claude", e)


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
            model_name="gemini-3.8-flash",
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
            recommended_routine=_safe_routine_list(parsed.get("recommended_routine")),
            generated_at=datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
        )
    except Exception as e:
        return _fallback_coaching(request, "Gemini", e)


def _call_bedrock_coaching(request: CoachingRequest) -> CoachingResponse:
    """
    AWS Bedrock 연동 (교수님 권고 AWS 정석 아키텍처).
    - AWS SDK: boto3 bedrock-runtime converse API 사용
    - 자격 증명: EC2 IAM Role(인스턴스 프로파일) 우선 자동 감지,
      로컬 개발 시 AWS_ACCESS_KEY_ID / AWS_SECRET_ACCESS_KEY 환경변수 지원
    - 기본 모델: Anthropic Claude 3.5 Sonnet (BEDROCK_MODEL_ID)
    - 리전: AWS_REGION (기본: us-east-1)
    - 호출 실패 시 스마트 더미로 자동 폴백
    """
    try:
        import boto3

        region_name = os.getenv("AWS_REGION", "ap-northeast-2")
        model_id = os.getenv("BEDROCK_MODEL_ID", "anthropic.claude-3-5-sonnet-20240620-v1:0")

        # EC2 IAM Role 우선, 환경변수에 명시된 경우만 직접 주입
        boto3_kwargs = {"region_name": region_name}
        access_key = os.getenv("AWS_ACCESS_KEY_ID")
        secret_key = os.getenv("AWS_SECRET_ACCESS_KEY")
        if access_key and secret_key:
            boto3_kwargs["aws_access_key_id"] = access_key
            boto3_kwargs["aws_secret_access_key"] = secret_key
            session_token = os.getenv("AWS_SESSION_TOKEN")
            if session_token:
                boto3_kwargs["aws_session_token"] = session_token

        client = boto3.client(service_name="bedrock-runtime", **boto3_kwargs)

        prompt_data = {
            "user_goal": request.user_goal,
            "user_profile": request.user_profile,
            "workouts": [w.model_dump(mode="json") for w in request.recent_workouts],
        }

        system_prompt = """당신은 전문 피트니스 트레이너이자 재활 코치입니다.
사용자의 신체 스펙(키, 체중, 골격근량, 체지방률, 경력), 운동 목표, 최근 운동 기록을 종합적으로 분석하여
개인 맞춤형 코칭 피드백과 오늘 수행할 추천 운동 루틴을 작성합니다.

반드시 아래 JSON 스키마만 포함하는 유효한 JSON 형식으로 응답하세요:
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

recommended_routine 은 3~5개 종목으로 구성하고, 각 종목의 tip 은 1~2문장으로 구체적인 자세 교정 포인트를 포함합니다.
응답에는 마크다운 백틱(```json)이나 다른 설명 없이 오직 JSON 텍스트만 출력하세요."""

        user_message = (
            f"기록 및 프로필 데이터 (JSON): {json.dumps(prompt_data, ensure_ascii=False)}\n\n"
            "위 데이터를 분석하여 지정된 JSON 스키마로 코칭 결과를 반환하세요."
        )

        response = client.converse(
            modelId=model_id,
            messages=[
                {
                    "role": "user",
                    "content": [{"text": user_message}]
                }
            ],
            system=[{"text": system_prompt}],
            inferenceConfig={
                "temperature": 0.7,
                "maxTokens": 2048,
            }
        )

        output_message = response.get("output", {}).get("message", {})
        content_blocks = output_message.get("content", [])
        text_content = "".join(b.get("text", "") for b in content_blocks if "text" in b)

        start = text_content.find("{")
        end = text_content.rfind("}")
        if start == -1 or end == -1 or end <= start:
            raise ValueError("Bedrock 응답에서 JSON 객체를 찾지 못했습니다.")

        parsed = json.loads(text_content[start:end + 1])

        return CoachingResponse(
            summary=parsed.get("summary", ""),
            coaching_advice=parsed.get("coaching_advice", ""),
            recommended_routine=_safe_routine_list(parsed.get("recommended_routine")),
            generated_at=datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
        )
    except Exception as e:
        return _fallback_coaching(request, "AWS Bedrock", e)


def _call_bedrock_gateway_coaching(
    request: CoachingRequest,
    api_key: str,
    base_url: str,
    model_name: str = "bedrock-sonnet",
) -> CoachingResponse:
    """
    Bedrock LLM 게이트웨이 연동 (학교/기관 5만원 한도 제어 OpenAI 호환 API).
    - base_url: 게이트웨이 엔드포인트 URL
    - api_key: 게이트웨이 API 키
    - model: bedrock-sonnet (기본) / bedrock-haiku / bedrock-gpt-5.6-luna
    - OpenAI 호환 API (chat.completions.create) 로 호출
    - 실패 시 스마트 더미 엔진으로 자동 폴백
    """
    try:
        from openai import OpenAI

        client = OpenAI(api_key=api_key, base_url=base_url)

        prompt_data = {
            "user_goal": request.user_goal,
            "user_profile": request.user_profile,
            "workouts": [w.model_dump(mode="json") for w in request.recent_workouts],
        }

        system_prompt = """당신은 전문 피트니스 트레이너이자 재활 코치입니다.
사용자의 신체 스펙(키, 체중, 골격근량, 체지방률, 경력), 운동 목표, 최근 운동 기록을 종합적으로 분석하여
개인 맞춤형 코칭 피드백과 오늘 수행할 추천 운동 루틴을 작성합니다.

반드시 아래 JSON 스키마만 포함하는 유효한 JSON 형식으로 응답하세요:
{
  "summary": "운동 기록과 신체 상태를 바탕으로 한 현재 피트니스 상태 및 회복도 분석 요약 (전문 코치의 친절한 1~2문장)",
  "coaching_advice": "생체역학적 부하 분석, 점진적 과부하 방향, 부상 예방 팁을 포함한 코칭 조언 (2~3문장)",
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

recommended_routine 은 3~5개 종목으로 구성하고, 각 종목의 tip 은 1~2문장으로 구체적인 자세 교정 포인트를 포함합니다.
응답에는 마크다운 백틱(```json)이나 다른 설명 없이 오직 JSON 텍스트만 출력하세요."""

        user_message = (
            f"기록 및 프로필 데이터 (JSON): {json.dumps(prompt_data, ensure_ascii=False)}\n\n"
            "위 데이터를 분석하여 지정된 JSON 스키마로 코칭 결과를 반환하세요."
        )

        response = client.chat.completions.create(
            model=model_name,
            response_format={"type": "json_object"},
            messages=[
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": user_message},
            ],
            temperature=0.7,
        )

        content = response.choices[0].message.content or ""
        start = content.find("{")
        end = content.rfind("}")
        if start == -1 or end == -1 or end <= start:
            raise ValueError("Bedrock 게이트웨이 응답에서 JSON 객체를 찾지 못했습니다.")

        parsed = json.loads(content[start:end + 1])

        return CoachingResponse(
            summary=parsed.get("summary", ""),
            coaching_advice=parsed.get("coaching_advice", ""),
            recommended_routine=_safe_routine_list(parsed.get("recommended_routine")),
            generated_at=datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
        )
    except Exception as e:
        # 게이트웨이 에러 문구에는 키 일부가 포함될 수 있어 사용자 화면에는 노출하지 않음
        return _fallback_coaching(request, "Bedrock 게이트웨이", e, annotate_summary=False)


# ==========================================
# 1:1 실시간 AI 코칭 채팅 (Chat) 엔진
# ==========================================

def _extract_suggested_questions(text: str) -> Tuple[str, List[str]]:
    """답변 텍스트에서 [추천 질문] 블록을 파싱하여 본문과 분리."""
    markers = ["[추천 질문]", "추천 질문:", "[추천질문]"]
    marker_pos = -1
    for m in markers:
        p = text.rfind(m)
        if p != -1:
            marker_pos = p
            break

    if marker_pos == -1:
        return text.strip(), []

    main_text = text[:marker_pos].strip()
    questions_block = text[marker_pos:].split("\n")
    suggestions: List[str] = []

    for line in questions_block:
        line = line.strip()
        if not line or any(m in line for m in markers):
            continue
        cleaned = line.lstrip("-*•0123456789. \t").strip()
        if cleaned:
            suggestions.append(cleaned)

    return main_text, suggestions[:3]


def _generate_default_suggestions(user_message: str) -> List[str]:
    """사용자 메시지 키워드에 따른 기본 후속 질문 3선."""
    msg = user_message.lower()
    if any(k in msg for k in ["루틴", "추천", "프로그램"]):
        return [
            "오늘 바로 할 수 있는 30분 루틴 알려줘",
            "세트 간 휴식 시간은 몇 초가 좋아?",
            "점진적 과부하는 어떻게 적용해?"
        ]
    if any(k in msg for k in ["어깨", "통증", "아파", "부상", "허리", "무릎"]):
        return [
            "어깨 충돌 증후군 예방 스트레칭 알려줘",
            "벤치프레스 할 때 손목 통증 줄이는 법",
            "허리 부담 없는 하체 운동 추천해줘"
        ]
    if any(k in msg for k in ["식단", "단백질", "칼로리", "다이어트", "살"]):
        return [
            "내 체중에 맞는 하루 단백질 권장량은?",
            "운동 직후 단백질 섭취 타이밍",
            "가성비 좋은 단백질 식단 추천해줘"
        ]
    return [
        "오늘 추천 운동 루틴 알려줘",
        "벤치프레스 자세 팁 가르쳐줘",
        "근성장에 최적화된 식단 알려줘"
    ]


def _generate_smart_dummy_chat(
    request: AiChatRequest,
    user_context: Optional[dict] = None
) -> AiChatResponse:
    """Bedrock Gateway 키가 없거나 일시 장애 시의 지능형 피트니스 코치 응답."""
    msg = request.message.strip().lower()
    user_goal = request.user_goal or "근비대 및 전신 근력 증진"

    if any(k in msg for k in ["안녕", "반가", "하이", "처음"]):
        reply = (
            "안녕하세요! 회원님의 1:1 전담 AI 피트니스 코치입니다. 💪\n\n"
            f"현재 설정하신 목표인 **'{user_goal}'**에 맞추어 운동 루틴 설계, 자세 교정, 점진적 과부하 주기화, "
            "그리고 영양 식단까지 무엇이든 물어보세요! 오늘 어떤 부위 운동을 계획 중이신가요?"
        )
    elif any(k in msg for k in ["어깨", "통증", "아파", "찝히", "부상"]):
        reply = (
            "웨이트 트레이닝 시 관절 통증은 즉시 점검해야 할 중요한 신호입니다! ⚠️\n\n"
            "**1. 견갑골 후인하강 점검**: 프레스 동작 시 견갑골(날개뼈)이 거상(으쓱)되면 회전근개와 삼각근이 찝히기 쉽습니다. 가슴을 들고 날개뼈를 바닥 쪽으로 단단히 고정하세요.\n"
            "**2. 팔꿈치 각도**: 바벨이나 덤벨을 내릴 때 팔꿈치가 어깨선과 평행(90도)이 되면 어깨 충돌이 일어납니다. 몸통과 60~75도 각도를 유지하세요.\n"
            "**3. 회전근개 웜업**: 본 세트 전 케이블 페이스 풀이나 Y-레이즈로 후면 근육을 예열하는 것을 강력히 추천합니다."
        )
    elif any(k in msg for k in ["루틴", "오늘 운동", "추천", "프로그램"]):
        reply = (
            f"회원님의 목표인 **'{user_goal}'**을 극대화할 수 있는 추천 3분할 루틴 중 오늘 추천 세션입니다! 🎯\n\n"
            "**[대흉근 & 삼두 집중 루틴]**\n"
            "1. **바벨 벤치프레스**: 4세트 × 8~10회 (메인 복합 중량 운동)\n"
            "2. **인클라인 덤벨 프레스**: 4세트 × 10~12회 (상부 가슴 타깃)\n"
            "3. **케이블 체스트 플라이**: 3세트 × 15회 (지속 긴장 고립)\n"
            "4. **로프 트라이셉스 익스텐션**: 3세트 × 12회 (삼두근 마무리)\n\n"
            "💡 세트 간 휴식은 다관절 운동은 90~120초, 고립 운동은 60초를 유지하세요!"
        )
    elif any(k in msg for k in ["식단", "단백질", "칼로리", "닭가슴살", "보충제"]):
        reply = (
            "근성장과 체지방 관리를 위한 영양 섭취 황금 원칙입니다! 🥗\n\n"
            "**1. 하루 단백질 섭취량**: 체중 1kg당 1.6g ~ 2.0g을 권장합니다. (체중 70kg 기준 약 120~140g)\n"
            "**2. 끼니별 분배**: 한 번에 몰아먹기보다 3~4끼로 나누어 끼니당 25~35g씩 섭취하는 것이 근단백질 합성(MPS)을 종일 높게 유지하는 비결입니다.\n"
            "**3. 수분 섭취**: 크레아틴 합성과 근육 펌핑을 위해 하루 최소 2~2.5L의 물을 충분히 마셔주세요."
        )
    elif any(k in msg for k in ["스쿼트", "하체", "데드리프트"]):
        reply = (
            "하체 및 후면 사슬은 신체 전체 근육량의 60% 이상을 차지하는 핵심 부위입니다! 🦵\n\n"
            "**스쿼트 핵심 큐**: 발바닥 3점(엄지발가락, 새끼발가락, 뒤꿈치)으로 지면을 강하게 지지하고, "
            "복압(발살바 호흡)을 채워 척추를 중립으로 보호한 상태에서 고관절과 무릎을 동시에 접어 내려가세요.\n"
            "무릎이 안쪽으로 모이지 않도록 바깥쪽으로 밀어내는 느낌(엉덩이 외회전)을 유지하는 것이 핵심입니다!"
        )
    else:
        reply = (
            f"'{request.message}'에 대해 전문 코칭 관점에서 답변드립니다. 💡\n\n"
            "효과적인 피트니스는 **[정확한 자세 정렬 ➔ 점진적 과부하 ➔ 충분한 단백질 영양 ➔ 양질의 수면]** 4가지 축이 조화를 이룰 때 가장 빠르고 부상 없이 완성됩니다.\n\n"
            "추가로 세부적인 운동 종목이나 현재 겪고 계신 정체기, 식단에 대해 구체적으로 말씀해 주시면 회원님의 스펙에 맞춤 설계해 드릴게요!"
        )

    return AiChatResponse(
        reply=reply,
        suggested_questions=_generate_default_suggestions(request.message),
        timestamp=datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    )


def chat_with_ai_coach(
    request: AiChatRequest,
    user_context: Optional[dict] = None
) -> AiChatResponse:
    """
    1:1 실시간 AI 코치 대화 엔진.
    AWS Bedrock Gateway (Claude 3.5 Sonnet)를 우선 호출하며,
    키 부재 또는 통신 불가 시 지능형 규칙/키워드 기반 피트니스 챗봇으로 안전하게 폴백합니다.
    """
    gateway_key = os.getenv("BEDROCK_GATEWAY_API_KEY")
    gateway_url = os.getenv("BEDROCK_GATEWAY_BASE_URL")
    gateway_model = os.getenv("BEDROCK_GATEWAY_MODEL", "bedrock-sonnet")

    if gateway_key and gateway_url:
        try:
            from openai import OpenAI
            client = OpenAI(api_key=gateway_key, base_url=gateway_url)

            context_str = ""
            if user_context:
                h = user_context.get("height_cm")
                w = user_context.get("weight_kg")
                m = user_context.get("muscle_kg")
                f = user_context.get("body_fat_percent")
                exp = user_context.get("experience")
                context_str = (
                    f"[회원 신체 정보: 키 {h or '-'}cm, 체중 {w or '-'}kg, "
                    f"골격근량 {m or '-'}kg, 체지방률 {f or '-'}%, 경력: {exp or '-'}, 목표: {request.user_goal}]\n"
                )

            system_instruction = (
                "당신은 피트니스 플랫폼 CoachFit(코치핏)의 수석 1:1 전담 AI 코치입니다.\n"
                "사용자의 웨이트 트레이닝 자세 교정, 분할 루틴 설계, 점진적 과부하 원리, 스포츠 영양(단백질/식단), "
                "스트레칭 및 부상 방지에 대해 전문적이고 명쾌하며 친절하게 답변합니다.\n"
                f"{context_str}\n"
                "답변 가이드라인:\n"
                "1. 핵심을 명확히 짚고, 모바일에서 편하게 읽을 수 있도록 이모지와 단락을 깔끔하게 구성하세요.\n"
                "2. 너무 장황하지 않게 2~4개 단락 내외로 핵심 노하우를 전달하세요.\n"
                "3. 답변의 맨 마지막 줄에 사용자가 바로 이어 물어볼 만한 후속 질문 2~3개를 아래 형식으로 꼭 붙여주세요:\n"
                "[추천 질문]\n"
                "- 추천 질문 1\n"
                "- 추천 질문 2\n"
                "- 추천 질문 3"
            )

            messages = [{"role": "system", "content": system_instruction}]
            for h in request.history[-8:]:
                role = "assistant" if h.role in ("assistant", "ai") else "user"
                messages.append({"role": role, "content": h.content})

            messages.append({"role": "user", "content": request.message})

            response = client.chat.completions.create(
                model=gateway_model,
                messages=messages,
                temperature=0.7,
                max_tokens=1000,
            )

            raw_reply = response.choices[0].message.content or ""
            reply, suggestions = _extract_suggested_questions(raw_reply)
            if not suggestions:
                suggestions = _generate_default_suggestions(request.message)

            return AiChatResponse(
                reply=reply.strip(),
                suggested_questions=suggestions,
                timestamp=datetime.now().strftime("%Y-%m-%d %H:%M:%S")
            )
        except Exception as e:
            logger.warning("AI 채팅 Bedrock 게이트웨이 호출 실패, 더미 응답으로 대체: %s", e)

    return _generate_smart_dummy_chat(request, user_context)



