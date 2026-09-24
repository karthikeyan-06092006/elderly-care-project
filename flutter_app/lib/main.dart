import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'services/notification_service.dart';
import 'services/alarm_service.dart';
import 'services/app_settings.dart';
import 'theme/app_theme.dart';
import 'screens/landing_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp();
    debugPrint("✅ Firebase SUCCESS");
    await NotificationService.initialize();
  } catch (e) {
    debugPrint("❌ Firebase Initialized with Warning: $e");
  }

  await AlarmService.instance.initialize();
  await AppSettings.instance.load();

  runApp(const CognitiveCareApp());
}

class CognitiveCareApp extends StatelessWidget {
  const CognitiveCareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppSettings.instance,
      builder: (context, _) {
        return MaterialApp(
          title: 'CognitiveCare - Dementia Support',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.themeFor(AppSettings.instance.theme),
          builder: (context, child) {
            final factor =
                AppSettings.instance.theme == 'High Contrast' ? 1.2 : 1.0;
            if (factor == 1.0) return child ?? const SizedBox.shrink();
            final base = MediaQuery.textScalerOf(context);
            final sysScale = base.scale(1.0);
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(sysScale * factor),
              ),
              child: child ?? const SizedBox.shrink(),
            );
          },
          home: const LandingScreen(),
        );
      },
    );
  }
}
