import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AboutScreen extends StatelessWidget {
  final bool isBengali;

  const AboutScreen({
    super.key,
    this.isBengali = false,
  });

  @override
  Widget build(BuildContext context) {
    final isBn = isBengali;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isBn ? "অ্যাপ সম্পর্কে" : "About App",
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // App Logo & Title
            Center(
              child: Column(
                children: [
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryLight,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.primary, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primary.withAlpha(40),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.psychology_rounded,
                      size: 52,
                      color: AppTheme.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isBn ? "কগনিটিভকেয়ার" : "CognitiveCare",
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isBn
                        ? "ডিমেনশিয়া রোগীদের জন্য এআই ভিত্তিক কগনিটিভ সাপোর্ট সিস্টেম"
                        : "AI-Based Cognitive Support & Redressal for Dementia Patients",
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.green.shade300),
                    ),
                    child: Text(
                      isBn ? "সংস্করণ ১.০.০" : "Version 1.0.0 (Elderly Edition)",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Mission Statement
            Card(
              elevation: 1.5,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(18.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.lightbulb_outline_rounded, color: AppTheme.accent, size: 24),
                        const SizedBox(width: 10),
                        Text(
                          isBn ? "আমাদের লক্ষ্য" : "Our Mission",
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      isBn
                          ? "বয়োবৃদ্ধ ডিমেনশিয়া রোগীদের স্মৃতিশক্তি অক্ষুণ্ণ রাখা এবং তাদের যত্নশীল ও পরিবারের সাথে নিরবচ্ছিন্ন সংযোগ নিশ্চিত করা। বিশেষ করে সহজে ব্যবহারযোগ্য বড় ফন্ট ও বাংলা ভাষা সহায়ক ইন্টারফেসের মাধ্যমে।"
                          : "Empowering elderly dementia patients to maintain cognitive vitality through adaptive memory games, instant emergency assistance, bilingual Bengali AI voice support, and seamless caregiver integration.",
                      style: const TextStyle(
                        fontSize: 15,
                        height: 1.5,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Key Highlights
            Card(
              elevation: 1.5,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(18.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isBn ? "✨ প্রধান বৈশিষ্ট্যসমূহ" : "✨ Key Features",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _buildFeatureRow(
                      icon: Icons.extension_rounded,
                      color: Colors.teal,
                      title: isBn ? "স্মৃতিশক্তি বৃদ্ধির গেম" : "Cognitive Memory Games",
                      desc: isBn
                          ? "প্যাটার্ন মেমোরি, কার্ড ম্যাচিং ও শব্দ মেলানোর গেম"
                          : "Pattern Memory, Card Matching & Word Recall designed for seniors",
                    ),
                    const Divider(height: 20),
                    _buildFeatureRow(
                      icon: Icons.emergency_rounded,
                      color: Colors.red,
                      title: isBn ? "এক-ট্যাপে জরুরি এসওএস" : "One-Tap Emergency SOS",
                      desc: isBn
                          ? "প্রধান যত্নশীলকে সরাসরি কল ও অন্যদের বার্তা প্রেরণ"
                          : "Immediate phone calling and alert broadcast to caretakers",
                    ),
                    const Divider(height: 20),
                    _buildFeatureRow(
                      icon: Icons.mic_rounded,
                      color: Colors.deepPurple,
                      title: isBn ? "বাংলা ও ইংরেজি এআই ভয়েস" : "Bilingual AI Voice Companion",
                      desc: isBn
                          ? "রোগীদের সাথে আন্তরিক কথোপকথন ও সহায়তা"
                          : "Friendly Bengali & English conversational AI assistant",
                    ),
                    const Divider(height: 20),
                    _buildFeatureRow(
                      icon: Icons.qr_code_2_rounded,
                      color: Colors.blue,
                      title: isBn ? "কিউআর কোড যত্নশীল সংযোগ" : "Instant Caregiver QR Pairing",
                      desc: isBn
                          ? "সহজ কিউআর কোড স্ক্যানের মাধ্যমে কেয়ারটেকার সংযোগ"
                          : "Caretakers scan patient's profile QR code to link instantly",
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),

            Center(
              child: Text(
                isBn
                    ? "© ২০২৬ কগনিটিভকেয়ার টিম • সর্বস্বত্ব সংরক্ষিত"
                    : "© 2026 CognitiveCare Team • All Rights Reserved",
                style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureRow({
    required IconData icon,
    required Color color,
    required String title,
    required String desc,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withAlpha(25),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                desc,
                style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
