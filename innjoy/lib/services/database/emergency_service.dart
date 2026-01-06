import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:login_page/services/database/base_database_service.dart';

/// EmergencyService - Emergency alerts management.
class EmergencyService extends BaseDatabaseService {
  // Singleton pattern
  static final EmergencyService _instance = EmergencyService._internal();
  factory EmergencyService() => _instance;
  EmergencyService._internal();

  /// Send emergency alert to Firestore
  Future<void> sendEmergencyAlert({
    required String emergencyType,
    required String roomNumber,
    required String locationContext,
  }) async {
    try {
      await db.collection('emergency_alerts').add({
        'type': emergencyType,
        'room_number': roomNumber,
        'user_uid': auth.currentUser?.uid,
        'timestamp': Timestamp.now(), // Client-side timestamp for immediate availability
        'status': 'active',
        'location_context': locationContext,
      });
    } catch (e) {
      throw Exception("Failed to send notification: $e");
    }
  }
}
