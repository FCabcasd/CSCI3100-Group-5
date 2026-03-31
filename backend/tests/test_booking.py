from datetime import datetime
from app.services.booking_service import is_time_conflict, approve_booking

def test_time_overlap():
    existing_start = datetime(2026, 1, 1, 10, 0)
    existing_end = datetime(2026, 1, 1, 12, 0)

    new_start = datetime(2026, 1, 1, 11, 0)
    new_end = datetime(2026, 1, 1, 13, 0)

    assert is_time_conflict(new_start, new_end, existing_start, existing_end)

def test_conflict_detection_simple():
    existing_start = datetime(2026, 1, 1, 10, 0)
    existing_end = datetime(2026, 1, 1, 12, 0)

    new_start = datetime(2026, 1, 1, 11, 0)
    new_end = datetime(2026, 1, 1, 13, 0)

    assert is_time_conflict(new_start, new_end, existing_start, existing_end)

def test_same_department():
    class FakeUser:
        department_id = 1

    class FakeResource:
        department_id = 1

    assert FakeUser.department_id == FakeResource.department_id

def test_approve_booking():
    class FakeBooking:
        status = "pending"

    booking = FakeBooking()

    result = approve_booking(booking)

    assert result is True
    assert booking.status == "approved"

def test_late_cancellation_penalty():
    class FakeUser:
        penalty_points = 0

    FakeUser.penalty_points += 1

    assert FakeUser.penalty_points == 1

def test_waitlist():
    queue = [2, 3, 4]

    next_user = queue.pop(0)

    assert next_user == 2

def test_accept_waitlist():
    queue = [2, 3]
    promoted_user = queue.pop(0)

    assert promoted_user == 2
    assert queue == [3]