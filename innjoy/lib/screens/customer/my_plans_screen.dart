import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../../services/database_service.dart';

class MyPlansScreen extends StatefulWidget {
  const MyPlansScreen({super.key});

  @override
  State<MyPlansScreen> createState() => _MyPlansScreenState();
}

class _MyPlansScreenState extends State<MyPlansScreen> {
  final DatabaseService _db = DatabaseService();
  final String? _userId = FirebaseAuth.instance.currentUser?.uid;
  DateTime _selectedDate = DateTime.now();
  String? _hotelName;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserHotel();
  }

  Future<void> _loadUserHotel() async {
    if (_userId == null) return;

    final userData = await _db.getUserData(_userId);
    if (mounted) {
      setState(() {
        _hotelName = userData?['hotelName'];
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_userId == null) {
      return const Scaffold(
        body: Center(child: Text("Please login to view your plans.")),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        title: const Text(
          'My Plans',
          style: TextStyle(
            color: Color(0xFF101922),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF101922)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          _buildDateHeader(),
          Expanded(child: _buildTimelineList()),
        ],
      ),
    );
  }

  Widget _buildDateHeader() {
    final dateFormat = DateFormat('EEE, MMM d');
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () {
              setState(() {
                _selectedDate = _selectedDate.subtract(const Duration(days: 1));
              });
            },
            icon: const Icon(Icons.chevron_left, color: Colors.grey),
          ),
          GestureDetector(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime.now().subtract(const Duration(days: 365)),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (picked != null) {
                setState(() => _selectedDate = picked);
              }
            },
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_today,
                  size: 18,
                  color: Color(0xFF137fec),
                ),
                const SizedBox(width: 8),
                Text(
                  dateFormat.format(_selectedDate),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF101922),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              setState(() {
                _selectedDate = _selectedDate.add(const Duration(days: 1));
              });
            },
            icon: const Icon(Icons.chevron_right, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineList() {
    // Otel bilgisi y�klenene kadar bekle
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_hotelName == null || _hotelName!.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.hotel, size: 60, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              "Hotel information not found.",
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
          ],
        ),
      );
    }

    // Strategy: Fetch Reservation Stream, then Event Stream, then Spa Stream.
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _db.getUserReservations(_userId!, hotelName: _hotelName),
      builder: (context, resSnapshot) {
        if (resSnapshot.hasError) {
          return _buildErrorState(resSnapshot.error);
        }

        return StreamBuilder<List<Map<String, dynamic>>>(
          stream: _db.getUserEvents(_userId, hotelName: _hotelName),
          builder: (context, evtSnapshot) {
            if (evtSnapshot.hasError) {
              return _buildErrorState(evtSnapshot.error);
            }

            return StreamBuilder<List<Map<String, dynamic>>>(
              stream: _db.getUserSpaAppointments(
                _userId,
                hotelName: _hotelName,
              ),
              builder: (context, spaSnapshot) {
                if (spaSnapshot.hasError) {
                  return _buildErrorState(spaSnapshot.error);
                }

                if (resSnapshot.connectionState == ConnectionState.waiting &&
                    evtSnapshot.connectionState == ConnectionState.waiting &&
                    spaSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final reservations = resSnapshot.data ?? [];
                final events = evtSnapshot.data ?? [];
                final spaAppointments = spaSnapshot.data ?? [];

                // Filter by date
                final dailyItems = _filterAndMerge(
                  reservations,
                  events,
                  spaAppointments,
                );

                if (dailyItems.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: dailyItems.length,
                  itemBuilder: (context, index) {
                    final item = dailyItems[index];
                    if (item['type'] == 'reservation') {
                      return _buildReservationCard(item['data']);
                    } else if (item['type'] == 'spa') {
                      return _buildSpaCard(item['data']);
                    } else {
                      return _buildEventCard(item['data']);
                    }
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  List<Map<String, dynamic>> _filterAndMerge(
    List<Map<String, dynamic>> reservations,
    List<Map<String, dynamic>> events,
    List<Map<String, dynamic>> spaAppointments,
  ) {
    final List<Map<String, dynamic>> merged = [];

    // Reservations (Restaurant)
    for (var r in reservations) {
      if (r['date'] != null && r['date'] is Timestamp) {
        DateTime d = (r['date'] as Timestamp).toDate();
        if (_isSameDay(d, _selectedDate)) {
          merged.add({'type': 'reservation', 'date': d, 'data': r});
        }
      }
    }

    // Events
    for (var e in events) {
      DateTime? eventDate;
      if (e['date'] != null && e['date'] is Timestamp) {
        eventDate = (e['date'] as Timestamp).toDate();
      } else if (e['eventDate'] != null && e['eventDate'] is Timestamp) {
        eventDate = (e['eventDate'] as Timestamp).toDate();
      }

      if (eventDate != null && _isSameDay(eventDate, _selectedDate)) {
        merged.add({'type': 'event', 'date': eventDate, 'data': e});
      }
    }

    // Spa Appointments
    for (var s in spaAppointments) {
      DateTime? spaDate;
      if (s['appointmentDate'] != null && s['appointmentDate'] is Timestamp) {
        spaDate = (s['appointmentDate'] as Timestamp).toDate();
      }

      if (spaDate != null && _isSameDay(spaDate, _selectedDate)) {
        merged.add({'type': 'spa', 'date': spaDate, 'data': s});
      }
    }

    // Sort by time
    merged.sort(
      (a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime),
    );
    return merged;
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Widget _buildReservationCard(Map<String, dynamic> data) {
    final restaurantName = data['restaurantName'] ?? 'Restaurant';
    final timeStr = DateFormat(
      'HH:mm',
    ).format((data['date'] as Timestamp).toDate());
    final partySize = data['partySize'] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.restaurant, color: Colors.orange.shade700),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    restaurantName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 14,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(timeStr, style: TextStyle(color: Colors.grey[600])),
                      const SizedBox(width: 12),
                      Icon(Icons.people, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        "$partySize Guests",
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventCard(Map<String, dynamic> data) {
    final title = data['eventTitle'] ?? data['title'] ?? 'Event';
    final location = data['eventLocation'] ?? data['location'] ?? '';
    final time = data['time'] ?? ''; // Saat bilgisi (�rn: "14:00")
    final imageUrl = data['imageAsset'] ?? data['imageUrl'];

    // Tarih bilgisini al
    DateTime? eventDate;
    if (data['date'] is Timestamp) {
      eventDate = (data['date'] as Timestamp).toDate();
    } else if (data['eventDate'] is Timestamp) {
      eventDate = (data['eventDate'] as Timestamp).toDate();
    }

    // Saat bilgisi: time alan�ndan veya tarihten ��kar
    String timeStr = time.isNotEmpty
        ? time
        : (eventDate != null ? DateFormat('HH:mm').format(eventDate) : '');

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.purple.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Event Image or Icon
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: imageUrl != null && imageUrl.toString().isNotEmpty
                  ? (imageUrl.toString().startsWith('http')
                        ? Image.network(
                            imageUrl,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                _buildEventIconFallback(),
                          )
                        : Image.asset(
                            imageUrl,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                _buildEventIconFallback(),
                          ))
                  : _buildEventIconFallback(),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  // Saat ve Lokasyon
                  Wrap(
                    spacing: 12,
                    runSpacing: 4,
                    children: [
                      if (timeStr.isNotEmpty)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 14,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              timeStr,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      if (location.isNotEmpty)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 14,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              location,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 13,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventIconFallback() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: Colors.purple.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(Icons.event, color: Colors.purple.shade700, size: 28),
    );
  }

  Widget _buildSpaCard(Map<String, dynamic> data) {
    final serviceName = data['serviceName'] ?? 'Spa Appointment';
    final timeSlot = data['timeSlot'] ?? '';
    final duration = data['duration'] ?? '';
    final status = data['status'] ?? 'pending';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.teal.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.teal.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.teal.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.spa, color: Colors.teal.shade700),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    serviceName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 14,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(timeSlot, style: TextStyle(color: Colors.grey[600])),
                      const SizedBox(width: 12),
                      Icon(Icons.timer, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(duration, style: TextStyle(color: Colors.grey[600])),
                    ],
                  ),
                ],
              ),
            ),
            // Status badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getSpaStatusColor(status).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _getSpaStatusText(status),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: _getSpaStatusColor(status),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getSpaStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      case 'completed':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _getSpaStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return 'Confirmed';
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

  Widget _buildErrorState(Object? error) {
    final errStr = error.toString();
    if (errStr.contains('failed-precondition')) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.build, size: 60, color: Colors.orange),
              const SizedBox(height: 16),
              const Text(
                "Setup Required",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 8),
              const Text(
                "Missing Index. Please check your console/terminal and click the link to create it.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }
    return Center(child: Text("Error loading plans: $errStr"));
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.calendar_today, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            "No plans for this day.",
            style: TextStyle(color: Colors.grey[500], fontSize: 16),
          ),
        ],
      ),
    );
  }
}
