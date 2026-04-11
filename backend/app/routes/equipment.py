from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from typing import List

from app.database import get_db
from app.models import User, Equipment, Tenant
from app.schemas import EquipmentCreate, EquipmentResponse, EquipmentUpdate
from app.auth import get_current_user, check_tenant_admin

router = APIRouter(prefix="/api/equipments", tags=["equipments"])

@router.post("/", response_model=EquipmentResponse)
async def create_equipment(
    equipment_data: EquipmentCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    check_tenant_admin(current_user)
    tenant = await db.get(Tenant, equipment_data.tenant_id)
    if not tenant:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="租户不存在",
        )
    
    # 检查权限
    if current_user.tenant_id != equipment_data.tenant_id and current_user.role != "admin":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="无权限创建该租户的设备",
        )
    
    equipment = Equipment(**equipment_data.model_dump())
    db.add(equipment)
    await db.commit()
    await db.refresh(equipment)
    
    return equipment

@router.get("/", response_model=List[EquipmentResponse])
async def list_equipments(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
    skip: int = 0,
    limit: int = 10,
):
    """获取设备列表"""
    result = await db.execute(
        select(Equipment)
        .where(Equipment.is_active == True)
        .offset(skip)
        .limit(limit)
    )
    equipments = result.scalars().all()
    return equipments

@router.get("/{equipment_id}", response_model=EquipmentResponse)
async def get_equipment(
    equipment_id: int,
    db: AsyncSession = Depends(get_db),
):
    """获取设备详情"""
    equipment = await db.get(Equipment, equipment_id)
    
    if not equipment:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="设备不存在",
        )
    
    return equipment

@router.put("/{equipment_id}", response_model=EquipmentResponse)
async def update_equipment(
    equipment_id: int,
    equipment_data: EquipmentUpdate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """更新设备信息"""
    check_tenant_admin(current_user)
    
    equipment = await db.get(Equipment, equipment_id)
    if not equipment:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="设备不存在",
        )
    
    # 检查权限
    if current_user.tenant_id != equipment.tenant_id and current_user.role != "admin":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="无权限修改该设备",
        )
    
    # 更新字段
    update_data = equipment_data.model_dump(exclude_unset=True)
    for key, value in update_data.items():
        setattr(equipment, key, value)
    
    await db.commit()
    await db.refresh(equipment)
    
    return equipment

@router.delete("/{equipment_id}")
async def delete_equipment(
    equipment_id: int,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """删除设备（逻辑删除）"""
    check_tenant_admin(current_user)
    
    equipment = await db.get(Equipment, equipment_id)
    if not equipment:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="设备不存在",
        )
    
    # 检查权限
    if current_user.tenant_id != equipment.tenant_id and current_user.role != "admin":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="无权限删除该设备",
        )
    
    equipment.is_active = False
    await db.commit()
    
    return {"success": True, "message": "设备已删除"}
