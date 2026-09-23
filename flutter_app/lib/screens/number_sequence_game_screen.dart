import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../theme/app_theme.dart';
import '../services/ml_difficulty_service.dart';
import '../services/caregiver_trend_service.dart';

enum SequenceDifficulty { easy, medium, hard }
enum SequenceGameState { ready, watching, entering, roundSuccess, roundFailure, finished }

class _DifficultyConfig {
  final SequenceDifficulty difficulty;
  final String nameEn;
  final String nameBn;
  final Color color;
  final Duration displayInterval;

  const _DifficultyConfig({
    required this.difficulty,
    required this.nameEn,
    required this.nameBn,
    required this.color,
    required this.displayInterval,
  });
}

class NumberSequenceGameScreen extends StatefulWidget {
  final bool isBengali;

  const NumberSequenceGameScreen({super.key, this.isBengali = false});

  @override
  State<NumberSequenceGameScreen> createState() => _NumberSequenceGameScreenState();
}

class _NumberSequenceGameScreenState extends State<NumberSequenceGameScreen>
    with SingleTickerProviderStateMixin {
  static const int _totalRounds = 5;

  final List<_DifficultyConfig> _configs = const [
    _DifficultyConfig(
      difficulty: SequenceDifficulty.easy,
      nameEn: "Easy",
      nameBn: "সহজ",
      color: Color(0xFF2E7D32),
      displayInterval: Duration(milliseconds: 1600),
    ),
    _DifficultyConfig(
      difficulty: SequenceDifficulty.medium,
      nameEn: "Medium",
      nameBn: "মধ্যম",
      color: Color(0xFFE65100),
      displayInterval: Duration(milliseconds: 1100),
    ),
    _DifficultyConfig(
      difficulty: SequenceDifficulty.hard,
      nameEn: "Hard",
      nameBn: "কঠিন",
      color: Color(0xFFC2185B),
      displayInterval: Duration(milliseconds: 750),
    ),
  ];

  final FlutterTts _flutterTts = FlutterTts();
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;
  final Random _random = Random();
  Timer? _displayTimer;

  SequenceDifficulty _currentDifficulty = SequenceDifficulty.easy;
  SequenceGameState _gameState = SequenceGameState.ready;

  int _currentRound = 1;
  int _score = 0;
  int _firstTryCorrect = 0;
  int _mistakesCount = 0;
  DateTime _sessionStartTime = DateTime.now();

  List<int> _sequence = [];
  List<int> _userInputs = [];
  int? _currentDisplayIndex;
  String _statusMessage = "";

  _DifficultyConfig get _currentConfig => _configs[_currentDifficulty.index];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _scaleAnimation = CurvedAnimation(parent: _animController, curve: Curves.easeOutBack);
    _initTts();
    _resetGame();
  }

  @override
  void dispose() {
    _displayTimer?.cancel();
    _flutterTts.stop();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _initTts() async {
    try {
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setSpeechRate(0.45);
      await _flutterTts.setPitch(1.0);
    } catch (e) {
      debugPrint("TTS init error: $e");
    }
  }

  Future<void> _speak(String text) async {
    try {
      await _flutterTts.setLanguage(widget.isBengali ? "bn-BD" : "en-US");
      await _flutterTts.speak(text);
    } catch (_) {}
  }

  void _resetGame() {
    _displayTimer?.cancel();
    setState(() {
      _currentRound = 1;
      _score = 0;
      _firstTryCorrect = 0;
      _mistakesCount = 0;
      _gameState = SequenceGameState.ready;
      _sequence = [];
      _userInputs = [];
      _currentDisplayIndex = null;
      _statusMessage = widget.isBengali
          ? "সংখ্যাগুলো দেখে মনে রাখুন, তারপর একই ক্রমে ট্যাপ করুন"
          : "Watch the numbers, then tap them in the same order";
    });
  }

  void _changeDifficulty(SequenceDifficulty newDifficulty) {
    if (_currentDifficulty == newDifficulty || _gameState == SequenceGameState.watching) return;
    _displayTimer?.cancel();
    _currentDifficulty = newDifficulty;
    _resetGame();
  }

  int _sequenceLengthForRound() {
    switch (_currentDifficulty) {
      case SequenceDifficulty.easy:
        return _currentRound <= 2 ? 2 : 3; // 2,2,3,3,3
      case SequenceDifficulty.medium:
        return _currentRound <= 2 ? 4 : 5; // 4,4,5,5,5
      case SequenceDifficulty.hard:
        return _currentRound == 5 ? 8 : (_currentRound <= 2 ? 6 : 7); // 6,6,7,7,8
    }
  }

  void _startNextRound() {
    _displayTimer?.cancel();
    _userInputs = [];
    setState(() {
      _sequence = List.generate(_sequenceLengthForRound(), (_) => _random.nextInt(9) + 1);
      _currentDisplayIndex = 0;
      _gameState = SequenceGameState.watching;
      _statusMessage = widget.isBengali
          ? "👀 মনোযোগ দিন! সংখ্যা ক্রমটি দেখুন..."
          : "👀 Watch closely! Remember the numbers...";
    });
    _playSequence();
  }

  void _playSequence() {
    _speak(
      widget.isBengali
          ? "মনে রাখুন! ${_sequence.length} টি সংখ্যা"
          : "Remember! ${_sequence.length} numbers",
    );

    int index = 0;
    _displayTimer?.cancel();
    _displayTimer = Timer.periodic(_currentConfig.displayInterval, (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (index < _sequence.length) {
        setState(() {
          _currentDisplayIndex = index;
        });
        _animController.forward(from: 0.0);
        _speak("${_sequence[index]}");
        index++;
      } else {
        timer.cancel();
        setState(() {
          _currentDisplayIndex = null;
        });
        Future.delayed(const Duration(milliseconds: 500), () {
          if (!mounted) return;
          _beginEntering();
        });
      }
    });
  }

  void _replaySequence() {
    if (_gameState == SequenceGameState.entering) {
      _userInputs = [];
      setState(() {
        _gameState = SequenceGameState.watching;
        _statusMessage = widget.isBengali
            ? "👀 আবার দেখানো হচ্ছে... মনোযোগ দিন"
            : "👀 Replaying... Watch carefully";
      });
      _playSequence();
    }
  }

  void _beginEntering() {
    setState(() {
      _gameState = SequenceGameState.entering;
      _statusMessage = widget.isBengali
          ? "👉 এবার একই ক্রমে সংখ্যাগুলো ট্যাপ করুন (${_sequence.length} টি)"
          : "👉 Your turn! Tap the numbers in order (${_sequence.length} numbers)";
    });
  }

  void _onDigitTap(int digit) {
    if (_gameState != SequenceGameState.entering) return;
    if (_userInputs.length >= _sequence.length) return;

    setState(() {
      _userInputs.add(digit);
    });

    final index = _userInputs.length - 1;
    if (digit != _sequence[index]) {
      setState(() {
        _mistakesCount++;
        _gameState = SequenceGameState.roundFailure;
        _statusMessage = widget.isBengali
            ? "❌ একটু ভুল হয়েছে, তবে নিরুৎসাহিত হবেন না!"
            : "❌ That was a little off, don't be discouraged!";
      });
      _speak(widget.isBengali ? "কোনো সমস্যা নেই! পরের রাউন্ডে চেষ্টা করুন" : "No problem! Try the next round");
      Future.delayed(const Duration(milliseconds: 1800), () {
        if (!mounted) return;
        _advanceRound();
      });
      return;
    }

    if (_userInputs.length == _sequence.length) {
      _firstTryCorrect++;
      setState(() {
        _score += 20;
        _gameState = SequenceGameState.roundSuccess;
        _statusMessage = widget.isBengali
            ? "🎉 চমৎকার! সঠিক ক্রম!"
            : "🎉 Wonderful! Correct sequence!";
      });
      _speak(widget.isBengali ? "চমৎকার!" : "Wonderful!");

      Future.delayed(const Duration(milliseconds: 1600), () {
        if (!mounted) return;
        _advanceRound();
      });
    }
  }

  void _onClearPress() {
    if (_gameState != SequenceGameState.entering || _userInputs.isEmpty) return;
    setState(() {
      _userInputs.removeLast();
    });
  }

  void _advanceRound() {
    if (_currentRound >= _totalRounds) {
      _finishSession();
    } else {
      setState(() {
        _currentRound++;
      });
      _startNextRound();
    }
  }

  void _finishSession() {
    _displayTimer?.cancel();
    final double elapsedSeconds =
        DateTime.now().difference(_sessionStartTime).inSeconds.toDouble().clamp(1.0, 1000.0);
    final double accuracy = (_firstTryCorrect / _totalRounds) * 100;

    final performance = GamePerformanceData(
      score: _score.toDouble(),
      completionTimeSeconds: elapsedSeconds,
      accuracyPercentage: accuracy,
      mistakesCount: _mistakesCount,
      currentLevel: _currentDifficulty.index,
      gameTitle: 'Number Sequence',
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
      gameTitle: 'Number Sequence',
      score: _score.toDouble(),
      completionTimeSeconds: elapsedSeconds,
      accuracyPercentage: accuracy,
      mistakesCount: _mistakesCount,
      difficultyLevel: _currentDifficulty.name.toUpperCase(),
      aiRecommendedLevel: prediction.levelName.toUpperCase(),
      aiConfidence: prediction.confidence,
      playedAt: DateTime.now(),
    ));

    setState(() {
      _gameState = SequenceGameState.finished;
    });
  }

  String _levelName(bool isBn) {
    switch (_currentDifficulty) {
      case SequenceDifficulty.easy:
        return isBn ? "সহজ স্তর" : "Easy Level";
      case SequenceDifficulty.medium:
        return isBn ? "মধ্যম স্তর" : "Medium Level";
      case SequenceDifficulty.hard:
        return isBn ? "কঠিন স্তর" : "Hard Level";
    }
  }

  @override
  Widget build(BuildContext context) {
    final isBn = widget.isBengali;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          isBn ? "সংখ্যা ক্রম খেলা" : "Number Sequence Game",
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        backgroundColor: const Color(0xFF00695C),
        foregroundColor: Colors.white,
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: isBn ? "নতুন করে শুরু" : "Restart Game",
            onPressed: _resetGame,
          ),
        ],
      ),
      body: SafeArea(
        child: _gameState == SequenceGameState.finished
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
          // Difficulty selector
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFFE0ECE8),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: List.generate(_configs.length, (index) {
                final config = _configs[index];
                return _buildDifficultyTab(config);
              }),
            ),
          ),
          const SizedBox(height: 12),

          // Round & Score bar
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
                    Icon(Icons.military_tech_rounded, color: _currentConfig.color, size: 26),
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
                    color: _currentConfig.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.star_rounded, color: _currentConfig.color, size: 20),
                      const SizedBox(width: 4),
                      Text(
                        isBn ? "স্কোর: $_score" : "Score: $_score",
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: _currentConfig.color),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Status banner
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

          // Main display area: number being shown OR input slots
          _gameState == SequenceGameState.watching
              ? _buildNumberDisplay(isBn)
              : _buildInputSlots(isBn),
          const SizedBox(height: 14),

          // Keypad
          if (_gameState == SequenceGameState.entering)
            _buildKeypad()
          else if (_gameState == SequenceGameState.roundSuccess ||
              _gameState == SequenceGameState.roundFailure)
            const SizedBox(height: 8),
          const SizedBox(height: 8),

          // Start / Replay controls
          if (_gameState == SequenceGameState.ready)
            ElevatedButton.icon(
              onPressed: _startNextRound,
              style: ElevatedButton.styleFrom(
                backgroundColor: _currentConfig.color,
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
          else if (_gameState == SequenceGameState.entering)
            OutlinedButton.icon(
              onPressed: _replaySequence,
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: _currentConfig.color, width: 2),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              icon: const Icon(Icons.replay_rounded, size: 22),
              label: Text(
                isBn ? "🔁 আবার দেখুন" : "🔁 Watch Again",
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            )
          else
            const SizedBox(height: 52),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildDifficultyTab(_DifficultyConfig config) {
    final isSelected = _currentDifficulty == config.difficulty;
    final isBn = widget.isBengali;
    return Expanded(
      child: GestureDetector(
        onTap: () => _changeDifficulty(config.difficulty),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withAlpha(12),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                config.difficulty == SequenceDifficulty.easy
                    ? Icons.looks_one_rounded
                    : config.difficulty == SequenceDifficulty.medium
                        ? Icons.looks_two_rounded
                        : Icons.looks_3_rounded,
                size: 16,
                color: isSelected ? config.color : Colors.grey.shade600,
              ),
              const SizedBox(width: 4),
              Text(
                isBn ? config.nameBn : config.nameEn,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? config.color : Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNumberDisplay(bool isBn) {
    final index = _currentDisplayIndex;
    final total = _sequence.length;
    return Container(
      height: 220,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(20),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            isBn ? "প্রদর্শিত হচ্ছে..." : "Showing...",
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 10),
          if (index != null)
            ScaleTransition(
              scale: _scaleAnimation,
              child: Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  color: _currentConfig.color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                  border: Border.all(color: _currentConfig.color, width: 4),
                ),
                child: Center(
                  child: Text(
                    "${_sequence[index]}",
                    style: TextStyle(
                      fontSize: 72,
                      fontWeight: FontWeight.bold,
                      color: _currentConfig.color,
                    ),
                  ),
                ),
              ),
            )
          else
            const SizedBox.shrink(),
          const SizedBox(height: 12),
          Text(
            isBn
                ? "${(index ?? 0) + 1} / $total"
                : "${(index ?? 0) + 1} of $total",
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildInputSlots(bool isBn) {
    return Container(
      height: 150,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(20),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Center(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: List.generate(_sequence.length, (index) {
              final isFilled = index < _userInputs.length;
              final isCurrent = index == _userInputs.length && _gameState == SequenceGameState.entering;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: _sequence.length > 6 ? 38 : 46,
                  height: _sequence.length > 6 ? 50 : 58,
                  decoration: BoxDecoration(
                    color: isFilled
                        ? _currentConfig.color.withValues(alpha: 0.14)
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isCurrent
                          ? _currentConfig.color
                          : isFilled
                              ? _currentConfig.color.withValues(alpha: 0.5)
                              : const Color(0xFFCFD8DC),
                      width: isCurrent ? 2.5 : 1.5,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      isFilled ? "${_userInputs[index]}" : "",
                      style: TextStyle(
                        fontSize: _sequence.length > 6 ? 20 : 26,
                        fontWeight: FontWeight.bold,
                        color: _currentConfig.color,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildKeypad() {
    final isBn = widget.isBengali;
    final List<Widget> rows = [];
    final rowData = [
      [1, 2, 3],
      [4, 5, 6],
      [7, 8, 9],
    ];

    for (final row in rowData) {
      rows.add(
        Row(
          children: [
            for (final digit in row) Expanded(child: _buildKeyButton(digit)),
          ],
        ),
      );
      rows.add(const SizedBox(height: 10));
    }

    rows.add(
      Row(
        children: [
          Expanded(child: _buildKeyButton(0)),
          const SizedBox(width: 10),
          Expanded(
            child: _buildKeyButton(-1, label: isBn ? "↩ মুছুন" : "↩ Clear"),
          ),
        ],
      ),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: rows,
    );
  }

  Widget _buildKeyButton(int digit, {String? label}) {
    final isClearKey = digit == -1;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
      child: Material(
        color: isClearKey ? const Color(0xFFEFEBE9) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 2,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => isClearKey ? _onClearPress() : _onDigitTap(digit),
          child: Container(
            height: 58,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isClearKey ? const Color(0xFFBCAAA4) : const Color(0xFFCFD8DC),
                width: 1.5,
              ),
            ),
            child: Center(
              child: Text(
                label ?? "$digit",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: isClearKey ? AppTheme.textSecondary : AppTheme.textPrimary,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScoreSummaryView(bool isBn) {
    final double accuracy = (_firstTryCorrect / _totalRounds) * 100;
    final int stars = _firstTryCorrect >= 4 ? 3 : (_firstTryCorrect >= 2 ? 2 : 1);
    final double elapsedSeconds =
        DateTime.now().difference(_sessionStartTime).inSeconds.toDouble().clamp(1.0, 1000.0);

    String feedbackMsg = "";
    if (_score >= 80) {
      feedbackMsg = isBn
          ? "অসাধারণ স্মৃতিশক্তি! আপনার মস্তিষ্ক সক্রিয় ও চমৎকার রয়েছে।"
          : "Exceptional Memory! Your mind is active, sharp, and focused.";
    } else if (_score >= 40) {
      feedbackMsg = isBn
          ? "খুব ভালো চেষ্টা! নিয়মিত সংখ্যা খেলা স্মৃতিশক্তি বজায় রাখতে সাহায্য করে।"
          : "Well played! Daily number practice helps preserve memory recall.";
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
          Text(
            isBn ? "খেলা সম্পন্ন হয়েছে! 🌟" : "Game Completed! 🌟",
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 6),
          Text(
            isBn ? "আপনার ফলাফল নিচে প্রদর্শিত হয়েছে" : "Here is your cognitive session score",
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 24),

          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                children: [
                  Text(
                    "$_score / 100",
                    style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: _currentConfig.color, letterSpacing: 2),
                  ),
                  Text(
                    isBn
                        ? "সঠিক ক্রম (${accuracy.toInt()}% নির্ভুলতা)"
                        : "Correct Sequences (${accuracy.toInt()}% Accuracy)",
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(3, (index) {
                      return Icon(
                        index < stars ? Icons.star_rounded : Icons.star_outline_rounded,
                        color: Colors.amber.shade700,
                        size: 42,
                      );
                    }),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          Text(isBn ? "স্তর" : "Level", style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                          Text(_levelName(isBn), style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: _currentConfig.color)),
                        ],
                      ),
                      Container(height: 26, width: 1, color: Colors.grey.shade400),
                      Column(
                        children: [
                          Text(isBn ? "সময়" : "Time", style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                          Text("${elapsedSeconds.toInt()}s", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: _currentConfig.color)),
                        ],
                      ),
                      Container(height: 26, width: 1, color: Colors.grey.shade400),
                      Column(
                        children: [
                          Text(isBn ? "সঠিকতা" : "Accuracy", style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                          Text("${accuracy.toInt()}%", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: _currentConfig.color)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          _buildAiRecommendationCard(isBn),

          const SizedBox(height: 16),

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
                      Text(feedbackMsg,
                          style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary, height: 1.4)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          ElevatedButton.icon(
            onPressed: () {
              setState(() {
                _sessionStartTime = DateTime.now();
              });
              _resetGame();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _currentConfig.color,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            icon: const Icon(Icons.replay_rounded, size: 24),
            label: Text(isBn ? "আবার খেলুন" : "Play Again", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 12),

          OutlinedButton.icon(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            icon: const Icon(Icons.dashboard_rounded, size: 22),
            label: Text(isBn ? "ড্যাশবোর্ডে ফিরে যান" : "Back to Dashboard",
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildAiRecommendationCard(bool isBn) {
    final performance = GamePerformanceData(
      score: _score.toDouble(),
      completionTimeSeconds: DateTime.now().difference(_sessionStartTime).inSeconds.toDouble().clamp(1.0, 1000.0),
      accuracyPercentage: (_firstTryCorrect / _totalRounds) * 100,
      mistakesCount: _mistakesCount,
      currentLevel: _currentDifficulty.index,
      gameTitle: 'Number Sequence',
    );
    final prediction = MlDifficultyService.predictNextDifficulty(performance);

    return Container(
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
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF004D40)),
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
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            isBn ? prediction.messageBn : prediction.messageEn,
            style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary, height: 1.35),
          ),
        ],
      ),
    );
  }

  Color _getStatusBgColor() {
    switch (_gameState) {
      case SequenceGameState.watching:
        return Colors.amber.shade50;
      case SequenceGameState.entering:
        return const Color(0xFFE0F2F1);
      case SequenceGameState.roundSuccess:
        return Colors.green.shade50;
      case SequenceGameState.roundFailure:
        return Colors.red.shade50;
      default:
        return Colors.blue.shade50;
    }
  }

  Color _getStatusBorderColor() {
    switch (_gameState) {
      case SequenceGameState.watching:
        return Colors.amber.shade400;
      case SequenceGameState.entering:
        return _currentConfig.color;
      case SequenceGameState.roundSuccess:
        return Colors.green.shade400;
      case SequenceGameState.roundFailure:
        return Colors.red.shade300;
      default:
        return Colors.blue.shade300;
    }
  }

  Color _getStatusTextColor() {
    switch (_gameState) {
      case SequenceGameState.watching:
        return Colors.amber.shade900;
      case SequenceGameState.entering:
        return const Color(0xFF004D40);
      case SequenceGameState.roundSuccess:
        return Colors.green.shade900;
      case SequenceGameState.roundFailure:
        return Colors.red.shade900;
      default:
        return Colors.blue.shade900;
    }
  }
}