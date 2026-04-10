"""冲突检测测试 - 时间重叠、不同场地、取消后释放"""

import pytest
from datetime import datetime, timedelta
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession
from tests.conftest import auth_header
from app.models import User, Venue

pytestmark = pytest.mark.asyncio


def _p(venue_id: int, start: datetime, end: datetime) -> dict:
    return {
        "title": "C",
        "venue_id": venue_id,
        "start_time": start.isoformat(),
        "end_time": end.isoformat(),
        "contact_person": "T",
        "contact_email": "t@t.com",
        "contact_phone": "0",
    }


async def test_full_overlap_rejected(client: AsyncClient, user: User, venue: Venue):
    """完全重叠应被拒绝"""
    h = auth_header(user)
    s = datetime.utcnow() + timedelta(hours=48)
    e = s + timedelta(hours=2)
    r1 = await client.post("/api/bookings/", json=_p(venue.id, s, e), headers=h)
    assert r1.status_code == 200
    r2 = await client.post("/api/bookings/", json=_p(venue.id, s, e), headers=h)
    assert r2.status_code == 400


async def test_partial_overlap_rejected(client: AsyncClient, user: User, venue: Venue):
    """部分重叠也应被拒绝"""
    h = auth_header(user)
    s = datetime.utcnow() + timedelta(hours=48)
    e = s + timedelta(hours=2)
    await client.post("/api/bookings/", json=_p(venue.id, s, e), headers=h)
    r = await client.post(
        "/api/bookings/",
        json=_p(venue.id, s + timedelta(hours=1), e + timedelta(hours=1)),
        headers=h,
    )
    assert r.status_code == 400


async def test_adjacent_allowed(client: AsyncClient, user: User, venue: Venue):
    """紧邻时段应被允许"""
    h = auth_header(user)
    s = datetime.utcnow() + timedelta(hours=48)
    e = s + timedelta(hours=2)
    await client.post("/api/bookings/", json=_p(venue.id, s, e), headers=h)
    r = await client.post(
        "/api/bookings/",
        json=_p(venue.id, e, e + timedelta(hours=2)),
        headers=h,
    )
    assert r.status_code == 200


async def test_different_venue_no_conflict(
    client: AsyncClient, user: User, venue: Venue, db: AsyncSession
):
    """不同场地同一时间不冲突"""
    v2 = Venue(tenant_id=venue.tenant_id, name="Room B", capacity=20,
               available_from="08:00", available_until="22:00")
    db.add(v2)
    await db.commit()
    await db.refresh(v2)

    h = auth_header(user)
    s = datetime.utcnow() + timedelta(hours=48)
    e = s + timedelta(hours=2)
    await client.post("/api/bookings/", json=_p(venue.id, s, e), headers=h)
    r = await client.post("/api/bookings/", json=_p(v2.id, s, e), headers=h)
    assert r.status_code == 200


async def test_cancelled_frees_slot(client: AsyncClient, user: User, venue: Venue):
    """取消后同一时段可重新预订"""
    h = auth_header(user)
    s = datetime.utcnow() + timedelta(hours=48)
    e = s + timedelta(hours=2)
    r1 = await client.post("/api/bookings/", json=_p(venue.id, s, e), headers=h)
    bid = r1.json()["id"]
    await client.post(f"/api/bookings/{bid}/cancel", headers=h)
    r2 = await client.post("/api/bookings/", json=_p(venue.id, s, e), headers=h)
    assert r2.status_code == 200
