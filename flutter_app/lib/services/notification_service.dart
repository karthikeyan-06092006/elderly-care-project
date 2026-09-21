import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'api_service.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint("🚨 Background FCM Emergency Alert: ${message.messageId} - ${message.notification?.title}");
}

class NotificationService {
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotificationsPlugin = FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _emergencyChannel = AndroidNotificationChannel(
    'emergency_channel',
    'Emergency SOS Alerts',
    description: 'High-priority critical alerts for patient emergency SOS events',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
  );

  static Future<void> initialize() async {
    try {
      // 1. Request notification permissions for Android 13+ / iOS
      final settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
        criticalAlert: true,
      );
      debugPrint('Notification Permission status: ${settings.authorizationStatus}');

      // 2. Initialize Local Notifications Plugin
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const initSettings = InitializationSettings(android: androidSettings);

      await _localNotificationsPlugin.initialize(
        settings: initSettings,
      );

      // 3. Create High-Priority Notification Channel on Android
      final platform = _localNotificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (platform != null) {
        await platform.createNotificationChannel(_emergencyChannel);
      }

      // 4. Background message handler
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // 5. Foreground message handler
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint("🔔 Foreground FCM message received: ${message.notification?.title}");
        showEmergencyNotification(
          title: message.notification?.title ?? "🚨 EMERGENCY SOS",
          body: message.notification?.body ?? "A patient has triggered an emergency alert!",
        );
      });
    } catch (e) {
      debugPrint("NotificationService initialization notice: $e");
    }
  }

  static Future<String?> getFcmToken() async {
    try {
      return await _firebaseMessaging.getToken();
    } catch (e) {
      debugPrint("Could not retrieve FCM token: $e");
      return null;
    }
  }

  static Future<void> registerDeviceToken(String email) async {
    final token = await getFcmToken();
    if (token != null && token.isNotEmpty) {
      await ApiService.updateFcmToken(email: email, fcmToken: token);
    }
  }

  static Future<void> showEmergencyNotification({
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'emergency_channel',
      'Emergency SOS Alerts',
      channelDescription: 'High-priority critical alerts for patient emergency SOS events',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      styleInformation: BigTextStyleInformation(''),
      color: Colors.red,
      icon: '@mipmap/ic_launcher',
    );

    const notificationDetails = NotificationDetails(android: androidDetails);

    await _localNotificationsPlugin.show(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: title,
      body: body,
      notificationDetails: notificationDetails,
    );
  }
}
