"""Celery background tasks for email notifications and maintenance"""

import logging
from datetime import datetime, timedelta
from typing import Optional

import aiosmtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from sqlalchemy import create_engine, select, and_
from sqlalchemy.orm import Session, sessionmaker

from app.config import settings
from app.models import Booking, User, BookingStatus, Cancellation
from app.utils.email import (
    _format_equipment_info,
    _format_contact_info,
    _build_html,
    EMAIL_CSS,
)

logger = logging.getLogger(__name__)

# Synchronous database engine for Celery tasks
_engine_kwargs = dict(pool_pre_ping=True, pool_size=5, max_overflow=10)
if settings.DATABASE_URL.startswith("sqlite"):
    _engine_kwargs = {}

engine = create_engine(settings.DATABASE_URL, **_engine_kwargs)
SessionLocal = sessionmaker(bind=engine)


def get_sync_db():
    """Get synchronous database session for Celery tasks"""
    db = SessionLocal()
    try:
        return db
    finally:
        pass  # Don't close here, caller is responsible


# ======================== Email Sending Tasks ========================


def _get_booking_email_data(booking_id: int) -> Optional[dict]:
    """Fetch booking and user data for sending emails (sync version)"""
    db = SessionLocal()
    try:
        booking = db.get(Booking, booking_id)
        if not booking:
            return None

        user = db.get(User, booking.user_id)
        if not user:
            return None

        # Get venue name
        venue_name = booking.venue.name if booking.venue else str(booking.venue_id)

        # Get equipment list
        equipment_list = list(booking.equipment_list) if booking.equipment_list else []

        return {
            "booking": booking,
            "user": user,
            "venue_name": venue_name,
            "equipment_list": equipment_list,
            "db": db,
        }
    except Exception as e:
        logger.error(f"Error fetching booking data for email: {e}")
        db.close()
        return None
    finally:
        pass  # Session closed by caller


def _close_db_session(db: Session):
    """Safely close database session"""
    try:
        db.close()
    except Exception:
        pass


def send_booking_confirmation_task(booking_id: int) -> dict:
    """Send booking confirmation email asynchronously"""
    data = _get_booking_email_data(booking_id)
    if not data:
        return {"status": "error", "message": "Booking not found"}

    booking = data["booking"]
    user = data["user"]
    db = data["db"]

    try:
        result = _sync_send_booking_confirmation(
            user_name=user.full_name or user.username,
            user_email=user.email,
            booking_title=booking.title,
            venue_name=data["venue_name"],
            start_time=booking.start_time.strftime("%Y-%m-%d %H:%M"),
            end_time=booking.end_time.strftime("%Y-%m-%d %H:%M"),
            equipment_list=data["equipment_list"],
            contact_person=booking.contact_person,
            contact_email=booking.contact_email,
            contact_phone=booking.contact_phone,
        )
        return {"status": "success" if result else "failed", "booking_id": booking_id}
    finally:
        _close_db_session(db)


def send_booking_confirmed_by_admin_task(booking_id: int) -> dict:
    """Send booking confirmed by admin email asynchronously"""
    data = _get_booking_email_data(booking_id)
    if not data:
        return {"status": "error", "message": "Booking not found"}

    booking = data["booking"]
    user = data["user"]
    db = data["db"]

    try:
        result = _sync_send_booking_confirmed_by_admin(
            user_name=user.full_name or user.username,
            user_email=user.email,
            booking_title=booking.title,
            venue_name=data["venue_name"],
            start_time=booking.start_time.strftime("%Y-%m-%d %H:%M"),
            end_time=booking.end_time.strftime("%Y-%m-%d %H:%M"),
            equipment_list=data["equipment_list"],
        )
        return {"status": "success" if result else "failed", "booking_id": booking_id}
    finally:
        _close_db_session(db)


def send_booking_cancellation_task(
    booking_id: int,
    reason: Optional[str] = None,
    is_late_cancellation: bool = False,
    points_deducted: Optional[int] = None,
) -> dict:
    """Send booking cancellation email asynchronously"""
    data = _get_booking_email_data(booking_id)
    if not data:
        return {"status": "error", "message": "Booking not found"}

    booking = data["booking"]
    user = data["user"]
    db = data["db"]

    try:
        result = _sync_send_booking_cancellation(
            user_name=user.full_name or user.username,
            user_email=user.email,
            booking_title=booking.title,
            venue_name=data["venue_name"],
            start_time=booking.start_time.strftime("%Y-%m-%d %H:%M"),
            end_time=booking.end_time.strftime("%Y-%m-%d %H:%M"),
            reason=reason,
            is_late_cancellation=is_late_cancellation,
            points_deducted=points_deducted,
        )
        return {"status": "success" if result else "failed", "booking_id": booking_id}
    finally:
        _close_db_session(db)


# ======================== Synchronous Email Sending Functions ========================


def _sync_send_email(to_email: str, subject: str, html_body: str) -> bool:
    """Synchronous version of send_email for Celery tasks"""
    import asyncio

    if not settings.SMTP_USER or not settings.SMTP_PASSWORD:
        logger.warning("SMTP credentials not configured, skipping email")
        return False

    message = MIMEMultipart("alternative")
    message["From"] = settings.SMTP_FROM or settings.SMTP_USER
    message["To"] = to_email
    message["Subject"] = subject
    message.attach(MIMEText(html_body, "html"))

    try:
        loop = asyncio.get_event_loop()
    except RuntimeError:
        loop = asyncio.new_event_loop()
        asyncio.set_event_loop(loop)

    try:
        loop.run_until_complete(
            aiosmtplib.send(
                message,
                hostname=settings.SMTP_SERVER,
                port=settings.SMTP_PORT,
                username=settings.SMTP_USER,
                password=settings.SMTP_PASSWORD,
                start_tls=True,
            )
        )
        logger.info(f"Email sent to {to_email}: {subject}")
        return True
    except Exception as e:
        logger.error(f"Failed to send email to {to_email}: {e}")
        return False


def _sync_send_booking_confirmation(
    user_name: str,
    user_email: str,
    booking_title: str,
    venue_name: str,
    start_time: str,
    end_time: str,
    equipment_list: list = None,
    contact_person: str = None,
    contact_email: str = None,
    contact_phone: str = None,
) -> bool:
    """Synchronous version of send_booking_confirmation"""
    subject = f"Booking Created - {booking_title}"

    equipment_info = _format_equipment_info(equipment_list or [])
    contact_info = _format_contact_info(contact_person, contact_email, contact_phone)

    body = f"""
    <p>Dear {user_name},</p>
    <p>Your booking has been successfully created with status: <span class="status">Pending Confirmation</span>.</p>

    <div class="booking-details">
        <h3>Booking Details</h3>
        <div class="detail-row"><span class="label">Title:</span> {booking_title}</div>
        <div class="detail-row"><span class="label">Venue:</span> {venue_name}</div>
        <div class="detail-row"><span class="label">Start Time:</span> {start_time}</div>
        <div class="detail-row"><span class="label">End Time:</span> {end_time}</div>
        {equipment_info}
        {contact_info}
    </div>

    <p>Please wait for the administrator to confirm your booking. If you have any questions, please contact the venue administrator.</p>
    """

    html = _build_html(EMAIL_CSS, "#2c3e50", "Booking Confirmation", body)
    return _sync_send_email(user_email, subject, html)


def _sync_send_booking_confirmed_by_admin(
    user_name: str,
    user_email: str,
    booking_title: str,
    venue_name: str,
    start_time: str,
    end_time: str,
    equipment_list: list = None,
) -> bool:
    """Synchronous version of send_booking_confirmed_by_admin"""
    subject = f"Booking Confirmed - {booking_title}"

    equipment_info = _format_equipment_info(equipment_list or [])

    body = f"""
    <p>Dear {user_name},</p>
    <p>Your booking has been confirmed!</p>

    <div class="booking-details">
        <h3>Booking Details</h3>
        <div class="detail-row"><span class="label">Title:</span> {booking_title}</div>
        <div class="detail-row"><span class="label">Venue:</span> {venue_name}</div>
        <div class="detail-row"><span class="label">Start Time:</span> {start_time}</div>
        <div class="detail-row"><span class="label">End Time:</span> {end_time}</div>
        {equipment_info}
    </div>

    <p>Please arrive at the venue on time. If you need to cancel, please contact the administrator in advance.</p>
    """

    html = _build_html(EMAIL_CSS, "#27ae60", "Booking Confirmed", body)
    return _sync_send_email(user_email, subject, html)


def _sync_send_booking_cancellation(
    user_name: str,
    user_email: str,
    booking_title: str,
    venue_name: str,
    start_time: str,
    end_time: str,
    reason: str = None,
    is_late_cancellation: bool = False,
    points_deducted: int = None,
) -> bool:
    """Synchronous version of send_booking_cancellation"""
    subject = f"Booking Cancelled - {booking_title}"

    late_warning = ""
    if is_late_cancellation and points_deducted:
        late_warning = f'''
        <div class="warning">
            <strong>Late Cancellation Notice:</strong> Because you cancelled within a short time before the booking start,
            <strong>{points_deducted}</strong> points have been deducted from your account.
        </div>
        '''
    elif is_late_cancellation:
        late_warning = '''
        <div class="warning">
            <strong>Late Cancellation Notice:</strong> Because you cancelled within a short time before the booking start,
            points may have been deducted from your account.
        </div>
        '''

    body = f"""
    <p>Dear {user_name},</p>
    <p>Your booking has been cancelled.</p>

    <div class="booking-details">
        <h3>Cancelled Booking</h3>
        <div class="detail-row"><span class="label">Title:</span> {booking_title}</div>
        <div class="detail-row"><span class="label">Venue:</span> {venue_name}</div>
        <div class="detail-row"><span class="label">Original Time:</span> {start_time} - {end_time}</div>
        <div class="detail-row"><span class="label">Cancellation Reason:</span> {reason or "Not provided"}</div>
    </div>

    {late_warning}
    """

    html = _build_html(EMAIL_CSS, "#e74c3c", "Booking Cancelled", body)
    return _sync_send_email(user_email, subject, html)


def _sync_send_booking_reminder(
    user_name: str,
    user_email: str,
    booking_title: str,
    venue_name: str,
    start_time: str,
    end_time: str,
    equipment_list: list = None,
    hours_until: int = None,
) -> bool:
    """Send booking reminder email"""
    subject = f"Booking Reminder - {booking_title}"

    equipment_info = _format_equipment_info(equipment_list or [])

    time_message = f"in {hours_until} hours" if hours_until else "soon"

    body = f"""
    <p>Dear {user_name},</p>
    <p>This is a reminder that your booking is starting {time_message}.</p>

    <div class="booking-details">
        <h3>Upcoming Booking</h3>
        <div class="detail-row"><span class="label">Title:</span> {booking_title}</div>
        <div class="detail-row"><span class="label">Venue:</span> {venue_name}</div>
        <div class="detail-row"><span class="label">Start Time:</span> {start_time}</div>
        <div class="detail-row"><span class="label">End Time:</span> {end_time}</div>
        {equipment_info}
    </div>

    <p>Please arrive at the venue on time. If you can no longer attend, please cancel as soon as possible.</p>
    """

    html = _build_html(EMAIL_CSS, "#3498db", "Booking Reminder", body)
    return _sync_send_email(user_email, subject, html)


def _sync_send_account_suspension(
    user_name: str,
    user_email: str,
    suspended_until: str,
    reason: str,
    hours_suspended: int,
) -> bool:
    """Synchronous version of send_account_suspension for Celery tasks"""
    subject = "Account Suspended - Action Required"

    body = f"""
    <p>Dear {user_name},</p>
    <p>Your account has been <strong>suspended</strong> due to the following reason:</p>

    <div class="warning">
        <strong>Reason:</strong> {reason}
    </div>

    <div class="booking-details">
        <h3>Suspension Details</h3>
        <div class="detail-row"><span class="label">Duration:</span> {hours_suspended} hours</div>
        <div class="detail-row"><span class="label">Suspension Ends:</span> {suspended_until}</div>
    </div>

    <p>During the suspension period, you will not be able to:</p>
    <ul>
        <li>Create new bookings</li>
        <li>Modify existing bookings</li>
    </ul>

    <p>Please contact the administrator if you believe this suspension was made in error.</p>

    <p>After the suspension period ends, your account will be automatically restored.</p>
    """

    html = _build_html(EMAIL_CSS, "#e74c3c", "Account Suspended", body)
    return _sync_send_email(user_email, subject, html)


# ======================== Periodic/Scheduled Tasks ========================


def send_booking_reminders_task() -> dict:
    """
    Send reminder emails for bookings starting in 24 hours and 1 hour.
    This task runs every 30 minutes via Celery Beat.
    """
    db = SessionLocal()
    try:
        now = datetime.utcnow()

        # Find bookings starting in 23-24 hours (for 24-hour reminder)
        reminder_24h_start = now + timedelta(hours=23)
        reminder_24h_end = now + timedelta(hours=24)

        # Find bookings starting in 30 minutes to 1 hour (for 1-hour reminder)
        reminder_1h_start = now + timedelta(minutes=30)
        reminder_1h_end = now + timedelta(hours=1)

        results = {"24h_reminders": 0, "1h_reminders": 0, "errors": 0}

        # Query for 24-hour reminders
        query_24h = select(Booking).where(
            and_(
                Booking.status == BookingStatus.CONFIRMED,
                Booking.start_time >= reminder_24h_start,
                Booking.start_time <= reminder_24h_end,
            )
        )

        for booking in db.execute(query_24h).scalars().all():
            try:
                user = db.get(User, booking.user_id)
                if not user:
                    continue

                equipment_list = list(booking.equipment_list) if booking.equipment_list else []
                venue_name = booking.venue.name if booking.venue else str(booking.venue_id)

                result = _sync_send_booking_reminder(
                    user_name=user.full_name or user.username,
                    user_email=user.email,
                    booking_title=booking.title,
                    venue_name=venue_name,
                    start_time=booking.start_time.strftime("%Y-%m-%d %H:%M"),
                    end_time=booking.end_time.strftime("%Y-%m-%d %H:%M"),
                    equipment_list=equipment_list,
                    hours_until=24,
                )

                if result:
                    results["24h_reminders"] += 1
                else:
                    results["errors"] += 1

            except Exception as e:
                logger.error(f"Error sending 24h reminder for booking {booking.id}: {e}")
                results["errors"] += 1

        # Query for 1-hour reminders
        query_1h = select(Booking).where(
            and_(
                Booking.status == BookingStatus.CONFIRMED,
                Booking.start_time >= reminder_1h_start,
                Booking.start_time <= reminder_1h_end,
            )
        )

        for booking in db.execute(query_1h).scalars().all():
            try:
                user = db.get(User, booking.user_id)
                if not user:
                    continue

                equipment_list = list(booking.equipment_list) if booking.equipment_list else []
                venue_name = booking.venue.name if booking.venue else str(booking.venue_id)

                result = _sync_send_booking_reminder(
                    user_name=user.full_name or user.username,
                    user_email=user.email,
                    booking_title=booking.title,
                    venue_name=venue_name,
                    start_time=booking.start_time.strftime("%Y-%m-%d %H:%M"),
                    end_time=booking.end_time.strftime("%Y-%m-%d %H:%M"),
                    equipment_list=equipment_list,
                    hours_until=1,
                )

                if result:
                    results["1h_reminders"] += 1
                else:
                    results["errors"] += 1

            except Exception as e:
                logger.error(f"Error sending 1h reminder for booking {booking.id}: {e}")
                results["errors"] += 1

        logger.info(f"Booking reminders task completed: {results}")
        return results

    finally:
        db.close()


def cleanup_old_cancelled_bookings_task() -> dict:
    """
    Clean up old cancelled bookings and their associated data.
    Removes cancellations for bookings older than 90 days.
    This task runs daily via Celery Beat.
    """
    db = SessionLocal()
    try:
        cutoff_date = datetime.utcnow() - timedelta(days=90)

        # Find old cancelled bookings
        old_cancellations = (
            db.query(Cancellation)
            .join(Booking)
            .filter(
                Booking.status == BookingStatus.CANCELLED,
                Cancellation.cancelled_at < cutoff_date,
            )
            .all()
        )

        deleted_count = 0
        for cancellation in old_cancellations:
            try:
                db.delete(cancellation)
                deleted_count += 1
            except Exception as e:
                logger.error(f"Error deleting cancellation {cancellation.id}: {e}")

        db.commit()

        results = {"cancellations_deleted": deleted_count}
        logger.info(f"Cleanup task completed: {results}")
        return results

    except Exception as e:
        logger.error(f"Error in cleanup task: {e}")
        db.rollback()
        return {"error": str(e)}
    finally:
        db.close()


def check_user_suspensions_task() -> dict:
    """
    Check and lift user suspensions that have expired.
    This task runs hourly via Celery Beat.
    """
    db = SessionLocal()
    try:
        now = datetime.utcnow()

        # Find users with expired suspensions
        suspended_users = (
            db.query(User)
            .filter(
                User.suspension_until.isnot(None),
                User.suspension_until <= now,
            )
            .all()
        )

        unsuspended_count = 0
        for user in suspended_users:
            try:
                user.suspension_until = None
                unsuspended_count += 1
                logger.info(f"Unsuspending user {user.id}: {user.username}")
            except Exception as e:
                logger.error(f"Error unsuspending user {user.id}: {e}")

        db.commit()

        results = {"users_unsuspended": unsuspended_count}
        logger.info(f"User suspension check completed: {results}")
        return results

    except Exception as e:
        logger.error(f"Error in suspension check task: {e}")
        db.rollback()
        return {"error": str(e)}
    finally:
        db.close()


# ======================== Health Check ========================


def health_check_task() -> dict:
    """Simple health check task to verify Celery is working"""
    return {
        "status": "healthy",
        "timestamp": datetime.utcnow().isoformat(),
    }
