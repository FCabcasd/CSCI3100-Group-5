from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from typing import List, Optional

from app.database import get_db
from app.models import User
from app.schemas import LoginRequest, TokenResponse, UserCreate, UserResponse, UserUpdate
from app.auth import (
    get_current_user, check_admin
)
from app.services import UserService

router = APIRouter(prefix="/api/admin", tags=["admin"])

@router.get("/users", response_model=List[UserResponse])
async def list_users(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
    role: Optional[List[str]] = Query(None),
    skip: int = 0,
):
    check_admin(current_user)
    """获取用戶列表"""
    if role and all(x in role for x in ["admin", "tenant_admin", "user"]):
        result = await db.execute(
            select(User)
            .where(User.is_active == True)
            .filter(User.role.in_(role))
            .offset(skip)
        )
    elif role:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="角色不存在",
        )
    else:
        result = await db.execute(
            select(User)
            .where(User.is_active == True)
            .offset(skip)
        )
    users = result.all()
    return users

@router.post("/users/{id}/suspend", response_model=UserResponse)
async def suspend_users(
    id: int,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),   
):
    check_admin(current_user)

    user = await db.get(User, id)
    
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="用户不存在",
        )
    
    UserService.suspend_user(db, user)

    return user

@router.delete("/users/{id}")
async def delete_users(
    id: int,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    check_admin(current_user)

    user = await db.get(User, id)
    
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="用户不存在",
        )
    
    user.is_active = False
    await db.commit()
    
    return {"success": True, "message": "用戶已删除"}
    