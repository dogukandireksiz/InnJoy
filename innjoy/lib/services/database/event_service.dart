import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:login_page/services/database/base_database_service.dart';
import 'package:login_page/services/logger_service.dart';

/// EventService - Events, registration, and interests management.
class EventService extends BaseDatabaseService {
  // Singleton pattern
  static final EventService _instance = EventService._internal();
  factory EventService() => _instance;
  EventService._internal();

  // Helper: Etkinlik adını sanitize et (klasör adı için)
  String _sanitizeEventName(String name) {
    final turkishChars = {
      'ı': 'i',
      'ğ': 'g',
      'ü': 'u',
      'ş': 's',
      'ö': 'o',
      'ç': 'c',
      'İ': 'I',
      'Ğ': 'G',
      'Ü': 'U',
      'Ş': 'S',
      'Ö': 'O',
      'Ç': 'C',
    };
    String sanitized = name;
    turkishChars.forEach((key, value) {
      sanitized = sanitized.replaceAll(key, value);
    });
    sanitized = sanitized
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .replaceAll(RegExp(r'\s+'), '_')
        .toLowerCase();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '${sanitized}_$timestamp';
  }

  // 1. Etkinlikleri Getir (Otel Bazlı)
  Stream<List<Map<String, dynamic>>> getHotelEvents(String hotelName) {
    return db
        .collection('hotels')
        .doc(hotelName)
        .collection('events')
        .snapshots()
        .asyncMap((snapshot) async {
          List<Map<String, dynamic>> events = [];

          for (var doc in snapshot.docs) {
            final detailsDoc = await doc.reference
                .collection('hotel_information')
                .doc('details')
                .get();

            if (detailsDoc.exists && detailsDoc.data() != null) {
              var data = detailsDoc.data()!;
              data['id'] = doc.id;
              events.add(data);
            }
          }

          events.sort((a, b) {
            final aDate = a['date'];
            final bDate = b['date'];
            if (aDate == null || bDate == null) return 0;
            if (aDate is Timestamp && bDate is Timestamp) {
              return aDate.compareTo(bDate);
            }
            return 0;
          });

          return events;
        });
  }

  // 2. Etkinlik Ekle
  Future<String> addEvent(
    String hotelName,
    Map<String, dynamic> eventData,
  ) async {
    final eventTitle = eventData['title'] ?? 'event';
    final eventFolderId = _sanitizeEventName(eventTitle);

    final eventRef = db
        .collection('hotels')
        .doc(hotelName)
        .collection('events')
        .doc(eventFolderId);

    await eventRef.set({
      'createdAt': FieldValue.serverTimestamp(),
      'eventName': eventData['title'],
      'category': eventData['category'],
      'date': eventData['date'],
      'isPublished': eventData['isPublished'] ?? true,
    });

    await eventRef.collection('hotel_information').doc('details').set({
      ...eventData,
      'registered': eventData['registered'] ?? 0,
    });

    return eventFolderId;
  }

  // 3. Etkinlik Güncelle
  Future<void> updateEvent(
    String hotelName,
    String eventId,
    Map<String, dynamic> eventData,
  ) async {
    final eventRef = db
        .collection('hotels')
        .doc(hotelName)
        .collection('events')
        .doc(eventId);

    await eventRef.update({
      if (eventData.containsKey('title')) 'eventName': eventData['title'],
      if (eventData.containsKey('category')) 'category': eventData['category'],
      if (eventData.containsKey('date')) 'date': eventData['date'],
      if (eventData.containsKey('isPublished'))
        'isPublished': eventData['isPublished'],
    });

    await eventRef
        .collection('hotel_information')
        .doc('details')
        .update(eventData);
  }

  // --- ETKİNLİK KATILIMCILARI (ADMIN) ---
  Stream<List<Map<String, dynamic>>> getEventParticipants(
    String hotelName,
    String eventId,
  ) {
    return db
        .collection('hotels')
        .doc(hotelName)
        .collection('events')
        .doc(eventId)
        .collection('registrants')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  // 4. Etkinlik Sil
  Future<void> deleteEvent(String hotelName, String eventId) async {
    final eventRef = db
        .collection('hotels')
        .doc(hotelName)
        .collection('events')
        .doc(eventId);

    final hotelInfoDocs = await eventRef.collection('hotel_information').get();
    for (var doc in hotelInfoDocs.docs) {
      await doc.reference.delete();
    }

    final registrantsDocs = await eventRef.collection('registrants').get();
    for (var doc in registrantsDocs.docs) {
      await doc.reference.delete();
    }

    await eventRef.delete();
  }

  // ETKİNLİK KAYIT
  Future<Map<String, dynamic>> registerForEvent(
    String hotelName,
    String eventId,
    Map<String, dynamic> userInfo,
    Map<String, dynamic> eventDetails,
  ) async {
    final eventRef = db
        .collection('hotels')
        .doc(hotelName)
        .collection('events')
        .doc(eventId);

    try {
      final hotelInfoRef = eventRef
          .collection('hotel_information')
          .doc('details');
      final registrantsRef = eventRef
          .collection('registrants')
          .doc(userInfo['userId']);

      return await db.runTransaction((transaction) async {
        final detailsSnapshot = await transaction.get(hotelInfoRef);
        if (!detailsSnapshot.exists) {
          return {'success': false, 'message': 'Event not found.'};
        }
        final eventData = detailsSnapshot.data()!;

        final currentRegistered = eventData['registered'] ?? 0;
        final capacity = eventData['capacity'] ?? 0;

        if (capacity > 0 && currentRegistered >= capacity) {
          return {
            'success': false,
            'status': 'full',
            'message': 'Capacity is full.',
          };
        }

        final userSnapshot = await transaction.get(registrantsRef);
        if (userSnapshot.exists) {
          return {
            'success': false,
            'status': 'already_registered',
            'message': 'You are already registered.',
          };
        }

        transaction.update(hotelInfoRef, {'registered': currentRegistered + 1});

        final registrantData = {
          'userId': userInfo['userId'],
          'userName': userInfo['kullaniciAdi'] ?? userInfo['userName'] ?? '',
          'userEmail': userInfo['email'] ?? '',
          'roomNumber': userInfo['odaNo'] ?? userInfo['roomNumber'] ?? '',
          'eventId': eventId,
          'eventTitle':
              eventDetails['eventTitle'] ?? eventDetails['title'] ?? '',
          'eventDate': eventDetails['eventDate'] ?? eventDetails['date'],
          'hotelName': hotelName,
          'timestamp': FieldValue.serverTimestamp(),
        };

        transaction.set(registrantsRef, registrantData);

        return {
          'success': true,
          'status': 'success',
          'message': 'Registration successful.',
        };
      });
    } catch (e) {
      Logger.error("Registration Error: $e");
      return {'success': false, 'message': 'An error occurred: $e'};
    }
  }

  // --- KULLANICIYA AİT TÜM ETKİNLİK KAYITLARINI GETİR (Otel Bazlı) ---
  Stream<List<Map<String, dynamic>>> getUserEvents(
    String userId, {
    String? hotelName,
  }) async* {
    if (hotelName == null || hotelName.isEmpty) {
      yield [];
      return;
    }

    final eventsSnapshot = await db
        .collection('hotels')
        .doc(hotelName)
        .collection('events')
        .get();

    if (eventsSnapshot.docs.isEmpty) {
      yield [];
      return;
    }

    List<Map<String, dynamic>> allRegistrations = [];

    for (var eventDoc in eventsSnapshot.docs) {
      final registrantDoc = await eventDoc.reference
          .collection('registrants')
          .doc(userId)
          .get();

      if (registrantDoc.exists && registrantDoc.data() != null) {
        final eventData = eventDoc.data();
        final registrationData = registrantDoc.data()!;

        final mergedData = <String, dynamic>{
          ...eventData,
          ...registrationData,
          'eventId': eventDoc.id,
          'eventDate': eventData['date'],
        };

        allRegistrations.add(mergedData);
      }
    }

    yield allRegistrations;
  }

  // 3. İlgi alanlarına göre yeni etkinlikleri dinle
  Stream<QuerySnapshot> listenForInterestEvents(
    String hotelName,
    List<String> interests,
  ) {
    if (interests.isEmpty) return const Stream.empty();

    return db
        .collection('hotels')
        .doc(hotelName)
        .collection('events')
        .where('category', whereIn: interests)
        .snapshots();
  }
}
