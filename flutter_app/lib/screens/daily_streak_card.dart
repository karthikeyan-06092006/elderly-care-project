import 'package:flutter/material.dart';
import '../services/daily_streak_service.dart';
import 'pattern_memory_game_screen.dart';
import 'card_matching_game_screen.dart';
import 'word_recall_game_screen.dart';
import 'number_sequence_game_screen.dart';

class DailyStreakCard extends StatefulWidget {
  final String userKey;
  final bool isBengali;

  const DailyStreakCard({super.key, required this.userKey, this.isBengali = false});

  @override
  State<DailyStreakCard> createState() => _DailyStreakCardState();
}

class _DailyStreakCardState extends State<DailyStreakCard> {
  final DailyStreakService _service = DailyStreakService.instance;

  @override
  void initState() {
    super.initState();
    _service.load();
    _service.addListener(_onServiceChanged);
  }

  void _onServiceChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _service.removeListener(_onServiceChanged);
    super.dispose();
  }

  void _playTodayGame() {
    final isBn = widget.isBengali;
    Widget screen;
    switch (DailyStreakService.dailyGameIndex()) {
      case 1:
        screen = CardMatchingGameScreen(isBengali: isBn);
        break;
      case 2:
        screen = WordRecallGameScreen(isBengali: isBn);
        break;
      case 3:
        screen = NumberSequenceGameScreen(isBengali: isBn);
        break;
      default:
        screen = PatternMemoryGameScreen(isBengali: isBn);
    }
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen)).then((_) {
      _service.recordGamePlayed(widget.userKey);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isBn = widget.isBengali;
    final streak = _service.currentStreak(widget.userKey);
    final playedToday = _service.hasPlayedToday(widget.userKey);
    final sevenDays = DailyStreakService.lastSevenDays();

    const weekdays = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
    final gameInfo = _todayGameInfo(isBn);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF9800), Color(0xFFE65100)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE65100).withAlpha(55),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(45),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.local_fire_department_rounded, color: Colors.white, size: 30),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isBn ? "দৈনিক স্ট্রিক" : "Daily Streak",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      playedToday
                          ? (isBn ? "আজ খেলা হয়েছে। চমৎকার!" : "You played today. Amazing!")
                          : (isBn ? "প্রতিদিন খেলুন, স্ট্রিক বাড়ান" : "Play daily to keep your streak growing"),
                      style: const TextStyle(color: Color(0xFFFFE0B2), fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(50),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  children: [
                    Text(
                      '$streak',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        height: 1.1,
                      ),
                    ),
                    Text(
                      isBn ? "দিন" : "days",
                      style: const TextStyle(color: Color(0xFFFFE0B2), fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (i) {
              final played = _service.hasPlayedOn(widget.userKey, sevenDays[i]);
              final date = DateTime.parse(sevenDays[i]);
              final dowIndex = date.weekday % 7;
              return Column(
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: played ? Colors.white : Colors.white.withAlpha(35),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: played
                          ? const Icon(Icons.check_rounded, size: 15, color: Color(0xFFE65100))
                          : null,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    weekdays[dowIndex],
                    style: TextStyle(
                      color: played ? Colors.white : Colors.white.withAlpha(150),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              );
            }),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(32),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(45),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(gameInfo['icon'] as IconData, color: Colors.white, size: 26),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isBn ? "আজকের খেলা" : "Today's Game",
                        style: const TextStyle(color: Color(0xFFFFE0B2), fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        gameInfo['title'] as String,
                        style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: _playTodayGame,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFFE65100),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: Icon(playedToday ? Icons.replay_rounded : Icons.play_arrow_rounded, size: 20),
                  label: Text(
                    playedToday ? (isBn ? "আবার" : "Replay") : (isBn ? "খেলুন" : "Play"),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _todayGameInfo(bool isBn) {
    final games = [
      {
        'title': isBn ? 'প্যাটার্ন মেমোরি' : 'Pattern Memory',
        'icon': Icons.grid_view_rounded,
      },
      {
        'title': isBn ? 'কার্ড ম্যাচিং' : 'Card Matching',
        'icon': Icons.style_rounded,
      },
      {
        'title': isBn ? 'শব্দ স্মরণ' : 'Word Recall',
        'icon': Icons.menu_book_rounded,
      },
      {
        'title': isBn ? 'সংখ্যা ক্রম' : 'Number Sequence',
        'icon': Icons.pin_rounded,
      },
    ];
    return games[DailyStreakService.dailyGameIndex()];
  }
}