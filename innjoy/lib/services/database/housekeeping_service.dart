import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:login_page/services/database/base_database_service.dart';
import 'package:login_page/services/database/user_data_service.dart';
import 'package:login_page/services/logger_service.dart';

/// HousekeepingService - Cleaning requests management.
class HousekeepingService extends BaseDatabaseService {
  // Singleton pattern
  static final HousekeepingService _instance = HousekeepingService._internal();
  factory HousekeepingService() => _instance;
  HousekeepingService._internal();

  final _userDataService = UserDataService();

  // --- HOUSEKEEPING (TEMİZLİK/BAKIM) İSTEĞİ GÖNDER ---
  Future<void> requestHousekeeping(String requestType, String note) async {
    final user = auth.currentUser;
    if (user == null) {
      Logger.debug('requestHousekeeping: No user logged in');
      return;
    }

    final userData = await _userDataService.getUserData(user.uid);
    if (userData == null) {
      Logger.debug('requestHousekeeping: No user data found');
      return;
    }

    final hotelName = userData['hotelName'];
    final roomNumber = userData['roomNumber'];
    final guestName = userData['name_username'] ?? 'Guest';

    if (hotelName == null || roomNumber == null) {
      Logger.debug('requestHousekeeping: Missing hotelName or roomNumber');
      return;
    }

    Logger.debug(
      'requestHousekeeping: Creating request for user ${user.uid} at hotel $hotelName room $roomNumber',
    );

    await db
        .collection('hotels')
        .doc(hotelName)
        .collection('housekeeping_requests')
        .add({
          'userId': user.uid,
          'roomNumber': roomNumber,
          'guestName': guestName,
          'hotelName': hotelName,
          'requestType': requestType,
          'details': note,
          'status': 'Active',
          'timestamp': FieldValue.serverTimestamp(),
        });

    Logger.debug('requestHousekeeping: Request created successfully');
  }

  // --- OTEL BAZLI HOUSEKEEPING İSTEKLERİNİ GETİR (ADMİN İÇİN) ---
  Stream<List<Map<String, dynamic>>> getHotelHousekeepingRequests(
    String hotelName,
  ) {
    return db
        .collection('hotels')
        .doc(hotelName)
        .collection('housekeeping_requests')
        .where('status', isNotEqualTo: 'archived')
        .snapshots()
        .map((snapshot) {
          final requests = snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return data;
          }).toList();
          requests.sort((a, b) {
            final aTime = a['timestamp'] as Timestamp?;
            final bTime = b['timestamp'] as Timestamp?;
            if (aTime == null || bTime == null) return 0;
            return bTime.compareTo(aTime);
          });
          return requests;
        });
  }

  // Get current user's housekeeping requests
  Stream<List<Map<String, dynamic>>> getMyHousekeepingRequests(
    String hotelName,
  ) {
    final user = auth.currentUser;
    if (user == null) {
      Logger.debug('getMyHousekeepingRequests: No user logged in');
      return Stream.value([]);
    }

    Logger.debug(
      'getMyHousekeepingRequests: Fetching for user ${user.uid} at hotel $hotelName',
    );

    return db
        .collection('hotels')
        .doc(hotelName)
        .collection('housekeeping_requests')
        .where('userId', isEqualTo: user.uid)
        .snapshots()
        .map((snapshot) {
          Logger.debug(
            'getMyHousekeepingRequests: Found ${snapshot.docs.length} total documents',
          );

          final requests = snapshot.docs
              .map((doc) {
                final data = doc.data();
                data['id'] = doc.id;
                return data;
              })
              .where((data) {
                // Client-side filter for non-archived requests
                final status = data['status']?.toString().toLowerCase() ?? '';
                return status != 'archived';
              })
              .toList();

          Logger.debug(
            'getMyHousekeepingRequests: After filtering, ${requests.length} non-archived requests',
          );

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
    final snapshot = await db
        .collection('hotels')
        .doc(hotelName)
        .collection('housekeeping_requests')
        .where('roomNumber', isEqualTo: roomNumber)
        .where('status', isNotEqualTo: 'archived')
        .get();

    final batch = db.batch();
    for (final doc in snapshot.docs) {
      batch.update(doc.reference, {
        'status': 'archived',
        'archivedAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }
}
