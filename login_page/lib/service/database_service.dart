import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../model/menu_item_model.dart';

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

  // --- ETKİNLİKLERİ GETİR ---
  Stream<List<Map<String, dynamic>>> getEvents() {
    return _db.collection('events').orderBy('date').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        var data = doc.data();
        data['id'] = doc.id; // Döküman ID'sini de alalım (Katılmak için lazım)
        return data;
      }).toList();
    });
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

// --- KULLANICI ROLÜNÜ GETİR ---
// --- KULLANICI ROLÜNÜ GETİR (DEBUG MODU) ---
  Future<String> getUserRole(String userId) async {
    try {
      print("🔍 ROL KONTROLÜ BAŞLADI: Kullanıcı ID -> $userId"); // 1. Adım

      DocumentSnapshot doc = await _db.collection('users').doc(userId).get();

      if (doc.exists && doc.data() != null) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        
        print("📄 VERİTABANINDAN GELEN VERİ: $data"); // 2. Adım: Tüm veriyi göster

        // Rolü kontrol et
        if (data.containsKey('role')) {
          String role = data['role'];
          print("✅ BULUNAN ROL: $role"); // 3. Adım: Rol bulundu
          return role;
        } else {
          print("⚠️ DİKKAT: 'role' alanı bu belgede YOK! Varsayılan 'customer' dönüyor.");
          return 'customer';
        }
      } else {
        print("❌ HATA: Kullanıcı veritabanında bulunamadı!");
        return 'customer';
      }
    } catch (e) {
      print("🔥 KRİTİK HATA: $e");
      return 'customer';
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
    });
  }
}