import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/theme/app_theme.dart';
import 'package:flutter_app/services/app_settings.dart';
import 'package:flutter_app/screens/settings_screen.dart';

void main() {
  testWidgets('theme switches (Light/Dark/High Contrast) do not crash',
      (tester) async {
    for (final theme in ['Light', 'Dark', 'High Contrast']) {
      AppSettings.instance.setTheme(theme);
      await tester.pumpWidget(
        ListenableBuilder(
          listenable: AppSettings.instance,
          builder: (context, _) => MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.themeFor(AppSettings.instance.theme),
            home: const SettingsScreen(isBengali: false),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('1. Change Theme'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
    }
  });
}