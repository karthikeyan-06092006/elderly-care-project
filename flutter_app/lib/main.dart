import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'services/notification_service.dart';
import 'services/app_settings.dart';
import 'services/profile_storage_service.dart';
import 'models/user_model.dart';
import 'theme/app_theme.dart';
import 'screens/landing_screen.dart';
import 'screens/patient_dashboard_screen.dart';
import 'screens/caretaker_dashboard_screen.dart';
import 'screens/healthcare_worker_dashboard_screen.dart';
import 'screens/admin_dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp();
    debugPrint("✅ Firebase SUCCESS");
    await NotificationService.initialize();
  } catch (e) {
    debugPrint("❌ Firebase Initialized with Warning: $e");
  }

  await AppSettings.instance.load();

  // Pre-load active session so the app immediately renders the right dashboard with zero flicker or black screen
  Widget homeScreen = const LandingScreen();
  try {
    final session = await ProfileStorageService.loadSession();
    if (session != null) {
      if (session.isAdmin) {
        homeScreen = AdminDashboardScreen(session: session);
      } else if (session.isHealthcareWorker) {
        homeScreen = HealthcareWorkerDashboardScreen(session: session);
      } else if (session.isPatient) {
        final profile = await ProfileStorageService.hydrateProfile(
          PatientProfile.fromSession(session),
        );
        homeScreen = PatientDashboardScreen(profile: profile);
      } else {
        homeScreen = CaretakerDashboardScreen(session: session);
      }
    }
  } catch (e) {
    debugPrint("Session load error: $e");
  }

  runApp(CognitiveCareApp(homeScreen: homeScreen));
}

class CognitiveCareApp extends StatelessWidget {
  final Widget homeScreen;
  const CognitiveCareApp({super.key, required this.homeScreen});

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
          home: homeScreen,
        );
      },
    );
  }
}
