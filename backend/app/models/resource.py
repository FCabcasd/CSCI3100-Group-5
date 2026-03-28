from sqlalchemy import Column, Integer, String, ForeignKey
from .base import Base

class Resource(Base):
    __tablename__ = "resources"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String)
    type = Column(String)
    department_id = Column(Integer, ForeignKey("departments.id"))