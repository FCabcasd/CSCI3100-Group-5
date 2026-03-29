from datetime import datetime
from app.services.booking_service import is_time_conflict

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