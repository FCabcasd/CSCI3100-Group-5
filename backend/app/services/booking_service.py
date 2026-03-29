from app.models.booking import Booking

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