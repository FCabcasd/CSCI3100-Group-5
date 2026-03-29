from fastapi import FastAPI

from app.database import engine
from app.models.base import Base
from app.routes import booking
import app.models

app = FastAPI()
app.include_router(booking.router)

Base.metadata.create_all(bind=engine)


@app.get("/")
def root():
    return {"message": "Hello World"}