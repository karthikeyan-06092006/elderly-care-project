import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../theme/app_theme.dart';
import '../services/ml_difficulty_service.dart';
import '../services/caregiver_trend_service.dart';

enum WordRecallDifficulty { easy, medium, hard }

class WordRecallItem {
  final int id;
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final String questionEn;
  final String questionBn;
  final String correctWordEn;
  final String correctWordBn;
  final List<String> optionsEn;
  final List<String> optionsBn;
  final String categoryEn;
  final String categoryBn;
  final String hintEn;
  final String hintBn;

  const WordRecallItem({
    required this.id,
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    required this.questionEn,
    required this.questionBn,
    required this.correctWordEn,
    required this.correctWordBn,
    required this.optionsEn,
    required this.optionsBn,
    required this.categoryEn,
    required this.categoryBn,
    required this.hintEn,
    required this.hintBn,
  });
}

class WordRecallGameScreen extends StatefulWidget {
  final bool isBengali;

  const WordRecallGameScreen({super.key, this.isBengali = false});

  @override
  State<WordRecallGameScreen> createState() => _WordRecallGameScreenState();
}

class _WordRecallGameScreenState extends State<WordRecallGameScreen> with SingleTickerProviderStateMixin {
  final FlutterTts _flutterTts = FlutterTts();
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;

  WordRecallDifficulty _currentDifficulty = WordRecallDifficulty.easy;

  // 1. Easy Questions Bank (2 Distinct Options, Direct Visual Clue)
  static const List<WordRecallItem> _easyQuestions = [
    WordRecallItem(
      id: 101,
      icon: Icons.apple_rounded,
      iconColor: Color(0xFFD32F2F),
      bgColor: Color(0xFFFFEBEE),
      questionEn: "What is this fruit?",
      questionBn: "এই ফলটির নাম কী?",
      correctWordEn: "Apple",
      correctWordBn: "আপেল",
      optionsEn: ["Apple", "Car"],
      optionsBn: ["আপেল", "গাড়ি"],
      categoryEn: "Fresh Fruit",
      categoryBn: "তাজা ফল",
      hintEn: "A sweet, red fruit that grows on trees.",
      hintBn: "একটি সুস্বাদু লাল ফল।",
    ),
    WordRecallItem(
      id: 102,
      icon: Icons.pets_rounded,
      iconColor: Color(0xFFE65100),
      bgColor: Color(0xFFFFF3E0),
      questionEn: "Which pet animal says 'Meow'?",
      questionBn: "কোন প্রাণী 'মিউ মিউ' ডাকে?",
      correctWordEn: "Cat",
      correctWordBn: "বিড়াল",
      optionsEn: ["Cat", "Chair"],
      optionsBn: ["বিড়াল", "চেয়ার"],
      categoryEn: "Friendly Pet",
      categoryBn: "পোষা প্রাণী",
      hintEn: "A furry little friend who drinks milk.",
      hintBn: "দুধ খেতে ভালোবাসে এমন পোষা প্রাণী।",
    ),
    WordRecallItem(
      id: 103,
      icon: Icons.local_cafe_rounded,
      iconColor: Color(0xFF6D4C41),
      bgColor: Color(0xFFEFEBE9),
      questionEn: "What warm morning drink is in this cup?",
      questionBn: "সকালের কাপে কোন গরম পানীয় থাকে?",
      correctWordEn: "Tea / Chai",
      correctWordBn: "চা",
      optionsEn: ["Tea / Chai", "Cold Ice"],
      optionsBn: ["চা", "বরফ"],
      categoryEn: "Warm Beverage",
      categoryBn: "গরম পানীয়",
      hintEn: "Served hot in a cup, enjoyed in the morning.",
      hintBn: "সকালে কাপে গরম পরিবেশন করা হয়।",
    ),
    WordRecallItem(
      id: 104,
      icon: Icons.home_rounded,
      iconColor: Color(0xFF1976D2),
      bgColor: Color(0xFFE3F2FD),
      questionEn: "Where do we live with family?",
      questionBn: "আমরা পরিবারের সাথে কোথায় থাকি?",
      correctWordEn: "House",
      correctWordBn: "বাড়ি / ঘর",
      optionsEn: ["House", "Bus"],
      optionsBn: ["বাড়ি / ঘর", "বাস"],
      categoryEn: "Home & Shelter",
      categoryBn: "আবাসস্থল",
      hintEn: "A safe, loving home with our family.",
      hintBn: "পরিবারের সাথে থাকার নিরাপদ স্থান।",
    ),
    WordRecallItem(
      id: 105,
      icon: Icons.local_florist_rounded,
      iconColor: Color(0xFFC2185B),
      bgColor: Color(0xFFFCE4EC),
      questionEn: "What blooms with lovely petals?",
      questionBn: "গাছে সুন্দর পাপড়ি নিয়ে কী ফোটে?",
      correctWordEn: "Flower",
      correctWordBn: "ফুল",
      optionsEn: ["Flower", "Stone"],
      optionsBn: ["ফুল", "পাথর"],
      categoryEn: "Nature & Garden",
      categoryBn: "প্রকৃতি ও বাগান",
      hintEn: "Smells sweet and blooms in garden bushes.",
      hintBn: "বাগানে ফোটে এবং মিষ্টি সুবাস দেয়।",
    ),
    WordRecallItem(
      id: 106,
      icon: Icons.directions_car_rounded,
      iconColor: Color(0xFF00796B),
      bgColor: Color(0xFFE0F2F1),
      questionEn: "What vehicle drives on the road?",
      questionBn: "রাস্তায় কোন গাড়িটি চলে?",
      correctWordEn: "Car",
      correctWordBn: "গাড়ি",
      optionsEn: ["Car", "Boat"],
      optionsBn: ["গাড়ি", "নৌকা"],
      categoryEn: "Vehicle & Travel",
      categoryBn: "যানবাহন",
      hintEn: "Has 4 wheels and drives on streets.",
      hintBn: "চার চাকার বাহন যা রাস্তায় চলে।",
    ),
  ];

  // 2. Medium Questions Bank (4 Options Grid, Functional Everyday Objects)
  static const List<WordRecallItem> _mediumQuestions = [
    WordRecallItem(
      id: 201,
      icon: Icons.beach_access_rounded,
      iconColor: Color(0xFF0288D1),
      bgColor: Color(0xFFE1F5FE),
      questionEn: "What do we use to stay dry when it rains?",
      questionBn: "বৃষ্টিতে ভিজে না যেতে আমরা কী ব্যবহার করি?",
      correctWordEn: "Umbrella",
      correctWordBn: "ছাতা",
      optionsEn: ["Umbrella", "Hat", "Pillow", "Chair"],
      optionsBn: ["ছাতা", "টুপি", "বালিশ", "চেয়ার"],
      categoryEn: "Weather Protection",
      categoryBn: "আবহাওয়া সুরক্ষা",
      hintEn: "Opens up overhead to block rain drops.",
      hintBn: "মাথার ওপর মেলে ধরে বৃষ্টি আটকানো হয়।",
    ),
    WordRecallItem(
      id: 202,
      icon: Icons.bakery_dining_rounded,
      iconColor: Color(0xFFF57F17),
      bgColor: Color(0xFFFFFDE7),
      questionEn: "Which sweet yellow fruit is peeled before eating?",
      questionBn: "খোসা ছাড়িয়ে কোন মিষ্টি হলুদ ফল খাওয়া হয়?",
      correctWordEn: "Banana",
      correctWordBn: "কলা",
      optionsEn: ["Banana", "Orange", "Lemon", "Grape"],
      optionsBn: ["কলা", "কমলালেবু", "লেবু", "আঙুর"],
      categoryEn: "Nutritious Fruit",
      categoryBn: "পুষ্টিকর ফল",
      hintEn: "Curved yellow fruit rich in energy and potassium.",
      hintBn: "হলুদ রঙের পুষ্টিকর ফল।",
    ),
    WordRecallItem(
      id: 203,
      icon: Icons.pets_rounded,
      iconColor: Color(0xFF6D4C41),
      bgColor: Color(0xFFEFEBE9),
      questionEn: "Which loyal animal barks and guards the house?",
      questionBn: "কোন বিশ্বস্ত প্রাণী ঘেউ ঘেউ করে এবং পাহারা দেয়?",
      correctWordEn: "Dog",
      correctWordBn: "কুকুর",
      optionsEn: ["Dog", "Cat", "Cow", "Rabbit"],
      optionsBn: ["কুকুর", "বিড়াল", "গরু", "খরগোশ"],
      categoryEn: "Loyal Guardian",
      categoryBn: "বিশ্বস্ত বন্ধু",
      hintEn: "Man's best friend that barks happily.",
      hintBn: "বিশ্বস্ত গৃহপালিত প্রাণী।",
    ),
    WordRecallItem(
      id: 204,
      icon: Icons.wb_sunny_rounded,
      iconColor: Color(0xFFE65100),
      bgColor: Color(0xFFFFF3E0),
      questionEn: "What gives bright daylight and morning warmth?",
      questionBn: "দিনের বেলা উজ্জ্বল আলো এবং উষ্ণতা কে দেয়?",
      correctWordEn: "Sun",
      correctWordBn: "সূর্য",
      optionsEn: ["Sun", "Moon", "Stars", "Cloud"],
      optionsBn: ["সূর্য", "চাঁদ", "তারা", "মেঘ"],
      categoryEn: "Solar System",
      categoryBn: "মহাকাশ ও দিন",
      hintEn: "Shines in the sky from dawn till evening.",
      hintBn: "পূর্ব আকাশে ভোরে উদিত হয়।",
    ),
    WordRecallItem(
      id: 205,
      icon: Icons.menu_book_rounded,
      iconColor: Color(0xFF5E35B1),
      bgColor: Color(0xFFEDE7F6),
      questionEn: "What do we open to read knowledge and stories?",
      questionBn: "আমরা পাতা উল্টে জ্ঞান ও গল্প কী থেকে পড়ি?",
      correctWordEn: "Book",
      correctWordBn: "বই",
      optionsEn: ["Book", "Spoon", "Mirror", "Pillow"],
      optionsBn: ["বই", "চামচ", "আয়না", "বালিশ"],
      categoryEn: "Knowledge & Reading",
      categoryBn: "পড়াশোনা ও জ্ঞান",
      hintEn: "Contains chapters, pages, and wonderful stories.",
      hintBn: "পাতায় গল্প ও তথ্য লেখা থাকে।",
    ),
    WordRecallItem(
      id: 206,
      icon: Icons.access_time_filled_rounded,
      iconColor: Color(0xFF00796B),
      bgColor: Color(0xFFE0F2F1),
      questionEn: "What shows the exact time of day on the wall?",
      questionBn: "দেওয়ালে থাকা কোন বস্তুটি সঠিক সময় দেখায়?",
      correctWordEn: "Clock",
      correctWordBn: "ঘড়ি",
      optionsEn: ["Clock", "Plate", "Shoe", "Door"],
      optionsBn: ["ঘড়ি", "থালা", "জুতো", "দরজা"],
      categoryEn: "Time & Schedule",
      categoryBn: "সময় ও রুটিন",
      hintEn: "Has numbers 1 to 12 and ticking hands.",
      hintBn: "কাঁটা ঘুরে ১ থেকে ১২ পর্যন্ত সময় জানায়।",
    ),
  ];

  // 3. Hard Questions Bank (4 Options, Semantic Riddles, Memory Tested Without Direct Picture Spoilers)
  static const List<WordRecallItem> _hardQuestions = [
    WordRecallItem(
      id: 301,
      icon: Icons.calendar_month_rounded,
      iconColor: Color(0xFF3949AB),
      bgColor: Color(0xFFE8EAF6),
      questionEn: "Which day comes between Monday and Wednesday?",
      questionBn: "সোমবার এবং বুধবারের মাঝে কোন দিন আসে?",
      correctWordEn: "Tuesday",
      correctWordBn: "মঙ্গলবার",
      optionsEn: ["Tuesday", "Thursday", "Friday", "Sunday"],
      optionsBn: ["মঙ্গলবার", "বৃহস্পতিবার", "শুক্রবার", "রবিবার"],
      categoryEn: "Days & Calendar",
      categoryBn: "সপ্তাহ ও ক্যালেন্ডার",
      hintEn: "The second working day of the traditional week.",
      hintBn: "সপ্তাহের দ্বিতীয় কাজের দিন।",
    ),
    WordRecallItem(
      id: 302,
      icon: Icons.edit_note_rounded,
      iconColor: Color(0xFF00695C),
      bgColor: Color(0xFFE0F2F1),
      questionEn: "What instrument is used to write with ink on paper?",
      questionBn: "কাগজে কালি দিয়ে লিখতে কোন জিনিসটি ব্যবহার করা হয়?",
      correctWordEn: "Pen",
      correctWordBn: "কলম",
      optionsEn: ["Pen", "Eraser", "Ruler", "Scissors"],
      optionsBn: ["কলম", "রাবার", "স্কেল", "কাঁচি"],
      categoryEn: "Writing & Stationery",
      categoryBn: "লেখার উপকরণ",
      hintEn: "Has a nib or ballpoint that flows with blue or black ink.",
      hintBn: "নীল বা কালো কালির মাধ্যমে লেখা তৈরি করে।",
    ),
    WordRecallItem(
      id: 303,
      icon: Icons.restaurant_rounded,
      iconColor: Color(0xFFD84315),
      bgColor: Color(0xFFFBE9E7),
      questionEn: "What is the first morning meal of the day called?",
      questionBn: "দিনের শুরুর প্রথম সকালের খাবারকে কী বলা হয়?",
      correctWordEn: "Breakfast",
      correctWordBn: "প্রাতরাশ / সকালের নাস্তা",
      optionsEn: ["Breakfast", "Lunch", "Dinner", "Snack"],
      optionsBn: ["প্রাতরাশ / নাস্তা", "দুপুরের খাবার", "রাতের খাবার", "স্ন্যাকস"],
      categoryEn: "Daily Meals",
      categoryBn: "দৈনিক আহার",
      hintEn: "Breaks your night fast soon after waking up.",
      hintBn: "ঘুম থেকে ওঠার পর সকালের প্রথম আহার।",
    ),
    WordRecallItem(
      id: 304,
      icon: Icons.ac_unit_rounded,
      iconColor: Color(0xFF0277BD),
      bgColor: Color(0xFFE1F5FE),
      questionEn: "Which cold season requires wearing warm sweaters?",
      questionBn: "কোন ঠান্ডা ঋতুতে গরম সোয়েটার পরতে হয়?",
      correctWordEn: "Winter",
      correctWordBn: "শীতকাল",
      optionsEn: ["Winter", "Summer", "Monsoon", "Autumn"],
      optionsBn: ["শীতকাল", "গ্রীষ্মকাল", "বর্ষাকাল", "শরৎকাল"],
      categoryEn: "Seasons & Weather",
      categoryBn: "ঋতু ও আবহাওয়া",
      hintEn: "Brings cold mornings, fog, and warm woolen clothes.",
      hintBn: "কুয়াশা ও ঠান্ডা বাতাসের ঋতু।",
    ),
    WordRecallItem(
      id: 305,
      icon: Icons.hourglass_top_rounded,
      iconColor: Color(0xFF6A1B9A),
      bgColor: Color(0xFFF3E5F5),
      questionEn: "How many hours are there in one complete day?",
      questionBn: "একটি সম্পূর্ণ দিনে কত ঘণ্টা সময় থাকে?",
      correctWordEn: "24 Hours",
      correctWordBn: "২৪ ঘণ্টা",
      optionsEn: ["24 Hours", "12 Hours", "48 Hours", "60 Hours"],
      optionsBn: ["২৪ ঘণ্টা", "১২ ঘণ্টা", "৪৮ ঘণ্টা", "৬০ ঘণ্টা"],
      categoryEn: "Time Measurement",
      categoryBn: "সময়ের গণনা",
      hintEn: "Equals one full day and night cycle.",
      hintBn: "একদিন ও একরাতের সম্মিলিত সময়।",
    ),
    WordRecallItem(
      id: 306,
      icon: Icons.medical_services_rounded,
      iconColor: Color(0xFF2E7D32),
      bgColor: Color(0xFFE8F5E9),
      questionEn: "What medical professional examines patients and prescribes medicine?",
      questionBn: "কোন স্বাস্থ্যকর্মী রোগী দেখেন এবং ওষুধ লিখে দেন?",
      correctWordEn: "Doctor",
      correctWordBn: "চিকিৎসক / ডাক্তার",
      optionsEn: ["Doctor", "Driver", "Chef", "Tailor"],
      optionsBn: ["ডাক্তার", "চালক", "রাঁধুনি", "দর্জি"],
      categoryEn: "Healthcare Heroes",
      categoryBn: "স্বাস্থ্যসেবা",
      hintEn: "Uses a stethoscope to check your heart and health.",
      hintBn: "স্টেথোস্কোপ দিয়ে স্বাস্থ্য পরীক্ষা করেন।",
    ),
  ];

  late List<WordRecallItem> _sessionQuestions;
  int _currentIndex = 0;
  int _score = 0;
  int _firstTryCorrect = 0;
  int _mistakesCount = 0;
  DateTime _sessionStartTime = DateTime.now();
  int? _selectedOptionIndex;
  bool _hasAnswered = false;
  bool _isAnswerCorrect = false;
  bool _showHint = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutBack,
    );
    _initTts();
    _startNewSession();
  }

  Future<void> _initTts() async {
    try {
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setSpeechRate(0.42); // Clear and slow pace for seniors
      await _flutterTts.setPitch(1.0);
    } catch (e) {
      debugPrint("TTS init error: $e");
    }
  }

  void _startNewSession() {
    List<WordRecallItem> pool;
    switch (_currentDifficulty) {
      case WordRecallDifficulty.easy:
        pool = _easyQuestions;
        break;
      case WordRecallDifficulty.medium:
        pool = _mediumQuestions;
        break;
      case WordRecallDifficulty.hard:
        pool = _hardQuestions;
        break;
    }

    final shuffled = List<WordRecallItem>.from(pool)..shuffle(Random());
    _sessionQuestions = shuffled.take(5).toList();
    _currentIndex = 0;
    _score = 0;
    _firstTryCorrect = 0;
    _mistakesCount = 0;
    _sessionStartTime = DateTime.now();
    _selectedOptionIndex = null;
    _hasAnswered = false;
    _isAnswerCorrect = false;
    _showHint = false;
    _animController.forward(from: 0.0);
    _speakCurrentQuestion();
  }

  void _changeDifficulty(WordRecallDifficulty newDifficulty) {
    if (_currentDifficulty == newDifficulty) return;
    setState(() {
      _currentDifficulty = newDifficulty;
    });
    _startNewSession();
  }

  @override
  void dispose() {
    _flutterTts.stop();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _speakCurrentQuestion() async {
    if (_sessionQuestions.isEmpty) return;
    final item = _sessionQuestions[_currentIndex];
    final text = widget.isBengali
        ? "${item.questionBn}। সঠিক উত্তরটি বেছে নিন।"
        : "${item.questionEn}. Choose the correct answer.";
    try {
      await _flutterTts.setLanguage(widget.isBengali ? "bn-BD" : "en-US");
      await _flutterTts.speak(text);
    } catch (_) {}
  }

  void _onOptionSelected(int index) {
    if (_hasAnswered && _isAnswerCorrect) return;

    final item = _sessionQuestions[_currentIndex];
    final isBn = widget.isBengali;
    final selectedWord = isBn ? item.optionsBn[index] : item.optionsEn[index];
    final correctWord = isBn ? item.correctWordBn : item.correctWordEn;

    setState(() {
      _selectedOptionIndex = index;
      _hasAnswered = true;
    });

    if (selectedWord == correctWord) {
      // Correct!
      setState(() {
        _isAnswerCorrect = true;
        _score += 20;
        if (!_showHint) {
          _firstTryCorrect++;
        }
      });

      _speakFeedback(true);

      // Auto advance to next question after 1.5 seconds
      Future.delayed(const Duration(milliseconds: 1600), () {
        if (!mounted) return;
        if (_currentIndex < _sessionQuestions.length - 1) {
          setState(() {
            _currentIndex++;
            _selectedOptionIndex = null;
            _hasAnswered = false;
            _isAnswerCorrect = false;
            _showHint = false;
          });
          _animController.forward(from: 0.0);
          _speakCurrentQuestion();
        } else {
          _showVictoryDialog();
        }
      });
    } else {
      // Incorrect - friendly hint
      setState(() {
        _isAnswerCorrect = false;
        _showHint = true;
        _mistakesCount++;
      });
      _speakFeedback(false);
    }
  }

  Future<void> _speakFeedback(bool isCorrect) async {
    final isBn = widget.isBengali;
    final item = _sessionQuestions[_currentIndex];
    String speech;

    if (isCorrect) {
      speech = isBn
          ? "চমৎকার! এটি হলো ${item.correctWordBn}।"
          : "Splendid! That is correct: ${item.correctWordEn}.";
    } else {
      speech = isBn
          ? "আবার চেষ্টা করুন। সংকেত: ${item.hintBn}"
          : "Try again! Hint: ${item.hintEn}";
    }

    try {
      await _flutterTts.setLanguage(isBn ? "bn-BD" : "en-US");
      await _flutterTts.speak(speech);
    } catch (_) {}
  }

  void _showVictoryDialog() {
    final isBn = widget.isBengali;
    final int stars = _firstTryCorrect >= 4 ? 3 : (_firstTryCorrect >= 2 ? 2 : 1);
    final double elapsedSeconds = DateTime.now().difference(_sessionStartTime).inSeconds.toDouble();
    final double accuracy = (_firstTryCorrect / max(1, _sessionQuestions.length)) * 100.0;

    // 🌲 On-Device Random Forest ML Difficulty Evaluation
    final performance = GamePerformanceData(
      score: _score.toDouble(),
      completionTimeSeconds: elapsedSeconds,
      accuracyPercentage: accuracy,
      mistakesCount: _mistakesCount,
      currentLevel: _currentDifficulty.index,
      gameTitle: 'Word Recall',
    );

    final prediction = MlDifficultyService.predictNextDifficulty(performance);
    final WordRecallDifficulty recommendedDiff = WordRecallDifficulty.values[prediction.recommendedLevelIndex.clamp(0, 2)];

    // Background log to backend and local trend storage
    MlDifficultyService.logSessionToBackend(
      patientId: 'demo-patient-001',
      performance: performance,
      prediction: prediction,
    );

    CaregiverTrendService.recordSession(GameSessionRecord(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      patientId: 'demo-patient-001',
      patientName: 'Karthikeyan',
      gameTitle: 'Word Recall',
      score: _score.toDouble(),
      completionTimeSeconds: elapsedSeconds,
      accuracyPercentage: accuracy,
      mistakesCount: _mistakesCount,
      difficultyLevel: _currentDifficulty.name.toUpperCase(),
      aiRecommendedLevel: recommendedDiff.name.toUpperCase(),
      aiConfidence: prediction.confidence,
      playedAt: DateTime.now(),
    ));

    String levelName;
    switch (_currentDifficulty) {
      case WordRecallDifficulty.easy:
        levelName = isBn ? "সহজ স্তর (Easy)" : "Easy Level";
        break;
      case WordRecallDifficulty.medium:
        levelName = isBn ? "মধ্যম স্তর (Medium)" : "Medium Level";
        break;
      case WordRecallDifficulty.hard:
        levelName = isBn ? "কঠিন স্তর (Hard)" : "Hard Level";
        break;
    }

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
              child: const Icon(Icons.emoji_events_rounded, color: Colors.amber, size: 50),
            ),
            const SizedBox(height: 12),
            Text(
              isBn ? "🎉 চমৎকার শব্দ স্মরণ!" : "🎉 Splendid Word Recall!",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: AppTheme.textPrimary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: _getDifficultyColor(_currentDifficulty).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                levelName,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: _getDifficultyColor(_currentDifficulty),
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isBn
                  ? "আপনি এই স্তরের সমস্ত প্রশ্ন সফলভাবে সম্পন্ন করেছেন!"
                  : "You successfully completed all memory recall rounds!",
              style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 14),
            // Star rating
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (index) {
                return Icon(
                  Icons.star_rounded,
                  size: 40,
                  color: index < stars ? Colors.amber : Colors.grey.shade300,
                );
              }),
            ),
            const SizedBox(height: 14),
            // Performance stats
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
                      Text(isBn ? "স্কোর" : "Score", style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                      Text("$_score/100", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32))),
                    ],
                  ),
                  Container(height: 26, width: 1, color: Colors.grey.shade400),
                  Column(
                    children: [
                      Text(isBn ? "সময়" : "Time", style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                      Text("${elapsedSeconds.toInt()}s", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32))),
                    ],
                  ),
                  Container(height: 26, width: 1, color: Colors.grey.shade400),
                  Column(
                    children: [
                      Text(isBn ? "সঠিকতা" : "Accuracy", style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                      Text("${accuracy.toInt()}%", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32))),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            // AI Random Forest Recommendation Card
            Container(
              padding: const EdgeInsets.all(12),
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
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: Text(isBn ? "মেনু" : "Exit", style: const TextStyle(fontSize: 16)),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              _changeDifficulty(recommendedDiff);
            },
            icon: const Icon(Icons.auto_awesome_rounded, size: 16),
            label: Text(
              isBn
                  ? "AI প্রস্তাবিত স্তর খেলুন"
                  : "Play AI ${recommendedDiff.name.toUpperCase()}",
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00695C),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              _startNewSession();
            },
            icon: const Icon(Icons.replay_rounded, size: 18),
            label: Text(isBn ? "আবার খেলুন" : "Replay"),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF37474F),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Color _getDifficultyColor(WordRecallDifficulty diff) {
    switch (diff) {
      case WordRecallDifficulty.easy:
        return const Color(0xFF2E7D32);
      case WordRecallDifficulty.medium:
        return const Color(0xFFE65100);
      case WordRecallDifficulty.hard:
        return const Color(0xFFC2185B);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isBn = widget.isBengali;
    if (_sessionQuestions.isEmpty) return const Scaffold();

    final item = _sessionQuestions[_currentIndex];
    final options = isBn ? item.optionsBn : item.optionsEn;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          isBn ? "শব্দ স্মরণ খেলা" : "Word Recall Game",
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        backgroundColor: const Color(0xFF00695C),
        foregroundColor: Colors.white,
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.volume_up_rounded),
            tooltip: "Listen Audio Prompt",
            onPressed: _speakCurrentQuestion,
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: "Restart Session",
            onPressed: _startNewSession,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 14.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Difficulty Level Selector Tabs
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE0ECE8),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    _buildDifficultyTab(
                      difficulty: WordRecallDifficulty.easy,
                      label: isBn ? "সহজ" : "Easy",
                      icon: Icons.looks_one_rounded,
                      activeColor: const Color(0xFF2E7D32),
                    ),
                    _buildDifficultyTab(
                      difficulty: WordRecallDifficulty.medium,
                      label: isBn ? "মধ্যম" : "Medium",
                      icon: Icons.looks_two_rounded,
                      activeColor: const Color(0xFFE65100),
                    ),
                    _buildDifficultyTab(
                      difficulty: WordRecallDifficulty.hard,
                      label: isBn ? "কঠিন" : "Hard",
                      icon: Icons.looks_3_rounded,
                      activeColor: const Color(0xFFC2185B),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // 2. Progress Bar & Score Bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0F2F1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      isBn
                          ? "প্রশ্ন: ${_currentIndex + 1} / ${_sessionQuestions.length}"
                          : "Round: ${_currentIndex + 1} / ${_sessionQuestions.length}",
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF00695C), fontSize: 14),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3E0),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.stars_rounded, color: Colors.orange, size: 18),
                        const SizedBox(width: 4),
                        Text(
                          isBn ? "স্কোর: $_score" : "Score: $_score",
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFE65100), fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Progress linear indicator
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: (_currentIndex + 1) / _sessionQuestions.length,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(_getDifficultyColor(_currentDifficulty)),
                  minHeight: 6,
                ),
              ),
              const SizedBox(height: 16),

              // 3. Main Question Card with Adaptive Visual Clue
              ScaleTransition(
                scale: _scaleAnimation,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    border: Border.all(color: const Color(0xFFE0E0E0)),
                  ),
                  child: Column(
                    children: [
                      // Category Tag
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                        decoration: BoxDecoration(
                          color: item.bgColor,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: item.iconColor.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          isBn ? item.categoryBn : item.categoryEn,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: item.iconColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Large Recognizable Icon
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: item.bgColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: item.iconColor.withValues(alpha: 0.4), width: 3),
                        ),
                        child: Icon(item.icon, size: 58, color: item.iconColor),
                      ),
                      const SizedBox(height: 14),

                      // Question Prompt
                      Text(
                        isBn ? item.questionBn : item.questionEn,
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),

                      // Speaker button for TTS read aloud
                      InkWell(
                        onTap: _speakCurrentQuestion,
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F8E9),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFF81C784)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.volume_up_rounded, color: Color(0xFF2E7D32), size: 18),
                              const SizedBox(width: 6),
                              Text(
                                isBn ? "উচ্চৈঃস্বরে শুনুন" : "Listen Prompt",
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF2E7D32),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 4. Hint Banner if wrong attempt
              if (_showHint && !_isAnswerCorrect)
                Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF9C4),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFFBC02D)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.lightbulb_rounded, color: Color(0xFFF57F17), size: 22),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          isBn ? "সংকেত: ${item.hintBn}" : "Hint: ${item.hintEn}",
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFFE65100),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // 5. Accessible Option Buttons (2 Large Options for Easy, 4 Grid Options for Medium/Hard)
              if (_currentDifficulty == WordRecallDifficulty.easy)
                _buildEasyOptionCards(options)
              else
                _buildGridOptionCards(options),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDifficultyTab({
    required WordRecallDifficulty difficulty,
    required String label,
    required IconData icon,
    required Color activeColor,
  }) {
    final isSelected = _currentDifficulty == difficulty;
    return Expanded(
      child: GestureDetector(
        onTap: () => _changeDifficulty(difficulty),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: isSelected ? activeColor : Colors.grey.shade600),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? activeColor : Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEasyOptionCards(List<String> options) {
    return Row(
      children: List.generate(options.length, (index) {
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              left: index > 0 ? 8.0 : 0,
              right: index < options.length - 1 ? 8.0 : 0,
            ),
            child: _buildOptionButton(
              optionText: options[index],
              index: index,
              minHeight: 70,
            ),
          ),
        );
      }),
    );
  }

  Widget _buildGridOptionCards(List<String> options) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 2.2,
      ),
      itemCount: options.length,
      itemBuilder: (context, index) {
        return _buildOptionButton(
          optionText: options[index],
          index: index,
        );
      },
    );
  }

  Widget _buildOptionButton({
    required String optionText,
    required int index,
    double? minHeight,
  }) {
    final isSelected = _selectedOptionIndex == index;

    Color btnBgColor = Colors.white;
    Color borderColor = const Color(0xFFCFD8DC);
    Color textColor = AppTheme.textPrimary;
    IconData? trailingIcon;

    if (_hasAnswered) {
      if (isSelected && _isAnswerCorrect) {
        btnBgColor = const Color(0xFFE8F5E9);
        borderColor = const Color(0xFF2E7D32);
        textColor = const Color(0xFF2E7D32);
        trailingIcon = Icons.check_circle_rounded;
      } else if (isSelected && !_isAnswerCorrect) {
        btnBgColor = const Color(0xFFFFEBEE);
        borderColor = const Color(0xFFC62828);
        textColor = const Color(0xFFC62828);
        trailingIcon = Icons.cancel_rounded;
      }
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      constraints: minHeight != null ? BoxConstraints(minHeight: minHeight) : null,
      decoration: BoxDecoration(
        color: btnBgColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor, width: isSelected ? 2.5 : 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _onOptionSelected(index),
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    optionText,
                    style: TextStyle(
                      fontSize: minHeight != null ? 18 : 16,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (trailingIcon != null) ...[
                  const SizedBox(width: 6),
                  Icon(trailingIcon, color: textColor, size: 22),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
