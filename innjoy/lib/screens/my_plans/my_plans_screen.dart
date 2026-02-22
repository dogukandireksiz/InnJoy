import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:rxdart/rxdart.dart';
import '../../services/database_service.dart';
import '../../utils/responsive_utils.dart';

class MyPlansScreen extends StatefulWidget {
  const MyPlansScreen({super.key});

  @override
  State<MyPlansScreen> createState() => _MyPlansScreenState();
}

class _MyPlansScreenState extends State<MyPlansScreen> {
  final _db = DatabaseService();
  final _userId = FirebaseAuth.instance.currentUser?.uid ?? '';
  String? _hotelName;
  bool _isLoadingHotel = true;

  @override
  void initState() {
    super.initState();
    _fetchUserHotel();
  }

  Future<void> _fetchUserHotel() async {
    if (_userId.isEmpty) {
      setState(() => _isLoadingHotel = false);
      return;
    }
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_userId)
          .get();
      if (userDoc.exists && userDoc.data() != null) {
        setState(() {
          _hotelName = userDoc.data()!['hotelName'];
          _isLoadingHotel = false;
        });
      } else {
        setState(() => _isLoadingHotel = false);
      }
    } catch (e) {
      setState(() => _isLoadingHotel = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        title: Text(
          'My Plans',
          style: TextStyle(
            color: Color(0xFF0d141b),
            fontWeight: FontWeight.bold,
            fontSize: ResponsiveUtils.sp(context, 20),
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: Color(0xFF0d141b), size: ResponsiveUtils.iconSize(context) * (20 / 24)),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isLoadingHotel
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<List<Map<String, dynamic>>>(
        stream: _getCombinedPlans(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}', style: TextStyle(color: Colors.red)),
            );
          }

          final plans = snapshot.data ?? [];

          if (plans.isEmpty) {
            return _buildEmptyState();
          }

          // Group plans by date
          final groupedPlans = _groupPlansByDate(plans);

          return ListView.builder(
            padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 16)),
            itemCount: groupedPlans.length,
            itemBuilder: (context, index) {
              final dateKey = groupedPlans.keys.elementAt(index);
              final dayPlans = groupedPlans[dateKey]!;
              
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date Header
                  Padding(
                    padding: EdgeInsets.only(top: 8, bottom: 12),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: ResponsiveUtils.spacing(context, 12), vertical: ResponsiveUtils.spacing(context, 6)),
                          decoration: BoxDecoration(
                            color: _isToday(dateKey) 
                                ? const Color(0xFF137fec) 
                                : Colors.grey[200],
                            borderRadius: BorderRadius.circular(ResponsiveUtils.spacing(context, 20)),
                          ),
                          child: Text(
                            _formatDateHeader(dateKey),
                            style: TextStyle(
                              fontSize: ResponsiveUtils.sp(context, 13),
                              fontWeight: FontWeight.w600,
                              color: _isToday(dateKey) ? Colors.white : Colors.grey[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Plans for this date
                  ...dayPlans.map((plan) => _buildPlanCard(plan)),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Stream<List<Map<String, dynamic>>> _getCombinedPlans() {
    if (_userId.isEmpty || _hotelName == null || _hotelName!.isEmpty) {
      return Stream.value([]);
    }

    final restaurantStream = _db.getUserReservations(_userId, hotelName: _hotelName);
    final eventStream = _db.getUserEvents(_userId, hotelName: _hotelName);
    final spaStream = _db.getUserSpaAppointments(_userId, hotelName: _hotelName);

    return Rx.combineLatest3(
      restaurantStream,
      eventStream,
      spaStream,
      (List<Map<String, dynamic>> restaurants, 
       List<Map<String, dynamic>> events, 
       List<Map<String, dynamic>> spa) {
        final List<Map<String, dynamic>> allPlans = [];

        // Transform restaurant reservations
        for (final r in restaurants) {
          final date = r['date'];
          if (date == null) continue;
          
          allPlans.add({
            'type': 'restaurant',
            'title': r['restaurantName'] ?? 'Restaurant Reservation',
            'subtitle': '${r['partySize'] ?? 2} guests • Table ${r['tableNumber'] ?? '-'}',
            'date': date is Timestamp ? date.toDate() : DateTime.now(),
            'status': r['status'] ?? 'confirmed',
            'icon': Icons.restaurant,
            'color': const Color(0xFFFF9800),
            'note': r['note'],
          });
        }

        // Transform event registrations
        for (final e in events) {
          final date = e['eventDate'];
          if (date == null) continue;
          
          allPlans.add({
            'type': 'event',
            'title': e['eventTitle'] ?? 'Event',
            'subtitle': e['hotelName'] ?? '',
            'date': date is Timestamp ? date.toDate() : DateTime.now(),
            'status': 'registered',
            'icon': Icons.celebration,
            'color': const Color(0xFF9C27B0),
          });
        }

        // Transform spa appointments
        for (final s in spa) {
          final date = s['appointmentDate'];
          if (date == null) continue;
          
          allPlans.add({
            'type': 'spa',
            'title': s['serviceName'] ?? 'Spa Appointment',
            'subtitle': '${s['timeSlot'] ?? ''} • ${s['duration'] ?? ''}',
            'date': date is Timestamp ? date.toDate() : DateTime.now(),
            'status': s['status'] ?? 'pending',
            'icon': Icons.spa,
            'color': const Color(0xFF009688),
          });
        }

        // Sort by date (ascending - nearest first)
        allPlans.sort((a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime));

        return allPlans;
      },
    );
  }

  Map<String, List<Map<String, dynamic>>> _groupPlansByDate(List<Map<String, dynamic>> plans) {
    final Map<String, List<Map<String, dynamic>>> grouped = {};
    
    for (final plan in plans) {
      final date = plan['date'] as DateTime;
      final key = DateFormat('yyyy-MM-dd').format(date);
      
      if (!grouped.containsKey(key)) {
        grouped[key] = [];
      }
      grouped[key]!.add(plan);
    }
    
    return grouped;
  }

  bool _isToday(String dateKey) {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    return dateKey == today;
  }

  String _formatDateHeader(String dateKey) {
    final date = DateTime.parse(dateKey);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final targetDate = DateTime(date.year, date.month, date.day);

    if (targetDate == today) {
      return 'Today';
    } else if (targetDate == tomorrow) {
      return 'Tomorrow';
    } else {
      return DateFormat('d MMMM, EEEE').format(date);
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 24)),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.event_note_outlined, size: ResponsiveUtils.iconSize(context) * (64 / 24), color: Colors.grey[400]),
          ),
          SizedBox(height: ResponsiveUtils.spacing(context, 24)),
          Text(
            'No plans yet',
            style: TextStyle(
              fontSize: ResponsiveUtils.sp(context, 20),
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: ResponsiveUtils.spacing(context, 8)),
          Text(
            'Start by making a restaurant,\nspa or event reservation',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: ResponsiveUtils.sp(context, 14),
              color: Colors.grey[500],
              height: ResponsiveUtils.hp(context, 1.5 / 844),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCard(Map<String, dynamic> plan) {
    final Color planColor = plan['color'] as Color;
    final IconData planIcon = plan['icon'] as IconData;
    final DateTime date = plan['date'] as DateTime;
    final String status = plan['status'] as String;
    final bool isPast = date.isBefore(DateTime.now());

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(ResponsiveUtils.spacing(context, 16)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            // Color indicator bar
            Container(
              width: ResponsiveUtils.wp(context, 4 / 375),
              decoration: BoxDecoration(
                color: isPast ? Colors.grey[400] : planColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
              ),
            ),
            // Content
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 16)),
                child: Row(
                  children: [
                    // Icon
                    Container(
                      padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 10)),
                      decoration: BoxDecoration(
                        color: (isPast ? Colors.grey : planColor).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(ResponsiveUtils.spacing(context, 12)),
                      ),
                      child: Icon(
                        planIcon,
                        color: isPast ? Colors.grey[500] : planColor,
                        size: ResponsiveUtils.iconSize(context) * (22 / 24),
                      ),
                    ),
                    SizedBox(width: ResponsiveUtils.spacing(context, 14)),
                    // Text content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            plan['title'],
                            style: TextStyle(
                              fontSize: ResponsiveUtils.sp(context, 15),
                              fontWeight: FontWeight.w600,
                              color: isPast ? Colors.grey[500] : const Color(0xFF0d141b),
                            ),
                          ),
                          SizedBox(height: ResponsiveUtils.spacing(context, 4)),
                          Text(
                            plan['subtitle'],
                            style: TextStyle(
                              fontSize: ResponsiveUtils.sp(context, 13),
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Time & Status
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          DateFormat('HH:mm').format(date),
                          style: TextStyle(
                            fontSize: ResponsiveUtils.sp(context, 14),
                            fontWeight: FontWeight.w600,
                            color: isPast ? Colors.grey[400] : const Color(0xFF0d141b),
                          ),
                        ),
                        SizedBox(height: ResponsiveUtils.spacing(context, 4)),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: ResponsiveUtils.spacing(context, 8), vertical: ResponsiveUtils.spacing(context, 3)),
                          decoration: BoxDecoration(
                            color: _getStatusColor(status, isPast).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(ResponsiveUtils.spacing(context, 8)),
                          ),
                          child: Text(
                            _getStatusText(status, isPast),
                            style: TextStyle(
                              fontSize: ResponsiveUtils.sp(context, 14),
                            ),
                          ),
                        ),
                      ],
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

  Color _getStatusColor(String status, bool isPast) {
    if (isPast) return Colors.grey;
    
    switch (status.toLowerCase()) {
      case 'confirmed':
      case 'registered':
        return const Color(0xFF4CAF50);
      case 'pending':
        return const Color(0xFFFF9800);
      case 'cancelled':
        return const Color(0xFFF44336);
      case 'completed':
        return const Color(0xFF2196F3);
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status, bool isPast) {
    if (isPast) return 'Past';
    
    switch (status.toLowerCase()) {
      case 'confirmed':
        return 'Confirmed';
      case 'registered':
        return 'Registered';
      case 'pending':
        return 'Pending';
      case 'cancelled':
        return 'Cancelled';
      case 'completed':
        return 'Completed';
      default:
        return status;
    }
  }
}









