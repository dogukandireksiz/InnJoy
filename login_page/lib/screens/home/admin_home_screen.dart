import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'pre_trip_screen.dart';
import '../events_activities/admin_events_screen.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  final user = FirebaseAuth.instance.currentUser;

  String get userName {
    if (user?.displayName != null && user!.displayName!.isNotEmpty) {
      return user!.displayName!;
    }
    if (user?.email != null) {
      return user!.email!.split('@').first;
    }
    return 'Admin';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFF6F7FB),
        scrolledUnderElevation: 0,
        titleSpacing: 0,
        leading: IconButton(
          onPressed: () {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) => PreTripScreen(userName: userName),
              ),
            );
          },
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          tooltip: 'Geri Dön',
        ),
        actions: [
          // Admin badge
          Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.admin_panel_settings, color: Colors.orange, size: 16),
                SizedBox(width: 4),
                Text(
                  'Admin',
                  style: TextStyle(
                    color: Colors.orange,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () async {
              final shouldLogout = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Çıkış Yap'),
                  content: const Text('Çıkmak istediğinize emin misiniz?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('İptal'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                      child: const Text('Çıkış Yap'),
                    ),
                  ],
                ),
              );
              if (shouldLogout == true) {
                await FirebaseAuth.instance.signOut();
              }
            },
            icon: const Icon(Icons.exit_to_app, color: Colors.red),
          ),
        ],
        title: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Yönetici Paneli',
                style: TextStyle(color: Colors.black54, fontSize: 14),
              ),
              Text(
                userName,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
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
            // Otel Bilgi Kartı
            _AdminHotelCard(),
            const SizedBox(height: 20),

            // Hızlı İstatistikler
            const Text(
              'Bugünkü Özet',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    icon: Icons.people,
                    label: 'Aktif Misafir',
                    value: '24',
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    icon: Icons.room_service,
                    label: 'Bekleyen Sipariş',
                    value: '7',
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    icon: Icons.cleaning_services,
                    label: 'Temizlik Talebi',
                    value: '3',
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    icon: Icons.spa,
                    label: 'Spa Randevu',
                    value: '5',
                    color: Colors.purple,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Yönetim Butonları
            const Text(
              'Otel Yönetimi',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _AdminServiceTile(
                    icon: Icons.room_service,
                    label: 'Room Service',
                    subtitle: 'Menü Düzenle',
                    onTap: () {
                      _showComingSoonDialog(context, 'Room Service Yönetimi');
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _AdminServiceTile(
                    icon: Icons.cleaning_services,
                    label: 'Housekeeping',
                    subtitle: 'Talepleri Gör',
                    onTap: () {
                      _showComingSoonDialog(context, 'Housekeeping Yönetimi');
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _AdminServiceTile(
                    icon: Icons.restaurant,
                    label: 'Dining',
                    subtitle: 'Restoran & Bar',
                    onTap: () {
                      _showComingSoonDialog(context, 'Dining Yönetimi');
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _AdminServiceTile(
                    icon: Icons.spa,
                    label: 'Spa & Wellness',
                    subtitle: 'Randevular',
                    onTap: () {
                      _showComingSoonDialog(context, 'Spa Yönetimi');
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _AdminServiceTile(
                    icon: Icons.event,
                    label: 'Events',
                    subtitle: 'Etkinlik Yönetimi',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AdminEventsScreen(),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _AdminServiceTile(
                    icon: Icons.fitness_center,
                    label: 'Fitness',
                    subtitle: 'Sınıf Yönetimi',
                    onTap: () {
                      _showComingSoonDialog(context, 'Fitness Yönetimi');
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Son Aktiviteler
            const Text(
              'Son Aktiviteler',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            _ActivityCard(
              icon: Icons.room_service,
              title: 'Yeni Sipariş - Oda 1204',
              subtitle: 'Kahvaltı Menüsü',
              time: '5 dk önce',
              color: Colors.blue,
            ),
            _ActivityCard(
              icon: Icons.cleaning_services,
              title: 'Temizlik Talebi - Oda 1105',
              subtitle: 'Havlu değişimi',
              time: '12 dk önce',
              color: Colors.green,
            ),
            _ActivityCard(
              icon: Icons.spa,
              title: 'Spa Randevusu - Oda 1302',
              subtitle: 'İsveç Masajı - 14:00',
              time: '25 dk önce',
              color: Colors.purple,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
      bottomNavigationBar: _AdminBottomBar(
        onTap: (item) {
          switch (item) {
            case _AdminBottomItem.dashboard:
              // Zaten buradayız
              break;
            case _AdminBottomItem.orders:
              _showComingSoonDialog(context, 'Siparişler');
              break;
            case _AdminBottomItem.guests:
              _showComingSoonDialog(context, 'Misafirler');
              break;
            case _AdminBottomItem.settings:
              _showComingSoonDialog(context, 'Ayarlar');
              break;
          }
        },
      ),
    );
  }

  void _showComingSoonDialog(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature - Backend entegrasyonu bekleniyor'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.orange,
      ),
    );
  }
}

// Otel Bilgi Kartı
class _AdminHotelCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFF1E3A5F), Color(0xFF2E5077)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E3A5F).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -20,
            child: Icon(
              Icons.hotel,
              size: 120,
              color: Colors.white.withOpacity(0.1),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.business,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Grand Hayat Otel',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Dogukan Direksiz',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _HotelInfoItem(
                      icon: Icons.king_bed,
                      label: 'Toplam Oda',
                      value: '48',
                    ),
                    _HotelInfoItem(
                      icon: Icons.people,
                      label: 'Dolu',
                      value: '32',
                    ),
                    _HotelInfoItem(
                      icon: Icons.event_available,
                      label: 'Müsait',
                      value: '16',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HotelInfoItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _HotelInfoItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white60,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

// İstatistik Kartı
class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
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

// Admin Servis Tile
class _AdminServiceTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback? onTap;

  const _AdminServiceTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: Colors.orange, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Aktivite Kartı
class _ActivityCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String time;
  final Color color;

  const _ActivityCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.time,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
          Text(
            time,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[400],
            ),
          ),
        ],
      ),
    );
  }
}

// Admin Bottom Bar
enum _AdminBottomItem { dashboard, orders, guests, settings }

class _AdminBottomBar extends StatelessWidget {
  final ValueChanged<_AdminBottomItem>? onTap;
  const _AdminBottomBar({this.onTap});

  @override
  Widget build(BuildContext context) {
    const labelStyle = TextStyle(fontSize: 10, color: Colors.black87, height: 1.1);
    return BottomAppBar(
      elevation: 8,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 56,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _AdminBottomBarItem(
                icon: Icons.dashboard,
                label: 'Dashboard',
                labelStyle: labelStyle,
                isActive: true,
                onTap: () => onTap?.call(_AdminBottomItem.dashboard),
              ),
              _AdminBottomBarItem(
                icon: Icons.receipt_long,
                label: 'Siparişler',
                labelStyle: labelStyle,
                onTap: () => onTap?.call(_AdminBottomItem.orders),
              ),
              _AdminBottomBarItem(
                icon: Icons.people,
                label: 'Misafirler',
                labelStyle: labelStyle,
                onTap: () => onTap?.call(_AdminBottomItem.guests),
              ),
              _AdminBottomBarItem(
                icon: Icons.settings,
                label: 'Ayarlar',
                labelStyle: labelStyle,
                onTap: () => onTap?.call(_AdminBottomItem.settings),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdminBottomBarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final TextStyle labelStyle;
  final VoidCallback onTap;
  final bool isActive;

  const _AdminBottomBarItem({
    required this.icon,
    required this.label,
    required this.labelStyle,
    required this.onTap,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive ? Colors.orange : Colors.black87,
              size: 22,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: labelStyle.copyWith(
                color: isActive ? Colors.orange : Colors.black87,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}