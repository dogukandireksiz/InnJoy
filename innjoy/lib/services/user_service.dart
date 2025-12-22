import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:login_page/models/user_model.dart';
import 'package:login_page/services/logger_service.dart';

class UserService {
  // Firestore bağlantı nesnesi
  FirebaseFirestore firestore = FirebaseFirestore.instance;

  // Firestore'a yeni kullanıcı kaydı ekleyen fonksiyon
  Future<void> createDbUser(UserModel user) async {
    try {
      await firestore
          .collection("users")     // "users" koleksiyonuna eriş
          .doc(user.uid)           // Belge ID olarak Firebase UID kullan
          .set(user.toJson(), SetOptions(merge: true));     // UserModel'i mevcut verinin üzerine ekle (role silinmesin)
    } catch (e) {
      Logger.error("there is an error : $e");  // Hata durumunda konsola yaz
    }
  }
}









