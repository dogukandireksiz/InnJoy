import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:flutter/material.dart';
import 'logger_service.dart';

/// NotificationService - Singleton pattern ile zamanlanmış bildirimler.
/// Rezervasyon, etkinlik ve spa randevuları için 1 saat önceden hatırlatıcı gönderir.
class NotificationService {
  // Singleton pattern
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  /// Servisi başlat (main.dart'ta çağrılmalı)
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Timezone verilerini yükle
    tz_data.initializeTimeZones();

    // Türkiye için yerel saat dilimini ayarla (Europe/Istanbul = UTC+3)
    tz.setLocalLocation(tz.getLocation('Europe/Istanbul'));

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(settings);

    // Android 13+ için bildirim izni iste
    final androidPlugin = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (androidPlugin != null) {
      final granted = await androidPlugin.requestNotificationsPermission();
      Logger.debug('🔔 Notification permission granted: $granted');

      // Exact alarm izni de iste (Android 12+)
      final exactAlarmGranted = await androidPlugin
          .requestExactAlarmsPermission();
      Logger.debug('⏰ Exact alarm permission granted: $exactAlarmGranted');
    }

    _isInitialized = true;
    Logger.debug('✅ NotificationService initialized');
  }

  /// Hatırlatıcı bildirimi zamanla
  /// [id] - Benzersiz bildirim ID'si (iptal için gerekli)
  /// [title] - Bildirim başlığı
  /// [body] - Bildirim içeriği
  /// [scheduledTime] - Bildirimin gösterileceği zaman
  /// [type] - Bildirim türü ('spa', 'event', 'restaurant')
  Future<void> scheduleReminderNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String type = 'reminder',
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    // Eğer zamanlanmış zaman geçmişte ise bildirim gönderme
    if (scheduledTime.isBefore(DateTime.now())) {
      Logger.debug('⚠️ Scheduled time is in the past, skipping notification');
      return;
    }

    // Android kanal ayarları
    AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'reminder_channel_$type',
      'Reminder Notifications',
      channelDescription: 'Reservation and appointment reminders',
      importance: Importance.high,
      priority: Priority.high,
      color: _getColorForType(type),
      playSound: true,
      enableVibration: true,
      category: AndroidNotificationCategory.reminder,
      visibility: NotificationVisibility.public,
      autoCancel: true,
      icon: '@mipmap/ic_launcher',
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // TZDateTime'a çevir
    final tz.TZDateTime tzScheduledTime = tz.TZDateTime.from(
      scheduledTime,
      tz.local,
    );

    try {
      await _notificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        tzScheduledTime,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: null,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );

      // FALLBACK: Timer-based bildirim (uygulama açıkken)
      // zonedSchedule bazı cihazlarda çalışmayabilir, bu yüzden Timer da kullanıyoruz
      final delay = scheduledTime.difference(DateTime.now());
      if (delay.inSeconds > 0) {
        Future.delayed(delay, () async {
          await _notificationsPlugin.show(id + 1, title, body, details);
        });
      }
    } catch (e) {
      Logger.error('❌ Failed to schedule notification: $e');
    }
  }

  /// Zamanlanmış bildirimi iptal et
  Future<void> cancelReminderNotification(int id) async {
    try {
      await _notificationsPlugin.cancel(id);
      Logger.debug('🗑️ Notification cancelled: ID=$id');
    } catch (e) {
      Logger.error('❌ Failed to cancel notification: $e');
    }
  }

  /// Tüm zamanlanmış bildirimleri iptal et
  Future<void> cancelAllReminderNotifications() async {
    try {
      await _notificationsPlugin.cancelAll();
      Logger.debug('🗑️ All notifications cancelled');
    } catch (e) {
      Logger.error('❌ Failed to cancel all notifications: $e');
    }
  }

  /// Bildirim türüne göre renk döndür
  Color _getColorForType(String type) {
    switch (type) {
      case 'spa':
        return const Color(0xFF9C27B0); // Mor - Spa
      case 'event':
        return const Color(0xFF2196F3); // Mavi - Etkinlik
      case 'restaurant':
        return const Color(0xFFFF9800); // Turuncu - Restoran
      default:
        return const Color(0xFF137fec); // Varsayılan mavi
    }
  }

  /// Benzersiz bildirim ID'si oluştur (DateTime ve type kombinasyonu)
  static int generateNotificationId(DateTime dateTime, String type) {
    // DateTime'ın hashCode'u ve type'ın hashCode'unu birleştir
    return dateTime.millisecondsSinceEpoch.hashCode ^ type.hashCode;
  }
}
