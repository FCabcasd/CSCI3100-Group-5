"""API routes for AI consultation assistant"""

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from typing import Optional
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.auth import get_current_user
from app.models import User
from app.utils.ai_consultant import ai_consultant

router = APIRouter(prefix="/api/ai", tags=["ai"])


class QuestionRequest(BaseModel):
    """Question about booking policy"""
    question: str


class VenueRecommendationRequest(BaseModel):
    """Venue recommendation request"""
    requirements: str


class BookingGuidanceRequest(BaseModel):
    """Booking guidance request"""
    message: str


class ConflictCheckRequest(BaseModel):
    """Check booking conflicts"""
    venue_id: int
    start_time: str
    end_time: str


class AIResponse(BaseModel):
    """AI response model"""
    success: bool
    answer: str
    venues_found: Optional[int] = None
    has_conflicts: Optional[bool] = None
    conflict_count: Optional[int] = None


@router.post("/ask", response_model=AIResponse)
async def ask_question(
    request: QuestionRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """
    Ask a question about booking policies.

    The AI will answer based on the system's booking rules.
    """
    user_context = {
        "name": current_user.full_name or current_user.username,
        "points": current_user.points,
        "role": current_user.role.value if hasattr(current_user.role, "value") else current_user.role,
    }

    result = await ai_consultant.answer_question(
        question=request.question,
        user_context=user_context,
    )

    return AIResponse(**result)


@router.post("/recommend-venues", response_model=AIResponse)
async def recommend_venues(
    request: VenueRecommendationRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """
    Get venue recommendations based on requirements.

    Example: "I need a room for 30 people with a projector"
    """
    result = await ai_consultant.recommend_venues(
        requirements=request.requirements,
        db=db,
        tenant_id=current_user.tenant_id,
    )

    return AIResponse(
        success=result["success"],
        answer=result["answer"],
        venues_found=result.get("venues_found"),
    )


@router.post("/guide-booking", response_model=AIResponse)
async def guide_booking(
    request: BookingGuidanceRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """
    Get guided help for the booking process.

    The AI will help users step by step to complete their booking.
    """
    result = await ai_consultant.guide_booking(
        user_message=request.message,
        db=db,
        current_user=current_user,
    )

    return AIResponse(**result)


@router.post("/check-conflicts", response_model=AIResponse)
async def check_booking_conflicts(
    request: ConflictCheckRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """
    Check if a proposed booking time has conflicts.

    Returns AI analysis of the booking slot.
    """
    result = await ai_consultant.check_booking_conflicts(
        venue_id=request.venue_id,
        start_time=request.start_time,
        end_time=request.end_time,
        db=db,
    )

    return AIResponse(
        success=result["success"],
        answer=result["answer"],
        has_conflicts=result.get("has_conflicts"),
        conflict_count=result.get("conflict_count"),
    )


@router.get("/status")
async def ai_status():
    """
    Check if AI consultant is available and configured.
    """
    available = ai_consultant.is_available()
    return {
        "available": available,
        "message": "AI consultant is ready" if available else "Please configure OPENAI_API_KEY",
    }
