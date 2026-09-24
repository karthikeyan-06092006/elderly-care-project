import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/user_model.dart';
import 'profile_menu_screen.dart';
import 'games_hub_screen.dart';
import 'pattern_memory_game_screen.dart';
import 'card_matching_game_screen.dart';
import 'word_recall_game_screen.dart';

import '../services/api_service.dart';
import '../services/call_service.dart';
import '../services/app_settings.dart';
import '../services/daily_streak_service.dart';
import 'caretakers_screen.dart';
import 'daily_streak_card.dart';
import 'social_hub_screen.dart';
import 'voice_assistant_screen.dart';
import 'reminders_screen.dart';
import '../services/alarm_service.dart';

class PatientDashboardScreen extends StatefulWidget {
  final PatientProfile profile;
  final bool isBengali;

  const PatientDashboardScreen({
    super.key,
    required this.profile,
    this.isBengali = false,
  });

  @override
  State<PatientDashboardScreen> createState() => _PatientDashboardScreenState();
}

class _PatientDashboardScreenState extends State<PatientDashboardScreen> {
  late PatientProfile _currentProfile;
  late bool _isBengali;
  String _currentTheme = "Light";
  Timer? _midnightTimer;

  @override
  void initState() {
    super.initState();
    _currentProfile = widget.profile;
    _isBengali = widget.isBengali;
    _currentTheme = AppSettings.instance.theme;
    DailyStreakService.instance.load();
    _scheduleMidnightRefresh();
    _fetchCaretakersFromDb();
    _syncPatientAlarms();
    AlarmService.instance.startRoutineChecker(
      context: context,
      patientId: _currentProfile.userId.isNotEmpty ? _currentProfile.userId : _currentProfile.email,
      onStatusChanged: () {},
    );
  }

  Future<void> _syncPatientAlarms() async {
    try {
      final pid = _currentProfile.userId.isNotEmpty ? _currentProfile.userId : _currentProfile.email;
      final res = await ApiService.getPatientReminders(pid);
      if (res.success && res.data != null) {
        await AlarmService.instance.syncAllAlarms(res.data!);
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    AlarmService.instance.stopRoutineChecker();
    _midnightTimer?.cancel();
    super.dispose();
  }

  void _scheduleMidnightRefresh() {
    _midnightTimer?.cancel();
    final now = DateTime.now();
    final nextMidnight = DateTime(now.year, now.month, now.day + 1);
    final delay = nextMidnight.difference(now);
    _midnightTimer = Timer(delay, () {
      if (mounted) {
        setState(() {});
      }
      _scheduleMidnightRefresh();
    });
  }

  Future<void> _fetchCaretakersFromDb() async {
    try {
      final list = await ApiService.getPatientCaretakers(_currentProfile.email);
      if (!mounted) return;
      if (list.isNotEmpty) {
        final primaryItem = list.firstWhere(
          (c) => c.isPrimary,
          orElse: () => list.first,
        );
        final others = list
            .where((c) => c.caretakerId != primaryItem.caretakerId)
            .map((c) => c.toContact())
            .toList();
        setState(() {
          _currentProfile = _currentProfile.copyWith(
            primaryCaretaker: primaryItem.toContact(),
            otherCaretakers: others,
          );
        });
      }
    } catch (_) {}
  }

  Future<void> _makeCall(String phoneNumber) async {
    await CallService.makeDirectPhoneCall(
      context: context,
      phoneNumber: phoneNumber,
      isBengali: _isBengali,
    );
  }

  void _triggerEmergencyDialog() {
    final isBn = _isBengali;
    final primaryCt = _currentProfile.primaryCaretaker;
    final bool hasLinkedCaregiver = primaryCt.phone.isNotEmpty && primaryCt.relation != "Unlinked";

    if (!hasLinkedCaregiver) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          backgroundColor: Colors.white,
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.amber.shade100,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 30),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  isBn ? "যত্নশীল যুক্ত নেই" : "No Caregiver Linked",
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.black87),
                ),
              ),
            ],
          ),
          content: Text(
            isBn
                ? "জরুরি সাহায্যের জন্য আপনার অ্যাকাউন্টের সাথে কোনো যত্নশীল যুক্ত করা হয়নি। অনুগ্রহ করে আপনার কেয়ারটেকারকে কিউআর কোড স্ক্যান করতে বলুন।"
                : "No primary caregiver is linked to your account yet. Please ask your caregiver to scan your QR code to connect.",
            style: const TextStyle(fontSize: 15, height: 1.4, color: AppTheme.textPrimary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                isBn ? "বাতিল" : "Cancel",
                style: const TextStyle(fontSize: 16, color: AppTheme.textSecondary),
              ),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CaretakersScreen(
                      profile: _currentProfile,
                      isBengali: isBn,
                    ),
                  ),
                ).then((_) => _fetchCaretakersFromDb());
              },
              icon: const Icon(Icons.qr_code, color: Colors.white),
              label: Text(
                isBn ? "কিউআর কোড দেখুন" : "View My QR Code",
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.shade100,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 32),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                isBn ? "জরুরি সহায়তা (SOS)" : "Emergency SOS",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: Colors.red),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isBn
                  ? "প্রধান যত্নশীল ${primaryCt.name}-কে সরাসরি কল করা হবে এবং অন্যান্য যত্নশীলদের জরুরি বার্তা পাঠানো হবে।"
                  : "Calling primary caretaker ${primaryCt.name} (${primaryCt.phone}) and alerting all linked caregivers.",
              style: const TextStyle(fontSize: 16, height: 1.4, color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.phone_in_talk_rounded, color: Colors.red, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          primaryCt.name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Text(
                          primaryCt.phone,
                          style: const TextStyle(fontSize: 14, color: Colors.red, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              isBn ? "বাতিল" : "Cancel",
              style: const TextStyle(fontSize: 16, color: AppTheme.textSecondary),
            ),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              
              // 1. Dispatch SOS broadcast to backend & secondary caregivers
              ApiService.triggerSos(
                patientEmail: _currentProfile.email,
                patientName: _currentProfile.name,
                patientPhone: _currentProfile.phone,
              );

              // 2. Direct Phone Call to Primary Caretaker
              _makeCall(primaryCt.phone);

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    isBn
                        ? "জরুরি কল শুরু হয়েছে এবং অন্যান্য যত্নশীলদের অ্যালার্ট পাঠানো হয়েছে!"
                        : "Emergency call initiated & notifications dispatched to secondary caregivers!",
                  ),
                  backgroundColor: Colors.red.shade800,
                ),
              );
            },
            icon: const Icon(Icons.call, color: Colors.white),
            label: Text(
              isBn ? "এখনই কল করুন" : "Call Now",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _openVoiceAssistant() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VoiceAssistantScreen(
          isBengali: _isBengali,
          userName: _currentProfile.name,
        ),
      ),
    );
  }

  void _openProfileMenu() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfileMenuScreen(
          profile: _currentProfile,
          isBengali: _isBengali,
          currentTheme: _currentTheme,
          onProfileUpdated: (updated) {
            setState(() {
              _currentProfile = updated;
            });
          },
          onLanguageChanged: (newIsBn) {
            setState(() {
              _isBengali = newIsBn;
            });
          },
          onThemeChanged: (newTheme) {
            AppSettings.instance.setTheme(newTheme);
            setState(() {
              _currentTheme = newTheme;
            });
          },
        ),
      ),
    ).then((_) => _fetchCaretakersFromDb());
  }

  @override
  Widget build(BuildContext context) {
    final isBn = _isBengali;
    final profile = _currentProfile;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // 1. Top Custom App Bar with Left Profile Avatar Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
              child: Row(
                children: [
                  // Top Left Profile Avatar Button
                  GestureDetector(
                    onTap: _openProfileMenu,
                    child: Container(
                      padding: const EdgeInsets.all(2.5),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        border: Border.all(color: AppTheme.primary, width: 2.5),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primary.withAlpha(40),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          )
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 24,
                        backgroundColor: AppTheme.primaryLight,
                        child: ClipOval(
                          child: profile.photoPath != null
                              ? Image.file(
                                  File(profile.photoPath!),
                                  width: 48,
                                  height: 48,
                                  fit: BoxFit.cover,
                                )
                              : const Icon(
                                  Icons.person_rounded,
                                  size: 28,
                                  color: AppTheme.primary,
                                ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  // Title
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isBn ? "স্মৃতি কেয়ার" : "CognitiveCare",
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        Text(
                          isBn ? "প্রোফাইল মেনু খুলতে ছবিতে ট্যাপ করুন" : "Tap photo for profile & options",
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Fixed Emergency SOS Banner (always visible at top)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: ElevatedButton.icon(
                onPressed: _triggerEmergencyDialog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD32F2F),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: const Icon(Icons.emergency_rounded, size: 24, color: Colors.white),
                label: Text(
                  isBn ? "🚨 জরুরি সাহায্য (SOS Call)" : "🚨 Emergency Assistance (SOS)",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Daily Streak Game Card
                    DailyStreakCard(
                      userKey: _currentProfile.email,
                      isBengali: _isBengali,
                    ),
                    const SizedBox(height: 20),

                    // 2. Welcome Banner with Patient's Name
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF00796B), Color(0xFF004D40)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF004D40).withAlpha(40),
                            blurRadius: 12,
                            offset: const Offset(0, 5),
                          )
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                isBn ? "সুপ্রভাত," : "Good Day,",
                                style: const TextStyle(
                                  fontSize: 18,
                                  color: Colors.white70,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Text("😊", style: TextStyle(fontSize: 20)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            profile.name,
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(40),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              isBn
                                  ? "আজকের মস্তিষ্ক ব্যায়াম ও গেম খেলতে নিচের অপশনগুলি বেছে নিন"
                                  : "Keep your mind sharp today with cognitive memory games below",
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 3. Routine Alarms & Voice Reminders (Medicine, Food, Sleep)
                    InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => RemindersScreen(
                              patientId: _currentProfile.userId.isNotEmpty ? _currentProfile.userId : _currentProfile.email,
                              patientName: _currentProfile.name,
                              isBengali: isBn,
                            ),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(22),
                      child: Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF0D9488), Color(0xFF14B8A6)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF0F766E).withAlpha(45),
                              blurRadius: 12,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(13),
                              decoration: BoxDecoration(
                                color: Colors.white.withAlpha(40),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.alarm_on_rounded, color: Colors.white, size: 32),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isBn ? "দৈনন্দিন রুটিন ও অ্যালার্ম" : "Alarms & Reminders",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 19,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    isBn
                                        ? "ওষুধ, খাবার ও ঘুমের ভয়েস রিমাইন্ডার"
                                        : "Voice reminders for medicine, meals & sleep routine",
                                    style: const TextStyle(color: Color(0xFFE0F2F1), fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 20),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 4. Let's Connect - Social Interaction Section
                    InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SocialHubScreen(profile: _currentProfile, isBengali: isBn),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(22),
                      child: Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF00897B), Color(0xFF4DB6AC)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF00695C).withAlpha(45),
                              blurRadius: 12,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(13),
                              decoration: BoxDecoration(
                                color: Colors.white.withAlpha(40),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.groups_rounded, color: Colors.white, size: 32),
                            ),
                            const SizedBox(width: 16),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Let's Connect!",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 19,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 3),
                                  Text(
                                    "Meet new friends, chat, and share photos & voice",
                                    style: TextStyle(color: Color(0xFFE0F2F1), fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 20),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 4. Featured Cognitive Games Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isBn ? "মস্তিষ্কের খেলা" : "Memory Games",
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => GamesHubScreen(isBengali: isBn),
                              ),
                            );
                          },
                          icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                          label: Text(
                            isBn ? "আরও খেলা" : "More Games",
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Game Card 1: Pattern Memory (with Wrap to prevent overflow)
                    _buildGameCard(
                      title: isBn ? "প্যাটার্ন মেমোরি" : "Pattern Memory",
                      desc: isBn ? "রঙ ও আকার মনে রাখুন" : "Remember tile sequences",
                      badge: isBn ? "সুপারিশকৃত" : "Recommended",
                      icon: Icons.grid_view_rounded,
                      color: const Color(0xFFE8F5E9),
                      iconColor: const Color(0xFF2E7D32),
                      badgeColor: const Color(0xFF2E7D32),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PatternMemoryGameScreen(isBengali: isBn),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 14),

                    // Game Card 2: Card Match
                    _buildGameCard(
                      title: isBn ? "কার্ড ম্যাচিং" : "Card Matching",
                      desc: isBn ? "একই ধরণের ছবি মিলিয়ে দেখুন" : "Find identical pairs of picture cards",
                      badge: isBn ? "সহজ লেভেল" : "Easy Level",
                      icon: Icons.style_rounded,
                      color: const Color(0xFFE3F2FD),
                      iconColor: const Color(0xFF1565C0),
                      badgeColor: const Color(0xFF1565C0),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CardMatchingGameScreen(isBengali: isBn),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 14),

                    // Game Card 3: Word Recall
                    _buildGameCard(
                      title: isBn ? "শব্দ স্মরণ" : "Word Recall",
                      desc: isBn ? "পরিচিত বস্তু ও রঙের নাম মনে করুন" : "Recall everyday names and items",
                      badge: isBn ? "মজার খেলা" : "Fun & Relaxing",
                      icon: Icons.menu_book_rounded,
                      color: const Color(0xFFFFF3E0),
                      iconColor: const Color(0xFFE65100),
                      badgeColor: const Color(0xFFE65100),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => WordRecallGameScreen(isBengali: isBn),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),

            // Voice Assistant Quick Button (now at the bottom)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(15),
                    blurRadius: 10,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: _openVoiceAssistant,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                icon: const Icon(Icons.mic_rounded, size: 28, color: Colors.white),
                label: Text(
                  isBn ? "ভয়েস সহায়ক" : "Voice Assistant",
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGameCard({
    required String title,
    required String desc,
    required String badge,
    required IconData icon,
    required Color color,
    required Color iconColor,
    required Color badgeColor,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: Colors.white,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(icon, size: 38, color: iconColor),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Using Wrap prevents any overflow on small screens or Bengali text
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: badgeColor.withAlpha(25),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            badge,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: badgeColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      desc,
                      style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.arrow_forward_ios_rounded, size: 20, color: AppTheme.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
