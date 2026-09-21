import os
import firebase_admin
from firebase_admin import credentials, messaging
from app.config import settings
from app.db.oracle_db import db_manager

class FCMNotificationService:
    def __init__(self):
        self.initialized = False
        self._init_firebase()

    def _init_firebase(self):
        if settings.FIREBASE_CREDENTIALS_PATH and os.path.exists(settings.FIREBASE_CREDENTIALS_PATH):
            try:
                cred = credentials.Certificate(settings.FIREBASE_CREDENTIALS_PATH)
                firebase_admin.initialize_app(cred)
                self.initialized = True
                print("[FCM] Firebase Admin SDK initialized successfully.")
            except Exception as e:
                print(f"[FCM] Firebase initialization failed: {e}")
        else:
            print("[FCM] Running in simulated notification mode (No service account file specified).")

    def send_emergency_alert(self, caregiver_fcm_token: str, patient_name: str, 
                             alert_type: str, message: str) -> bool:
        """Sends an urgent push alert to the caregiver's device."""
        print(f"\n🚨 [EMERGENCY ALERT TO CAREGIVER]")
        print(f"   Target FCM Token: {caregiver_fcm_token[:20]}...")
        print(f"   Patient: {patient_name}")
        print(f"   Alert: {alert_type} - {message}\n")

        if not self.initialized or not caregiver_fcm_token:
            return True  # Handled / simulated

        try:
            msg = messaging.Message(
                notification=messaging.Notification(
                    title=f"🚨 Emergency Alert: {patient_name}",
                    body=message
                ),
                data={
                    "alert_type": alert_type,
                    "patient_name": patient_name,
                    "click_action": "FLUTTER_NOTIFICATION_CLICK"
                },
                token=caregiver_fcm_token,
                android=messaging.AndroidConfig(
                    priority="high",
                    notification=messaging.AndroidNotification(
                        sound="default",
                        channel_id="emergency_alerts"
                    )
                )
            )
            response = messaging.send(msg)
            print(f"[FCM] Message sent successfully: {response}")
            return True
        except Exception as e:
            print(f"[FCM] Failed to send push message: {e}")
            return False

fcm_service = FCMNotificationService()
