import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../model/menu_item_model.dart';
import 'dart:math';
import '../location/location_model.dart';
class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // --- ODA SERVİSİ MENÜSÜNÜ GETİR ---
  Stream<List<MenuItem>> getMenuItems() {
    return _db.collection('menu_items').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return MenuItem.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  // --- SİPARİŞ VERME ---
  Future<void> placeOrder(List<MenuItem> cartItems, double totalPrice) async {
    User? user = _auth.currentUser;
    if (user != null) {
      await _db.collection('orders').add({
        'userId': user.uid,
        'items': cartItems.map((item) => item.toMap()).toList(),
        'totalPrice': totalPrice,
        'status': 'Pending',
        'timestamp': FieldValue.serverTimestamp(),
        'roomNumber': '101', // İleride kullanıcı profilinden çekilebilir
      });
    }
  }

  // --- TOPLAM HARCAMAYI HESAPLA ---
  Stream<double> getTotalSpending() {
    // 1. Giriş yapmış kullanıcıyı bul
    User? user = _auth.currentUser;
    if (user == null) return Stream.value(0.0);

    // 2. Bu kullanıcının siparişlerini dinle
    return _db
        .collection('orders')
        .where('userId', isEqualTo: user.uid)
        .snapshots()
        .map((snapshot) {
      double total = 0.0;
      
      // 3. Tüm siparişlerin fiyatlarını topla
      for (var doc in snapshot.docs) {
        var data = doc.data();
        if (data.containsKey('totalPrice')) {
          // Gelen veri sayı mı yazı mı kontrol et, ona göre topla
          var price = data['totalPrice'];
          if (price is int) {
            total += price.toDouble();
          } else if (price is double) {
            total += price;
          }
        }
      }
      return total;
    });


  }


  // --- SPA RANDEVUSU VE HARCAMASI ---
  Future<void> bookSpaAppointment(String serviceName, String duration, double price) async {
    User? user = _auth.currentUser;
    if (user != null) {
      // 1. Önce Randevu Kaydı Oluştur (Detaylar için)
      await _db.collection('spa_bookings').add({
        'userId': user.uid,
        'serviceName': serviceName,
        'duration': duration,
        'price': price,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // 2. Sonra HARCAMA (Order) Olarak Ekle (Böylece Toplam Borçta görünür)
      await _db.collection('orders').add({
        'userId': user.uid,
        'items': [
          {
            'name': "$serviceName ($duration)",
            'price': price,
            'category': 'spa',
            'imageUrl': '' // Resim yoksa boş
          }
        ],
        'totalPrice': price, // Fiyatı buraya sayı olarak ekliyoruz
        'status': 'Confirmed',
        'timestamp': FieldValue.serverTimestamp(),
        'type': 'spa_booking' 
      });
    }
  }
// --- GEÇMİŞ SİPARİŞLERİ LİSTELE (DÜZELTİLMİŞ HALİ) ---
  Stream<List<Map<String, dynamic>>> getOrderHistory() {
    User? user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _db
        .collection('orders')
        .where('userId', isEqualTo: user.uid)
        // .orderBy('timestamp', descending: true)  <-- BU SATIRI SİL VEYA YORUMA AL (//)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => doc.data()).toList();
    });
  }

  // --- HOUSEKEEPING (TEMİZLİK/BAKIM) İSTEĞİ GÖNDER ---
  Future<void> requestHousekeeping(String requestType, String note) async {
    User? user = _auth.currentUser;
    if (user != null) {
      await _db.collection('housekeeping_requests').add({
        'userId': user.uid,
        'roomNumber': '101', // İleride kullanıcı profilinden dinamik çekilebilir
        'requestType': requestType, // Örn: 'Temizlik', 'Teknik Servis', 'Havlu'
        'note': note,
        'status': 'Pending', // Pending (Bekliyor), In Progress (İşleniyor), Completed (Tamamlandı)
        'timestamp': FieldValue.serverTimestamp(),
      });
    }
  }

  // --- GEÇMİŞ İSTEKLERİ GETİR (Opsiyonel: Ekranda göstermek istersen) ---
  Stream<List<Map<String, dynamic>>> getHousekeepingHistory() {
    User? user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _db
        .collection('housekeeping_requests')
        .where('userId', isEqualTo: user.uid)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  // --- ETKİNLİKLERİ GETİR (ESKİ - KULLANILMIYOR) ---
  /*
  Stream<List<Map<String, dynamic>>> getEvents() {
    return _db.collection('events').orderBy('date').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        var data = doc.data();
        data['id'] = doc.id; // Döküman ID'sini de alalım (Katılmak için lazım)
        return data;
      }).toList();
    });
  }
  */

  // --- OTEL ÖZELİNDE ETKİNLİK İŞLEMLERİ ---

  // 1. Etkinlikleri Getir (Otel Bazlı)
  Stream<List<Map<String, dynamic>>> getHotelEvents(String hotelName) {
    return _db
        .collection('hotels')
        .doc(hotelName)
        .collection('events')
        .orderBy('date')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        var data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }

  // 2. Etkinlik Ekle
  Future<void> addEvent(String hotelName, Map<String, dynamic> eventData) async {
    await _db
        .collection('hotels')
        .doc(hotelName)
        .collection('events')
        .add(eventData);
  }

  // 3. Etkinlik Güncelle
  Future<void> updateEvent(String hotelName, String eventId, Map<String, dynamic> eventData) async {
    await _db
        .collection('hotels')
        .doc(hotelName)
        .collection('events')
        .doc(eventId)
        .update(eventData);
  }

  // --- ETKİNLİK KAYIT (REGISTRATION) ---
  Future<Map<String, dynamic>> registerForEvent(String hotelName, String eventId, Map<String, dynamic> userInfo) async {
    final eventRef = _db.collection('hotels').doc(hotelName).collection('events').doc(eventId);
    final userRef = eventRef.collection('registrations').doc(userInfo['userId']);

    try {
      return await _db.runTransaction((transaction) async {
        final eventSnapshot = await transaction.get(eventRef);
        
        if (!eventSnapshot.exists) {
          return {'success': false, 'message': 'Etkinlik bulunamadı.'};
        }

        final data = eventSnapshot.data()!;
        final currentRegistered = data['registered'] ?? 0;
        final capacity = data['capacity'] ?? 0;

        // 1. Kontenjan Kontrolü
        if (capacity > 0 && currentRegistered >= capacity) { // capacity > 0 ekledik ki sınırsız kapasite durumunda hep dolu olmasın
          return {'success': false, 'status': 'full', 'message': 'Kontejan dolu.'};
        }

        // 2. Kullanıcı daha önce kayıt olmuş mu kontrolü (Opsiyonel: Client side'da da yapılabilir ama burada garanti olsun)
        final userSnapshot = await transaction.get(userRef);
        if (userSnapshot.exists) {
          return {'success': false, 'status': 'already_registered', 'message': 'Zaten kayıtlısınız.'};
        }

        // 3. Kayıt İşlemi
        // Etkinlik sayacını artır
        transaction.update(eventRef, {'registered': currentRegistered + 1});
        
        // Alt koleksiyona kullanıcıyı ekle
        transaction.set(userRef, {
          ...userInfo,
          'timestamp': FieldValue.serverTimestamp(),
        });

        return {'success': true, 'status': 'success', 'message': 'Kayıt başarılı.'};
      });
    } catch (e) {
      print("Registration Error: $e");
      return {'success': false, 'message': 'Bir hata oluştu: $e'};
    }
  }

  // --- ETKİNLİK KATILIMCILARI (ADMIN) ---
  Stream<List<Map<String, dynamic>>> getEventParticipants(String hotelName, String eventId) {
    return _db
        .collection('hotels')
        .doc(hotelName)
        .collection('events')
        .doc(eventId)
        .collection('registrations')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  // 4. Etkinlik Sil
  Future<void> deleteEvent(String hotelName, String eventId) async {
    await _db
        .collection('hotels')
        .doc(hotelName)
        .collection('events')
        .doc(eventId)
        .delete();
  }


  // --- ETKİNLİĞE KATIL ---
  Future<void> joinEvent(String eventId, String eventName) async {
    User? user = _auth.currentUser;
    if (user != null) {
      // 1. Kullanıcıyı etkinliğin katılımcı listesine ekle
      await _db.collection('events').doc(eventId).update({
        'participants': FieldValue.arrayUnion([user.uid])
      });

      // 2. Kullanıcının kendi "Katıldıklarım" listesine ekle (Opsiyonel ama iyi olur)
      await _db.collection('event_bookings').add({
        'userId': user.uid,
        'eventId': eventId,
        'eventName': eventName,
        'timestamp': FieldValue.serverTimestamp(),
      });
    }
  }

  // --- PNR / REZERVASYON İŞLEMLERİ ---

  // 1. Yeni PNR Oluştur (Admin)
  Future<void> createReservation(String hotelName, String roomNumber, String guestName, DateTime checkInDate, DateTime checkOutDate) async {
    // 6 Haneli Rastgele PNR Üret
    String pnr = _generateRandomPnr();
    
    // Aynı PNR var mı diye kontrol et (Çok düşük ihtimal ama olsun)
    // Basitlik adına şimdilik direkt oluşturuyoruz.

    final reservation = {
      'pnr': pnr,
      'roomNumber': roomNumber,
      'guestName': guestName,
      'checkInDate': Timestamp.fromDate(checkInDate),
      'checkOutDate': Timestamp.fromDate(checkOutDate),
      'status': 'active',
      'createdAt': FieldValue.serverTimestamp(),
    };

    // hotels/{hotelName}/reservations/{pnr} yoluna kaydet
    await _db
        .collection('hotels')
        .doc(hotelName)
        .collection('reservations')
        .doc(pnr)
        .set(reservation);
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

  // 3. PNR Doğrula ve Kullan (Müşteri)
  Future<bool> verifyAndRedeemPnr(String pnr, String selectedHotel, String userId) async {
    try {
      final docRef = _db
          .collection('hotels')
          .doc(selectedHotel)
          .collection('reservations')
          .doc(pnr);

      final doc = await docRef.get();

      if (!doc.exists) return false;

      final data = doc.data();
      if (data == null) return false;

      if (data['status'] == 'active') {
        // PNR Geçerli -> Kullanıldı olarak işaretle
        await docRef.update({
          'status': 'used',
          'usedBy': userId,
        });

        // Kullanıcının profiline otel bilgisini kaydet
        await _db.collection('users').doc(userId).update({
          'hotelName': selectedHotel,
          'roomNumber': data['roomNumber'],
          'checkedInAt': FieldValue.serverTimestamp(),
        });

        return true;
      }
      
      return false; // Zaten kullanılmış veya iptal edilmiş
    } catch (e) {
      print("PNR Verify Error: $e");
      return false;
    }
  }

  // Yardımcı: Rastgele 6 haneli kod üretici (Örn: XK92M4)
  String _generateRandomPnr() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return List.generate(6, (index) => chars[random.nextInt(chars.length)]).join();
  }

  // --- KULLANICI ROLÜNÜ GETİR (DEBUG MODU) ---
  // --- KULLANICI VERİSİNİ GETİR (ROL VE OTEL ADI İÇİN) ---
  Future<Map<String, dynamic>?> getUserData(String userId) async {
    try {
      DocumentSnapshot doc = await _db.collection('users').doc(userId).get();

      if (doc.exists && doc.data() != null) {
        return doc.data() as Map<String, dynamic>;
      } else {
        print("❌ HATA: Kullanıcı veritabanında bulunamadı!");
        return null;
      }
    } catch (e) {
      print("🔥 KRİTİK HATA: $e");
      return null;
    }
  }

  // --- KULLANICI KAYDET (Senin Değişken İsimlerine Göre) ---
  Future<void> saveUserdata(String uid, String email, String name, {String role = 'customer'}) async {
    await _db.collection('users').doc(uid).set({
      'mailAddress': email,      // Senin veritabanındaki isimlendirme
      'name_username': name,     // Senin veritabanındaki isimlendirme
      'role': role,              // YENİ EKLENEN ALAN
      'uid': uid,
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

      //LOCATİON SERVİCE

  final String hotelId = "o5qzfgsM56fuGn5PNij9"; //şimdilik geçici

  Future<LocationModel?> getLocationDetails(String locationId) async {
    try{
      var doc = await _db
            .collection('hotels')
            .doc(hotelId)
            .collection('locations')
            .doc(locationId)
            .get();

      if(doc.exists && doc.data() != null){
        return LocationModel.fromFirestore(doc.data()!,doc.id);
      }      
    }catch(e){
      print("$e");
    }
    return null;
  }

  // Kullanıcının oda numarasını çeken fonksiyon
  Future<String> getUserRoomNumber() async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser != null) {
        DocumentSnapshot userDoc = await _db
            .collection('users')
            .doc(currentUser.uid)
            .get();

        if (userDoc.exists) {
          var data = userDoc.data() as Map<String, dynamic>;
          return data['room_number']?.toString() ?? "1";
        }
      }
      return "1"; // Kullanıcı yoksa veya veri yoksa varsayılan
    } catch (e) {
      throw Exception("Oda numarası çekilirken hata: $e");
    }
  }

  // Acil durum bildirimini gönderen fonksiyon
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
      throw Exception("Bildirim gönderilemedi: $e");
    }
  }

  // Oda verilerini dinleyen Stream (UI'daki StreamBuilder için)
  Stream<DocumentSnapshot> getRoomStream(String documentId) {
    return _db.collection('rooms').doc(documentId).snapshots();
  }
}