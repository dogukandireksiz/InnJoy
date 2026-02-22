import 'package:flutter/material.dart';
import 'room_service_menu_management_screen.dart';
import 'room_service_orders_screen.dart'; // We will create this
// import 'room_service_settings_screen.dart';
import '../../../utils/responsive_utils.dart';

class RoomServiceManagementScreen extends StatelessWidget {
  final String hotelName;

  const RoomServiceManagementScreen({super.key, required this.hotelName});

  @override
  Widget build(BuildContext context) {
    // Colors from the design
    const primaryColor = Color(0xFF137fec);


    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF6F7FB),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: Padding(
          padding: EdgeInsets.only(left: 16.0),
          child: Center(
            child: InkWell(
              onTap: () => Navigator.of(context).pop(),
              borderRadius: BorderRadius.circular(ResponsiveUtils.spacing(context, 24)),
              child: Container(
                width: ResponsiveUtils.wp(context, 48 / 375),
                height: ResponsiveUtils.hp(context, 48 / 844),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.arrow_back,
                  color: Color(0xFF0d141b),
                  size: ResponsiveUtils.iconSize(context) * (24 / 24),
                ),
              ),
            ),
          ),
        ),
        centerTitle: true,
        title: Text(
          'Room Service Management',
          style: TextStyle(
            color: Color(0xFF0d141b),
            fontSize: ResponsiveUtils.sp(context, 18),
            fontWeight: FontWeight.bold,
            letterSpacing: -0.015,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: ResponsiveUtils.spacing(context, 16.0), vertical: ResponsiveUtils.spacing(context, 8.0)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: ResponsiveUtils.spacing(context, 20)),

              Text(
                'Service Operations',
                style: TextStyle(
                  color: Color(0xFF0d141b),
                  fontSize: ResponsiveUtils.sp(context, 24),
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),

              SizedBox(height: ResponsiveUtils.spacing(context, 8)),

              Text(
                'Manage menus and track incoming orders.',
                style: TextStyle(
                  color: Color(0xFF4c739a),
                  fontSize: ResponsiveUtils.sp(context, 16),
                  fontWeight: FontWeight.normal,
                ),
              ),

              SizedBox(height: ResponsiveUtils.spacing(context, 24)),

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
                  SizedBox(height: ResponsiveUtils.spacing(context, 16)),
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

              SizedBox(height: ResponsiveUtils.spacing(context, 40)),
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
        borderRadius: BorderRadius.circular(ResponsiveUtils.spacing(context, 16)),
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
        borderRadius: BorderRadius.circular(ResponsiveUtils.spacing(context, 16)),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(ResponsiveUtils.spacing(context, 16)),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: ResponsiveUtils.spacing(context, 16), vertical: ResponsiveUtils.spacing(context, 32)),
            child: Column(
              children: [
                Container(
                  width: ResponsiveUtils.wp(context, 64 / 375),
                  height: ResponsiveUtils.hp(context, 64 / 844),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(ResponsiveUtils.spacing(context, 16)),
                  ),
                  child: Icon(icon, color: primaryColor, size: ResponsiveUtils.iconSize(context) * (32 / 24)),
                ),
                SizedBox(height: ResponsiveUtils.spacing(context, 16)),
                Text(
                  title,
                  style: TextStyle(
                    color: Color(0xFF0d141b),
                    fontSize: ResponsiveUtils.sp(context, 18),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: ResponsiveUtils.spacing(context, 8)),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Color(0xFF4c739a),
                    fontSize: ResponsiveUtils.sp(context, 14),
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












