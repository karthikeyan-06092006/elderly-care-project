import sys
import os
# Force UTF-8 stdout
sys.stdout.reconfigure(encoding='utf-8')

from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)

def run_e2e_tests():
    print("\n--- 1. Testing Root Endpoint ---")
    res = client.get("/")
    assert res.status_code == 200, f"Root failed: {res.text}"
    print(" Root status:", res.json())

    print("\n--- 2. Testing Patient Auth (Send OTP + Verify) ---")
    otp_req = client.post("/api/auth/send-otp", json={"email": "patient@example.com", "role": "PATIENT"})
    assert otp_req.status_code == 200, f"Send OTP failed: {otp_req.text}"
    debug_otp = otp_req.json().get("debug_otp")
    print(f" OTP Sent! Generated OTP: {debug_otp}")

    verify_req = client.post("/api/auth/verify-otp", json={
        "email": "patient@example.com",
        "otp": debug_otp,
        "full_name": "Amina Begum",
        "phone_number": "+919876543210",
        "age": 74
    })
    assert verify_req.status_code == 200, f"Verify OTP failed: {verify_req.text}"
    patient_auth = verify_req.json()
    patient_id = patient_auth["user_id"]
    qr_token = patient_auth["qr_code_token"]
    print(f" Patient Logged In! Patient ID: {patient_id} | QR Token: {qr_token}")

    print("\n--- 3. Testing Caregiver Auth & QR Pairing ---")
    c_otp_req = client.post("/api/auth/send-otp", json={"email": "caregiver@example.com", "role": "CAREGIVER"})
    c_debug_otp = c_otp_req.json().get("debug_otp")

    c_verify_req = client.post("/api/auth/verify-otp", json={
        "email": "caregiver@example.com",
        "otp": c_debug_otp,
        "full_name": "Rahim Khan",
        "relation_type": "Son"
    })
    caregiver_id = c_verify_req.json()["user_id"]
    print(f" Caregiver Logged In! Caregiver ID: {caregiver_id}")

    pair_req = client.post("/api/auth/pair-caregiver", json={
        "caregiver_id": caregiver_id,
        "qr_code_token": qr_token
    })
    assert pair_req.status_code == 200, f"Pairing failed: {pair_req.text}"
    print(" QR Code Scanned & Paired:", pair_req.json())

    print("\n--- 4. Testing Offline Sync & Random Forest Assessment ---")
    sync_payload = {
        "patient_id": patient_id,
        "sessions": [
            {
                "session_id": "sess-001",
                "patient_id": patient_id,
                "game_type": "PATTERN_MEMORY",
                "level_played": 1,
                "accuracy_rate": 0.88,
                "avg_reaction_time_ms": 920.5,
                "error_count": 1,
                "completion_time_sec": 24.0,
                "consistency_score": 0.90,
                "session_timestamp": "2026-09-19 00:10:00"
            },
            {
                "session_id": "sess-002",
                "patient_id": patient_id,
                "game_type": "PATTERN_MEMORY",
                "level_played": 2,
                "accuracy_rate": 0.30,
                "avg_reaction_time_ms": 3600.0,
                "error_count": 9,
                "completion_time_sec": 95.0,
                "consistency_score": 0.35,
                "session_timestamp": "2026-09-19 00:15:00"
            }
        ]
    }
    sync_res = client.post("/api/sync/sessions", json=sync_payload)
    assert sync_res.status_code == 200, f"Sync failed: {sync_res.text}"
    print(" Sync & ML Evaluation Result:", sync_res.json())

    print("\n--- 5. Testing Caregiver Dashboard Queries ---")
    dash_res = client.get(f"/api/caregiver/dashboard/{patient_id}")
    assert dash_res.status_code == 200, f"Dashboard failed: {dash_res.text}"
    dash_data = dash_res.json()
    print(" Caregiver Dashboard Summary:", dash_data["summary"])
    print(f" Total Sessions: {len(dash_data['recent_sessions'])} | Alerts Count: {len(dash_data['recent_alerts'])}")

    print("\n--- 6. Testing Bilingual AI Companion (English & Bengali) ---")
    chat_en = client.post("/api/ai/chat", json={
        "messages": [{"role": "user", "content": "Hello, I feel a bit forgetful today."}],
        "language": "en"
    })
    print(" English AI Response:", chat_en.json())

    chat_bn = client.post("/api/ai/chat", json={
        "messages": [{"role": "user", "content": "হ্যালো, আমার আজ ভালো লাগছে না।"}],
        "language": "bn"
    })
    print(" Bengali AI Response:", chat_bn.json())

    print("\n==========================================")
    print(" ALL BACKEND E2E TESTS PASSED SUCCESSFULLY!")
    print("==========================================\n")

if __name__ == "__main__":
    run_e2e_tests()
