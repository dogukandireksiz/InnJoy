import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:login_page/screens/screens.dart';
import 'package:login_page/widgets/common/verification_screen.dart';
import '../services/database_service.dart';
import '../screens/home/hotel_selection_screen.dart';
import '../screens/home/admin_home_screen.dart';



class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // Firebase Auth durumunu dinliyoruz (Giriş yapıldı mı Çıkış mı yapıldı?)
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        
        // 1. Firebase hala bağlantıyı kontrol ediyorsa bekleme ikonu göster
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // 2. Eğer snapshot iÇinde veri varsa (Kullanıcı giriş yapmışsa)
        if (snapshot.hasData) {
          // Giriş yapmış kullanıcının bilgilerini alıyoruz
          User? user = snapshot.data;
          
          if(user != null && !user.emailVerified){
            return VerificationScreen(user: user);
          }

          // ROL VE OTEL KONTROLÜ (STREAM - CANLI TAKİP)
          return StreamBuilder<Map<String, dynamic>?>(
            stream: DatabaseService().getUserStream(user!.uid),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              final userData = snapshot.data;
              // Eğer kullanıcı verisi henüz oluşmamışsa (signup sonrası gecikme olabilir), loading göster veya misafir varsay
              if (userData == null) {
                 return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              final role = userData['role'] ?? 'customer'; 
              final hotelName = userData['hotelName'];

              if (role == 'admin') {
                // 1. Admin ise ama otel ataması yoksa -> ERİşİM ENGELİ
                if (hotelName == null || hotelName.isEmpty) {
                  return Scaffold(
                    body: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline, size: 60, color: Colors.amber),
                            const SizedBox(height: 16),
                            const Text(
                              'Admin Account Pending',
                              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Your account has an admin role.\nPlease assign a hotel via Firebase.',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 16, color: Colors.black54),
                            ),
                            const SizedBox(height: 32),
                            ElevatedButton.icon(
                              onPressed: () async {
                                await FirebaseAuth.instance.signOut();
                              },
                              icon: const Icon(Icons.logout),
                              label: const Text('Log Out'),
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

              // --- MÜşTERİ AKIşI ---
              // Eğer müşterinin kayıtlı oteli yoksa -> Otel SeÇim Ekranı (PNR Girişi)
              if (hotelName == null || hotelName.isEmpty) {
                return const HotelSelectionScreen();
              }

              // Tarih Kontrolü (Fail-safe)
              // Admin paneli actiginda otomatik siliniyor ama panel acilmazsa buradan engelliyoruz.
              if (userData['checkOutDate'] != null && userData['checkOutDate'] is Timestamp) {
                final checkOut = (userData['checkOutDate'] as Timestamp).toDate();
                if (DateTime.now().isAfter(checkOut)) {
                  // Tarih geÇmiş!
                  // Kullanıcıyı HotelSelection'a atıyoruz (Girişi engelliyoruz)
                  // İdealde burada bir "Süreniz doldu" uyarısı verilebilir ama şimdilik seÇim ekranına atalım.
                  return const HotelSelectionScreen();
                }
              }

              // Oteli varsa -> Direkt Ana Ekrana (HomeScreen)
              return HomeScreen(userName: userData['name_username'] ?? user.displayName ?? "Guest");
            },
          );

        }
        return const LoginScreen();
      },
    );
  }
}







