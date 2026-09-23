import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/reminder_model.dart';
import 'api_service.dart';

class AlarmService {
  AlarmService._();
  static final AlarmService instance = AlarmService._();

  final FlutterTts _tts = FlutterTts();
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  
  bool _isTtsInitialized = false;
  Timer? _pollingTimer;
  List<PatientReminder> _cachedReminders = [];

  Future<void> initialize() async {
    try {
      await _tts.setSpeechRate(0.45); // Gentle, understandable speed for elderly
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);
      _isTtsInitialized = true;
    } catch (e) {
      debugPrint('[AlarmService] TTS init note: $e');
    }
  }

  /// Speaks reminder voice message aloud
  Future<void> speakReminder(PatientReminder reminder) async {
    try {
      if (!_isTtsInitialized) {
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
                color: reminder.color.withOpacity(0.2),
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
              onStatusChanged();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("⏰ Snoozed for 10 minutes"),
                  backgroundColor: Colors.amber,
                  duration: Duration(seconds: 3),
                ),
              );
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
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("✅ Marked as Completed: ${reminder.title}"),
                  backgroundColor: Colors.green.shade700,
                  duration: const Duration(seconds: 3),
                ),
              );
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

  /// Start background checker for alarms matching current minute
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
          for (final reminder in _cachedReminders) {
            if (reminder.isActive && reminder.reminderTime == currentHourMinute) {
              final lastTrig = reminder.lastTriggeredAt;
              // Check if already triggered in the same minute
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
