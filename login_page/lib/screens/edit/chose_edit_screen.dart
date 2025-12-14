import 'package:flutter/material.dart';
import '../events_activities/admin_events_screen.dart';
import 'chose_services_screen.dart';
import '../restourant/chose_restourant_screen.dart';

class ChoseEditScreen extends StatelessWidget {
  final String? hotelName;
  const ChoseEditScreen({super.key, this.hotelName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        title: const Text('Edit Categories'),
        centerTitle: true,
        backgroundColor: const Color(0xFFF6F7FB),
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Select an area to update',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 6),
          Text(
            'Choose a category below to manage details and operations.',
            style: TextStyle(color: Colors.black54),
          ),
          SizedBox(height: 16),
          _EditTile(
            icon: Icons.miscellaneous_services,
            title: 'Services',
            subtitle: 'General hotel amenities & facilities',
            routeBuilder: (ctx) => const ChoseServicesScreen(),
          ),
          SizedBox(height: 10),
          _EditTile(
            icon: Icons.room_service,
            title: 'Room Services',
            subtitle: 'In-room dining & requests',
          ),
          SizedBox(height: 10),
          _EditTile(
            icon: Icons.event,
            title: 'Events',
            subtitle: 'Conferences, weddings & meetings',
            routeBuilder: (ctx) => AdminEventsScreen(hotelName: hotelName ?? 'Innjoy'),
          ),
          SizedBox(height: 10),
          _EditTile(
            icon: Icons.restaurant,
            title: 'Restaurant',
            subtitle: 'Menus, hours & seating',
            routeBuilder: (ctx) => const ChoseRestourantScreen(),
          ),
        ],
      ),
    );
  }
}

class _EditTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final WidgetBuilder? routeBuilder;
  const _EditTile({required this.icon, required this.title, required this.subtitle, this.routeBuilder});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          if (routeBuilder != null) {
            Navigator.push(context, MaterialPageRoute(builder: routeBuilder!));
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.blue),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(subtitle, style: const TextStyle(color: Colors.black54)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.black38),
            ],
          ),
        ),
      ),
    );
  }
}

// Moved Restaurant screens into lib/screens/restourant/ as separate files.
