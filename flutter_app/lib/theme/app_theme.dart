import 'package:flutter/material.dart';

class AppTheme {
  static const Color primary = Color(0xFF00796B); // Calm Teal
  static const Color primaryLight = Color(0xFFE0F2F1);
  static const Color accent = Color(0xFFFF7043); // Warm Coral
  static const Color background = Color(0xFFF7F9FC);
  static const Color cardColor = Colors.white;
  static const Color textPrimary = Color(0xFF263238);
  static const Color textSecondary = Color(0xFF607D8B);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: background,
      primaryColor: primary,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        primary: primary,
        secondary: accent,
        surface: cardColor,
      ),
      fontFamily: 'Roboto',
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: textPrimary),
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: const BorderSide(color: primary, width: 2),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFCFD8DC)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFCFD8DC)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        labelStyle: const TextStyle(color: textSecondary, fontSize: 16),
        prefixIconColor: primary,
      ),
    );
  }

  /// Dark theme for low-light environments.
  static ThemeData get darkTheme {
    const scaffold = Color(0xFF101614);
    const surface = Color(0xFF1B2421);
    const onSurface = Color(0xFFECEFF1);
    const onSurfaceMuted = Color(0xFFB0BEC5);
    const primaryBright = Color(0xFF66BB9F);
    final scheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.dark,
      primary: primaryBright,
      onPrimary: const Color(0xFF001F19),
      secondary: accent,
      onSecondary: const Color(0xFF3A0B00),
      surface: surface,
      onSurface: onSurface,
    );

    return _buildTheme(
      scaffold: scaffold,
      surface: surface,
      scheme: scheme,
      textPrimary: onSurface,
      textSecondary: onSurfaceMuted,
      highlight: primaryBright,
    );
  }

  /// High-contrast senior mode: black background, white text, large fonts.
  static ThemeData get highContrastTheme {
    const scaffold = Color(0xFF000000);
    const surface = Color(0xFF000000);
    const onSurface = Color(0xFFFFFFFF);
    const onSurfaceMuted = Color(0xFFFFFF00);
    const highlight = Color(0xFFFFEB3B);
    final scheme = ColorScheme.fromSeed(
      seedColor: highlight,
      brightness: Brightness.dark,
      primary: highlight,
      onPrimary: const Color(0xFF000000),
      secondary: const Color(0xFFFFA726),
      onSecondary: const Color(0xFF000000),
      surface: surface,
      onSurface: onSurface,
    );

    return _buildTheme(
      scaffold: scaffold,
      surface: surface,
      scheme: scheme,
      textPrimary: onSurface,
      textSecondary: onSurfaceMuted,
      highlight: highlight,
    );
  }

  /// Returns the active theme for a settings key: Light / Dark / High Contrast.
  static ThemeData themeFor(String key) {
    switch (key) {
      case 'Dark':
        return darkTheme;
      case 'High Contrast':
        return highContrastTheme;
      default:
        return lightTheme;
    }
  }

  static ThemeData _buildTheme({
    required Color scaffold,
    required Color surface,
    required ColorScheme scheme,
    required Color textPrimary,
    required Color textSecondary,
    required Color highlight,
  }) {
    final base = ThemeData(
      useMaterial3: true,
      brightness: scheme.brightness,
      scaffoldBackgroundColor: scaffold,
      colorScheme: scheme,
      fontFamily: 'Roboto',
    );

    final baseText = base.textTheme.apply(
      bodyColor: textPrimary,
      displayColor: textPrimary,
    );

    return base.copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: textPrimary),
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        contentTextStyle: TextStyle(color: textPrimary, fontSize: 15),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: highlight,
        contentTextStyle: const TextStyle(
          color: Color(0xFF000000),
          fontWeight: FontWeight.bold,
        ),
      ),
      dividerTheme: DividerThemeData(
        color: textSecondary.withValues(alpha: 0.3),
        thickness: 1,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStatePropertyAll(scheme.primary),
        trackColor: WidgetStatePropertyAll(
          scheme.primary.withValues(alpha: 0.4),
        ),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStatePropertyAll(scheme.primary),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStatePropertyAll(scheme.primary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.primary,
          side: BorderSide(color: scheme.primary, width: 2),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.primary,
          textStyle: TextStyle(fontSize: 15),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: textSecondary.withValues(alpha: 0.5)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: textSecondary.withValues(alpha: 0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
        labelStyle: TextStyle(color: textSecondary, fontSize: 16),
        prefixIconColor: scheme.primary,
        hintStyle: TextStyle(color: textSecondary.withValues(alpha: 0.7)),
      ),
      listTileTheme: ListTileThemeData(
        textColor: textPrimary,
        iconColor: textPrimary,
      ),
      textTheme: baseText,
    );
  }
}
