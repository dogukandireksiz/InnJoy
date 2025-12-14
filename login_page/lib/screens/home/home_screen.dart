import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:login_page/screens/emergency/emergency_screen.dart';
import 'dart:ui';
import '../services/service_screen.dart';
import '../events_activities/events_activities_screen.dart';
import '../events_activities/event_details_screen.dart';
import '../payment/payment_screen.dart';
import '../room_service/room_service_screen.dart';
import '../housekeeping/housekeeping_screen.dart';
import '../profile/profile_screen.dart';
import '../../service/database_service.dart';
import '../../utils/custom_dialog.dart';
import 'hotel_selection_screen.dart';
import '../../widgets/auth_wrapper.dart';
import '../../map/map_screen.dart';
import 'admin_home_screen.dart';
import '../payment/payment_detail_screen.dart';
/// Ana Ekran (Home Screen)
///
/// Kullanıcının otel deneyimini yönettiği, hizmetlere, etkinliklere
/// ve fatura detaylarına erişebildiği ana kontrol panelidir.
class HomeScreen extends StatefulWidget {
  final String userName;
  final bool? isAdmin; // Gecikmeyi önlemek için opsiyonel parametre
  final String? hotelName; // Admin Guest View için opsiyonel

  const HomeScreen({
    super.key, 
    required this.userName, 
    this.isAdmin,
    this.hotelName,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late bool _isAdmin;
  String? _hotelName;

  @override
  void initState() {
    super.initState();
    // Eğer parametre geldiyse direkt onu kullan (Gecikme olmaz)
    // Gelmediyse varsayılan false ve asenkron kontrol
    _isAdmin = widget.isAdmin ?? false; 
    _hotelName = widget.hotelName;
    
    // Parametre gelmediyse veya otel adı yoksa kontrol et (User ise)
    if (widget.isAdmin == null || (_hotelName == null && !_isAdmin)) {
      _checkUserRole();
    }
  }

  Future<void> _checkUserRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userData = await DatabaseService().getUserData(user.uid);
      final role = userData?['role'];
      final hotel = userData?['hotelName'];
      if (mounted) {
        setState(() {
          // Eğer admin parametresi geldiyse onu ezme, sadece hotelName al
          if (widget.isAdmin == null) _isAdmin = role == 'admin';
          if (_hotelName == null) _hotelName = hotel;
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
                      MaterialPageRoute(builder: (_) => EventsActivitiesScreen(hotelName: _hotelName ?? 'GrandHyatt Hotel')),
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
              height: 170,
              child: _hotelName == null
                  ? const Center(child: CircularProgressIndicator())
                  : StreamBuilder<List<Map<String, dynamic>>>(
                      stream: DatabaseService().getHotelEvents(_hotelName!),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        if (snapshot.hasError) {
                          return const Center(child: Text("Yüklenemedi"));
                        }

                        final allEvents = snapshot.data ?? [];
                        // Filter published and future events if needed. For now just published.
                        final events = allEvents.where((e) => e['isPublished'] == true).toList();
                        
                        // Sort by date 
                        events.sort((a, b) {
                           final da = (a['date'] as Timestamp?)?.toDate() ?? DateTime(0);
                           final db = (b['date'] as Timestamp?)?.toDate() ?? DateTime(0);
                           return da.compareTo(db);
                        });

                        if (events.isEmpty) {
                          return Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Container(
                               decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(12),
                               ),
                               alignment: Alignment.center,
                               child: const Text(
                                  "Etkinliklerimiz yakında",
                                  style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
                               ),
                            ),
                          );
                        }

                        return ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: events.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 12),
                          itemBuilder: (context, index) {
                            final e = events[index];
                            final title = e['title'] ?? 'Adsız Etkinlik';
                            final time = e['time'] ?? '';
                            final imageAsset = e['imageAsset'];

                            return _EventCard(
                              title: title,
                              subtitle: time,
                              imageAsset: imageAsset,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => EventDetailsScreen(
                                      event: e,
                                      hotelName: _hotelName!,
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        );
                      },
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
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const EmergencyScreen() )
            );
          },
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
          } else if(item == _BottomItem.map){
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const MapScreen())
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
  final String? imageAsset; // Dinamik resim desteği
  final VoidCallback? onTap;

  const _EventCard({
    required this.title, 
    required this.subtitle,
    this.imageAsset,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 160,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12), // rounded-xl equivalent
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))], // shadow-sm
        ),
        clipBehavior: Clip.hardEdge, // Overflow hidden for rounded corners
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          Image.asset(
            imageAsset ?? 'assets/images/arkaplanyok1.png', // Varsayılan resim
            width: double.infinity,
            height: 80, // h-20 equivalent
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                  width: double.infinity, 
                  height: 80, 
                  color: Colors.grey[200],
                  child: const Icon(Icons.broken_image, color: Colors.grey),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.all(10), // p-2.5
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title, 
                  style: const TextStyle(
                    fontWeight: FontWeight.w800, // Daha kalın
                    fontSize: 16, // Daha büyük (was 14)
                    color: Color(0xFF1C1C1E), 
                  ), 
                  maxLines: 1, 
                  overflow: TextOverflow.ellipsis
                ),
                const SizedBox(height: 4), // was 2
                Text(
                  subtitle, 
                  style: TextStyle(
                    color: Colors.grey[700], // Daha okunaklı gri (was 8A8A8E)
                    fontSize: 13, // was 12
                    fontWeight: FontWeight.w500, // Biraz kalınlık
                  ), 
                  maxLines: 1, 
                  overflow: TextOverflow.ellipsis
                ),
              ],
            ),
          )
        ],
      ),
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
                MaterialPageRoute(builder: (_) => const PaymentDetailScreen()),
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

enum _BottomItem { home, map, services, profile }

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
                          icon: Icons.map,
                          label: 'Map',
                          labelStyle: labelStyle,
                          onTap: () => onTap?.call(_BottomItem.map),
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
