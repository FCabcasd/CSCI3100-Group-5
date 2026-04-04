"""API路由 - 场地相关"""

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from typing import List

from app.database import get_db
from app.models import User, Venue, Tenant
from app.schemas import VenueCreate, VenueResponse, VenueUpdate
from app.auth import get_current_user, check_tenant_admin

router = APIRouter(prefix="/api/venues", tags=["venues"])


@router.post("/", response_model=VenueResponse)
async def create_venue(
    venue_data: VenueCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """创建场地（仅租户管理员）"""
    check_tenant_admin(current_user)
    
    # 检查租户是否存在
    tenant = await db.get(Tenant, venue_data.tenant_id)
    if not tenant:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="租户不存在",
        )
    
    # 检查权限
    if current_user.tenant_id != venue_data.tenant_id and current_user.role != "admin":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="无权限创建该租户的场地",
        )
    
    venue = Venue(**venue_data.model_dump())
    db.add(venue)
    await db.commit()
    await db.refresh(venue)
    
    return venue


@router.get("/", response_model=List[VenueResponse])
async def list_venues(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
    skip: int = 0,
    limit: int = 10,
):
    """获取场地列表"""
    result = await db.execute(
        select(Venue)
        .where(Venue.is_active == True)
        .offset(skip)
        .limit(limit)
    )
    venues = result.scalars().all()
    return venues


@router.get("/{venue_id}", response_model=VenueResponse)
async def get_venue(
    venue_id: int,
    db: AsyncSession = Depends(get_db),
):
    """获取场地详情"""
    venue = await db.get(Venue, venue_id)
    
    if not venue:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="场地不存在",
        )
    
    return venue


@router.put("/{venue_id}", response_model=VenueResponse)
async def update_venue(
    venue_id: int,
    venue_data: VenueUpdate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """更新场地信息"""
    check_tenant_admin(current_user)
    
    venue = await db.get(Venue, venue_id)
    if not venue:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="场地不存在",
        )
    
    # 检查权限
    if current_user.tenant_id != venue.tenant_id and current_user.role != "admin":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="无权限修改该场地",
        )
    
    # 更新字段
    update_data = venue_data.model_dump(exclude_unset=True)
    for key, value in update_data.items():
        setattr(venue, key, value)
    
    await db.commit()
    await db.refresh(venue)
    
    return venue


@router.delete("/{venue_id}")
async def delete_venue(
    venue_id: int,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """删除场地（逻辑删除）"""
    check_tenant_admin(current_user)
    
    venue = await db.get(Venue, venue_id)
    if not venue:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="场地不存在",
        )
    
    # 检查权限
    if current_user.tenant_id != venue.tenant_id and current_user.role != "admin":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="无权限删除该场地",
        )
    
    venue.is_active = False
    await db.commit()
    
    return {"success": True, "message": "场地已删除"}
