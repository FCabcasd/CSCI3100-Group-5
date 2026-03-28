from sqlalchemy import Column, Integer, String, ForeignKey
from .base import Base

class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    email = Column(String, unique=True)
    role = Column(String)
    department_id = Column(Integer, ForeignKey("departments.id"))