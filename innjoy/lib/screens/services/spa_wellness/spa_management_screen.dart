import 'package:flutter/material.dart';
import '../../../../services/database_service.dart';
import 'spa_form_screen.dart';
import '../../../utils/responsive_utils.dart';

class SpaManagementScreen extends StatefulWidget {
  final String hotelName;

  const SpaManagementScreen({super.key, required this.hotelName});

  @override
  State<SpaManagementScreen> createState() => _SpaManagementScreenState();
}

class _SpaManagementScreenState extends State<SpaManagementScreen> {
  final DatabaseService _dbService = DatabaseService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F8),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: ResponsiveUtils.spacing(context, 16)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: ResponsiveUtils.spacing(context, 20)),
                    Text(
                      'Manage Services',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: ResponsiveUtils.sp(context, 24),
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0d141b),
                        height: ResponsiveUtils.hp(context, 1.2 / 844),
                      ),
                    ),
                    SizedBox(height: ResponsiveUtils.spacing(context, 4)),
                    Text(
                      'Tap the edit icon to manage service details.',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: ResponsiveUtils.sp(context, 14),
                        color: Color(0xFF4c739a),
                        height: ResponsiveUtils.hp(context, 1.5 / 844),
                      ),
                    ),
                    SizedBox(height: ResponsiveUtils.spacing(context, 24)),
                    
                    StreamBuilder<List<Map<String, dynamic>>>(
                      stream: _dbService.getSpaMenu(widget.hotelName),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        final services = snapshot.data ?? [];

                        return GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: ResponsiveUtils.spacing(context, 16),
                            mainAxisSpacing: ResponsiveUtils.spacing(context, 16),
                            childAspectRatio: 0.60,
                          ),
                          itemCount: services.length,
                          itemBuilder: (context, index) {
                            return _buildAdminServiceCard(context, services[index]);
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
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => SpaFormScreen(hotelName: widget.hotelName)),
          );
        },
        backgroundColor: const Color(0xFF137fec),
        child: Icon(Icons.add, color: Colors.white, size: ResponsiveUtils.iconSize(context) * (28 / 24)),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: ResponsiveUtils.spacing(context, 16), vertical: ResponsiveUtils.spacing(context, 12)),
      decoration: const BoxDecoration(
        color: Color(0xFFF6F7F8),
        border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF0d141b)),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Text(
              'Spa Management',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: ResponsiveUtils.sp(context, 18),
                fontWeight: FontWeight.bold,
                color: Color(0xFF0d141b),
              ),
            ),
          ),
          SizedBox(width: ResponsiveUtils.spacing(context, 48)), // Placeholder to keep title centered
        ],
      ),
    );
  }

  Widget _buildAdminServiceCard(BuildContext context, Map<String, dynamic> service) {
    final String name = service['name'] ?? 'Hizmet';
    final String description = service['description'] ?? '';
    final int duration = service['duration'] ?? 60;
    final double price = (service['price'] ?? 0).toDouble();
    final String imageUrl = service['imageUrl'] ?? 'https://via.placeholder.com/300';
    final String docId = service['id'];

    return Container(
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
                        '$duration dk',
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
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SpaFormScreen(
                          hotelName: widget.hotelName,
                          serviceId: docId,
                          initialData: service,
                        ),
                      ),
                    );
                  },
                  child: Container(
                    padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 6)),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.95),
                      shape: BoxShape.circle,
                      boxShadow: [
                         BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 6),
                      ]
                    ),
                    child: Icon(Icons.edit, size: ResponsiveUtils.iconSize(context) * (16 / 24), color: Color(0xFF0d141b)),
                  ),
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
    );
  }
}









