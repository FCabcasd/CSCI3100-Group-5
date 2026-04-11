"""Tests for email notification service"""

import pytest
from unittest.mock import patch, AsyncMock, MagicMock
from app.utils.email import (
    _format_equipment_info,
    _format_contact_info,
    send_booking_confirmation,
    send_booking_confirmed_by_admin,
    send_booking_cancellation,
    send_recurring_booking_confirmation,
    send_account_suspension,
)


# ======================== Helper Function Tests ========================

class TestFormatEquipmentInfo:
    """Tests for _format_equipment_info helper"""

    def test_empty_list_returns_empty_string(self):
        """Empty equipment list should return empty string"""
        result = _format_equipment_info([])
        assert result == ""

    def test_single_equipment(self):
        """Single equipment should be formatted correctly"""
        class MockEquipment:
            name = "Projector"

        result = _format_equipment_info([MockEquipment()])

        assert "Projector" in result
        assert "Equipment:" in result

    def test_multiple_equipment(self):
        """Multiple equipment should be comma-separated"""
        class MockEquipment:
            def __init__(self, name):
                self.name = name

        result = _format_equipment_info([
            MockEquipment("Projector"),
            MockEquipment("Microphone"),
            MockEquipment("Whiteboard")
        ])

        assert "Projector" in result
        assert "Microphone" in result
        assert "Whiteboard" in result
        assert ", " in result  # comma separator


class TestFormatContactInfo:
    """Tests for _format_contact_info helper"""

    def test_all_fields_present(self):
        """All contact fields should be formatted"""
        result = _format_contact_info(
            contact_person="John Doe",
            contact_email="john@example.com",
            contact_phone="12345678"
        )

        assert "John Doe" in result
        assert "john@example.com" in result
        assert "12345678" in result
        assert "Contact:" in result

    def test_only_person(self):
        """Only contact person provided"""
        result = _format_contact_info(
            contact_person="John Doe",
            contact_email=None,
            contact_phone=None
        )

        assert "John Doe" in result
        assert "Email:" not in result

    def test_empty_fields(self):
        """No contact info should return empty string"""
        result = _format_contact_info(None, None, None)
        assert result == ""

    def test_partial_fields(self):
        """Some fields missing"""
        result = _format_contact_info(
            contact_person=None,
            contact_email="john@example.com",
            contact_phone=None
        )

        assert "john@example.com" in result
        assert "Contact Person:" not in result


# ======================== Email Sending Tests ========================

class TestSendEmail:
    """Tests for base send_email function"""

    @pytest.mark.asyncio
    @patch('app.utils.email.settings')
    @patch('app.utils.email.aiosmtplib.send')
    async def test_send_email_success(self, mock_send, mock_settings):
        """Email sent successfully"""
        mock_settings.SMTP_USER = "test@example.com"
        mock_settings.SMTP_PASSWORD = "password"
        mock_settings.SMTP_FROM = "noreply@test.com"
        mock_settings.SMTP_SERVER = "smtp.gmail.com"
        mock_settings.SMTP_PORT = 587

        from app.utils.email import send_email
        result = await send_email(
            to_email="user@example.com",
            subject="Test Subject",
            html_body="<p>Test body</p>"
        )

        assert result is True
        mock_send.assert_called_once()

    @pytest.mark.asyncio
    @patch('app.utils.email.settings')
    async def test_send_email_no_credentials(self, mock_settings):
        """Should fail gracefully when SMTP not configured"""
        mock_settings.SMTP_USER = ""
        mock_settings.SMTP_PASSWORD = ""

        from app.utils.email import send_email
        result = await send_email(
            to_email="user@example.com",
            subject="Test Subject",
            html_body="<p>Test body</p>"
        )

        assert result is False

    @pytest.mark.asyncio
    @patch('app.utils.email.settings')
    @patch('app.utils.email.aiosmtplib.send')
    async def test_send_email_failure(self, mock_send, mock_settings):
        """Should handle send failure gracefully"""
        mock_settings.SMTP_USER = "test@example.com"
        mock_settings.SMTP_PASSWORD = "password"
        mock_settings.SMTP_FROM = "noreply@test.com"
        mock_settings.SMTP_SERVER = "smtp.gmail.com"
        mock_settings.SMTP_PORT = 587
        mock_send.side_effect = Exception("Connection failed")

        from app.utils.email import send_email
        result = await send_email(
            to_email="user@example.com",
            subject="Test Subject",
            html_body="<p>Test body</p>"
        )

        assert result is False


# ======================== Booking Confirmation Tests ========================

class TestSendBookingConfirmation:
    """Tests for send_booking_confirmation email"""

    @pytest.mark.asyncio
    @patch('app.utils.email.send_email')
    async def test_send_confirmation_email_success(self, mock_send_email):
        """Booking confirmation email sent successfully"""
        mock_send_email.return_value = True

        result = await send_booking_confirmation(
            user_name="Test User",
            user_email="test@example.com",
            booking_title="Team Meeting",
            venue_name="Conference Room A",
            start_time="2026-04-10 10:00",
            end_time="2026-04-10 11:00",
        )

        assert result is True
        mock_send_email.assert_called_once()
        # send_email is called with positional args: (to_email, subject, html_body)
        call_args = mock_send_email.call_args[0]
        assert call_args[0] == "test@example.com"  # to_email
        assert "Team Meeting" in call_args[1]  # subject

    @pytest.mark.asyncio
    @patch('app.utils.email.send_email')
    async def test_confirmation_with_equipment(self, mock_send_email):
        """Confirmation email includes equipment info"""
        mock_send_email.return_value = True

        class MockEquipment:
            name = "Projector"

        await send_booking_confirmation(
            user_name="Test User",
            user_email="test@example.com",
            booking_title="Team Meeting",
            venue_name="Conference Room A",
            start_time="2026-04-10 10:00",
            end_time="2026-04-10 11:00",
            equipment_list=[MockEquipment()],
        )

        call_args = mock_send_email.call_args[0]
        html = call_args[2]  # html_body
        assert "Projector" in html

    @pytest.mark.asyncio
    @patch('app.utils.email.send_email')
    async def test_confirmation_with_contact_info(self, mock_send_email):
        """Confirmation email includes contact info"""
        mock_send_email.return_value = True

        await send_booking_confirmation(
            user_name="Test User",
            user_email="test@example.com",
            booking_title="Team Meeting",
            venue_name="Conference Room A",
            start_time="2026-04-10 10:00",
            end_time="2026-04-10 11:00",
            contact_person="John Doe",
            contact_email="john@example.com",
            contact_phone="12345678",
        )

        call_args = mock_send_email.call_args[0]
        html = call_args[2]  # html_body
        assert "John Doe" in html
        assert "john@example.com" in html
        assert "12345678" in html


# ======================== Booking Confirmed by Admin Tests ========================

class TestSendBookingConfirmedByAdmin:
    """Tests for send_booking_confirmed_by_admin email"""

    @pytest.mark.asyncio
    @patch('app.utils.email.send_email')
    async def test_send_confirmed_email_success(self, mock_send_email):
        """Admin confirmation email sent successfully"""
        mock_send_email.return_value = True

        result = await send_booking_confirmed_by_admin(
            user_name="Test User",
            user_email="test@example.com",
            booking_title="Team Meeting",
            venue_name="Conference Room A",
            start_time="2026-04-10 10:00",
            end_time="2026-04-10 11:00",
        )

        assert result is True
        call_args = mock_send_email.call_args[0]
        assert "Confirmed" in call_args[1]  # subject

    @pytest.mark.asyncio
    @patch('app.utils.email.send_email')
    async def test_confirmed_email_with_equipment(self, mock_send_email):
        """Confirmed email includes equipment"""
        mock_send_email.return_value = True

        class MockEquipment:
            name = "Microphone"

        await send_booking_confirmed_by_admin(
            user_name="Test User",
            user_email="test@example.com",
            booking_title="Team Meeting",
            venue_name="Conference Room A",
            start_time="2026-04-10 10:00",
            end_time="2026-04-10 11:00",
            equipment_list=[MockEquipment()],
        )

        call_args = mock_send_email.call_args[0]
        html = call_args[2]  # html_body
        assert "Microphone" in html


# ======================== Booking Cancellation Tests ========================

class TestSendBookingCancellation:
    """Tests for send_booking_cancellation email"""

    @pytest.mark.asyncio
    @patch('app.utils.email.send_email')
    async def test_send_cancellation_email_success(self, mock_send_email):
        """Cancellation email sent successfully"""
        mock_send_email.return_value = True

        result = await send_booking_cancellation(
            user_name="Test User",
            user_email="test@example.com",
            booking_title="Team Meeting",
            venue_name="Conference Room A",
            start_time="2026-04-10 10:00",
            end_time="2026-04-10 11:00",
            reason="Schedule conflict",
            is_late_cancellation=False,
        )

        assert result is True
        call_args = mock_send_email.call_args[0]
        assert "Cancelled" in call_args[1]  # subject
        html = call_args[2]  # html_body
        assert "Schedule conflict" in html

    @pytest.mark.asyncio
    @patch('app.utils.email.send_email')
    async def test_late_cancellation_with_points_deduction(self, mock_send_email):
        """Late cancellation shows points deduction"""
        mock_send_email.return_value = True

        await send_booking_cancellation(
            user_name="Test User",
            user_email="test@example.com",
            booking_title="Team Meeting",
            venue_name="Conference Room A",
            start_time="2026-04-10 10:00",
            end_time="2026-04-10 11:00",
            reason="Emergency",
            is_late_cancellation=True,
            points_deducted=10,
        )

        call_args = mock_send_email.call_args[0]
        html = call_args[2]  # html_body
        assert "Late Cancellation Notice" in html
        assert "10" in html
        assert "points have been deducted" in html

    @pytest.mark.asyncio
    @patch('app.utils.email.send_email')
    async def test_late_cancellation_no_points_specified(self, mock_send_email):
        """Late cancellation without points specified"""
        mock_send_email.return_value = True

        await send_booking_cancellation(
            user_name="Test User",
            user_email="test@example.com",
            booking_title="Team Meeting",
            venue_name="Conference Room A",
            start_time="2026-04-10 10:00",
            end_time="2026-04-10 11:00",
            reason="Emergency",
            is_late_cancellation=True,
        )

        call_args = mock_send_email.call_args[0]
        html = call_args[2]  # html_body
        assert "Late Cancellation Notice" in html
        assert "points may have been deducted" in html

    @pytest.mark.asyncio
    @patch('app.utils.email.send_email')
    async def test_cancellation_no_reason(self, mock_send_email):
        """Cancellation without reason shows 'Not provided'"""
        mock_send_email.return_value = True

        await send_booking_cancellation(
            user_name="Test User",
            user_email="test@example.com",
            booking_title="Team Meeting",
            venue_name="Conference Room A",
            start_time="2026-04-10 10:00",
            end_time="2026-04-10 11:00",
            reason=None,
            is_late_cancellation=False,
        )

        call_args = mock_send_email.call_args[0]
        html = call_args[2]  # html_body
        assert "Not provided" in html

    @pytest.mark.asyncio
    @patch('app.utils.email.send_email')
    async def test_on_time_cancellation_no_warning(self, mock_send_email):
        """On-time cancellation should not show warning"""
        mock_send_email.return_value = True

        await send_booking_cancellation(
            user_name="Test User",
            user_email="test@example.com",
            booking_title="Team Meeting",
            venue_name="Conference Room A",
            start_time="2026-04-10 10:00",
            end_time="2026-04-10 11:00",
            reason="Changed plans",
            is_late_cancellation=False,
        )

        call_args = mock_send_email.call_args[0]
        html = call_args[2]  # html_body
        assert "Late Cancellation Notice" not in html


# ======================== Recurring Booking Tests ========================

class TestSendRecurringBookingConfirmation:
    """Tests for send_recurring_booking_confirmation email"""

    @pytest.mark.asyncio
    @patch('app.utils.email.send_email')
    async def test_send_recurring_confirmation_success(self, mock_send_email):
        """Recurring booking confirmation sent successfully"""
        mock_send_email.return_value = True

        result = await send_recurring_booking_confirmation(
            user_name="Test User",
            user_email="test@example.com",
            booking_title="Weekly Meeting",
            venue_name="Conference Room A",
            booking_count=12,
            start_time="2026-04-10 10:00",
            end_time="11:00",
            recurrence_pattern="weekly",
            recurrence_end_date="2026-07-10",
        )

        assert result is True
        call_args = mock_send_email.call_args[0]
        assert "Weekly Meeting" in call_args[1]  # subject
        html = call_args[2]  # html_body
        assert "12" in html

    @pytest.mark.asyncio
    @patch('app.utils.email.send_email')
    async def test_recurring_pattern_translations(self, mock_send_email):
        """Recurrence patterns should be translated to English"""
        mock_send_email.return_value = True

        patterns = {
            "daily": "Daily",
            "weekly": "Weekly",
            "monthly": "Monthly",
        }

        for pattern, expected in patterns.items():
            await send_recurring_booking_confirmation(
                user_name="Test User",
                user_email="test@example.com",
                booking_title="Meeting",
                venue_name="Room A",
                booking_count=5,
                start_time="2026-04-10 10:00",
                end_time="11:00",
                recurrence_pattern=pattern,
                recurrence_end_date="2026-07-10",
            )

            call_args = mock_send_email.call_args[0]
            html = call_args[2]  # html_body
            assert expected in html


# ======================== Account Suspension Tests ========================

class TestSendAccountSuspension:
    """Tests for send_account_suspension email"""

    @pytest.mark.asyncio
    @patch('app.utils.email.send_email')
    async def test_suspension_email_success(self, mock_send_email):
        """Suspension email sent successfully"""
        mock_send_email.return_value = True

        result = await send_account_suspension(
            user_name="Test User",
            user_email="test@example.com",
            suspended_until="2026-04-12 10:00",
            reason="Excessive late cancellations",
            hours_suspended=24,
        )

        assert result is True
        mock_send_email.assert_called_once()
        call_args = mock_send_email.call_args[0]
        assert call_args[0] == "test@example.com"
        assert "Suspended" in call_args[1]

    @pytest.mark.asyncio
    @patch('app.utils.email.send_email')
    async def test_suspension_email_content(self, mock_send_email):
        """Suspension email contains correct content"""
        mock_send_email.return_value = True

        await send_account_suspension(
            user_name="John Doe",
            user_email="john@example.com",
            suspended_until="2026-04-12 10:00",
            reason="Too many no-shows",
            hours_suspended=48,
        )

        call_args = mock_send_email.call_args[0]
        html = call_args[2]
        assert "John Doe" in html
        assert "Too many no-shows" in html
        assert "48" in html
        assert "2026-04-12" in html
        assert "Create new bookings" in html

    @pytest.mark.asyncio
    @patch('app.utils.email.send_email')
    async def test_suspension_email_has_warning_style(self, mock_send_email):
        """Suspension email has warning styling"""
        mock_send_email.return_value = True

        await send_account_suspension(
            user_name="Test User",
            user_email="test@example.com",
            suspended_until="2026-04-12 10:00",
            reason="Policy violation",
            hours_suspended=12,
        )

        call_args = mock_send_email.call_args[0]
        html = call_args[2]
        assert "warning" in html
        assert "suspended" in html.lower()
