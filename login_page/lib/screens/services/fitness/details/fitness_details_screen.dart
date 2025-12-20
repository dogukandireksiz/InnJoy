import 'package:flutter/material.dart';
import '../../../../service/database_service.dart';

/// Fitness Center Details Screen
/// 
/// Informational screen displaying fitness center details, 
/// operating hours, equipment, and facility images.
/// No booking or payment functionality.
class FitnessDetailsScreen extends StatelessWidget {
  final String hotelName;

  const FitnessDetailsScreen({super.key, required this.hotelName});

  // Icon mapping from string to IconData
  static const Map<String, IconData> _iconMap = {
    'directions_run': Icons.directions_run,
    'pedal_bike': Icons.pedal_bike,
    'fitness_center': Icons.fitness_center,
    'accessibility_new': Icons.accessibility_new,
    'self_improvement': Icons.self_improvement,
    'water_drop': Icons.water_drop,
    'tv': Icons.tv,
    'air': Icons.air,
  };

  @override
  Widget build(BuildContext context) {
    const bgLight = Color(0xFFF6F7F8);
    final DatabaseService db = DatabaseService();

    return Scaffold(
      backgroundColor: bgLight,
      body: StreamBuilder<Map<String, dynamic>?>(
        stream: db.getFitnessInfo(hotelName),
        builder: (context, snapshot) {
          // Default values
          String title = '24/7 Fitness Center';
          String description = 'Stay fit during your stay with our state-of-the-art fitness center.';
          String imageUrl = 'assets/images/fitness.png';
          Map<String, dynamic> operatingHours = {
            'schedule': 'Monday - Sunday',
            'hours': '24 Hours',
            'staffAvailable': '06:00 - 22:00',
          };
          List<Map<String, dynamic>> equipment = [];
          List<String> gallery = [];
          Map<String, dynamic> location = {
            'floor': 'Ground Floor',
            'description': 'Next to the Pool Area',
          };
          String accessInfo = 'Use your room key to access the fitness center at any time.';

          // Override with Firebase data if available
          if (snapshot.hasData && snapshot.data != null) {
            final data = snapshot.data!;
            title = data['title'] ?? title;
            description = data['description'] ?? description;
            imageUrl = data['imageUrl'] ?? imageUrl;
            
            if (data['operatingHours'] != null) {
              operatingHours = Map<String, dynamic>.from(data['operatingHours']);
            }
            if (data['equipment'] != null) {
              equipment = List<Map<String, dynamic>>.from(
                (data['equipment'] as List).map((e) => Map<String, dynamic>.from(e))
              );
            }
            if (data['gallery'] != null) {
              gallery = List<String>.from(data['gallery']);
            }
            if (data['location'] != null) {
              location = Map<String, dynamic>.from(data['location']);
            }
            accessInfo = data['accessInfo'] ?? accessInfo;
          }

          // Use default equipment if empty
          if (equipment.isEmpty) {
            equipment = [
              {'icon': 'directions_run', 'name': 'Treadmills'},
              {'icon': 'pedal_bike', 'name': 'Exercise Bikes'},
              {'icon': 'fitness_center', 'name': 'Free Weights'},
              {'icon': 'accessibility_new', 'name': 'Weight Machines'},
              {'icon': 'self_improvement', 'name': 'Yoga Mats'},
              {'icon': 'water_drop', 'name': 'Water Station'},
              {'icon': 'tv', 'name': 'Entertainment'},
              {'icon': 'air', 'name': 'Air Conditioning'},
            ];
          }

          // Use default gallery if empty
          if (gallery.isEmpty) {
            gallery = [
              'https://images.unsplash.com/photo-1571902943202-507ec2618e8f?w=400',
              'https://images.unsplash.com/photo-1558611848-73f7eb4001a1?w=400',
              'https://images.unsplash.com/photo-1540497077202-7c8a3999166f?w=400',
            ];
          }

          return CustomScrollView(
            slivers: [
              // Collapsible Hero Header
              SliverAppBar(
                expandedHeight: 250.0,
                floating: false,
                pinned: true,
                backgroundColor: Colors.transparent,
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Hero Image
                      _buildHeaderImage(imageUrl),
                      // Gradient Overlay
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.white.withOpacity(0.5),
                              bgLight,
                            ],
                            stops: const [0.5, 0.8, 1.0],
                          ),
                        ),
                      ),
                      // Title and badge overlay
                      Positioned(
                        left: 16,
                        right: 16,
                        bottom: 16,
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                title,
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF101922),
                                  letterSpacing: -0.5,
                                  height: 1.1,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.green.shade200),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.check_circle, 
                                    color: Colors.green, 
                                    size: 14,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'Open 24/7',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                leading: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.8),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.black),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),

              // Content
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Description
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Operating Hours
                      _buildSection(
                        title: 'Operating Hours',
                        icon: Icons.access_time,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              _InfoRow(
                                label: operatingHours['schedule'] ?? 'Monday - Sunday',
                                value: operatingHours['hours'] ?? '24 Hours',
                                icon: Icons.calendar_today,
                              ),
                              const Divider(height: 20),
                              _InfoRow(
                                label: 'Staff Available',
                                value: operatingHours['staffAvailable'] ?? '06:00 - 22:00',
                                icon: Icons.person,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Equipment & Features
                      _buildSection(
                        title: 'Equipment & Facilities',
                        icon: Icons.fitness_center,
                        child: _buildEquipmentGrid(equipment),
                      ),
                      const SizedBox(height: 24),
                      
                      // Gallery
                      _buildSection(
                        title: 'Gallery',
                        icon: Icons.photo_library,
                        child: _buildGallery(gallery),
                      ),
                      const SizedBox(height: 24),
                      
                      // Location
                      _buildSection(
                        title: 'Location',
                        icon: Icons.location_on,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF137fec).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.directions,
                                  color: Color(0xFF137fec),
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      location['floor'] ?? 'Ground Floor',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF0d141b),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      location['description'] ?? 'Next to the Pool Area',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Access Info
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF137fec).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFF137fec).withOpacity(0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.key,
                              color: Color(0xFF137fec),
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Room Key Access',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF137fec),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    accessInfo,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFF137fec),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeaderImage(String imageUrl) {
    if (imageUrl.startsWith('assets/')) {
      return Image.asset(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          color: Colors.grey[300],
          child: const Icon(Icons.fitness_center, size: 64, color: Colors.grey),
        ),
      );
    }
    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        color: Colors.grey[300],
        child: const Icon(Icons.fitness_center, size: 64, color: Colors.grey),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: const Color(0xFF137fec)),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0d141b),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }

  Widget _buildEquipmentGrid(List<Map<String, dynamic>> equipment) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.9,
      ),
      itemCount: equipment.length,
      itemBuilder: (context, index) {
        final item = equipment[index];
        final iconName = item['icon'] as String? ?? 'fitness_center';
        final iconData = _iconMap[iconName] ?? Icons.fitness_center;
        
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                iconData,
                size: 24,
                color: const Color(0xFF137fec),
              ),
              const SizedBox(height: 6),
              Text(
                item['name'] as String? ?? '',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF0d141b),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGallery(List<String> images) {
    return SizedBox(
      height: 120,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: images.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: AspectRatio(
              aspectRatio: 4 / 3,
              child: Image.network(
                images[index],
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: Colors.grey[300],
                  child: const Icon(Icons.image, color: Colors.grey),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _InfoRow({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF0d141b),
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF137fec).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF137fec),
            ),
          ),
        ),
      ],
    );
  }
}
