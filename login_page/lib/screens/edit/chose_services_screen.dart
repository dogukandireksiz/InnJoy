import 'package:flutter/material.dart';
import '../services/spa_wellness/spa_management_screen.dart';
import '../services/fitness/details/fitness_details_screen.dart';

class ChoseServicesScreen extends StatelessWidget {
  final String hotelName;
  
  const ChoseServicesScreen({super.key, required this.hotelName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        title: const Text('Service Categories'),
        centerTitle: true,
        backgroundColor: const Color(0xFFF6F7FB),
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Select a service to update',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 6),
          Text(
            'Choose a specific service category below to manage details and operations.',
            style: TextStyle(color: Colors.black54),
          ),
          SizedBox(height: 16),
          _ServiceTile(
            icon: Icons.spa,
            title: 'Spa & Wellness',
            subtitle: 'Manage treatments, therapists & schedules',
            onTap: (context) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => SpaManagementScreen(hotelName: hotelName)),
              );
            },
          ),
          SizedBox(height: 10),
          _ServiceTile(
            icon: Icons.fitness_center,
            title: 'Fitness',
            subtitle: 'Manage gym access, equipment & classes',
            onTap: (context) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => FitnessDetailsScreen(hotelName: hotelName)),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ServiceTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final void Function(BuildContext context)? onTap;
  const _ServiceTile({required this.icon, required this.title, required this.subtitle, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => onTap?.call(context),
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
