import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:login_page/services/database/base_database_service.dart';
import 'package:login_page/services/logger_service.dart';

/// HotelService - Hotel CRUD, WiFi info, and seeding operations.
class HotelService extends BaseDatabaseService {
  // Singleton pattern
  static final HotelService _instance = HotelService._internal();
  factory HotelService() => _instance;
  HotelService._internal();

  // --- OTEL LİSTESİNİ GETİR ---
  Stream<List<Map<String, dynamic>>> getHotels() {
    return db.collection('hotels').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        var data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }

  // Create or Update Hotel Document
  Future<void> createHotel(String hotelName, Map<String, dynamic> data) async {
    await db
        .collection('hotels')
        .doc(hotelName)
        .set(data, SetOptions(merge: true));
  }

  /// Get hotel WiFi information from 'hotel information' subcollection
  Stream<Map<String, dynamic>?> getHotelWifiInfo(String hotelName) {
    return db
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
    const encryption = 'WPA';
    final qrData = 'WIFI:S:$ssid;T:$encryption;P:$password;;';

    final snapshot = await db
        .collection('hotels')
        .doc(hotelName)
        .collection('hotel information')
        .limit(1)
        .get();

    DocumentReference ref;
    if (snapshot.docs.isNotEmpty) {
      ref = snapshot.docs.first.reference;
    } else {
      ref = db
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
      },
    }, SetOptions(merge: true));
  }

  // RESTORE: Recover parent doc from 'hotel information' subcollection
  Future<bool> restoreHotelFromSubcollection(String hotelName) async {
    try {
      final snapshot = await db
          .collection('hotels')
          .doc(hotelName)
          .collection('hotel information')
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final data = snapshot.docs.first.data();
        await db
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

  // Get hotel information
  Stream<Map<String, dynamic>?> getHotelInfo(String hotelName) {
    return db
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

  // --- SEEDING (DEFAULT DATA CREATION) ---
  Future<void> seedDefaultServices(String hotelName) async {
    // 1. Check & Seed Restaurant
    final restRef = db
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
    final spaRef = db
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
    final fitnessRef = db
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
}
