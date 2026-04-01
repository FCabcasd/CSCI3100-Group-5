"""Database initialization script"""

import asyncio
import logging
from sqlalchemy import text

from app.database import engine, Base
from app.models import User, Tenant, Venue, Equipment
from app.auth import hash_password

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


async def init_db():
    """Initialize database with tables and sample data"""
    
    # 创建所有表
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    
    logger.info("✅ Database tables created")


async def init_sample_data():
    """插入示例数据"""
    from sqlalchemy.ext.asyncio import AsyncSession
    from app.database import AsyncSessionLocal
    
    async with AsyncSessionLocal() as session:
        # 检查是否已有数据
        result = await session.execute(text("SELECT COUNT(*) FROM tenant"))
        if result.scalar() > 0:
            logger.info("Sample data already exists, skipping...")
            return
        
        # 创建示例租户
        tenant = Tenant(
            name="计算机科学系",
            description="计算机科学与工程学系",
            cancellation_deadline_hours=24,
            point_deduction_per_late_cancel=10,
        )
        session.add(tenant)
        await session.flush()
        
        # 创建示例场地
        venue = Venue(
            tenant_id=tenant.id,
            name="多媒体教室A",
            description="配备投影仪和音视频设备",
            capacity=50,
            location="李兆基楼3楼",
            latitude=22.3026,
            longitude=114.2068,
            features={
                "projector": True,
                "whiteboard": True,
                "wifi": True,
                "air_conditioning": True,
            },
            available_from="08:00",
            available_until="22:00",
        )
        session.add(venue)
        await session.flush()
        
        # 创建示例设备
        equipment1 = Equipment(
            tenant_id=tenant.id,
            name="投影仪",
            description="高清投影仪",
            quantity=2,
            equipment_type="audio_visual",
        )
        equipment2 = Equipment(
            tenant_id=tenant.id,
            name="麦克风",
            description="无线麦克风",
            quantity=10,
            equipment_type="audio",
        )
        session.add_all([equipment1, equipment2])
        await session.flush()
        
        # 创建示例用户
        user = User(
            email="admin@example.com",
            username="admin",
            full_name="管理员",
            hashed_password=hash_password("admin123"),
            role="admin",
            points=1000,
        )
        
        tenant_admin = User(
            email="tenant_admin@example.com",
            username="tenant_admin",
            full_name="租户管理员",
            hashed_password=hash_password("admin123"),
            role="tenant_admin",
            tenant_id=tenant.id,
            points=500,
        )
        
        regular_user = User(
            email="user@example.com",
            username="user",
            full_name="普通用户",
            hashed_password=hash_password("user123"),
            role="user",
            tenant_id=tenant.id,
            points=100,
        )
        
        session.add_all([user, tenant_admin, regular_user])
        
        await session.commit()
        
        logger.info("✅ Sample data created")
        logger.info(f"   Tenant: 计算机科学系")
        logger.info(f"   Venue: 多媒体教室A")
        logger.info(f"   Equipment: 投影仪, 麦克风")
        logger.info(f"   Users:")
        logger.info(f"     - admin@example.com / admin123 (admin)")
        logger.info(f"     - tenant_admin@example.com / admin123 (tenant_admin)")
        logger.info(f"     - user@example.com / user123 (user)")


async def main():
    """Main initialization"""
    logger.info("Initializing database...")
    await init_db()
    
    logger.info("Adding sample data...")
    await init_sample_data()
    
    logger.info("✨ Database initialization complete!")


if __name__ == "__main__":
    asyncio.run(main())
