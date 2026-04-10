"""测试配置 - 异步测试基建

使用 SQLite 内存数据库 + AsyncClient, 每个测试自动重建表。
"""

import os
import pytest
import pytest_asyncio
from httpx import AsyncClient, ASGITransport
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession, async_sessionmaker

# ── 在导入 app 之前覆盖数据库 URL ──
os.environ["DATABASE_URL"] = "sqlite+aiosqlite:///./test.db"

from app.database import Base, get_db  # noqa: E402
from app.main import app  # noqa: E402
from app.models import User, Tenant, Venue, UserRole  # noqa: E402
from app.auth import hash_password, create_access_token  # noqa: E402

# ── 测试引擎 ──
TEST_DATABASE_URL = "sqlite+aiosqlite:///./test.db"
engine_test = create_async_engine(TEST_DATABASE_URL, echo=False)
TestSession = async_sessionmaker(engine_test, class_=AsyncSession, expire_on_commit=False)


async def _override_get_db():
    async with TestSession() as session:
        yield session

app.dependency_overrides[get_db] = _override_get_db


# ── Fixtures ──

@pytest_asyncio.fixture(autouse=True)
async def _reset_tables():
    """每个测试前后重建所有表"""
    async with engine_test.begin() as conn:
        await conn.run_sync(Base.metadata.drop_all)
        await conn.run_sync(Base.metadata.create_all)
    yield
    async with engine_test.begin() as conn:
        await conn.run_sync(Base.metadata.drop_all)


@pytest_asyncio.fixture
async def db():
    """提供测试用数据库会话"""
    async with TestSession() as session:
        yield session


@pytest_asyncio.fixture
async def client():
    """异步 HTTP 测试客户端"""
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        yield ac


@pytest_asyncio.fixture
async def tenant(db: AsyncSession) -> Tenant:
    t = Tenant(name="Test Dept", description="For testing")
    db.add(t)
    await db.commit()
    await db.refresh(t)
    return t


@pytest_asyncio.fixture
async def user(db: AsyncSession, tenant: Tenant) -> User:
    u = User(
        email="user@test.com",
        username="testuser",
        full_name="Test User",
        hashed_password=hash_password("password123"),
        role=UserRole.USER,
        tenant_id=tenant.id,
    )
    db.add(u)
    await db.commit()
    await db.refresh(u)
    return u


@pytest_asyncio.fixture
async def admin_user(db: AsyncSession, tenant: Tenant) -> User:
    u = User(
        email="admin@test.com",
        username="adminuser",
        full_name="Admin User",
        hashed_password=hash_password("adminpass"),
        role=UserRole.ADMIN,
        tenant_id=tenant.id,
    )
    db.add(u)
    await db.commit()
    await db.refresh(u)
    return u


@pytest_asyncio.fixture
async def venue(db: AsyncSession, tenant: Tenant) -> Venue:
    v = Venue(
        tenant_id=tenant.id,
        name="Test Room A",
        description="A test venue",
        capacity=50,
        location="Building 1, Floor 2",
        available_from="08:00",
        available_until="22:00",
    )
    db.add(v)
    await db.commit()
    await db.refresh(v)
    return v


# ── Helpers ──

def auth_header(user_obj: User) -> dict:
    """为给定用户生成 Bearer token 头"""
    token = create_access_token({"sub": str(user_obj.id)})
    return {"Authorization": f"Bearer {token}"}
