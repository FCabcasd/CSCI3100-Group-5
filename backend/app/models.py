"""
数据模型定义

包含：
- User（用户）
- Tenant（租户/部门）
- Venue（场地）
- Equipment（设备）
- Booking（预订）
- EquipmentBooking（设备预订）
- Cancellation（取消）
- PointDeduction（积分扣除）
"""

from datetime import datetime
from sqlalchemy import (
    Column, Integer, String, Text, DateTime, Boolean, Float, 
    ForeignKey, Table, Enum, JSON, Index, UniqueConstraint
)
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
import enum
from app.database import Base


# 枚举类型
class UserRole(str, enum.Enum):
    """用户角色"""
    ADMIN = "admin"  # 管理员
    TENANT_ADMIN = "tenant_admin"  # 租户管理员
    USER = "user"  # 普通用户


class BookingStatus(str, enum.Enum):
    """预订状态"""
    PENDING = "pending"  # 待确认
    CONFIRMED = "confirmed"  # 已确认
    CANCELLED = "cancelled"  # 已取消
    COMPLETED = "completed"  # 已完成
    NO_SHOW = "no_show"  # 未使用


class FacilityType(str, enum.Enum):
    """设施类型"""
    VENUE = "venue"  # 场地
    EQUIPMENT = "equipment"  # 设备


# 关联表
equipment_booking_association = Table(
    'equipment_booking_association',
    Base.metadata,
    Column('booking_id', Integer, ForeignKey('booking.id', ondelete='CASCADE')),
    Column('equipment_id', Integer, ForeignKey('equipment.id', ondelete='CASCADE')),
)


class User(Base):
    """用户模型"""
    __tablename__ = "user"
    
    id = Column(Integer, primary_key=True, index=True)
    email = Column(String(255), unique=True, index=True, nullable=False)
    username = Column(String(255), unique=True, index=True, nullable=False)
    full_name = Column(String(255))
    hashed_password = Column(String(255), nullable=False)
    role = Column(Enum(UserRole), default=UserRole.USER)
    tenant_id = Column(Integer, ForeignKey('tenant.id'), nullable=True)
    is_active = Column(Boolean, default=True)
    points = Column(Integer, default=100)  # 预订积分
    suspension_until = Column(DateTime, nullable=True)  # 封禁截止时间
    
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())
    
    # 关系
    tenant = relationship("Tenant", back_populates="users")
    bookings = relationship("Booking", back_populates="user", cascade="all, delete-orphan")
    point_deductions = relationship("PointDeduction", back_populates="user")
    
    __table_args__ = (
        Index('idx_user_email', 'email'),
        Index('idx_user_tenant_id', 'tenant_id'),
    )


class Tenant(Base):
    """租户/部门模型"""
    __tablename__ = "tenant"
    
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(255), unique=True, nullable=False, index=True)
    description = Column(Text)
    is_active = Column(Boolean, default=True)
    cancellation_deadline_hours = Column(Integer, default=24)  # 取消截止时间（小时）
    point_deduction_per_late_cancel = Column(Integer, default=10)  # 迟到取消扣分
    max_recurring_days = Column(Integer, default=180)  # 最大重复天数
    
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())
    
    # 关系
    users = relationship("User", back_populates="tenant", cascade="all, delete-orphan")
    venues = relationship("Venue", back_populates="tenant", cascade="all, delete-orphan")
    equipment = relationship("Equipment", back_populates="tenant", cascade="all, delete-orphan")


class Venue(Base):
    """场地模型"""
    __tablename__ = "venue"
    
    id = Column(Integer, primary_key=True, index=True)
    tenant_id = Column(Integer, ForeignKey('tenant.id'), nullable=False)
    name = Column(String(255), nullable=False)
    description = Column(Text)
    capacity = Column(Integer)  # 容纳人数
    location = Column(String(255))  # 位置描述
    latitude = Column(Float)  # 纬度
    longitude = Column(Float)  # 经度
    features = Column(JSON, default=dict)  # 特性（如投影仪、WiFi等）
    image_url = Column(String(255))
    available_from = Column(String(5))  # HH:MM 格式
    available_until = Column(String(5))  # HH:MM 格式
    is_active = Column(Boolean, default=True)
    
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())
    
    # 关系
    tenant = relationship("Tenant", back_populates="venues")
    bookings = relationship("Booking", back_populates="venue", cascade="all, delete-orphan")
    
    __table_args__ = (
        Index('idx_venue_tenant_id', 'tenant_id'),
        Index('idx_venue_location', 'latitude', 'longitude'),
    )


class Equipment(Base):
    """设备模型"""
    __tablename__ = "equipment"
    
    id = Column(Integer, primary_key=True, index=True)
    tenant_id = Column(Integer, ForeignKey('tenant.id'), nullable=False)
    name = Column(String(255), nullable=False)
    description = Column(Text)
    quantity = Column(Integer, default=1)  # 数量
    equipment_type = Column(String(100))  # 设备类型
    status = Column(String(50), default='available')  # 状态
    image_url = Column(String(255))
    is_active = Column(Boolean, default=True)
    
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())
    
    # 关系
    tenant = relationship("Tenant", back_populates="equipment")
    bookings = relationship("Booking", secondary=equipment_booking_association, back_populates="equipment_list")
    
    __table_args__ = (
        Index('idx_equipment_tenant_id', 'tenant_id'),
    )


class Booking(Base):
    """预订模型"""
    __tablename__ = "booking"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey('user.id'), nullable=False)
    venue_id = Column(Integer, ForeignKey('venue.id'), nullable=False)
    title = Column(String(255), nullable=False)
    description = Column(Text)
    status = Column(Enum(BookingStatus), default=BookingStatus.PENDING)
    
    # 时间信息
    start_time = Column(DateTime, nullable=False)
    end_time = Column(DateTime, nullable=False)
    
    # 重复预订
    is_recurring = Column(Boolean, default=False)
    recurrence_pattern = Column(String(50))  # 'daily', 'weekly', 'monthly'
    recurrence_end_date = Column(DateTime, nullable=True)
    parent_booking_id = Column(Integer, ForeignKey('booking.id'), nullable=True)
    
    # 额外信息
    contact_person = Column(String(255))
    contact_email = Column(String(255))
    contact_phone = Column(String(20))
    estimated_attendance = Column(Integer)  # 预期出席人数
    special_requirements = Column(Text)  # 特殊要求
    
    # 取消信息
    cancelled_at = Column(DateTime, nullable=True)
    cancellation_reason = Column(Text)
    
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())
    
    # 关系
    user = relationship("User", back_populates="bookings")
    venue = relationship("Venue", back_populates="bookings")
    equipment_list = relationship("Equipment", secondary=equipment_booking_association, back_populates="bookings")
    cancellation = relationship("Cancellation", back_populates="booking", uselist=False, cascade="all, delete-orphan")
    child_bookings = relationship("Booking", remote_side=[parent_booking_id])
    
    __table_args__ = (
        Index('idx_booking_user_id', 'user_id'),
        Index('idx_booking_venue_id', 'venue_id'),
        Index('idx_booking_start_end_time', 'start_time', 'end_time'),
        Index('idx_booking_status', 'status'),
        UniqueConstraint('id', 'status', name='uc_booking_id_status'),
    )


class Cancellation(Base):
    """取消记录模型"""
    __tablename__ = "cancellation"
    
    id = Column(Integer, primary_key=True, index=True)
    booking_id = Column(Integer, ForeignKey('booking.id'), nullable=False, unique=True)
    cancelled_at = Column(DateTime(timezone=True), server_default=func.now())
    hours_before_start = Column(Float)  # 距离开始时间多少小时取消
    reason = Column(Text)
    is_late_cancellation = Column(Boolean, default=False)  # 是否为迟到取消
    
    # 关系
    booking = relationship("Booking", back_populates="cancellation")


class PointDeduction(Base):
    """积分扣除记录"""
    __tablename__ = "point_deduction"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey('user.id'), nullable=False)
    booking_id = Column(Integer, ForeignKey('booking.id'), nullable=True)
    points = Column(Integer, nullable=False)  # 扣除的积分数
    reason = Column(String(100))  # 原因：'late_cancellation', 'no_show'等
    
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    
    # 关系
    user = relationship("User", back_populates="point_deductions")
    
    __table_args__ = (
        Index('idx_point_deduction_user_id', 'user_id'),
    )
