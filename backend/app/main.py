from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.config import settings
from app.api.auth import router as auth_router
from app.api.sync import router as sync_router
from app.api.cognitive import router as cognitive_router
from app.api.caregiver import router as caregiver_router
from app.api.ai_chat import router as ai_chat_router

app = FastAPI(
    title="AI-Based Cognitive Support Backend",
    description="Backend API for Elderly Dementia Patients Cognitive System with Random Forest ML, Oracle 11g, Groq LLM, and FCM Alerting.",
    version="1.0.0"
)

# Enable CORS for Flutter Mobile Client
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include API Routers
app.include_router(auth_router)
app.include_router(sync_router)
app.include_router(cognitive_router)
app.include_router(caregiver_router)
app.include_router(ai_chat_router)

@app.get("/")
def root():
    return {
        "status": "online",
        "service": settings.APP_NAME,
        "oracle_db": "connected" if not settings.USE_SQLITE_FALLBACK else "local_mirror_active",
        "version": "1.0.0"
    }

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("app.main:app", host="0.0.0.0", port=settings.APP_PORT, reload=settings.DEBUG)
