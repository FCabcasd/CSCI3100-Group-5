from app.models.booking import Booking
from app.models.user import User
from app.models.resource import Resource

from datetime import datetime, timedelta

def is_time_conflict(new_start, new_end, existing_start, existing_end):
    return new_start < existing_end and new_end > existing_start

def has_conflict(db, resource_id, new_start, new_end):
    bookings = db.query(Booking).filter(
        Booking.resource_id == resource_id
    ).all()

    for b in bookings:
        if new_start < b.end_time and new_end > b.start_time:
            return True

    return False

def same_department(db, user_id, resource_id):
    user = db.query(User).filter(User.id == user_id).first()
    resource = db.query(Resource).filter(Resource.id == resource_id).first()

    if not user or not resource:
        return False

    return user.department_id == resource.department_id

def approve_booking(booking):
    if booking.status != "pending":
        return False

    booking.status = "approved"
    return True

def cancel_booking(booking, user):
    deadline = booking.start_time - timedelta(hours=12)

    if datetime.now() > deadline:
        user.penalty_points += 1

    booking.status = "cancelled"
    return True