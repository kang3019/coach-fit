import pytest

import app.main as main_module
from app.models.schemas import CoachingResponse, RecommendedRoutineItem
from app.services.ai_usage_guard import ai_rate_limiter, coaching_cache


@pytest.fixture(autouse=True)
def _reset_guards():
    ai_rate_limiter.reset()
    coaching_cache.clear()
    yield
    ai_rate_limiter.reset()
    coaching_cache.clear()


@pytest.fixture()
def counting_coach(monkeypatch):
    calls = {"count": 0, "fallback": False}

    def fake_generate(request):
        calls["count"] += 1
        return CoachingResponse(
            summary=f"요약 {calls['count']}",
            coaching_advice="조언",
            recommended_routine=[
                RecommendedRoutineItem(
                    exercise_name="스쿼트", sets=4, reps=8, focus="하체", tip="무릎 정렬"
                )
            ],
            is_fallback=calls["fallback"],
        )

    monkeypatch.setattr(main_module, "generate_coaching_advice", fake_generate)
    return calls


def _add_workout(client, headers):
    res = client.post(
        "/api/workouts",
        json={"exerciseName": "벤치프레스", "sets": 3, "reps": 10, "weight": 60},
        headers=headers,
    )
    assert res.status_code == 201


@pytest.mark.parametrize(
    "path, body",
    [
        ("/api/coaching/generate", {"userId": "user_01"}),
        ("/api/coaching", {"user_id": "user_01"}),
        ("/api/ai/chat", {"message": "안녕"}),
    ],
)
def test_ai_endpoints_require_login(client, path, body):
    assert client.post(path, json=body).status_code == 401


def test_coaching_reuses_cached_result_until_workouts_change(client, new_user, counting_coach):
    headers = new_user["headers"]

    first = client.post("/api/coaching/generate", json={}, headers=headers)
    second = client.post("/api/coaching/generate", json={}, headers=headers)
    assert first.status_code == second.status_code == 200
    assert first.json()["summary"] == second.json()["summary"] == "요약 1"
    assert counting_coach["count"] == 1

    _add_workout(client, headers)
    third = client.post("/api/coaching/generate", json={}, headers=headers)
    assert third.json()["summary"] == "요약 2"
    assert counting_coach["count"] == 2


def test_coaching_cache_is_per_goal(client, new_user, counting_coach):
    headers = new_user["headers"]
    client.post("/api/coaching/generate", json={"goal": "근력 증가"}, headers=headers)
    client.post("/api/coaching/generate", json={"goal": "체지방 감량"}, headers=headers)
    assert counting_coach["count"] == 2


def test_fallback_result_is_not_cached(client, new_user, counting_coach):
    counting_coach["fallback"] = True
    headers = new_user["headers"]
    client.post("/api/coaching/generate", json={}, headers=headers)
    client.post("/api/coaching/generate", json={}, headers=headers)
    assert counting_coach["count"] == 2


def test_chat_is_rate_limited_per_minute(client, new_user, monkeypatch):
    monkeypatch.setenv("AI_RATE_LIMIT_PER_MINUTE", "2")
    headers = new_user["headers"]

    for _ in range(2):
        assert client.post("/api/ai/chat", json={"message": "안녕"}, headers=headers).status_code == 200

    blocked = client.post("/api/ai/chat", json={"message": "안녕"}, headers=headers)
    assert blocked.status_code == 429
    assert "잠시 후" in blocked.json()["detail"]


def test_daily_limit_is_per_user(client, new_user, auth_headers, monkeypatch):
    monkeypatch.setenv("AI_RATE_LIMIT_PER_DAY", "1")

    assert client.post("/api/ai/chat", json={"message": "안녕"}, headers=new_user["headers"]).status_code == 200
    assert client.post("/api/ai/chat", json={"message": "안녕"}, headers=new_user["headers"]).status_code == 429
    assert client.post("/api/ai/chat", json={"message": "안녕"}, headers=auth_headers).status_code == 200


def test_global_daily_limit_blocks_everyone(client, new_user, auth_headers, monkeypatch):
    monkeypatch.setenv("AI_GLOBAL_LIMIT_PER_DAY", "1")

    assert client.post("/api/ai/chat", json={"message": "안녕"}, headers=new_user["headers"]).status_code == 200
    assert client.post("/api/ai/chat", json={"message": "안녕"}, headers=auth_headers).status_code == 429


def test_cached_coaching_does_not_consume_rate_limit(client, new_user, counting_coach, monkeypatch):
    monkeypatch.setenv("AI_RATE_LIMIT_PER_MINUTE", "1")
    headers = new_user["headers"]

    for _ in range(3):
        assert client.post("/api/coaching/generate", json={}, headers=headers).status_code == 200
    assert counting_coach["count"] == 1
