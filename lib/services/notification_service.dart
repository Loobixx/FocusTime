import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:permission_handler/permission_handler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

  // ✨ PLANIFIER OU DÉCLENCHER LE BILAN QUOTIDIEN DE 20H
  Future<void> checkAndSendDailySummary() async {
    final prefs = await _getUserPreferences();
    if (prefs['arrival'] == false && prefs['pauseReminder'] == false) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('history')
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .get();

      int totalMinutesToday = 0;
      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        totalMinutesToday += (data['durationMinutes'] as int?) ?? 0;
      }

      String title;
      String body;

      if (totalMinutesToday >= 180) {
        title = '🌟 Journée légendaire !';
        body = 'Tu as validé plus de 3h de focus aujourd\'hui, ton voyage avance à grand pas !';
      } else if (totalMinutesToday >= 30) {
        title = '👍 Belle régularité !';
        body = 'Tu as planté de belles bases aujourd\'hui ($totalMinutesToday min). Encore un effort demain !';
      } else {
        title = '🌧️ Ton personnage s\'ennuie...';
        body = 'L\'application n\'a pas été beaucoup utilisée aujourd\'hui. Viens faire un petit tour sur les sentiers !';
      }

      await showNotification(
        id: 300,
        title: title,
        body: body,
      );
      
      debugPrint('📊 Bilan de 20h envoyé : $totalMinutesToday minutes aujourd\'hui.');
    } catch (e) {
      debugPrint('❌ Erreur lors du calcul du bilan quotidien : $e');
    }
  }

  // Programmer l'alerte quotidienne à 20h00
  Future<void> scheduleDailySummaryAt20H() async {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, 20, 0);

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    const androidDetails = AndroidNotificationDetails(
      'daily_summary_channel',
      'Bilan quotidien',
      channelDescription: 'Notification de fin de journée à 20h',
      importance: Importance.high,
      priority: Priority.high,
    );

    await _notificationsPlugin.zonedSchedule(
      id: 300,
      title: 'Bilan de la journée',
      body: 'Regardons ta progression du jour...',
      scheduledDate: scheduledDate,
      notificationDetails: const NotificationDetails(
        android: androidDetails,
        iOS: DarwinNotificationDetails(presentAlert: true, presentSound: true),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
    
    debugPrint('⏰ Bilan quotidien programmé pour 20h00.');
  }

  Future<Map<String, dynamic>> _getUserPreferences() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return {'arrival': true, 'pauseReminder': true, 'sound': true};

      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final data = doc.data();

      return {
        'arrival': data?['notifArrival'] ?? true,
        'pauseReminder': data?['notifPauseReminder'] ?? true,
        'sound': data?['notifSound'] ?? true,
      };
    } catch (e) {
      return {'arrival': true, 'pauseReminder': true, 'sound': true};
    }
  }

  // Fonction utilitaire pour les détails Android par défaut
  AndroidNotificationDetails _defaultAndroidDetails(bool playSound) {
    return AndroidNotificationDetails(
      'focus_channel_id', 
      'Voyages et Pauses',
      importance: Importance.max,
      priority: Priority.high,
      playSound: playSound,
    );
  }

  // ✨ Notification classique (avec option d'image grande taille)
  Future<void> showNotification({
    required int id, 
    required String title, 
    required String body,
    String? imageAssetPath, 
  }) async {
    final prefs = await _getUserPreferences();
    if (prefs['arrival'] == false) return;

    final bool playSound = prefs['sound'] ?? true;
    AndroidNotificationDetails androidDetails;

    if (imageAssetPath != null) {
      try {
        final ByteArrayAndroidBitmap? bigImage = await _loadAssetImageForAndroid(imageAssetPath);
        
        if (bigImage != null) {
          final BigPictureStyleInformation bigPictureStyleInformation = BigPictureStyleInformation(
            bigImage,
            contentTitle: title,
            summaryText: body,
          );

          androidDetails = AndroidNotificationDetails(
            'focus_channel_id', 
            'Voyages et Pauses',
            importance: Importance.max,
            priority: Priority.high,
            playSound: playSound,
            styleInformation: bigPictureStyleInformation,
          );
        } else {
          androidDetails = _defaultAndroidDetails(playSound);
        }
      } catch (e) {
        androidDetails = _defaultAndroidDetails(playSound);
      }
    } else {
      androidDetails = _defaultAndroidDetails(playSound);
    }

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notificationsPlugin.show(
      id: id, 
      title: title, 
      body: body, 
      notificationDetails: platformDetails,
    );
  }

  // ✨ Charge l'asset directement en mémoire sous forme de Bytes pour Android
  Future<ByteArrayAndroidBitmap?> _loadAssetImageForAndroid(String assetPath) async {
    try {
      final ByteData data = await rootBundle.load(assetPath);
      final Uint8List bytes = data.buffer.asUint8List();
      return ByteArrayAndroidBitmap(bytes);
    } catch (e) {
      debugPrint('❌ Erreur conversion asset en bytes pour notification: $e');
      return null;
    }
  }
  
  Future<void> showPauseChronometer(int remainingSeconds) async {
    final prefs = await _getUserPreferences();
    if (prefs['pauseReminder'] == false) return;

    final bool playSound = prefs['sound'] ?? true;
    final int endTime = DateTime.now().millisecondsSinceEpoch + (remainingSeconds * 1000);

    AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'pause_chrono_channel',
      'Pause au coin du feu',
      channelDescription: 'Affiche le temps de pause restant en direct',
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true,
      autoCancel: false,
      usesChronometer: true,
      chronometerCountDown: true,
      when: endTime,
      showWhen: true,
      playSound: playSound,
    );

    NotificationDetails platformDetails = NotificationDetails(android: androidDetails);

    await _notificationsPlugin.show(
      id: 200,
      title: '🔥 Pause au coin du feu',
      body: 'Temps de repos restant :',
      notificationDetails: platformDetails,
    );
  }

  Future<void> schedulePauseEndNotification(int remainingSeconds, String message) async {
    final prefs = await _getUserPreferences();
    if (prefs['pauseReminder'] == false) return;

    if (remainingSeconds <= 120) return;

    final bool playSound = prefs['sound'] ?? true;
    final int delayInSeconds = remainingSeconds - 120;
    final canScheduleExact = await Permission.scheduleExactAlarm.isGranted;
    final scheduledDate = tz.TZDateTime.now(tz.local).add(Duration(seconds: delayInSeconds));

    await _notificationsPlugin.zonedSchedule(
      id: 201,
      title: '⏰ Bientôt la fin de la pause !',
      body: message,
      scheduledDate: scheduledDate,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          'pause_channel_id',
          'Fin de pause',
          importance: Importance.max,
          priority: Priority.high,
          playSound: playSound,
        ),
        iOS: const DarwinNotificationDetails(
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