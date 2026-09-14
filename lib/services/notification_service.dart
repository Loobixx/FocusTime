import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    // Initialisation des fuseaux horaires (obligatoire pour programmer dans le futur)
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

    // ✨ CORRECTION : Le paramètre s'appelle maintenant "settings"
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

    // ✨ CORRECTION : Utilisation des paramètres nommés
    await _notificationsPlugin.show(
      id: id, 
      title: title, 
      body: body, 
      notificationDetails: platformDetails,
    );
  }

  // CHRONO EN DIRECT (UNIQUEMENT ANDROID)
  Future<void> showLiveTimerNotification(int remainingSeconds, String destination) async {
    final int endTime = DateTime.now().millisecondsSinceEpoch + (remainingSeconds * 1000);

    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'live_timer_channel',
      'Marche en cours',
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

    // ✨ CORRECTION : Utilisation des paramètres nommés
    await _notificationsPlugin.show(
      id: 99, 
      title: '🥾 En marche vers $destination',
      body: 'Temps restant :',
      notificationDetails: platformDetails,
    );
  }

  // NOTIFICATION PROGRAMMÉE 1 MINUTE AVANT (UNIQUEMENT IOS)
  Future<void> scheduleIOSNotification(int remainingSeconds, String destination) async {
    // Si on est à moins d'une minute de l'arrivée, pas la peine de prévenir
    if (remainingSeconds <= 60) return; 

    // On calcule le délai : temps total moins 60 secondes
    final int delayInSeconds = remainingSeconds - 60;

    // ✨ CORRECTION : Utilisation des paramètres nommés et suppression de uiLocalNotificationDateInterpretation
    await _notificationsPlugin.zonedSchedule(
      id: 100, 
      title: 'Presque arrivé !',
      body: 'Tu arrives à $destination dans moins d\'une minute, prépare-toi !',
      scheduledDate: tz.TZDateTime.now(tz.local).add(Duration(seconds: delayInSeconds)),
      notificationDetails: const NotificationDetails(
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
    // ✨ CORRECTION : Le paramètre s'appelle maintenant "id"
    await _notificationsPlugin.cancel(id: id);
  }
}