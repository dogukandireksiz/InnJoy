
// Temel Flutter araçlarını ve 'foundation' kütüphanesini içeri aktarır.
//import "package:flutter/foundation.dart";
// Firebase Authentication (kimlik doğrulama) kütüphanesini içeri aktarır.
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'email': email,
        'role': 'customer', // Varsayılan rol
        'createdAt': FieldValue.serverTimestamp(),
      });

      await user.sendEmailVerification();
    }

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

    if(user != null) {
      // 1. E-posta doğrulama kontrolü (mevcut mantık)
      if(!user.emailVerified){
         // Gerekirse buraya mantık eklenebilir
      }

      // 2. Self-Healing: Eğer Firestore'da kaydı yoksa oluştur (Eski kayıtları kurtarmak için)
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (!userDoc.exists) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'email': email,
          'role': 'customer', 
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    }
    return userCredential;
  }

  // SIGN OUT (OTURUMU KAPATMA)
  
  // Aktif kullanıcı oturumunu kapatır.
  Future<void> signOut()async{
    // Kullanıcının oturumunu kapatma işlemini yapar.
    await _firebaseAuth.signOut();
    await _googleSignIn.signOut();
  }

  // ŞİFRE SIFIRLAMA: Kullanıcıya şifre sıfırlama e-postası gönderir
  Future<void> sendPasswordResetEmail({required String email}) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } catch (e) {
      print("Password Reset Error: $e");
      rethrow;
    }
  }

  // ŞİFRE GÜNCELLEME: Mevcut şifreyi doğrulayıp yeni şifre ile güncelleme
  Future<void> reauthenticateAndUpdatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _firebaseAuth.currentUser;
    if (user == null || user.email == null) {
      throw FirebaseAuthException(code: 'no-current-user', message: 'No user signed in');
    }

    // 1. Re-authenticate (Kullanıcıyı yeniden kimlik doğrulama işlemi)
    final credential = EmailAuthProvider.credential(
      email: user.email!,
      password: currentPassword,
    );
    await user.reauthenticateWithCredential(credential);

    // 2. Şifreyi güncelleme
    await user.updatePassword(newPassword);

    // Kullanıcı profilini yeniden yükleme (force refresh)
    await user.reload();
  }

  // Twitter ile giriş (Twitter Authentication)
  Future<User?> signInWithTwitter() async {
    try {
      TwitterAuthProvider twitterProvider = TwitterAuthProvider();

      // Firebase ile Twitter credential'ı kullanılarak giriş yapılır
      UserCredential userCredential = await FirebaseAuth.instance.signInWithProvider(twitterProvider);
      User? user = userCredential.user;

      //  Firestore'a Twitter kullanıcı bilgilerini ekleme işlemi 
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'email': user.email,
          'displayName': user.displayName,
          'provider': 'twitter',
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      return user;
    } catch (e) {
      print("Twitter Giriş Hatası: $e");
      return null;
    }
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
        User? user = userCredential.user;

        if (user != null) {
           await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
             'uid': user.uid,
             'email': user.email,
             'displayName': user.displayName,
             'photoURL': user.photoURL,
             'provider': 'facebook',
           }, SetOptions(merge: true));

           final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
           if (!userDoc.exists || !userDoc.data()!.containsKey('role')) {
              await FirebaseFirestore.instance.collection('users').doc(user.uid).update({'role': 'customer'});
           }
        }
        return user;
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
     User? user = userCredential.user;
    
     if (user != null) {
       // Kullanıcı daha önce kayıtlı mı kontrol et (merge: true ile güncelleme yapar)
       await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
         'uid': user.uid,
         'email': user.email,
         'displayName': user.displayName,
         'photoURL': user.photoURL,
         'provider': 'google',
         // 'role': 'customer', // Var olan rolü ezmemek için bunu set içinde değil, yoksa eklemek lazım.
         // 'createdAt': FieldValue.serverTimestamp(), // Var olanı ezmemek için
       }, SetOptions(merge: true));
       
       // Sadece eğer rol yoksa 'customer' olarak ata
       final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
       if (!userDoc.exists || !userDoc.data()!.containsKey('role')) {
          await FirebaseFirestore.instance.collection('users').doc(user.uid).update({'role': 'customer'});
       }
     }

    return user;

    }catch(e){
      print(e.toString());
    }
    




  }

}