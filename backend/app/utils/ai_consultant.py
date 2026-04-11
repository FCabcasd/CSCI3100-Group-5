"""AI-powered booking consultation assistant using OpenAI"""

import logging
from typing import Optional, List, Dict, Any
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, and_
from openai import OpenAI

from app.config import settings
from app.models import Booking, Venue, User, Tenant, BookingStatus

logger = logging.getLogger(__name__)

# Booking policy for system prompt
BOOKING_POLICY = """You are a helpful assistant for the CUHK Venue & Equipment Booking System.

KNOWLEDGE BASE:

## Booking Rules:
1. Users can create bookings for venues and equipment
2. Each user has points (starting at 100 points)
3. Late cancellation (within 24 hours of start time) results in 10 point deduction
4. If points fall below 10, user cannot make new bookings
5. Users with 0 points or below will be suspended

## Venue Information:
- Venues have capacity, location, and features
- Venues are scoped to tenants (departments)
- Each venue has available_from and available_until times

## Equipment:
- Equipment can be booked alongside venues
- Equipment availability is checked for conflicts

## Booking Process:
1. Create booking with venue_id, start_time, end_time, title
2. System checks for time conflicts
3. Booking starts in "pending" status
4. Admin confirms booking to change status to "confirmed"
5. User or admin can cancel booking

## Recurring Bookings:
- Support daily, weekly, and monthly patterns
- Each instance is checked for conflicts independently

## Cancellation:
- Can cancel any booking before start time
- Late cancellation (within deadline_hours, typically 24) loses points
- Cancellation reason is recorded

## User Roles:
- admin: Full system access
- tenant_admin: Manage venues and confirm bookings within tenant
- user: Create and manage own bookings

## Key Time Formats:
- Start/end time format: "YYYY-MM-DD HH:MM"
- Dates use 24-hour format

Answer questions based on the above policy. Be helpful, concise, and accurate.
If you don't know something, say you don't know rather than making up information."""


class AIconsultant:
    """AI consultation assistant for booking system"""

    def __init__(self):
        self.client = None
        if settings.OPENAI_API_KEY:
            self.client = OpenAI(api_key=settings.OPENAI_API_KEY)

    def is_available(self) -> bool:
        """Check if AI consultant is configured"""
        return self.client is not None

    async def answer_question(
        self,
        question: str,
        user_context: Optional[Dict[str, Any]] = None,
    ) -> Dict[str, Any]:
        """
        Answer a question about booking policies.

        Args:
            question: User's question
            user_context: Optional user info (name, points, etc.)

        Returns:
            Dict with 'answer' and 'success' status
        """
        if not self.is_available():
            return {
                "success": False,
                "answer": "AI consultant is not available. Please configure OPENAI_API_KEY.",
            }

        try:
            # Build context message if user info provided
            context_msg = ""
            if user_context:
                context_msg = f"\n\nUser Context:\n- User: {user_context.get('name', 'Unknown')}\n- Points: {user_context.get('points', 'N/A')}\n- Role: {user_context.get('role', 'user')}"

            response = self.client.chat.completions.create(
                model="gpt-3.5-turbo",
                messages=[
                    {"role": "system", "content": BOOKING_POLICY},
                    {
                        "role": "user",
                        "content": f"{context_msg}\n\nQuestion: {question}",
                    },
                ],
                max_tokens=500,
                temperature=0.7,
            )

            answer = response.choices[0].message.content
            return {"success": True, "answer": answer}

        except Exception as e:
            logger.error(f"AI consultant error: {e}")
            return {"success": False, "answer": f"Sorry, I encountered an error: {str(e)}"}

    async def recommend_venues(
        self,
        requirements: str,
        db: AsyncSession,
        tenant_id: Optional[int] = None,
    ) -> Dict[str, Any]:
        """
        Recommend venues based on user requirements.

        Args:
            requirements: User's requirements (e.g., "30 person meeting room with projector")
            db: Database session
            tenant_id: Filter by tenant (optional)

        Returns:
            Dict with venue recommendations
        """
        if not self.is_available():
            return {
                "success": False,
                "answer": "AI consultant is not available. Please configure OPENAI_API_KEY.",
            }

        try:
            # Query available venues
            query = select(Venue).where(Venue.is_active == True)
            if tenant_id:
                query = query.where(Venue.tenant_id == tenant_id)

            result = await db.execute(query)
            venues = result.scalars().all()

            # Format venue info for prompt
            venue_list = []
            for v in venues:
                venue_list.append(
                    f"- {v.name}: Capacity {v.capacity or 'N/A'}, "
                    f"Location: {v.location or 'N/A'}, "
                    f"Features: {v.features or {}}"
                )

            venues_info = "\n".join(venue_list) if venue_list else "No venues available."

            system_prompt = f"""{BOOKING_POLICY}

AVAILABLE VENUES:
{venues_info}

Based on the user's requirements below, recommend the most suitable venues from the list above.
If no venues match, explain why and suggest alternatives.
Be specific about which venue fits best and why."""

            response = self.client.chat.completions.create(
                model="gpt-3.5-turbo",
                messages=[
                    {"role": "system", "content": system_prompt},
                    {"role": "user", "content": f"Requirements: {requirements}"},
                ],
                max_tokens=500,
                temperature=0.7,
            )

            answer = response.choices[0].message.content
            return {
                "success": True,
                "answer": answer,
                "venues_found": len(venues),
            }

        except Exception as e:
            logger.error(f"AI consultant venue recommendation error: {e}")
            return {"success": False, "answer": f"Sorry, I encountered an error: {str(e)}"}

    async def guide_booking(
        self,
        user_message: str,
        db: AsyncSession,
        current_user: User,
    ) -> Dict[str, Any]:
        """
        Guide user through the booking process.

        Args:
            user_message: User's message describing what they want
            db: Database session
            current_user: The current logged-in user

        Returns:
            Dict with guidance
        """
        if not self.is_available():
            return {
                "success": False,
                "answer": "AI consultant is not available. Please configure OPENAI_API_KEY.",
            }

        try:
            # Get user's tenant info
            tenant_name = "General"
            if current_user.tenant_id:
                tenant = await db.get(Tenant, current_user.tenant_id)
                if tenant:
                    tenant_name = tenant.name

            # Get user's booking count
            bookings_result = await db.execute(
                select(Booking).where(Booking.user_id == current_user.id)
            )
            user_bookings = bookings_result.scalars().all()

            user_info = f"""Current User Information:
- Name: {current_user.full_name or current_user.username}
- Email: {current_user.email}
- Points: {current_user.points}
- Role: {current_user.role.value if hasattr(current_user.role, 'value') else current_user.role}
- Tenant: {tenant_name}
- Total Bookings: {len(user_bookings)}
- Pending Bookings: {len([b for b in user_bookings if b.status == BookingStatus.PENDING])}
- Confirmed Bookings: {len([b for b in user_bookings if b.status == BookingStatus.CONFIRMED])}"""

            system_prompt = f"""{BOOKING_POLICY}

{user_info}

The user needs help with booking. Guide them through the process step by step.
Ask for any missing information needed (venue, date, time, etc.).
Once you have all info, summarize what they need to do or what API to call.

Current time context: User is seeking help with booking.
"""

            response = self.client.chat.completions.create(
                model="gpt-3.5-turbo",
                messages=[
                    {"role": "system", "content": system_prompt},
                    {"role": "user", "content": user_message},
                ],
                max_tokens=600,
                temperature=0.7,
            )

            answer = response.choices[0].message.content
            return {"success": True, "answer": answer}

        except Exception as e:
            logger.error(f"AI consultant booking guidance error: {e}")
            return {"success": False, "answer": f"Sorry, I encountered an error: {str(e)}"}

    async def check_booking_conflicts(
        self,
        venue_id: int,
        start_time: str,
        end_time: str,
        db: AsyncSession,
    ) -> Dict[str, Any]:
        """
        Check if there are conflicts for a potential booking.

        Args:
            venue_id: The venue ID
            start_time: Start time string
            end_time: End time string
            db: Database session

        Returns:
            Dict with conflict check results
        """
        if not self.is_available():
            return {
                "success": False,
                "answer": "AI consultant is not available. Please configure OPENAI_API_KEY.",
            }

        try:
            # Get venue info
            venue = await db.get(Venue, venue_id)
            venue_info = f"Venue: {venue.name if venue else 'Unknown'}\n"
            if venue:
                venue_info += f"Capacity: {venue.capacity}\n"
                venue_info += f"Location: {venue.location}\n"
                venue_info += f"Available: {venue.available_from} - {venue.available_until}"

            # Check for conflicts
            from datetime import datetime

            start_dt = datetime.fromisoformat(start_time.replace("Z", "+00:00"))
            end_dt = datetime.fromisoformat(end_time.replace("Z", "+00:00"))

            conflicts_result = await db.execute(
                select(Booking).where(
                    and_(
                        Booking.venue_id == venue_id,
                        Booking.status.in_([BookingStatus.CONFIRMED, BookingStatus.PENDING]),
                        Booking.start_time < end_dt,
                        Booking.end_time > start_dt,
                    )
                )
            )
            conflicts = conflicts_result.scalars().all()

            conflict_info = "No conflicts found!" if not conflicts else (
                f"Conflicts with {len(conflicts)} existing booking(s):\n" +
                "\n".join([
                    f"- {c.title}: {c.start_time.strftime('%Y-%m-%d %H:%M')} to {c.end_time.strftime('%H:%M')}"
                    for c in conflicts
                ])
            )

            system_prompt = f"""{BOOKING_POLICY}

BOOKING SLOT TO CHECK:
Venue ID: {venue_id}
{venue_info}
Start Time: {start_time}
End Time: {end_time}

{conflict_info}

Analyze this booking slot and provide advice to the user."""

            response = self.client.chat.completions.create(
                model="gpt-3.5-turbo",
                messages=[
                    {"role": "system", "content": system_prompt},
                    {
                        "role": "user",
                        "content": f"Is this time slot available for booking? Should I proceed?",
                    },
                ],
                max_tokens=400,
                temperature=0.7,
            )

            answer = response.choices[0].message.content
            return {
                "success": True,
                "answer": answer,
                "has_conflicts": len(conflicts) > 0,
                "conflict_count": len(conflicts),
            }

        except Exception as e:
            logger.error(f"AI consultant conflict check error: {e}")
            return {"success": False, "answer": f"Sorry, I encountered an error: {str(e)}"}


# Singleton instance
ai_consultant = AIconsultant()


async def get_ai_consultant() -> AIconsultant:
    """Get AI consultant instance"""
    return ai_consultant
