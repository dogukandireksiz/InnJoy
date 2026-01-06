import 'package:flutter/material.dart';
import 'package:login_page/services/logger_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:login_page/widgets/auth_wrapper.dart';
import 'firebase_options.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:audioplayers/audioplayers.dart';
import 'services/database_service.dart';
import 'services/notification_service.dart';
import 'dart:async';

void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // NotificationService'i başlat (zamanlanmış bildirimler için gerekli)
  await NotificationService().initialize();

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

  // Emergency siren için AudioPlayer
  final AudioPlayer _emergencyPlayer = AudioPlayer();

  // Etkinlik bildirimleri iÇin
  final Timestamp _appStartTime = Timestamp.now();
  final Set<String> _notifiedEventIds = {};
  StreamSubscription? _eventSubscription;
  StreamSubscription? _authSubscription;

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    _listenForEmergencies();
    _setupAuthListener(); // Auth durumunu dinle
  }

  // Auth durumunu dinle ve login olunca etkinlik dinleyiciyi başlat
  void _setupAuthListener() {
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((user) {
      Logger.debug("?? DEBUG: Auth state değişti, user: ${user?.uid}");

      if (user != null) {
        // Kullanıcı login oldu, etkinlik dinleyicisini başlat
        _listenForInterestEvents();
      } else {
        // Kullanıcı logout oldu, dinleyicileri iptal et
        _eventSubscription?.cancel();
        _userSubscription?.cancel();
      }
    });
  }

  @override
  void dispose() {
    _eventSubscription?.cancel();
    _userSubscription?.cancel();
    _authSubscription?.cancel();
    _emergencyPlayer.dispose();
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

  // Zaten bildirim gönderilen emergency ID'leri
  final Set<String> _notifiedEmergencyIds = {};

  // 2. Firestore'u Dinle (GLOBAL DİNLEYİCİ)
  void _listenForEmergencies() {
    // Uygulama başlama zamanı
    final appStartTime = DateTime.now();
    Logger.debug(
      "🚨 _listenForEmergencies starting, appStartTime: $appStartTime",
    );

    FirebaseFirestore.instance
        .collection('emergency_alerts')
        .where('status', isEqualTo: 'active')
        .snapshots()
        .listen((snapshot) {
          final now = DateTime.now(); // Her snapshot için güncel zamanı al

          for (var change in snapshot.docChanges) {
            if (change.type == DocumentChangeType.added) {
              final docId = change.doc.id;
              final data = change.doc.data();

              // Already notified, skip
              if (_notifiedEmergencyIds.contains(docId)) {
                Logger.debug("🚨 Emergency $docId already notified, skipping");
                continue;
              }

              if (data != null) {
                // Timestamp check - ONLY accept alerts created in the last 60 seconds
                final timestamp = data['timestamp'] as Timestamp?;
                
                // If timestamp is null, this is a brand new alert (just written)
                // Show notification immediately
                if (timestamp == null) {
                  Logger.debug(
                    "🚨 NEW Emergency detected (null timestamp - brand new): $docId",
                  );
                  _notifiedEmergencyIds.add(docId);
                  _showEmergencyNotification(data);
                } else {
                  final alertTime = timestamp.toDate();
                  final secondsSinceAlert = now.difference(alertTime).inSeconds;

                  Logger.debug(
                    "🚨 Emergency $docId: alertTime=$alertTime, now=$now, secondsSinceAlert=$secondsSinceAlert",
                  );

                  // Only accept alerts created in the last 60 seconds
                  // (future or old alerts are rejected)
                  if (secondsSinceAlert >= 0 && secondsSinceAlert <= 60) {
                    Logger.debug(
                      "🚨 NEW Emergency detected: $docId (${secondsSinceAlert}s ago)",
                    );
                    _notifiedEmergencyIds.add(docId);
                    _showEmergencyNotification(data);
                  } else {
                    Logger.debug(
                      "🚨 OLD/FUTURE Emergency skipped: $docId (secondsSinceAlert: $secondsSinceAlert)",
                    );
                  }
                }
              }
            }
          }
        });
  }

  // 2B. Kategori Bazlı Etkinlik Dinleyici (DİNAMİK)
  StreamSubscription? _userSubscription;

  void _listenForInterestEvents() {
    final user = FirebaseAuth.instance.currentUser;
    Logger.debug(
      "?? DEBUG: _listenForInterestEvents başladı, user: ${user?.uid}",
    );

    if (user == null) {
      Logger.debug("? DEBUG: User null, bildirim dinleyicisi başlatılamadı!");
      return;
    }

    // 1. Kullanıcı dokümanını sürekli dinle (ilgi alanları değişirse anında yakala)
    _userSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .listen(
          (userSnapshot) {
            Logger.debug(
              "?? DEBUG: User snapshot geldi, exists: ${userSnapshot.exists}",
            );

            if (!userSnapshot.exists) {
              Logger.debug("? DEBUG: User dokümanı bulunamadı!");
              return;
            }

            final userData = userSnapshot.data();
            final interests = List<String>.from(userData?['interests'] ?? []);
            final hotelName = userData?['hotelName'] as String?;

            Logger.debug("?? DEBUG: Interests: $interests");
            Logger.debug("?? DEBUG: HotelName: $hotelName");

            // Çâ€œnceki etkinlik aboneliğini iptal et (varsa)
            _eventSubscription?.cancel();

            // Eğer ilgi alanı veya otel yoksa Çık
            if (interests.isEmpty) {
              Logger.debug(
                "?? DEBUG: İlgi alanları boş, dinleyici başlatılmadı!",
              );
              return;
            }

            if (hotelName == null || hotelName.isEmpty) {
              Logger.debug("?? DEBUG: HotelName boş, dinleyici başlatılmadı!");
              return;
            }

            Logger.debug(
              "? DEBUG: Etkinlik dinleyici başlatılıyor - Hotel: $hotelName, Interests: $interests",
            );

            // 2. Yeni ilgi alanlarına göre etkinlikleri dinle
            _eventSubscription = DatabaseService()
                .listenForInterestEvents(hotelName, interests)
                .listen(
                  (snapshot) {
                    Logger.debug(
                      "?? DEBUG: Etkinlik snapshot geldi, docChanges: ${snapshot.docChanges.length}",
                    );

                    for (var change in snapshot.docChanges) {
                      Logger.debug(
                        "?? DEBUG: Change type: ${change.type}, docId: ${change.doc.id}",
                      );

                      if (change.type == DocumentChangeType.added) {
                        final eventId = change.doc.id;
                        final data = change.doc.data() as Map<String, dynamic>?;

                        Logger.debug("?? DEBUG: Event data: $data");

                        // Zaten bildirim gönderilmişse atla
                        if (_notifiedEventIds.contains(eventId)) {
                          Logger.debug(
                            "?? DEBUG: Bu etkinlik iÇin zaten bildirim gönderildi: $eventId",
                          );
                          continue;
                        }

                        // createdAt kontrolü (Parent dokümandan)
                        if (data != null && data.containsKey('createdAt')) {
                          final createdAt = data['createdAt'] as Timestamp?;
                          Logger.debug(
                            "⏱ DEBUG: createdAt: $createdAt, appStartTime: $_appStartTime",
                          );

                          // Sadece uygulama açıldıktan SONRA oluşturulanları al
                          // createdAt > appStartTime olmalı (yani createdAt daha büyük/sonra olmalı)
                          if (createdAt != null &&
                              createdAt.compareTo(_appStartTime) > 0) {
                            Logger.debug(
                              "✅ DEBUG: Yeni etkinlik bulundu (appStart sonrası), bildirim gönderiliyor: $eventId",
                            );
                            _fetchEventDetailsAndNotify(hotelName, eventId);
                          } else {
                            Logger.debug(
                              "⏭️ DEBUG: Eski etkinlik (appStart öncesi veya null), bildirim gönderilmiyor",
                            );
                          }
                        } else {
                          Logger.debug(
                            "⏭️ DEBUG: createdAt yok, eski etkinlik olarak kabul ediliyor - bildirim gönderilmiyor",
                          );
                        }
                      }
                    }
                  },
                  onError: (error) {
                    Logger.debug("? DEBUG: Etkinlik dinleyici hatası: $error");
                  },
                );
          },
          onError: (error) {
            Logger.debug("? DEBUG: User dinleyici hatası: $error");
          },
        );
  }

  // Etkinlik detaylarını Çek ve bildirim gönder (retry mekanizmalı)
  Future<void> _fetchEventDetailsAndNotify(
    String hotelName,
    String eventId, {
    int retryCount = 0,
  }) async {
    Logger.debug(
      "?? DEBUG: _fetchEventDetailsAndNotify Çağrıldı - Hotel: $hotelName, EventId: $eventId (retry: $retryCount)",
    );

    try {
      final detailsDoc = await FirebaseFirestore.instance
          .collection('hotels')
          .doc(hotelName)
          .collection('events')
          .doc(eventId)
          .collection('hotel_information')
          .doc('details')
          .get();

      Logger.debug("?? DEBUG: Details dokümanı exists: ${detailsDoc.exists}");

      if (!detailsDoc.exists) {
        // Details henüz yazılmamış olabilir, retry yap
        if (retryCount < 3) {
          Logger.debug(
            "? DEBUG: Details bulunamadı, ${retryCount + 1}. deneme iÇin 500ms bekleniyor...",
          );
          await Future.delayed(const Duration(milliseconds: 500));
          return _fetchEventDetailsAndNotify(
            hotelName,
            eventId,
            retryCount: retryCount + 1,
          );
        }
        Logger.debug("? DEBUG: Details dokümanı 3 denemede de bulunamadı!");
        return;
      }

      final data = detailsDoc.data();
      Logger.debug("📋 DEBUG: Details data: $data");

      if (data == null) {
        Logger.debug("❌ DEBUG: Details data null!");
        return;
      }

      // createdAt kontrolü (Detaylarda da)
      final createdAt = data['createdAt'] as Timestamp?;
      Logger.debug(
        "⏱ DEBUG: Details createdAt: $createdAt, appStartTime: $_appStartTime",
      );

      // Sadece uygulama başladıktan SONRA oluşturulanları bildir
      // createdAt != null VE createdAt > appStartTime olmalı
      if (createdAt != null && createdAt.compareTo(_appStartTime) > 0) {
        Logger.debug("✅ DEBUG: Bildirim gönderilecek! (appStart sonrası)");
        _notifiedEventIds.add(eventId);
        _showEventNotification(data);
      } else {
        Logger.debug(
          "⏭️ DEBUG: createdAt appStart'tan önce veya null, bildirim gönderilmedi",
        );
      }
    } catch (e) {
      Logger.debug('? DEBUG: Etkinlik detay hatası: $e');
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

    // Android Bildirim Detayları - Etkinlikler iÇin
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
      "🎉 New Event: $title",
      "$location • $time${category.isNotEmpty ? ' • $category' : ''}",
      details,
    );
  }

  // 3. Bildirimi Göster (ALARM SESLİ VE YÜKSEK ÖNCELİKLİ)
  Future<void> _showEmergencyNotification(Map<String, dynamic> data) async {
    Logger.debug("🚨🚨🚨 _showEmergencyNotification ÇAĞRILDI! Data: $data");

    String type = data['type'] ?? 'Acil Durum';
    String room = data['room_number'] ?? 'Bilinmiyor';
    String location = data['location_context'] ?? 'Otel Alanı';

    // Location translation (English key -> English)
    String locationText;
    switch (location) {
      case 'my_room':
        locationText = 'Room $room';
        break;
      case 'restaurant':
        locationText = 'Restaurant';
        break;
      case 'fitness':
        locationText = 'Fitness Center';
        break;
      case 'spa':
        locationText = 'Spa Center';
        break;
      case 'reception':
        locationText = 'Reception';
        break;
      default:
        locationText = location;
    }

    // Benzersiz bildirim ID'si (üst üste yazmasın)
    final int notificationId = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    // 🔊 ÖNCE SESİ ÇAL (audioplayers ile - notification channel'dan bağımsız)
    try {
      await _emergencyPlayer.stop(); // Önceki ses varsa durdur
      await _emergencyPlayer.setReleaseMode(ReleaseMode.stop); // Tek sefer çal
      await _emergencyPlayer.setVolume(1.0); // Maksimum ses
      await _emergencyPlayer.play(AssetSource('sounds/emergency_siren.mp3'));
      Logger.debug('🔊 Emergency siren çalınıyor!');
    } catch (e) {
      Logger.error('❌ Emergency siren çalınamadı: $e');
    }

    // Android Bildirim Detayları - Varsayılan Alarm Sesi
    const AndroidNotificationDetails
    androidDetails = AndroidNotificationDetails(
      'emergency_alarm_channel_v2', // Yeni kanal adı (eski kanalda ses çalışmıyorsa)
      'Acil Durum Alarmları',
      channelDescription: 'Yüksek öncelikli acil durum alarm bildirimleri',
      importance: Importance.max,
      priority: Priority.high,
      color: Colors.red,
      playSound: true,
      sound: RawResourceAndroidNotificationSound(
        'emergency_siren',
      ), // Android özel ses (res/raw/emergency_siren.mp3)
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
      sound: 'emergency_siren.wav', // iOS özel ses dosyası
      interruptionLevel: InterruptionLevel.critical, // Kritik uyarı
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notificationsPlugin.show(
      notificationId, // Unique ID
      "🚨 EMERGENCY: $type",
      "📍 Location: $locationText",
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
