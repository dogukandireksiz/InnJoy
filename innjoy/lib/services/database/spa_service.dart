import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:login_page/services/database/base_database_service.dart';
import 'package:login_page/services/logger_service.dart';

/// SpaService - Spa menu, appointments, and wellness management.
class SpaService extends BaseDatabaseService {
  // Singleton pattern
  static final SpaService _instance = SpaService._internal();
  factory SpaService() => _instance;
  SpaService._internal();

  // --- SPA & FITNESS INFO ---
  Stream<Map<String, dynamic>?> getSpaInfo(String hotelName) {
    return db
        .collection('hotels')
        .doc(hotelName)
        .collection('spa_wellness')
        .doc('information')
        .snapshots()
        .map((doc) => doc.data());
  }

  Stream<Map<String, dynamic>?> getFitnessInfo(String hotelName) {
    return db
        .collection('hotels')
        .doc(hotelName)
        .collection('fitness')
        .doc('information')
        .snapshots()
        .map((doc) => doc.data());
  }

  // --- SPA RANDEVU OLUŞTURMA ---
  Future<void> bookSpaAppointment({
    required String serviceName,
    required String duration,
    required double price,
    required DateTime appointmentDate,
    required String timeSlot,
    required String paymentMethod,
  }) async {
    final user = auth.currentUser;
    if (user == null) throw Exception("User is not logged in.");

    final userDoc = await db.collection('users').doc(user.uid).get();
    if (!userDoc.exists) throw Exception("User profile not found.");

    final userData = userDoc.data()!;
    final String hotelName = userData['hotelName'] ?? '';

    if (hotelName.isEmpty) throw Exception("Hotel information not found.");

    // Update balance if room charge
    if (paymentMethod == 'room_charge' && price > 0) {
      final roomNumber = userData['roomNumber'];

      var reservationQuery = await db
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
          'title': serviceName,
          'date': Timestamp.now(),
          'amount': price,
          'category': 'spa_wellness',
          'items': 'Spa Appointment - $duration',
        };

        await reservationRef.update({
          'expenses': FieldValue.arrayUnion([expenseItem]),
          'currentBalance': FieldValue.increment(price),
        });
      } else {
        throw Exception(
          "No active hotel reservation found, cannot charge to room.",
        );
      }
    }

    // Save appointment
    await db
        .collection('hotels')
        .doc(hotelName)
        .collection('spa_wellness')
        .doc('reservations')
        .collection('appointments')
        .add({
          'serviceName': serviceName,
          'duration': duration,
          'price': price,
          'appointmentDate': Timestamp.fromDate(appointmentDate),
          'timeSlot': timeSlot,
          'guestName': userData['name_username'] ?? 'Guest',
          'guestEmail': userData['email'] ?? userData['mailAddress'] ?? '',
          'roomNumber': userData['roomNumber'] ?? 'Unknown',
          'userId': user.uid,
          'hotelName': hotelName,
          'createdAt': FieldValue.serverTimestamp(),
          'status': 'pending',
          'paymentStatus': paymentMethod == 'room_charge'
              ? 'charged_to_room'
              : 'pay_at_spa',
          'paymentMethod': paymentMethod,
        });
  }

  // --- MÜSAİTLİK KONTROLÜ İÇİN ---
  Stream<List<String>> getSpaBookedSlots(String hotelName, DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return db
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
        .where('status', isNotEqualTo: 'cancelled')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => doc.data()['timeSlot'] as String)
              .toList();
        });
  }

  // --- SPA RANDEVULARINI GETİR (ADMIN) ---
  Stream<List<Map<String, dynamic>>> getSpaReservations(String hotelName) {
    return db
        .collection('hotels')
        .doc(hotelName)
        .collection('spa_wellness')
        .doc('reservations')
        .collection('appointments')
        .orderBy('appointmentDate', descending: true)
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
    await db
        .collection('hotels')
        .doc(hotelName)
        .collection('spa_wellness')
        .doc('reservations')
        .collection('appointments')
        .doc(reservationId)
        .update({'status': status});
  }

  // --- SPA MENÜ YÖNETİMİ (ADMIN) ---

  // Add Spa Service
  Future<void> addSpaService(
    String hotelName,
    Map<String, dynamic> serviceData,
  ) async {
    serviceData['type'] = 'service';

    final serviceName = serviceData['name'] ?? 'Unknown Service';
    await db
        .collection('hotels')
        .doc(hotelName)
        .collection('spa_wellness')
        .doc('services')
        .collection('items')
        .doc(serviceName)
        .set(serviceData);
  }

  // Update Spa Service
  Future<void> updateSpaService(
    String hotelName,
    String docId,
    Map<String, dynamic> serviceData,
  ) async {
    await db
        .collection('hotels')
        .doc(hotelName)
        .collection('spa_wellness')
        .doc('services')
        .collection('items')
        .doc(docId)
        .update(serviceData);
  }

  // Delete Spa Service
  Future<void> deleteSpaService(String hotelName, String docId) async {
    await db
        .collection('hotels')
        .doc(hotelName)
        .collection('spa_wellness')
        .doc('services')
        .collection('items')
        .doc(docId)
        .delete();
  }

  // Get Spa Menu
  Stream<List<Map<String, dynamic>>> getSpaMenu(String hotelName) {
    return db
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

  // --- KULLANICIYA AİT TÜM SPA RANDEVULARINI GETİR ---
  Stream<List<Map<String, dynamic>>> getUserSpaAppointments(
    String userId, {
    String? hotelName,
  }) {
    if (hotelName == null || hotelName.isEmpty) {
      return Stream.value([]);
    }

    return db
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

  // ONE-TIME SEEDING: Add default spa services
  Future<void> migrateSpaServicesToNewStructure(String hotelName) async {
    try {
      Logger.debug('Checking spa services seeding for $hotelName');

      final migrationDoc = await db
          .collection('hotels')
          .doc(hotelName)
          .collection('spa_wellness')
          .doc('migration_status')
          .get();

      if (migrationDoc.exists && migrationDoc.data()?['completed'] == true) {
        Logger.debug('Seeding already completed, skipping');
        return;
      }

      final existingServices = await db
          .collection('hotels')
          .doc(hotelName)
          .collection('spa_wellness')
          .doc('services')
          .collection('items')
          .get();

      if (existingServices.docs.isNotEmpty) {
        Logger.debug(
          'Services already exist (${existingServices.docs.length}), skipping seeding',
        );
        await db
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

      final defaultServices = [
        {
          'name': 'Aromatherapy',
          'description': 'Sensory therapy with essential natural oils.',
          'duration': 60,
          'price': 1500,
          'imageUrl':
              'https://images.unsplash.com/photo-1540555700478-4be289fbecef?q=80&w=1000&auto=format&fit=crop',
          'type': 'service',
        },
        {
          'name': 'Skin Care',
          'description': 'Professional skin cleansing and care.',
          'duration': 45,
          'price': 850,
          'imageUrl':
              'https://images.unsplash.com/photo-1570172619644-dfd03ed5d881?q=80&w=1000&auto=format&fit=crop',
          'type': 'service',
        },
        {
          'name': 'Massage Therapy',
          'description': 'Relaxing and rejuvenating massage therapy.',
          'duration': 60,
          'price': 1200,
          'imageUrl':
              'https://images.unsplash.com/photo-1544161515-4ab6ce6db874?q=80&w=1000&auto=format&fit=crop',
          'type': 'service',
        },
        {
          'name': 'Sauna & Steam',
          'description': 'Relaxation in sauna and steam rooms.',
          'duration': 30,
          'price': 500,
          'imageUrl':
              'https://images.unsplash.com/photo-1596178060671-7a80dc8059ea?w=1000&auto=format&fit=crop',
          'type': 'service',
        },
      ];

      for (final serviceData in defaultServices) {
        final serviceName = serviceData['name'] as String;
        await db
            .collection('hotels')
            .doc(hotelName)
            .collection('spa_wellness')
            .doc('services')
            .collection('items')
            .doc(serviceName)
            .set(serviceData);

        Logger.debug('Seeded service: $serviceName');
      }

      await db
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
}
