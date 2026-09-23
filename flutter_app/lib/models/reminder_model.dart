import 'package:flutter/material.dart';

class PatientReminder {
  final String reminderId;
  final String patientId;
  final String? createdBy;
  final String title;
  final String category; // MEDICINE, FOOD, SLEEP, WATER, APPOINTMENT, OTHER
  final String reminderTime; // "HH:mm" e.g. "08:30"
  final String daysOfWeek;
  final String voiceMessage;
  final String voiceLanguage; // "en" or "bn"
  bool isActive;
  String status; // PENDING, TAKEN, SNOOZED, MISSED
  final DateTime? lastTriggeredAt;
  final DateTime? createdAt;

  PatientReminder({
    required this.reminderId,
    required this.patientId,
    this.createdBy,
    required this.title,
    required this.category,
    required this.reminderTime,
    this.daysOfWeek = 'DAILY',
    required this.voiceMessage,
    this.voiceLanguage = 'en',
    this.isActive = true,
    this.status = 'PENDING',
    this.lastTriggeredAt,
    this.createdAt,
  });

  factory PatientReminder.fromJson(Map<String, dynamic> json) {
    return PatientReminder(
      reminderId: json['reminderId'] ?? '',
      patientId: json['patientId'] ?? '',
      createdBy: json['createdBy'],
      title: json['title'] ?? 'Reminder',
      category: (json['category'] ?? 'MEDICINE').toString().toUpperCase(),
      reminderTime: json['reminderTime'] ?? '08:00',
      daysOfWeek: json['daysOfWeek'] ?? 'DAILY',
      voiceMessage: json['voiceMessage'] ?? '',
      voiceLanguage: json['voiceLanguage'] ?? 'en',
      isActive: json['isActive'] ?? true,
      status: json['status'] ?? 'PENDING',
      lastTriggeredAt: json['lastTriggeredAt'] != null ? DateTime.tryParse(json['lastTriggeredAt']) : null,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'reminderId': reminderId,
      'patientId': patientId,
      'createdBy': createdBy,
      'title': title,
      'category': category,
      'reminderTime': reminderTime,
      'daysOfWeek': daysOfWeek,
      'voiceMessage': voiceMessage,
      'voiceLanguage': voiceLanguage,
      'isActive': isActive,
      'status': status,
      'lastTriggeredAt': lastTriggeredAt?.toIso8601String(),
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  IconData get icon {
    switch (category) {
      case 'MEDICINE':
        return Icons.medication_rounded;
      case 'FOOD':
        return Icons.restaurant_rounded;
      case 'SLEEP':
        return Icons.bedtime_rounded;
      case 'WATER':
        return Icons.water_drop_rounded;
      case 'APPOINTMENT':
        return Icons.medical_services_rounded;
      default:
        return Icons.alarm_rounded;
    }
  }

  Color get color {
    switch (category) {
      case 'MEDICINE':
        return Colors.teal;
      case 'FOOD':
        return Colors.orange.shade700;
      case 'SLEEP':
        return Colors.indigo;
      case 'WATER':
        return Colors.blue;
      case 'APPOINTMENT':
        return Colors.deepPurple;
      default:
        return Colors.teal;
    }
  }

  String get categoryDisplayName {
    switch (category) {
      case 'MEDICINE':
        return 'Medicine (ওষুধ)';
      case 'FOOD':
        return 'Food / Meal (খাবার)';
      case 'SLEEP':
        return 'Bedtime / Sleep (ঘুম)';
      case 'WATER':
        return 'Hydration / Water (জল)';
      case 'APPOINTMENT':
        return 'Doctor Appointment (চিকিৎসক)';
      default:
        return 'General Reminder';
    }
  }
}
