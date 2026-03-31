from sqlalchemy import Column, Integer, String, ForeignKey, DateTime
from datetime import datetime

from app.models.base import Base


class Waitlist(Base):
    __tablename__ = "waitlists"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    resource_id = Column(Integer, ForeignKey("resources.id"))
    created_at = Column(DateTime, default=datetime.utcnow)