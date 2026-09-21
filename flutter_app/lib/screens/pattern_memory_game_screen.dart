import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/ml_difficulty_service.dart';
import '../services/caregiver_trend_service.dart';

enum GameState { ready, watching, playing, roundSuccess, roundFailure, finished }

class TileData {
  final int id;
  final String nameEn;
  final String nameBn;
  final Color baseColor;
  final Color activeColor;
  final IconData icon;

  const TileData({
    required this.id,
    required this.nameEn,
    required this.nameBn,
    required this.baseColor,
    required this.activeColor,
    required this.icon,
  });
}

class PatternMemoryGameScreen extends StatefulWidget {
  final bool isBengali;

  const PatternMemoryGameScreen({
    super.key,
    this.isBengali = false,
  });

  @override
  State<PatternMemoryGameScreen> createState() => _PatternMemoryGameScreenState();
}

class _PatternMemoryGameScreenState extends State<PatternMemoryGameScreen> with SingleTickerProviderStateMixin {
  final List<TileData> _tiles = const [
    TileData(
      id: 0,
      nameEn: "Emerald Green",
      nameBn: "সবুজ",
      baseColor: Color(0xFF2E7D32),
      activeColor: Color(0xFF69F0AE),
      icon: Icons.eco_rounded,
    ),
    TileData(
      id: 1,
      nameEn: "Sunset Coral",
      nameBn: "কমলা",
      baseColor: Color(0xFFE65100),
      activeColor: Color(0xFFFFAB40),
      icon: Icons.wb_sunny_rounded,
    ),
    TileData(
      id: 2,
      nameEn: "Ocean Blue",
      nameBn: "নীল",
      baseColor: Color(0xFF1565C0),
      activeColor: Color(0xFF40C4FF),
      icon: Icons.water_drop_rounded,
    ),
    TileData(
      id: 3,
      nameEn: "Amber Gold",
      nameBn: "হলুদ",
      baseColor: Color(0xFFF57F17),
      activeColor: Color(0xFFFFFF00),
      icon: Icons.star_rounded,
    ),
  ];

  final int _totalRounds = 5;
  int _currentRound = 1;
  int _score = 0;
  GameState _gameState = GameState.ready;
  List<int> _sequence = [];
  List<int> _userInputs = [];
  int? _activeHighlightTile;
  String _statusMessage = "";
  final Random _random = Random();
  Timer? _playbackTimer;

  @override
  void initState() {
    super.initState();
    _resetGame();
  }

  @override
  void dispose() {
    _playbackTimer?.cancel();
    super.dispose();
  }

  void _resetGame() {
    _playbackTimer?.cancel();
    setState(() {
      _currentRound = 1;
      _score = 0;
      _gameState = GameState.ready;
      _sequence = [];
      _userInputs = [];
      _activeHighlightTile = null;
      _statusMessage = widget.isBengali
          ? "শুরু করতে নিচের বাটনে ট্যাপ করুন"
          : "Tap 'Start Game' below when you are ready";
    });
  }

  void _startNextRound() {
    _playbackTimer?.cancel();
    _userInputs = [];

    // Length of sequence scales gently: Round 1 & 2 = 2 tiles, Round 3 & 4 = 3 tiles, Round 5 = 4 tiles
    int length;
    if (_currentRound <= 2) {
      length = 2;
    } else if (_currentRound <= 4) {
      length = 3;
    } else {
      length = 4;
    }

    _sequence = List.generate(length, (_) => _random.nextInt(4));

    setState(() {
      _gameState = GameState.watching;
      _statusMessage = widget.isBengali
          ? "👀 মনোযোগ দিন! প্যাটার্নটি লক্ষ্য করুন..."
          : "👀 Watch closely! Remember the pattern...";
      _activeHighlightTile = null;
    });

    _playSequence();
  }

  void _playSequence() {
    int index = 0;
    _playbackTimer?.cancel();

    _playbackTimer = Timer.periodic(const Duration(milliseconds: 950), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (index < _sequence.length) {
        setState(() {
          _activeHighlightTile = _sequence[index];
        });

        // Flash off shortly
        Future.delayed(const Duration(milliseconds: 550), () {
          if (mounted && _gameState == GameState.watching) {
            setState(() {
              _activeHighlightTile = null;
            });
          }
        });

        index++;
      } else {
        timer.cancel();
        Future.delayed(const Duration(milliseconds: 600), () {
          if (mounted) {
            setState(() {
              _gameState = GameState.playing;
              _activeHighlightTile = null;
              _statusMessage = widget.isBengali
                  ? "👉 এবার আপনার পালা! একই ক্রমে ট্যাপ করুন (${_sequence.length} টি)"
                  : "👉 Your Turn! Tap the tiles in the same order (${_sequence.length} tiles)";
            });
          }
        });
      }
    });
  }

  void _onTileTap(int tileId) {
    if (_gameState != GameState.playing) return;

    // Flash tapped tile
    setState(() {
      _activeHighlightTile = tileId;
      _userInputs.add(tileId);
    });

    Future.delayed(const Duration(milliseconds: 250), () {
      if (mounted) {
        setState(() {
          _activeHighlightTile = null;
        });
      }
    });

    int currentIndex = _userInputs.length - 1;

    // Check if correct
    if (_userInputs[currentIndex] != _sequence[currentIndex]) {
      // Mistake made
      setState(() {
        _gameState = GameState.roundFailure;
        _statusMessage = widget.isBengali
            ? "❌ ভুল হয়েছে, কিন্তু কোনো সমস্যা নেই!"
            : "❌ Not quite, but keep going!";
      });

      Future.delayed(const Duration(milliseconds: 1400), () {
        if (!mounted) return;
        _advanceRound(passed: false);
      });
      return;
    }

    // Check if full sequence completed
    if (_userInputs.length == _sequence.length) {
      setState(() {
        _gameState = GameState.roundSuccess;
        _score++;
        _statusMessage = widget.isBengali
            ? "🎉 চমৎকার! সঠিক উত্তর!"
            : "🎉 Wonderful! Correct pattern!";
      });

      Future.delayed(const Duration(milliseconds: 1400), () {
        if (!mounted) return;
        _advanceRound(passed: true);
      });
    }
  }

  void _advanceRound({required bool passed}) {
    if (_currentRound >= _totalRounds) {
      final double accuracy = (_score / _totalRounds) * 100;
      final int mistakes = _totalRounds - _score;
      final performance = GamePerformanceData(
        score: accuracy,
        completionTimeSeconds: 45.0,
        accuracyPercentage: accuracy,
        mistakesCount: mistakes,
        currentLevel: 0,
        gameTitle: 'Pattern Memory',
      );
      final prediction = MlDifficultyService.predictNextDifficulty(performance);

      MlDifficultyService.logSessionToBackend(
        patientId: 'demo-patient-001',
        performance: performance,
        prediction: prediction,
      );

      CaregiverTrendService.recordSession(GameSessionRecord(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        patientId: 'demo-patient-001',
        patientName: 'Karthikeyan',
        gameTitle: 'Pattern Memory',
        score: accuracy,
        completionTimeSeconds: 45.0,
        accuracyPercentage: accuracy,
        mistakesCount: mistakes,
        difficultyLevel: 'MEDIUM',
        aiRecommendedLevel: prediction.levelName.toUpperCase(),
        aiConfidence: prediction.confidence,
        playedAt: DateTime.now(),
      ));

      setState(() {
        _gameState = GameState.finished;
      });
    } else {
      setState(() {
        _currentRound++;
      });
      _startNextRound();
    }
  }

  void _replaySequence() {
    if (_gameState == GameState.playing) {
      _userInputs = [];
      setState(() {
        _gameState = GameState.watching;
        _statusMessage = widget.isBengali
            ? "👀 আবার দেখানো হচ্ছে... মনোযোগ দিয়ে দেখুন"
            : "👀 Replaying sequence... Watch carefully";
      });
      _playSequence();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isBn = widget.isBengali;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isBn ? "প্যাটার্ন মেমোরি খেলা" : "Pattern Memory Game",
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: isBn ? "নতুন করে শুরু" : "Restart Game",
            onPressed: _resetGame,
          ),
        ],
      ),
      body: SafeArea(
        child: _gameState == GameState.finished
            ? _buildScoreSummaryView(isBn)
            : _buildGamePlayView(isBn),
      ),
    );
  }

  Widget _buildGamePlayView(bool isBn) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Top Round & Score Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(15),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.military_tech_rounded, color: AppTheme.accent, size: 26),
                    const SizedBox(width: 8),
                    Text(
                      isBn ? "রাউন্ড: $_currentRound/$_totalRounds" : "Round: $_currentRound/$_totalRounds",
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.star_rounded, color: AppTheme.primary, size: 20),
                      const SizedBox(width: 4),
                      Text(
                        isBn ? "স্কোর: $_score" : "Score: $_score",
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.primary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // 2. Status Banner (Large, High Contrast Cues for Seniors)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: _getStatusBgColor(),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _getStatusBorderColor(), width: 2),
            ),
            child: Text(
              _statusMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: _getStatusTextColor(),
                height: 1.3,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 3. 2x2 Big Interactive Memory Grid
          Expanded(
            child: Center(
              child: AspectRatio(
                aspectRatio: 1.0,
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: 4,
                  itemBuilder: (context, index) {
                    final tile = _tiles[index];
                    final isHighlighted = _activeHighlightTile == tile.id;
                    final isClickable = _gameState == GameState.playing;

                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeInOut,
                      transform: isHighlighted
                          ? Matrix4.diagonal3Values(1.04, 1.04, 1.0)
                          : Matrix4.identity(),
                      decoration: BoxDecoration(
                        color: isHighlighted ? tile.activeColor : tile.baseColor.withAlpha(210),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: isHighlighted ? Colors.white : Colors.transparent,
                          width: 4,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: isHighlighted
                                ? tile.activeColor.withAlpha(180)
                                : Colors.black.withAlpha(30),
                            blurRadius: isHighlighted ? 20 : 6,
                            spreadRadius: isHighlighted ? 4 : 0,
                            offset: isHighlighted ? const Offset(0, 0) : const Offset(0, 4),
                          )
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(24),
                          onTap: isClickable ? () => _onTileTap(tile.id) : null,
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  tile.icon,
                                  size: isHighlighted ? 58 : 50,
                                  color: isHighlighted ? Colors.black87 : Colors.white,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  isBn ? tile.nameBn : tile.nameEn,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: isHighlighted ? Colors.black87 : Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // 4. Bottom Controls: Replay / Start Game Button
          if (_gameState == GameState.ready)
            ElevatedButton.icon(
              onPressed: _startNextRound,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                elevation: 4,
              ),
              icon: const Icon(Icons.play_arrow_rounded, size: 30),
              label: Text(
                isBn ? "খেলা শুরু করুন" : "Start Game",
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            )
          else if (_gameState == GameState.playing)
            OutlinedButton.icon(
              onPressed: _replaySequence,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppTheme.primary, width: 2),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              icon: const Icon(Icons.replay_rounded, size: 22),
              label: Text(
                isBn ? "🔁 প্যাটার্ন আবার দেখুন" : "🔁 Watch Pattern Again",
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            )
          else
            const SizedBox(height: 52), // Space placeholder to maintain smooth layout
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildScoreSummaryView(bool isBn) {
    final double accuracy = (_score / _totalRounds) * 100;
    final int mistakes = _totalRounds - _score;
    final double scorePct = accuracy;

    final performance = GamePerformanceData(
      score: scorePct,
      completionTimeSeconds: 45.0,
      accuracyPercentage: accuracy,
      mistakesCount: mistakes,
      currentLevel: 0,
      gameTitle: 'Pattern Memory',
    );

    final prediction = MlDifficultyService.predictNextDifficulty(performance);

    String feedbackMsg = "";
    if (_score >= 4) {
      feedbackMsg = isBn
          ? "অসাধারণ স্মৃতিশক্তি! আপনার মস্তিষ্ক সক্রিয় ও চমৎকার রয়েছে।"
          : "Exceptional Memory! Your mind is active, sharp, and focused.";
    } else if (_score >= 2) {
      feedbackMsg = isBn
          ? "খুব ভালো চেষ্টা! নিয়মিত প্যাটার্ন খেলা স্মৃতিশক্তি বজায় রাখতে সাহায্য করে।"
          : "Well played! Daily cognitive practice helps preserve memory recall.";
    } else {
      feedbackMsg = isBn
          ? "কোনো চিন্তা নেই! ধীরে ধীরে বারবার খেললে আপনার স্মৃতিশক্তি বৃদ্ধি পাবে।"
          : "Don't worry! Relaxed, regular practice nurtures memory strengthening.";
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 10),
          // Celebration Icon
          Center(
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.amber.shade100,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.amber.shade600, width: 3),
              ),
              child: const Icon(Icons.emoji_events_rounded, color: Color(0xFFF57F17), size: 58),
            ),
          ),
          const SizedBox(height: 20),

          // Game Complete Title
          Text(
            isBn ? "খেলা সম্পন্ন হয়েছে! 🌟" : "Game Completed! 🌟",
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isBn ? "আপনার ফলাফল নিচে প্রদর্শিত হয়েছে" : "Here is your cognitive session score",
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 24),

          // Score Card
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                children: [
                  Text(
                    "$_score / $_totalRounds",
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primary,
                      letterSpacing: 2,
                    ),
                  ),
                  Text(
                    isBn
                        ? "সঠিক সমাধান (${accuracy.toInt()}% নির্ভুলতা)"
                        : "Correct Rounds (${accuracy.toInt()}% Accuracy)",
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (i) {
                      return Icon(
                        i < _score ? Icons.star_rounded : Icons.star_outline_rounded,
                        color: Colors.amber.shade700,
                        size: 36,
                      );
                    }),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // AI Random Forest Recommendation Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF004D40).withValues(alpha: 0.06),
                  const Color(0xFF00796B).withValues(alpha: 0.12),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFF00796B).withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.psychology_rounded, color: Color(0xFF00695C), size: 24),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isBn ? "AI অসুবিধা নির্ধারণ (Random Forest)" : "AI Adaptive Recommendation",
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF004D40),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00695C),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        "${(prediction.confidence * 100).toInt()}% Match",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  isBn ? prediction.messageBn : prediction.messageEn,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.textPrimary,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Dementia Redressal Feedback Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppTheme.primaryLight,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppTheme.primary.withAlpha(80)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.health_and_safety_rounded, color: AppTheme.primary, size: 28),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isBn ? "স্মৃতি মূল্যায়ণ প্রতিক্রিয়া" : "Cognitive Assessment Note",
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.primary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        feedbackMsg,
                        style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary, height: 1.4),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Play Again Button
          ElevatedButton.icon(
            onPressed: _resetGame,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            icon: const Icon(Icons.replay_rounded, size: 24),
            label: Text(
              isBn ? "আবার খেলুন" : "Play Again",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 12),

          // Back to Dashboard Button
          OutlinedButton.icon(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            icon: const Icon(Icons.dashboard_rounded, size: 22),
            label: Text(
              isBn ? "ড্যাশবোর্ডে ফিরে যান" : "Back to Dashboard",
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Color _getStatusBgColor() {
    switch (_gameState) {
      case GameState.watching:
        return Colors.amber.shade50;
      case GameState.playing:
        return const Color(0xFFE0F2F1);
      case GameState.roundSuccess:
        return Colors.green.shade50;
      case GameState.roundFailure:
        return Colors.red.shade50;
      default:
        return Colors.blue.shade50;
    }
  }

  Color _getStatusBorderColor() {
    switch (_gameState) {
      case GameState.watching:
        return Colors.amber.shade400;
      case GameState.playing:
        return AppTheme.primary;
      case GameState.roundSuccess:
        return Colors.green.shade400;
      case GameState.roundFailure:
        return Colors.red.shade300;
      default:
        return Colors.blue.shade300;
    }
  }

  Color _getStatusTextColor() {
    switch (_gameState) {
      case GameState.watching:
        return Colors.amber.shade900;
      case GameState.playing:
        return const Color(0xFF004D40);
      case GameState.roundSuccess:
        return Colors.green.shade900;
      case GameState.roundFailure:
        return Colors.red.shade900;
      default:
        return Colors.blue.shade900;
    }
  }
}
