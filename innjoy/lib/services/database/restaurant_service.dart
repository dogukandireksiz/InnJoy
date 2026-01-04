import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:login_page/services/database/base_database_service.dart';
import 'package:login_page/services/database/room_service_service.dart';
import 'package:login_page/services/logger_service.dart';
import '../../models/menu_item_model.dart';

/// RestaurantService - Menus, reservations, and restaurant settings.
class RestaurantService extends BaseDatabaseService {
  // Singleton pattern
  static final RestaurantService _instance = RestaurantService._internal();
  factory RestaurantService() => _instance;
  RestaurantService._internal();

  final _roomServiceService = RoomServiceService();

  // YENİ: Otelin restoranlarını getir
  Stream<List<Map<String, dynamic>>> getRestaurants(String hotelName) {
    Logger.debug('DEBUG: getRestaurants called with hotelName: $hotelName');
    return db
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

  // Get Menu Items for a specific Restaurant in a Hotel
  Stream<List<MenuItem>> getRestaurantMenu(
    String hotelName,
    String restaurantId,
  ) {
    if (restaurantId == 'room_service') {
      return _roomServiceService.getRoomServiceMenu(hotelName);
    }
    return db
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

  // Add Menu Item
  Future<void> addMenuItem(
    String hotelName,
    String restaurantId,
    MenuItem item,
  ) async {
    if (restaurantId == 'room_service') {
      await _roomServiceService.addRoomServiceMenuItem(hotelName, item);
      return;
    }

    final collectionRef = db
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

  // Update Menu Item
  Future<void> updateMenuItem(
    String hotelName,
    String restaurantId,
    String itemId,
    MenuItem item,
  ) async {
    if (restaurantId == 'room_service') {
      await _roomServiceService.updateRoomServiceMenuItem(
        hotelName,
        itemId,
        item,
      );
      return;
    }
    await db
        .collection('hotels')
        .doc(hotelName)
        .collection('restaurants')
        .doc(restaurantId)
        .collection('menu')
        .doc(itemId)
        .update(item.toMap());
  }

  // Delete Menu Item
  Future<void> deleteMenuItem(
    String hotelName,
    String restaurantId,
    String itemId,
  ) async {
    if (restaurantId == 'room_service') {
      await _roomServiceService.deleteRoomServiceMenuItem(hotelName, itemId);
      return;
    }
    await db
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
    return db
        .collection('hotels')
        .doc(hotelName)
        .collection('restaurants')
        .doc(restaurantId)
        .collection('settings')
        .doc('general')
        .snapshots()
        .map((doc) => doc.data());
  }

  Future<void> updateRestaurantSettings(
    String hotelName,
    String restaurantId,
    Map<String, dynamic> data,
  ) async {
    await db
        .collection('hotels')
        .doc(hotelName)
        .collection('restaurants')
        .doc(restaurantId)
        .collection('settings')
        .doc('general')
        .set(data, SetOptions(merge: true));
  }

  // --- RESTAURANT RESERVATION SYSTEM ---

  // Make a Reservation (Customer) with Automatic Table Assignment
  Future<Map<String, dynamic>> makeReservation(
    String hotelName,
    String restaurantId,
    String restaurantName,
    DateTime date,
    int partySize,
    String note,
  ) async {
    final startDate = DateTime(date.year, date.month, date.day);
    final endDate = startDate.add(const Duration(days: 1));

    try {
      return await db.runTransaction((transaction) async {
        // A. Get Total Tables
        final settingsRef = db
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
        final reservationsRef = db
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
        final user = auth.currentUser;
        if (user == null) {
          return {'success': false, 'message': 'User not logged in.'};
        }

        final newReservationRef = reservationsRef.doc();

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

  // --- KULLANICIYA AİT TÜM REZERVASYONLARI GETİR ---
  Stream<List<Map<String, dynamic>>> getUserReservations(
    String userId, {
    String? hotelName,
  }) {
    if (hotelName == null || hotelName.isEmpty) {
      return Stream.value([]);
    }

    return db
        .collectionGroup('reservations')
        .where('userId', isEqualTo: userId)
        .where('hotelName', isEqualTo: hotelName)
        .orderBy('date', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  // Get Reservations (Admin)
  Stream<List<Map<String, dynamic>>> getRestaurantReservations(
    String hotelName,
    String restaurantId,
  ) {
    return db
        .collection('hotels')
        .doc(hotelName)
        .collection('restaurants')
        .doc(restaurantId)
        .collection('reservations')
        .orderBy('date', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }
}
