import 'package:flutter/material.dart';
import '../services/spa_wellness/spa_management_screen.dart';
import '../services/fitness/details/fitness_details_screen.dart';
import '../../utils/responsive_utils.dart';

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
        padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 16)),
        children: [
          Text(
            'Select a service to update',
            style: TextStyle(fontSize: ResponsiveUtils.sp(context, 18), fontWeight: FontWeight.w700),
          ),
          SizedBox(height: ResponsiveUtils.spacing(context, 6)),
          Text(
            'Choose a specific service category below to manage details and operations.',
            style: TextStyle(color: Colors.black54),
          ),
          SizedBox(height: ResponsiveUtils.spacing(context, 16)),
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
          SizedBox(height: ResponsiveUtils.spacing(context, 10)),
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
      borderRadius: BorderRadius.circular(ResponsiveUtils.spacing(context, 16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(ResponsiveUtils.spacing(context, 16)),
        onTap: () => onTap?.call(context),
        child: Padding(
          padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 14)),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 10)),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(ResponsiveUtils.spacing(context, 12)),
                ),
                child: Icon(icon, color: Colors.blue),
              ),
              SizedBox(width: ResponsiveUtils.spacing(context, 12)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(fontSize: ResponsiveUtils.sp(context, 16), fontWeight: FontWeight.w600)),
                    SizedBox(height: ResponsiveUtils.spacing(context, 4)),
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









