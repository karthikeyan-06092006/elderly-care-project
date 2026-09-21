import uuid
import jwt
from datetime import datetime, timedelta
from fastapi import APIRouter, HTTPException, Depends
from pydantic import BaseModel, EmailStr
from typing import Optional
from app.config import settings
from app.db.oracle_db import db_manager
from app.services.otp_service import otp_service

router = APIRouter(prefix="/api/auth", tags=["Authentication"])

class SendOTPRequest(BaseModel):
    email: EmailStr
    role: str  # 'PATIENT' or 'CAREGIVER'

class VerifyOTPRequest(BaseModel):
    email: EmailStr
    otp: str
    full_name: Optional[str] = "User"
    phone_number: Optional[str] = ""
    fcm_token: Optional[str] = ""
    age: Optional[int] = 70
    relation_type: Optional[str] = "Family Caregiver"

class PairCaregiverRequest(BaseModel):
    caregiver_id: str
    qr_code_token: str

@router.post("/send-otp")
def send_otp(req: SendOTPRequest):
    role = req.role.strip().upper()
    if role not in ["PATIENT", "CAREGIVER"]:
        raise HTTPException(status_code=400, detail="Role must be PATIENT or CAREGIVER")
    
    result = otp_service.create_and_send_otp(req.email.lower(), role)
    return result

@router.post("/verify-otp")
def verify_otp(req: VerifyOTPRequest):
    email = req.email.lower()
    res = otp_service.verify_otp(email, req.otp)
    if not res.get("success"):
        raise HTTPException(status_code=400, detail=res.get("message"))

    role = res.get("role")

    # Check if user already exists
    existing = db_manager.execute_query("SELECT * FROM USERS WHERE EMAIL = ?", (email,))
    
    if existing:
        user = existing[0]
        user_id = user.get("USER_ID") or user.get("user_id")
        # Update FCM token / phone if provided
        if req.fcm_token:
            db_manager.execute_query("UPDATE USERS SET FCM_TOKEN = ? WHERE USER_ID = ?", (req.fcm_token, user_id))
    else:
        user_id = str(uuid.uuid4())
        db_manager.execute_query(
            "INSERT INTO USERS (USER_ID, EMAIL, ROLE, FULL_NAME, PHONE_NUMBER, FCM_TOKEN) VALUES (?, ?, ?, ?, ?, ?)",
            (user_id, email, role, req.full_name, req.phone_number, req.fcm_token)
        )

        if role == "PATIENT":
            qr_token = f"PATIENT-{uuid.uuid4().hex[:12].upper()}"
            db_manager.execute_query(
                "INSERT INTO PATIENTS (PATIENT_ID, AGE, DIAGNOSIS_STAGE, CURRENT_DIFFICULTY, EMERGENCY_CONTACT, QR_CODE_TOKEN) VALUES (?, ?, ?, ?, ?, ?)",
                (user_id, req.age, "Early Stage", 1, req.phone_number, qr_token)
            )
        else:
            db_manager.execute_query(
                "INSERT INTO CAREGIVERS (CAREGIVER_ID, RELATION_TYPE) VALUES (?, ?)",
                (user_id, req.relation_type)
            )

    # Fetch patient QR code token if role is patient
    qr_token = None
    if role == "PATIENT":
        p_row = db_manager.execute_query("SELECT QR_CODE_TOKEN FROM PATIENTS WHERE PATIENT_ID = ?", (user_id,))
        if p_row:
            qr_token = p_row[0].get("QR_CODE_TOKEN") or p_row[0].get("qr_code_token")

    # Create JWT Token
    token_payload = {
        "user_id": user_id,
        "email": email,
        "role": role,
        "exp": datetime.utcnow() + timedelta(days=30)
    }
    jwt_token = jwt.encode(token_payload, settings.JWT_SECRET, algorithm=settings.JWT_ALGORITHM)

    return {
        "success": True,
        "token": jwt_token,
        "user_id": user_id,
        "email": email,
        "role": role,
        "full_name": req.full_name,
        "qr_code_token": qr_token
    }

@router.post("/pair-caregiver")
def pair_caregiver(req: PairCaregiverRequest):
    # Find patient by qr_code_token
    p_rows = db_manager.execute_query("SELECT * FROM PATIENTS WHERE QR_CODE_TOKEN = ?", (req.qr_code_token,))
    if not p_rows:
        raise HTTPException(status_code=404, detail="Invalid QR code. Patient not found.")
    
    patient = p_rows[0]
    patient_id = patient.get("PATIENT_ID") or patient.get("patient_id")

    # Fetch patient user details
    u_rows = db_manager.execute_query("SELECT * FROM USERS WHERE USER_ID = ?", (patient_id,))
    patient_name = u_rows[0].get("FULL_NAME") or u_rows[0].get("full_name") if u_rows else "Patient"

    map_id = str(uuid.uuid4())
    try:
        db_manager.execute_query(
            "INSERT INTO PATIENT_CAREGIVER_MAP (MAP_ID, PATIENT_ID, CAREGIVER_ID) VALUES (?, ?, ?)",
            (map_id, patient_id, req.caregiver_id)
        )
    except Exception as e:
        # Already paired
        pass

    return {
        "success": True,
        "message": f"Successfully linked as caregiver for {patient_name}",
        "patient_id": patient_id,
        "patient_name": patient_name
    }

@router.get("/patient-profile/{patient_id}")
def get_patient_profile(patient_id: str):
    rows = db_manager.execute_query(
        """SELECT u.USER_ID, u.EMAIL, u.FULL_NAME, u.PHONE_NUMBER, 
                  p.AGE, p.DIAGNOSIS_STAGE, p.CURRENT_DIFFICULTY, p.QR_CODE_TOKEN
           FROM USERS u JOIN PATIENTS p ON u.USER_ID = p.PATIENT_ID
           WHERE u.USER_ID = ?""",
        (patient_id,)
    )
    if not rows:
        raise HTTPException(status_code=404, detail="Patient profile not found")
    return rows[0]
