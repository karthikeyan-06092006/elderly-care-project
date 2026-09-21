import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'api_service.dart';

enum CognitiveTrendDirection { improving, stable, declining }

class PatientProfile {
  final String id;
  final String name;
  final int age;
  final String stage; // e.g. "Early Stage", "Mild Impairment", "Moderate Stage"
  final String avatarColorHex;

  const PatientProfile({
    required this.id,
    required this.name,
    required this.age,
    required this.stage,
    required this.avatarColorHex,
  });
}

class GameSessionRecord {
  final String id;
  final String patientId;
  final String patientName;
  final String gameTitle;
  final double score;
  final double completionTimeSeconds;
  final double accuracyPercentage;
  final int mistakesCount;
  final String difficultyLevel;
  final String aiRecommendedLevel;
  final double aiConfidence;
  final DateTime playedAt;

  GameSessionRecord({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.gameTitle,
    required this.score,
    required this.completionTimeSeconds,
    required this.accuracyPercentage,
    required this.mistakesCount,
    required this.difficultyLevel,
    required this.aiRecommendedLevel,
    required this.aiConfidence,
    required this.playedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'patientId': patientId,
        'patientName': patientName,
        'gameTitle': gameTitle,
        'score': score,
        'completionTimeSeconds': completionTimeSeconds,
        'accuracyPercentage': accuracyPercentage,
        'mistakesCount': mistakesCount,
        'difficultyLevel': difficultyLevel,
        'aiRecommendedLevel': aiRecommendedLevel,
        'aiConfidence': aiConfidence,
        'playedAt': playedAt.toIso8601String(),
      };

  factory GameSessionRecord.fromJson(Map<String, dynamic> json) => GameSessionRecord(
        id: json['id']?.toString() ?? '',
        patientId: json['patientId'] ?? '',
        patientName: json['patientName'] ?? 'Patient',
        gameTitle: json['gameTitle'] ?? 'Cognitive Game',
        score: (json['score'] as num?)?.toDouble() ?? 0.0,
        completionTimeSeconds: (json['completionTimeSeconds'] as num?)?.toDouble() ?? 0.0,
        accuracyPercentage: (json['accuracyPercentage'] as num?)?.toDouble() ?? 0.0,
        mistakesCount: (json['mistakesCount'] as num?)?.toInt() ?? 0,
        difficultyLevel: json['difficultyLevel'] ?? 'Normal',
        aiRecommendedLevel: json['aiRecommendedLevel'] ?? 'Normal',
        aiConfidence: (json['aiConfidence'] as num?)?.toDouble() ?? 0.0,
        playedAt: json['playedAt'] != null ? DateTime.tryParse(json['playedAt']) ?? DateTime.now() : DateTime.now(),
      );
}

class CognitiveTrajectoryAnalysis {
  final double cognitiveVitalityScore; // 0 - 100
  final CognitiveTrendDirection trendDirection;
  final double trendSlope; // OLS Linear Regression slope m
  final double rateOfChangePercentage; // e.g. +14.2%
  final double averageAccuracy;
  final double averageSpeedSeconds;
  final int totalMistakes;
  final int totalSessions;
  final Map<String, double> gameBreakdownAccuracy; // Game -> Accuracy %
  final Map<String, int> gameBreakdownPlays; // Game -> Session count
  final List<double> weeklyAccuracyPoints; // Past 7 sessions accuracy
  final List<double> weeklySpeedPoints; // Past 7 sessions reaction times
  final String clinicalInsightEn;
  final String clinicalInsightBn;
  final bool hasDeclineAlert;

  const CognitiveTrajectoryAnalysis({
    required this.cognitiveVitalityScore,
    required this.trendDirection,
    required this.trendSlope,
    required this.rateOfChangePercentage,
    required this.averageAccuracy,
    required this.averageSpeedSeconds,
    required this.totalMistakes,
    required this.totalSessions,
    required this.gameBreakdownAccuracy,
    required this.gameBreakdownPlays,
    required this.weeklyAccuracyPoints,
    required this.weeklySpeedPoints,
    required this.clinicalInsightEn,
    required this.clinicalInsightBn,
    required this.hasDeclineAlert,
  });
}

class CaregiverTrendService {
  static Future<String> _getBackendUrl() async {
    try {
      final authUrl = await ApiService.getWorkingBaseUrl();
      return authUrl.replaceAll('/auth', '/analytics');
    } catch (_) {
      return 'http://127.0.0.1:8088/api/analytics';
    }
  }

  // In-memory cache for ultra-fast access
  static final Map<String, List<GameSessionRecord>> _localMemoryCache = {};

  // Demo Patient Roster (1 Caretaker Managing Multiple Patients)
  static const List<PatientProfile> defaultRoster = [
    PatientProfile(
      id: 'demo-patient-001',
      name: 'Karthikeyan',
      age: 72,
      stage: 'Mild Impairment',
      avatarColorHex: '0xFF00796B',
    ),
    PatientProfile(
      id: 'demo-patient-002',
      name: 'Anjali Sen',
      age: 68,
      stage: 'Moderate Stage',
      avatarColorHex: '0xFF8E24AA',
    ),
    PatientProfile(
      id: 'demo-patient-003',
      name: 'Rahim Mia',
      age: 76,
      stage: 'Early Stage',
      avatarColorHex: '0xFFE65100',
    ),
  ];

  static Future<File> _getLocalCacheFile(String patientId) async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/game_sessions_$patientId.json');
  }

  /// Record session both locally in file cache and sync to Spring Boot Oracle DB
  static Future<void> recordSession(GameSessionRecord session) async {
    try {
      // 1. In-memory cache
      _localMemoryCache.putIfAbsent(session.patientId, () => []).insert(0, session);

      // 2. Local File Storage
      try {
        final file = await _getLocalCacheFile(session.patientId);
        List<dynamic> list = [];
        if (await file.exists()) {
          final content = await file.readAsString();
          list = jsonDecode(content);
        }
        list.insert(0, session.toJson());
        if (list.length > 50) list = list.sublist(0, 50);
        await file.writeAsString(jsonEncode(list));
      } catch (_) {}

      // 3. Remote Backend Sync to Oracle DB
      final baseUrl = await _getBackendUrl();
      http.post(
        Uri.parse('$baseUrl/game-session'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(session.toJson()),
      ).timeout(const Duration(seconds: 4)).catchError((e) {
        debugPrint('[CaregiverTrendService] Backend sync skipped (offline mode): $e');
        return http.Response('', 500);
      });
    } catch (e) {
      debugPrint('[CaregiverTrendService] Error recording session: $e');
    }
  }

  /// Fetch sessions: tries Oracle DB first, falls back to offline cache
  static Future<List<GameSessionRecord>> fetchPatientSessions(String patientId) async {
    List<GameSessionRecord> sessions = [];

    // Try fetching from Oracle DB
    try {
      final baseUrl = await _getBackendUrl();
      final response = await http.get(
        Uri.parse('$baseUrl/patient/$patientId'),
      ).timeout(const Duration(seconds: 3));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded['success'] == true && decoded['data'] is List) {
          sessions = (decoded['data'] as List)
              .map((item) => GameSessionRecord.fromJson(item))
              .toList();
        }
      }
    } catch (e) {
      debugPrint('[CaregiverTrendService] Backend fetch failed, using local offline cache: $e');
    }

    // If backend had no sessions, load local cache
    if (sessions.isEmpty) {
      if (_localMemoryCache.containsKey(patientId) && _localMemoryCache[patientId]!.isNotEmpty) {
        sessions = List.from(_localMemoryCache[patientId]!);
      } else {
        try {
          final file = await _getLocalCacheFile(patientId);
          if (await file.exists()) {
            final content = await file.readAsString();
            final list = jsonDecode(content) as List;
            sessions = list.map((item) => GameSessionRecord.fromJson(item)).toList();
          }
        } catch (_) {}
      }
    }

    // If still empty (e.g. initial demo patient profiles), seed with realistic clinical seed data
    if (sessions.isEmpty) {
      sessions = _getSeededSessionsForPatient(patientId);
    }

    _localMemoryCache[patientId] = sessions;
    return sessions;
  }

  /// 📈 Linear Regression & Moving-Average Time-Series Trend Classifier
  static CognitiveTrajectoryAnalysis analyzeTrajectory(List<GameSessionRecord> sessions) {
    if (sessions.isEmpty) {
      return const CognitiveTrajectoryAnalysis(
        cognitiveVitalityScore: 75.0,
        trendDirection: CognitiveTrendDirection.stable,
        trendSlope: 0.0,
        rateOfChangePercentage: 0.0,
        averageAccuracy: 80.0,
        averageSpeedSeconds: 15.0,
        totalMistakes: 0,
        totalSessions: 0,
        gameBreakdownAccuracy: {},
        gameBreakdownPlays: {},
        weeklyAccuracyPoints: [70, 75, 80, 80, 85, 85, 90],
        weeklySpeedPoints: [25, 22, 20, 19, 18, 16, 15],
        clinicalInsightEn: "Play memory games daily to generate automated AI trajectory reports.",
        clinicalInsightBn: "দৈনিক স্মৃতি গেম খেললে স্বয়ংক্রিয় AI রিপোর্ট তৈরি হবে।",
        hasDeclineAlert: false,
      );
    }

    // 1. Group and calculate averages
    double sumAccuracy = 0;
    double sumSpeed = 0;
    int sumMistakes = 0;
    final Map<String, List<double>> gameAccuracies = {};
    final Map<String, int> gamePlays = {};

    for (var s in sessions) {
      sumAccuracy += s.accuracyPercentage;
      sumSpeed += s.completionTimeSeconds;
      sumMistakes += s.mistakesCount;

      gameAccuracies.putIfAbsent(s.gameTitle, () => []).add(s.accuracyPercentage);
      gamePlays[s.gameTitle] = (gamePlays[s.gameTitle] ?? 0) + 1;
    }

    final double avgAccuracy = sumAccuracy / sessions.length;
    final double avgSpeed = sumSpeed / sessions.length;

    // 2. Prepare chronological session series for Time-Series Regression
    final chronological = List<GameSessionRecord>.from(sessions)
      ..sort((a, b) => a.playedAt.compareTo(b.playedAt));

    final recent7 = chronological.length > 7
        ? chronological.sublist(chronological.length - 7)
        : chronological;

    final List<double> accuracyPoints = recent7.map((s) => s.accuracyPercentage).toList();
    final List<double> speedPoints = recent7.map((s) => s.completionTimeSeconds).toList();

    // 3. Exponential Moving Average (EMA) Smoothing
    final List<double> smoothed = [];
    double ema = accuracyPoints.first;
    const double alpha = 0.35;
    for (var val in accuracyPoints) {
      ema = (alpha * val) + ((1 - alpha) * ema);
      smoothed.add(ema);
    }

    // 4. Ordinary Least Squares (OLS) Linear Regression Slope (m)
    final int n = smoothed.length;
    double slope = 0.0;
    if (n >= 2) {
      double sumX = 0;
      double sumY = 0;
      for (int i = 0; i < n; i++) {
        sumX += i;
        sumY += smoothed[i];
      }
      final double meanX = sumX / n;
      final double meanY = sumY / n;

      double numerator = 0;
      double denominator = 0;
      for (int i = 0; i < n; i++) {
        numerator += (i - meanX) * (smoothed[i] - meanY);
        denominator += (i - meanX) * (i - meanX);
      }
      slope = denominator != 0 ? (numerator / denominator) : 0.0;
    }

    // 5. Trend Direction and Rate of Change %
    CognitiveTrendDirection direction;
    double rateOfChange;

    if (smoothed.length >= 2) {
      rateOfChange = ((smoothed.last - smoothed.first) / max(1.0, smoothed.first)) * 100.0;
    } else {
      rateOfChange = 0.0;
    }

    if (slope > 0.4 || rateOfChange > 5.0) {
      direction = CognitiveTrendDirection.improving;
    } else if (slope < -0.6 || rateOfChange < -8.0) {
      direction = CognitiveTrendDirection.declining;
    } else {
      direction = CognitiveTrendDirection.stable;
    }

    final bool hasAlert = direction == CognitiveTrendDirection.declining;

    // 6. Overall Cognitive Vitality Index (0 - 100)
    final double vitality = (avgAccuracy * 0.50) +
        (max(0.0, 100.0 - (avgSpeed * 1.5)) * 0.30) +
        (max(0.0, 100.0 - (sumMistakes * 4.0)) * 0.20);
    final double clampedVitality = vitality.clamp(20.0, 99.0);

    // 7. Breakdown map
    final Map<String, double> breakdownAcc = {};
    gameAccuracies.forEach((game, list) {
      breakdownAcc[game] = list.reduce((a, b) => a + b) / list.length;
    });

    // 8. Generate Automated Clinical Insights
    String insightEn;
    String insightBn;

    if (direction == CognitiveTrendDirection.improving) {
      insightEn = "Cognitive agility improved by ${rateOfChange.abs().toStringAsFixed(1)}% over recent sessions. Response times are steadily sharpening.";
      insightBn = "সাম্প্রতিক সেশনে জ্ঞানীয় তৎপরতা ${rateOfChange.abs().toStringAsFixed(1)}% বৃদ্ধি পেয়েছে। প্রতিক্রিয়ার গতি লক্ষণীয়ভাবে উন্নত হচ্ছে।";
    } else if (direction == CognitiveTrendDirection.declining) {
      insightEn = "Early cognitive fatigue detected (-${rateOfChange.abs().toStringAsFixed(1)}% decline). Recommend shorter sessions in the morning and adequate hydration.";
      insightBn = "ক্লান্তি বা একাগ্রতার ঘাটতি চিহ্নিত (-${rateOfChange.abs().toStringAsFixed(1)}%)। সকালে স্বল্প মেয়াদের গেম সেশন এবং বিশ্রামের পরামর্শ দেওয়া হচ্ছে।";
    } else {
      insightEn = "Memory retention is well-preserved with stable accuracy (${avgAccuracy.toInt()}%) across daily cognitive routines.";
      insightBn = "দৈনিক জ্ঞানীয় অনুশীলনে স্মৃতিশক্তি ও একাগ্রতা স্থিতিশীল রয়েছে (${avgAccuracy.toInt()}%)।";
    }

    return CognitiveTrajectoryAnalysis(
      cognitiveVitalityScore: clampedVitality,
      trendDirection: direction,
      trendSlope: slope,
      rateOfChangePercentage: rateOfChange,
      averageAccuracy: avgAccuracy,
      averageSpeedSeconds: avgSpeed,
      totalMistakes: sumMistakes,
      totalSessions: sessions.length,
      gameBreakdownAccuracy: breakdownAcc,
      gameBreakdownPlays: gamePlays,
      weeklyAccuracyPoints: accuracyPoints,
      weeklySpeedPoints: speedPoints,
      clinicalInsightEn: insightEn,
      clinicalInsightBn: insightBn,
      hasDeclineAlert: hasAlert,
    );
  }

  static List<GameSessionRecord> _getSeededSessionsForPatient(String patientId) {
    final now = DateTime.now();
    if (patientId == 'demo-patient-002') {
      // Anjali Sen (Moderate - slightly lower scores, stable)
      return [
        GameSessionRecord(
          id: 'seed-201',
          patientId: patientId,
          patientName: 'Anjali Sen',
          gameTitle: 'Word Recall',
          score: 80,
          completionTimeSeconds: 32,
          accuracyPercentage: 80,
          mistakesCount: 1,
          difficultyLevel: 'Easy',
          aiRecommendedLevel: 'Easy',
          aiConfidence: 0.82,
          playedAt: now.subtract(const Duration(days: 3)),
        ),
        GameSessionRecord(
          id: 'seed-202',
          patientId: patientId,
          patientName: 'Anjali Sen',
          gameTitle: 'Card Matching',
          score: 75,
          completionTimeSeconds: 38,
          accuracyPercentage: 75,
          mistakesCount: 2,
          difficultyLevel: 'Easy',
          aiRecommendedLevel: 'Easy',
          aiConfidence: 0.79,
          playedAt: now.subtract(const Duration(days: 2)),
        ),
        GameSessionRecord(
          id: 'seed-203',
          patientId: patientId,
          patientName: 'Anjali Sen',
          gameTitle: 'Pattern Memory',
          score: 70,
          completionTimeSeconds: 42,
          accuracyPercentage: 70,
          mistakesCount: 3,
          difficultyLevel: 'Easy',
          aiRecommendedLevel: 'Easy',
          aiConfidence: 0.85,
          playedAt: now.subtract(const Duration(days: 1)),
        ),
      ];
    } else if (patientId == 'demo-patient-003') {
      // Rahim Mia (Early Stage - good scores)
      return [
        GameSessionRecord(
          id: 'seed-301',
          patientId: patientId,
          patientName: 'Rahim Mia',
          gameTitle: 'Pattern Memory',
          score: 90,
          completionTimeSeconds: 22,
          accuracyPercentage: 90,
          mistakesCount: 1,
          difficultyLevel: 'Medium',
          aiRecommendedLevel: 'Medium',
          aiConfidence: 0.89,
          playedAt: now.subtract(const Duration(days: 2)),
        ),
        GameSessionRecord(
          id: 'seed-302',
          patientId: patientId,
          patientName: 'Rahim Mia',
          gameTitle: 'Word Recall',
          score: 100,
          completionTimeSeconds: 18,
          accuracyPercentage: 100,
          mistakesCount: 0,
          difficultyLevel: 'Medium',
          aiRecommendedLevel: 'Hard',
          aiConfidence: 0.91,
          playedAt: now.subtract(const Duration(days: 1)),
        ),
      ];
    }

    // Default: Karthikeyan (Active with 5 sessions showing strong improvement)
    return [
      GameSessionRecord(
        id: 'seed-101',
        patientId: patientId,
        patientName: 'Karthikeyan',
        gameTitle: 'Card Matching',
        score: 70,
        completionTimeSeconds: 35,
        accuracyPercentage: 70,
        mistakesCount: 3,
        difficultyLevel: 'Easy',
        aiRecommendedLevel: 'Easy',
        aiConfidence: 0.80,
        playedAt: now.subtract(const Duration(days: 5)),
      ),
      GameSessionRecord(
        id: 'seed-102',
        patientId: patientId,
        patientName: 'Karthikeyan',
        gameTitle: 'Pattern Memory',
        score: 80,
        completionTimeSeconds: 28,
        accuracyPercentage: 80,
        mistakesCount: 2,
        difficultyLevel: 'Easy',
        aiRecommendedLevel: 'Medium',
        aiConfidence: 0.84,
        playedAt: now.subtract(const Duration(days: 4)),
      ),
      GameSessionRecord(
        id: 'seed-103',
        patientId: patientId,
        patientName: 'Karthikeyan',
        gameTitle: 'Word Recall',
        score: 85,
        completionTimeSeconds: 25,
        accuracyPercentage: 85,
        mistakesCount: 1,
        difficultyLevel: 'Medium',
        aiRecommendedLevel: 'Medium',
        aiConfidence: 0.87,
        playedAt: now.subtract(const Duration(days: 3)),
      ),
      GameSessionRecord(
        id: 'seed-104',
        patientId: patientId,
        patientName: 'Karthikeyan',
        gameTitle: 'Card Matching',
        score: 95,
        completionTimeSeconds: 20,
        accuracyPercentage: 95,
        mistakesCount: 1,
        difficultyLevel: 'Medium',
        aiRecommendedLevel: 'Hard',
        aiConfidence: 0.90,
        playedAt: now.subtract(const Duration(days: 1)),
      ),
      GameSessionRecord(
        id: 'seed-105',
        patientId: patientId,
        patientName: 'Karthikeyan',
        gameTitle: 'Word Recall',
        score: 100,
        completionTimeSeconds: 16,
        accuracyPercentage: 100,
        mistakesCount: 0,
        difficultyLevel: 'Hard',
        aiRecommendedLevel: 'Hard',
        aiConfidence: 0.94,
        playedAt: now,
      ),
    ];
  }
}
