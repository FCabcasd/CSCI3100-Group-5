"""认证测试 - 注册、登录、令牌刷新、当前用户"""

import pytest
from httpx import AsyncClient

pytestmark = pytest.mark.asyncio


# ── 注册 ──

async def test_register_success(client: AsyncClient):
    resp = await client.post("/api/auth/register", json={
        "email": "a@test.com", "username": "aaa",
        "full_name": "A", "password": "pass123",
    })
    assert resp.status_code == 200
    data = resp.json()
    assert data["email"] == "a@test.com"
    assert data["username"] == "aaa"
    assert "id" in data


async def test_register_duplicate_email(client: AsyncClient):
    payload = {"email": "dup@t.com", "username": "u1", "full_name": "U", "password": "p"}
    await client.post("/api/auth/register", json=payload)
    resp = await client.post("/api/auth/register", json={**payload, "username": "u2"})
    assert resp.status_code == 409


async def test_register_duplicate_username(client: AsyncClient):
    payload = {"email": "x@t.com", "username": "same", "full_name": "U", "password": "p"}
    await client.post("/api/auth/register", json=payload)
    resp = await client.post("/api/auth/register", json={**payload, "email": "y@t.com"})
    assert resp.status_code == 409


# ── 登录 ──

async def test_login_success(client: AsyncClient):
    await client.post("/api/auth/register", json={
        "email": "login@t.com", "username": "lu", "full_name": "L", "password": "pw",
    })
    resp = await client.post("/api/auth/login", json={"email": "login@t.com", "password": "pw"})
    assert resp.status_code == 200
    d = resp.json()
    assert "access_token" in d and "refresh_token" in d
    assert d["token_type"] == "bearer"


async def test_login_wrong_password(client: AsyncClient):
    await client.post("/api/auth/register", json={
        "email": "w@t.com", "username": "wu", "full_name": "W", "password": "right",
    })
    resp = await client.post("/api/auth/login", json={"email": "w@t.com", "password": "wrong"})
    assert resp.status_code == 401


async def test_login_nonexistent(client: AsyncClient):
    resp = await client.post("/api/auth/login", json={"email": "no@t.com", "password": "x"})
    assert resp.status_code == 401


# ── 刷新令牌 ──

async def test_refresh_token(client: AsyncClient):
    await client.post("/api/auth/register", json={
        "email": "r@t.com", "username": "ru", "full_name": "R", "password": "p",
    })
    lr = await client.post("/api/auth/login", json={"email": "r@t.com", "password": "p"})
    resp = await client.post("/api/auth/refresh", json={"refresh_token": lr.json()["refresh_token"]})
    assert resp.status_code == 200
    assert "access_token" in resp.json()


async def test_refresh_invalid_token(client: AsyncClient):
    resp = await client.post("/api/auth/refresh", json={"refresh_token": "bad.token.here"})
    assert resp.status_code == 401


# ── 当前用户 ──

async def test_get_me(client: AsyncClient):
    await client.post("/api/auth/register", json={
        "email": "me@t.com", "username": "me", "full_name": "Me", "password": "p",
    })
    lr = await client.post("/api/auth/login", json={"email": "me@t.com", "password": "p"})
    token = lr.json()["access_token"]
    resp = await client.get("/api/auth/me", headers={"Authorization": f"Bearer {token}"})
    assert resp.status_code == 200
    assert resp.json()["email"] == "me@t.com"


async def test_get_me_no_token(client: AsyncClient):
    resp = await client.get("/api/auth/me")
    assert resp.status_code == 403
