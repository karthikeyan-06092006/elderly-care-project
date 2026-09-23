import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

class _UserStreak {
  int currentStreak;
  String lastPlayedDate;
  List<String> recentPlayedDates;

  _UserStreak({
    this.currentStreak = 0,
    this.lastPlayedDate = '',
    List<String>? recentPlayedDates,
  }) : recentPlayedDates = recentPlayedDates ?? [];

  factory _UserStreak.fromJson(Map<String, dynamic> json) => _UserStreak(
        currentStreak: json['currentStreak'] is int ? json['currentStreak'] as int : 0,
        lastPlayedDate: json['lastPlayedDate'] is String ? json['lastPlayedDate'] as String : '',
        recentPlayedDates: json['recentPlayedDates'] is List
            ? (json['recentPlayedDates'] as List).whereType<String>().toList()
            : [],
      );

  Map<String, dynamic> toJson() => {
        'currentStreak': currentStreak,
        'lastPlayedDate': lastPlayedDate,
        'recentPlayedDates': recentPlayedDates,
      };
}

class DailyStreakService extends ChangeNotifier {
  DailyStreakService._();

  static final DailyStreakService instance = DailyStreakService._();

  static const String _fileName = 'daily_streak.json';

  final Map<String, _UserStreak> _streaks = {};
  bool _loaded = false;

  static String get today {
    final now = DateTime.now();
    return '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
  }

  static List<String> lastSevenDays() {
    final now = DateTime.now();
    return List.generate(7, (i) {
      final d = now.subtract(Duration(days: 6 - i));
      return '${d.year.toString().padLeft(4, '0')}-'
          '${d.month.toString().padLeft(2, '0')}-'
          '${d.day.toString().padLeft(2, '0')}';
    });
  }

  static int dailyGameIndex() {
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day);
    final seed = midnight.millisecondsSinceEpoch ~/ Duration.millisecondsPerDay;
    return Random(seed).nextInt(4);
  }

  Future<void> load() async {
    if (_loaded) return;
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}${Platform.pathSeparator}$_fileName');
      if (await file.exists()) {
        final data = jsonDecode(await file.readAsString());
        if (data is Map<String, dynamic>) {
          data.forEach((key, value) {
            if (value is Map<String, dynamic>) {
              _streaks[key] = _UserStreak.fromJson(value);
            }
          });
        }
      }
    } catch (_) {}
    _loaded = true;
    notifyListeners();
  }

  _UserStreak _for(String userKey) => _streaks.putIfAbsent(userKey, () => _UserStreak());

  int currentStreak(String userKey) => _for(userKey).currentStreak;

  bool hasPlayedToday(String userKey) => _for(userKey).lastPlayedDate == today;

  bool hasPlayedOn(String userKey, String date) => _for(userKey).recentPlayedDates.contains(date);

  Future<void> recordGamePlayed(String userKey) async {
    final streak = _for(userKey);
    if (streak.lastPlayedDate == today) return;
    streak.currentStreak += 1;
    streak.lastPlayedDate = today;
    streak.recentPlayedDates.remove(today);
    streak.recentPlayedDates.add(today);
    if (streak.recentPlayedDates.length > 7) {
      streak.recentPlayedDates.sort();
      streak.recentPlayedDates.removeRange(0, streak.recentPlayedDates.length - 7);
    }
    notifyListeners();
    await _save();
  }

  Future<void> _save() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}${Platform.pathSeparator}$_fileName');
      final data = <String, dynamic>{};
      _streaks.forEach((key, value) => data[key] = value.toJson());
      await file.writeAsString(jsonEncode(data), flush: true);
    } catch (_) {}
  }
}