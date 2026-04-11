"""Celery configuration for background tasks"""

from celery import Celery
from celery.schedules import crontab

from app.config import settings

celery_app = Celery(
    "booking_system",
    broker=settings.REDIS_URL,
    backend=settings.REDIS_URL,
    include=["app.tasks"],
)

# Celery configuration
celery_app.conf.update(
    task_serializer="json",
    accept_content=["json"],
    result_serializer="json",
    timezone="Asia/Hong_Kong",
    enable_utc=True,
    task_track_started=True,
    task_time_limit=30 * 60,  # 30 minutes
    task_soft_time_limit=25 * 60,  # 25 minutes soft limit
    worker_prefetch_multiplier=4,
    worker_max_tasks_per_child=1000,
)

# Beat schedule for periodic tasks
celery_app.conf.beat_schedule = {
    "send-booking-reminders": {
        "task": "app.tasks.send_booking_reminders_task",
        # Run every 30 minutes
        "schedule": crontab(minute="*/30"),
    },
    "cleanup-old-cancelled-bookings": {
        "task": "app.tasks.cleanup_old_cancelled_bookings_task",
        # Run daily at 3 AM
        "schedule": crontab(hour=3, minute=0),
    },
    "check-user-suspensions": {
        "task": "app.tasks.check_user_suspensions_task",
        # Run every hour
        "schedule": crontab(minute=0),
    },
}