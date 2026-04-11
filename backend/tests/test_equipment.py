import pytest
from httpx import AsyncClient
from tests.conftest import auth_header
from app.models import User, Tenant, Equipment

pytestmark = pytest.mark.asyncio

# ── 创建 ──

async def test_create_equipment_admin(client: AsyncClient, admin_user: User, tenant: Tenant):
    resp = await client.post("/api/equipments/", json={
        "name": "Projector", "tenant_id": tenant.id, "description": "HD projector",
    }, headers=auth_header(admin_user))
    assert resp.status_code == 200
    assert resp.json()["name"] == "Projector"

async def test_create_equipment_user_forbidden(client: AsyncClient, user: User, tenant: Tenant):
    resp = await client.post("/api/equipments/", json={
        "name": "X", "tenant_id": tenant.id,
    }, headers=auth_header(user))
    assert resp.status_code == 403

# ── 列表 ──

async def test_list_equipments(client: AsyncClient, user: User, equipment: Equipment):
    resp = await client.get("/api/equipments/", headers=auth_header(user))
    assert resp.status_code == 200
    assert len(resp.json()) >= 1

# ── 详情 ──

async def test_get_equipment(client: AsyncClient, equipment: Equipment):
    resp = await client.get(f"/api/equipments/{equipment.id}")
    assert resp.status_code == 200
    assert resp.json()["id"] == equipment.id

async def test_get_equipment_not_found(client: AsyncClient):
    resp = await client.get("/api/equipments/9999")
    assert resp.status_code == 404

# ── 更新 ──

async def test_update_equipment(client: AsyncClient, admin_user: User, equipment: Equipment):
    resp = await client.put(f"/api/equipments/{equipment.id}", json={
        "name": "Updated", "description": "Updated description",
    }, headers=auth_header(admin_user))
    assert resp.status_code == 200
    assert resp.json()["name"] == "Updated"

async def test_update_equipment_user_forbidden(client: AsyncClient, user: User, equipment: Equipment):
    resp = await client.put(f"/api/equipments/{equipment.id}", json={
        "name": "X",
    }, headers=auth_header(user))
    assert resp.status_code == 403

# ── 删除 ──

async def test_delete_equipment(client: AsyncClient, admin_user: User, equipment: Equipment):
    resp = await client.delete(f"/api/equipments/{equipment.id}", headers=auth_header(admin_user))
    assert resp.status_code == 200
    assert resp.json()["success"] == True
    assert resp.json()["message"] == "设备已删除"

async def test_delete_equipment_user_forbidden(client: AsyncClient, user: User, equipment: Equipment):
    resp = await client.delete(f"/api/equipments/{equipment.id}", headers=auth_header(user))
    assert resp.status_code == 403