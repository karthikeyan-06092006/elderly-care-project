from fastapi import APIRouter, HTTPException
from typing import Optional
from app.db.oracle_db import db_manager

router = APIRouter(prefix="/api/caregiver", tags=["Caregiver Dashboard"])

@router.get("/patients/{caregiver_id}")
def get_linked_patients(caregiver_id: str):
    rows = db_manager.execute_query(
        """SELECT p.PATIENT_ID, u.FULL_NAME, u.EMAIL, u.PHONE_NUMBER, 
                  p.AGE, p.DIAGNOSIS_STAGE, p.CURRENT_DIFFICULTY, m.PAIRED_AT
           FROM PATIENT_CAREGIVER_MAP m
           JOIN PATIENTS p ON m.PATIENT_ID = p.PATIENT_ID
           JOIN USERS u ON p.PATIENT_ID = u.USER_ID
           WHERE m.CAREGIVER_ID = ?""",
        (caregiver_id,)
    )
    return rows

@router.get("/dashboard/{patient_id}")
def get_patient_dashboard(patient_id: str):
    # 1. Patient Profile
    p_rows = db_manager.execute_query(
        """SELECT u.USER_ID, u.FULL_NAME, u.EMAIL, u.PHONE_NUMBER, 
                  p.AGE, p.DIAGNOSIS_STAGE, p.CURRENT_DIFFICULTY, p.EMERGENCY_CONTACT
           FROM USERS u JOIN PATIENTS p ON u.USER_ID = p.PATIENT_ID
           WHERE u.USER_ID = ?""",
        (patient_id,)
    )
    if not p_rows:
        raise HTTPException(status_code=404, detail="Patient not found")
    patient = p_rows[0]

    # 2. Recent Game Sessions (last 20)
    sessions = db_manager.execute_query(
        """SELECT SESSION_ID, GAME_TYPE, LEVEL_PLAYED, ACCURACY_RATE, 
                  AVG_REACTION_TIME_MS, ERROR_COUNT, COMPLETION_TIME_SEC, 
                  COGNITIVE_STATE, SESSION_TIMESTAMP
           FROM GAME_SESSIONS
           WHERE PATIENT_ID = ?
           ORDER BY SESSION_TIMESTAMP DESC
           LIMIT 20""",
        (patient_id,)
    )

    # 3. Emergency Alerts
    alerts = db_manager.execute_query(
        """SELECT ALERT_ID, ALERT_TYPE, MESSAGE, SEVERITY, IS_ACKNOWLEDGED, CREATED_AT
           FROM EMERGENCY_ALERTS
           WHERE PATIENT_ID = ?
           ORDER BY CREATED_AT DESC
           LIMIT 10""",
        (patient_id,)
    )

    # 4. Summary Metrics
    total_played = len(sessions)
    if total_played > 0:
        avg_acc = sum((s.get("ACCURACY_RATE") or s.get("accuracy_rate") or 0.0) for s in sessions) / total_played
        avg_lat = sum((s.get("AVG_REACTION_TIME_MS") or s.get("avg_reaction_time_ms") or 0.0) for s in sessions) / total_played
        latest_state = (sessions[0].get("COGNITIVE_STATE") or sessions[0].get("cognitive_state") or "Normal")
    else:
        avg_acc = 0.0
        avg_lat = 0.0
        latest_state = "No sessions yet"

    return {
        "patient": patient,
        "summary": {
            "total_sessions": total_played,
            "average_accuracy": round(avg_acc * 100, 1),
            "average_reaction_time_ms": round(avg_lat, 0),
            "current_cognitive_state": latest_state,
            "current_difficulty": patient.get("CURRENT_DIFFICULTY") or patient.get("current_difficulty") or 1
        },
        "recent_sessions": sessions,
        "recent_alerts": alerts
    }

@router.post("/acknowledge-alert/{alert_id}")
def acknowledge_alert(alert_id: str):
    db_manager.execute_query(
        "UPDATE EMERGENCY_ALERTS SET IS_ACKNOWLEDGED = 1 WHERE ALERT_ID = ?",
        (alert_id,)
    )
    return {"success": True, "message": "Alert acknowledged"}
