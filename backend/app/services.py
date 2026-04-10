"""业务逻辑层 - 核心服务"""

from datetime import datetime, timedelta
from typing import List, Optional, Tuple
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, and_, or_
from app.models import (
    Booking, Venue, Equipment, User, Cancellation, 
    PointDeduction, BookingStatus, Tenant
)
from app.schemas import BookingCreate, RecurringBookingCreate
import logging

logger = logging.getLogger(__name__)


class ConflictDetectionService:
    """冲突检测服务 - 核心功能：检测时间冲突"""
    
    @staticmethod
    async def check_venue_availability(
        db: AsyncSession,
        venue_id: int,
        start_time: datetime,
        end_time: datetime,
        exclude_booking_id: Optional[int] = None,
    ) -> Tuple[bool, Optional[str]]:
        """
        检查场地在指定时间是否可用
        
        Args:
            db: 数据库会话
            venue_id: 场地ID
            start_time: 开始时间
            end_time: 结束时间
            exclude_booking_id: 排除的预订ID（用于编辑）
        
        Returns:
            (是否可用, 冲突消息)
        """
        # 查询重叠的预订
        query = select(Booking).where(
            and_(
                Booking.venue_id == venue_id,
                Booking.status.in_([BookingStatus.CONFIRMED, BookingStatus.PENDING]),
                # 时间重叠逻辑：start_time < other.end_time AND end_time > other.start_time
                Booking.start_time < end_time,
                Booking.end_time > start_time,
            )
        )
        
        if exclude_booking_id:
            query = query.where(Booking.id != exclude_booking_id)
        
        result = await db.execute(query)
        conflicts = result.scalars().all()
        
        if conflicts:
            conflict_booking = conflicts[0]
            return False, f"场地在 {conflict_booking.start_time} 到 {conflict_booking.end_time} 已被预订"
        
        return True, None
    
    @staticmethod
    async def check_equipment_availability(
        db: AsyncSession,
        equipment_id: int,
        start_time: datetime,
        end_time: datetime,
        exclude_booking_id: Optional[int] = None,
    ) -> Tuple[bool, Optional[str]]:
        """检查设备在指定时间是否可用"""
        query = select(Booking).join(
            Booking.equipment_list
        ).where(
            and_(
                Equipment.id == equipment_id,
                Booking.status.in_([BookingStatus.CONFIRMED, BookingStatus.PENDING]),
                Booking.start_time < end_time,
                Booking.end_time > start_time,
            )
        )
        
        if exclude_booking_id:
            query = query.where(Booking.id != exclude_booking_id)
        
        result = await db.execute(query)
        conflicts = result.scalars().all()
        
        if conflicts:
            return False, f"设备在该时间已被预订"
        
        return True, None
    
    @staticmethod
    async def validate_booking_times(
        db: AsyncSession,
        venue_id: int,
        equipment_ids: List[int],
        start_time: datetime,
        end_time: datetime,
        exclude_booking_id: Optional[int] = None,
    ) -> Tuple[bool, Optional[str]]:
        """
        验证预订时间是否有效（多个资源）
        
        Returns:
            (是否有效, 冲突消息)
        """
        # 检查场地
        available, msg = await ConflictDetectionService.check_venue_availability(
            db, venue_id, start_time, end_time, exclude_booking_id
        )
        if not available:
            return False, msg
        
        # 检查所有设备
        for equipment_id in equipment_ids:
            available, msg = await ConflictDetectionService.check_equipment_availability(
                db, equipment_id, start_time, end_time, exclude_booking_id
            )
            if not available:
                return False, msg
        
        return True, None


class BookingService:
    """预订服务"""
    
    @staticmethod
    async def create_booking(
        db: AsyncSession,
        user: User,
        booking_data: BookingCreate,
    ) -> Booking:
        """创建单次预订"""
        # 验证冲突
        available, msg = await ConflictDetectionService.validate_booking_times(
            db,
            booking_data.venue_id,
            booking_data.equipment_ids or [],
            booking_data.start_time,
            booking_data.end_time,
        )
        
        if not available:
            raise ValueError(msg)
        
        # 检查用户积分
        if user.points < 10:
            raise ValueError("积分不足，无法预订")
        
        # 创建预订
        booking = Booking(
            user_id=user.id,
            venue_id=booking_data.venue_id,
            title=booking_data.title,
            description=booking_data.description,
            start_time=booking_data.start_time,
            end_time=booking_data.end_time,
            contact_person=booking_data.contact_person,
            contact_email=booking_data.contact_email,
            contact_phone=booking_data.contact_phone,
            estimated_attendance=booking_data.estimated_attendance,
            special_requirements=booking_data.special_requirements,
            status=BookingStatus.PENDING,
        )
        
        # 添加设备
        if booking_data.equipment_ids:
            equipment_query = select(Equipment).where(
                Equipment.id.in_(booking_data.equipment_ids)
            )
            result = await db.execute(equipment_query)
            equipment_list = result.scalars().all()
            booking.equipment_list = equipment_list
        
        db.add(booking)
        await db.commit()
        await db.refresh(booking)
        
        logger.info(f"Created booking {booking.id} for user {user.id}")
        return booking
    
    @staticmethod
    async def create_recurring_booking(
        db: AsyncSession,
        user: User,
        booking_data: RecurringBookingCreate,
    ) -> List[Booking]:
        """
        创建重复预订
        
        生成多个预订实例，间隔根据recurrence_pattern确定
        """
        bookings = []
        current_date = booking_data.start_time.date()
        end_date = booking_data.recurrence_end_date.date()
        
        # 确定间隔
        if booking_data.recurrence_pattern == "daily":
            delta = timedelta(days=1)
        elif booking_data.recurrence_pattern == "weekly":
            delta = timedelta(weeks=1)
        elif booking_data.recurrence_pattern == "monthly":
            delta = timedelta(days=30)
        else:
            raise ValueError(f"Invalid recurrence pattern: {booking_data.recurrence_pattern}")
        
        # 生成所有预订实例
        while current_date <= end_date:
            # 计算该日期对应的start_time和end_time
            instance_start = datetime.combine(
                current_date,
                booking_data.start_time.time()
            )
            instance_end = datetime.combine(
                current_date,
                booking_data.end_time.time()
            )
            
            # 验证冲突
            available, msg = await ConflictDetectionService.validate_booking_times(
                db,
                booking_data.venue_id,
                booking_data.equipment_ids or [],
                instance_start,
                instance_end,
            )
            
            if available:
                # 创建预订实例
                booking = Booking(
                    user_id=user.id,
                    venue_id=booking_data.venue_id,
                    title=booking_data.title,
                    description=booking_data.description,
                    start_time=instance_start,
                    end_time=instance_end,
                    contact_person=booking_data.contact_person,
                    contact_email=booking_data.contact_email,
                    contact_phone=booking_data.contact_phone,
                    estimated_attendance=booking_data.estimated_attendance,
                    special_requirements=booking_data.special_requirements,
                    is_recurring=True,
                    recurrence_pattern=booking_data.recurrence_pattern,
                    status=BookingStatus.PENDING,
                )
                
                if booking_data.equipment_ids:
                    equipment_query = select(Equipment).where(
                        Equipment.id.in_(booking_data.equipment_ids)
                    )
                    result = await db.execute(equipment_query)
                    equipment_list = result.scalars().all()
                    booking.equipment_list = equipment_list
                
                db.add(booking)
                bookings.append(booking)
            
            # 移到下一个日期
            current_date += delta
        
        await db.commit()
        
        for booking in bookings:
            await db.refresh(booking)
        
        logger.info(f"Created {len(bookings)} recurring bookings for user {user.id}")
        return bookings
    
    @staticmethod
    async def cancel_booking(
        db: AsyncSession,
        booking: Booking,
        reason: Optional[str] = None,
    ) -> Cancellation:
        """取消预订并记录取消信息"""
        now = datetime.utcnow()
        hours_before = (booking.start_time - now).total_seconds() / 3600
        
        # 从预订所属租户获取取消截止时间
        venue = await db.get(Venue, booking.venue_id)
        tenant = await db.get(Tenant, venue.tenant_id)
        is_late = hours_before < tenant.cancellation_deadline_hours
        
        # 更新预订状态
        booking.status = BookingStatus.CANCELLED
        booking.cancelled_at = now
        booking.cancellation_reason = reason
        
        # 创建取消记录
        cancellation = Cancellation(
            booking_id=booking.id,
            cancelled_at=now,
            hours_before_start=hours_before,
            reason=reason,
            is_late_cancellation=is_late,
        )
        
        db.add(cancellation)
        
        # 如果是迟到取消，扣分
        if is_late:
            user = await db.get(User, booking.user_id)
            points_deduction = tenant.point_deduction_per_late_cancel
            user.points -= points_deduction
            
            # 记录扣分
            point_record = PointDeduction(
                user_id=booking.user_id,
                booking_id=booking.id,
                points=points_deduction,
                reason="late_cancellation",
            )
            db.add(point_record)
            
            logger.info(f"Deducted {points_deduction} points from user {booking.user_id}")
        
        await db.commit()
        await db.refresh(cancellation)
        
        logger.info(f"Cancelled booking {booking.id}")
        return cancellation


class UserService:
    """用户服务"""
    
    @staticmethod
    async def suspend_user(
        db: AsyncSession,
        user: User,
        hours: int = 24,
    ) -> User:
        """暂停用户账户（迟到取消过多）"""
        user.suspension_until = datetime.utcnow() + timedelta(hours=hours)
        await db.commit()
        await db.refresh(user)
        
        logger.info(f"User {user.id} suspended until {user.suspension_until}")
        return user
    
    @staticmethod
    async def check_suspension(user: User) -> bool:
        """检查用户是否被暂停"""
        if user.suspension_until and datetime.utcnow() < user.suspension_until:
            return True
        return False
