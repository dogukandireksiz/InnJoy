import 'package:flutter/material.dart';
import 'room_service_menu_management_screen.dart';
import 'room_service_orders_screen.dart'; // We will create this
// import 'room_service_settings_screen.dart'; // Optional

class RoomServiceManagementScreen extends StatelessWidget {
  final String hotelName;

  const RoomServiceManagementScreen({super.key, required this.hotelName});

  @override
  Widget build(BuildContext context) {
    // Colors from the design
    const primaryColor = Color(0xFF137fec);
    const backgroundLight = Color(0xFFf6f7f8);

    return Scaffold(
      backgroundColor: backgroundLight,
      appBar: AppBar(
        backgroundColor: backgroundLight,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: Center(
            child: InkWell(
              onTap: () => Navigator.of(context).pop(),
              borderRadius: BorderRadius.circular(24),
              child: Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_back,
                  color: Color(0xFF0d141b),
                  size: 24,
                ),
              ),
            ),
          ),
        ),
        centerTitle: true,
        title: const Text(
          'Room Service Management',
          style: TextStyle(
            color: Color(0xFF0d141b),
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.015,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),

              const Text(
                'Service Operations',
                style: TextStyle(
                  color: Color(0xFF0d141b),
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'Manage menus and track incoming orders.',
                style: TextStyle(
                  color: Color(0xFF4c739a),
                  fontSize: 16,
                  fontWeight: FontWeight.normal,
                ),
              ),

              const SizedBox(height: 24),

              // Vertical Cards Column
              Column(
                children: [
                  _ServiceCard(
                    icon: Icons.menu_book,
                    title: 'Menu Management',
                    subtitle: 'Edit food & drink items',
                    primaryColor: primaryColor,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) =>
                              RoomServiceMenuManagementScreen(hotelName: hotelName),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  _ServiceCard(
                    icon: Icons.room_service,
                    title: 'Orders',
                    subtitle: 'View and manage active orders',
                    primaryColor: primaryColor,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) =>
                              RoomServiceOrdersScreen(hotelName: hotelName),
                        ),
                      );
                    },
                  ),
                ],
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color primaryColor;
  final VoidCallback onTap;

  const _ServiceCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.primaryColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
            child: Column(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: primaryColor, size: 32),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF0d141b),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFF4c739a),
                    fontSize: 14,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}









