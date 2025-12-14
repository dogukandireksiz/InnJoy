import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../service/auth.dart';
import 'home_screen.dart';
import '../../widgets/auth_wrapper.dart';
import '../events_activities/admin_events_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../admin/admin_room_management_screen.dart';
import '../../service/database_service.dart';
import '../services/spa_wellness/spa_admin_placeholder_screen.dart';
import '../edit/chose_edit_screen.dart';

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
      // Alt menü (Odalar/Bildirimler/Ayarlar) kaldırıldı
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFF6F7FB),
        scrolledUnderElevation: 0,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.black87),
          onPressed: () => _openManagementPanel(context),
          tooltip: 'Menü',
        ),
        automaticallyImplyLeading: false, // Otomatik ok işaretini de kapat
        actions: [
          TextButton.icon(
            onPressed: () {
               Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => HomeScreen(
                    userName: userName, // State getter'ını kullan
                    isAdmin: true, 
                    hotelName: _hotelName, 
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

  void _openManagementPanel(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final width = MediaQuery.of(ctx).size.width;
        final panelWidth = width * 0.82; // like a side sheet
        return GestureDetector(
          onTap: () => Navigator.pop(ctx),
          child: Stack(
            children: [
              // Dim background
              Container(color: Colors.black.withOpacity(0.25)),
              // Sheet
              Align(
                alignment: Alignment.centerLeft,
                child: SafeArea(
                  child: Container(
                    width: panelWidth,
                    height: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(20),
                        bottomRight: Radius.circular(20),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 18,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: _ManagementPanel(
                      hotelName: _hotelName ?? 'Innjoy',
                      userName: userName,
                      onNavigate: (route) {
                        // Close panel first
                        Navigator.pop(ctx);
                        // Handle routes
                        switch (route) {
                          case 'dashboard':
                            setState(() => _selectedIndex = 0);
                            break;
                          case 'rooms':
                            if (_hotelName != null) setState(() => _selectedIndex = 1);
                            break;
                          case 'housekeeping':
                            _showComingSoonDialog(context, 'Housekeeping');
                            break;
                          case 'requests':
                            _showComingSoonDialog(context, 'Requests');
                            break;
                          case 'edits':
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => ChoseEditScreen(hotelName: _hotelName ?? 'Innjoy')),
                            );
                            break;
                          case 'emergency':
                            _showComingSoonDialog(context, 'Acil Durumlar');
                            break;
                          case 'settings':
                            _showComingSoonDialog(context, 'Ayarlar');
                            break;
                        }
                      },
                      onSignOut: () async {
                        Navigator.pop(ctx);
                        await Auth().signOut();
                        if (mounted) {
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(builder: (_) => const AuthWrapper()),
                            (route) => false,
                          );
                        }
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
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
            const _OccupancySection(),
            const SizedBox(height: 24),
            // Otel Yönetimi bölümü kaldırıldı
            // Events gösterim bölümü (tek örnek kart)
            const _EventsShowcaseSection(),
            const SizedBox(height: 24),
            // Son Aktiviteler bölümü kaldırıldı
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

// Alt navigasyon bileşenleri kaldırıldı

class _ManagementPanel extends StatelessWidget {
  final String hotelName;
  final String userName;
  final void Function(String route) onNavigate;
  final VoidCallback onSignOut;

  const _ManagementPanel({
    required this.hotelName,
    required this.userName,
    required this.onNavigate,
    required this.onSignOut,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(Icons.apartment, color: Colors.blue),
                  SizedBox(width: 8),
                  Text('Innjoy', style: TextStyle(fontWeight: FontWeight.w700)),
                ],
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF6F7FB),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const CircleAvatar(radius: 18, backgroundColor: Colors.blue, child: Icon(Icons.person, color: Colors.white)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(userName, style: const TextStyle(fontWeight: FontWeight.w600)),
                      const Text('Front Desk Manager', style: TextStyle(color: Colors.black54, fontSize: 12)),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.chevron_right),
                )
              ],
            ),
          ),
          const SizedBox(height: 16),
          _PanelItem(icon: Icons.dashboard_rounded, label: 'Dashboard', selected: true, onTap: () => onNavigate('dashboard')),
          _PanelItem(icon: Icons.bed, label: 'Rooms', onTap: () => onNavigate('rooms')),
          _PanelItem(icon: Icons.cleaning_services, label: 'Housekeeping', onTap: () => onNavigate('housekeeping')),
          _PanelItem(icon: Icons.inbox, label: 'Requests', badge: '3', onTap: () => onNavigate('requests')),
          _PanelItem(icon: Icons.edit, label: 'Edits', onTap: () => onNavigate('edits')),
          _PanelItem(icon: Icons.emergency_share, label: 'Acil Durumlar', onTap: () => onNavigate('emergency')),
          const Spacer(),
          const Divider(),
          _PanelItem(icon: Icons.settings, label: 'Settings', onTap: () => onNavigate('settings')),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: onSignOut,
            icon: const Icon(Icons.logout),
            label: const Text('Sign Out'),
          ),
          const SizedBox(height: 4),
          const Text('v2.4.0 • Innjoy Management', style: TextStyle(color: Colors.black38, fontSize: 11)),
        ],
      ),
    );
  }
}

class _PanelItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? badge;
  final bool selected;
  final VoidCallback onTap;

  const _PanelItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.badge,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: selected ? Colors.blue.withOpacity(0.12) : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: selected ? Colors.blue : Colors.black87),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                  color: Colors.black87,
                ),
              ),
            ),
            if (badge != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(badge!, style: const TextStyle(color: Colors.white, fontSize: 12)),
              ),
          ],
        ),
      ),
    );
  }
}

class _OccupancySection extends StatelessWidget {
  const _OccupancySection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Text('Occupancy', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            _TodayBadge(),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: Offset(0, 4)),
            ],
          ),
          child: Row(
            children: [
              Expanded(child: _DonutOccupancy(percent: 0.85, totalRooms: 124)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  children: const [
                    _StatusItem(color: Colors.green, label: 'Ready', value: '12'),
                    SizedBox(height: 8),
                    _StatusItem(color: Colors.blue, label: 'In Cleaning', value: '5'),
                    SizedBox(height: 8),
                    _StatusItem(color: Colors.red, label: 'Needs Attn', value: '2'),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: const [
            Expanded(child: _MiniStatCard(icon: Icons.login, label: 'Check-ins', value: '14', color: Colors.green)),
            SizedBox(width: 12),
            Expanded(child: _MiniStatCard(icon: Icons.logout, label: 'Check-outs', value: '8', color: Colors.orange)),
          ],
        ),
      ],
    );
  }
}

class _TodayBadge extends StatelessWidget {
  const _TodayBadge();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.calendar_today, size: 14, color: Colors.black54),
          SizedBox(width: 6),
          Text('Today', style: TextStyle(fontSize: 12, color: Colors.black87)),
        ],
      ),
    );
  }
}

class _DonutOccupancy extends StatelessWidget {
  final double percent;
  final int totalRooms;
  const _DonutOccupancy({required this.percent, required this.totalRooms});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          height: 100,
          width: 100,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                height: 100,
                width: 100,
                child: CircularProgressIndicator(
                  value: percent,
                  strokeWidth: 10,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('${(percent * 100).round()}%', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  const Text('OCCUPIED', style: TextStyle(fontSize: 10, color: Colors.black54)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text('Total Rooms: $totalRooms', style: const TextStyle(fontSize: 11, color: Colors.black54)),
      ],
    );
  }
}

class _StatusItem extends StatelessWidget {
  final Color color;
  final String label;
  final String value;
  const _StatusItem({required this.color, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Icon(Icons.circle, color: color, size: 10),
          const SizedBox(width: 10),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 13))),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _MiniStatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _MiniStatCard({required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
              Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
            ]),
          ),
        ],
      ),
    );
  }
}

class _EventsShowcaseSection extends StatelessWidget {
  const _EventsShowcaseSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Bugünün Etkinlikleri',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AdminEventsScreen(hotelName: (context.findAncestorStateOfType<_AdminHomeScreenState>()?._hotelName) ?? ''),
                  ),
                );
              },
              child: const Text('See all'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _EventCard(
          title: 'Morning Yoga Flow',
          location: 'Sky Terrace Deck',
          timeBadge: '10:00',
          image: const AssetImage('assets/images/yoga.jpg'),
        ),
      ],
    );
  }
}

class _EventCard extends StatelessWidget {
  final String title;
  final String location;
  final String timeBadge;
  final ImageProvider image;

  const _EventCard({
    required this.title,
    required this.location,
    required this.timeBadge,
    required this.image,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Image(
                    image: image,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Positioned(
                right: 12,
                top: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 6, offset: const Offset(0, 2)),
                    ],
                  ),
                  child: Text(
                    timeBadge,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.place_outlined, size: 16, color: Colors.black54),
                    const SizedBox(width: 6),
                    Text(
                      location,
                      style: const TextStyle(fontSize: 12, color: Colors.black54),
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