import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/services/ml_difficulty_service.dart';

void main() {
  group('Offline Random Forest Dynamic Difficulty ML Tests', () {
    test('High Performing Patient (Sharp Recall) -> Predicts Upgrade (Medium/Hard)', () {
      final performance = GamePerformanceData(
        score: 95.0,
        completionTimeSeconds: 16.0,
        accuracyPercentage: 100.0,
        mistakesCount: 0,
        currentLevel: 0, // Easy
      );

      final result = MlDifficultyService.predictNextDifficulty(performance);

      expect(result.recommendedLevelIndex, greaterThanOrEqualTo(1));
      expect(result.confidence, greaterThan(0.5));
      expect(result.messageEn.contains('AI recommends'), isTrue);
    });

    test('Struggling / Fatigued Patient -> Predicts Downgrade / Stay Easy', () {
      final performance = GamePerformanceData(
        score: 35.0,
        completionTimeSeconds: 110.0,
        accuracyPercentage: 38.0,
        mistakesCount: 12,
        currentLevel: 2, // Hard
      );

      final result = MlDifficultyService.predictNextDifficulty(performance);

      expect(result.recommendedLevelIndex, equals(0)); // Should step down to Easy
      expect(result.levelName, contains('Easy'));
      expect(result.confidence, greaterThan(0.7));
    });

    test('Balanced Moderate Patient -> Predicts Steady Progression', () {
      final performance = GamePerformanceData(
        score: 75.0,
        completionTimeSeconds: 42.0,
        accuracyPercentage: 75.0,
        mistakesCount: 3,
        currentLevel: 1, // Medium
      );

      final result = MlDifficultyService.predictNextDifficulty(performance);

      expect(result.confidence, greaterThan(0.5));
      expect(result.classProbabilities.containsKey('EASY'), isTrue);
      expect(result.classProbabilities.containsKey('MEDIUM'), isTrue);
      expect(result.classProbabilities.containsKey('HARD'), isTrue);
    });

    test('Execution Speed Test: Must evaluate 50 trees in < 5ms offline', () {
      final performance = GamePerformanceData(
        score: 85.0,
        completionTimeSeconds: 28.0,
        accuracyPercentage: 85.0,
        mistakesCount: 2,
        currentLevel: 0,
      );

      final stopwatch = Stopwatch()..start();
      for (int i = 0; i < 100; i++) {
        MlDifficultyService.predictNextDifficulty(performance);
      }
      stopwatch.stop();

      final avgMsPerInference = stopwatch.elapsedMilliseconds / 100.0;
      expect(avgMsPerInference, lessThan(5.0)); // <5ms per inference
    });
  });
}
