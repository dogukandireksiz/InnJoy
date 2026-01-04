import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:login_page/services/database/base_database_service.dart';
import 'package:login_page/services/logger_service.dart';

/// UserDataService - User profiles, preferences, and interests management.
class UserDataService extends BaseDatabaseService {
  // Singleton pattern
  static final UserDataService _instance = UserDataService._internal();
  factory UserDataService() => _instance;
  UserDataService._internal();

  // --- KULLANICI VERİSİNİ GETİR (TEK SEFERLİK) ---
  Future<Map<String, dynamic>?> getUserData(String userId) async {
    try {
      DocumentSnapshot doc = await db.collection('users').doc(userId).get();

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
    return db.collection('users').doc(userId).snapshots().map((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        return snapshot.data() as Map<String, dynamic>;
      }
      return null;
    });
  }

  // --- KULLANICI KAYDET ---
  Future<void> saveUserdata(
    String uid,
    String email,
    String name, {
    String role = 'customer',
  }) async {
    await db.collection('users').doc(uid).set({
      'email': email,
      'name_username': name,
      'role': role,
      'uid': uid,
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // --- USER MANGEMENT ---
  Future<Map<String, dynamic>?> getUser(String uid) async {
    try {
      final doc = await db.collection('users').doc(uid).get();
      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      Logger.error("Error fetching user: $e");
      return null;
    }
  }

  // --- BİLDİRİM TERCİHLERİ ---

  // 1. Kullanıcının seçtiği ilgi alanlarını getir
  Future<List<String>> getUserInterests() async {
    final user = auth.currentUser;
    if (user == null) return [];

    try {
      DocumentSnapshot doc = await db.collection('users').doc(user.uid).get();
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
    final user = auth.currentUser;
    if (user != null) {
      await db.collection('users').doc(user.uid).set({
        'interests': interests,
      }, SetOptions(merge: true));
    }
  }

  /// Get current user's room number for emergency situations
  Future<String> getUserRoomNumber() async {
    final user = auth.currentUser;
    if (user == null) return "Unknown";

    try {
      final doc = await db.collection('users').doc(user.uid).get();

      if (doc.exists) {
        return doc.data()?['roomNumber'] ?? "Unknown";
      }
    } catch (e) {
      Logger.debug("getUserRoomNumber Error: $e");
    }
    return "Unknown";
  }
}
