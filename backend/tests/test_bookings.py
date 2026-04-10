"""预订测试 - 创建、列表、详情、取消、确认"""

import pytest
from datetime import datetime, timedelta
from httpx import AsyncClient
from tests.conftest import auth_header
from app.models import User, Venue

pytestmark = pytest.mark.asyncio


def _booking(venue_id: int, hours_offset: int = 48) -> dict:
    s = datetime.utcnow() + timedelta(hours=hours_offset)
    e = s + timedelta(hours=2)
    return {
        "title": "Meeting",
        "venue_id": venue_id,
        "start_time": s.isoformat(),
        "end_time": e.isoformat(),
        "contact_person": "T",
        "contact_email": "t@t.com",
        "contact_phone": "000",
    }


# ── 创建 ──

async def test_create_booking(client: AsyncClient, user: User, venue: Venue):
    resp = await client.post("/api/bookings/", json=_booking(venue.id), headers=auth_header(user))
    assert resp.status_code == 200
    d = resp.json()
    assert d["status"] == "pending"
    assert d["venue_id"] == venue.id


async def test_create_booking_no_auth(client: AsyncClient, venue: Venue):
    resp = await client.post("/api/bookings/", json=_booking(venue.id))
    assert resp.status_code == 403


# ── 列表 ──

async def test_list_bookings(client: AsyncClient, user: User, venue: Venue):
    h = auth_header(user)
    await client.post("/api/bookings/", json=_booking(venue.id, 48), headers=h)
    await client.post("/api/bookings/", json=_booking(venue.id, 96), headers=h)
    resp = await client.get("/api/bookings/", headers=h)
    assert resp.status_code == 200
    assert len(resp.json()) == 2


# ── 详情 ──

async def test_get_booking(client: AsyncClient, user: User, venue: Venue):
    h = auth_header(user)
    cr = await client.post("/api/bookings/", json=_booking(venue.id), headers=h)
    bid = cr.json()["id"]
    resp = await client.get(f"/api/bookings/{bid}", headers=h)
    assert resp.status_code == 200
    assert resp.json()["id"] == bid


async def test_get_booking_not_found(client: AsyncClient, user: User):
    resp = await client.get("/api/bookings/9999", headers=auth_header(user))
    assert resp.status_code == 404


# ── 取消 ──

async def test_cancel_booking(client: AsyncClient, user: User, venue: Venue):
    h = auth_header(user)
    cr = await client.post("/api/bookings/", json=_booking(venue.id), headers=h)
    bid = cr.json()["id"]
    resp = await client.post(f"/api/bookings/{bid}/cancel", headers=h)
    assert resp.status_code == 200
    assert resp.json()["success"] is True


async def test_cancel_already_cancelled(client: AsyncClient, user: User, venue: Venue):
    h = auth_header(user)
    cr = await client.post("/api/bookings/", json=_booking(venue.id), headers=h)
    bid = cr.json()["id"]
    await client.post(f"/api/bookings/{bid}/cancel", headers=h)
    resp = await client.post(f"/api/bookings/{bid}/cancel", headers=h)
    assert resp.status_code == 400


async def test_admin_can_cancel_other(client: AsyncClient, user: User, admin_user: User, venue: Venue):
    cr = await client.post("/api/bookings/", json=_booking(venue.id), headers=auth_header(user))
    bid = cr.json()["id"]
    resp = await client.post(f"/api/bookings/{bid}/cancel", headers=auth_header(admin_user))
    assert resp.status_code == 200


# ── 确认 ──

async def test_confirm_by_admin(client: AsyncClient, user: User, admin_user: User, venue: Venue):
    cr = await client.post("/api/bookings/", json=_booking(venue.id), headers=auth_header(user))
    bid = cr.json()["id"]
    resp = await client.post(f"/api/bookings/{bid}/confirm", headers=auth_header(admin_user))
    assert resp.status_code == 200
    assert resp.json()["success"] is True


async def test_confirm_by_user_forbidden(client: AsyncClient, user: User, venue: Venue):
    h = auth_header(user)
    cr = await client.post("/api/bookings/", json=_booking(venue.id), headers=h)
    bid = cr.json()["id"]
    resp = await client.post(f"/api/bookings/{bid}/confirm", headers=h)
    assert resp.status_code == 403
