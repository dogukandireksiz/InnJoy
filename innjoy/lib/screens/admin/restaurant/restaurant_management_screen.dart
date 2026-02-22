import 'package:flutter/material.dart';
import 'menu_management_screen.dart';
import 'restaurant_settings_screen.dart';
import 'admin_restaurant_reservations_screen.dart';
import '../../../services/database_service.dart';
import '../../../utils/responsive_utils.dart';

class RestaurantManagementScreen extends StatelessWidget {
  final String hotelName;

  const RestaurantManagementScreen({super.key, required this.hotelName});

  @override
  Widget build(BuildContext context) {
    // Colors from the design
    const primaryColor = Color(0xFF137fec);

    // const backgroundDark = Color(0xFF101922); // Not using dark mode logic explicitly yet, adhering to system theme or light for now as per base file structure

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
                  // color: Colors.transparent, // hover effect handled by InkWell
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
          'Restaurant Management',
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
                'Restaurant Operations',
                style: TextStyle(
                  color: Color(0xFF0d141b),
                  fontSize: ResponsiveUtils.sp(context, 24),
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5, // tight tracking
                ),
              ),

              SizedBox(height: ResponsiveUtils.spacing(context, 8)),

              Text(
                'Select a category to manage menus or reservations.',
                style: TextStyle(
                  color: Color(0xFF4c739a),
                  fontSize: ResponsiveUtils.sp(context, 16),
                  fontWeight: FontWeight.normal,
                ),
              ),

              SizedBox(height: ResponsiveUtils.spacing(context, 24)),

              // Vertical Cards Column
              StreamBuilder<List<Map<String, dynamic>>>(
                stream: DatabaseService().getRestaurants(hotelName),
                builder: (context, snapshot) {
                  // Fallback: Eğer stream boşsa veya hata varsa Aurora Restaurant'ı göster
                  List<Map<String, dynamic>> restaurants = snapshot.data ?? [];
                  
                  // Eğer restoran listesi boşsa, fallback olarak Aurora Restaurant ekle
                  if (restaurants.isEmpty) {
                    restaurants = [
                      {'id': 'Aurora Restaurant', 'name': 'Aurora Restaurant'}
                    ];
                  }

                  return Column(
                    children: [
                      _MenuCard(
                        icon: Icons.menu_book,
                        title: 'Menus',
                        subtitle: 'Manage food and drink menus',
                        primaryColor: primaryColor,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) =>
                                  MenuManagementScreen(hotelName: hotelName),
                            ),
                          );
                        },
                      ),
                      SizedBox(height: ResponsiveUtils.spacing(context, 16)),
                      _MenuCard(
                        icon: Icons.table_restaurant,
                        title: 'Reservations',
                        subtitle: 'Manage table bookings',
                        primaryColor: primaryColor,
                        onTap: () {
                          // Artık her zaman en az 1 restoran var (fallback sayesinde)
                          if (restaurants.length == 1) {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) =>
                                    AdminRestaurantReservationsScreen(
                                      hotelName: hotelName,
                                      restaurantId: restaurants.first['id'],
                                    ),
                              ),
                            );
                          } else {
                            // Multiple restaurants - show selection dialog
                            showModalBottomSheet(
                              context: context,
                              builder: (_) => Container(
                                padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 16)),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Select Restaurant',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: ResponsiveUtils.sp(context, 18),
                                      ),
                                    ),
                                    SizedBox(height: ResponsiveUtils.spacing(context, 16)),
                                    ...restaurants.map(
                                      (r) => ListTile(
                                        title: Text(r['name'] ?? r['id']),
                                        onTap: () {
                                          Navigator.pop(context);
                                          Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  AdminRestaurantReservationsScreen(
                                                    hotelName: hotelName,
                                                    restaurantId: r['id'],
                                                  ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }
                        },
                      ),
                      SizedBox(height: ResponsiveUtils.spacing(context, 16)),
                      _MenuCard(
                        icon: Icons.store,
                        title: 'Restaurant Settings',
                        subtitle: 'General restaurant configuration',
                        primaryColor: primaryColor,
                        onTap: () {
                          // Artık her zaman en az 1 restoran var (fallback sayesinde)
                          if (restaurants.length == 1) {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => RestaurantSettingsScreen(
                                  hotelName: hotelName,
                                  restaurantId: restaurants.first['id'],
                                ),
                              ),
                            );
                          } else {
                            showModalBottomSheet(
                              context: context,
                              builder: (_) => Container(
                                padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 16)),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Select Restaurant',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: ResponsiveUtils.sp(context, 18),
                                      ),
                                    ),
                                    SizedBox(height: ResponsiveUtils.spacing(context, 16)),
                                    ...restaurants.map(
                                      (r) => ListTile(
                                        title: Text(r['name'] ?? r['id']),
                                        onTap: () {
                                          Navigator.pop(context);
                                          Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  RestaurantSettingsScreen(
                                                    hotelName: hotelName,
                                                    restaurantId:
                                                        r['id'], // Use ID from DB
                                                  ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  );
                },
              ),


              SizedBox(height: ResponsiveUtils.spacing(context, 40)),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color primaryColor;
  final VoidCallback onTap;

  const _MenuCard({
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
        borderRadius: BorderRadius.circular(ResponsiveUtils.spacing(context, 16)), // Rounded-2xl approx
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











