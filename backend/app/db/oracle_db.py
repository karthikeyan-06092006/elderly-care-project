import os
import sqlite3
import oracledb
from app.config import settings

class DatabaseManager:
    def __init__(self):
        self.is_oracle = False
        self.sqlite_path = os.path.join(os.path.dirname(__file__), "server_mirror.db")
        self._init_db()

    def _init_db(self):
        """Attempts Oracle connection; falls back to SQLite mirror if unavailable."""
        try:
            # Try Oracle 11g
            dsn = f"{settings.ORACLE_HOST}:{settings.ORACLE_PORT}/{settings.ORACLE_SERVICE_NAME}"
            # For Oracle 11g, thin mode or thick mode can be used
            conn = oracledb.connect(
                user=settings.ORACLE_USER,
                password=settings.ORACLE_PASSWORD,
                dsn=dsn
            )
            conn.close()
            self.is_oracle = True
            print(f"[DB] Connected to Oracle 11g successfully at {dsn}")
        except Exception as e:
            if settings.USE_SQLITE_FALLBACK:
                self.is_oracle = False
                print(f"[DB] Oracle 11g not available ({e}). Using Local SQLite Mirror for Development at: {self.sqlite_path}")
                self._init_sqlite_schema()
            else:
                raise e

    def _init_sqlite_schema(self):
        conn = sqlite3.connect(self.sqlite_path)
        cursor = conn.cursor()
        cursor.executescript("""
        CREATE TABLE IF NOT EXISTS USERS (
            USER_ID TEXT PRIMARY KEY,
            EMAIL TEXT UNIQUE NOT NULL,
            ROLE TEXT NOT NULL,
            FULL_NAME TEXT,
            PHONE_NUMBER TEXT,
            FCM_TOKEN TEXT,
            CREATED_AT TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        );

        CREATE TABLE IF NOT EXISTS PATIENTS (
            PATIENT_ID TEXT PRIMARY KEY,
            AGE INTEGER,
            DIAGNOSIS_STAGE TEXT,
            CURRENT_DIFFICULTY INTEGER DEFAULT 1,
            EMERGENCY_CONTACT TEXT,
            QR_CODE_TOKEN TEXT UNIQUE,
            FOREIGN KEY (PATIENT_ID) REFERENCES USERS(USER_ID)
        );

        CREATE TABLE IF NOT EXISTS CAREGIVERS (
            CAREGIVER_ID TEXT PRIMARY KEY,
            RELATION_TYPE TEXT,
            FOREIGN KEY (CAREGIVER_ID) REFERENCES USERS(USER_ID)
        );

        CREATE TABLE IF NOT EXISTS PATIENT_CAREGIVER_MAP (
            MAP_ID TEXT PRIMARY KEY,
            PATIENT_ID TEXT NOT NULL,
            CAREGIVER_ID TEXT NOT NULL,
            PAIRED_AT TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (PATIENT_ID) REFERENCES PATIENTS(PATIENT_ID),
            FOREIGN KEY (CAREGIVER_ID) REFERENCES CAREGIVERS(CAREGIVER_ID),
            UNIQUE(PATIENT_ID, CAREGIVER_ID)
        );

        CREATE TABLE IF NOT EXISTS GAME_SESSIONS (
            SESSION_ID TEXT PRIMARY KEY,
            PATIENT_ID TEXT NOT NULL,
            GAME_TYPE TEXT DEFAULT 'PATTERN_MEMORY',
            LEVEL_PLAYED INTEGER NOT NULL,
            ACCURACY_RATE REAL NOT NULL,
            AVG_REACTION_TIME_MS REAL NOT NULL,
            ERROR_COUNT INTEGER NOT NULL,
            COMPLETION_TIME_SEC REAL NOT NULL,
            CONSISTENCY_SCORE REAL NOT NULL,
            COGNITIVE_STATE TEXT NOT NULL,
            RECOMMENDED_LEVEL INTEGER NOT NULL,
            SESSION_TIMESTAMP TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            SYNCED_AT TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (PATIENT_ID) REFERENCES PATIENTS(PATIENT_ID)
        );

        CREATE TABLE IF NOT EXISTS EMERGENCY_ALERTS (
            ALERT_ID TEXT PRIMARY KEY,
            PATIENT_ID TEXT NOT NULL,
            ALERT_TYPE TEXT NOT NULL,
            MESSAGE TEXT NOT NULL,
            SEVERITY TEXT DEFAULT 'HIGH',
            IS_ACKNOWLEDGED INTEGER DEFAULT 0,
            CREATED_AT TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (PATIENT_ID) REFERENCES PATIENTS(PATIENT_ID)
        );

        CREATE TABLE IF NOT EXISTS OTP_VERIFICATIONS (
            EMAIL TEXT PRIMARY KEY,
            OTP_CODE TEXT NOT NULL,
            ROLE TEXT NOT NULL,
            EXPIRES_AT TIMESTAMP NOT NULL,
            CREATED_AT TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        );
        """)
        conn.commit()
        conn.close()

    def get_connection(self):
        if self.is_oracle:
            dsn = f"{settings.ORACLE_HOST}:{settings.ORACLE_PORT}/{settings.ORACLE_SERVICE_NAME}"
            return oracledb.connect(
                user=settings.ORACLE_USER,
                password=settings.ORACLE_PASSWORD,
                dsn=dsn
            )
        else:
            conn = sqlite3.connect(self.sqlite_path)
            conn.row_factory = sqlite3.Row
            return conn

    def execute_query(self, query: str, params: tuple = ()):
        conn = self.get_connection()
        cursor = conn.cursor()
        try:
            cursor.execute(query, params)
            if query.strip().upper().startswith("SELECT"):
                columns = [col[0].upper() for col in cursor.description] if cursor.description else []
                rows = cursor.fetchall()
                if self.is_oracle:
                    return [dict(zip(columns, row)) for row in rows]
                else:
                    return [dict(row) for row in rows]
            else:
                conn.commit()
                return cursor.rowcount
        finally:
            cursor.close()
            conn.close()

db_manager = DatabaseManager()
