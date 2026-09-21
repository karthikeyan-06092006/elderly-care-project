import numpy as np
import pandas as pd
from sklearn.ensemble import RandomForestClassifier
from sklearn.model_selection import train_test_split
from sklearn.metrics import classification_report, accuracy_score
import joblib
import os

# Set seed for reproducibility
np.random.seed(42)

def generate_synthetic_data(n_samples=3000):
    """
    Generates synthetic cognitive game telemetry data representing:
    - 0: Normal Cognitive State
    - 1: Mild Cognitive Decline (MCD)
    - 2: Severe Risk
    """
    # 1. Normal (Class 0) ~40%
    n_normal = int(n_samples * 0.40)
    acc_norm = np.random.uniform(0.75, 1.00, n_normal)
    reaction_norm = np.random.normal(900, 200, n_normal).clip(400, 1600)
    errors_norm = np.random.poisson(1.2, n_normal).clip(0, 4)
    completion_norm = np.random.normal(25, 6, n_normal).clip(10, 45)
    consistency_norm = np.random.uniform(0.80, 0.98, n_normal)
    level_norm = np.random.choice([1, 2, 3], size=n_normal, p=[0.2, 0.4, 0.4])
    labels_norm = np.zeros(n_normal, dtype=int)

    # 2. Mild Cognitive Decline (Class 1) ~35%
    n_mild = int(n_samples * 0.35)
    acc_mild = np.random.uniform(0.45, 0.78, n_mild)
    reaction_mild = np.random.normal(1800, 350, n_mild).clip(1200, 2800)
    errors_mild = np.random.poisson(4.5, n_mild).clip(2, 9)
    completion_mild = np.random.normal(55, 12, n_mild).clip(30, 90)
    consistency_mild = np.random.uniform(0.50, 0.80, n_mild)
    level_mild = np.random.choice([1, 2, 3], size=n_mild, p=[0.4, 0.4, 0.2])
    labels_mild = np.ones(n_mild, dtype=int)

    # 3. Severe Risk (Class 2) ~25%
    n_severe = n_samples - n_normal - n_mild
    acc_severe = np.random.uniform(0.10, 0.50, n_severe)
    reaction_severe = np.random.normal(3200, 500, n_severe).clip(2200, 5000)
    errors_severe = np.random.poisson(9.0, n_severe).clip(5, 18)
    completion_severe = np.random.normal(100, 20, n_severe).clip(60, 180)
    consistency_severe = np.random.uniform(0.15, 0.55, n_severe)
    level_severe = np.random.choice([1, 2, 3], size=n_severe, p=[0.7, 0.2, 0.1])
    labels_severe = np.full(n_severe, 2, dtype=int)

    # Combine
    df = pd.DataFrame({
        'accuracy_rate': np.concatenate([acc_norm, acc_mild, acc_severe]),
        'avg_reaction_time_ms': np.concatenate([reaction_norm, reaction_mild, reaction_severe]),
        'error_count': np.concatenate([errors_norm, errors_mild, errors_severe]),
        'completion_time_sec': np.concatenate([completion_norm, completion_mild, completion_severe]),
        'consistency_score': np.concatenate([consistency_norm, consistency_mild, consistency_severe]),
        'level_played': np.concatenate([level_norm, level_mild, level_severe]),
        'cognitive_state': np.concatenate([labels_norm, labels_mild, labels_severe])
    })

    return df.sample(frac=1.0, random_state=42).reset_index(drop=True)

def train_and_save_model():
    print("Generating cognitive telemetry dataset...")
    df = generate_synthetic_data(n_samples=5000)

    feature_cols = ['accuracy_rate', 'avg_reaction_time_ms', 'error_count', 
                    'completion_time_sec', 'consistency_score', 'level_played']
    X = df[feature_cols]
    y = df['cognitive_state']

    X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42, stratify=y)

    print("Training Random Forest Classifier...")
    model = RandomForestClassifier(
        n_estimators=120,
        max_depth=10,
        min_samples_split=4,
        random_state=42,
        class_weight='balanced'
    )
    model.fit(X_train, y_train)

    y_pred = model.predict(X_test)
    acc = accuracy_score(y_test, y_pred)
    print(f"Model Training Accuracy: {acc * 100:.2f}%\n")
    print("Classification Report:")
    print(classification_report(y_test, y_pred, target_names=['Normal', 'Mild Decline', 'Severe Risk']))

    # Feature Importance
    print("Feature Importances:")
    for feat, imp in zip(feature_cols, model.feature_importances_):
        print(f"  - {feat}: {imp:.4f}")

    # Output Directory
    out_dir = os.path.dirname(os.path.abspath(__file__))
    model_path = os.path.join(out_dir, "cognitive_rf_model.pkl")
    dataset_path = os.path.join(out_dir, "cognitive_telemetry_dataset.csv")

    df.to_csv(dataset_path, index=False)
    joblib.dump(model, model_path)
    print(f"\n[OK] Model saved to: {model_path}")
    print(f"[OK] Dataset saved to: {dataset_path}")

if __name__ == "__main__":
    train_and_save_model()
