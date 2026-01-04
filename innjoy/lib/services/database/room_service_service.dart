import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:login_page/services/database/base_database_service.dart';
import 'package:login_page/services/logger_service.dart';
import '../../models/menu_item_model.dart';

/// RoomServiceService - Room service orders, menu, and spending tracker.
class RoomServiceService extends BaseDatabaseService {
  // Singleton pattern
  static final RoomServiceService _instance = RoomServiceService._internal();
  factory RoomServiceService() => _instance;
  RoomServiceService._internal();

  // --- ROOM SERVICE MENU METHODS ---
  Stream<List<MenuItem>> getRoomServiceMenu(String hotelName) {
    return db
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
    final collectionRef = db
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
    await db
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
    await db
        .collection('hotels')
        .doc(hotelName)
        .collection('room_service')
        .doc('menu')
        .collection('items')
        .doc(itemId)
        .delete();
  }

  // --- SİPARİŞ VERME ---
  Future<void> placeRoomServiceOrder(
    String hotelName,
    String roomNumber,
    String guestName,
    List<Map<String, dynamic>> items,
    double totalPrice,
  ) async {
    final user = auth.currentUser;
    if (user != null) {
      final timestamp = FieldValue.serverTimestamp();

      await db
          .collection('hotels')
          .doc(hotelName)
          .collection('room_service')
          .doc('orders')
          .collection('items')
          .add({
            'hotelName': hotelName,
            'roomNumber': roomNumber,
            'guestName': guestName,
            'items': items,
            'totalPrice': totalPrice,
            'status': 'Active',
            'timestamp': timestamp,
            'userId': user.uid,
            'type': 'room_service',
          });

      // Add to User's Reservation Expenses
      try {
        Logger.debug(
          "DEBUG placeRoomServiceOrder: Starting balance update for user ${user.uid}",
        );

        // Check if user is admin
        final userDoc = await db.collection('users').doc(user.uid).get();
        final role = userDoc.data()?['role'];

        if (role == 'admin') {
          Logger.debug(
            "DEBUG placeRoomServiceOrder: User is admin, skipping balance update",
          );
          return;
        }

        // Find Active Reservation
        var query = await db
            .collection('hotels')
            .doc(hotelName)
            .collection('reservations')
            .where('usedBy', isEqualTo: user.uid)
            .where('status', isEqualTo: 'used')
            .limit(1)
            .get();

        DocumentReference? reservationRef;

        if (query.docs.isNotEmpty) {
          reservationRef = query.docs.first.reference;
        } else {
          final roomDoc = await db
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
            'title': 'Room Service',
            'date': Timestamp.now(),
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
      }
    }
  }

  // --- HARCAMA TAKİBİ (SPENDINGS) ---
  Stream<Map<String, dynamic>?> getMySpending(String hotelName) {
    final user = auth.currentUser;
    if (user == null) return Stream.value(null);

    return db.collection('users').doc(user.uid).snapshots().asyncExpand((
      userSnapshot,
    ) {
      final userData = userSnapshot.data();
      final roomNumber = userData?['roomNumber'];
      final userHotelName = userData?['hotelName'];

      if (roomNumber == null || userHotelName != hotelName) {
        Logger.debug(
          "DEBUG getMySpending: No roomNumber ($roomNumber) or hotel mismatch ($userHotelName vs $hotelName)",
        );
        return Stream.value(null);
      }

      Logger.debug(
        "DEBUG getMySpending: Listening to reservation for room $roomNumber",
      );

      return db
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

  // Get ALL room service orders (Admin)
  Stream<List<Map<String, dynamic>>> getAllRoomServiceOrders(String hotelName) {
    return db
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
    final user = auth.currentUser;
    if (user == null) {
      Logger.debug('getMyRoomServiceOrders: No user logged in');
      return Stream.value([]);
    }

    Logger.debug(
      'getMyRoomServiceOrders: Fetching orders for user ${user.uid} at hotel $hotelName',
    );

    return db
        .collection('hotels')
        .doc(hotelName)
        .collection('room_service')
        .doc('orders')
        .collection('items')
        .where('userId', isEqualTo: user.uid)
        .snapshots()
        .map((snapshot) {
          Logger.debug(
            'getMyRoomServiceOrders: Found ${snapshot.docs.length} orders',
          );
          final orders = snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return data;
          }).toList();
          orders.sort((a, b) {
            final aTime = a['timestamp'] as Timestamp?;
            final bTime = b['timestamp'] as Timestamp?;
            if (aTime == null || bTime == null) return 0;
            return bTime.compareTo(aTime);
          });
          return orders;
        });
  }

  // --- ODA YÖNETİMİ ---
  Stream<List<Map<String, dynamic>>> getRooms(String hotelName) {
    return db
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

  Stream<DocumentSnapshot> getRoomStream(String documentId) {
    return db.collection('rooms').doc(documentId).snapshots();
  }
}
