import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:permission_handler/permission_handler.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz.initializeTimeZones();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsDarwin = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
      macOS: initializationSettingsDarwin,
    );

    await _notificationsPlugin.initialize(settings: initializationSettings);

    // ✨ Demande explicite de la permission notification (Android 13+)
    final androidPlugin = _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.requestNotificationsPermission();
  }

  Future<bool> requestExactAlarmPermission() async {
    final status = await Permission.scheduleExactAlarm.status;
    if (status.isGranted) return true;

    final result = await Permission.scheduleExactAlarm.request();
    return result.isGranted;
  }

  // Notif classique (pour les arrivées)
  Future<void> showNotification({required int id, required String title, required String body}) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'focus_channel_id', 
      'Voyages et Pauses',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    await _notificationsPlugin.show(
      id: id, 
      title: title, 
      body: body, 
      notificationDetails: platformDetails,
    );
  }

  // ✨ CHRONO DE PAUSE EN DIRECT (ANDROID)
  Future<void> showPauseChronometer(int remainingSeconds) async {
    final int endTime = DateTime.now().millisecondsSinceEpoch + (remainingSeconds * 1000);

    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'pause_chrono_channel',
      'Pause au feu de camp',
      channelDescription: 'Affiche le temps de pause restant en direct',
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true,
      autoCancel: false,
      usesChronometer: true,
      chronometerCountDown: true,
      when: endTime,
      showWhen: true,
    );

    final NotificationDetails platformDetails = NotificationDetails(android: androidDetails);

    await _notificationsPlugin.show(
      id: 200,
      title: '🔥 Pause au coin du feu',
      body: 'Temps de repos restant :',
      notificationDetails: platformDetails,
    );
  }

  // ✨ NOTIFICATION PROGRAMMÉE 2 MINUTES AVANT LA FIN (IOS ET ANDROID)
  Future<void> schedulePauseEndNotification(int remainingSeconds, String message) async {
  if (remainingSeconds <= 120) {
    debugPrint('⏭️ Pause trop courte, notif 2min non programmée');
    return;
  }

  final int delayInSeconds = remainingSeconds - 120;
  final canScheduleExact = await Permission.scheduleExactAlarm.isGranted;
  final scheduledDate = tz.TZDateTime.now(tz.local).add(Duration(seconds: delayInSeconds));

  debugPrint('🔔 Notif 201 programmée pour: $scheduledDate (exact: $canScheduleExact, délai: ${delayInSeconds}s)');

  await _notificationsPlugin.zonedSchedule(
    id: 201,
    title: '⏰ Bientôt la fin de la pause !',
    body: message,
    scheduledDate: scheduledDate,
    notificationDetails: const NotificationDetails(
      android: AndroidNotificationDetails(
        'pause_channel_id',
        'Fin de pause',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    ),
    androidScheduleMode: canScheduleExact
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle,
  );
}


  Future<void> cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id: id);
  }
}