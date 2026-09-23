import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/app_settings.dart';
import 'about_screen.dart';

class SettingsScreen extends StatefulWidget {
  final bool isBengali;
  final String currentTheme;
  final ValueChanged<bool>? onLanguageChanged;
  final ValueChanged<String>? onThemeChanged;

  const SettingsScreen({
    super.key,
    required this.isBengali,
    this.currentTheme = "Light",
    this.onLanguageChanged,
    this.onThemeChanged,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late bool _isBengali;
  late String _selectedTheme;

  @override
  void initState() {
    super.initState();
    _isBengali = widget.isBengali;
    _selectedTheme = AppSettings.instance.theme;
  }

  void _showThemeDialog() {
    final isBn = _isBengali;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          title: Row(
            children: [
              Icon(
                AppSettings.instance.theme == 'High Contrast'
                    ? Icons.highlight_rounded
                    : Icons.palette_outlined,
                color: AppTheme.primary,
                size: 26,
              ),
              const SizedBox(width: 10),
              Text(
                isBn ? "থিম নির্বাচন করুন" : "Choose Theme",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildThemeOptionTile(
                title: isBn ? "স্বাভাবিক (হালকা)" : "Light (Standard)",
                subtitle: isBn ? "পরিষ্কার ও শান্ত রঙ" : "Clean teal & white background",
                themeValue: "Light",
                onSelected: () {
                  AppSettings.instance.setTheme("Light");
                  setDialogState(() => _selectedTheme = "Light");
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(isBn ? "থিম পরিবর্তিত হয়েছে: হালকা" : "Theme changed to Light"),
                      backgroundColor: AppTheme.primary,
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),
              _buildThemeOptionTile(
                title: isBn ? "ডার্ক মোড" : "Dark Mode",
                subtitle: isBn ? "রাতের জন্য চোখের আরামদায়ক" : "Easy on eyes in dark rooms",
                themeValue: "Dark",
                onSelected: () {
                  AppSettings.instance.setTheme("Dark");
                  setDialogState(() => _selectedTheme = "Dark");
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(isBn ? "থিম পরিবর্তিত হয়েছে: ডার্ক মোড" : "Theme changed to Dark Mode"),
                      backgroundColor: AppTheme.primary,
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),
              _buildThemeOptionTile(
                title: isBn ? "উচ্চ বৈসাদৃশ্য (সিনিয়র মোড)" : "High Contrast (Senior Mode)",
                subtitle: isBn ? "সহজে স্পষ্ট দেখার উপযোগী" : "Maximum readability for elderly eyes",
                themeValue: "High Contrast",
                onSelected: () {
                  AppSettings.instance.setTheme("High Contrast");
                  setDialogState(() => _selectedTheme = "High Contrast");
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(isBn ? "উচ্চ বৈসাদৃশ্য থিম সক্রিয়" : "High Contrast Theme Activated"),
                      backgroundColor: AppTheme.primary,
                    ),
                  );
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(isBn ? "বন্ধ করুন" : "Close"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeOptionTile({
    required String title,
    required String subtitle,
    required String themeValue,
    required VoidCallback onSelected,
  }) {
    final isSelected = _selectedTheme == themeValue;
    return InkWell(
      onTap: onSelected,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryLight : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppTheme.primary : Colors.grey.shade300,
            width: isSelected ? 1.8 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? AppTheme.primary : Colors.grey,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                      color: isSelected ? AppTheme.primary : AppTheme.textPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _toggleLanguage(bool value) {
    setState(() {
      _isBengali = value;
    });
    widget.onLanguageChanged?.call(_isBengali);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isBengali ? "ভাষা পরিবর্তিত হয়েছে: বাংলা" : "Language switched to English",
        ),
        backgroundColor: AppTheme.primary,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isBn = _isBengali;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isBn ? "সেটিংস" : "Settings",
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
        children: [
          // 1. Theme Option
          Card(
            elevation: 1.5,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            color: Colors.white,
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.palette_rounded, color: Colors.amber.shade800, size: 28),
              ),
              title: Text(
                isBn ? "১. থিম পরিবর্তন করুন" : "1. Change Theme",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
              ),
              subtitle: Text(
                isBn
                    ? "বর্তমান থিম: $_selectedTheme"
                    : "Current: $_selectedTheme",
                style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
              ),
              trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 18, color: AppTheme.textSecondary),
              onTap: _showThemeDialog,
            ),
          ),
          const SizedBox(height: 14),

          // 2. Language Option
          Card(
            elevation: 1.5,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(Icons.translate_rounded, color: Colors.blue.shade800, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isBn ? "২. ভাষা পরিবর্তন" : "2. Change Language",
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isBn ? "বাংলা (Bengali) সক্রিয়" : "English Active",
                          style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  // Switch
                  Switch.adaptive(
                    value: _isBengali,
                    activeTrackColor: AppTheme.primary,
                    onChanged: _toggleLanguage,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // 3. About Page
          Card(
            elevation: 1.5,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            color: Colors.white,
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.teal.shade50,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.info_outline_rounded, color: AppTheme.primary, size: 28),
              ),
              title: Text(
                isBn ? "৩. অ্যাপ সম্পর্কে" : "3. About Our App",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
              ),
              subtitle: Text(
                isBn ? "অ্যাপের উদ্দেশ্য ও সহায়ক তথ্য" : "Learn about app features & mission",
                style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
              ),
              trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 18, color: AppTheme.textSecondary),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AboutScreen(isBengali: _isBengali),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 30),

          // Tip box for seniors
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primaryLight,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.primary.withAlpha(50)),
            ),
            child: Row(
              children: [
                const Icon(Icons.elderly_rounded, color: AppTheme.primary, size: 30),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    isBn
                        ? "বয়োবৃদ্ধদের সুবিধার জন্য বড় ফন্ট এবং পরিষ্কার রঙের ডিজাইন রাখা হয়েছে।"
                        : "Designed with high readability and clean contrast for elderly ease of use.",
                    style: const TextStyle(fontSize: 13, color: AppTheme.primary, height: 1.4, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
