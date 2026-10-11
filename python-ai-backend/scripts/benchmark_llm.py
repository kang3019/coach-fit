#!/usr/bin/env python3
"""AI 코칭 공급자(LLM) 비교 벤치마크.

실제 서비스 코드(app.services.ai_coach.generate_coaching_advice)를 그대로 호출해
공급자별 응답 시간, 폴백 발생률, 응답 구조 품질을 같은 입력으로 비교한다.

사용법 (python-ai-backend 디렉터리에서):
    python scripts/benchmark_llm.py --list
    python scripts/benchmark_llm.py --targets dummy,groq,claude --runs 5
    python scripts/benchmark_llm.py --targets gateway:bedrock-sonnet,gateway:bedrock-haiku

API 키는 환경변수(.env 포함)로 읽는다. 키가 없는 대상은 건너뛰고 'skipped'로 표시한다.
측정하지 않는 것: 토큰 사용량/비용(기존 코드가 usage를 반환하지 않음), 조언의 질(수동 평가 필요).
"""
from __future__ import annotations

import argparse
import json
import os
import statistics
import sys
import time
from datetime import datetime
from pathlib import Path
from typing import Any, Dict, List, Optional

# 서비스 코드가 모든 공급자 실패 시 summary 뒤에 붙이는 문구 (ai_coach.py 의 except 블록)
FALLBACK_MARKER = "더미 엔진 적용됨"
DEFAULT_TIP = "자세를 정확히 유지하세요."
DEFAULT_FOCUS = "타겟 부위"

GATEWAY_ENV_VARS = ("BEDROCK_GATEWAY_API_KEY", "BEDROCK_GATEWAY_BASE_URL", "BEDROCK_GATEWAY_MODEL")

# 대상 이름 -> (AI_PROVIDER 값, 필수 환경변수)
PROVIDERS: Dict[str, Dict[str, Any]] = {
    "dummy": {"provider": "dummy", "required": []},
    "bedrock": {"provider": "bedrock", "required": []},  # EC2 IAM Role 또는 AWS_* 환경변수. 실패는 폴백으로 드러남
    "groq": {"provider": "groq", "required": ["GROQ_API_KEY"]},
    "gemini": {"provider": "gemini", "required": ["GEMINI_API_KEY"]},
    "claude": {"provider": "claude", "required": ["ANTHROPIC_API_KEY"]},
    "openai": {"provider": "openai", "required": ["OPENAI_API_KEY"]},
    # gateway:<모델명> 형태로 모델을 지정한다. 예) gateway:bedrock-sonnet
    "gateway": {
        "provider": "bedrock-gateway",
        "required": ["BEDROCK_GATEWAY_API_KEY", "BEDROCK_GATEWAY_BASE_URL"],
    },
}

SCENARIOS: List[Dict[str, Any]] = [
    {
        "name": "신규 사용자(기록 없음)",
        "goal": "근비대 및 전신 근력 증진",
        "profile": {"height_cm": 175, "weight_kg": 72.0, "muscle_kg": 32.0, "body_fat_percent": 18.0},
        "workouts": [],
    },
    {
        "name": "체지방 감량 목표",
        "goal": "체지방 감량",
        "profile": {"height_cm": 168, "weight_kg": 78.5, "muscle_kg": 30.2, "body_fat_percent": 29.0},
        "workouts": [
            {"exercise_name": "러닝머신", "sets": 1, "reps": 30, "weight": 0},
            {"exercise_name": "스쿼트", "sets": 4, "reps": 12, "weight": 50},
            {"exercise_name": "랫 풀 다운", "sets": 4, "reps": 12, "weight": 40},
        ],
    },
    {
        "name": "근력 증진 목표(고중량)",
        "goal": "근력 증진",
        "profile": {"height_cm": 181, "weight_kg": 84.0, "muscle_kg": 39.5, "body_fat_percent": 14.0},
        "workouts": [
            {"exercise_name": "벤치프레스", "sets": 5, "reps": 5, "weight": 90},
            {"exercise_name": "데드리프트", "sets": 3, "reps": 5, "weight": 140},
            {"exercise_name": "오버헤드 프레스", "sets": 4, "reps": 6, "weight": 50},
            {"exercise_name": "바벨 로우", "sets": 4, "reps": 8, "weight": 70},
        ],
    },
]


def is_fallback(summary: str) -> bool:
    return FALLBACK_MARKER in (summary or "")


def extract_error(summary: str, limit: int = 200) -> Optional[str]:
    """폴백 문구 뒤의 에러 메시지만 잘라 반환한다 (길이 제한)."""
    if not is_fallback(summary):
        return None
    idx = summary.find(FALLBACK_MARKER)
    return summary[idx:idx + limit]


def evaluate_response(summary: str, advice: str, routine: List[Dict[str, Any]], latency_s: float) -> Dict[str, Any]:
    """한 번의 호출 결과를 지표 dict 로 변환한다. 순수 함수."""
    fallback = is_fallback(summary)
    filler = sum(
        1 for item in routine
        if item.get("tip") == DEFAULT_TIP or item.get("focus") == DEFAULT_FOCUS
    )
    return {
        "latency_s": round(latency_s, 3),
        "fallback": fallback,
        "error": extract_error(summary),
        "routine_count": len(routine),
        "routine_in_range": 3 <= len(routine) <= 5,
        "filler_items": filler,
        "advice_chars": len(advice or ""),
    }


def summarize(rows: List[Dict[str, Any]]) -> Dict[str, Any]:
    """대상 하나의 호출 결과 목록을 요약한다. 순수 함수."""
    total = len(rows)
    ok = [r for r in rows if not r["fallback"]]
    latencies = [r["latency_s"] for r in ok]
    result: Dict[str, Any] = {
        "runs": total,
        "success": len(ok),
        "fallback": total - len(ok),
        "success_rate": round(len(ok) / total, 3) if total else 0.0,
    }
    if latencies:
        result["latency_median_s"] = round(statistics.median(latencies), 3)
        result["latency_max_s"] = round(max(latencies), 3)
        result["routine_in_range_rate"] = round(sum(r["routine_in_range"] for r in ok) / len(ok), 3)
        result["filler_items_total"] = sum(r["filler_items"] for r in ok)
        result["advice_chars_mean"] = round(statistics.mean(r["advice_chars"] for r in ok))
    return result


def render_markdown(results: Dict[str, Any]) -> str:
    """결과 JSON 을 문서에 붙여넣을 마크다운 표로 만든다. 순수 함수."""
    lines = [
        "| 대상 | 호출 | 성공률 | 폴백 | 응답시간 중앙값(s) | 최대(s) | 루틴 3~5개 비율 | 빈 필드 항목 |",
        "| --- | --- | --- | --- | --- | --- | --- | --- |",
    ]
    for name, entry in results["targets"].items():
        if entry.get("skipped"):
            lines.append(f"| {name} | - | skipped ({entry['skipped']}) | - | - | - | - | - |")
            continue
        s = entry["summary"]
        lines.append(
            "| {n} | {runs} | {rate:.0%} | {fb} | {med} | {mx} | {rng} | {fill} |".format(
                n=name,
                runs=s["runs"],
                rate=s["success_rate"],
                fb=s["fallback"],
                med=s.get("latency_median_s", "-"),
                mx=s.get("latency_max_s", "-"),
                rng=f"{s['routine_in_range_rate']:.0%}" if "routine_in_range_rate" in s else "-",
                fill=s.get("filler_items_total", "-"),
            )
        )
    return "\n".join(lines)


def parse_target(raw: str) -> Dict[str, Any]:
    """'groq' 또는 'gateway:bedrock-sonnet' 을 해석한다."""
    key, _, model = raw.partition(":")
    key = key.strip().lower()
    if key not in PROVIDERS:
        raise ValueError(f"알 수 없는 대상: {raw} (사용 가능: {', '.join(PROVIDERS)})")
    if model and key != "gateway":
        raise ValueError(f"모델 지정(:)은 gateway 에서만 지원합니다: {raw}")
    spec = PROVIDERS[key]
    return {"name": raw.strip(), "key": key, "provider": spec["provider"], "required": spec["required"], "model": model or None}


def missing_env(required: List[str]) -> List[str]:
    return [name for name in required if not os.getenv(name)]


def _call_once(scenario: Dict[str, Any]) -> Dict[str, Any]:
    from app.models.schemas import CoachingRequest, WorkoutItem
    from app.services.ai_coach import generate_coaching_advice

    request = CoachingRequest(
        user_goal=scenario["goal"],
        user_profile=scenario["profile"],
        recent_workouts=[WorkoutItem(**w) for w in scenario["workouts"]],
    )
    started = time.perf_counter()
    response = generate_coaching_advice(request)
    elapsed = time.perf_counter() - started
    routine = [item.model_dump() for item in response.recommended_routine]
    return evaluate_response(response.summary, response.coaching_advice, routine, elapsed)


def run_target(target: Dict[str, Any], runs: int) -> List[Dict[str, Any]]:
    saved = {k: os.environ.get(k) for k in ("AI_PROVIDER", *GATEWAY_ENV_VARS)}
    try:
        os.environ["AI_PROVIDER"] = target["provider"]
        if target["key"] == "gateway":
            if target["model"]:
                os.environ["BEDROCK_GATEWAY_MODEL"] = target["model"]
        else:
            # 게이트웨이 키가 설정돼 있으면 ai_coach 가 bedrock 도 게이트웨이로 보내므로 직접 호출 비교를 위해 제거
            for var in GATEWAY_ENV_VARS:
                os.environ.pop(var, None)

        rows: List[Dict[str, Any]] = []
        for scenario in SCENARIOS:
            for i in range(runs):
                row = _call_once(scenario)
                row["scenario"] = scenario["name"]
                row["run"] = i + 1
                rows.append(row)
                status = "FALLBACK" if row["fallback"] else "ok"
                print(f"  [{target['name']}] {scenario['name']} #{i + 1}: {status} {row['latency_s']}s", flush=True)
        return rows
    finally:
        for key, value in saved.items():
            if value is None:
                os.environ.pop(key, None)
            else:
                os.environ[key] = value


def main(argv: Optional[List[str]] = None) -> int:
    parser = argparse.ArgumentParser(description="AI 코칭 LLM 공급자 비교 벤치마크")
    parser.add_argument("--targets", default="dummy", help="쉼표로 구분. 예: dummy,groq,claude,gateway:bedrock-sonnet")
    parser.add_argument("--runs", type=int, default=3, help="시나리오당 반복 횟수 (기본 3)")
    parser.add_argument("--out", default="benchmark_results", help="결과 JSON 저장 디렉터리")
    parser.add_argument("--list", action="store_true", help="사용 가능한 대상과 필요한 환경변수만 출력")
    args = parser.parse_args(argv)

    if args.list:
        for name, spec in PROVIDERS.items():
            req = ", ".join(spec["required"]) or "(없음)"
            print(f"{name:10s} AI_PROVIDER={spec['provider']:16s} 필요: {req}")
        return 0

    if args.runs < 1:
        parser.error("--runs 는 1 이상이어야 합니다")

    sys.path.insert(0, str(Path(__file__).resolve().parent.parent))
    try:
        from dotenv import load_dotenv

        load_dotenv()
    except ImportError:
        pass

    try:
        targets = [parse_target(t) for t in args.targets.split(",") if t.strip()]
    except ValueError as e:
        parser.error(str(e))

    results: Dict[str, Any] = {
        "generated_at": datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
        "runs_per_scenario": args.runs,
        "scenarios": [s["name"] for s in SCENARIOS],
        "targets": {},
    }

    for target in targets:
        missing = missing_env(target["required"])
        if missing:
            print(f"- {target['name']}: 건너뜀 (환경변수 없음: {', '.join(missing)})")
            results["targets"][target["name"]] = {"skipped": f"환경변수 없음: {', '.join(missing)}"}
            continue
        print(f"- {target['name']}: {len(SCENARIOS) * args.runs}회 호출")
        rows = run_target(target, args.runs)
        results["targets"][target["name"]] = {"summary": summarize(rows), "rows": rows}

    out_dir = Path(args.out)
    out_dir.mkdir(parents=True, exist_ok=True)
    out_path = out_dir / f"benchmark_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json"
    out_path.write_text(json.dumps(results, ensure_ascii=False, indent=2), encoding="utf-8")

    print()
    print(render_markdown(results))
    print(f"\n원본 결과: {out_path}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
