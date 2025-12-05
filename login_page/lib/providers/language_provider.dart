import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LanguageProvider extends ChangeNotifier {
  // Varsayılan dilimiz İNGİLİZCE
  Locale _appLocale = const Locale('en');

  Locale get appLocale => _appLocale;

  // 1. Firebase'den Kullanıcının Dilini Çekme (Uygulama açılınca çalışacak)
  Future<void> fetchLocale() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        var snapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (snapshot.exists && snapshot.data()!.containsKey('languageCode')) {
          String savedLang = snapshot.get('languageCode');
          _appLocale = Locale(savedLang);
          notifyListeners(); // Uygulamayı güncelle
        }
      } catch (e) {
        debugPrint("Dil çekme hatası: $e");
      }
    }
  }

  // 2. Dili Değiştirme ve Firebase'e Kaydetme (Profilde butona basınca çalışacak)
  Future<void> changeLanguage(Locale type) async {
    // Önce uygulama içindeki dili değiştir
    _appLocale = type;
    notifyListeners();

    // Sonra Firebase'e kaydet
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set(
        {
          'languageCode': type.languageCode, // 'en' veya 'tr' olarak kaydeder
        },
        SetOptions(merge: true),
      ); // Diğer verileri silmeden sadece dili günceller
    }
  }
}
