import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:login_page/services/database/base_database_service.dart';
import 'package:login_page/services/database/housekeeping_service.dart';
import 'package:login_page/services/logger_service.dart';
import 'dart:math';

/// ReservationService - Room reservations, PNR management.
class ReservationService extends BaseDatabaseService {
  // Singleton pattern
  static final ReservationService _instance = ReservationService._internal();
  factory ReservationService() => _instance;
  ReservationService._internal();

  final _housekeepingService = HousekeepingService();

  // Yardımcı: Rastgele 6 haneli kod üretici
  String _generateRandomPnr() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return List.generate(
      6,
      (index) => chars[random.nextInt(chars.length)],
    ).join();
  }

  // 1. Yeni Rezervasyon Oluştur (Admin) - Oda numarasına göre kayıt
  Future<String> createReservation(
    String hotelName,
    String roomNumber,
    String guestName,
    DateTime checkInDate,
    DateTime checkOutDate,
  ) async {
    String pnr = _generateRandomPnr();

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final qrCodeData = 'INNJOY:$hotelName:$roomNumber:$pnr:$timestamp';

    final reservation = {
      'pnr': pnr,
      'roomNumber': roomNumber,
      'guestName': guestName,
      'checkInDate': Timestamp.fromDate(checkInDate),
      'checkOutDate': Timestamp.fromDate(checkOutDate),
      'status': 'active',
      'currentBalance': 0,
      'expenses': [],
      'qrCodeData': qrCodeData,
      'createdAt': FieldValue.serverTimestamp(),
    };

    await db
        .collection('hotels')
        .doc(hotelName)
        .collection('reservations')
        .doc(roomNumber)
        .set(reservation);

    return pnr;
  }

  // 2. PNR Listesini Getir (Admin - Kendi Oteli)
  Stream<List<Map<String, dynamic>>> getHotelReservations(String hotelName) {
    return db
        .collection('hotels')
        .doc(hotelName)
        .collection('reservations')
        .orderBy('checkOutDate')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) => doc.data()).toList();
        });
  }

  // 3. PNR Doğrula ve Kullan (Müşteri) - PNR ile oda bul ve check-in yap
  Future<bool> verifyAndRedeemPnr(
    String pnr,
    String selectedHotel,
    String userId,
  ) async {
    try {
      final querySnapshot = await db
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

      final email = auth.currentUser?.email;
      String? linkedUserName;

      try {
        final userDoc = await db.collection('users').doc(userId).get();
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
        'claimedGuestName': linkedUserName,
        'currentBalance': 0,
        'expenses': [],
      });

      final checkIn = data['checkInDate'];
      final checkOut = data['checkOutDate'];

      await db.collection('users').doc(userId).update({
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
    String roomNumber,
    String status,
  ) async {
    final resRef = db
        .collection('hotels')
        .doc(hotelName)
        .collection('reservations')
        .doc(roomNumber);

    if (status == 'past') {
      final doc = await resRef.get();
      if (doc.exists) {
        final data = doc.data();
        final userId = data?['usedBy'];

        await _housekeepingService.archiveHousekeepingRequestsForRoom(
          hotelName,
          roomNumber,
        );

        if (userId != null) {
          await db.collection('users').doc(userId).update({
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
    await db
        .collection('hotels')
        .doc(hotelName)
        .collection('reservations')
        .doc(roomNumber)
        .delete();
  }
}
