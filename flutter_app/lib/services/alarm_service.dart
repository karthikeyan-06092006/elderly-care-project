import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../models/reminder_model.dart';
import 'api_service.dart';

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) async {
  debugPrint('[AlarmService] Background notification action tapped: ${notificationResponse.actionId}, payload: ${notificationResponse.payload}');
  if (notificationResponse.payload != null) {
    try {
      final map = jsonDecode(notificationResponse.payload!);
      final String reminderId = map['reminderId']?.toString() ?? '';
      final String title = map['title']?.toString() ?? 'Reminder';
      final String category = map['category']?.toString() ?? 'MEDICINE';
      final String voiceMsg = map['voiceMessage']?.toString() ?? '';
      final String voiceLang = map['voiceLanguage']?.toString() ?? 'en';

      if (reminderId.isNotEmpty) {
        if (notificationResponse.actionId == 'taken_action') {
          await ApiService.updateReminderStatus(reminderId: reminderId, status: 'TAKEN');
        } else if (notificationResponse.actionId == 'snooze_action') {
          await ApiService.updateReminderStatus(reminderId: reminderId, status: 'SNOOZED');
          await AlarmService.instance.scheduleSnoozeAlarm(
            reminderId: reminderId,
            title: title,
            category: category,
            voiceMessage: voiceMsg,
            voiceLanguage: voiceLang,
            snoozeMinutes: 10,
          );
        }
      }
    } catch (e) {
      debugPrint('[AlarmService] Background action error: $e');
    }
  }
}

class AlarmService {
  AlarmService._();
  static final AlarmService instance = AlarmService._();

  final FlutterTts _tts = FlutterTts();
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  
  bool _isInitialized = false;
  Timer? _pollingTimer;
  List<PatientReminder> _cachedReminders = [];

  int _getNotificationId(String reminderId) => reminderId.hashCode.abs() % 2147483647;

  Future<void> initialize() async {
    if (_isInitialized) return;
    try {
      tz.initializeTimeZones();
      try {
        final tzInfo = await FlutterTimezone.getLocalTimezone();
        final String currentTimeZone = tzInfo.identifier;
        tz.setLocalLocation(tz.getLocation(currentTimeZone));
        debugPrint('[AlarmService] 🌍 Local timezone configured: $currentTimeZone');
      } catch (e) {
        debugPrint('[AlarmService] ⚠️ Native timezone lookup fallback: $e');
        try {
          tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));
        } catch (_) {}
      }

      const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
      );

      await _localNotifications.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse details) {
          _handleNotificationResponse(details);
        },
        onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
      );

      final androidPlugin = _localNotifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        final vibrationPattern = Int64List.fromList([0, 1000, 500, 1000, 500, 1000, 500, 1000]);
        final AndroidNotificationChannel alarmChannel = AndroidNotificationChannel(
          'elderly_care_routine_alarms_v2',
          'Elderly Care Alarms & Routine Reminders',
          description: 'High-priority exact alarms for medicines, meals, and sleep routines even when screen is locked or app is closed.',
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
          vibrationPattern: vibrationPattern,
          audioAttributesUsage: AudioAttributesUsage.alarm,
        );

        await androidPlugin.createNotificationChannel(alarmChannel);
        await androidPlugin.requestNotificationsPermission();
        await androidPlugin.requestExactAlarmsPermission();
      }

      await _tts.setSpeechRate(0.45); // Gentle, understandable speed for elderly
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);

      _isInitialized = true;
      debugPrint('[AlarmService] Initialized successfully with system exact alarm channel.');
    } catch (e) {
      debugPrint('[AlarmService] Init note: $e');
    }
  }

  void _handleNotificationResponse(NotificationResponse details) {
    debugPrint('[AlarmService] Foreground notification tapped: ${details.actionId}, payload: ${details.payload}');
    if (details.payload != null) {
      try {
        final map = jsonDecode(details.payload!);
        final isBn = map['voiceLanguage'] == 'bn';
        final String voiceMsg = map['voiceMessage'] ?? '';
        final String title = map['title'] ?? 'Reminder';
        final String reminderId = map['reminderId']?.toString() ?? '';

        if (details.actionId == 'taken_action') {
          stopVoice();
          if (reminderId.isNotEmpty) {
            ApiService.updateReminderStatus(reminderId: reminderId, status: 'TAKEN');
          }
        } else if (details.actionId == 'snooze_action') {
          stopVoice();
          if (reminderId.isNotEmpty) {
            ApiService.updateReminderStatus(reminderId: reminderId, status: 'SNOOZED');
            scheduleSnoozeAlarm(
              reminderId: reminderId,
              title: title,
              category: map['category'] ?? 'Reminder',
              voiceMessage: voiceMsg,
              voiceLanguage: map['voiceLanguage'] ?? 'en',
              snoozeMinutes: 10,
            );
          }
        } else {
          // Speak aloud on notification tap
          speakCustom(voiceMsg.isNotEmpty ? voiceMsg : "Time for your $title", isBn);
        }
      } catch (e) {
        debugPrint('[AlarmService] Error handling response: $e');
      }
    }
  }

  /// Schedules a one-time Snooze Alarm for N minutes in the future
  Future<void> scheduleSnoozeAlarm({
    required String reminderId,
    required String title,
    required String category,
    required String voiceMessage,
    required String voiceLanguage,
    int snoozeMinutes = 10,
  }) async {
    try {
      if (!_isInitialized) await initialize();

      final now = tz.TZDateTime.now(tz.local);
      final snoozeTime = now.add(Duration(minutes: snoozeMinutes));

      final vibrationPattern = Int64List.fromList([0, 1000, 500, 1000, 500, 1000, 500, 1000]);
      final androidDetails = AndroidNotificationDetails(
        'elderly_care_routine_alarms_v2',
        'Elderly Care Alarms & Routine Reminders',
        channelDescription: 'High-priority exact alarms for medicines, meals, and sleep routines even when screen is off.',
        importance: Importance.max,
        priority: Priority.max,
        category: AndroidNotificationCategory.alarm,
        audioAttributesUsage: AudioAttributesUsage.alarm,
        playSound: true,
        enableVibration: true,
        vibrationPattern: vibrationPattern,
        fullScreenIntent: true,
        visibility: NotificationVisibility.public,
        ongoing: true,
        autoCancel: false,
        actions: [
          const AndroidNotificationAction('snooze_action', 'Snooze (10m)'),
          const AndroidNotificationAction('taken_action', 'Mark as Taken ✓', showsUserInterface: true),
        ],
      );

      final payload = jsonEncode({
        'reminderId': reminderId,
        'title': title,
        'category': category,
        'voiceMessage': voiceMessage,
        'voiceLanguage': voiceLanguage,
      });

      final notifId = _getNotificationId(reminderId);

      await _localNotifications.zonedSchedule(
        id: notifId,
        title: '⏰ [Snoozed] $category: $title',
        body: voiceMessage.isNotEmpty ? voiceMessage : "Snoozed reminder: $title",
        scheduledDate: snoozeTime,
        notificationDetails: NotificationDetails(android: androidDetails),
        androidScheduleMode: AndroidScheduleMode.alarmClock,
        payload: payload,
      );

      debugPrint('[AlarmService] 💤 Snooze alarm scheduled for $snoozeTime (in $snoozeMinutes mins)');
    } catch (e) {
      debugPrint('[AlarmService] Snooze error: $e');
    }
  }

  /// Schedules an Exact OS-level alarm that fires via AlarmManager even when screen is OFF or app is closed
  Future<void> scheduleSystemAlarm(PatientReminder reminder) async {
    if (!reminder.isActive) {
      await cancelSystemAlarm(reminder.reminderId);
      return;
    }

    try {
      if (!_isInitialized) {
        await initialize();
      }

      final parts = reminder.reminderTime.split(':');
      if (parts.length != 2) return;
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);

      final now = tz.TZDateTime.now(tz.local);
      var scheduledDate = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        hour,
        minute,
        0,
      );

      if (now.hour == hour && now.minute == minute) {
        // Scheduled for current minute: trigger in 4 seconds for immediate testing / alarm response
        scheduledDate = now.add(const Duration(seconds: 4));
      } else if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      final isBn = reminder.voiceLanguage == 'bn';
      String messageToSpeak = reminder.voiceMessage;
      if (messageToSpeak.trim().isEmpty) {
        messageToSpeak = isBn
            ? "নমস্কার, আপনার ${reminder.title} এর সময় হয়েছে।"
            : "Hello! It is time for your reminder: ${reminder.title}";
      }

      final vibrationPattern = Int64List.fromList([0, 1000, 500, 1000, 500, 1000, 500, 1000]);
      final androidDetails = AndroidNotificationDetails(
        'elderly_care_routine_alarms_v2',
        'Elderly Care Alarms & Routine Reminders',
        channelDescription: 'High-priority exact alarms for medicines, meals, and sleep routines even when screen is off.',
        importance: Importance.max,
        priority: Priority.max,
        category: AndroidNotificationCategory.alarm,
        audioAttributesUsage: AudioAttributesUsage.alarm,
        playSound: true,
        enableVibration: true,
        vibrationPattern: vibrationPattern,
        fullScreenIntent: true,
        visibility: NotificationVisibility.public,
        ongoing: true,
        autoCancel: false,
        actions: [
          const AndroidNotificationAction('snooze_action', 'Snooze (10m)'),
          const AndroidNotificationAction('taken_action', 'Mark as Taken ✓', showsUserInterface: true),
        ],
      );

      final payload = jsonEncode({
        'reminderId': reminder.reminderId,
        'patientId': reminder.patientId,
        'title': reminder.title,
        'category': reminder.category,
        'reminderTime': reminder.reminderTime,
        'voiceMessage': messageToSpeak,
        'voiceLanguage': reminder.voiceLanguage,
      });

      final notifId = _getNotificationId(reminder.reminderId);

      await _localNotifications.zonedSchedule(
        id: notifId,
        title: '⏰ ${reminder.categoryDisplayName}: ${reminder.title}',
        body: messageToSpeak,
        scheduledDate: scheduledDate,
        notificationDetails: NotificationDetails(android: androidDetails),
        androidScheduleMode: AndroidScheduleMode.alarmClock,
        matchDateTimeComponents: DateTimeComponents.time, // Repeats daily!
        payload: payload,
      );

      debugPrint('[AlarmService] ✅ Exact System Alarm #${reminder.reminderId} ($notifId) scheduled for $scheduledDate (Android AlarmClock Mode)');
    } catch (e) {
      debugPrint('[AlarmService] Failed to schedule system exact alarm: $e');
    }
  }

  /// Cancels an OS-level alarm
  Future<void> cancelSystemAlarm(String reminderId) async {
    try {
      final notifId = _getNotificationId(reminderId);
      await _localNotifications.cancel(id: notifId);
      debugPrint('[AlarmService] ❌ Cancelled Exact System Alarm #$reminderId ($notifId)');
    } catch (e) {
      debugPrint('[AlarmService] Error canceling system alarm: $e');
    }
  }

  /// Syncs all reminders with system AlarmManager (schedules active, cancels inactive)
  Future<void> syncAllAlarms(List<PatientReminder> reminders) async {
    _cachedReminders = reminders;
    for (final reminder in reminders) {
      if (reminder.isActive) {
        await scheduleSystemAlarm(reminder);
      } else {
        await cancelSystemAlarm(reminder.reminderId);
      }
    }
  }

  /// Speaks reminder voice message aloud
  Future<void> speakReminder(PatientReminder reminder) async {
    try {
      if (!_isInitialized) {
        await initialize();
      }

      final isBn = reminder.voiceLanguage == 'bn';
      if (isBn) {
        await _tts.setLanguage("bn-IN");
      } else {
        await _tts.setLanguage("en-IN");
      }

      String messageToSpeak = reminder.voiceMessage;
      if (messageToSpeak.trim().isEmpty) {
        messageToSpeak = isBn
            ? "নমস্কার, আপনার ${reminder.title} এর সময় হয়েছে।"
            : "Hello! It is time for your reminder: ${reminder.title}";
      }

      await _tts.stop();
      await _tts.speak(messageToSpeak);
      debugPrint('[AlarmService] Speaking alarm voice: $messageToSpeak');
    } catch (e) {
      debugPrint('[AlarmService] Speak failed: $e');
    }
  }

  Future<void> speakCustom(String text, bool isBn) async {
    try {
      if (!_isInitialized) await initialize();
      await _tts.setLanguage(isBn ? "bn-IN" : "en-IN");
      await _tts.stop();
      await _tts.speak(text);
    } catch (_) {}
  }

  /// Stop any active alarm voice
  Future<void> stopVoice() async {
    try {
      await _tts.stop();
    } catch (_) {}
  }

  /// Shows an interactive, full-screen popup alarm modal for elderly patients
  void triggerAlarmPopup({
    required BuildContext context,
    required PatientReminder reminder,
    required VoidCallback onStatusChanged,
  }) {
    // Speak aloud when popup opens
    speakReminder(reminder);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: reminder.color, width: 2),
        ),
        title: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: reminder.color.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(reminder.icon, size: 48, color: reminder.color),
            ),
            const SizedBox(height: 12),
            Text(
              "⏰ ${reminder.categoryDisplayName}",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: reminder.color,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              reminder.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                "Scheduled for: ${reminder.reminderTime}",
                style: const TextStyle(fontSize: 14, color: Colors.white70),
              ),
            ),
            if (reminder.voiceMessage.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                "💬 \"${reminder.voiceMessage}\"",
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                  color: Colors.white60,
                ),
              ),
            ],
          ],
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        actions: [
          // Snooze Button
          OutlinedButton.icon(
            onPressed: () async {
              stopVoice();
              Navigator.pop(ctx);
              await ApiService.updateReminderStatus(
                reminderId: reminder.reminderId,
                status: 'SNOOZED',
              );
              await scheduleSnoozeAlarm(
                reminderId: reminder.reminderId,
                title: reminder.title,
                category: reminder.categoryDisplayName,
                voiceMessage: reminder.voiceMessage,
                voiceLanguage: reminder.voiceLanguage,
                snoozeMinutes: 10,
              );
              onStatusChanged();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("⏰ Snoozed for 10 minutes"),
                    backgroundColor: Colors.amber,
                    duration: Duration(seconds: 3),
                  ),
                );
              }
            },
            icon: const Icon(Icons.snooze_rounded, color: Colors.amber, size: 20),
            label: const Text("Snooze (10m)", style: TextStyle(color: Colors.amber)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.amber),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
          ),

          // Taken / Done Button
          ElevatedButton.icon(
            onPressed: () async {
              stopVoice();
              Navigator.pop(ctx);
              await ApiService.updateReminderStatus(
                reminderId: reminder.reminderId,
                status: 'TAKEN',
              );
              onStatusChanged();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("✅ Marked as Completed: ${reminder.title}"),
                    backgroundColor: Colors.green.shade700,
                    duration: const Duration(seconds: 3),
                  ),
                );
              }
            },
            icon: const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
            label: const Text("Taken ✓", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade700,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  /// Start background checker for alarms matching current minute (in-app fallback)
  void startRoutineChecker({
    required BuildContext context,
    required String patientId,
    required VoidCallback onStatusChanged,
  }) {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 30), (timer) async {
      try {
        final now = DateTime.now();
        final currentHourMinute = "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";

        final res = await ApiService.getPatientReminders(patientId);
        if (res.success && res.data != null) {
          _cachedReminders = res.data!;
          // Sync with system alarms too!
          syncAllAlarms(_cachedReminders);

          for (final reminder in _cachedReminders) {
            if (reminder.isActive && reminder.reminderTime == currentHourMinute) {
              final lastTrig = reminder.lastTriggeredAt;
              if (lastTrig == null ||
                  lastTrig.day != now.day ||
                  lastTrig.hour != now.hour ||
                  lastTrig.minute != now.minute) {
                if (context.mounted) {
                  triggerAlarmPopup(
                    context: context,
                    reminder: reminder,
                    onStatusChanged: onStatusChanged,
                  );
                }
              }
            }
          }
        }
      } catch (e) {
        debugPrint('[AlarmService] Routine checker notice: $e');
      }
    });
  }

  void stopRoutineChecker() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }
}
