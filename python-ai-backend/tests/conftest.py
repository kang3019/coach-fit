import os
import sys
import tempfile
from pathlib import Path

# app.main 은 import 시점에 DB 시드를 수행하므로, import 전에 격리된 환경을 먼저 설정한다.
_TMP_DIR = tempfile.mkdtemp(prefix="coachfit-test-")
os.environ["DATABASE_URL"] = f"sqlite:///{Path(_TMP_DIR) / 'test.db'}"
os.environ["JWT_SECRET_KEY"] = "test-secret-key"
os.environ["AI_PROVIDER"] = "dummy"
for _k in (
    "BEDROCK_GATEWAY_API_KEY",
    "BEDROCK_GATEWAY_BASE_URL",
    "GROQ_API_KEY",
    "GEMINI_API_KEY",
    "ANTHROPIC_API_KEY",
    "OPENAI_API_KEY",
):
    os.environ.pop(_k, None)

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

import pytest
from fastapi.testclient import TestClient

from app.main import app

DEMO_EMAIL = "demo@coachfit.com"
DEMO_PASSWORD = "password123"


@pytest.fixture(scope="session")
def client():
    with TestClient(app) as c:
        yield c


@pytest.fixture()
def demo_token(client):
    res = client.post(
        "/api/auth/login", json={"email": DEMO_EMAIL, "password": DEMO_PASSWORD}
    )
    assert res.status_code == 200
    return res.json()["accessToken"]


@pytest.fixture()
def auth_headers(demo_token):
    return {"Authorization": f"Bearer {demo_token}"}


@pytest.fixture()
def new_user(client):
    """테스트마다 독립된 신규 계정을 만들어 볼륨 합계가 시드 데이터에 오염되지 않게 한다."""
    import uuid

    email = f"t_{uuid.uuid4().hex[:8]}@test.com"
    res = client.post(
        "/api/auth/register",
        json={"email": email, "password": "pw-12345", "nickname": "테스터"},
    )
    assert res.status_code == 201
    body = res.json()
    return {
        "userId": body["userId"],
        "headers": {"Authorization": f"Bearer {body['accessToken']}"},
    }
