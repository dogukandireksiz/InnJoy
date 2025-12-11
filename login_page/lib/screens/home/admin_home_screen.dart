import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../service/auth.dart';
import 'home_screen.dart';
import '../../widgets/auth_wrapper.dart';
import '../events_activities/admin_events_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../admin/admin_room_management_screen.dart';
import '../../service/database_service.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  final user = FirebaseAuth.instance.currentUser;
  String? _hotelName;

  @override
  void initState() {
    super.initState();
    _fetchHotelName();
  }

  Future<void> _fetchHotelName() async {
    if (user == null) return;
    final doc = await FirebaseFirestore.instance.collection('users').doc(user!.uid).get();
    if (doc.exists && mounted) {
      setState(() {
        _hotelName = doc.data()?['hotelName'] ?? 'Grand Hayat Otel';
      });
    }
  }

  String get userName {
    if (user?.displayName != null && user!.displayName!.isNotEmpty) {
      return user!.displayName!;
    }
    if (user?.email != null) {
      return user!.email!.split('@').first;
    }
    return 'Admin';
  }

  int _selectedIndex = 0;
  
  void _onItemTapped(int index) {
    if (index == 0) {
      setState(() => _selectedIndex = 0);
    } else if (index == 1) {
      if (_hotelName != null) {
        setState(() => _selectedIndex = 1);
      } else {
        _showComingSoonDialog(context, 'Otel bilgisi yükleniyor...');
      }
    } else {
      _showComingSoonDialog(context, index == 2 ? 'Bildirimler' : 'Ayarlar');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: _selectedIndex == 0 ? _buildAppBar() : null, // Sadece Dashboard'da AppBar göster
      body: _selectedIndex == 0 
          ? _buildDashboard() 
          : AdminRoomManagementScreen(hotelName: _hotelName!),
      bottomNavigationBar: _AdminBottomBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFF6F7FB),
        scrolledUnderElevation: 0,
        titleSpacing: 0,
        leading: null, // Ana ekran olduğu için geri butonu yok
        automaticallyImplyLeading: false, // Otomatik ok işaretini de kapat
        actions: [
          TextButton.icon(
            onPressed: () {
               Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => HomeScreen(
                  userName: userName,
                  isAdmin: true, // Gecikmeyi önlemek için true gönderiyoruz
                ),
                ),
              );
            },
            icon: const Icon(Icons.visibility, color: Colors.blue, size: 20),
            label: const Text(
              'Guest View',
              style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
            ),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
          ),
          Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.admin_panel_settings, color: Colors.orange, size: 18),
                SizedBox(width: 4),
                Text(
                  'Admin Panel',
                  style: TextStyle(
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
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
                await Auth().signOut();
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
      );
  }

  Widget _buildDashboard() {
    return SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _AdminHotelCard(hotelName: _hotelName ?? 'Yükleniyor...'),
            const SizedBox(height: 20),
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
            const Text(
              'Son Aktiviteler',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            // ... Activity cards ... (simplified for brevity if needed, but keeping full for safety)
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
      )
    );
  }

  // Helper method for ActivityCard if I replaced it with something new, but I am keeping existing ones largely.
  // Actually, I should just paste the full Dashboard body content into _buildDashboard


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

class _AdminHotelCard extends StatelessWidget {
  final String hotelName;

  const _AdminHotelCard({required this.hotelName});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final adminName = user?.displayName ?? 'Yönetici';

    return StreamBuilder<Map<String, dynamic>?>(
      stream: DatabaseService().getHotelInfo(hotelName),
      builder: (context, infoSnapshot) {
        int totalRooms = 0;
        
        if (infoSnapshot.hasData && infoSnapshot.data != null) {
            final data = infoSnapshot.data!;
            totalRooms = data['totalRooms'] ?? 0;
        }

        return StreamBuilder<List<Map<String, dynamic>>>(
          stream: DatabaseService().getHotelReservations(hotelName),
          builder: (context, resSnapshot) {
            int occupiedRooms = 0;

            if (resSnapshot.hasData && resSnapshot.data != null) {
              // 'active' veya 'used' statüsündeki rezervasyonlar dolu sayılır
              final reservations = resSnapshot.data!;
              occupiedRooms = reservations.where((r) => r['status'] == 'active' || r['status'] == 'used').length;
            }

            final availableRooms = totalRooms - occupiedRooms;

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
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                hotelName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                adminName,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _HotelInfoItem(
                          label: 'Toplam Oda',
                          value: totalRooms.toString(),
                          icon: Icons.meeting_room,
                        ),
                         _HotelInfoItem(
                          label: 'Dolu',
                          value: occupiedRooms.toString(),
                          icon: Icons.person,
                        ),
                         _HotelInfoItem(
                          label: 'Müsait',
                          value: availableRooms.toString(),
                          icon: Icons.check_circle_outline,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
                ],
              ),
            );
          },
        );
      },
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

enum _AdminBottomItem { dashboard, orders, guests, settings }

class _AdminBottomBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const _AdminBottomBar({
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      color: Colors.white,
      elevation: 10,
      shadowColor: Colors.black12,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _AdminBottomBarItem(
            icon: Icons.dashboard_rounded,
            label: 'Panel',
            labelStyle: const TextStyle(fontSize: 12),
            isActive: currentIndex == 0,
            onTap: () => onTap(0),
          ),
          _AdminBottomBarItem(
            icon: Icons.bed, // Odalar ikonu
            label: 'Odalar',
            labelStyle: const TextStyle(fontSize: 12),
             isActive: currentIndex == 1,
            onTap: () => onTap(1), 
          ),
           _AdminBottomBarItem(
            icon: Icons.notifications,
            label: 'Bildirimler',
            labelStyle: const TextStyle(fontSize: 12),
             isActive: currentIndex == 2,
            onTap: () => onTap(2), 
          ),
           _AdminBottomBarItem(
            icon: Icons.settings,
            label: 'Ayarlar',
            labelStyle: const TextStyle(fontSize: 12),
             isActive: currentIndex == 3,
            onTap: () => onTap(3), 
          ),
        ],
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