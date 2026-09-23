import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/user_model.dart';
import '../services/profile_storage_service.dart';
import 'login_screen.dart';
import 'register_screen.dart';
import 'patient_dashboard_screen.dart';
import 'caretaker_dashboard_screen.dart';
import 'healthcare_worker_dashboard_screen.dart';
import 'admin_dashboard_screen.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  String _selectedLang = 'en'; // 'en' or 'bn'
  bool _isCheckingSession = true;

  @override
  void initState() {
    super.initState();
    _checkRestoredSession();
  }

  Future<void> _checkRestoredSession() async {
    final session = await ProfileStorageService.loadSession();
    if (!mounted) return;

    if (session != null) {
      if (session.isAdmin) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => AdminDashboardScreen(session: session)),
        );
        return;
      } else if (session.isHealthcareWorker) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HealthcareWorkerDashboardScreen(session: session)),
        );
        return;
      } else if (session.isPatient) {
        final profile = await ProfileStorageService.hydrateProfile(
          PatientProfile.fromSession(session),
        );
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => PatientDashboardScreen(
              profile: profile,
              isBengali: _selectedLang == 'bn',
            ),
          ),
        );
        return;
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => CaretakerDashboardScreen(session: session)),
        );
        return;
      }
    }

    setState(() => _isCheckingSession = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingSession) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppTheme.primary),
        ),
      );
    }

    final isBn = _selectedLang == 'bn';

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Language Toggle Bar
              Align(
                alignment: Alignment.topRight,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.primaryLight,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildLangChip("English", 'en'),
                      _buildLangChip("বাংলা", 'bn'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // 2. App Logo & Brand Header
              Center(
                child: Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryLight,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primary.withAlpha(50),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      )
                    ],
                  ),
                  child: const Icon(
                    Icons.psychology_alt_rounded,
                    size: 64,
                    color: AppTheme.primary,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              Text(
                isBn ? "স্মৃতি কেয়ার" : "CognitiveCare",
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                isBn
                    ? "ডিমেনশিয়া রোগীদের স্মৃতিশক্তি বৃদ্ধি ও যত্নশীলদের সহায়তা কেন্দ্র"
                    : "AI-Powered Cognitive Support & Caregiver Companion for Dementia Patients",
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  color: AppTheme.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 40),

              // 3. Highlighted Feature Cards
              Row(
                children: [
                  Expanded(
                    child: _buildRolePreviewCard(
                      icon: Icons.elderly_rounded,
                      title: isBn ? "বয়স্ক রোগী" : "For Patient",
                      desc: isBn
                          ? "মেমোরি গেম ও এআই ভয়েস সাথী"
                          : "Brain games & Voice AI",
                      color: const Color(0xFFE8F5E9),
                      iconColor: const Color(0xFF2E7D32),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _buildRolePreviewCard(
                      icon: Icons.health_and_safety_rounded,
                      title: isBn ? "যত্নশীল" : "For Caretaker",
                      desc: isBn
                          ? "রিপোর্ট ও জরুরি অ্যালার্ট"
                          : "Live reports & alerts",
                      color: const Color(0xFFE3F2FD),
                      iconColor: const Color(0xFF1565C0),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 48),

              // 4. Action Buttons
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => LoginScreen(isBengali: isBn),
                    ),
                  );
                },
                child: Text(
                  isBn ? "লগ ইন করুন" : "Log In",
                  style: const TextStyle(fontSize: 18),
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RegisterScreen(isBengali: isBn),
                    ),
                  );
                },
                child: Text(
                  isBn ? "নতুন অ্যাকাউন্ট তৈরি করুন" : "Register New Account",
                  style: const TextStyle(fontSize: 18),
                ),
              ),
              const SizedBox(height: 24),

              // 5. Footer Info
              Center(
                child: Text(
                  isBn ? "নিরাপদ ও অফলাইন সুবিধা যুক্ত" : "Secure, Offline-Ready & Bilingual",
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLangChip(String label, String code) {
    final isSelected = _selectedLang == code;
    return GestureDetector(
      onTap: () => setState(() => _selectedLang = code),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppTheme.primary,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildRolePreviewCard({
    required IconData icon,
    required String title,
    required String desc,
    required Color color,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: iconColor.withAlpha(50)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 36, color: iconColor),
          const SizedBox(height: 10),
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: iconColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            desc,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }
}
