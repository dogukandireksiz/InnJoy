import 'package:flutter/material.dart';
import 'restaurant_menus_screen.dart';

class ChoseRestourantScreen extends StatelessWidget {
  const ChoseRestourantScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        title: const Text('Restaurant Management'),
        centerTitle: true,
        backgroundColor: const Color(0xFFF6F7FB),
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Restaurant Operations',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          const Text(
            'Select a category to manage menus or reservations.',
            style: TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _RestaurantTile(
                  icon: Icons.menu_book,
                  iconBg: const Color(0xFFE6F0FF),
                  iconColor: const Color(0xFF2A7AF4),
                  title: 'Menus',
                  subtitle: 'Manage food and\ndrink menus',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const RestaurantMenusScreen(),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _RestaurantTile(
                  icon: Icons.table_bar,
                  iconBg: const Color(0xFFE6F0FF),
                  iconColor: const Color(0xFF2A7AF4),
                  title: 'Reservations',
                  subtitle: 'Manage table\nbookings',
                  onTap: () {
                    // TODO: Navigate to Reservations management screen when available
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RestaurantTile extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  const _RestaurantTile({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 28),
              ),
              const SizedBox(height: 14),
              Text(
                title,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: const TextStyle(color: Colors.black54),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
