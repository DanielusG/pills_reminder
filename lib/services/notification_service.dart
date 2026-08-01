import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

/// Local notification service
class NotificationService extends ChangeNotifier {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  /// Initialize the notification plugin
  Future<void> initialize() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
    );

    await _plugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // Request notification permission on Android 13+
    await _requestPermissions();
  }

  /// Request notification permissions
  Future<void> _requestPermissions() async {
    final androidImpl = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidImpl?.requestNotificationsPermission();

    final iosImpl = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    await iosImpl?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  /// Schedule a daily notification for a pill
  Future<void> scheduleDailyNotification({
    required int id,
    required String name,
    required String quantity,
    required String time,
  }) async {
    final parts = time.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);

    final now = DateTime.now();
    final localDate = DateTime(
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    // DateTime() uses the device's local time zone.
    // tz.TZDateTime.from() preserves the exact instant, converting to TZDateTime.
    final scheduledDate = tz.TZDateTime.from(localDate, tz.getLocation('Etc/UTC'));

    final locale = Platform.localeName.substring(0, 2);
    final body = _formatNotificationBody(locale, quantity);
    await _plugin.zonedSchedule(
      id: id,
      title: name,
      body: body,
      scheduledDate: scheduledDate,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          'pills_channel',
          _getChannelName(locale),
          channelDescription: _getChannelDescription(locale),
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  String _formatNotificationBody(String locale, String quantity) {
    switch (locale) {
      case 'it':
        return 'È ora di assumere: $quantity';
      case 'en':
      default:
        return 'Time to take: $quantity';
    }
  }

  String _getChannelName(String locale) {
    switch (locale) {
      case 'it':
        return 'Promemoria Pillole';
      case 'en':
      default:
        return 'Pill Reminders';
    }
  }

  String _getChannelDescription(String locale) {
    switch (locale) {
      case 'it':
        return 'Notifiche per l\'assunzione dei farmaci';
      case 'en':
      default:
        return 'Notifications for medication intake';
    }
  }

  /// Cancel a scheduled notification
  Future<void> cancelNotification(int id) async {
    await _plugin.cancel(id: id);
  }

  /// Cancel all notifications
  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  /// Callback when user taps a notification
  void _onNotificationTap(NotificationResponse response) {
    // Notify listeners (HomeScreen) to trigger a refresh
    notifyListeners();
  }
}
