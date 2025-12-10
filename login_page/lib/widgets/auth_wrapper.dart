import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:login_page/screens/screens.dart';
import 'package:login_page/widgets/verification_screen.dart';
import '../service/database_service.dart';
import '../screens/home/admin_home_screen.dart';

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
          // Giriş yapmış kullanıcının bilgilerini alıyoruz
          User? user = snapshot.data;
          
          if(user != null && !user.emailVerified){
            return VerificationScreen(user: user);
          }

          // ROL KONTROLÜ (YENİ EKLENEN KISIM)
          return FutureBuilder<String>(
            future: DatabaseService().getUserRole(user!.uid),
            builder: (context, roleSnapshot) {
              if (roleSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              if (roleSnapshot.hasData && roleSnapshot.data == 'admin') {
                return const AdminHomeScreen();
              }

              // Varsayılan olarak Müşteri Ekranına Git
              return HomeScreen(userName: user.displayName ?? "User");
            },
          );
        }

        // 3. Kullanıcı giriş yapmamışsa Login ekranını göster
        return const LoginScreen();
      },
    );
  }
}