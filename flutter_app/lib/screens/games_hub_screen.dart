import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'pattern_memory_game_screen.dart';
import 'card_matching_game_screen.dart';
import 'word_recall_game_screen.dart';
import 'number_sequence_game_screen.dart';

class GamesHubScreen extends StatelessWidget {
  final bool isBengali;

  const GamesHubScreen({super.key, this.isBengali = false});

  @override
  Widget build(BuildContext context) {
    final isBn = isBengali;

    final List<Map<String, dynamic>> allGames = [
      {
        "title": isBn ? "প্যাটার্ন মেমোরি" : "Pattern Memory",
        "desc": isBn ? "রঙিন প্যাটার্ন মনে রাখুন ও পুনরাবৃত্তি করুন" : "Remember and repeat the glowing tile sequence",
        "icon": Icons.grid_view_rounded,
        "color": const Color(0xFFE8F5E9),
        "iconColor": const Color(0xFF2E7D32),
        "difficulty": isBn ? "সহজ" : "Easy",
      },
      {
        "title": isBn ? "কার্ড ম্যাচিং" : "Card Matching",
        "desc": isBn ? "একই ধরণের ছবি বা কার্ড খুঁজে মেলান" : "Flip cards and find matching pairs of familiar images",
        "icon": Icons.style_rounded,
        "color": const Color(0xFFE3F2FD),
        "iconColor": const Color(0xFF1565C0),
        "difficulty": isBn ? "মাঝারি" : "Medium",
      },
      {
        "title": isBn ? "শব্দ স্মরণ" : "Word Recall",
        "desc": isBn ? "সহজ শব্দ ও পরিচিত বস্তুর নাম মনে করুন" : "Identify everyday objects and match with their names",
        "icon": Icons.menu_book_rounded,
        "color": const Color(0xFFFFF3E0),
        "iconColor": const Color(0xFFE65100),
        "difficulty": isBn ? "সহজ" : "Easy",
      },
      {
        "title": isBn ? "সংখ্যা ক্রম" : "Number Sequence",
        "desc": isBn ? "সংখ্যার ক্রম দেখে মনে রাখুন ও একই ক্রমে ট্যাপ করুন" : "Watch the numbers flash, then repeat the same sequence",
        "icon": Icons.pin_rounded,
        "color": const Color(0xFFF3E5F5),
        "iconColor": const Color(0xFF7B1FA2),
        "difficulty": isBn ? "মাঝারি" : "Medium",
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(isBn ? "সকল মস্তিষ্কের খেলা" : "Cognitive Games"),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: allGames.length,
        itemBuilder: (context, index) {
          final game = allGames[index];
          return Card(
            elevation: 2,
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            color: Colors.white,
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () {
                if (index == 0) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PatternMemoryGameScreen(isBengali: isBn),
                    ),
                  );
                } else if (index == 1) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CardMatchingGameScreen(isBengali: isBn),
                    ),
                  );
                } else if (index == 2) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => WordRecallGameScreen(isBengali: isBn),
                    ),
                  );
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => NumberSequenceGameScreen(isBengali: isBn),
                    ),
                  );
                }
              },
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    Container(
                      width: 65,
                      height: 65,
                      decoration: BoxDecoration(
                        color: game['color'],
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(game['icon'], size: 36, color: game['iconColor']),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Text(
                                  game['title'],
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textPrimary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  game['difficulty'],
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade700),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            game['desc'],
                            style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.play_circle_fill_rounded, size: 38, color: AppTheme.primary),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
