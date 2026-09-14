import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

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
  }

  // Notif classique (pour les arrivées, fin de pause...)
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

  // CHRONO DE PAUSE EN DIRECT (UNIQUEMENT ANDROID)
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

  // ✨ NOTIFICATION PROGRAMMÉE 2 MINUTES AVANT LA FIN (POUR IOS ET ANDROID SI BESOIN)
  Future<void> schedulePauseEndNotification(int remainingSeconds, String message) async {
    // Si la pause est trop courte (moins de 2 minutes), on ne programme rien
    if (remainingSeconds <= 120) return; 

    // On calcule le délai : temps total moins 120 secondes (2 minutes)
    final int delayInSeconds = remainingSeconds - 120;

    await _notificationsPlugin.zonedSchedule(
      id: 200, 
      title: '⏰ Bientôt la fin de la pause !',
      body: message,
      scheduledDate: tz.TZDateTime.now(tz.local).add(Duration(seconds: delayInSeconds)),
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
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  Future<void> cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id: id);
  }
}