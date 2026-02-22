import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/database_service.dart';
import '../../services/notification_service.dart';
import '../../utils/responsive_utils.dart';

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
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _checkUserRole();
  }

  Future<void> _checkUserRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userData = await DatabaseService().getUserData(user.uid);
      if (mounted) {
        setState(() {
          _isAdmin = userData?['role'] == 'admin';
        });
      }
    }
  }

  Future<void> _handleBooking() async {
    setState(() => _isLoading = true);

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please log in first.')));
      setState(() => _isLoading = false);
      return;
    }

    final eventId = widget.event['id'];
    // Construct user info (In a real app, fetch more details like Name/Room from Profile)
    final userInfo = {
      'userId': user.uid,
      'userName': user.displayName ?? user.email ?? 'Guest',
      'roomNumber': '101', // Placeholder or fetch from context/profile
    };

    // Extract event details for saving
    final eventDetails = {
      'eventTitle': widget.event['title'],
      'eventDate': widget.event['date'], // Assuming Timestamp
      'eventLocation': widget.event['location'],
      'eventImage': widget.event['imageAsset'], // for thumbnail
    };

    final result = await DatabaseService().registerForEvent(
      widget.hotelName,
      eventId,
      userInfo,
      eventDetails,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['success'] == true) {
      // Etkinlikten 1 saat önce hatırlatıcı bildirim zamanla
      final eventDate = widget.event['date'] as Timestamp?;
      final eventTime = widget.event['time'] as String?;

      if (eventDate != null && eventTime != null) {
        final eventDateTime = _parseEventDateTime(eventDate, eventTime);
        if (eventDateTime != null) {
          // 1 saat önce hatırlatıcı
          final reminderTime1h = eventDateTime.subtract(
            const Duration(hours: 1),
          );
          await NotificationService().scheduleReminderNotification(
            id: NotificationService.generateNotificationId(
              eventDateTime,
              'event_1h',
            ),
            title: '🔔 Event in 1 Hour',
            body: '${widget.event['title']} • ${widget.event['location']} • ${widget.event['time']}',
            scheduledTime: reminderTime1h,
            type: 'event',
          );

          // 30 dakika önce hatırlatıcı
          final reminderTime30m = eventDateTime.subtract(
            const Duration(minutes: 30),
          );
          await NotificationService().scheduleReminderNotification(
            id: NotificationService.generateNotificationId(
              eventDateTime,
              'event_30m',
            ),
            title: '🔔 Event in 30 Minutes',
            body: '${widget.event['title']} • ${widget.event['location']} • ${widget.event['time']}',
            scheduledTime: reminderTime30m,
            type: 'event',
          );
        }
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Registration Successful! 🔔 Reminders set: 1h & 30min before',
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 4),
        ),
      );
    } else {
      if (result['status'] == 'full') {
        _showFullDialog();
      } else if (result['status'] == 'already_registered') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You are already registered for this event.'),
            backgroundColor: Colors.orange,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'An error occurred.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Etkinlik tarih ve saatini DateTime'a çevir
  DateTime? _parseEventDateTime(Timestamp eventDate, String eventTime) {
    try {
      final date = eventDate.toDate();
      final timeParts = eventTime.split(':');
      if (timeParts.length >= 2) {
        final hour = int.parse(timeParts[0]);
        final minute = int.parse(timeParts[1]);
        return DateTime(date.year, date.month, date.day, hour, minute);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  void _showFullDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(ResponsiveUtils.spacing(context, 16))),
        title: const Text(
          'Event Full',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo),
        ),
        content: Text(
          'This event is fully booked. Would you like to check out similar events?',
          style: TextStyle(fontSize: ResponsiveUtils.sp(context, 16)),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back to Event List
            },
            child: Text(
              'Browse',
              style: TextStyle(fontSize: ResponsiveUtils.sp(context, 16), fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Extract data with fallbacks
    final title = widget.event['title'] ?? 'Event Details';
    final imageAsset =
        widget.event['imageAsset'] ?? 'assets/images/arkaplanyok.png';
    final location = widget.event['location'] ?? 'Location not specified';
    final time = widget.event['time'] ?? 'Time not specified';
    final description =
        widget.event['description'] ?? 'No description provided.';
    final capacity = widget.event['capacity'] ?? 0;
    final registered = widget.event['registered'] ?? 0;
    final category = widget.event['category']; // Extract category

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
            padding: EdgeInsets.only(
              bottom: 100,
            ), // Space for bottom button
            child: Column(
              children: [
                SizedBox(height: kToolbarHeight + 20),

                // Content Container
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: ResponsiveUtils.spacing(context, 16)),
                  child: Column(
                    children: [
                      // Image Card
                      Container(
                        height: ResponsiveUtils.hp(context, 256 / 844),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(ResponsiveUtils.spacing(context, 32)),
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(ResponsiveUtils.spacing(context, 32)),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              (imageAsset.startsWith('http'))
                                  ? Image.network(
                                      imageAsset,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              Container(
                                                color: Colors.grey[300],
                                                child: const Icon(Icons.error),
                                              ),
                                    )
                                  : Image.asset(
                                      imageAsset,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              Container(
                                                color: Colors.grey[300],
                                                child: const Icon(Icons.error),
                                              ),
                                    ),
                              if (isFull)
                                Container(
                                  color: Colors.grey.withValues(alpha: 0.8),
                                ), // Grey out if full
                            ],
                          ),
                        ),
                      ),

                      SizedBox(height: ResponsiveUtils.spacing(context, 16)),

                      // Info Container
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 24)),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(ResponsiveUtils.spacing(context, 16)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (isFull)
                              Container(
                                margin: EdgeInsets.only(
                                  bottom: ResponsiveUtils.spacing(context, 12),
                                ),
                                padding: EdgeInsets.symmetric(
                                  horizontal: ResponsiveUtils.spacing(context, 12),
                                  vertical: ResponsiveUtils.spacing(context, 6),
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade100,
                                  borderRadius: BorderRadius.circular(ResponsiveUtils.spacing(context, 8)),
                                  border: Border.all(
                                    color: Colors.red.shade300,
                                  ),
                                ),
                                child: Text(
                                  'CAPACITY FULL',
                                  style: TextStyle(
                                    color: Colors.red.shade800,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            Text(
                              title,
                              style: TextStyle(
                                fontSize: ResponsiveUtils.sp(context, 24),
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF111827),
                              ),
                            ),
                            SizedBox(height: ResponsiveUtils.spacing(context, 16)),

                            // Display Category if available
                            if (category != null && category.isNotEmpty) ...[
                              Container(
                                decoration: BoxDecoration(
                                  color: _getCategoryColor(
                                    category,
                                  ).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(ResponsiveUtils.spacing(context, 8)),
                                  border: Border.all(
                                    color: _getCategoryColor(
                                      category,
                                    ).withValues(alpha: 0.3),
                                  ),
                                ),
                                padding: EdgeInsets.symmetric(
                                  horizontal: ResponsiveUtils.spacing(context, 12),
                                  vertical: ResponsiveUtils.spacing(context, 8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      _getCategoryIcon(category),
                                      size: ResponsiveUtils.iconSize(context) * (18 / 24),
                                      color: _getCategoryColor(category),
                                    ),
                                    SizedBox(width: ResponsiveUtils.spacing(context, 8)),
                                    Text(
                                      category,
                                      style: TextStyle(
                                        color: _getCategoryColor(category),
                                        fontWeight: FontWeight.bold,
                                        fontSize: ResponsiveUtils.sp(context, 13),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: ResponsiveUtils.spacing(context, 16)),
                            ],

                            // Date/Time/Loc Rows
                            _InfoRow(
                              icon: Icons.calendar_today,
                              label: 'Date: $dateStr',
                            ),
                            SizedBox(height: ResponsiveUtils.spacing(context, 12)),
                            _InfoRow(
                              icon: Icons.schedule,
                              label: 'Time: $time',
                            ),
                            SizedBox(height: ResponsiveUtils.spacing(context, 12)),
                            _InfoRow(
                              icon: Icons.place,
                              label: 'Location: $location',
                            ),
                            SizedBox(height: ResponsiveUtils.spacing(context, 12)),
                            // Capacity
                            _InfoRow(
                              icon: Icons.people,
                              label: isFull
                                  ? 'Event Full'
                                  : 'Capacity: $registered / $capacity',
                              color: isFull ? Colors.red : null,
                            ),

                            SizedBox(height: ResponsiveUtils.spacing(context, 20)),
                            Divider(color: Color(0xFFE5E7EB)),
                            SizedBox(height: ResponsiveUtils.spacing(context, 20)),

                            Text(
                              'Description',
                              style: TextStyle(
                                fontSize: ResponsiveUtils.sp(context, 18),
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF111827),
                              ),
                            ),
                            SizedBox(height: ResponsiveUtils.spacing(context, 8)),
                            Text(
                              description,
                              style: TextStyle(
                                fontSize: ResponsiveUtils.sp(context, 14),
                                height: ResponsiveUtils.hp(context, 1.6 / 844),
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
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top,
                left: 8,
                right: 16,
              ),
              color: Colors.white.withValues(alpha: 0.95),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back,
                      color: Color(0xFF1F2937),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  Expanded(
                    child: Text(
                      title,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: ResponsiveUtils.sp(context, 18),
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF111827),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(width: ResponsiveUtils.spacing(context, 40)),
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
              padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 16)),
              color: const Color(0xFFF3F4F6),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading || _isAdmin
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
                    backgroundColor: isFull || _isAdmin
                        ? Colors.grey
                        : const Color(0xFF1D8CF8),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(ResponsiveUtils.spacing(context, 9999)),
                    ),
                    elevation: 4,
                  ),
                  child: _isLoading
                      ? SizedBox(
                          width: ResponsiveUtils.wp(context, 24 / 375),
                          height: ResponsiveUtils.hp(context, 24 / 844),
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          _isAdmin
                              ? 'Admins Cannot Register'
                              : (isFull ? 'Event Full' : 'Book Session'),
                          style: TextStyle(
                            fontSize: ResponsiveUtils.sp(context, 16),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _monthName(int m) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return months[m - 1];
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Entertainment':
        return Colors.purple;
      case 'Wellness & Life':
        return Colors.teal; // İsim güncellendi
      case 'Sports':
        return Colors.orange;
      case 'Kids':
        return Colors.blue;
      case 'Food & Beverage':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Entertainment':
        return Icons.celebration; // Yeni (Parti)
      case 'Wellness & Life':
        return Icons.spa; // Eski (Wellness eski kalsın dendi)
      case 'Sports':
        return Icons.directions_run; // Yeni (Koşan adam)
      case 'Kids':
        return Icons.child_care; // Eski (Bebek arabası/çocuk)
      case 'Food & Beverage':
        return Icons.restaurant; // Eski (Klasik çatal bıçak)
      default:
        return Icons.category;
    }
  }

  String _weekdayName(int w) {
    const map = {
      1: 'Monday',
      2: 'Tuesday',
      3: 'Wednesday',
      4: 'Thursday',
      5: 'Friday',
      6: 'Saturday',
      7: 'Sunday',
    };
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
        Icon(icon, color: color ?? const Color(0xFF9CA3AF), size: ResponsiveUtils.iconSize(context) * (24 / 24)),
        SizedBox(width: ResponsiveUtils.spacing(context, 12)),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(top: 2.0),
            child: Text(
              label,
              style: TextStyle(
                fontSize: ResponsiveUtils.sp(context, 14),
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
