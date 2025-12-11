import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../service/database_service.dart';

class EventDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> event;
  final String hotelName;

  const EventDetailsScreen({
    super.key,
    required this.event,
    required this.hotelName, // Required for booking
  });

  @override
  State<EventDetailsScreen> createState() => _EventDetailsScreenState();
}

class _EventDetailsScreenState extends State<EventDetailsScreen> {
  bool _isLoading = false;

  Future<void> _handleBooking() async {
    setState(() => _isLoading = true);

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lütfen önce giriş yapın.')));
      setState(() => _isLoading = false);
      return;
    }

    final eventId = widget.event['id'];
    // Construct user info (In a real app, fetch more details like Name/Room from Profile)
    final userInfo = {
      'userId': user.uid,
      'userName': user.displayName ?? user.email ?? 'Misafir',
      'roomNumber': '101', // Placeholder or fetch from context/profile
    };

    final result = await DatabaseService().registerForEvent(widget.hotelName, eventId, userInfo);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kayıt Başarılı!'), backgroundColor: Colors.green));
    } else {
      if (result['status'] == 'full') {
         _showFullDialog();
      } else if (result['status'] == 'already_registered') {
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Zaten bu etkinliğe kayıtlısınız.'), backgroundColor: Colors.orange));
      } else {
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message'] ?? 'Bir hata oluştu.'), backgroundColor: Colors.red));
      }
    }
  }

  void _showFullDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Kontenjan Dolu', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
        content: const Text(
          'Bu etkinlik yoğun ilgi gördü ve kontenjanımız tamamen doldu. Benzer etkinliklere göz atmak ister misiniz?',
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back to Event List
            },
            child: const Text('Göz At', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Extract data with fallbacks
    final title = widget.event['title'] ?? 'Event Details';
    final imageAsset = widget.event['imageAsset'] ?? 'assets/images/arkaplanyok.png';
    final location = widget.event['location'] ?? 'Location not specified';
    final time = widget.event['time'] ?? 'Time not specified';
    final description = widget.event['description'] ?? 'No description provided.';
    final capacity = widget.event['capacity'] ?? 0;
    final registered = widget.event['registered'] ?? 0;
    
    // Parse Date
    String dateStr = 'Date not specified';
    if (widget.event['date'] != null) {
      if (widget.event['date'] is Timestamp) {
        final d = (widget.event['date'] as Timestamp).toDate();
        dateStr = "${_weekdayName(d.weekday)}, ${_monthName(d.month)} ${d.day}";
      }
    }

    final isFull = capacity > 0 && registered >= capacity;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6), // bg-background-light
      body: Stack(
        children: [
          // Scrollable Content
          SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 100), // Space for bottom button
            child: Column(
              children: [
                const SizedBox(height: kToolbarHeight + 20), 
                
                // Content Container
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      // Image Card
                      Container(
                        height: 256, 
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(32), 
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(32),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.asset(
                                imageAsset,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(color: Colors.grey[300], child: const Icon(Icons.error)),
                              ),
                              if (isFull)
                                Container(color: Colors.grey.withOpacity(0.8)), // Grey out if full
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Info Container
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24), 
                        decoration: BoxDecoration(
                          color: Colors.white, 
                          borderRadius: BorderRadius.circular(16), 
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (isFull)
                              Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.red.shade300),
                                ),
                                child: Text('KONTENJAN DOLU', style: TextStyle(color: Colors.red.shade800, fontWeight: FontWeight.bold)),
                              ),
                            Text(
                              title,
                              style: const TextStyle(
                                fontSize: 24, 
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF111827), 
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            // Date/Time/Loc Rows
                            _InfoRow(icon: Icons.calendar_today, label: 'Date: $dateStr'),
                            const SizedBox(height: 12),
                            _InfoRow(icon: Icons.schedule, label: 'Time: $time'),
                            const SizedBox(height: 12),
                            _InfoRow(icon: Icons.place, label: 'Location: $location'),
                            const SizedBox(height: 12),
                            // Capacity
                            _InfoRow(
                                icon: Icons.people, 
                                label: isFull ? 'Kameriye Dolu' : 'Kontenjan: $registered / $capacity',
                                color: isFull ? Colors.red : null,
                            ),
                            
                            const SizedBox(height: 20),
                            const Divider(color: Color(0xFFE5E7EB)), 
                            const SizedBox(height: 20),
                            
                            const Text(
                              'Description',
                              style: TextStyle(
                                fontSize: 18, 
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF111827),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              description,
                              style: const TextStyle(
                                fontSize: 14, 
                                height: 1.6, 
                                color: Color(0xFF4B5563), 
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
          
          // Fixed Header
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: kToolbarHeight + MediaQuery.of(context).padding.top,
              padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top, left: 8, right: 16),
              color: Colors.white.withOpacity(0.95), 
              child: Row(
                children: [
                   IconButton(
                     icon: const Icon(Icons.arrow_back, color: Color(0xFF1F2937)),
                     onPressed: () => Navigator.of(context).pop(),
                   ),
                   Expanded(
                     child: Text(
                       title,
                       textAlign: TextAlign.center,
                       style: const TextStyle(
                         fontSize: 18,
                         fontWeight: FontWeight.w600,
                         color: Color(0xFF111827),
                       ),
                       overflow: TextOverflow.ellipsis,
                     ),
                   ),
                   const SizedBox(width: 40), 
                ],
              ),
            ),
          ),

          // Fixed Bottom Button
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              color: const Color(0xFFF3F4F6), 
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading 
                      ? null 
                      : () {
                          // Check fullness locally first
                          if (isFull) {
                            _showFullDialog();
                          } else {
                            _handleBooking();
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isFull ? Colors.grey : const Color(0xFF1D8CF8),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(9999), 
                    ),
                    elevation: 4,
                  ),
                  child: _isLoading 
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text(isFull ? 'Kontenjan Dolu' : 'Book Session', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
   
  String _monthName(int m) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[m - 1];
  }
  
  String _weekdayName(int w) {
      const map = {1: 'Monday', 2: 'Tuesday', 3: 'Wednesday', 4: 'Thursday', 5: 'Friday', 6: 'Saturday', 7: 'Sunday'};
      return map[w] ?? '';
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;

  const _InfoRow({required this.icon, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color ?? const Color(0xFF9CA3AF), size: 24), 
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 2.0),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: color ?? const Color(0xFF4B5563), 
              ),
            ),
          ),
        ),
      ],
    );
  }
}
