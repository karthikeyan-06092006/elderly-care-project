import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// App-wide reactive settings (theme & language).
/// Changing a value notifies listeners so the MaterialApp re-themes live,
/// and persists the choice so it survives logout and app restarts.
class AppSettings extends ChangeNotifier {
  AppSettings._();

  static final AppSettings instance = AppSettings._();

  static const String _fileName = 'app_settings.json';
  static const List<String> themes = ['Light', 'Dark', 'High Contrast'];

  String _theme = 'Light';
  bool _isBengali = false;

  String get theme => _theme;
  bool get isBengali => _isBengali;

  /// Loads persisted settings; silently falls back to defaults on failure.
  Future<void> load() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}${Platform.pathSeparator}$_fileName');
      if (await file.exists()) {
        final data = jsonDecode(await file.readAsString());
        if (data is Map<String, dynamic>) {
          _theme = data['theme'] is String ? data['theme'] as String : 'Light';
          _isBengali = data['isBengali'] is bool ? data['isBengali'] as bool : false;
          if (!themes.contains(_theme)) {
            _theme = 'Light';
          }
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('[AppSettings] Load failed: $e');
    }
  }

  Future<void> setTheme(String value) async {
    if (_theme == value) return;
    _theme = value;
    notifyListeners();
    await _save();
  }

  Future<void> setBengali(bool value) async {
    if (_isBengali == value) return;
    _isBengali = value;
    notifyListeners();
    await _save();
  }

  Future<void> _save() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}${Platform.pathSeparator}$_fileName');
      await file.writeAsString(
        jsonEncode({'theme': _theme, 'isBengali': _isBengali}),
        flush: true,
      );
    } catch (e) {
      debugPrint('[AppSettings] Save failed: $e');
    }
  }
}