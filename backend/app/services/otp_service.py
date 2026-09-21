import random
import string
import smtplib
from email.mime.text import MIMEText
from datetime import datetime, timedelta
from app.config import settings
from app.db.oracle_db import db_manager

class OTPService:
    @staticmethod
    def generate_otp(length=6) -> str:
        return ''.join(random.choices(string.digits, k=length))

    @classmethod
    def create_and_send_otp(cls, email: str, role: str) -> dict:
        otp = cls.generate_otp()
        expires_at = (datetime.utcnow() + timedelta(minutes=10)).strftime("%Y-%m-%d %H:%M:%S")

        # Save to DB (replace or insert)
        db_manager.execute_query(
            "DELETE FROM OTP_VERIFICATIONS WHERE EMAIL = ?",
            (email,)
        )
        db_manager.execute_query(
            "INSERT INTO OTP_VERIFICATIONS (EMAIL, OTP_CODE, ROLE, EXPIRES_AT) VALUES (?, ?, ?, ?)",
            (email, otp, role.upper(), expires_at)
        )

        sent = False
        if settings.SMTP_USER and settings.SMTP_PASSWORD:
            try:
                msg = MIMEText(f"Your Elderly Care Cognitive Support OTP verification code is: {otp}\n\nThis code expires in 10 minutes.")
                msg['Subject'] = 'Your Elderly Care Verification Code'
                msg['From'] = settings.SMTP_USER
                msg['To'] = email

                with smtplib.SMTP(settings.SMTP_HOST, settings.SMTP_PORT) as server:
                    server.starttls()
                    server.login(settings.SMTP_USER, settings.SMTP_PASSWORD)
                    server.sendmail(settings.SMTP_USER, [email], msg.as_string())
                sent = True
            except Exception as e:
                print(f"[OTP] SMTP send failed: {e}")

        # In debug / mock mode, always log to console
        print(f"\n==========================================")
        print(f" [OTP DISPATCH] Email: {email} | Role: {role}")
        print(f" [OTP CODE]: >>> {otp} <<< (Expires in 10 mins)")
        print(f"==========================================\n")

        return {
            "success": True,
            "message": "OTP generated and sent",
            "email": email,
            "debug_otp": otp if settings.MOCK_OTP else None
        }

    @classmethod
    def verify_otp(cls, email: str, otp: str) -> dict:
        rows = db_manager.execute_query(
            "SELECT * FROM OTP_VERIFICATIONS WHERE EMAIL = ? AND OTP_CODE = ?",
            (email, otp.strip())
        )
        if not rows:
            return {"success": False, "message": "Invalid OTP code"}

        record = rows[0]
        # Normalize key names for SQLite/Oracle
        expires_at_val = record.get("EXPIRES_AT") or record.get("expires_at")
        role_val = record.get("ROLE") or record.get("role")

        if isinstance(expires_at_val, str):
            exp_time = datetime.strptime(expires_at_val, "%Y-%m-%d %H:%M:%S")
        else:
            exp_time = expires_at_val

        if datetime.utcnow() > exp_time:
            return {"success": False, "message": "OTP has expired. Please request a new one."}

        # Clear verified OTP
        db_manager.execute_query("DELETE FROM OTP_VERIFICATIONS WHERE EMAIL = ?", (email,))

        return {
            "success": True,
            "email": email,
            "role": role_val
        }

otp_service = OTPService()
