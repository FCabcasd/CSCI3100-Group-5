from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.database import get_db
from app.models.booking import Booking
from app.schemas.booking import BookingCreate
from app.services.booking_service import has_conflict, same_department

router = APIRouter()

@router.post("/bookings")
def create_booking(data: BookingCreate, db: Session = Depends(get_db)):

    if not same_department(db, data.user_id, data.resource_id):
        raise HTTPException(status_code=403, detail="User and resource belong to different departments")

    # 1) Check conflict
    if has_conflict(db, data.resource_id, data.start_time, data.end_time):
        raise HTTPException(status_code=400, detail="Timeslot already booked")

    # 2) Create booking
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