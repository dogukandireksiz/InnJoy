import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/service_screen.dart';
import '../events_activities/events_activities_screen.dart';
import '../payment/payment_screen.dart';
import '../room_service/room_service_screen.dart';
import '../housekeeping/housekeeping_screen.dart';

class HomeScreen extends StatefulWidget {
  final String userName;
  const HomeScreen({super.key, required this.userName});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFF6F7FB),
        scrolledUnderElevation: 0,
        titleSpacing: 0,
        actions: [
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
            _SpendingCard(),
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
          }
        },
      ),
    );
  }
}

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
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1677FF),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Unlock'),
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
                Text('\$${SpendingData.totalBalance.toStringAsFixed(2)}', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const PaymentScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1677FF),
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('View Detailed Bill'),
          ),
        ],
      ),
    );
  }
}

enum _BottomItem { home, theme, services, profile }

class _CustomBottomBar extends StatelessWidget {
  final ValueChanged<_BottomItem>? onTap;
  const _CustomBottomBar({this.onTap});

  @override
  Widget build(BuildContext context) {
    const labelStyle = TextStyle(fontSize: 11, color: Colors.black87, height: 1.1);
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      elevation: 8,
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
                      labelStyle: labelStyle,
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.black87, size: 22),
            const SizedBox(height: 2),
            Text(label, style: labelStyle),
          ],
        ),
      ),
    );
  }
}
