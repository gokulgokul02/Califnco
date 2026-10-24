import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService instance = NotificationService._();
  NotificationService._();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  static const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'califnco_orders',
    'Califnco Notifications',
    description: 'High-priority notifications for Califnco water purifier orders and services',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
  );

  Future<void> initialize() async {
    if (_initialized) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    await _notificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) {
        debugPrint('[Notification Tap] Payload: ${response.payload}');
      },
    );

    // Create Notification Channel for Android
    final androidImpl = _notificationsPlugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidImpl != null) {
      await androidImpl.createNotificationChannel(channel);

      // Request notification permission for Android 13+ (API 33+)
      if (Platform.isAndroid) {
        await androidImpl.requestNotificationsPermission();
      }
    }

    _initialized = true;
  }

  Future<void> showSystemNotification({
    int id = 0,
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      if (!_initialized) await initialize();

      const androidDetails = AndroidNotificationDetails(
        'califnco_orders',
        'Califnco Notifications',
        channelDescription: 'High-priority notifications for orders and services',
        importance: Importance.max,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        playSound: true,
        enableVibration: true,
      );

      const notificationDetails = NotificationDetails(android: androidDetails);

      await _notificationsPlugin.show(
        id == 0 ? DateTime.now().millisecondsSinceEpoch % 100000 : id,
        title,
        body,
        notificationDetails,
        payload: payload,
      );
    } catch (e) {
      debugPrint('[NotificationService] Error showing system notification: $e');
    }
  }
}
