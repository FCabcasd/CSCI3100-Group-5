from app.models.booking import Booking
from app.models.user import User
from app.models.resource import Resource
from app.models.waitlist import Waitlist

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

def get_next_waitlist_user(db, resource_id):
    return db.query(Waitlist).filter(Waitlist.resource_id == resource_id).order_by(Waitlist.created_at).first()

def accept_waitlist_user(db, cancelled_booking, next_waitlist_user):
    new_booking = Booking(
        user_id=next_waitlist_user.user_id,
        resource_id=cancelled_booking.resource_id,
        start_time=cancelled_booking.start_time,
        end_time=cancelled_booking.end_time,
        status="pending"
    )

    db.add(new_booking)

    db.delete(next_waitlist_user)

    return new_booking