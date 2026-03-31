from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.database import get_db
from app.models.booking import Booking
from app.models.user import User
from app.schemas.booking import BookingCreate
from app.services.booking_service import (
    has_conflict,
    same_department,
    approve_booking,
    cancel_booking,
    get_next_waitlist_user,
    accept_waitlist_user
)

router = APIRouter()

@router.post("/bookings")
def create_booking(data: BookingCreate, db: Session = Depends(get_db)):

    # 1) Check department
    if not same_department(db, data.user_id, data.resource_id):
        raise HTTPException(status_code=403, detail="User and resource belong to different departments")

    # 2) Check conflict
    if has_conflict(db, data.resource_id, data.start_time, data.end_time):
        raise HTTPException(status_code=400, detail="Timeslot already booked")

    # 3) Create booking
    booking = Booking(
        user_id=data.user_id,
        resource_id=data.resource_id,
        start_time=data.start_time,
        end_time=data.end_time,
        status="pending"
    )

    db.add(booking)
    db.commit()
    db.refresh(booking)

    return booking


@router.patch("/bookings/{booking_id}/approve")
def approve_booking_route(booking_id: int, db: Session = Depends(get_db)):
    booking = db.query(Booking).filter(Booking.id == booking_id).first()

    # 1) Check if booking exists
    if not booking:
        raise HTTPException(status_code=404, detail="Booking not found")

    # 2) Check if pending
    if not approve_booking(booking):
        raise HTTPException(
            status_code=400,
            detail="Only pending bookings can be approved"
        )

    db.commit()
    db.refresh(booking)

    return booking


@router.patch("/bookings/{booking_id}/cancel")
def cancel_booking_route(booking_id: int, db: Session = Depends(get_db)):
    booking = db.query(Booking).filter(Booking.id == booking_id).first()

    # 1) Check if booking exists
    if not booking:
        raise HTTPException(status_code=404, detail="Booking not found")

    user = db.query(User).filter(User.id == booking.user_id).first()

    cancel_booking(booking, user)

    next_waitlist_user = get_next_waitlist_user(db, booking.resource_id)

    accepted_booking = None

    if next_waitlist_user:
        accepted_booking = accept_waitlist_user(db, booking, next_waitlist_user)

    db.commit()
    if accepted_booking:
        db.refresh(accepted_booking)

    return {
        "cancelled_booking_id": booking.id,
        "accepted_booking": accepted_booking if accepted_booking else None
    }