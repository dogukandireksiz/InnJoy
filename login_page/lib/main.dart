import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:login_page/widgets/auth_wrapper.dart';
import 'firebase_options.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'service/database_service.dart';
import 'dart:async';

void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const InnJoyHotelApp());
}

class InnJoyHotelApp extends StatefulWidget {
  const InnJoyHotelApp({super.key});

  @override
  State<InnJoyHotelApp> createState() => _InnJoyHotelAppState();
}

class _InnJoyHotelAppState extends State<InnJoyHotelApp> {
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Etkinlik bildirimleri için
  final Timestamp _appStartTime = Timestamp.now();
  final Set<String> _notifiedEventIds = {};
  StreamSubscription? _eventSubscription;

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    _listenForEmergencies();
    _listenForInterestEvents(); // Yeni: Kategori bazlı etkinlik dinleyici
  }

  @override
  void dispose() {
    _eventSubscription?.cancel();
    super.dispose();
  }

  // 1. Bildirim Ayarlarını Başlat
  Future<void> _initializeNotifications() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher'); // Varsayılan ikon

    // iOS Ayarları (İzin istemek gerekebilir)
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
  }

  // 2. Firestore'u Dinle (GLOBAL DİNLEYİCİ)
  void _listenForEmergencies() {
    // Sadece şu andan sonraki alarmları dinle (Eskiler bildirim yapmasın)
    final Timestamp startTime = Timestamp.now();

    FirebaseFirestore.instance
        .collection('emergency_alerts')
        .where('timestamp', isGreaterThan: startTime)
        .snapshots()
        .listen((snapshot) {
          for (var change in snapshot.docChanges) {
            if (change.type == DocumentChangeType.added) {
              final data = change.doc.data();
              if (data != null) {
                _showEmergencyNotification(data);
              }
            }
          }
        });
  }

  // 2B. Kategori Bazlı Etkinlik Dinleyici
  void _listenForInterestEvents() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // Kullanıcı verilerini çek
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!userDoc.exists) return;

      final userData = userDoc.data();
      final interests = List<String>.from(userData?['interests'] ?? []);
      final hotelName = userData?['hotelName'] as String?;

      // İlgi alanı veya otel yoksa dinleme
      if (interests.isEmpty || hotelName == null || hotelName.isEmpty) return;

      // Mevcut DatabaseService metodunu kullanarak dinle
      _eventSubscription = DatabaseService()
          .listenForInterestEvents(hotelName, interests)
          .listen((snapshot) {
            for (var change in snapshot.docChanges) {
              if (change.type == DocumentChangeType.added) {
                final eventId = change.doc.id;

                // Zaten bildirim gönderilmişse atla
                if (_notifiedEventIds.contains(eventId)) continue;

                // Etkinlik verisini al (hotel_information/details'dan)
                _fetchEventDetailsAndNotify(hotelName, eventId);
              }
            }
          });
    } catch (e) {
      debugPrint('Etkinlik dinleme hatası: $e');
    }
  }

  // Etkinlik detaylarını çek ve bildirim gönder
  Future<void> _fetchEventDetailsAndNotify(
    String hotelName,
    String eventId,
  ) async {
    try {
      final detailsDoc = await FirebaseFirestore.instance
          .collection('hotels')
          .doc(hotelName)
          .collection('events')
          .doc(eventId)
          .collection('hotel_information')
          .doc('details')
          .get();

      if (!detailsDoc.exists) return;

      final data = detailsDoc.data();
      if (data == null) return;

      // createdAt kontrolü - uygulama başladıktan sonra mı eklendi?
      final createdAt = data['createdAt'] as Timestamp?;
      if (createdAt != null && createdAt.compareTo(_appStartTime) > 0) {
        _notifiedEventIds.add(eventId);
        _showEventNotification(data);
      }
    } catch (e) {
      debugPrint('Etkinlik detay hatası: $e');
    }
  }

  // Etkinlik Bildirimi Göster
  Future<void> _showEventNotification(Map<String, dynamic> data) async {
    final title = data['title'] ?? 'Yeni Etkinlik';
    final time = data['time'] ?? '';
    final location = data['location'] ?? 'Otel';
    final category = data['category'] ?? '';

    // Benzersiz bildirim ID'si
    final int notificationId = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    // Android Bildirim Detayları - Etkinlikler için
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'event_notification_channel',
          'Etkinlik Bildirimleri',
          channelDescription: 'Yeni etkinlik bildirimleri',
          importance: Importance.high,
          priority: Priority.defaultPriority,
          color: Colors.blue,
          playSound: true,
          enableVibration: true,
          category: AndroidNotificationCategory.event,
          visibility: NotificationVisibility.public,
          autoCancel: true,
        );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notificationsPlugin.show(
      notificationId,
      "🎉 Yeni Etkinlik: $title",
      "📍 $location • ⏰ $time${category.isNotEmpty ? ' • $category' : ''}",
      details,
    );
  }

  // 3. Bildirimi Göster (ALARM SESLİ VE YÜKSEK ÖNCELİKLİ)
  Future<void> _showEmergencyNotification(Map<String, dynamic> data) async {
    String type = data['type'] ?? 'Acil Durum';
    String room = data['room_number'] ?? 'Bilinmiyor';
    String location = data['location_context'] ?? 'Otel Alanı';

    // Konum çevirisi (İngilizce key -> Türkçe)
    String locationText;
    switch (location) {
      case 'my_room':
        locationText = 'Oda $room';
        break;
      case 'restaurant':
        locationText = 'Restoran';
        break;
      case 'fitness':
        locationText = 'Spor Salonu';
        break;
      case 'spa':
        locationText = 'Spa Merkezi';
        break;
      case 'reception':
        locationText = 'Resepsiyon';
        break;
      default:
        locationText = location;
    }

    // Benzersiz bildirim ID'si (üst üste yazmasın)
    final int notificationId = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    // Android Bildirim Detayları - Varsayılan Alarm Sesi
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'emergency_alarm_channel', // Yeni kanal adı
          'Acil Durum Alarmları',
          channelDescription: 'Yüksek öncelikli acil durum alarm bildirimleri',
          importance: Importance.max,
          priority: Priority.high,
          color: Colors.red,
          playSound: true,
          // Varsayılan bildirim sesini kullan (playSound: true ile)
          enableVibration: true,
          fullScreenIntent: true, // Ekran kilitliyken bile tam ekran göster
          category: AndroidNotificationCategory.alarm, // Alarm kategorisi
          visibility: NotificationVisibility.public, // Kilit ekranında görünsün
          ongoing: false,
          autoCancel: true,
        );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'default', // iOS varsayılan alarm
      interruptionLevel: InterruptionLevel.critical, // Kritik uyarı
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notificationsPlugin.show(
      notificationId, // Benzersiz ID
      "🚨 ACİL DURUM: $type",
      "📍 Konum: $locationText",
      details,
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en', 'US'), Locale('tr', 'TR')],
      home: const AuthWrapper(),
    );
  }
}
