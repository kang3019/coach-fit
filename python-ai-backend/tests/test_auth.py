from datetime import timedelta

from app.utils.security import create_access_token, decode_access_token
from tests.conftest import DEMO_EMAIL, DEMO_PASSWORD


def test_login_issues_decodable_token(client):
    res = client.post(
        "/api/auth/login", json={"email": DEMO_EMAIL, "password": DEMO_PASSWORD}
    )
    assert res.status_code == 200
    body = res.json()
    assert body["tokenType"] == "bearer"
    assert body["userId"] == "user_01"
    payload = decode_access_token(body["accessToken"])
    assert payload is not None
    assert payload["sub"] == "user_01"
    assert "exp" in payload


def test_wrong_password_returns_401(client):
    res = client.post(
        "/api/auth/login", json={"email": DEMO_EMAIL, "password": "wrong-password"}
    )
    assert res.status_code == 401


def test_unknown_email_returns_401(client):
    res = client.post(
        "/api/auth/login", json={"email": "nobody@coachfit.com", "password": "x"}
    )
    assert res.status_code == 401


def test_me_with_valid_token(client, auth_headers):
    res = client.get("/api/auth/me", headers=auth_headers)
    assert res.status_code == 200
    assert res.json()["email"] == DEMO_EMAIL


def test_me_without_token_is_rejected(client):
    assert client.get("/api/auth/me").status_code in (401, 403)


def test_expired_token_is_rejected(client):
    expired = create_access_token(
        {"sub": "user_01", "email": DEMO_EMAIL}, expires_delta=timedelta(seconds=-5)
    )
    assert decode_access_token(expired) is None
    res = client.get("/api/auth/me", headers={"Authorization": f"Bearer {expired}"})
    assert res.status_code == 401


def test_tampered_token_is_rejected(client, demo_token):
    tampered = demo_token[:-4] + ("AAAA" if not demo_token.endswith("AAAA") else "BBBB")
    res = client.get("/api/auth/me", headers={"Authorization": f"Bearer {tampered}"})
    assert res.status_code == 401


def test_register_then_login(client):
    email = "register-flow@test.com"
    reg = client.post(
        "/api/auth/register", json={"email": email, "password": "pw-12345"}
    )
    assert reg.status_code == 201
    login = client.post("/api/auth/login", json={"email": email, "password": "pw-12345"})
    assert login.status_code == 200
    assert login.json()["userId"] == reg.json()["userId"]


def test_register_duplicate_email_returns_400(client):
    payload = {"email": "dup@test.com", "password": "pw-12345"}
    assert client.post("/api/auth/register", json=payload).status_code == 201
    assert client.post("/api/auth/register", json=payload).status_code == 400
