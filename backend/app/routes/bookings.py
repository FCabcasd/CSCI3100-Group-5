"""API路由 - 预订相关"""

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from sqlalchemy.orm import selectinload
from typing import List

from app.database import get_db
from app.models import User, Booking
from app.schemas import BookingCreate, BookingResponse, BookingDetailResponse
from app.auth import get_current_user
from app.services import ConflictDetectionService, BookingService

router = APIRouter(prefix="/api/bookings", tags=["bookings"])


@router.post("/", response_model=BookingResponse)
async def create_booking(
    booking_data: BookingCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """创建新预订"""
    try:
        booking = await BookingService.create_booking(db, current_user, booking_data)
        return booking
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e),
        )


@router.get("/", response_model=List[BookingDetailResponse])
async def list_bookings(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
    skip: int = 0,
    limit: int = 10,
):
    """获取用户的预订列表"""
    result = await db.execute(
        select(Booking)
        .where(Booking.user_id == current_user.id)
        .options(selectinload(Booking.venue), selectinload(Booking.user), selectinload(Booking.equipment_list))
        .offset(skip)
        .limit(limit)
        .order_by(Booking.created_at.desc())
    )
    bookings = result.scalars().all()
    return bookings


@router.get("/{booking_id}", response_model=BookingDetailResponse)
async def get_booking(
    booking_id: int,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """获取预订详情"""
    result = await db.execute(
        select(Booking)
        .where(Booking.id == booking_id)
        .options(selectinload(Booking.venue), selectinload(Booking.user), selectinload(Booking.equipment_list))
    )
    booking = result.scalar_one_or_none()
    
    if not booking:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="预订不存在",
        )
    
    # 检查权限（只有创建者和管理员可以查看）
    if booking.user_id != current_user.id and current_user.role != "admin":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="无权限访问",
        )
    
    return booking


@router.post("/{booking_id}/cancel")
async def cancel_booking(
    booking_id: int,
    reason: str = None,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """取消预订"""
    booking = await db.get(Booking, booking_id)
    
    if not booking:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="预订不存在",
        )
    
    if booking.user_id != current_user.id and current_user.role != "admin":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="无权限操作",
        )
    
    if booking.status == "cancelled":
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="预订已被取消",
        )
    
    cancellation = await BookingService.cancel_booking(db, booking, reason)
    
    return {
        "success": True,
        "message": "预订已取消",
        "cancellation": cancellation,
    }


@router.post("/{booking_id}/confirm")
async def confirm_booking(
    booking_id: int,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """确认预订（仅管理员）"""
    if current_user.role != "admin" and current_user.role != "tenant_admin":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="仅管理员可以确认预订",
        )
    
    booking = await db.get(Booking, booking_id)
    
    if not booking:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="预订不存在",
        )
    
    if booking.status != "pending":
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="只能确认待定的预订",
        )
    
    booking.status = "confirmed"
    await db.commit()
    await db.refresh(booking)
    
    return {
        "success": True,
        "message": "预订已确认",
        "booking": booking,
    }
