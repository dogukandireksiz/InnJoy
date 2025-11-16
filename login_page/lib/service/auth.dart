// Temel Flutter araçlarını ve 'foundation' kütüphanesini içeri aktarır.
//import "package:flutter/foundation.dart";
// Firebase Authentication (kimlik doğrulama) kütüphanesini içeri aktarır.
import 'package:firebase_auth/firebase_auth.dart';

// Firebase Auth işlemlerini yöneten sınıf.
class Auth{
  // Firebase Auth'un bir örneğini (instance) oluşturur.
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  // Şu anda oturum açmış olan kullanıcıyı (User) döndürür.
  User ? get currentUser => _firebaseAuth.currentUser; 

  // Kullanıcı oturum durumundaki (giriş/çıkış) değişiklikleri dinleyen bir Stream sağlar.
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges(); 

  // REGİSTER (KAYIT OLMA)

  // Yeni bir kullanıcı kaydı oluşturur.
  Future<UserCredential> createUser({
    required String email,
    required String password,
  }) async {
    // E-posta ve şifre ile kullanıcı oluşturma işlemini yapar.
    return await _firebaseAuth.createUserWithEmailAndPassword(email: email, password: password);
  }

  // LOGING (GİRİŞ YAPMA)
  
  // Mevcut bir kullanıcı ile oturum açar.
  Future<void> signIn({
    required String email,
    required String password,
  }) async{
    // E-posta ve şifre ile oturum açma işlemini yapar.
    await _firebaseAuth.signInWithEmailAndPassword(email: email, password: password);
  }

  // SIGN OUT (OTURUMU KAPATMA)
  
  // Aktif kullanıcı oturumunu kapatır.
  Future<void> signOut()async{
    // Kullanıcının oturumunu kapatma işlemini yapar.
    await _firebaseAuth.signOut();
  }
}