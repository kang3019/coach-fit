"""벤치마크 스크립트의 순수 로직(폴백 판정·집계·대상 파싱) 테스트. 외부 API 호출 없음."""
import importlib.util
from pathlib import Path

import pytest

_SCRIPT = Path(__file__).resolve().parent.parent / "scripts" / "benchmark_llm.py"
_spec = importlib.util.spec_from_file_location("benchmark_llm", _SCRIPT)
bench = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(bench)


def _routine(n, tip="벤치에서 어깨를 고정하세요.", focus="가슴"):
    return [{"exercise_name": f"운동{i}", "tip": tip, "focus": focus} for i in range(n)]


def test_fallback_detected_from_summary_marker():
    assert bench.is_fallback("요약 (Groq API 호출 에러로 더미 엔진 적용됨: timeout)")
    assert not bench.is_fallback("정상 요약")
    assert not bench.is_fallback("")


def test_evaluate_marks_fallback_and_keeps_error_snippet():
    row = bench.evaluate_response("요약 (더미 엔진 적용됨: boom)", "조언", _routine(3), 1.23456)
    assert row["fallback"] is True
    assert "boom" in row["error"]
    assert row["latency_s"] == 1.235


def test_evaluate_counts_filler_and_range():
    routine = _routine(2) + _routine(1, tip=bench.DEFAULT_TIP)
    row = bench.evaluate_response("정상", "조언입니다", routine, 0.5)
    assert row["routine_count"] == 3
    assert row["routine_in_range"] is True
    assert row["filler_items"] == 1
    assert row["error"] is None

    short = bench.evaluate_response("정상", "", _routine(2), 0.5)
    assert short["routine_in_range"] is False


def test_summarize_excludes_fallback_from_latency():
    rows = [
        bench.evaluate_response("정상", "abcd", _routine(3), 1.0),
        bench.evaluate_response("정상", "abcd", _routine(4), 3.0),
        bench.evaluate_response("더미 엔진 적용됨", "x", _routine(3), 99.0),
    ]
    s = bench.summarize(rows)
    assert s["runs"] == 3
    assert s["success"] == 2
    assert s["fallback"] == 1
    assert s["success_rate"] == pytest.approx(0.667, abs=0.001)
    assert s["latency_median_s"] == 2.0
    assert s["latency_max_s"] == 3.0


def test_summarize_all_fallback_has_no_latency_fields():
    rows = [bench.evaluate_response("더미 엔진 적용됨", "x", _routine(3), 5.0)]
    s = bench.summarize(rows)
    assert s["success"] == 0
    assert "latency_median_s" not in s


def test_parse_target_gateway_model_and_errors():
    t = bench.parse_target("gateway:bedrock-haiku")
    assert t["provider"] == "bedrock-gateway"
    assert t["model"] == "bedrock-haiku"
    assert bench.parse_target("groq")["model"] is None
    with pytest.raises(ValueError):
        bench.parse_target("unknown")
    with pytest.raises(ValueError):
        bench.parse_target("groq:some-model")


def test_missing_env(monkeypatch):
    monkeypatch.delenv("GROQ_API_KEY", raising=False)
    monkeypatch.setenv("OPENAI_API_KEY", "x")
    assert bench.missing_env(["GROQ_API_KEY", "OPENAI_API_KEY"]) == ["GROQ_API_KEY"]


def test_render_markdown_handles_skipped_and_results():
    rows = [bench.evaluate_response("정상", "abcd", _routine(3), 1.0)]
    results = {
        "targets": {
            "dummy": {"summary": bench.summarize(rows), "rows": rows},
            "groq": {"skipped": "환경변수 없음: GROQ_API_KEY"},
        }
    }
    md = bench.render_markdown(results)
    assert "| dummy | 1 | 100% | 0 | 1.0 | 1.0 | 100% | 0 |" in md
    assert "skipped" in md
