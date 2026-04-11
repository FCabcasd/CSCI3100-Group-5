import pytest
from httpx import AsyncClient
from tests.conftest import auth_header
from app.models import User, Tenant

pytestmark = pytest.mark.asyncio

async def test_list_users_admin(client: AsyncClient, admin_user: User, tenant: Tenant):
    resp = await client.get("/api/admin/users/", headers=auth_header(admin_user))
    assert resp.status_code == 200
    assert len(resp.json()) >= 1

async def test_list_filter_users_by_role_admin(client: AsyncClient, admin_user: User, user: User):
    resp = await client.get("/api/admin/users/?role=admin", headers=auth_header(admin_user))
    assert resp.status_code == 200
    users = resp.json()
    assert len(users) == 1
    assert users[0]["role"] == "admin"
    assert users[0]["id"] == admin_user.id

async def test_list_filter_users_by_multiple_roles(client: AsyncClient, admin_user: User, user: User):
    resp = await client.get("/api/admin/users/?role=admin&role=user", headers=auth_header(admin_user))
    assert resp.status_code == 200
    users = resp.json()
    assert len(users) == 2
    returned_roles = {user_data["role"] for user_data in users}
    assert returned_roles == {"admin", "user"}
    returned_ids = {user_data["id"] for user_data in users}
    assert returned_ids == {admin_user.id, user.id}


async def test_list_filter_users_invalid_role(client: AsyncClient, admin_user: User):
    resp = await client.get("/api/admin/users/?role=invalid_role", headers=auth_header(admin_user))
    assert resp.status_code == 404
    assert resp.json()["detail"] == "角色不存在"


async def test_list_users_user_forbidden(client: AsyncClient, user: User):
    resp = await client.get("/api/admin/users/", headers=auth_header(user))
    assert resp.status_code == 403

async def test_suspend_user(client: AsyncClient, admin_user: User, user: User):
    resp = await client.post(f"/api/admin/users/{user.id}/suspend", headers=auth_header(admin_user))
    assert resp.status_code == 200
    assert resp.json()["is_active"] == False

async def test_suspend_user_not_found(client: AsyncClient, admin_user: User):
    resp = await client.post("/api/admin/users/9999/suspend", headers=auth_header(admin_user))
    assert resp.status_code == 404

async def test_delete_user(client: AsyncClient, admin_user: User, user: User):
    resp = await client.delete(f"/api/admin/users/{user.id}", headers=auth_header(admin_user))
    assert resp.status_code == 200
    assert resp.json()["success"] == True
    assert resp.json()["message"] == "用户已删除"


async def test_delete_user_not_found(client: AsyncClient, admin_user: User):
    resp = await client.delete("/api/admin/users/9999", headers=auth_header(admin_user))
    assert resp.status_code == 404

