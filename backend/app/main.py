from fastapi import FastAPI

from app.database import engine
from app.models.base import Base

import app.models

app = FastAPI()

Base.metadata.create_all(bind=engine)


@app.get("/")
def root():
    return {"message": "Hello World"}