import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:login_page/screens/screens.dart';
import 'package:login_page/widgets/verification_screen.dart';
import '../service/database_service.dart';
import '../screens/home/hotel_selection_screen.dart';
import '../screens/home/home_screen.dart';
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

          // ROL VE OTEL KONTROLÜ
          return FutureBuilder<Map<String, dynamic>?>(
            future: DatabaseService().getUserData(user!.uid),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              final userData = snapshot.data;
              final role = userData?['role'] ?? 'customer'; // Varsayılan role
              final hotelName = userData?['hotelName'];

              if (role == 'admin') {
                // 1. Admin ise ama otel ataması yoksa -> ERİŞİM ENGELİ
                if (hotelName == null || hotelName.isEmpty) {
                  return Scaffold(
                    body: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline, size: 60, color: Colors.red),
                            const SizedBox(height: 16),
                            const Text(
                              'Erişim Reddedildi',
                              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Hesabınız yönetici olarak tanımlanmış ancak size atanmış bir otel bulunamadı.\n\nLütfen yöneticinizle görüşün.',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 16, color: Colors.black54),
                            ),
                            const SizedBox(height: 32),
                            ElevatedButton.icon(
                              onPressed: () async {
                                await FirebaseAuth.instance.signOut();
                              },
                              icon: const Icon(Icons.logout),
                              label: const Text('Çıkış Yap'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                  );
                }

                // 2. Admin ve oteli varsa -> AdminHomeScreen'e git
                return const AdminHomeScreen();
              }

              // --- MÜŞTERİ AKIŞI ---
              // Eğer müşterinin kayıtlı oteli yoksa -> Otel Seçim Ekranı (PNR Girişi)
              if (hotelName == null || hotelName.isEmpty) {
                return const HotelSelectionScreen();
              }

              // Oteli varsa -> Direkt Ana Ekrana (HomeScreen)
              return HomeScreen(userName: user.displayName ?? "Misafir");
            },
          );

        }
        return const LoginScreen();
      },
    );
  }
}