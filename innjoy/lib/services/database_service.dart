import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../models/menu_item_model.dart';
import 'dart:math';
import 'package:login_page/services/logger_service.dart';

/// DatabaseService - Singleton pattern ile uygulanan veritabanı servisi.
/// Her `DatabaseService()` çağrısı aynı instance'ı döndürür,
/// böylece gereksiz nesne oluşumu ve memory leak önlenir.
class DatabaseService {
  // Singleton instance
  static final DatabaseService _instance = DatabaseService._internal();

  factory DatabaseService() => _instance;

  DatabaseService._internal();

  // Firebase instances
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // --- IMAGE UPLOAD ---

  Future<String> uploadMenuItemImage(
    File file,
    String hotelName,
    String restaurantId,
  ) async {
    // Check if it's room service or restaurant for path
    String pathSegment = 'restaurants/$restaurantId';
    if (restaurantId == 'room_service') {
      pathSegment = 'room_service';
    }

    final String fileName =
        '${DateTime.now().millisecondsSinceEpoch}_${file.uri.pathSegments.last}';
    final ref = _storage.ref().child(
      'hotels/$hotelName/$pathSegment/menu_images/$fileName',
    );

    final uploadTask = ref.putFile(file);
    final snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }

  Future<String> uploadEventImage(File file, String hotelName) async {
    final String fileName =
        '${DateTime.now().millisecondsSinceEpoch}_${file.uri.pathSegments.last}';
    final ref = _storage.ref().child(
      'hotels/$hotelName/events/event_images/$fileName',
    );

    final uploadTask = ref.putFile(file);
    final snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }

  // --- RESTAURANT MENU MANAGEMENT ---

  // NOTE: Legacy getMenuItems() method removed.
  // Use getRoomServiceMenu(hotelName) or getRestaurantMenu(hotelName, restaurantId) instead.

  // --- NEW ROOM SERVICE SPECIFIC METHODS ---
  // Structure: hotels/{hotelName}/room_service/main/menu/{itemId}

  Stream<List<MenuItem>> getRoomServiceMenu(String hotelName) {
    return _db
        .collection('hotels')
        .doc(hotelName)
        .collection('room_service')
        .doc('menu')
        .collection('items')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return MenuItem.fromMap(doc.data(), doc.id);
          }).toList();
        });
  }

  Future<void> addRoomServiceMenuItem(String hotelName, MenuItem item) async {
    final collectionRef = _db
        .collection('hotels')
        .doc(hotelName)
        .collection('room_service')
        .doc('menu')
        .collection('items');

    if (item.id.isNotEmpty) {
      await collectionRef.doc(item.id).set(item.toMap());
    } else {
      await collectionRef.add(item.toMap());
    }
  }

  Future<void> updateRoomServiceMenuItem(
    String hotelName,
    String itemId,
    MenuItem item,
  ) async {
    await _db
        .collection('hotels')
        .doc(hotelName)
        .collection('room_service')
        .doc('menu')
        .collection('items')
        .doc(itemId)
        .update(item.toMap());
  }

  Future<void> deleteRoomServiceMenuItem(
    String hotelName,
    String itemId,
  ) async {
    await _db
        .collection('hotels')
        .doc(hotelName)
        .collection('room_service')
        .doc('menu')
        .collection('items')
        .doc(itemId)
        .delete();
  }

  // --- OTEL LİSTESİNİ GETİR ---
  Stream<List<Map<String, dynamic>>> getHotels() {
    return _db.collection('hotels').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        var data = doc.data();
        data['id'] =
            doc.id; // Document ID'yi (Örn: L2Nw...) 'id' olarak ekliyoruz
        return data;
      }).toList();
    });
  }

  // Create or Update Hotel Document (Fix for missing docs)
  Future<void> createHotel(String hotelName, Map<String, dynamic> data) async {
    await _db
        .collection('hotels')
        .doc(hotelName)
        .set(data, SetOptions(merge: true));
  }

  /// Get hotel WiFi information from 'hotel information' subcollection
  Stream<Map<String, dynamic>?> getHotelWifiInfo(String hotelName) {
    return _db
        .collection('hotels')
        .doc(hotelName)
        .collection('hotel information')
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isNotEmpty) {
            final doc = snapshot.docs.first;
            if (doc.data().containsKey('wifi')) {
              return doc.data()['wifi'] as Map<String, dynamic>;
            }
          }
          return null;
        });
  }

  /// Update hotel WiFi information in 'hotel information' subcollection
  Future<void> updateHotelWifiInfo(
    String hotelName,
    String ssid,
    String password,
  ) async {
    final encryption = 'WPA';
    // Generate QR data string to save as well
    final qrData = 'WIFI:S:$ssid;T:$encryption;P:$password;;';

    final snapshot = await _db
        .collection('hotels')
        .doc(hotelName)
        .collection('hotel information')
        .limit(1)
        .get();
    
    DocumentReference ref;
    if (snapshot.docs.isNotEmpty) {
      ref = snapshot.docs.first.reference;
    } else {
      // Create new doc if missing (auto-generated ID)
      ref = _db
          .collection('hotels')
          .doc(hotelName)
          .collection('hotel information')
          .doc();
    }

    await ref.set({
      'wifi': {
        'ssid': ssid,
        'password': password,
        'encryption': encryption,
        'qrData': qrData,
      }
    }, SetOptions(merge: true));
  }

  // RESTORE: Recover parent doc from 'hotel information' subcollection
  Future<bool> restoreHotelFromSubcollection(String hotelName) async {
    try {
      final snapshot = await _db
          .collection('hotels')
          .doc(hotelName)
          .collection('hotel information')
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final data = snapshot.docs.first.data();
        // Veriyi parent dokümana yaz
        await _db
            .collection('hotels')
            .doc(hotelName)
            .set(data, SetOptions(merge: true));
        return true;
      }
    } catch (e) {
      Logger.error("Restore Error: $e");
    }
    return false;
  }

  // YENİ: Otelin restoranlarını getir
  // Not: Restoran belgesi boş olabilir (sadece subcollection'lar var)
  // Bu durumda settings/general'dan veriyi çekiyoruz
  Stream<List<Map<String, dynamic>>> getRestaurants(String hotelName) {
    Logger.debug('DEBUG: getRestaurants called with hotelName: $hotelName');
    return _db
        .collection('hotels')
        .doc(hotelName)
        .collection('restaurants')
        .snapshots()
        .asyncMap((snapshot) async {
          Logger.debug('DEBUG: Got ${snapshot.docs.length} restaurant docs');
          List<Map<String, dynamic>> restaurants = [];

          for (var doc in snapshot.docs) {
            final originalData = doc.data();
            Logger.debug(
              'DEBUG: Restaurant doc ${doc.id}, data empty: ${originalData.isEmpty}',
            );
            Map<String, dynamic> data;

            // Eğer belge boşsa, settings/general'dan veriyi çek
            if (originalData.isEmpty) {
              Logger.debug('DEBUG: Fetching settings/general for ${doc.id}');
              try {
                final settingsDoc = await doc.reference
                    .collection('settings')
                    .doc('general')
                    .get();

                Logger.debug(
                  'DEBUG: Settings doc exists: ${settingsDoc.exists}',
                );
                if (settingsDoc.exists && settingsDoc.data() != null) {
                  data = {...settingsDoc.data()!, 'id': doc.id};
                  Logger.debug('DEBUG: Got settings data: $data');
                } else {
                  // Settings de yoksa, en azından id ve name olarak doc.id kullan
                  data = {'id': doc.id, 'name': doc.id};
                  Logger.debug('DEBUG: Using fallback data: $data');
                }
              } catch (e) {
                Logger.debug('DEBUG: Error fetching settings: $e');
                data = {'id': doc.id, 'name': doc.id};
              }
            } else {
              data = {...originalData, 'id': doc.id};
              Logger.debug('DEBUG: Using original data: $data');
            }

            restaurants.add(data);
          }

          Logger.debug('DEBUG: Returning ${restaurants.length} restaurants');
          return restaurants;
        });
  }

  // 1. Get Menu Items for a specific Restaurant in a Hotel
  Stream<List<MenuItem>> getRestaurantMenu(
    String hotelName,
    String restaurantId,
  ) {
    if (restaurantId == 'room_service') {
      return getRoomServiceMenu(hotelName);
    }
    return _db
        .collection('hotels')
        .doc(hotelName)
        .collection('restaurants')
        .doc(restaurantId)
        .collection('menu')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return MenuItem.fromMap(doc.data(), doc.id);
          }).toList();
        });
  }

  // 2. Add Menu Item
  Future<void> addMenuItem(
    String hotelName,
    String restaurantId,
    MenuItem item,
  ) async {
    if (restaurantId == 'room_service') {
      await addRoomServiceMenuItem(hotelName, item);
      return;
    }

    final collectionRef = _db
        .collection('hotels')
        .doc(hotelName)
        .collection('restaurants')
        .doc(restaurantId)
        .collection('menu');

    if (item.id.isNotEmpty) {
      await collectionRef.doc(item.id).set(item.toMap());
    } else {
      await collectionRef.add(item.toMap());
    }
  }

  // 3. Update Menu Item
  Future<void> updateMenuItem(
    String hotelName,
    String restaurantId,
    String itemId,
    MenuItem item,
  ) async {
    if (restaurantId == 'room_service') {
      await updateRoomServiceMenuItem(hotelName, itemId, item);
      return;
    }
    await _db
        .collection('hotels')
        .doc(hotelName)
        .collection('restaurants')
        .doc(restaurantId)
        .collection('menu')
        .doc(itemId)
        .update(item.toMap());
  }

  // 4. Delete Menu Item
  Future<void> deleteMenuItem(
    String hotelName,
    String restaurantId,
    String itemId,
  ) async {
    if (restaurantId == 'room_service') {
      await deleteRoomServiceMenuItem(hotelName, itemId);
      return;
    }
    await _db
        .collection('hotels')
        .doc(hotelName)
        .collection('restaurants')
        .doc(restaurantId)
        .collection('menu')
        .doc(itemId)
        .delete();
  }

  // --- RESTAURANT AYARLARI (BAŞLIK, AÇIKLAMA, RESİM) ---
  Stream<Map<String, dynamic>?> getRestaurantSettings(
    String hotelName,
    String restaurantId,
  ) {
    return _db
        .collection('hotels')
        .doc(hotelName)
        .collection('restaurants')
        .doc(restaurantId)
        .collection('settings')
        .doc(
          'general',
        ) // User asked for 'settings' folder, typically implies a subcollection. Let's use 'settings/general' doc for single config.
        .snapshots()
        .map((doc) => doc.data());
  }

  // --- SPA & FITNESS INFO ---
  Stream<Map<String, dynamic>?> getSpaInfo(String hotelName) {
    return _db
        .collection('hotels')
        .doc(hotelName)
        .collection('spa_wellness')
        .doc('information')
        .snapshots()
        .map((doc) => doc.data());
  }

  Stream<Map<String, dynamic>?> getFitnessInfo(String hotelName) {
    return _db
        .collection('hotels')
        .doc(hotelName)
        .collection('fitness')
        .doc('information')
        .snapshots()
        .map((doc) => doc.data());
  }

  // --- SEEDING (DEFAULT DATA CREATION) ---
  Future<void> seedDefaultServices(String hotelName) async {
    // 1. Check & Seed Restaurant
    // 'Aurora Restaurant' is the key
    final restRef = _db
        .collection('hotels')
        .doc(hotelName)
        .collection('restaurants')
        .doc('Aurora Restaurant')
        .collection('settings')
        .doc('general');

    final restSnap = await restRef.get();
    if (!restSnap.exists) {
      await restRef.set({
        'name': 'Aurora Restaurant',
        'description':
            'Fine dining with a panoramic city view, featuring a modern European menu.',
        'imageUrl': 'assets/images/rest.png',
        'tableCount': 20,
      });
    }

    // 2. Check & Seed Spa
    final spaRef = _db
        .collection('hotels')
        .doc(hotelName)
        .collection('spa_wellness')
        .doc('information');

    final spaSnap = await spaRef.get();
    if (!spaSnap.exists) {
      await spaRef.set({
        'title': 'Serenity Spa',
        'description':
            'Indulge in our signature treatments and find your inner peace.',
        'imageUrl': 'assets/images/spa_service.png',
      });
    }

    // 3. Check & Seed Fitness with detailed structure
    final fitnessRef = _db
        .collection('hotels')
        .doc(hotelName)
        .collection('fitness')
        .doc('information');

    final fitnessSnap = await fitnessRef.get();
    if (!fitnessSnap.exists) {
      await fitnessRef.set({
        'title': '24/7 Fitness Center',
        'description':
            'Stay fit during your stay with our state-of-the-art fitness center. Fully equipped with modern cardio and strength training equipment, our gym is available to all hotel guests around the clock.',
        'imageUrl': 'assets/images/fitness.png',
        'operatingHours': {
          'schedule': 'Monday - Sunday',
          'hours': '24 Hours',
          'staffAvailable': '06:00 - 22:00',
        },
        'equipment': [
          {'icon': 'directions_run', 'name': 'Treadmills'},
          {'icon': 'pedal_bike', 'name': 'Exercise Bikes'},
          {'icon': 'fitness_center', 'name': 'Free Weights'},
          {'icon': 'accessibility_new', 'name': 'Weight Machines'},
          {'icon': 'self_improvement', 'name': 'Yoga Mats'},
          {'icon': 'water_drop', 'name': 'Water Station'},
          {'icon': 'tv', 'name': 'Entertainment'},
          {'icon': 'air', 'name': 'Air Conditioning'},
        ],
        'gallery': [
          'https://images.unsplash.com/photo-1571902943202-507ec2618e8f?w=400',
          'https://images.unsplash.com/photo-1558611848-73f7eb4001a1?w=400',
          'https://images.unsplash.com/photo-1540497077202-7c8a3999166f?w=400',
        ],
        'location': {
          'floor': 'Ground Floor',
          'description': 'Next to the Pool Area',
        },
        'accessInfo':
            'Use your room key to access the fitness center at any time.',
      });
    }
  }

  Future<void> updateRestaurantSettings(
    String hotelName,
    String restaurantId,
    Map<String, dynamic> data,
  ) async {
    await _db
        .collection('hotels')
        .doc(hotelName)
        .collection('restaurants')
        .doc(restaurantId)
        .collection('settings')
        .doc('general')
        .set(data, SetOptions(merge: true));
  }

  // --- SİPARİŞ VERME ---
  Future<void> placeRoomServiceOrder(
    String hotelName,
    String roomNumber,
    String guestName,
    List<Map<String, dynamic>> items,
    double totalPrice,
  ) async {
    User? user = _auth.currentUser;
    if (user != null) {
      final timestamp = FieldValue.serverTimestamp();

      // 1. Save to Hotel's Room Service Orders collection
      // Path: hotels/{hotelName}/room_service/orders/{orderId}
      // This ensures data is isolated per hotel.
      await _db
          .collection('hotels')
          .doc(hotelName)
          .collection('room_service')
          .doc('orders')
          .collection('items') // Dedicated collection for this hotel's orders
          .add({
            'hotelName': hotelName,
            'roomNumber': roomNumber,
            'guestName': guestName,
            'items': items,
            'totalPrice': totalPrice,
            'status': 'Active', // Active or Completed
            'timestamp': timestamp,
            'userId': user.uid,
            'type': 'room_service',
          });

      // 2. Add to User's Reservation Expenses (For Spending Tracker)
      try {
        Logger.debug(
          "DEBUG placeRoomServiceOrder: Starting balance update for user ${user.uid}",
        );
        Logger.debug(
          "DEBUG placeRoomServiceOrder: hotelName = $hotelName, roomNumber = $roomNumber, totalPrice = $totalPrice",
        );

        // A. Check if user is admin (skip balance update if so)
        final userDoc = await _db.collection('users').doc(user.uid).get();
        final role = userDoc.data()?['role'];
        Logger.debug("DEBUG placeRoomServiceOrder: User role = $role");

        if (role == 'admin') {
          Logger.debug(
            "DEBUG placeRoomServiceOrder: User is admin, skipping balance update",
          );
          return;
        }

        // B. Find Active Reservation
        // Method 1: Try by usedBy field
        Logger.debug(
          "DEBUG placeRoomServiceOrder: Searching for reservation with usedBy=${user.uid}, status=used",
        );
        var query = await _db
            .collection('hotels')
            .doc(hotelName)
            .collection('reservations')
            .where('usedBy', isEqualTo: user.uid)
            .where('status', isEqualTo: 'used')
            .limit(1)
            .get();

        Logger.debug(
          "DEBUG placeRoomServiceOrder: usedBy query returned ${query.docs.length} documents",
        );

        DocumentReference? reservationRef;

        if (query.docs.isNotEmpty) {
          reservationRef = query.docs.first.reference;
          Logger.debug(
            "DEBUG placeRoomServiceOrder: Found reservation by usedBy: ${reservationRef.path}",
          );
        } else {
          // Method 2: Fallback - Try by roomNumber (doc ID)
          Logger.debug(
            "DEBUG placeRoomServiceOrder: Fallback - trying roomNumber as doc ID: $roomNumber",
          );
          final roomDoc = await _db
              .collection('hotels')
              .doc(hotelName)
              .collection('reservations')
              .doc(roomNumber)
              .get();

          if (roomDoc.exists) {
            final roomData = roomDoc.data();
            // Verify this reservation belongs to current user or is status='used'
            if (roomData != null && roomData['status'] == 'used') {
              reservationRef = roomDoc.reference;
              Logger.debug(
                "DEBUG placeRoomServiceOrder: Found reservation by roomNumber: ${reservationRef.path}",
              );
            } else {
              Logger.debug(
                "DEBUG placeRoomServiceOrder: Room doc exists but status is not 'used': ${roomData?['status']}",
              );
            }
          } else {
            Logger.debug(
              "DEBUG placeRoomServiceOrder: No reservation found by roomNumber either",
            );
          }
        }

        if (reservationRef != null) {
          final expenseItem = {
            'title': 'Room Service',
            'date':
                Timestamp.now(), // Use Timestamp.now() instead of FieldValue.serverTimestamp() for arrayUnion
            'amount': totalPrice,
            'category': 'room_service',
            'items': items.map((e) => e['name']).join(', '),
          };

          await reservationRef.update({
            'expenses': FieldValue.arrayUnion([expenseItem]),
            'currentBalance': FieldValue.increment(totalPrice),
          });
          Logger.debug("DEBUG placeRoomServiceOrder: Balance update SUCCESS!");
        } else {
          Logger.debug(
            "DEBUG placeRoomServiceOrder: NO RESERVATION FOUND - balance not updated",
          );
        }
      } catch (e) {
        Logger.error("Error updating balance: $e");
        // Fail silently or handle? Order is placed effectively, just balance failed.
      }
    }
  }

  // --- HARCAMA TAKİBİ (SPENDINGS) ---
  // Gets spending data by looking up user's current reservation
  Stream<Map<String, dynamic>?> getMySpending(String hotelName) {
    User? user = _auth.currentUser;
    if (user == null) return Stream.value(null);

    // First get user's roomNumber, then listen to that reservation
    return _db.collection('users').doc(user.uid).snapshots().asyncExpand((
      userSnapshot,
    ) {
      final userData = userSnapshot.data();
      final roomNumber = userData?['roomNumber'];
      final userHotelName = userData?['hotelName'];

      // User must have roomNumber and be in the correct hotel
      if (roomNumber == null || userHotelName != hotelName) {
        Logger.debug(
          "DEBUG getMySpending: No roomNumber ($roomNumber) or hotel mismatch ($userHotelName vs $hotelName)",
        );
        return Stream.value(null);
      }

      Logger.debug(
        "DEBUG getMySpending: Listening to reservation for room $roomNumber",
      );

      // Listen to the reservation document directly by roomNumber
      return _db
          .collection('hotels')
          .doc(hotelName)
          .collection('reservations')
          .doc(roomNumber)
          .snapshots()
          .map((snapshot) {
            if (snapshot.exists) {
              final data = snapshot.data();
              Logger.debug(
                "DEBUG getMySpending: Got reservation data, currentBalance = ${data?['currentBalance']}",
              );
              return data;
            }
            Logger.debug(
              "DEBUG getMySpending: Reservation document doesn't exist",
            );
            return null;
          });
    });
  }

  // NOTE: Legacy getTotalSpending() method removed.
  // Use getMySpending(hotelName) to get reservation spending data.

  // NOTE: Legacy getOrderHistory() method removed.
  // Use hotel-specific path: hotels/{hotelName}/room_service/orders/items

  // --- HOUSEKEEPING (TEMİZLİK/BAKIM) İSTEĞİ GÖNDER ---
  Future<void> requestHousekeeping(String requestType, String note) async {
    User? user = _auth.currentUser;
    if (user == null) return;

    // Get user data to fetch hotel name, room number, and guest name
    final userData = await getUserData(user.uid);
    if (userData == null) return;

    final hotelName = userData['hotelName'];
    final roomNumber = userData['roomNumber'];
    final guestName = userData['name_username'] ?? 'Guest';

    if (hotelName == null || roomNumber == null) return;

    await _db
        .collection('hotels')
        .doc(hotelName)
        .collection('housekeeping_requests')
        .add({
          'userId': user.uid,
          'roomNumber': roomNumber,
          'guestName': guestName,
          'hotelName': hotelName,
          'requestType': requestType, // 'Housekeeping'
          'details': note, // Full request details
          'status': 'Active', // Active or Completed
          'timestamp': FieldValue.serverTimestamp(),
        });
  }

  // NOTE: Legacy getHousekeepingHistory() method removed.
  // Use getHotelHousekeepingRequests(hotelName) for admin access or
  // getMyHousekeepingRequests(hotelName) for customer access.

  // --- OTEL BAZLI HOUSEKEEPING İSTEKLERİNİ GETİR (ADMİN İÇİN) ---
  Stream<List<Map<String, dynamic>>> getHotelHousekeepingRequests(
    String hotelName,
  ) {
    return _db
        .collection('hotels')
        .doc(hotelName)
        .collection('housekeeping_requests')
        .where(
          'status',
          isNotEqualTo: 'archived',
        ) // Arşivlenmişleri gösterme
        .snapshots()
        .map((snapshot) {
          final requests = snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id; // Document ID'yi ekle
            return data;
          }).toList();
          // Timestamp'e göre sırala (descending)
          requests.sort((a, b) {
            final aTime = a['timestamp'] as Timestamp?;
            final bTime = b['timestamp'] as Timestamp?;
            if (aTime == null || bTime == null) return 0;
            return bTime.compareTo(aTime);
          });
          return requests;
        });
  }

  // --- ODA İÇİN HOUSEKEEPING İSTEKLERİNİ ARŞİVLE (CHECK-OUT) ---
  Future<void> archiveHousekeepingRequestsForRoom(
    String hotelName,
    String roomNumber,
  ) async {
    final snapshot = await _db
        .collection('hotels')
        .doc(hotelName)
        .collection('housekeeping_requests')
        .where('roomNumber', isEqualTo: roomNumber)
        .where('status', isNotEqualTo: 'archived')
        .get();

    // Tüm bekleyen/aktif istekleri arşivle
    final batch = _db.batch();
    for (final doc in snapshot.docs) {
      batch.update(doc.reference, {
        'status': 'archived',
        'archivedAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }

  // NOTE: Legacy getEvents() method removed.\n  // Use getHotelEvents(hotelName) for hotel-specific events.

  // --- OTEL ÖZELİNDE ETKİNLİK İŞLEMLERİ ---

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
    return _db
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

          // Tarihe göre sırala
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

    final eventRef = _db
        .collection('hotels')
        .doc(hotelName)
        .collection('events')
        .doc(eventFolderId);

    // Ana event dokümanı - SORGULAMA İÇİN GEREKLİ ALANLAR BURAYA
    await eventRef.set({
      'createdAt': FieldValue.serverTimestamp(),
      'eventName': eventData['title'],
      'category': eventData['category'], // SORGULAMA İÇİN ŞART
      'date': eventData['date'],
      'isPublished': eventData['isPublished'] ?? true,
    });

    // hotel_information/details - etkinlik bilgileri
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
    final eventRef = _db
        .collection('hotels')
        .doc(hotelName)
        .collection('events')
        .doc(eventId);

    // Ana dokümanı güncelle (Sorgu verileri)
    await eventRef.update({
      if (eventData.containsKey('title')) 'eventName': eventData['title'],
      if (eventData.containsKey('category')) 'category': eventData['category'],
      if (eventData.containsKey('date')) 'date': eventData['date'],
      if (eventData.containsKey('isPublished'))
        'isPublished': eventData['isPublished'],
    });

    // Detayları güncelle
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
    return _db
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
    final eventRef = _db
        .collection('hotels')
        .doc(hotelName)
        .collection('events')
        .doc(eventId);

    // hotel_information koleksiyonunu sil
    final hotelInfoDocs = await eventRef.collection('hotel_information').get();
    for (var doc in hotelInfoDocs.docs) {
      await doc.reference.delete();
    }

    // registrants koleksiyonunu sil
    final registrantsDocs = await eventRef.collection('registrants').get();
    for (var doc in registrantsDocs.docs) {
      await doc.reference.delete();
    }

    // Ana dokümanı sil
    await eventRef.delete();
  }

  // NOTE: Legacy joinEvent() method removed.
  // Use registerForEvent(hotelName, eventId, userInfo, eventDetails) instead.
  // It correctly uses hotels/{hotelName}/events/{eventId}/registrants path.

  // 1. Yeni Rezervasyon Oluştur (Admin) - Oda numarasına göre kayıt
  Future<String> createReservation(
    String hotelName,
    String roomNumber,
    String guestName,
    DateTime checkInDate,
    DateTime checkOutDate,
  ) async {
    // 6 Haneli Rastgele PNR Üret (check-in kodu olarak)
    String pnr = _generateRandomPnr();

    // QR Kod verisi oluştur (benzersiz tanımlayıcı)
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final qrCodeData = 'INNJOY:$hotelName:$roomNumber:$pnr:$timestamp';

    final reservation = {
      'pnr': pnr, // Check-in için kullanılacak kod
      'roomNumber': roomNumber,
      'guestName': guestName,
      'checkInDate': Timestamp.fromDate(checkInDate),
      'checkOutDate': Timestamp.fromDate(checkOutDate),
      'status': 'active',
      'currentBalance': 0, // Bakiye sıfırdan başlar
      'expenses': [], // Harcamalar boş liste
      'qrCodeData': qrCodeData, // QR Kod verisi
      'createdAt': FieldValue.serverTimestamp(),
    };

    // hotels/{hotelName}/reservations/{roomNumber} yoluna kaydet
    await _db
        .collection('hotels')
        .doc(hotelName)
        .collection('reservations')
        .doc(roomNumber) // Oda numarası doc ID olarak
        .set(reservation);

    return pnr; // PNR'ı döndür (kullanıcıya verilecek)
  }

  // 2. PNR Listesini Getir (Admin - Kendi Oteli)
  Stream<List<Map<String, dynamic>>> getHotelReservations(String hotelName) {
    return _db
        .collection('hotels')
        .doc(hotelName)
        .collection('reservations')
        .orderBy('checkOutDate') // En yakın çıkış tarihine göre sırala
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) => doc.data()).toList();
        });
  }

  // 2.1 Otel Bilgilerini Getir (Doluluk vb.)
  // Güncelleme: Kullanıcı 'hotel information' alt koleksiyonu kullanıyor.
  Stream<Map<String, dynamic>?> getHotelInfo(String hotelName) {
    return _db
        .collection('hotels')
        .doc(hotelName)
        .collection('hotel information')
        .limit(1)
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isNotEmpty) {
            return snapshot.docs.first.data();
          }
          return null;
        });
  }

  // 3. PNR Doğrula ve Kullan (Müşteri) - PNR ile oda bul ve check-in yap
  Future<bool> verifyAndRedeemPnr(
    String pnr,
    String selectedHotel,
    String userId,
  ) async {
    try {
      // PNR'a göre rezervasyonu ara (artık PNR bir alan)
      final querySnapshot = await _db
          .collection('hotels')
          .doc(selectedHotel)
          .collection('reservations')
          .where('pnr', isEqualTo: pnr)
          .where('status', isEqualTo: 'active')
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) return false;

      final docRef = querySnapshot.docs.first.reference;
      final data = querySnapshot.docs.first.data();

      // PNR Geçerli -> Kullanıldı olarak işaretle
      final email = _auth.currentUser?.email;
      String? linkedUserName;

      // Kullanıcının ismini çekelim
      try {
        final userDoc = await _db.collection('users').doc(userId).get();
        if (userDoc.exists && userDoc.data() != null) {
          linkedUserName = userDoc.data()!['name_username'];
        }
      } catch (e) {
        Logger.error("Error fetching user name: $e");
      }

      await docRef.update({
        'status': 'used',
        'usedBy': userId,
        'guestEmail': email,
        'claimedGuestName': linkedUserName, // Gerçek kullanıcı adı
        'currentBalance': 0, // Bakiye sıfırdan başlar
        'expenses': [], // Harcamalar boş liste olarak başlar
      });

      // Kullanıcının profiline otel bilgisini ve TARİHLERİ kaydet
      final checkIn = data['checkInDate'];
      final checkOut = data['checkOutDate'];

      await _db.collection('users').doc(userId).update({
        'hotelName': selectedHotel,
        'roomNumber': data['roomNumber'],
        'checkInDate': checkIn ?? FieldValue.serverTimestamp(),
        'checkOutDate': checkOut,
        'checkedInAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      Logger.error("PNR Verify Error: $e");
      return false;
    }
  }

  // 4. Update Reservation Status & Clean User (roomNumber ile)
  Future<void> updateReservationStatus(
    String hotelName,
    String roomNumber, // Artık roomNumber kullanıyoruz
    String status,
  ) async {
    final resRef = _db
        .collection('hotels')
        .doc(hotelName)
        .collection('reservations')
        .doc(roomNumber); // roomNumber doc ID olarak

    // Eger 'past' (Geçmiş) yapıyorsak, kullanıcının profilinden de oteli silelim
    // ve housekeeping isteklerini arşivle
    if (status == 'past') {
      final doc = await resRef.get();
      if (doc.exists) {
        final data = doc.data();
        final userId = data?['usedBy'];

        // Housekeeping isteklerini arşivle
        await archiveHousekeepingRequestsForRoom(hotelName, roomNumber);

        if (userId != null) {
          // Kullanıcıyı otelden çıkar
          await _db.collection('users').doc(userId).update({
            'hotelName': FieldValue.delete(),
            'roomNumber': FieldValue.delete(),
            'checkInDate': FieldValue.delete(),
            'checkOutDate': FieldValue.delete(),
            'checkedInAt': FieldValue.delete(),
          });
        }
      }
    }

    await resRef.update({'status': status});
  }

  // 5. Delete Reservation (roomNumber ile)
  Future<void> deleteReservation(String hotelName, String roomNumber) async {
    await _db
        .collection('hotels')
        .doc(hotelName)
        .collection('reservations')
        .doc(roomNumber) // roomNumber doc ID olarak
        .delete();
  }

  // Yardımcı: Rastgele 6 haneli kod üretici (Örn: XK92M4)
  String _generateRandomPnr() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return List.generate(
      6,
      (index) => chars[random.nextInt(chars.length)],
    ).join();
  }

  // --- KULLANICI ROLÜNÜ GETİR (DEBUG MODU) ---
  // --- KULLANICI VERİSİNİ GETİR (ROL VE OTEL ADI İÇİN) ---
  // --- KULLANICI VERİSİNİ GETİR (TEK SEFERLİK) ---
  Future<Map<String, dynamic>?> getUserData(String userId) async {
    try {
      DocumentSnapshot doc = await _db.collection('users').doc(userId).get();

      if (doc.exists && doc.data() != null) {
        return doc.data() as Map<String, dynamic>;
      } else {
        Logger.debug("❌ ERROR: User not found in database!");
        return null;
      }
    } catch (e) {
      Logger.debug("🔥 CRITICAL ERROR: $e");
      return null;
    }
  }

  // --- KULLANICI VERİSİNİ DİNLE (CANLI AKIŞ) ---
  Stream<Map<String, dynamic>?> getUserStream(String userId) {
    return _db.collection('users').doc(userId).snapshots().map((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        return snapshot.data() as Map<String, dynamic>;
      }
      return null;
    });
  }

  // --- KULLANICI KAYDET (Senin Değişken İsimlerine Göre) ---
  Future<void> saveUserdata(
    String uid,
    String email,
    String name, {
    String role = 'customer',
  }) async {
    await _db.collection('users').doc(uid).set({
      'email': email, // auth.dart ile tutarlı
      'name_username': name,
      'role': role,
      'uid': uid,
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // --- RESTAURANT RESERVATION SYSTEM ---

  // 1. Make a Reservation (Customer) with Automatic Table Assignment
  Future<Map<String, dynamic>> makeReservation(
    String hotelName,
    String restaurantId,
    String restaurantName,
    DateTime date,
    int partySize,
    String note,
  ) async {
    // Normalize date to YYYY-MM-DD for simpler querying (ignoring specific time for checking *daily* slots if needed,
    // but here we are doing a fixed 20:00 slot per day).
    // Ensuring we compare 'bookings for this day'.
    final startDate = DateTime(date.year, date.month, date.day);
    final endDate = startDate.add(const Duration(days: 1));

    try {
      return await _db.runTransaction((transaction) async {
        // A. Get Total Tables
        final settingsRef = _db
            .collection('hotels')
            .doc(hotelName)
            .collection('restaurants')
            .doc(restaurantId)
            .collection('settings')
            .doc('general');

        final settingsSnap = await transaction.get(settingsRef);
        int totalTables = 20;
        if (settingsSnap.exists) {
          totalTables = settingsSnap.data()?['tableCount'] ?? 20;
        }

        // B. Get Existing Reservations for that Date
        final reservationsRef = _db
            .collection('hotels')
            .doc(hotelName)
            .collection('restaurants')
            .doc(restaurantId)
            .collection('reservations');

        final querySnapshot = await reservationsRef
            .where(
              'date',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
            )
            .where('date', isLessThan: Timestamp.fromDate(endDate))
            .get();

        List<int> occupiedTables = [];
        for (var doc in querySnapshot.docs) {
          if (doc.data()['status'] != 'cancelled') {
            occupiedTables.add(doc.data()['tableNumber']);
          }
        }

        // C. Find First Available Table
        int assignedTable = -1;
        for (int i = 1; i <= totalTables; i++) {
          if (!occupiedTables.contains(i)) {
            assignedTable = i;
            break;
          }
        }

        if (assignedTable == -1) {
          return {
            'success': false,
            'message': 'No tables available for this date.',
          };
        }

        // D. Create Reservation
        final user = _auth.currentUser;
        if (user == null) {
          return {'success': false, 'message': 'User not logged in.'};
        }

        final newReservationRef = reservationsRef.doc(); // Auto ID

        transaction.set(newReservationRef, {
          'id': newReservationRef.id,
          'userId': user.uid,
          'userName': user.displayName ?? 'Guest',
          'hotelName': hotelName,
          'restaurantId': restaurantId,
          'restaurantName': restaurantName,
          'date': Timestamp.fromDate(date),
          'partySize': partySize,
          'tableNumber': assignedTable,
          'note': note,
          'status': 'confirmed',
          'createdAt': FieldValue.serverTimestamp(),
        });

        return {
          'success': true,
          'message': 'Reservation confirmed! Table $assignedTable assigned.',
          'tableNumber': assignedTable,
        };
      });
    } catch (e) {
      Logger.error("Reservation Error: $e");
      return {'success': false, 'message': 'Failed to make reservation: $e'};
    }
  }

  // --- KULLANICIYA AİT TÜM REZERVASYONLARI GETİR (Otel Bazlı - Index gerektirmez) ---
  Stream<List<Map<String, dynamic>>> getUserReservations(
    String userId, {
    String? hotelName,
  }) {
    if (hotelName == null || hotelName.isEmpty) {
      return Stream.value([]);
    }

    // collectionGroup kullanarak tüm 'reservations' koleksiyonlarını tarar.
    // userId ve hotelName'e göre filtreleme yapar.
    // NOT: Bu sorgu Firebase Console'da bir Index oluşturmanızı gerektirebilir.
    // Konsolda çıkan linke tıklayarak oluşturun.
    return _db
        .collectionGroup('reservations')
        .where('userId', isEqualTo: userId)
        .where('hotelName', isEqualTo: hotelName)
        .orderBy('date', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  // --- KULLANICIYA AİT TÜM ETKİNLİK KAYITLARINI GETİR (Otel Bazlı) ---
  // --- KULLANICIYA AİT TÜM ETKİNLİK KAYITLARINI GETİR (Otel Bazlı) ---
  Stream<List<Map<String, dynamic>>> getUserEvents(
    String userId, {
    String? hotelName,
  }) async* {
    if (hotelName == null || hotelName.isEmpty) {
      yield [];
      return;
    }

    // Tüm etkinliklerin ID'lerini al
    final eventsSnapshot = await _db
        .collection('hotels')
        .doc(hotelName)
        .collection('events')
        .get();

    if (eventsSnapshot.docs.isEmpty) {
      yield [];
      return;
    }

    // Her etkinliğin registrants'ına bak ve kullanıcıyı ara
    List<Map<String, dynamic>> allRegistrations = [];

    for (var eventDoc in eventsSnapshot.docs) {
      final registrantDoc = await eventDoc.reference
          .collection('registrants')
          .doc(userId)
          .get();

      if (registrantDoc.exists && registrantDoc.data() != null) {
        // Event detaylarını (resim, lokasyon, saat) ve kayıt detaylarını (tarih) birleştir
        final eventData = eventDoc.data();
        final registrationData = registrantDoc.data()!;

        // Çakışmaları önlemek ve veriyi zenginleştirmek için birleştirme
        final mergedData = <String, dynamic>{
          ...eventData, // Event'ten gelen title, location, time, imageAsset
          ...registrationData, // Registrant'tan gelen timestamp
          'eventId': eventDoc.id,
          // Tarih karmaşasını önlemek için:
          // Eğer registrationData'da 'date' yoksa veya eventData'daki 'date' (gerçek etkinlik tarihi) gerekiyorsa
          // Genellikle takvimde etkinliğin olduğu gün gösterilmeli
          'eventDate': eventData['date'],
        };

        allRegistrations.add(mergedData);
      }
    }

    yield allRegistrations;
  }

  // --- KULLANICIYA AİT TÜM SPA RANDEVULARINI GETİR (Otel Bazlı) ---
  Stream<List<Map<String, dynamic>>> getUserSpaAppointments(
    String userId, {
    String? hotelName,
  }) {
    if (hotelName == null || hotelName.isEmpty) {
      return Stream.value([]);
    }

    return _db
        .collection('hotels')
        .doc(hotelName)
        .collection('spa_wellness')
        .doc('reservations')
        .collection('appointments')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return data;
          }).toList();
        });
  }

  // 2. Get Reservations (Admin)
  Stream<List<Map<String, dynamic>>> getRestaurantReservations(
    String hotelName,
    String restaurantId,
  ) {
    return _db
        .collection('hotels')
        .doc(hotelName)
        .collection('restaurants')
        .doc(restaurantId)
        .collection('reservations')
        .orderBy('date', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  // ETKİNLİK KAYIT
  Future<Map<String, dynamic>> registerForEvent(
    String hotelName,
    String eventId,
    Map<String, dynamic> userInfo,
    Map<String, dynamic> eventDetails,
  ) async {
    final eventRef = _db
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

      return await _db.runTransaction((transaction) async {
        // Etkinlik bilgilerini al
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

        // Kullanıcı zaten kayıtlı mı kontrol et
        final userSnapshot = await transaction.get(registrantsRef);
        if (userSnapshot.exists) {
          return {
            'success': false,
            'status': 'already_registered',
            'message': 'You are already registered.',
          };
        }

        // Kayıt sayısını güncelle
        transaction.update(hotelInfoRef, {'registered': currentRegistered + 1});

        // Kullanıcıyı kaydet
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

  // --- USER MANGEMENT ---
  Future<Map<String, dynamic>?> getUser(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      Logger.error("Error fetching user: $e");
      return null;
    }
  }

  // --- SPA RANDEVU OLUŞTURMA ---
  Future<void> bookSpaAppointment({
    required String serviceName,
    required String duration,
    required double price,
    required DateTime appointmentDate,
    required String timeSlot,
    required String paymentMethod, // 'room_charge', 'pay_at_spa'
  }) async {
    User? user = _auth.currentUser;
    if (user == null) throw Exception("User is not logged in.");

    // 1. Kullanıcı Bilgilerini ve Otelini Çek
    final userDoc = await _db.collection('users').doc(user.uid).get();
    if (!userDoc.exists) throw Exception("User profile not found.");

    final userData = userDoc.data()!;
    final String hotelName = userData['hotelName'] ?? '';

    if (hotelName.isEmpty) throw Exception("Hotel information not found.");

    // 2. Aktif Rezervasyonu Bul ve Ücreti Yansıt (SADECE ODA HESABI İSE)
    if (paymentMethod == 'room_charge' && price > 0) {
      final roomNumber = userData['roomNumber'];

      // Method 1: Try by usedBy field
      var reservationQuery = await _db
          .collection('hotels')
          .doc(hotelName)
          .collection('reservations')
          .where('usedBy', isEqualTo: user.uid)
          .where('status', isEqualTo: 'used')
          .limit(1)
          .get();

      DocumentReference? reservationRef;

      if (reservationQuery.docs.isNotEmpty) {
        reservationRef = reservationQuery.docs.first.reference;
      } else if (roomNumber != null) {
        // Method 2: Fallback - Try by roomNumber (doc ID)
        final roomDoc = await _db
            .collection('hotels')
            .doc(hotelName)
            .collection('reservations')
            .doc(roomNumber)
            .get();

        if (roomDoc.exists && roomDoc.data()?['status'] == 'used') {
          reservationRef = roomDoc.reference;
        }
      }

      if (reservationRef != null) {
        final expenseItem = {
          'title': serviceName,
          'date':
              Timestamp.now(), // Use Timestamp.now() instead of FieldValue.serverTimestamp() for arrayUnion
          'amount': price,
          'category': 'spa_wellness',
          'items': 'Spa Appointment - $duration',
        };

        await reservationRef.update({
          'expenses': FieldValue.arrayUnion([expenseItem]),
          'currentBalance': FieldValue.increment(price),
        });
      } else {
        // Eğer aktif rezervasyon yoksa
        throw Exception(
          "No active hotel reservation found, cannot charge to room.",
        );
      }
    }

    // 3. Randevuyu spa_wellness/reservations alt koleksiyonuna kaydet
    await _db
        .collection('hotels')
        .doc(hotelName)
        .collection('spa_wellness')
        .doc('reservations')
        .collection('appointments')
        .add({
          'serviceName': serviceName,
          'duration': duration, // "60 min" string olarak geliyor
          'price': price,
          'appointmentDate': Timestamp.fromDate(appointmentDate),
          'timeSlot': timeSlot,
          'guestName': userData['name_username'] ?? 'Guest',
          'guestEmail': userData['email'] ?? userData['mailAddress'] ?? '',
          'roomNumber': userData['roomNumber'] ?? 'Unknown',
          'userId': user.uid,
          'hotelName': hotelName,
          'createdAt': FieldValue.serverTimestamp(),
          'status': 'pending', // pending, confirmed, completed, cancelled
          'paymentStatus': paymentMethod == 'room_charge'
              ? 'charged_to_room'
              : 'pay_at_spa',
          'paymentMethod': paymentMethod,
        });
  }

  // --- MÜSAİTLİK KONTROLÜ İÇİN ---
  Stream<List<String>> getSpaBookedSlots(String hotelName, DateTime date) {
    // Seçilen günün başlangıcı ve bitişi
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return _db
        .collection('hotels')
        .doc(hotelName)
        .collection('spa_wellness')
        .doc('reservations')
        .collection('appointments')
        .where(
          'appointmentDate',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
        )
        .where('appointmentDate', isLessThan: Timestamp.fromDate(endOfDay))
        .where(
          'status',
          isNotEqualTo: 'cancelled',
        ) // İptal edilenler uygun sayılır
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => doc.data()['timeSlot'] as String)
              .toList();
        });
  }

  // --- SPA RANDEVULARINI GETİR (ADMIN) ---
  Stream<List<Map<String, dynamic>>> getSpaReservations(String hotelName) {
    return _db
        .collection('hotels')
        .doc(hotelName)
        .collection('spa_wellness')
        .doc('reservations')
        .collection('appointments')
        .orderBy('appointmentDate', descending: true) // Yeni randevular üstte
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return data;
          }).toList();
        });
  }

  // --- SPA RANDEVU DURUMU GÜNCELLE (ADMIN) ---
  Future<void> updateSpaReservationStatus(
    String hotelName,
    String reservationId,
    String status,
  ) async {
    await _db
        .collection('hotels')
        .doc(hotelName)
        .collection('spa_wellness')
        .doc('reservations')
        .collection('appointments')
        .doc(reservationId)
        .update({'status': status});
  }

  // --- SPA MENÜ YÖNETİMİ (ADMIN) ---

  // 1. Spa Hizmeti Ekle
  Future<void> addSpaService(
    String hotelName,
    Map<String, dynamic> serviceData,
  ) async {
    // Ensure 'type' field is set
    serviceData['type'] = 'service';
    
    // Use service name as document ID
    final serviceName = serviceData['name'] ?? 'Unknown Service';
    await _db
        .collection('hotels')
        .doc(hotelName)
        .collection('spa_wellness')
        .doc('services')
        .collection('items')
        .doc(serviceName)
        .set(serviceData);
  }

  // 2. Spa Hizmeti Güncelle
  Future<void> updateSpaService(
    String hotelName,
    String docId,
    Map<String, dynamic> serviceData,
  ) async {
    await _db
        .collection('hotels')
        .doc(hotelName)
        .collection('spa_wellness')
        .doc('services')
        .collection('items')
        .doc(docId)
        .update(serviceData);
  }

  // 3. Spa Hizmeti Sil
  Future<void> deleteSpaService(String hotelName, String docId) async {
    await _db
        .collection('hotels')
        .doc(hotelName)
        .collection('spa_wellness')
        .doc('services')
        .collection('items')
        .doc(docId)
        .delete();
  }

  // 4. Spa Menüsünü Getir (Stream)
  Stream<List<Map<String, dynamic>>> getSpaMenu(String hotelName) {
    return _db
        .collection('hotels')
        .doc(hotelName)
        .collection('spa_wellness')
        .doc('services')
        .collection('items')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return data;
          }).toList();
        });
  }

  // ONE-TIME SEEDING: Add default spa services in English
  Future<void> migrateSpaServicesToNewStructure(String hotelName) async {
    try {
      Logger.debug('Checking spa services seeding for $hotelName');

      // Check if seeding already completed
      final migrationDoc = await _db
          .collection('hotels')
          .doc(hotelName)
          .collection('spa_wellness')
          .doc('migration_status')
          .get();

      if (migrationDoc.exists && migrationDoc.data()?['completed'] == true) {
        Logger.debug('Seeding already completed, skipping');
        return;
      }

      // Check if there are existing services
      final existingServices = await _db
          .collection('hotels')
          .doc(hotelName)
          .collection('spa_wellness')
          .doc('services')
          .collection('items')
          .get();

      if (existingServices.docs.isNotEmpty) {
        Logger.debug('Services already exist (${existingServices.docs.length}), skipping seeding');
        // Still mark as completed to avoid checking again
        await _db
            .collection('hotels')
            .doc(hotelName)
            .collection('spa_wellness')
            .doc('migration_status')
            .set({
              'completed': true,
              'timestamp': FieldValue.serverTimestamp(),
              'servicesSeeded': 0,
              'note': 'Services already existed',
            });
        return;
      }

      Logger.debug('No services found, seeding default English services');

      // Default spa services in English
      final defaultServices = [
        {
          'name': 'Aromatherapy',
          'description': 'Sensory therapy with essential natural oils.',
          'duration': 60,
          'price': 1500,
          'imageUrl': 'https://images.unsplash.com/photo-1540555700478-4be289fbecef?q=80&w=1000&auto=format&fit=crop',
          'type': 'service',
        },
        {
          'name': 'Skin Care',
          'description': 'Professional skin cleansing and care.',
          'duration': 45,
          'price': 850,
          'imageUrl': 'https://images.unsplash.com/photo-1570172619644-dfd03ed5d881?q=80&w=1000&auto=format&fit=crop',
          'type': 'service',
        },
        {
          'name': 'Massage Therapy',
          'description': 'Relaxing and rejuvenating massage therapy.',
          'duration': 60,
          'price': 1200,
          'imageUrl': 'https://images.unsplash.com/photo-1544161515-4ab6ce6db874?q=80&w=1000&auto=format&fit=crop',
          'type': 'service',
        },
        {
          'name': 'Sauna & Steam',
          'description': 'Relaxation in sauna and steam rooms.',
          'duration': 30,
          'price': 500,
          'imageUrl': 'https://images.unsplash.com/photo-1596178060671-7a80dc8059ea?w=1000&auto=format&fit=crop',
          'type': 'service',
        },
      ];

      // Add each service using service name as document ID
      for (final serviceData in defaultServices) {
        final serviceName = serviceData['name'] as String;
        await _db
            .collection('hotels')
            .doc(hotelName)
            .collection('spa_wellness')
            .doc('services')
            .collection('items')
            .doc(serviceName)
            .set(serviceData);

        Logger.debug('Seeded service: $serviceName');
      }

      // Mark seeding as completed
      await _db
          .collection('hotels')
          .doc(hotelName)
          .collection('spa_wellness')
          .doc('migration_status')
          .set({
            'completed': true,
            'timestamp': FieldValue.serverTimestamp(),
            'servicesSeeded': defaultServices.length,
          });

      Logger.debug('Spa services seeding completed successfully');
    } catch (e) {
      Logger.error('Error during spa services seeding: $e');
      rethrow;
    }
  }

  // --- ODA YÖNETİMİ ---
  // Tüm odaları çek (İsimlerini ve DND durumlarını görmek için)
  Stream<List<Map<String, dynamic>>> getRooms(String hotelName) {
    return _db
        .collection('hotels')
        .doc(hotelName)
        .collection('rooms')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return data;
          }).toList();
        });
  }

  // --- MÜŞTERİ İSTEKLERİ (CUSTOMER REQUESTS) ---

  // Get ALL room service orders (Admin)
  Stream<List<Map<String, dynamic>>> getAllRoomServiceOrders(String hotelName) {
    return _db
        .collection('hotels')
        .doc(hotelName)
        .collection('room_service')
        .doc('orders')
        .collection('items')
        .snapshots()
        .map((snapshot) {
          final orders = snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return data;
          }).toList();
          // Sort by timestamp descending
          orders.sort((a, b) {
            final aTime = a['timestamp'] as Timestamp?;
            final bTime = b['timestamp'] as Timestamp?;
            if (aTime == null || bTime == null) return 0;
            return bTime.compareTo(aTime);
          });
          return orders;
        });
  }

  // Get current user's room service orders
  Stream<List<Map<String, dynamic>>> getMyRoomServiceOrders(String hotelName) {
    User? user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _db
        .collection('hotels')
        .doc(hotelName)
        .collection('room_service')
        .doc('orders')
        .collection('items')
        .where('userId', isEqualTo: user.uid)
        .snapshots()
        .map((snapshot) {
          final orders = snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return data;
          }).toList();
          // Sort by timestamp descending
          orders.sort((a, b) {
            final aTime = a['timestamp'] as Timestamp?;
            final bTime = b['timestamp'] as Timestamp?;
            if (aTime == null || bTime == null) return 0;
            return bTime.compareTo(aTime);
          });
          return orders;
        });
  }

  // Get current user's housekeeping requests
  Stream<List<Map<String, dynamic>>> getMyHousekeepingRequests(
    String hotelName,
  ) {
    User? user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _db
        .collection('hotels')
        .doc(hotelName)
        .collection('housekeeping_requests')
        .where('userId', isEqualTo: user.uid)
        .where('status', isNotEqualTo: 'archived')
        .snapshots()
        .map((snapshot) {
          final requests = snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return data;
          }).toList();
          // Sort by timestamp descending
          requests.sort((a, b) {
            final aTime = a['timestamp'] as Timestamp?;
            final bTime = b['timestamp'] as Timestamp?;
            if (aTime == null || bTime == null) return 0;
            return bTime.compareTo(aTime);
          });
          return requests;
        });
  }

  // ===================== EMERGENCY METHODS =====================

  /// Get current user's room number for emergency situations
  Future<String> getUserRoomNumber() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return "Unknown";

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        return doc.data()?['roomNumber'] ?? "Unknown";
      }
    } catch (e) {
      Logger.debug("getUserRoomNumber Error: $e");
    }
    return "Unknown";
  }

  /// Send emergency alert to Firestore
  Future<void> sendEmergencyAlert({
    required String emergencyType,
    required String roomNumber,
    required String locationContext,
  }) async {
    try {
      await _db.collection('emergency_alerts').add({
        'type': emergencyType,
        'room_number': roomNumber,
        'user_uid': _auth.currentUser?.uid,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'active',
        'location_context': locationContext,
      });
    } catch (e) {
      throw Exception("Failed to send notification: $e");
    }
  }

  // Oda verilerini dinleyen Stream (UI'daki StreamBuilder için)
  Stream<DocumentSnapshot> getRoomStream(String documentId) {
    return _db.collection('rooms').doc(documentId).snapshots();
  }

  // --- BİLDİRİM TERCİHLERİ ---

  // 1. Kullanıcının seçtiği ilgi alanlarını getir
  Future<List<String>> getUserInterests() async {
    User? user = _auth.currentUser;
    if (user == null) return [];

    try {
      DocumentSnapshot doc = await _db.collection('users').doc(user.uid).get();
      if (doc.exists && doc.data() != null) {
        var data = doc.data() as Map<String, dynamic>;
        if (data.containsKey('interests')) {
          return List<String>.from(data['interests']);
        }
      }
      return [];
    } catch (e) {
      Logger.debug("İlgi alanları çekilemedi: $e");
      return [];
    }
  }

  // 2. Kullanıcının ilgi alanlarını güncelle
  Future<void> updateUserInterests(List<String> interests) async {
    User? user = _auth.currentUser;
    if (user != null) {
      await _db.collection('users').doc(user.uid).set({
        'interests': interests,
      }, SetOptions(merge: true));
    }
  }

  // 3. İlgi alanlarına göre yeni etkinlikleri dinle
  Stream<QuerySnapshot> listenForInterestEvents(
    String hotelName,
    List<String> interests,
  ) {
    // Sadece şu andan sonra eklenen/güncellenen etkinlikleri dinle
    // Not: 'createdAt' veya benzeri bir zaman damgası etkinliklerde olmalı.
    // Şimdilik sadece dinleyici ekliyoruz, client tarafında filtreleme yapacağız.
    // Firestore whereIn sorgusu ile sadece ilgili kategorileri dinle

    if (interests.isEmpty) return const Stream.empty();

    return _db
        .collection('hotels')
        .doc(hotelName)
        .collection('events')
        .where('category', whereIn: interests)
        // .where('createdAt', isGreaterThan: Timestamp.now()) // Eğer etkinliklerde createdAt varsa bunu açın
        .snapshots();
  }
}
