"""Tests for AI consultation assistant"""

import pytest
from unittest.mock import patch, MagicMock, AsyncMock
from app.utils.ai_consultant import (
    AIconsultant,
    ai_consultant,
    BOOKING_POLICY,
)


class TestAIconsultantAvailability:
    """Tests for AI consultant availability check"""

    def test_is_available_without_api_key(self):
        """Returns False when OpenAI API key is not configured"""
        with patch("app.utils.ai_consultant.settings") as mock_settings:
            mock_settings.OPENAI_API_KEY = ""
            consultant = AIconsultant()
            assert consultant.is_available() is False

    def test_is_available_with_api_key(self):
        """Returns True when OpenAI API key is configured"""
        with patch("app.utils.ai_consultant.settings") as mock_settings:
            mock_settings.OPENAI_API_KEY = "test-key"
            consultant = AIconsultant()
            assert consultant.is_available() is True


class TestAnswerQuestion:
    """Tests for answer_question method"""

    @pytest.mark.asyncio
    @patch.object(AIconsultant, "is_available")
    async def test_answer_without_api_key(self, mock_is_available):
        """Returns error when API key not configured"""
        mock_is_available.return_value = False
        consultant = AIconsultant()

        result = await consultant.answer_question("How do I cancel?")

        assert result["success"] is False
        assert "configure OPENAI_API_KEY" in result["answer"]

    @pytest.mark.asyncio
    @patch("app.utils.ai_consultant.OpenAI")
    @patch.object(AIconsultant, "is_available", return_value=True)
    async def test_answer_success(self, mock_is_available, mock_openai):
        """Returns answer when API call succeeds"""
        mock_client = MagicMock()
        mock_response = MagicMock()
        mock_response.choices = [MagicMock(message=MagicMock(content="Late cancellation deducts 10 points."))]
        mock_client.chat.completions.create.return_value = mock_response
        mock_openai.return_value = mock_client

        consultant = AIconsultant()
        consultant.client = mock_client

        result = await consultant.answer_question("What happens if I cancel late?")

        assert result["success"] is True
        assert "Late cancellation deducts 10 points" in result["answer"]
        mock_client.chat.completions.create.assert_called_once()

    @pytest.mark.asyncio
    @patch.object(AIconsultant, "is_available", return_value=True)
    async def test_answer_with_user_context(self, mock_is_available):
        """Includes user context in the prompt"""
        consultant = AIconsultant()
        consultant.client = MagicMock()

        mock_response = MagicMock()
        mock_response.choices = [MagicMock(message=MagicMock(content="Test answer"))]
        consultant.client.chat.completions.create.return_value = mock_response

        user_context = {
            "name": "John Doe",
            "points": 80,
            "role": "user",
        }

        await consultant.answer_question(
            question="Can I book?",
            user_context=user_context,
        )

        # Verify the call was made with user context
        call_args = consultant.client.chat.completions.create.call_args
        messages = call_args.kwargs["messages"]
        user_message = messages[1]["content"]
        assert "John Doe" in user_message
        assert "80" in user_message


class TestRecommendVenues:
    """Tests for recommend_venues method"""

    @pytest.mark.asyncio
    @patch.object(AIconsultant, "is_available")
    async def test_recommend_without_api_key(self, mock_is_available):
        """Returns error when API key not configured"""
        mock_is_available.return_value = False
        consultant = AIconsultant()

        result = await consultant.recommend_venues(
            requirements="room for 30 people",
            db=MagicMock(),
        )

        assert result["success"] is False

    @pytest.mark.asyncio
    @patch("app.utils.ai_consultant.select")
    @patch("app.utils.ai_consultant.OpenAI")
    @patch.object(AIconsultant, "is_available", return_value=True)
    async def test_recommend_returns_venue_count(self, mock_is_available, mock_openai, mock_select):
        """Returns number of venues found"""
        mock_client = MagicMock()
        mock_response = MagicMock()
        mock_response.choices = [MagicMock(message=MagicMock(content="I recommend Conference Room A."))]
        mock_client.chat.completions.create.return_value = mock_response
        mock_openai.return_value = mock_client

        consultant = AIconsultant()
        consultant.client = mock_client

        # Mock database session
        mock_db = AsyncMock()
        mock_result = MagicMock()
        mock_result.scalars.return_value.all.return_value = [
            MagicMock(name="Room A", capacity=50),
            MagicMock(name="Room B", capacity=20),
        ]
        mock_db.execute.return_value = mock_result

        result = await consultant.recommend_venues(
            requirements="small meeting room",
            db=mock_db,
        )

        assert result["success"] is True
        assert result["venues_found"] == 2


class TestGuideBooking:
    """Tests for guide_booking method"""

    @pytest.mark.asyncio
    @patch.object(AIconsultant, "is_available")
    async def test_guide_without_api_key(self, mock_is_available):
        """Returns error when API key not configured"""
        mock_is_available.return_value = False
        consultant = AIconsultant()

        result = await consultant.guide_booking(
            user_message="I want to book a room",
            db=MagicMock(),
            current_user=MagicMock(),
        )

        assert result["success"] is False


class TestCheckBookingConflicts:
    """Tests for check_booking_conflicts method"""

    @pytest.mark.asyncio
    @patch.object(AIconsultant, "is_available")
    async def test_check_conflicts_without_api_key(self, mock_is_available):
        """Returns error when API key not configured"""
        mock_is_available.return_value = False
        consultant = AIconsultant()

        result = await consultant.check_booking_conflicts(
            venue_id=1,
            start_time="2026-04-15T10:00",
            end_time="2026-04-15T11:00",
            db=MagicMock(),
        )

        assert result["success"] is False


class TestBookingPolicy:
    """Tests for booking policy content"""

    def test_policy_contains_cancellation_rule(self):
        """Policy includes late cancellation rule"""
        assert "Late cancellation" in BOOKING_POLICY
        assert "24 hours" in BOOKING_POLICY
        assert "10 point" in BOOKING_POLICY

    def test_policy_contains_user_roles(self):
        """Policy includes user roles"""
        assert "admin" in BOOKING_POLICY
        assert "tenant_admin" in BOOKING_POLICY
        assert "user" in BOOKING_POLICY

    def test_policy_contains_booking_process(self):
        """Policy includes booking process steps"""
        assert "pending" in BOOKING_POLICY
        assert "confirmed" in BOOKING_POLICY


class TestAIServiceSingleton:
    """Tests for the ai_consultant singleton instance"""

    def test_singleton_exists(self):
        """ai_consultant singleton is defined"""
        assert ai_consultant is not None
        assert isinstance(ai_consultant, AIconsultant)
