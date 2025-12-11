import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:ui';
import '../services/service_screen.dart';
import '../events_activities/events_activities_screen.dart';
import '../payment/payment_screen.dart';
import '../room_service/room_service_screen.dart';
import '../housekeeping/housekeeping_screen.dart';
import '../profile/profile_screen.dart';
import '../../service/database_service.dart';
import '../../utils/custom_dialog.dart';
import 'hotel_selection_screen.dart';
import '../../widgets/auth_wrapper.dart';

import 'admin_home_screen.dart';

/// Ana Ekran (Home Screen)
///
/// Kullanıcının otel deneyimini yönettiği, hizmetlere, etkinliklere
/// ve fatura detaylarına erişebildiği ana kontrol panelidir.
class HomeScreen extends StatefulWidget {
  final String userName;
  final bool? isAdmin; // Gecikmeyi önlemek için opsiyonel parametre

  const HomeScreen({
    super.key, 
    required this.userName, 
    this.isAdmin,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late bool _isAdmin;

  @override
  void initState() {
    super.initState();
    // Eğer parametre geldiyse direkt onu kullan (Gecikme olmaz)
    // Gelmediyse varsayılan false ve asenkron kontrol
    _isAdmin = widget.isAdmin ?? false; 
    
    // Parametre gelmediyse yine de kontrol et
    if (widget.isAdmin == null) {
      _checkUserRole();
    }
  }

  Future<void> _checkUserRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userData = await DatabaseService().getUserData(user.uid);
      final role = userData?['role'];
      if (mounted) {
        setState(() {
          _isAdmin = role == 'admin';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFF6F7FB),
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        titleSpacing: 0,
        // PreTripScreen'e geri dönüş butonu (login_page projesinden korundu)
        leading: _isAdmin 
          ? null 
          : IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.grey),
              onPressed: () {
                // Müşteri ise otel seçimine gitsin
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const HotelSelectionScreen()),
                );
              },
              tooltip: 'Back',
            ),
        actions: [
          if (_isAdmin) ...[
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.visibility, color: Colors.blue, size: 18),
                  SizedBox(width: 4),
                  Text(
                    'Guest View',
                    style: TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            TextButton.icon(
              onPressed: () {
                 Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const AdminHomeScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.admin_panel_settings, color: Colors.orange, size: 20),
              label: const Text(
                'Admin Panel',
                style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
            ),
          ],
          IconButton(
            onPressed: () async {
              final shouldLogout = await CustomDialog.show(
                context,
                title: 'Log Out',
                message: 'Are you sure you want to log out?',
                confirmText: 'Log Out',
                cancelText: 'Cancel',
                isDanger: true,
              );
              if (shouldLogout == true) {
                await FirebaseAuth.instance.signOut();
                if (context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const AuthWrapper()),
                    (route) => false,
                  );
                }
              }
            },
            icon: const Icon(Icons.exit_to_app, color: Colors.red),
          ),
        ],
        title: _isAdmin
            ? null
            : Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Welcome back,',
                          style: TextStyle(color: Colors.black54, fontSize: 14),
                        ),
                        Text(
                          widget.userName.isEmpty ? 'Guest Name' : widget.userName,
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _HotelCard(),
            const SizedBox(height: 16),

            const Text(
              'Need Something?',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _ServiceTile(
                    icon: Icons.room_service,
                    label: 'Room Service',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const RoomServiceScreen()),
                      ).then((_) => setState(() {}));
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ServiceTile(
                    icon: Icons.cleaning_services,
                    label: 'Housekeeping',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const HousekeepingScreen()),
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "What's On Today",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const EventsActivitiesScreen()),
                    );
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.black87,
                    padding: EdgeInsets.zero,
                  ),
                  child: const Row(
                    children: [
                      Text('All Events'),
                      SizedBox(width: 4),
                      Icon(Icons.chevron_right, size: 20),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 120,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: const [
                  _EventCard(title: 'Live Jazz Night', subtitle: 'Lounge Bar • 8:00 PM'),
                  SizedBox(width: 12),
                  _EventCard(title: 'Sunset Happy Hour', subtitle: 'Rooftop Pool • 5:00 PM'),
                  SizedBox(width: 12),
                  _EventCard(title: 'Movie Night', subtitle: 'Garden • 9:00 PM'),
                ],
              ),
            ),
            const SizedBox(height: 20),

            const Text(
              'Spending Summary',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            const _SpendingCard(),
            const SizedBox(height: 24),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: SizedBox(
        height: 52,
        width: 52,
        child: FloatingActionButton(
          onPressed: () {},
          backgroundColor: Colors.red,
          elevation: 4,
          child: const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 26),
        ),
      ),
      bottomNavigationBar: _CustomBottomBar(
        onTap: (item) {
          if (item == _BottomItem.services) {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ServiceScreen()),
            );
          } else if (item == _BottomItem.profile) {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            );
          }
        },
      ),
    );
  }
}

/// Otel Bilgi Kartı
///
/// Kullanıcının konakladığı otel adı, oda numarası ve tarih aralığını gösterir.
/// Ayrıca kapı kilit açma (Unlock) butonu burada bulunur.
class _HotelCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 4)),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(
              'assets/images/arkaplan.jpg',
              width: 60,
              height: 60,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('GrandHyatt Hotel', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                SizedBox(height: 4),
                Text('Room 1204', style: TextStyle(color: Colors.black54)),
                Text('Nov 10 - Nov 15', style: TextStyle(color: Colors.black54)),
              ],
            ),
          ),
          // Kapı Açma Düğmesi (Unlock Button)
          ElevatedButton(
            onPressed: () {
              // Kapı açma/kilidi açma işlemini buraya ekleyin
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0057FF), 
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              foregroundColor: Colors.white, 
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.meeting_room, size: 20), // Kapı açma simgesi
                SizedBox(width: 8), 
                Text('Unlock',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ServiceTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  const _ServiceTile({required this.icon, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 90,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 4))],
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.blueAccent),
              const SizedBox(height: 8),
              Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  final String title;
  final String subtitle;
  const _EventCard({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), bottomLeft: Radius.circular(16)),
            child: Image.asset(
              'assets/images/arkaplanyok1.png',
              width: 90,
              height: 120,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(color: Colors.black54, fontSize: 12)),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}

class _SpendingCard extends StatelessWidget {
  const _SpendingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Current Balance', style: TextStyle(color: Colors.black54)),
                const SizedBox(height: 6),
                StreamBuilder<double>(
                  stream: DatabaseService().getTotalSpending(), // Veritabanını dinle
                  builder: (context, snapshot) {
                    // Veri gelene kadar ... göster veya 0.00 göster
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Text(
                        '\$0.00',
                        style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
                      );
                    }

                    double total = snapshot.data ?? 0.0;

                    return Text(
                      '\$${total.toStringAsFixed(2)}', // Gelen veriyi yazdır
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
                    );
                  },
                ),
              ],
            ),
          ),
          // Fatura Görüntüleme Düğmesi
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const PaymentScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0057FF),
              foregroundColor: Colors.white, // Metin ve simge rengi
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), // Daha kompakt hale getirildi
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              minimumSize: Size.zero, // Minimum boyutu sıfırla
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.receipt_long, size: 18), // Makbuz/Fatura simgesi
                SizedBox(width: 6), 
                Text(
                  'View Detailed Bill',
                  style: TextStyle(
                    fontSize: 14, 
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

enum _BottomItem { home, theme, services, profile }

/// Özel Alt Navigasyon Çubuğu (Custom Bottom Bar)
///
/// Saydam (yarı opak) ve blur efektli bir görünüme sahiptir.
class _CustomBottomBar extends StatelessWidget {
  final ValueChanged<_BottomItem>? onTap;
  const _CustomBottomBar({this.onTap});

  @override
  Widget build(BuildContext context) {
    const labelStyle = TextStyle(fontSize: 11, color: Colors.black87, height: 1.1);
    
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
        child: BottomAppBar(
          color: Colors.white.withOpacity(0.9), 
          surfaceTintColor: Colors.transparent,
          elevation: 0, 
          shape: const CircularNotchedRectangle(),
          notchMargin: 10,
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: 56,
              child: Row(
                children: [
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _BottomBarItem(
                          icon: Icons.home,
                          label: 'Home',
                          labelStyle: labelStyle.copyWith(color: const Color(0xFF0057FF), fontWeight: FontWeight.bold),
                          onTap: () => onTap?.call(_BottomItem.home),
                        ),
                        _BottomBarItem(
                          icon: Icons.brightness_6,
                          label: 'Theme',
                          labelStyle: labelStyle,
                          onTap: () => onTap?.call(_BottomItem.theme),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 68),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _BottomBarItem(
                          icon: Icons.apps,
                          label: 'Services',
                          labelStyle: labelStyle,
                          onTap: () => onTap?.call(_BottomItem.services),
                        ),
                        _BottomBarItem(
                          icon: Icons.person,
                          label: 'Profile',
                          labelStyle: labelStyle,
                          onTap: () => onTap?.call(_BottomItem.profile),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BottomBarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final TextStyle labelStyle;
  final VoidCallback onTap;
  const _BottomBarItem({
    required this.icon,
    required this.label,
    required this.labelStyle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isHome = icon == Icons.home;
    final iconColor = isHome ? const Color(0xFF0057FF) : Colors.black87;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: iconColor, size: 26), 
            const SizedBox(height: 2),
            Text(label, style: labelStyle.copyWith(color: iconColor)), 
          ],
        ),
      ),
    );
  }
}
