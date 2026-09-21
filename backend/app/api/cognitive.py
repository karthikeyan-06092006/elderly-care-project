import sys
import os
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), "../../../ai_model")))

from fastapi import APIRouter
from pydantic import BaseModel
from cognitive_evaluator import CognitiveEvaluator

router = APIRouter(prefix="/api/cognitive", tags=["Cognitive AI"])
evaluator = CognitiveEvaluator()

class TelemetryEvalRequest(BaseModel):
    accuracy_rate: float
    avg_reaction_time_ms: float
    error_count: int
    completion_time_sec: float
    consistency_score: float
    level_played: int = 1

@router.post("/evaluate")
def evaluate_telemetry(req: TelemetryEvalRequest):
    result = evaluator.evaluate_session(
        accuracy_rate=req.accuracy_rate,
        avg_reaction_time_ms=req.avg_reaction_time_ms,
        error_count=req.error_count,
        completion_time_sec=req.completion_time_sec,
        consistency_score=req.consistency_score,
        level_played=req.level_played
    )
    return result
