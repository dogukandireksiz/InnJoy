import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart'; // <-- 1. EKLENDİ: Provider paketi
import 'package:login_page/providers/language_provider.dart'; // <-- 2. EKLENDİ: Senin provider dosyan (yolu kontrol et)

import 'package:login_page/screens/screens.dart';
import 'package:login_page/widgets/verification_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // Firebase Auth durumunu dinliyoruz (Giriş yapıldı mı çıkış mı yapıldı?)
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        
        // 1. Firebase hala bağlantıyı kontrol ediyorsa bekleme ikonu göster
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // 2. Eğer snapshot içinde veri varsa (Kullanıcı giriş yapmışsa)
        if (snapshot.hasData) {
          User? user = snapshot.data;
          
          // E-posta doğrulaması kontrolü
          if(user != null && !user.emailVerified){
            return VerificationScreen(user: user);
          }

          // 🔥 3. EKLENDİ: DİL TERCİHİNİ ÇEKME İŞLEMİ 🔥
          // Ekran çizimi biter bitmez (addPostFrameCallback) dili Firebase'den çekiyoruz.
          // Eğer bunu yapmazsak uygulama varsayılan (İngilizce) açılır, sonra değişir.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Provider.of<LanguageProvider>(context, listen: false).fetchLocale();
          });

          // Kullanıcının ismini HomeScreen'e gönderiyoruz.
          return HomeScreen(userName: user?.displayName ?? "User");
        }

        // 3. Kullanıcı giriş yapmamışsa Login ekranını göster
        return const LoginScreen();
      },
    );
  }
}