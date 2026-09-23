import 'dart:io';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/user_model.dart';
import 'profile_details_screen.dart';
import 'caretakers_screen.dart';
import 'settings_screen.dart';
import 'landing_screen.dart';
import '../services/profile_storage_service.dart';

class ProfileMenuScreen extends StatefulWidget {
  final PatientProfile profile;
  final bool isBengali;
  final String currentTheme;
  final Function(PatientProfile) onProfileUpdated;
  final ValueChanged<bool>? onLanguageChanged;
  final ValueChanged<String>? onThemeChanged;

  const ProfileMenuScreen({
    super.key,
    required this.profile,
    this.isBengali = false,
    this.currentTheme = "Light",
    required this.onProfileUpdated,
    this.onLanguageChanged,
    this.onThemeChanged,
  });

  @override
  State<ProfileMenuScreen> createState() => _ProfileMenuScreenState();
}

class _ProfileMenuScreenState extends State<ProfileMenuScreen> {
  late PatientProfile _currentProfile;
  late bool _isBengali;
  late String _currentTheme;

  @override
  void initState() {
    super.initState();
    _currentProfile = widget.profile;
    _isBengali = widget.isBengali;
    _currentTheme = widget.currentTheme;
  }

  void _confirmLogout() {
    final isBn = _isBengali;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.logout_rounded, color: Colors.red, size: 28),
            const SizedBox(width: 10),
            Text(
              isBn ? "লগ আউট নিশ্চিতকরণ" : "Confirm Logout",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
          ],
        ),
        content: Text(
          isBn
              ? "আপনি কি নিশ্চিত যে অ্যাকাউন্ট থেকে লগ আউট করতে চান?"
              : "Are you sure you want to log out from this session?",
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              isBn ? "না" : "Cancel",
              style: const TextStyle(fontSize: 16, color: AppTheme.textSecondary),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700),
            onPressed: () async {
              await ProfileStorageService.clearSession();
              if (!mounted) return;
              Navigator.pop(ctx);
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LandingScreen()),
                (route) => false,
              );
            },
            child: Text(
              isBn ? "হ্যাঁ, লগ আউট" : "Yes, Log Out",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isBn = _isBengali;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isBn ? "অ্যাকাউন্ট মেনু" : "Profile & Options",
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Profile Header Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(15),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.primaryLight,
                      border: Border.all(color: AppTheme.primary, width: 2.5),
                    ),
                    child: ClipOval(
                      child: _currentProfile.photoPath != null
                          ? Image.file(
                              File(_currentProfile.photoPath!),
                              fit: BoxFit.cover,
                              width: 70,
                              height: 70,
                            )
                          : const Icon(
                              Icons.person_rounded,
                              size: 40,
                              color: AppTheme.primary,
                            ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _currentProfile.name,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _currentProfile.phone,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppTheme.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Option 1: Profile (Personal Details & Photo)
            _buildMenuOption(
              icon: Icons.person_outline_rounded,
              iconColor: AppTheme.primary,
              bgColor: AppTheme.primaryLight,
              title: isBn ? "১. ব্যক্তিগত বিবরণ (Profile)" : "1. Personal Profile",
              subtitle: isBn
                  ? "নাম, ইমেইল, ফোন ও ছবি পরিবর্তন করুন"
                  : "View/edit details & manage profile photo",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProfileDetailsScreen(
                      profile: _currentProfile,
                      isBengali: isBn,
                      onProfileUpdated: (updated) {
                        setState(() {
                          _currentProfile = updated;
                        });
                        widget.onProfileUpdated(updated);
                      },
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 14),

            // Option 2: Caretakers (Primary, Others, QR Code)
            _buildMenuOption(
              icon: Icons.supervisor_account_rounded,
              iconColor: const Color(0xFF1976D2),
              bgColor: const Color(0xFFE3F2FD),
              title: isBn ? "২. যত্নশীলদের তালিকা (Caretakers)" : "2. Caretakers & Linking",
              subtitle: isBn
                  ? "প্রধান ও সহকারী কেয়ারটেকার এবং কিউআর কোড"
                  : "Primary & secondary caregivers, SOS & QR link",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CaretakersScreen(
                      profile: _currentProfile,
                      isBengali: isBn,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 14),

            // Option 3: Settings (Theme, Language, About)
            _buildMenuOption(
              icon: Icons.settings_rounded,
              iconColor: const Color(0xFFE65100),
              bgColor: const Color(0xFFFFF3E0),
              title: isBn ? "৩. সেটিংস (Settings)" : "3. App Settings",
              subtitle: isBn
                  ? "থিম পরিবর্তন, ভাষা নির্বাচন এবং অ্যাপ সম্পর্কে"
                  : "Change theme, language (EN/BN) & about app",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SettingsScreen(
                      isBengali: _isBengali,
                      currentTheme: _currentTheme,
                      onLanguageChanged: (val) {
                        setState(() => _isBengali = val);
                        widget.onLanguageChanged?.call(val);
                      },
                      onThemeChanged: (val) {
                        setState(() => _currentTheme = val);
                        widget.onThemeChanged?.call(val);
                      },
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 28),

            // Option 4: Logout Button
            ElevatedButton.icon(
              onPressed: _confirmLogout,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD32F2F),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              ),
              icon: const Icon(Icons.logout_rounded, size: 24),
              label: Text(
                isBn ? "৪. লগ আউট করুন (Log Out)" : "4. Log Out",
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuOption({
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required String title,
    required String subtitle,
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
          padding: const EdgeInsets.all(18.0),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: iconColor, size: 30),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded, size: 18, color: AppTheme.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
