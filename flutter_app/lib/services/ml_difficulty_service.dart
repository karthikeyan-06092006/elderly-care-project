import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'ml_difficulty_trees.dart';

enum GameDifficulty { easy, medium, hard }

class GamePerformanceData {
  final double score;
  final double completionTimeSeconds;
  final double accuracyPercentage;
  final int mistakesCount;
  final int currentLevel; // 0: Easy, 1: Medium, 2: Hard
  final String gameTitle;

  const GamePerformanceData({
    required this.score,
    required this.completionTimeSeconds,
    required this.accuracyPercentage,
    required this.mistakesCount,
    required this.currentLevel,
    this.gameTitle = 'Card Matching',
  });

  List<double> toFeatureVector() {
    return [
      score.clamp(0.0, 100.0),
      completionTimeSeconds.clamp(1.0, 300.0),
      accuracyPercentage.clamp(0.0, 100.0),
      mistakesCount.toDouble().clamp(0.0, 50.0),
      currentLevel.toDouble().clamp(0.0, 2.0),
    ];
  }

  Map<String, dynamic> toJson() {
    return {
      'score': score,
      'completionTimeSeconds': completionTimeSeconds,
      'accuracyPercentage': accuracyPercentage,
      'mistakesCount': mistakesCount,
      'currentLevel': currentLevel,
      'gameTitle': gameTitle,
    };
  }
}

class DifficultyPredictionResult {
  final int recommendedLevelIndex; // 0 = Easy, 1 = Medium, 2 = Hard
  final GameDifficulty recommendedDifficulty;
  final String levelName;
  final double confidence;
  final Map<String, double> classProbabilities;
  final String messageEn;
  final String messageBn;
  final String reasoning;

  const DifficultyPredictionResult({
    required this.recommendedLevelIndex,
    required this.recommendedDifficulty,
    required this.levelName,
    required this.confidence,
    required this.classProbabilities,
    required this.messageEn,
    required this.messageBn,
    required this.reasoning,
  });

  bool get isUpgrade => recommendedLevelIndex > 0;
  bool get isEasy => recommendedLevelIndex == 0;
  bool get isMedium => recommendedLevelIndex == 1;
  bool get isHard => recommendedLevelIndex == 2;
}

/// Offline Random Forest ML Service
/// Evaluates 50 decision trees in pure Dart (<1ms latency, 100% offline).
class MlDifficultyService {
  static const List<String> _levelNames = ['Easy (6 Cards)', 'Medium (8 Cards)', 'Level 3 (12 Cards)'];

  /// Evaluates Random Forest ensemble on patient gameplay telemetry
  static DifficultyPredictionResult predictNextDifficulty(GamePerformanceData data) {
    final features = data.toFeatureVector();
    final trees = RandomForestModelData.trees;
    
    // Accumulate class probabilities across all 50 trees
    final List<double> classVotes = [0.0, 0.0, 0.0];

    for (final tree in trees) {
      final leafWeights = _traverseTree(tree, features);
      if (leafWeights != null && leafWeights.length == 3) {
        final sum = leafWeights.reduce((a, b) => a + b);
        if (sum > 0) {
          classVotes[0] += leafWeights[0] / sum;
          classVotes[1] += leafWeights[1] / sum;
          classVotes[2] += leafWeights[2] / sum;
        }
      }
    }

    final totalVotes = classVotes.reduce((a, b) => a + b);
    final normProbs = totalVotes > 0 
        ? [classVotes[0] / totalVotes, classVotes[1] / totalVotes, classVotes[2] / totalVotes]
        : [0.33, 0.33, 0.34];

    // Find predicted class index with highest probability
    int predictedClass = 0;
    double maxProb = normProbs[0];
    for (int i = 1; i < normProbs.length; i++) {
      if (normProbs[i] > maxProb) {
        maxProb = normProbs[i];
        predictedClass = i;
      }
    }

    final diffEnum = GameDifficulty.values[predictedClass];
    final lvlName = _levelNames[predictedClass];

    // Generate clinical reasoning & localized encouragement
    String reason;
    String msgEn;
    String msgBn;

    if (predictedClass > data.currentLevel) {
      reason = 'High recall speed (${data.completionTimeSeconds.toInt()}s) and sharp accuracy (${data.accuracyPercentage.toInt()}%) indicate readiness for a cognitive step-up.';
      msgEn = '🌟 Excellent memory! AI recommends trying $lvlName for a fun new challenge!';
      msgBn = '🌟 দুর্দান্ত স্মৃতিশক্তি! AI নতুন চ্যালেঞ্জের জন্য $lvlName খেলার পরামর্শ দিচ্ছে!';
    } else if (predictedClass < data.currentLevel) {
      reason = 'Patient took ${data.completionTimeSeconds.toInt()}s with ${data.mistakesCount} attempts. Easing difficulty to prevent cognitive fatigue and frustration.';
      msgEn = '🌱 Good effort! AI recommends relaxing with $lvlName for gentle practice.';
      msgBn = '🌱 ভালো প্রচেষ্টা! আরামদায়ক অনুশীলনের জন্য AI $lvlName খেলার পরামর্শ দিচ্ছে।';
    } else {
      reason = 'Performance is well-balanced (${data.accuracyPercentage.toInt()}% accuracy). Maintaining current level to solidify memory retention.';
      msgEn = '✨ Well done! AI recommends continuing with $lvlName to master this level.';
      msgBn = '✨ চমৎকার! এই স্তরটি ভালোভাবে আয়ত্ত করতে AI $lvlName চালিয়ে যাওয়ার পরামর্শ দিচ্ছে।';
    }

    final Map<String, double> probMap = {
      'EASY': (normProbs[0] * 100).roundToDouble() / 100,
      'MEDIUM': (normProbs[1] * 100).roundToDouble() / 100,
      'HARD': (normProbs[2] * 100).roundToDouble() / 100,
    };

    return DifficultyPredictionResult(
      recommendedLevelIndex: predictedClass,
      recommendedDifficulty: diffEnum,
      levelName: lvlName,
      confidence: (maxProb * 100).roundToDouble() / 100,
      classProbabilities: probMap,
      messageEn: msgEn,
      messageBn: msgBn,
      reasoning: reason,
    );
  }

  /// Traverses a single decision tree from root to leaf
  static List<double>? _traverseTree(List<DecisionNode> tree, List<double> features) {
    if (tree.isEmpty) return null;
    int currIdx = 0;

    while (currIdx >= 0 && currIdx < tree.length) {
      final node = tree[currIdx];
      if (node.isLeaf) {
        return node.weights;
      }

      final featIdx = node.featIdx ?? 0;
      final thresh = node.thresh ?? 0.0;
      final val = (featIdx >= 0 && featIdx < features.length) ? features[featIdx] : 0.0;

      if (val <= thresh) {
        currIdx = node.left ?? -1;
      } else {
        currIdx = node.right ?? -1;
      }
    }
    return null;
  }

  /// Optional: Logs game telemetry session to Spring Boot backend for Caregiver reports
  static Future<bool> logSessionToBackend({
    required String patientId,
    required GamePerformanceData performance,
    required DifficultyPredictionResult prediction,
  }) async {
    try {
      final url = Uri.parse('http://127.0.0.1:8088/api/games/session');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'patientId': patientId,
          'gameTitle': performance.gameTitle,
          'score': performance.score,
          'completionTime': performance.completionTimeSeconds,
          'accuracy': performance.accuracyPercentage,
          'mistakes': performance.mistakesCount,
          'currentLevel': performance.currentLevel,
          'predictedLevel': prediction.recommendedLevelIndex,
          'confidence': prediction.confidence,
        }),
      ).timeout(const Duration(seconds: 3));

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint('[MlDifficultyService] Backend sync skipped (offline mode): $e');
      return false;
    }
  }
}
