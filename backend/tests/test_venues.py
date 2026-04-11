"""场地测试 - 创建、列表、详情、更新、删除"""

import pytest
from httpx import AsyncClient
from tests.conftest import auth_header
from app.models import User, Tenant, Venue

pytestmark = pytest.mark.asyncio


# ── 创建 ──

async def test_create_venue_admin(client: AsyncClient, admin_user: User, tenant: Tenant):
    resp = await client.post("/api/venues/", json={
        "name": "New Room", "tenant_id": tenant.id, "capacity": 100,
        "available_from": "08:00", "available_until": "22:00",
    }, headers=auth_header(admin_user))
    assert resp.status_code == 200
    assert resp.json()["name"] == "New Room"


async def test_create_venue_user_forbidden(client: AsyncClient, user: User, tenant: Tenant):
    resp = await client.post("/api/venues/", json={
        "name": "X", "tenant_id": tenant.id,
    }, headers=auth_header(user))
    assert resp.status_code == 403


# ── 列表 ──

async def test_list_venues(client: AsyncClient, user: User, venue: Venue):
    resp = await client.get("/api/venues/", headers=auth_header(user))
    assert resp.status_code == 200
    assert len(resp.json()) >= 1


# ── 详情 ──

async def test_get_venue(client: AsyncClient, venue: Venue):
    resp = await client.get(f"/api/venues/{venue.id}")
    assert resp.status_code == 200
    assert resp.json()["id"] == venue.id


async def test_get_venue_not_found(client: AsyncClient):
    resp = await client.get("/api/venues/9999")
    assert resp.status_code == 404


# ── 更新 ──

async def test_update_venue(client: AsyncClient, admin_user: User, venue: Venue):
    resp = await client.put(f"/api/venues/{venue.id}", json={
        "name": "Updated", "capacity": 200,
    }, headers=auth_header(admin_user))
    assert resp.status_code == 200
    assert resp.json()["name"] == "Updated"


async def test_update_venue_user_forbidden(client: AsyncClient, user: User, venue: Venue):
    resp = await client.put(f"/api/venues/{venue.id}", json={"name": "X"}, headers=auth_header(user))
    assert resp.status_code == 403


# ── 删除 ──

async def test_delete_venue(client: AsyncClient, admin_user: User, venue: Venue):
    resp = await client.delete(f"/api/venues/{venue.id}", headers=auth_header(admin_user))
    assert resp.status_code == 200
    assert resp.json()["success"] is True


async def test_delete_venue_user_forbidden(client: AsyncClient, user: User, venue: Venue):
    resp = await client.delete(f"/api/venues/{venue.id}", headers=auth_header(user))
    assert resp.status_code == 403
