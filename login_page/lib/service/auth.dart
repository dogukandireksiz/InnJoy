
// Temel Flutter araçlarını ve 'foundation' kütüphanesini içeri aktarır.
//import "package:flutter/foundation.dart";
// Firebase Authentication (kimlik doğrulama) kütüphanesini içeri aktarır.
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';

import 'package:google_sign_in/google_sign_in.dart';




// Firebase Auth işlemlerini yöneten sınıf. 
class Auth{
  // Firebase Auth'un bir örneğini (instance) oluşturur.
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  
  // Şu anda oturum açmış olan kullanıcıyı (User) döndürür.
  User ? get currentUser => _firebaseAuth.currentUser; 

  // Kullanıcı oturum durumundaki (giriş/çıkış) değişiklikleri dinleyen bir Stream sağlar.
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges(); 

  // REGİSTER (KAYIT OLMA)

  // Yeni bir kullanıcı kaydı oluşturur.

Future<UserCredential?> createUser({
  required String email,
  required String password,
}) async {
  
  try {
    UserCredential userCredential = await _firebaseAuth.createUserWithEmailAndPassword(email: email, password: password);

    User? user = userCredential.user;

    await user?.sendEmailVerification();

    return userCredential;
  } on FirebaseAuthException {
   
    rethrow;
  } catch (e) {
    
    print("$e");
    return null;
  }
}

  // LOGING (GİRİŞ YAPMA)
  
  // Mevcut bir kullanıcı ile oturum açar.
  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async{
    // E-posta ve şifre ile oturum açma işlemini yapar.
    UserCredential userCredential = await _firebaseAuth.signInWithEmailAndPassword(email: email, password: password);
    User? user = userCredential.user;

    if(user != null && !user.emailVerified){

    }
    return userCredential;
  }

  // SIGN OUT (OTURUMU KAPATMA)
  
  // Aktif kullanıcı oturumunu kapatır.
  Future<void> signOut()async{
    // Kullanıcının oturumunu kapatma işlemini yapar.
    await _firebaseAuth.currentUser?.delete();
    await _firebaseAuth.signOut();
    await _googleSignIn.signOut();
  }

  Future<User?> signInWithFacebook() async {
    try{

      final LoginResult result = await FacebookAuth.instance.login();

      if(result.status == LoginStatus.success){
        final AccessToken accessToken = result.accessToken!;

        final OAuthCredential credential = FacebookAuthProvider.credential(
          accessToken.tokenString
        );

        final UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
        return userCredential.user;
      }else{
        return null;
      }

    }catch(e){
      print("$e");
      return null;
    }
  }

  Future<User?> singInWithTwitter() async {
    
      try{
        TwitterAuthProvider twitterProvider = TwitterAuthProvider();

        UserCredential userCredential = await FirebaseAuth.instance.signInWithProvider(twitterProvider);
        return userCredential.user;
      }catch(e){
        print("$e");
        return null;
      }
  }


  Future<User?> signInWithGoogle() async {
    // Oturum açma sürecini başlat
    try{
    // Oturum açma sürecini başlat
    final GoogleSignInAccount? gUser = await _googleSignIn.signIn();

    // Kullanıcı oturum açmayı iptal ederse null döndür
    if (gUser == null) {
      print("Google Sign-In is cancelled.");
      return null;
    }
    // Süreç içerisinden bilgileri al
    final GoogleSignInAuthentication gAuth = await gUser.authentication;  
    // Kullanıcı nesnesi oluştur
    final credential = GoogleAuthProvider.credential(accessToken: gAuth.accessToken, idToken: gAuth.idToken);     
    // Kullanıcı girişini sağla

     final UserCredential userCredential = await _firebaseAuth.signInWithCredential(credential);
    
    return userCredential.user;       

    }catch(e){
      print(e.toString());
    }
    







  }

}