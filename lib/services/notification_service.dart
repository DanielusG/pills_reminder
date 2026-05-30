import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

/// Servizio per la gestione delle notifiche locali
class NotificationService extends ChangeNotifier {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  /// Inizializza il plugin notifiche
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

    // Richiedi permesso notifiche su Android 13+
    await _requestPermissions();
  }

  /// Richiede i permessi per le notifiche
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

  /// Schedula una notifica giornaliera per una pillola
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
    // DateTime() usa l'orario locale del dispositivo.
    // tz.TZDateTime.from() preserva l'istante esatto convertendolo in TZDateTime.
    final scheduledDate = tz.TZDateTime.from(localDate, tz.getLocation('Etc/UTC'));

    await _plugin.zonedSchedule(
      id: id,
      title: name,
      body: 'È ora di assumere: $quantity',
      scheduledDate: scheduledDate,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'pills_channel',
          'Promemoria Pillole',
          channelDescription: 'Notifiche per l\'assunzione dei farmaci',
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

  /// Cancella una notifica schedulata
  Future<void> cancelNotification(int id) async {
    await _plugin.cancel(id: id);
  }

  /// Cancella tutte le notifiche
  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  /// Callback quando l'utente tap sulla notifica
  void _onNotificationTap(NotificationResponse response) {
    // Notifica i listener (HomeScreen) per triggerare un refresh
    notifyListeners();
  }
}
