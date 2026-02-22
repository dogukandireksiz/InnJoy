import 'package:flutter/material.dart';
import '../events_activities/admin_events_screen.dart';
import '../services/spa_wellness/spa_management_screen.dart';
import '../services/fitness/details/fitness_details_screen.dart';
import '../admin/restaurant/restaurant_management_screen.dart';
import '../admin/room_service/room_service_management_screen.dart';
import '../admin/admin_housekeeping_screen.dart';
import '../admin/admin_room_management_screen.dart';
import '../admin/admin_requests_screen.dart';
import '../../utils/responsive_utils.dart';

class ChoseEditScreen extends StatelessWidget {
  final String? hotelName;
  const ChoseEditScreen({super.key, this.hotelName});

  @override
  Widget build(BuildContext context) {
    final items = [
      _EditItem(
        icon: Icons.room_service,
        title: 'Room Service',
        subtitle: 'Edit Menu',
        color: const Color(0xFFFFA726), // Orange 400
        routeBuilder: (ctx) => RoomServiceManagementScreen(hotelName: hotelName ?? 'Innjoy'),
      ),
      _EditItem(
        icon: Icons.restaurant,
        title: 'Restaurant',
        subtitle: 'Dining & Bar',
        color: const Color(0xFF66BB6A), // Green 400
        routeBuilder: (ctx) => RestaurantManagementScreen(hotelName: hotelName ?? 'Innjoy'),
      ),
      _EditItem(
        icon: Icons.event,
        title: 'Events',
        subtitle: 'Event Management',
        color: const Color(0xFF5C6BC0), // Indigo 400
        routeBuilder: (ctx) => AdminEventsScreen(hotelName: hotelName ?? 'Innjoy'),
      ),
      _EditItem(
        icon: Icons.spa,
        title: 'Spa & Wellness',
        subtitle: 'Appointments',
        color: const Color(0xFFEC407A), // Pink 400
        routeBuilder: (ctx) => SpaManagementScreen(hotelName: hotelName ?? 'Innjoy'),
      ),
      _EditItem(
        icon: Icons.fitness_center,
        title: 'Fitness',
        subtitle: 'Gym & Facilities',
        color: const Color(0xFFEF5350), // Red 400
        routeBuilder: (ctx) => FitnessDetailsScreen(hotelName: hotelName ?? 'Innjoy'),
      ),
      _EditItem(
        icon: Icons.cleaning_services,
        title: 'Housekeeping',
        subtitle: 'Staff & Tasks',
        color: const Color(0xFF26C6DA), // Cyan 400
        routeBuilder: (ctx) => AdminHousekeepingScreen(hotelName: hotelName ?? 'Innjoy'),
      ),
      _EditItem(
        icon: Icons.bed,
        title: 'Rooms',
        subtitle: 'Manage Availability',
        color: const Color(0xFF42A5F5), // Blue 400
        routeBuilder: (ctx) => AdminRoomManagementScreen(hotelName: hotelName ?? 'Innjoy'),
      ),
      _EditItem(
        icon: Icons.inbox,
        title: 'Requests',
        subtitle: 'Guest Inquiries',
        color: const Color(0xFF7E57C2), // Deep Purple 400
        routeBuilder: (ctx) => AdminRequestsScreen(hotelName: hotelName ?? 'Innjoy'),
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6), // Matches admin background
      appBar: AppBar(
        title: const Text('Edit Categories'),
        centerTitle: true,
        backgroundColor: const Color(0xFFF3F4F6),
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: Padding(
        padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select an area to update',
              style: TextStyle(fontSize: ResponsiveUtils.sp(context, 18), fontWeight: FontWeight.w700),
            ),
            SizedBox(height: ResponsiveUtils.spacing(context, 6)),
            Text(
              'Choose a category below to manage.',
              style: TextStyle(color: Colors.black54),
            ),
            SizedBox(height: ResponsiveUtils.spacing(context, 20)),
            Expanded(
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: ResponsiveUtils.spacing(context, 16),
                  mainAxisSpacing: ResponsiveUtils.spacing(context, 16),
                  childAspectRatio: 1.1, // Adjusted aspect ratio
                ),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  return _EditCard(
                    icon: item.icon,
                    title: item.title,
                    subtitle: item.subtitle,
                    color: item.color,
                    onTap: () {
                      if (item.routeBuilder != null) {
                        Navigator.push(context, MaterialPageRoute(builder: item.routeBuilder!));
                      }
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final WidgetBuilder? routeBuilder;

  _EditItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    this.routeBuilder,
  });
}

class _EditCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback? onTap;

  const _EditCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 20)),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(ResponsiveUtils.spacing(context, 20)),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [
             BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          // Removed MainAxisAlignment.center to ensure top alignment like Quick Access
          children: [
            Container(
              width: ResponsiveUtils.wp(context, 40 / 375),
              height: ResponsiveUtils.hp(context, 40 / 844),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(ResponsiveUtils.spacing(context, 20)),
              ),
              child: Icon(icon, color: color, size: ResponsiveUtils.iconSize(context) * (22 / 24)),
            ),
            SizedBox(height: ResponsiveUtils.spacing(context, 16)), // Changed from 12 to 16 to match Quick Access
            Text(
              title,
              style: TextStyle(
                fontSize: ResponsiveUtils.sp(context, 15),
                fontWeight: FontWeight.bold,
                color: Color(0xFF111827),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: ResponsiveUtils.spacing(context, 2)), // Changed from 4 to 2 to match Quick Access
            Text(
              subtitle,
              style: TextStyle(
                fontSize: ResponsiveUtils.sp(context, 12),
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}









