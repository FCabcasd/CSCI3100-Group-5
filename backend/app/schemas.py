"""Pydantic Schemas - 用于请求/响应验证"""

from datetime import datetime
from typing import Optional, List
from pydantic import BaseModel, EmailStr, Field


# ======================== User Schemas ========================
class UserBase(BaseModel):
    email: EmailStr
    username: str
    full_name: str


class UserCreate(UserBase):
    password: str


class UserUpdate(BaseModel):
    full_name: Optional[str] = None
    email: Optional[EmailStr] = None


class UserResponse(UserBase):
    id: int
    role: str
    tenant_id: Optional[int] = None
    is_active: bool
    points: int
    created_at: datetime
    
    class Config:
        from_attributes = True


class UserDetailResponse(UserResponse):
    suspension_until: Optional[datetime] = None
    updated_at: datetime


# ======================== Auth Schemas ========================
class LoginRequest(BaseModel):
    email: str
    password: str


class TokenResponse(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"
    expires_in: int


class TokenRefreshRequest(BaseModel):
    refresh_token: str


# ======================== Tenant Schemas ========================
class TenantBase(BaseModel):
    name: str
    description: Optional[str] = None
    cancellation_deadline_hours: int = 24
    point_deduction_per_late_cancel: int = 10
    max_recurring_days: int = 180


class TenantCreate(TenantBase):
    pass


class TenantUpdate(BaseModel):
    name: Optional[str] = None
    description: Optional[str] = None
    cancellation_deadline_hours: Optional[int] = None
    point_deduction_per_late_cancel: Optional[int] = None
    max_recurring_days: Optional[int] = None


class TenantResponse(TenantBase):
    id: int
    is_active: bool
    created_at: datetime
    updated_at: datetime
    
    class Config:
        from_attributes = True


# ======================== Venue Schemas ========================
class VenueBase(BaseModel):
    name: str
    description: Optional[str] = None
    capacity: Optional[int] = None
    location: Optional[str] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    features: Optional[dict] = None
    image_url: Optional[str] = None
    available_from: str = "08:00"
    available_until: str = "22:00"


class VenueCreate(VenueBase):
    tenant_id: int


class VenueUpdate(BaseModel):
    name: Optional[str] = None
    description: Optional[str] = None
    capacity: Optional[int] = None
    location: Optional[str] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    features: Optional[dict] = None
    image_url: Optional[str] = None
    available_from: Optional[str] = None
    available_until: Optional[str] = None


class VenueResponse(VenueBase):
    id: int
    tenant_id: int
    is_active: bool
    created_at: datetime
    updated_at: datetime
    
    class Config:
        from_attributes = True


# ======================== Equipment Schemas ========================
class EquipmentBase(BaseModel):
    name: str
    description: Optional[str] = None
    quantity: int = 1
    equipment_type: str
    image_url: Optional[str] = None


class EquipmentCreate(EquipmentBase):
    tenant_id: int


class EquipmentUpdate(BaseModel):
    name: Optional[str] = None
    description: Optional[str] = None
    quantity: Optional[int] = None
    equipment_type: Optional[str] = None
    image_url: Optional[str] = None


class EquipmentResponse(EquipmentBase):
    id: int
    tenant_id: int
    status: str
    is_active: bool
    created_at: datetime
    updated_at: datetime
    
    class Config:
        from_attributes = True


# ======================== Booking Schemas ========================
class BookingBase(BaseModel):
    title: str
    description: Optional[str] = None
    venue_id: int
    start_time: datetime
    end_time: datetime
    contact_person: str
    contact_email: EmailStr
    contact_phone: str
    estimated_attendance: Optional[int] = None
    special_requirements: Optional[str] = None


class RecurringBookingCreate(BookingBase):
    is_recurring: bool = True
    recurrence_pattern: str  # 'daily', 'weekly', 'monthly'
    recurrence_end_date: datetime
    equipment_ids: Optional[List[int]] = []


class BookingCreate(BookingBase):
    equipment_ids: Optional[List[int]] = []


class BookingUpdate(BaseModel):
    title: Optional[str] = None
    description: Optional[str] = None
    contact_person: Optional[str] = None
    contact_phone: Optional[str] = None
    estimated_attendance: Optional[int] = None
    special_requirements: Optional[str] = None


class BookingResponse(BookingBase):
    id: int
    user_id: int
    status: str
    is_recurring: bool
    recurrence_pattern: Optional[str] = None
    recurrence_end_date: Optional[datetime] = None
    cancelled_at: Optional[datetime] = None
    created_at: datetime
    updated_at: datetime
    
    class Config:
        from_attributes = True


class BookingDetailResponse(BookingResponse):
    equipment_list: List[EquipmentResponse] = []
    venue: VenueResponse
    user: UserResponse


# ======================== Cancellation Schemas ========================
class CancellationCreate(BaseModel):
    reason: Optional[str] = None


class CancellationResponse(BaseModel):
    id: int
    booking_id: int
    cancelled_at: datetime
    hours_before_start: float
    is_late_cancellation: bool
    
    class Config:
        from_attributes = True


# ======================== Pagination & Filter Schemas ========================
class PaginationParams(BaseModel):
    skip: int = Field(0, ge=0)
    limit: int = Field(10, ge=1, le=100)


class BookingFilterParams(PaginationParams):
    status: Optional[str] = None
    user_id: Optional[int] = None
    venue_id: Optional[int] = None
    start_date: Optional[datetime] = None
    end_date: Optional[datetime] = None
    tenant_id: Optional[int] = None


# ======================== Analytics Schemas ========================
class BookingStatistics(BaseModel):
    total_bookings: int
    confirmed_bookings: int
    cancelled_bookings: int
    completed_bookings: int
    no_show_count: int
    average_attendance: float
    peak_hours: List[str]
    peak_days: List[str]


class VenueUsageStats(BaseModel):
    venue_id: int
    venue_name: str
    total_bookings: int
    total_hours_used: float
    utilization_rate: float
    revenue_potential: float


class TenantAnalytics(BaseModel):
    tenant_id: int
    tenant_name: str
    total_bookings: int
    total_venues: int
    total_equipment: int
    active_users: int
    average_booking_duration_hours: float
    booking_statistics: BookingStatistics
    venue_usage: List[VenueUsageStats]
