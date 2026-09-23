import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/ml_difficulty_service.dart';
import '../services/caregiver_trend_service.dart';

class CardItem {
  final int pairId;
  final String nameEn;
  final String nameBn;
  final IconData icon;
  final Color color;
  bool isFlipped;
  bool isMatched;

  CardItem({
    required this.pairId,
    required this.nameEn,
    required this.nameBn,
    required this.icon,
    required this.color,
    this.isFlipped = false,
    this.isMatched = false,
  });

  CardItem copyWith({bool? isFlipped, bool? isMatched}) {
    return CardItem(
      pairId: pairId,
      nameEn: nameEn,
      nameBn: nameBn,
      icon: icon,
      color: color,
      isFlipped: isFlipped ?? this.isFlipped,
      isMatched: isMatched ?? this.isMatched,
    );
  }
}

class CardMatchingGameScreen extends StatefulWidget {
  final bool isBengali;

  const CardMatchingGameScreen({
    super.key,
    this.isBengali = false,
  });

  @override
  State<CardMatchingGameScreen> createState() => _CardMatchingGameScreenState();
}

class _CardMatchingGameScreenState extends State<CardMatchingGameScreen> {
  // Available pool of dementia-friendly everyday items
  final List<CardItem> _masterDeck = [
    CardItem(
      pairId: 1,
      nameEn: "Apple",
      nameBn: "আপেল",
      icon: Icons.apple_rounded,
      color: const Color(0xFFE53935),
    ),
    CardItem(
      pairId: 2,
      nameEn: "Sun",
      nameBn: "সূর্য",
      icon: Icons.wb_sunny_rounded,
      color: const Color(0xFFFB8C00),
    ),
    CardItem(
      pairId: 3,
      nameEn: "Tree",
      nameBn: "গাছ",
      icon: Icons.park_rounded,
      color: const Color(0xFF2E7D32),
    ),
    CardItem(
      pairId: 4,
      nameEn: "Water",
      nameBn: "পানি",
      icon: Icons.water_drop_rounded,
      color: const Color(0xFF1E88E5),
    ),
    CardItem(
      pairId: 5,
      nameEn: "Flower",
      nameBn: "ফুল",
      icon: Icons.local_florist_rounded,
      color: const Color(0xFFD81B60),
    ),
    CardItem(
      pairId: 6,
      nameEn: "Star",
      nameBn: "তারা",
      icon: Icons.star_rounded,
      color: const Color(0xFFFBC02D),
    ),
    CardItem(
      pairId: 7,
      nameEn: "House",
      nameBn: "বাড়ি",
      icon: Icons.home_rounded,
      color: const Color(0xFF3949AB),
    ),
    CardItem(
      pairId: 8,
      nameEn: "Car",
      nameBn: "গাড়ি",
      icon: Icons.directions_car_rounded,
      color: const Color(0xFF00897B),
    ),
  ];

  int _selectedDifficulty = 1; // 1 = Easy (6 cards), 2 = Medium (8 cards), 3 = Advanced (12 cards)
  List<CardItem> _gameCards = [];
  int? _firstSelectedIndex;
  int? _secondSelectedIndex;
  bool _isProcessingFlip = false;
  int _moves = 0;
  int _matchedPairs = 0;
  int _totalPairs = 3;
  int _secondsElapsed = 0;
  Timer? _timer;
  bool _isGameCompleted = false;

  @override
  void initState() {
    super.initState();
    _startNewGame(_selectedDifficulty);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _secondsElapsed = 0;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isGameCompleted && mounted) {
        setState(() {
          _secondsElapsed++;
        });
      }
    });
  }

  void _startNewGame(int difficulty) {
    _timer?.cancel();
    _selectedDifficulty = difficulty;
    _firstSelectedIndex = null;
    _secondSelectedIndex = null;
    _isProcessingFlip = false;
    _moves = 0;
    _matchedPairs = 0;
    _isGameCompleted = false;

    // Determine total pairs
    if (difficulty == 1) {
      _totalPairs = 3; // 6 cards (2x3)
    } else if (difficulty == 2) {
      _totalPairs = 4; // 8 cards (2x4)
    } else {
      _totalPairs = 6; // 12 cards (3x4)
    }

    // Pick random items from master deck
    final random = Random();
    final shuffledPool = List<CardItem>.from(_masterDeck)..shuffle(random);
    final chosenItems = shuffledPool.take(_totalPairs).toList();

    // Create duplicate pairs
    final List<CardItem> newDeck = [];
    for (var item in chosenItems) {
      newDeck.add(item.copyWith(isFlipped: false, isMatched: false));
      newDeck.add(item.copyWith(isFlipped: false, isMatched: false));
    }

    newDeck.shuffle(random);

    setState(() {
      _gameCards = newDeck;
    });

    _startTimer();
  }

  void _onCardTap(int index) {
    if (_isProcessingFlip || _isGameCompleted) return;
    if (_gameCards[index].isFlipped || _gameCards[index].isMatched) return;

    setState(() {
      _gameCards[index].isFlipped = true;
    });

    if (_firstSelectedIndex == null) {
      // First card flipped
      _firstSelectedIndex = index;
    } else {
      // Second card flipped
      _secondSelectedIndex = index;
      _moves++;
      _isProcessingFlip = true;

      final firstCard = _gameCards[_firstSelectedIndex!];
      final secondCard = _gameCards[_secondSelectedIndex!];

      if (firstCard.pairId == secondCard.pairId) {
        // MATCH!
        Future.delayed(const Duration(milliseconds: 400), () {
          if (!mounted) return;
          setState(() {
            firstCard.isMatched = true;
            secondCard.isMatched = true;
            _matchedPairs++;
            _firstSelectedIndex = null;
            _secondSelectedIndex = null;
            _isProcessingFlip = false;
          });

          if (_matchedPairs == _totalPairs) {
            _onGameWon();
          }
        });
      } else {
        // NO MATCH - Flip back after short delay
        Future.delayed(const Duration(milliseconds: 900), () {
          if (!mounted) return;
          setState(() {
            firstCard.isFlipped = false;
            secondCard.isFlipped = false;
            _firstSelectedIndex = null;
            _secondSelectedIndex = null;
            _isProcessingFlip = false;
          });
        });
      }
    }
  }

  void _onGameWon() {
    _timer?.cancel();
    setState(() {
      _isGameCompleted = true;
    });

    final isBn = widget.isBengali;
    final int mistakes = max(0, _moves - _totalPairs);
    final double accuracy = (_totalPairs / max(1, _moves)) * 100.0;
    final double score = max(50.0, 100.0 - (mistakes * 5.0));
    final int currentLevelIndex = _selectedDifficulty - 1;

    // Evaluate Offline Random Forest Machine Learning Model
    final performance = GamePerformanceData(
      score: score,
      completionTimeSeconds: _secondsElapsed.toDouble(),
      accuracyPercentage: accuracy,
      mistakesCount: mistakes,
      currentLevel: currentLevelIndex,
      gameTitle: 'Card Matching',
    );

    final prediction = MlDifficultyService.predictNextDifficulty(performance);
    final int nextDifficulty = prediction.recommendedLevelIndex + 1;

    // Optional background log to backend and local trend storage
    MlDifficultyService.logSessionToBackend(
      patientId: 'demo-patient-001',
      performance: performance,
      prediction: prediction,
    );

    CaregiverTrendService.recordSession(GameSessionRecord(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      patientId: 'demo-patient-001',
      patientName: 'Karthikeyan',
      gameTitle: 'Card Matching',
      score: score,
      completionTimeSeconds: _secondsElapsed.toDouble(),
      accuracyPercentage: accuracy,
      mistakesCount: mistakes,
      difficultyLevel: currentLevelIndex == 0 ? 'EASY' : (currentLevelIndex == 1 ? 'MEDIUM' : 'HARD'),
      aiRecommendedLevel: prediction.levelName.toUpperCase(),
      aiConfidence: prediction.confidence,
      playedAt: DateTime.now(),
    ));

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        title: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber.shade100,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.emoji_events_rounded, color: Colors.amber, size: 48),
            ),
            const SizedBox(height: 12),
            Text(
              isBn ? "🎉 অসাধারণ খেলেছেন!" : "🎉 Splendid Work!",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: AppTheme.textPrimary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isBn
                    ? "আপনি সফলভাবে সবগুলি কার্ড মিলিয়েছেন!"
                    : "You found all matching card pairs!",
                style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              // Star rating
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (index) {
                  final bool isLit = index < (_moves <= _totalPairs + 2 ? 3 : (_moves <= _totalPairs + 5 ? 2 : 1));
                  return Icon(
                    Icons.star_rounded,
                    size: 36,
                    color: isLit ? Colors.amber : Colors.grey.shade300,
                  );
                }),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF81C784)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        Text(isBn ? "মোট চাল" : "Moves", style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                        Text("$_moves", style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32))),
                      ],
                    ),
                    Container(height: 28, width: 1, color: Colors.grey.shade400),
                    Column(
                      children: [
                        Text(isBn ? "সময়" : "Time", style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                        Text("${_secondsElapsed}s", style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32))),
                      ],
                    ),
                    Container(height: 28, width: 1, color: Colors.grey.shade400),
                    Column(
                      children: [
                        Text(isBn ? "সঠিকতা" : "Accuracy", style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                        Text("${accuracy.toInt()}%", style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32))),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // AI Random Forest Recommendation Card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF004D40).withValues(alpha: 0.06),
                      const Color(0xFF00796B).withValues(alpha: 0.12),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF00796B).withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.psychology_rounded, color: Color(0xFF00695C), size: 22),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            isBn ? "AI অসুবিধা নির্ধারণ (Random Forest)" : "AI Adaptive Next Level",
                            style: const TextStyle(
                              fontSize: 13,
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
                        fontSize: 12,
                        color: AppTheme.textPrimary,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: Text(isBn ? "মেনু" : "Exit", style: const TextStyle(fontSize: 15)),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              _startNewGame(nextDifficulty);
            },
            icon: Icon(
              nextDifficulty != _selectedDifficulty
                  ? Icons.auto_awesome_rounded
                  : Icons.replay_rounded,
              size: 18,
            ),
            label: Text(
              nextDifficulty != _selectedDifficulty
                  ? (isBn ? "AI প্রস্তাবিত স্তর খেলুন" : "Play AI Next Level")
                  : (isBn ? "আবার খেলুন" : "Play Again"),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00695C),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isBn = widget.isBengali;

    int crossAxisCount = 3;
    if (_selectedDifficulty == 2) crossAxisCount = 4;
    if (_selectedDifficulty == 3) crossAxisCount = 4;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          isBn ? "কার্ড ম্যাচিং খেলা" : "Card Matching Game",
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        backgroundColor: const Color(0xFF00695C),
        foregroundColor: Colors.white,
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: "Restart Game",
            onPressed: () => _startNewGame(_selectedDifficulty),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Top Status & Stats Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              color: Colors.white,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Moves counter
                  _buildStatBadge(
                    icon: Icons.touch_app_rounded,
                    label: isBn ? "চাল: $_moves" : "Moves: $_moves",
                    color: const Color(0xFF1565C0),
                    bgColor: const Color(0xFFE3F2FD),
                  ),
                  // Matches counter
                  _buildStatBadge(
                    icon: Icons.check_circle_rounded,
                    label: isBn ? "জোড়া: $_matchedPairs/$_totalPairs" : "Pairs: $_matchedPairs/$_totalPairs",
                    color: const Color(0xFF2E7D32),
                    bgColor: const Color(0xFFE8F5E9),
                  ),
                  // Timer
                  _buildStatBadge(
                    icon: Icons.timer_rounded,
                    label: "${_secondsElapsed}s",
                    color: const Color(0xFFE65100),
                    bgColor: const Color(0xFFFFF3E0),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Difficulty Selector Tabs
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
              child: Row(
                children: [
                  Text(
                    isBn ? "লেভেল:" : "Level:",
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textSecondary),
                  ),
                  const SizedBox(width: 8),
                  _buildDifficultyChip(1, isBn ? "সহজ (৬)" : "Easy (6 Cards)"),
                  const SizedBox(width: 6),
                  _buildDifficultyChip(2, isBn ? "মাঝারি (৮)" : "Medium (8)"),
                  const SizedBox(width: 6),
                  _buildDifficultyChip(3, isBn ? "কঠিন (১২)" : "Level 3 (12)"),
                ],
              ),
            ),

            // Instruction Banner
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFE0F2F1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lightbulb_outline_rounded, color: Color(0xFF00796B), size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isBn
                          ? "কার্ডে ট্যাপ করে একই ছবি মিলিয়ে জোড়া তৈরি করুন।"
                          : "Tap two cards to flip and match identical pictures.",
                      style: const TextStyle(fontSize: 13, color: Color(0xFF004D40), fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Card Grid
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: GridView.builder(
                  physics: const BouncingScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: _gameCards.length,
                  itemBuilder: (context, index) {
                    final card = _gameCards[index];
                    return _buildCardTile(card, index, isBn);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDifficultyChip(int level, String label) {
    final isSelected = _selectedDifficulty == level;
    return InkWell(
      onTap: () => _startNewGame(level),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF00695C) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? const Color(0xFF00695C) : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : AppTheme.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildStatBadge({
    required IconData icon,
    required String label,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildCardTile(CardItem card, int index, bool isBn) {
    final bool isFaceUp = card.isFlipped || card.isMatched;

    return GestureDetector(
      onTap: () => _onCardTap(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: isFaceUp
              ? (card.isMatched ? const Color(0xFFE8F5E9) : Colors.white)
              : const Color(0xFF00695C),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isFaceUp
                ? (card.isMatched ? const Color(0xFF4CAF50) : card.color)
                : Colors.teal.shade700,
            width: isFaceUp ? 2.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isFaceUp
                  ? (card.isMatched ? Colors.green.withAlpha(50) : card.color.withAlpha(40))
                  : Colors.black.withAlpha(20),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: isFaceUp
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    card.icon,
                    size: _selectedDifficulty == 3 ? 36 : 46,
                    color: card.color,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isBn ? card.nameBn : card.nameEn,
                    style: TextStyle(
                      fontSize: _selectedDifficulty == 3 ? 11 : 13,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (card.isMatched) ...[
                    const SizedBox(height: 2),
                    const Icon(Icons.check_circle, size: 14, color: Color(0xFF4CAF50)),
                  ],
                ],
              )
            : Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(30),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.question_mark_rounded,
                        size: 26,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isBn ? "ট্যাপ করুন" : "TAP",
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.white70,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
