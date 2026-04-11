"""Email notification service"""

import logging
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from typing import Optional
import aiosmtplib

from app.config import settings

logger = logging.getLogger(__name__)


# CSS styles for emails (using {{ to escape { in .format())
EMAIL_CSS = """
body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
.container { max-width: 600px; margin: 0 auto; padding: 20px; }
.header { background-color: #2c3e50; color: white; padding: 20px; text-align: center; }
.content { padding: 20px; background-color: #f9f9f9; }
.booking-details { background-color: white; padding: 15px; border-radius: 5px; margin: 15px 0; }
.detail-row { margin: 10px 0; }
.label { font-weight: bold; color: #555; }
.footer { text-align: center; padding: 20px; color: #888; font-size: 12px; }
.status { color: #27ae60; font-weight: bold; }
.warning { background-color: #fff3cd; padding: 10px; border-radius: 5px; margin: 10px 0; }
.count { font-size: 24px; color: #3498db; text-align: center; }
""".replace("{", "{{").replace("}", "}}")


def _build_html(css: str, header_color: str, header_title: str, body_content: str) -> str:
    """Build HTML email with consistent structure"""
    return f"""
<!DOCTYPE html>
<html>
<head>
    <style>{css}</style>
</head>
<body>
    <div class="container">
        <div class="header" style="background-color: {header_color}; color: white; padding: 20px; text-align: center;">
            <h1>{header_title}</h1>
        </div>
        <div class="content">
            {body_content}
        </div>
        <div class="footer">
            <p>This email was automatically sent by {settings.APP_NAME}</p>
            <p>Please do not reply to this email</p>
        </div>
    </div>
</body>
</html>
"""


def _format_equipment_info(equipment_list: list) -> str:
    """Format equipment list for email"""
    if not equipment_list:
        return ""
    equipment_names = [e.name for e in equipment_list]
    return f'<div class="detail-row"><span class="label">Equipment:</span> {", ".join(equipment_names)}</div>'


def _format_contact_info(contact_person: Optional[str], contact_email: Optional[str], contact_phone: Optional[str]) -> str:
    """Format contact information for email"""
    parts = []
    if contact_person:
        parts.append(f"Contact Person: {contact_person}")
    if contact_email:
        parts.append(f"Email: {contact_email}")
    if contact_phone:
        parts.append(f"Phone: {contact_phone}")
    if not parts:
        return ""
    return f'<div class="detail-row"><span class="label">Contact:</span> {" | ".join(parts)}</div>'


async def send_email(
    to_email: str,
    subject: str,
    html_body: str,
    text_body: Optional[str] = None,
) -> bool:
    """
    Send an email

    Args:
        to_email: Recipient email address
        subject: Email subject
        html_body: HTML content of the email
        text_body: Plain text content (optional)

    Returns:
        True if sent successfully, False otherwise
    """
    if not settings.SMTP_USER or not settings.SMTP_PASSWORD:
        logger.warning("SMTP credentials not configured, skipping email")
        return False

    message = MIMEMultipart("alternative")
    message["From"] = settings.SMTP_FROM or settings.SMTP_USER
    message["To"] = to_email
    message["Subject"] = subject

    if text_body:
        message.attach(MIMEText(text_body, "plain"))
    message.attach(MIMEText(html_body, "html"))

    try:
        await aiosmtplib.send(
            message,
            hostname=settings.SMTP_SERVER,
            port=settings.SMTP_PORT,
            username=settings.SMTP_USER,
            password=settings.SMTP_PASSWORD,
            start_tls=True,
        )
        logger.info(f"Email sent to {to_email}: {subject}")
        return True
    except Exception as e:
        logger.error(f"Failed to send email to {to_email}: {e}")
        return False


async def send_booking_confirmation(
    user_name: str,
    user_email: str,
    booking_title: str,
    venue_name: str,
    start_time: str,
    end_time: str,
    equipment_list: Optional[list] = None,
    contact_person: Optional[str] = None,
    contact_email: Optional[str] = None,
    contact_phone: Optional[str] = None,
) -> bool:
    """Send booking confirmation email (new booking created)"""
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
    return await send_email(user_email, subject, html)


async def send_booking_confirmed_by_admin(
    user_name: str,
    user_email: str,
    booking_title: str,
    venue_name: str,
    start_time: str,
    end_time: str,
    equipment_list: Optional[list] = None,
) -> bool:
    """Send booking confirmed email (admin confirmed the booking)"""
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
    return await send_email(user_email, subject, html)


async def send_booking_cancellation(
    user_name: str,
    user_email: str,
    booking_title: str,
    venue_name: str,
    start_time: str,
    end_time: str,
    reason: Optional[str],
    is_late_cancellation: bool,
    points_deducted: Optional[int] = None,
) -> bool:
    """Send booking cancellation notification email"""
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
    return await send_email(user_email, subject, html)


async def send_recurring_booking_confirmation(
    user_name: str,
    user_email: str,
    booking_title: str,
    venue_name: str,
    booking_count: int,
    start_time: str,
    end_time: str,
    recurrence_pattern: str,
    recurrence_end_date: str,
) -> bool:
    """Send recurring booking confirmation email"""
    subject = f"Recurring Booking Created - {booking_title} ({booking_count} bookings)"

    pattern_display = {
        "daily": "Daily",
        "weekly": "Weekly",
        "monthly": "Monthly",
    }.get(recurrence_pattern, recurrence_pattern)

    body = f"""
    <p>Dear {user_name},</p>
    <p>Your recurring booking has been successfully created with a total of <span class="count">{booking_count}</span> booking instances.</p>

    <div class="booking-details">
        <h3>Booking Summary</h3>
        <div class="detail-row"><span class="label">Title:</span> {booking_title}</div>
        <div class="detail-row"><span class="label">Venue:</span> {venue_name}</div>
        <div class="detail-row"><span class="label">Recurrence Pattern:</span> {pattern_display}</div>
        <div class="detail-row"><span class="label">First Start Time:</span> {start_time}</div>
        <div class="detail-row"><span class="label">End Time:</span> {end_time}</div>
        <div class="detail-row"><span class="label">Recurrence End Date:</span> {recurrence_end_date}</div>
    </div>

    <p>All bookings are currently <strong>pending confirmation</strong>. Please wait for administrator confirmation.</p>
    """

    html = _build_html(EMAIL_CSS, "#3498db", "Recurring Booking Created", body)
    return await send_email(user_email, subject, html)


async def send_account_suspension(
    user_name: str,
    user_email: str,
    suspended_until: str,
    reason: str,
    hours_suspended: int,
) -> bool:
    """Send account suspension notification email"""
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
    return await send_email(user_email, subject, html)
