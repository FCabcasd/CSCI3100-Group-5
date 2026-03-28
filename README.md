# CSCI3100-Group-5
26-27 CSCI3100 group5


Backend Setup (FastAPI)
1. Requirements
Install PostgreSQL

2. Clone Repository
git clone https://github.com/FCabcasd/CSCI3100-Group-5
cd backend

3. Create Virtual Environment
python -m venv venv

Activate:

Windows
venv\Scripts\activate

Mac/Linux
source venv/bin/activate

4. Install Dependencies
pip install -r requirements.txt

5. Setup PostgreSQL Database

Login to PostgreSQL:
psql -U postgres

Create database:
CREATE DATABASE booking_db;

6. Configure Database Connection

Edit app/database.py:
DATABASE_URL = "postgresql://postgres:<YOUR_PASSWORD>@localhost/booking_db"
(Currently, I have left my password in database.py, which is bad practice
This should probably be inside a .env file? I'm not sure how it works)

7. Run Server
uvicorn app.main:app --reload

Open in browser:
http://127.0.0.1:8000
http://127.0.0.1:8000/docs

8. Run Tests
pytest

Project Structure
backend/
├── app/
│   ├── main.py
│   ├── database.py
│   ├── models/
│   └── ...
├── tests/
├── requirements.txt

Data will be accessed through department_id
