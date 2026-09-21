import os
from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    # App
    APP_NAME: str = "CognitiveSupportBackend"
    APP_PORT: int = 8000
    DEBUG: bool = True
    JWT_SECRET: str = "elderly_care_super_secret_jwt_key_2026"
    JWT_ALGORITHM: str = "HS256"

    # Oracle 11g
    ORACLE_USER: str = os.getenv("ORACLE_USER", "system")
    ORACLE_PASSWORD: str = os.getenv("ORACLE_PASSWORD", "oracle")
    ORACLE_HOST: str = os.getenv("ORACLE_HOST", "localhost")
    ORACLE_PORT: int = int(os.getenv("ORACLE_PORT", "1521"))
    ORACLE_SERVICE_NAME: str = os.getenv("ORACLE_SERVICE_NAME", "xe")
    USE_SQLITE_FALLBACK: bool = True  # Allows offline/local dev when Oracle is unreachable

    # Groq API
    GROQ_API_KEY: str = os.getenv("GROQ_API_KEY", "")

    # Firebase Admin (FCM)
    FIREBASE_CREDENTIALS_PATH: str = os.getenv("FIREBASE_CREDENTIALS_PATH", "")

    # SMTP for OTP
    SMTP_HOST: str = os.getenv("SMTP_HOST", "smtp.gmail.com")
    SMTP_PORT: int = int(os.getenv("SMTP_PORT", "587"))
    SMTP_USER: str = os.getenv("SMTP_USER", "")
    SMTP_PASSWORD: str = os.getenv("SMTP_PASSWORD", "")
    MOCK_OTP: bool = True  # When true, logs OTP to console and returns in debug mode

    class Config:
        env_file = ".env"

settings = Settings()
