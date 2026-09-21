import sys
import os
import uuid
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), "../../../ai_model")))

from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from typing import List
from app.db.oracle_db import db_manager
from app.services.fcm_service import fcm_service
from cognitive_evaluator import CognitiveEvaluator

router = APIRouter(prefix="/api/sync", tags=["Data Sync"])
evaluator = CognitiveEvaluator()

class SessionItem(BaseModel):
    session_id: str
    patient_id: str
    game_type: str = "PATTERN_MEMORY"
    level_played: int
    accuracy_rate: float
    avg_reaction_time_ms: float
    error_count: int
    completion_time_sec: float
    consistency_score: float
    session_timestamp: str

class SyncBatchRequest(BaseModel):
    patient_id: str
    sessions: List[SessionItem]

@router.post("/sessions")
def sync_sessions(req: SyncBatchRequest):
    processed_count = 0
    latest_recommended_level = 1
    emergency_alerts = []

    # Get patient's full name for notifications
    u_rows = db_manager.execute_query("SELECT FULL_NAME FROM USERS WHERE USER_ID = ?", (req.patient_id,))
    patient_name = u_rows[0].get("FULL_NAME") or u_rows[0].get("full_name") if u_rows else "Patient"

    for sess in req.sessions:
        # Run Random Forest Model
        eval_res = evaluator.evaluate_session(
            accuracy_rate=sess.accuracy_rate,
            avg_reaction_time_ms=sess.avg_reaction_time_ms,
            error_count=sess.error_count,
            completion_time_sec=sess.completion_time_sec,
            consistency_score=sess.consistency_score,
            level_played=sess.level_played
        )

        cognitive_state = eval_res["cognitive_state"]
        recommended_level = eval_res["recommended_level"]
        latest_recommended_level = recommended_level

        # Insert or replace in Oracle 11g / Server DB
        try:
            db_manager.execute_query(
                """INSERT INTO GAME_SESSIONS 
                   (SESSION_ID, PATIENT_ID, GAME_TYPE, LEVEL_PLAYED, ACCURACY_RATE, 
                    AVG_REACTION_TIME_MS, ERROR_COUNT, COMPLETION_TIME_SEC, 
                    CONSISTENCY_SCORE, COGNITIVE_STATE, RECOMMENDED_LEVEL, SESSION_TIMESTAMP) 
                   VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)""",
                (
                    sess.session_id, sess.patient_id, sess.game_type, sess.level_played,
                    sess.accuracy_rate, sess.avg_reaction_time_ms, sess.error_count,
                    sess.completion_time_sec, sess.consistency_score, cognitive_state,
                    recommended_level, sess.session_timestamp
                )
            )
            processed_count += 1
        except Exception as e:
            # Already synced or error
            pass

        # Handle Emergency / Severe Risk Trigger
        if eval_res["is_emergency"]:
            alert_id = str(uuid.uuid4())
            alert_msg = f"Severe cognitive fatigue or confusion detected. Accuracy dropped to {sess.accuracy_rate*100:.0f}%, reaction latency: {sess.avg_reaction_time_ms:.0f}ms."
            
            db_manager.execute_query(
                """INSERT INTO EMERGENCY_ALERTS (ALERT_ID, PATIENT_ID, ALERT_TYPE, MESSAGE, SEVERITY) 
                   VALUES (?, ?, ?, ?, ?)""",
                (alert_id, sess.patient_id, "SEVERE_COGNITIVE_DECLINE", alert_msg, "CRITICAL")
            )
            emergency_alerts.append(alert_msg)

            # Find linked caregivers to send FCM push notification
            caregiver_rows = db_manager.execute_query(
                """SELECT u.FCM_TOKEN FROM USERS u 
                   JOIN PATIENT_CAREGIVER_MAP m ON u.USER_ID = m.CAREGIVER_ID 
                   WHERE m.PATIENT_ID = ?""",
                (sess.patient_id,)
            )
            for c_row in caregiver_rows:
                token = c_row.get("FCM_TOKEN") or c_row.get("fcm_token")
                if token:
                    fcm_service.send_emergency_alert(
                        caregiver_fcm_token=token,
                        patient_name=patient_name,
                        alert_type="Severe Cognitive Risk",
                        message=alert_msg
                    )

    # Update patient's current difficulty level
    db_manager.execute_query(
        "UPDATE PATIENTS SET CURRENT_DIFFICULTY = ? WHERE PATIENT_ID = ?",
        (latest_recommended_level, req.patient_id)
    )

    return {
        "success": True,
        "processed_count": processed_count,
        "recommended_level": latest_recommended_level,
        "recommended_level_name": {1: "Easy", 2: "Medium", 3: "Hard"}[latest_recommended_level],
        "emergency_triggered": len(emergency_alerts) > 0,
        "alerts": emergency_alerts
    }
