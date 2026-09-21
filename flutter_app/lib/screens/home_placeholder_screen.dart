import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class HomePlaceholderScreen extends StatelessWidget {
  final String email;
  final String role;
  final String name;
  final bool isBengali;

  const HomePlaceholderScreen({
    super.key,
    required this.email,
    required this.role,
    required this.name,
    this.isBengali = false,
  });

  @override
  Widget build(BuildContext context) {
    final isPatient = role.toUpperCase() == 'PATIENT';

    return Scaffold(
      appBar: AppBar(
        title: Text(isBengali ? "ড্যাশবোর্ড" : "Dashboard"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () {
              Navigator.popUntil(context, (route) => route.isFirst);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // User Header Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isPatient
                      ? [const Color(0xFF00796B), const Color(0xFF004D40)]
                      : [const Color(0xFF1565C0), const Color(0xFF0D47A1)],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(25),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 34,
                    backgroundColor: Colors.white,
                    child: Icon(
                      isPatient ? Icons.elderly_rounded : Icons.health_and_safety_rounded,
                      size: 40,
                      color: isPatient ? const Color(0xFF00796B) : const Color(0xFF1565C0),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isBengali ? "স্বাগতম," : "Welcome back,",
                          style: const TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                        Text(
                          name.isNotEmpty ? name : "User",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(50),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            isPatient ? (isBengali ? "রোগী মোড" : "Patient Mode") : (isBengali ? "যত্নশীল মোড" : "Caretaker Mode"),
                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // Success Info Box
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Column(
                children: [
                  const Icon(Icons.check_circle_rounded, color: Colors.green, size: 48),
                  const SizedBox(height: 12),
                  Text(
                    isBengali ? "লগইন সফল হয়েছে!" : "Authentication Successful!",
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isBengali
                        ? "ইমেইল: $email\nভূমিকা: ${isPatient ? 'রোগী' : 'যত্নশীল'}"
                        : "Email: $email\nRole: ${isPatient ? 'Patient' : 'Caretaker'}",
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppTheme.textSecondary, height: 1.4),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),

            ElevatedButton.icon(
              onPressed: () {
                Navigator.popUntil(context, (route) => route.isFirst);
              },
              icon: const Icon(Icons.logout_rounded),
              label: Text(isBengali ? "লগ আউট" : "Log Out"),
            ),
          ],
        ),
      ),
    );
  }
}
