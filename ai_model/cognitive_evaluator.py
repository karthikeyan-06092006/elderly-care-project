import os
import joblib
import pandas as pd
import numpy as np

class CognitiveEvaluator:
    def __init__(self, model_path=None):
        if model_path is None:
            base_dir = os.path.dirname(os.path.abspath(__file__))
            model_path = os.path.join(base_dir, "cognitive_rf_model.pkl")
        
        self.model = joblib.load(model_path)
        self.class_names = {0: "Normal", 1: "Mild Cognitive Decline", 2: "Severe Risk"}
        self.feature_names = ['accuracy_rate', 'avg_reaction_time_ms', 'error_count', 
                              'completion_time_sec', 'consistency_score', 'level_played']

    def evaluate_session(self, accuracy_rate: float, avg_reaction_time_ms: float, 
                         error_count: int, completion_time_sec: float, 
                         consistency_score: float, level_played: int):
        """
        Runs Random Forest inference on a single session's telemetry metrics.
        Returns:
            - state: "Normal" | "Mild Cognitive Decline" | "Severe Risk"
            - state_id: 0 | 1 | 2
            - probabilities: dict of class probabilities
            - recommended_level: 1 (Easy), 2 (Medium), 3 (Hard)
            - is_emergency: bool (True if severe risk or extreme anomaly)
        """
        data = pd.DataFrame([{
            'accuracy_rate': float(accuracy_rate),
            'avg_reaction_time_ms': float(avg_reaction_time_ms),
            'error_count': int(error_count),
            'completion_time_sec': float(completion_time_sec),
            'consistency_score': float(consistency_score),
            'level_played': int(level_played)
        }])

        pred_class = int(self.model.predict(data)[0])
        probs = self.model.predict_proba(data)[0]

        prob_dict = {
            self.class_names[i]: round(float(probs[i]), 4)
            for i in range(len(self.class_names))
        }

        # Adaptive Difficulty Logic
        if pred_class == 0 and accuracy_rate >= 0.80:
            recommended_level = min(3, level_played + 1)
        elif pred_class == 2 or accuracy_rate < 0.45:
            recommended_level = max(1, level_played - 1)
        else:
            recommended_level = level_played

        # Emergency Trigger Criteria:
        # 1. Classified as Severe Risk
        # 2. Accuracy < 30% with Reaction Time > 3500ms
        is_emergency = (pred_class == 2) or (accuracy_rate < 0.30 and avg_reaction_time_ms > 3500)

        return {
            "cognitive_state": self.class_names[pred_class],
            "state_id": pred_class,
            "probabilities": prob_dict,
            "recommended_level": recommended_level,
            "recommended_level_name": {1: "Easy", 2: "Medium", 3: "Hard"}[recommended_level],
            "is_emergency": is_emergency
        }

if __name__ == "__main__":
    evaluator = CognitiveEvaluator()
    # Test Normal
    print("Normal test:", evaluator.evaluate_session(0.90, 850, 1, 22.0, 0.92, 2))
    # Test Mild
    print("Mild test:", evaluator.evaluate_session(0.65, 1750, 4, 52.0, 0.65, 2))
    # Test Severe
    print("Severe test:", evaluator.evaluate_session(0.25, 3400, 10, 110.0, 0.30, 2))
