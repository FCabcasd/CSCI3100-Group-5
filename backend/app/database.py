from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

DATABASE_URL = "postgresql://postgres:Quo/*-+123@localhost/booking_db"

engine = create_engine(DATABASE_URL)
SessionLocal = sessionmaker(bind=engine)