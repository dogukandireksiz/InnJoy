import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:login_page/model/user_model.dart';

class UserService {
  // Firestore bağlantı nesnesi
  FirebaseFirestore firestore = FirebaseFirestore.instance;

  // Firestore'a yeni kullanıcı kaydı ekleyen fonksiyon
  Future<void> createDbUser(UserModel user) async {
    try {
      await firestore
          .collection("users")     // "users" koleksiyonuna eriş
          .doc(user.uid)           // Belge ID olarak Firebase UID kullan
          .set(user.toJson(), SetOptions(merge: true));     // UserModel'i mevcut verinin üzerine ekle (role silinmesin)
    } catch (e) {
      print("there is an error : $e");  // Hata durumunda konsola yaz
    }
  }
}
