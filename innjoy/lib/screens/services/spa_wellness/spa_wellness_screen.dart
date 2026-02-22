import 'package:flutter/material.dart';
import '../../../../services/database_service.dart';
import 'spa_booking_screen.dart';
import '../../../utils/responsive_utils.dart';

class SpaWellnessScreen extends StatefulWidget {
  final String hotelName;

  const SpaWellnessScreen({super.key, required this.hotelName});

  @override
  State<SpaWellnessScreen> createState() => _SpaWellnessScreenState();
}

class _SpaWellnessScreenState extends State<SpaWellnessScreen> {
  final DatabaseService _dbService = DatabaseService();

  @override
  void initState() {
    super.initState();
  }


  @override
  Widget build(BuildContext context) {
    const bgLight = Color(0xFFF6F7F8);

    return Scaffold(
      backgroundColor: bgLight,
      body: CustomScrollView(
        slivers: [
          // Collapsible Hero Header - Menu Screen Style
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
                  Image.asset(
                    'assets/images/spa_service.png',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: Colors.grey[300],
                      child: Icon(
                        Icons.spa,
                        size: ResponsiveUtils.iconSize(context) * (64 / 24),
                        color: Colors.grey,
                      ),
                    ),
                  ),
                  // Gradient Overlay - Fades to background color
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.white.withValues(alpha: 0.5),
                          bgLight,
                        ],
                        stops: const [0.5, 0.8, 1.0],
                      ),
                    ),
                  ),
                  // Title and description overlay
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Spa & Wellness',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: ResponsiveUtils.sp(context, 32),
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF101922),
                            letterSpacing: -0.5,
                            height: ResponsiveUtils.hp(context, 1.1 / 844),
                          ),
                        ),
                        SizedBox(height: ResponsiveUtils.spacing(context, 8)),
                        Text(
                          'Relax, rejuvenate, and restore your balance.',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: ResponsiveUtils.sp(context, 15),
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF475569),
                            height: ResponsiveUtils.hp(context, 1.4 / 844),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            leading: Container(
              margin: EdgeInsets.all(ResponsiveUtils.spacing(context, 8)),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.8),
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
              padding: EdgeInsets.symmetric(horizontal: ResponsiveUtils.spacing(context, 16)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: ResponsiveUtils.spacing(context, 8)),
                  Text(
                    'Our Services',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: ResponsiveUtils.sp(context, 20),
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0d141b),
                    ),
                  ),
                  SizedBox(height: ResponsiveUtils.spacing(context, 16)),
                  
                  
                  // Service Grid
                  StreamBuilder<List<Map<String, dynamic>>>(
                      stream: _dbService.getSpaMenu(widget.hotelName),
                      builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Center(child: Text("Error: ${snapshot.error}"));
                      }

                      final services = snapshot.data ?? [];

                      if (services.isEmpty) {
                        return _buildEmptyState();
                      }

                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: ResponsiveUtils.spacing(context, 16),
                          mainAxisSpacing: ResponsiveUtils.spacing(context, 16),
                          childAspectRatio: 0.68,
                        ),
                        itemCount: services.length,
                        itemBuilder: (context, index) {
                          return _buildServiceCard(context, services[index]);
                        },
                      );
                    },
                  ),
                  SizedBox(height: ResponsiveUtils.spacing(context, 80)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        children: [
          Icon(Icons.spa_outlined, size: ResponsiveUtils.iconSize(context) * (64 / 24), color: Colors.grey[300]),
          SizedBox(height: ResponsiveUtils.spacing(context, 16)),
          Text(
            "No services available yet.",
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceCard(BuildContext context, Map<String, dynamic> service) {
    final String name = service['name'] ?? 'Service';
    final String description = service['description'] ?? '';
    final int duration = service['duration'] ?? 60;
    final double price = (service['price'] ?? 0).toDouble();
    final String imageUrl = service['imageUrl'] ?? 'https://lh3.googleusercontent.com/aida-public/AB6AXuBY-_ub_PyIa9dcHRKEI2sAiXHAwCwaTpicjK69KkjdCu0tVDJs_FjvUSup6a_Sa_O_8Kyi_O8O0qDSWkI2Z__IZV59QUWQ_s3f7nCw1Ie-GMwsDqKuqvE3zF5dzIICfgpw2iMORXKbtPYAQJIpk_oJB9Ixg05_7cAnsddlz6MLGpq0XzOlazr6E5R9748zL0TV_ZqFUj_3XiCkBqIkRZwF-6LvaPR_e_E2DIAa7OXDbDVpSr0CDgMQxmrd9q6zJvYxWZRmkA6-kaQ';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SpaBookingScreen(
              hotelName: widget.hotelName,
              service: service,
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(ResponsiveUtils.spacing(context, 16)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            )
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 4 / 3,
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (ctx, error, stackTrace) => Container(color: Colors.grey[200]),
                  ),
                ),
                // Duration badge
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: ResponsiveUtils.spacing(context, 10), vertical: ResponsiveUtils.spacing(context, 6)),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(ResponsiveUtils.spacing(context, 20)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.access_time, size: ResponsiveUtils.iconSize(context) * (12 / 24), color: Colors.white),
                        SizedBox(width: ResponsiveUtils.spacing(context, 4)),
                        Text(
                          '$duration min',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: ResponsiveUtils.sp(context, 11),
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 6)),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.95),
                      shape: BoxShape.circle,
                      boxShadow: [
                         BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 6),
                      ]
                    ),
                    child: Icon(Icons.arrow_forward, size: ResponsiveUtils.iconSize(context) * (16 / 24), color: Color(0xFF137fec)),
                  ),
                ),
              ],
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 14)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: ResponsiveUtils.sp(context, 15),
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0d141b),
                            height: ResponsiveUtils.hp(context, 1.2 / 844),
                          ),
                        ),
                        if (description.isNotEmpty) ...[
                          SizedBox(height: ResponsiveUtils.spacing(context, 4)),
                          Text(
                            description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: ResponsiveUtils.sp(context, 11),
                              fontWeight: FontWeight.w400,
                              color: Colors.grey[600],
                              height: ResponsiveUtils.hp(context, 1.3 / 844),
                            ),
                          ),
                        ],
                      ],
                    ),
                    // Price section
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: ResponsiveUtils.spacing(context, 10), vertical: ResponsiveUtils.spacing(context, 6)),
                      decoration: BoxDecoration(
                        color: const Color(0xFF137fec).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(ResponsiveUtils.spacing(context, 8)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '₺',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: ResponsiveUtils.sp(context, 14),
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF137fec),
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                          SizedBox(width: ResponsiveUtils.spacing(context, 2)),
                          Text(
                            price.toStringAsFixed(0),
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: ResponsiveUtils.sp(context, 16),
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF137fec),
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}









