# CSCI3100-Group-5

## Backend Setup (FastAPI)

### 1. Requirements
- Install PostgreSQL

### 2. Clone Repository
```bash
git clone https://github.com/FCabcasd/CSCI3100-Group-5  
cd backend
```

### 3. Create Virtual Environment  
```bash
python -m venv venv
```
### To activate:

Windows  
```bash
venv\Scripts\activate
```
Mac/Linux  
```bash
source venv/bin/activate
```
### 4. Install Dependencies  
```bash
pip install -r requirements.txt
```
### 5. Setup PostgreSQL Database  

Login to PostgreSQL:  
```bash
psql -U postgres
```
Create database:  
```bash
CREATE DATABASE booking_db;
```
### 6. Configure Database Connection  

Edit app/database.py:  
```bash
DATABASE_URL = "postgresql://postgres:<YOUR_PASSWORD>@localhost/booking_db"
```
Note:  
The password is currently hardcoded,  
it should be moved to a .env file later but I'm not sure how.

### 7. Run Server  
```bash
uvicorn app.main:app --reload
```
Open in browser:  
```bash
http://127.0.0.1:8000  
http://127.0.0.1:8000/docs
```
### 8. Run Tests  
```bash
pytest
```

## Project Structure  

backend/  
├── app/  
│   ├── main.py  
│   ├── database.py  
│   ├── models/  
│   └── ...  
├── tests/  
├── requirements.txt  

Data will be accessed through department_id
