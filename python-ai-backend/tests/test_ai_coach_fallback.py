import sys
import types

import pytest

from app.models.schemas import CoachingRequest, CoachingResponse, WorkoutItem
from app.services import ai_coach


@pytest.fixture()
def coaching_request():
    return CoachingRequest(
        user_id="user_01",
        user_goal="근비대 및 전신 근력 증진",
        user_profile={"height_cm": 175, "weight_kg": 70, "experience": "beginner"},
        recent_workouts=[
            WorkoutItem(exercise_name="벤치프레스", sets=3, reps=10, weight=60)
        ],
    )


def _assert_valid(resp: CoachingResponse):
    assert isinstance(resp, CoachingResponse)
    assert resp.summary
    assert resp.coaching_advice
    assert len(resp.recommended_routine) >= 1


def test_dummy_provider_returns_valid_response(monkeypatch, coaching_request):
    monkeypatch.setenv("AI_PROVIDER", "dummy")
    _assert_valid(ai_coach.generate_coaching_advice(coaching_request))


def test_bedrock_failure_falls_back_to_rule_engine(monkeypatch, coaching_request):
    class FailingClient:
        def converse(self, **kwargs):
            raise RuntimeError("simulated Bedrock outage")

    fake_boto3 = types.SimpleNamespace(client=lambda **kwargs: FailingClient())
    monkeypatch.setitem(sys.modules, "boto3", fake_boto3)
    monkeypatch.setenv("AI_PROVIDER", "bedrock")
    monkeypatch.delenv("BEDROCK_GATEWAY_API_KEY", raising=False)
    monkeypatch.delenv("BEDROCK_GATEWAY_BASE_URL", raising=False)

    resp = ai_coach.generate_coaching_advice(coaching_request)

    _assert_valid(resp)
    assert "더미 엔진 적용됨" in resp.summary
    assert "simulated Bedrock outage" in resp.summary


def test_bedrock_invalid_json_falls_back(monkeypatch, coaching_request):
    class GarbageClient:
        def converse(self, **kwargs):
            return {"output": {"message": {"content": [{"text": "JSON 아님"}]}}}

    monkeypatch.setitem(
        sys.modules, "boto3", types.SimpleNamespace(client=lambda **kw: GarbageClient())
    )
    monkeypatch.setenv("AI_PROVIDER", "bedrock")
    monkeypatch.delenv("BEDROCK_GATEWAY_API_KEY", raising=False)
    monkeypatch.delenv("BEDROCK_GATEWAY_BASE_URL", raising=False)

    resp = ai_coach.generate_coaching_advice(coaching_request)

    _assert_valid(resp)
    assert "더미 엔진 적용됨" in resp.summary


def test_bedrock_success_is_used_without_fallback(monkeypatch, coaching_request):
    payload = (
        '{"summary":"요약","coaching_advice":"조언","recommended_routine":'
        '[{"exercise_name":"스쿼트","sets":4,"reps":8,"focus":"하체","tip":"무릎 정렬"}]}'
    )

    class OkClient:
        def converse(self, **kwargs):
            return {"output": {"message": {"content": [{"text": payload}]}}}

    monkeypatch.setitem(
        sys.modules, "boto3", types.SimpleNamespace(client=lambda **kw: OkClient())
    )
    monkeypatch.setenv("AI_PROVIDER", "bedrock")
    monkeypatch.delenv("BEDROCK_GATEWAY_API_KEY", raising=False)
    monkeypatch.delenv("BEDROCK_GATEWAY_BASE_URL", raising=False)

    resp = ai_coach.generate_coaching_advice(coaching_request)

    assert resp.summary == "요약"
    assert resp.recommended_routine[0].exercise_name == "스쿼트"


def test_coaching_endpoint_survives_provider_failure(client, auth_headers, monkeypatch):
    class FailingClient:
        def converse(self, **kwargs):
            raise RuntimeError("boom")

    monkeypatch.setitem(
        sys.modules, "boto3", types.SimpleNamespace(client=lambda **kw: FailingClient())
    )
    monkeypatch.setenv("AI_PROVIDER", "bedrock")
    monkeypatch.delenv("BEDROCK_GATEWAY_API_KEY", raising=False)
    monkeypatch.delenv("BEDROCK_GATEWAY_BASE_URL", raising=False)

    res = client.post("/api/coaching/generate", json={"userId": "user_01"}, headers=auth_headers)

    assert res.status_code == 200
    body = res.json()
    assert "더미 엔진 적용됨" in body["summary"]
    assert len(body["recommended_routine"]) >= 1
    assert "is_fallback" not in body
