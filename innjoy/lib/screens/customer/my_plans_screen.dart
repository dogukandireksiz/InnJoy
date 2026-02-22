import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../../services/database_service.dart';
import '../../utils/responsive_utils.dart';

// ─── THEME CONSTANTS (matches app-wide design) ───────────────────────────────
const _kBg = Color(0xFFF6F7FB);
const _kPrimary = Color(0xFF137FEC);
const _kTextDark = Color(0xFF0D141B);
const _kCardShadow = Color(0x0D000000); // black @ ~5% opacity

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
    if (_userId == null) {
      setState(() => _isLoading = false);
      return;
    }
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
        body: Center(child: Text('Please login to view your plans.')),
      );
    }

    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Text(
          'My Plans',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
            fontSize: ResponsiveUtils.sp(context, 18),
          ),
        ),
      ),
      body: Column(
        children: [
          _buildDateSelector(),
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  // ─── DATE SELECTOR ─────────────────────────────────────────────────────────
  Widget _buildDateSelector() {
    final today = DateTime.now();
    final isToday = _isSameDay(_selectedDate, today);

    return Container(
      color: Colors.white,
      padding: EdgeInsets.symmetric(
        vertical: ResponsiveUtils.spacing(context, 10),
        horizontal: ResponsiveUtils.spacing(context, 8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _navButton(
            icon: Icons.chevron_left,
            onTap: () => setState(() => _selectedDate = _selectedDate.subtract(const Duration(days: 1))),
          ),
          GestureDetector(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime.now().subtract(const Duration(days: 365)),
                lastDate: DateTime.now().add(const Duration(days: 365)),
                builder: (ctx, child) => Theme(
                  data: Theme.of(ctx).copyWith(
                    colorScheme: const ColorScheme.light(primary: _kPrimary),
                  ),
                  child: child!,
                ),
              );
              if (picked != null) setState(() => _selectedDate = picked);
            },
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: ResponsiveUtils.spacing(context, 20),
                vertical: ResponsiveUtils.spacing(context, 8),
              ),
              decoration: BoxDecoration(
                color: isToday ? _kPrimary : _kBg,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_month_rounded,
                    size: ResponsiveUtils.iconSize(context) * (18 / 24),
                    color: isToday ? Colors.white : _kPrimary,
                  ),
                  SizedBox(width: ResponsiveUtils.spacing(context, 8)),
                  Text(
                    isToday
                        ? 'Today  •  ${DateFormat('EEE, MMM d').format(_selectedDate)}'
                        : DateFormat('EEE, MMM d').format(_selectedDate),
                    style: TextStyle(
                      fontSize: ResponsiveUtils.sp(context, 14),
                      fontWeight: FontWeight.w600,
                      color: isToday ? Colors.white : _kTextDark,
                    ),
                  ),
                ],
              ),
            ),
          ),
          _navButton(
            icon: Icons.chevron_right,
            onTap: () => setState(() => _selectedDate = _selectedDate.add(const Duration(days: 1))),
          ),
        ],
      ),
    );
  }

  Widget _navButton({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 8)),
        decoration: BoxDecoration(
          color: _kBg,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: _kTextDark, size: ResponsiveUtils.iconSize(context)),
      ),
    );
  }

  // ─── CONTENT ───────────────────────────────────────────────────────────────
  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: _kPrimary));
    }

    if (_hotelName == null || _hotelName!.isEmpty) {
      return _buildNoHotelState();
    }

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _db.getUserReservations(_userId!, hotelName: _hotelName),
      builder: (context, resSnap) {
        if (resSnap.hasError) return _buildErrorState(resSnap.error);
        return StreamBuilder<List<Map<String, dynamic>>>(
          stream: _db.getUserEvents(_userId, hotelName: _hotelName),
          builder: (context, evtSnap) {
            if (evtSnap.hasError) return _buildErrorState(evtSnap.error);
            return StreamBuilder<List<Map<String, dynamic>>>(
              stream: _db.getUserSpaAppointments(_userId, hotelName: _hotelName),
              builder: (context, spaSnap) {
                if (spaSnap.hasError) return _buildErrorState(spaSnap.error);

                final loading =
                    resSnap.connectionState == ConnectionState.waiting &&
                    evtSnap.connectionState == ConnectionState.waiting &&
                    spaSnap.connectionState == ConnectionState.waiting;

                if (loading) {
                  return const Center(child: CircularProgressIndicator(color: _kPrimary));
                }

                final items = _mergeAndFilter(
                  resSnap.data ?? [],
                  evtSnap.data ?? [],
                  spaSnap.data ?? [],
                );

                if (items.isEmpty) return _buildEmptyState();

                return ListView.builder(
                  padding: EdgeInsets.fromLTRB(
                    ResponsiveUtils.spacing(context, 16),
                    ResponsiveUtils.spacing(context, 16),
                    ResponsiveUtils.spacing(context, 16),
                    ResponsiveUtils.spacing(context, 32),
                  ),
                  itemCount: items.length + 1, // +1 for summary header
                  itemBuilder: (ctx, i) {
                    if (i == 0) return _buildSummaryCard(items);
                    return _buildPlanCard(items[i - 1], isLast: i == items.length);
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  // ─── SUMMARY CARD ──────────────────────────────────────────────────────────
  Widget _buildSummaryCard(List<Map<String, dynamic>> items) {
    final restCount = items.where((i) => i['type'] == 'reservation').length;
    final spaCount = items.where((i) => i['type'] == 'spa').length;
    final evtCount = items.where((i) => i['type'] == 'event').length;

    return Container(
      margin: EdgeInsets.only(bottom: ResponsiveUtils.spacing(context, 16)),
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveUtils.spacing(context, 16),
        vertical: ResponsiveUtils.spacing(context, 14),
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(ResponsiveUtils.spacing(context, 14)),
        boxShadow: const [BoxShadow(color: _kCardShadow, blurRadius: 8, offset: Offset(0, 2))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _summaryItem(Icons.restaurant, '$restCount', 'Restaurant', const Color(0xFFFF9800)),
          Container(width: 1, height: 40, color: Colors.grey[100]),
          _summaryItem(Icons.spa, '$spaCount', 'Spa', const Color(0xFF009688)),
          Container(width: 1, height: 40, color: Colors.grey[100]),
          _summaryItem(Icons.celebration, '$evtCount', 'Event', const Color(0xFF9C27B0)),
        ],
      ),
    );
  }

  Widget _summaryItem(IconData icon, String count, String label, Color color) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 8)),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: ResponsiveUtils.iconSize(context) * (18 / 24)),
        ),
        SizedBox(height: ResponsiveUtils.spacing(context, 4)),
        Text(count, style: TextStyle(fontWeight: FontWeight.bold, fontSize: ResponsiveUtils.sp(context, 16), color: _kTextDark)),
        Text(label, style: TextStyle(fontSize: ResponsiveUtils.sp(context, 11), color: Colors.grey[500])),
      ],
    );
  }

  // ─── PLAN CARD ─────────────────────────────────────────────────────────────
  Widget _buildPlanCard(Map<String, dynamic> item, {bool isLast = false}) {
    final type = item['type'] as String;
    final date = item['date'] as DateTime;
    final data = item['data'] as Map<String, dynamic>;
    final isPast = date.isBefore(DateTime.now());

    Color accent;
    IconData cardIcon;
    String typeLabel;

    switch (type) {
      case 'reservation':
        accent = const Color(0xFFFF9800);
        cardIcon = Icons.restaurant;
        typeLabel = 'Restaurant';
        break;
      case 'spa':
        accent = const Color(0xFF009688);
        cardIcon = Icons.spa;
        typeLabel = 'Spa';
        break;
      default:
        accent = const Color(0xFF9C27B0);
        cardIcon = Icons.celebration;
        typeLabel = 'Event';
    }

    if (isPast) accent = Colors.grey;

    String title;
    String subtitle;
    String status;

    if (type == 'reservation') {
      title = data['restaurantName'] ?? 'Restaurant';
      final partySize = data['partySize'] ?? 0;
      final tableNo = data['tableNumber'] ?? '-';
      subtitle = '$partySize guests  •  Table $tableNo';
      status = (data['status'] as String?)?.capitalize() ?? 'Confirmed';
    } else if (type == 'spa') {
      title = data['serviceName'] ?? 'Spa Appointment';
      subtitle = '${data['timeSlot'] ?? ''}  •  ${data['duration'] ?? ''}';
      status = (data['status'] as String?)?.capitalize() ?? 'Pending';
    } else {
      title = data['eventTitle'] ?? data['title'] ?? 'Event';
      subtitle = data['eventLocation'] ?? data['location'] ?? '';
      status = 'Registered';
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Timeline indicator
        Column(
          children: [
            Container(
              width: ResponsiveUtils.wp(context, 36 / 375),
              height: ResponsiveUtils.wp(context, 36 / 375),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(cardIcon, color: accent, size: ResponsiveUtils.iconSize(context) * (18 / 24)),
            ),
            if (!isLast)
              Container(
                width: 1,
                height: ResponsiveUtils.hp(context, 64 / 844),
                margin: EdgeInsets.symmetric(vertical: ResponsiveUtils.spacing(context, 4)),
                color: Colors.grey[200],
              ),
          ],
        ),
        SizedBox(width: ResponsiveUtils.spacing(context, 12)),
        // Card
        Expanded(
          child: GestureDetector(
            onTap: () => _showDetailSheet(item, accent),
            child: Container(
              margin: EdgeInsets.only(bottom: ResponsiveUtils.spacing(context, 14)),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(ResponsiveUtils.spacing(context, 12)),
                boxShadow: const [BoxShadow(color: _kCardShadow, blurRadius: 8, offset: Offset(0, 2))],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(ResponsiveUtils.spacing(context, 12)),
                child: InkWell(
                  onTap: () => _showDetailSheet(item, accent),
                  borderRadius: BorderRadius.circular(ResponsiveUtils.spacing(context, 12)),
                  child: Column(
                    children: [
                      // Left accent border via top strip
                      Container(
                        height: 3,
                        color: accent,
                      ),
                      Padding(
                        padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 14)),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Time
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  DateFormat('HH:mm').format(date),
                                  style: TextStyle(
                                    fontSize: ResponsiveUtils.sp(context, 15),
                                    fontWeight: FontWeight.bold,
                                    color: isPast ? Colors.grey : _kTextDark,
                                  ),
                                ),
                                Text(
                                  DateFormat('a').format(date),
                                  style: TextStyle(fontSize: ResponsiveUtils.sp(context, 11), color: Colors.grey[400]),
                                ),
                              ],
                            ),
                            Container(
                              width: 1, height: 38,
                              margin: EdgeInsets.symmetric(horizontal: ResponsiveUtils.spacing(context, 12)),
                              color: Colors.grey[200],
                            ),
                            // Info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          title,
                                          style: TextStyle(
                                            fontSize: ResponsiveUtils.sp(context, 15),
                                            fontWeight: FontWeight.w700,
                                            color: isPast ? Colors.grey[500] : _kTextDark,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: ResponsiveUtils.spacing(context, 8),
                                          vertical: ResponsiveUtils.spacing(context, 2),
                                        ),
                                        decoration: BoxDecoration(
                                          color: accent.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          typeLabel,
                                          style: TextStyle(
                                            fontSize: ResponsiveUtils.sp(context, 10),
                                            fontWeight: FontWeight.w600,
                                            color: accent,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (subtitle.isNotEmpty) ...[
                                    SizedBox(height: ResponsiveUtils.spacing(context, 4)),
                                    Text(
                                      subtitle,
                                      style: TextStyle(fontSize: ResponsiveUtils.sp(context, 12), color: Colors.grey[500]),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                  SizedBox(height: ResponsiveUtils.spacing(context, 8)),
                                  Row(
                                    children: [
                                      Container(
                                        width: 7, height: 7,
                                        decoration: BoxDecoration(
                                          color: isPast ? Colors.grey : _statusColor(status),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      SizedBox(width: ResponsiveUtils.spacing(context, 4)),
                                      Text(
                                        isPast ? 'Completed' : status,
                                        style: TextStyle(
                                          fontSize: ResponsiveUtils.sp(context, 11),
                                          color: isPast ? Colors.grey : _statusColor(status),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const Spacer(),
                                      Icon(Icons.chevron_right, color: Colors.grey[300], size: 18),
                                    ],
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
              ),
            ),
          ),
        ),
      ],
    );
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed': return const Color(0xFF4CAF50);
      case 'registered': return const Color(0xFF4CAF50);
      case 'pending': return const Color(0xFFFF9800);
      case 'cancelled': return const Color(0xFFF44336);
      case 'completed': return const Color(0xFF2196F3);
      default: return Colors.grey;
    }
  }

  // ─── DETAIL BOTTOM SHEET ───────────────────────────────────────────────────
  void _showDetailSheet(Map<String, dynamic> item, Color accent) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DetailSheet(item: item, accent: accent),
    );
  }

  // ─── EMPTY / ERROR STATES ──────────────────────────────────────────────────
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_note_outlined, size: ResponsiveUtils.iconSize(context) * (48 / 24), color: Colors.grey[300]),
          SizedBox(height: ResponsiveUtils.spacing(context, 16)),
          Text(
            'No plans for this day',
            style: TextStyle(fontSize: ResponsiveUtils.sp(context, 18), fontWeight: FontWeight.w700, color: _kTextDark),
          ),
          SizedBox(height: ResponsiveUtils.spacing(context, 8)),
          Text(
            'Make a restaurant, spa or event\nreservation to see it here',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: ResponsiveUtils.sp(context, 14), color: Colors.grey[500], height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildNoHotelState() {
    return Center(
      child: Text(
        'Hotel information not found.',
        style: TextStyle(color: Colors.grey[600], fontSize: ResponsiveUtils.sp(context, 16)),
      ),
    );
  }

  Widget _buildErrorState(Object? error) {
    final errStr = error.toString();
    IconData icon = Icons.wifi_off_rounded;
    String title = 'Connection Error';
    String message = 'Unable to load your plans. Check your internet connection.';

    if (errStr.contains('failed-precondition') || errStr.contains('requires an index')) {
      icon = Icons.build_outlined;
      title = 'Setup Required';
      message = 'A database index needs to be created. Please contact support.';
    } else if (errStr.contains('permission-denied')) {
      icon = Icons.lock_outline;
      title = 'Access Denied';
      message = "You don't have permission. Please log out and back in.";
    }

    return Center(
      child: Padding(
        padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 32)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 20)),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: ResponsiveUtils.iconSize(context) * (40 / 24), color: Colors.orange),
            ),
            SizedBox(height: ResponsiveUtils.spacing(context, 16)),
            Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: ResponsiveUtils.sp(context, 18))),
            SizedBox(height: ResponsiveUtils.spacing(context, 8)),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], fontSize: ResponsiveUtils.sp(context, 14), height: 1.5),
            ),
            SizedBox(height: ResponsiveUtils.spacing(context, 24)),
            ElevatedButton.icon(
              onPressed: () {
                setState(() => _isLoading = true);
                _loadUserHotel();
              },
              icon: const Icon(Icons.refresh),
              label: Text('Try Again', style: TextStyle(fontSize: ResponsiveUtils.sp(context, 15))),
              style: ElevatedButton.styleFrom(
                backgroundColor: _kPrimary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(ResponsiveUtils.spacing(context, 12))),
                padding: EdgeInsets.symmetric(
                  horizontal: ResponsiveUtils.spacing(context, 24),
                  vertical: ResponsiveUtils.spacing(context, 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── HELPERS ───────────────────────────────────────────────────────────────
  List<Map<String, dynamic>> _mergeAndFilter(
    List<Map<String, dynamic>> reservations,
    List<Map<String, dynamic>> events,
    List<Map<String, dynamic>> spa,
  ) {
    final merged = <Map<String, dynamic>>[];

    for (final r in reservations) {
      final raw = r['date'];
      if (raw is Timestamp) {
        final d = raw.toDate();
        if (_isSameDay(d, _selectedDate)) merged.add({'type': 'reservation', 'date': d, 'data': r});
      }
    }

    for (final e in events) {
      DateTime? d;
      final raw = e['date'];
      final rawEvt = e['eventDate'];
      if (raw is Timestamp) { d = raw.toDate(); }
      else if (rawEvt is Timestamp) { d = rawEvt.toDate(); }
      if (d != null && _isSameDay(d, _selectedDate)) merged.add({'type': 'event', 'date': d, 'data': e});
    }

    for (final s in spa) {
      final raw = s['appointmentDate'];
      if (raw is Timestamp) {
        final d = raw.toDate();
        if (_isSameDay(d, _selectedDate)) merged.add({'type': 'spa', 'date': d, 'data': s});
      }
    }

    merged.sort((a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime));
    return merged;
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

// ─────────────────────────────────────────────────────────────────────────────
// DETAIL BOTTOM SHEET
// ─────────────────────────────────────────────────────────────────────────────
class _DetailSheet extends StatelessWidget {
  final Map<String, dynamic> item;
  final Color accent;

  const _DetailSheet({required this.item, required this.accent});

  @override
  Widget build(BuildContext context) {
    final type = item['type'] as String;
    final date = item['date'] as DateTime;
    final data = item['data'] as Map<String, dynamic>;
    final isPast = date.isBefore(DateTime.now());

    IconData icon;
    String typeLabel;
    switch (type) {
      case 'reservation': icon = Icons.restaurant; typeLabel = 'Restaurant Reservation'; break;
      case 'spa': icon = Icons.spa; typeLabel = 'Spa Appointment'; break;
      default: icon = Icons.celebration; typeLabel = 'Event Registration';
    }

    final effectiveAccent = isPast ? Colors.grey : accent;

    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (ctx, ctrl) => Container(
        decoration: const BoxDecoration(
          color: _kBg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              width: 40, height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(4)),
            ),
            // Header
            Container(
              margin: EdgeInsets.fromLTRB(
                ResponsiveUtils.spacing(context, 16), 0,
                ResponsiveUtils.spacing(context, 16),
                ResponsiveUtils.spacing(context, 12),
              ),
              padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 16)),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(ResponsiveUtils.spacing(context, 14)),
                border: Border(left: BorderSide(color: effectiveAccent, width: 4)),
                boxShadow: const [BoxShadow(color: _kCardShadow, blurRadius: 8, offset: Offset(0, 2))],
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 10)),
                    decoration: BoxDecoration(
                      color: effectiveAccent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: effectiveAccent, size: ResponsiveUtils.iconSize(context) * (24 / 24)),
                  ),
                  SizedBox(width: ResponsiveUtils.spacing(context, 12)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          typeLabel.toUpperCase(),
                          style: TextStyle(color: Colors.grey[400], fontSize: ResponsiveUtils.sp(context, 11), fontWeight: FontWeight.w600, letterSpacing: 0.5),
                        ),
                        SizedBox(height: ResponsiveUtils.spacing(context, 2)),
                        Text(
                          _getTitle(type, data),
                          style: TextStyle(color: _kTextDark, fontSize: ResponsiveUtils.sp(context, 17), fontWeight: FontWeight.w700),
                          maxLines: 2, overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (isPast)
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: ResponsiveUtils.spacing(context, 8), vertical: ResponsiveUtils.spacing(context, 4)),
                      decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(20)),
                      child: Text('Completed', style: TextStyle(fontSize: ResponsiveUtils.sp(context, 11), color: Colors.grey[600], fontWeight: FontWeight.w600)),
                    ),
                ],
              ),
            ),
            // Detail rows
            Expanded(
              child: ListView(
                controller: ctrl,
                padding: EdgeInsets.fromLTRB(
                  ResponsiveUtils.spacing(context, 16), 0,
                  ResponsiveUtils.spacing(context, 16),
                  ResponsiveUtils.spacing(context, 32),
                ),
                children: [
                  _buildDetailCard(context, type, date, data, effectiveAccent),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getTitle(String type, Map<String, dynamic> data) {
    switch (type) {
      case 'reservation': return data['restaurantName'] ?? 'Restaurant';
      case 'spa': return data['serviceName'] ?? 'Spa Appointment';
      default: return data['eventTitle'] ?? data['title'] ?? 'Event';
    }
  }

  Widget _buildDetailCard(BuildContext context, String type, DateTime date, Map<String, dynamic> data, Color accent) {
    final rows = <_DetailRow>[];

    rows.add(_DetailRow(icon: Icons.calendar_today_rounded, label: 'Date', value: DateFormat('EEEE, d MMMM yyyy').format(date), accent: accent));
    rows.add(_DetailRow(icon: Icons.access_time_rounded, label: 'Time', value: DateFormat('HH:mm').format(date), accent: accent));

    if (type == 'reservation') {
      if (data['restaurantName'] != null) rows.add(_DetailRow(icon: Icons.storefront_rounded, label: 'Restaurant', value: data['restaurantName'], accent: accent));
      if (data['partySize'] != null) rows.add(_DetailRow(icon: Icons.people_rounded, label: 'Guests', value: '${data['partySize']} people', accent: accent));
      if (data['tableNumber'] != null) rows.add(_DetailRow(icon: Icons.table_restaurant_rounded, label: 'Table', value: 'Table ${data['tableNumber']}', accent: accent));
      if (data['status'] != null) rows.add(_DetailRow(icon: Icons.info_outline_rounded, label: 'Status', value: (data['status'] as String).capitalize(), accent: accent, isStatus: true));
      if ((data['note'] as String?)?.isNotEmpty == true) rows.add(_DetailRow(icon: Icons.note_alt_outlined, label: 'Note', value: data['note'], accent: accent));
    } else if (type == 'spa') {
      if (data['serviceName'] != null) rows.add(_DetailRow(icon: Icons.spa_rounded, label: 'Service', value: data['serviceName'], accent: accent));
      if (data['timeSlot'] != null) rows.add(_DetailRow(icon: Icons.schedule_rounded, label: 'Time Slot', value: data['timeSlot'], accent: accent));
      if (data['duration'] != null) rows.add(_DetailRow(icon: Icons.timer_rounded, label: 'Duration', value: data['duration'].toString(), accent: accent));
      if (data['price'] != null) rows.add(_DetailRow(icon: Icons.payments_rounded, label: 'Price', value: '₺${data['price']}', accent: accent));
      final pm = data['paymentMethod'];
      if (pm != null) rows.add(_DetailRow(icon: Icons.credit_card_rounded, label: 'Payment', value: _fmtPayment(pm), accent: accent));
      if (data['status'] != null) rows.add(_DetailRow(icon: Icons.info_outline_rounded, label: 'Status', value: (data['status'] as String).capitalize(), accent: accent, isStatus: true));
      if (data['roomNumber'] != null) rows.add(_DetailRow(icon: Icons.meeting_room_rounded, label: 'Room', value: 'Room ${data['roomNumber']}', accent: accent));
    } else {
      final loc = data['eventLocation'] ?? data['location'];
      if (loc != null && (loc as String).isNotEmpty) rows.add(_DetailRow(icon: Icons.location_on_rounded, label: 'Location', value: loc, accent: accent));
      final cap = data['capacity'];
      if (cap != null) rows.add(_DetailRow(icon: Icons.people_outlined, label: 'Capacity', value: '${data['registered'] ?? 0} / $cap', accent: accent));
      if (data['category'] != null) rows.add(_DetailRow(icon: Icons.category_rounded, label: 'Category', value: data['category'].toString(), accent: accent));
      rows.add(_DetailRow(icon: Icons.check_circle_outline_rounded, label: 'Status', value: 'Registered', accent: accent, isStatus: true));
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(ResponsiveUtils.spacing(context, 12)),
        boxShadow: const [BoxShadow(color: _kCardShadow, blurRadius: 8, offset: Offset(0, 2))],
      ),
      child: Column(
        children: List.generate(rows.length, (i) => Column(
          children: [
            rows[i].build(context),
            if (i < rows.length - 1) Padding(padding: EdgeInsets.symmetric(horizontal: ResponsiveUtils.spacing(context, 16)), child: Divider(height: 1, color: Colors.grey[100])),
          ],
        )),
      ),
    );
  }

  String _fmtPayment(String m) {
    switch (m) {
      case 'room_charge': return 'Charged to Room';
      case 'pay_at_spa': return 'Pay at Spa';
      case 'credit_card': return 'Credit Card';
      default: return m;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DETAIL ROW
// ─────────────────────────────────────────────────────────────────────────────
class _DetailRow {
  final IconData icon;
  final String label;
  final dynamic value;
  final Color accent;
  final bool isStatus;

  const _DetailRow({required this.icon, required this.label, required this.value, required this.accent, this.isStatus = false});

  Widget build(BuildContext context) {
    final display = value?.toString() ?? '-';
    Color? statusColor;
    if (isStatus) {
      switch (display.toLowerCase()) {
        case 'confirmed': case 'registered': statusColor = const Color(0xFF4CAF50); break;
        case 'pending': statusColor = const Color(0xFFFF9800); break;
        case 'cancelled': statusColor = const Color(0xFFF44336); break;
        case 'completed': statusColor = const Color(0xFF2196F3); break;
        default: statusColor = Colors.grey;
      }
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: ResponsiveUtils.spacing(context, 16), vertical: ResponsiveUtils.spacing(context, 14)),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 8)),
            decoration: BoxDecoration(
              color: const Color(0xFFE3F2FD),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: ResponsiveUtils.iconSize(context) * (16 / 24), color: accent),
          ),
          SizedBox(width: ResponsiveUtils.spacing(context, 14)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: ResponsiveUtils.sp(context, 11), color: Colors.grey[400], fontWeight: FontWeight.w500)),
                SizedBox(height: ResponsiveUtils.spacing(context, 2)),
                isStatus
                    ? Container(
                        padding: EdgeInsets.symmetric(horizontal: ResponsiveUtils.spacing(context, 10), vertical: ResponsiveUtils.spacing(context, 3)),
                        decoration: BoxDecoration(color: statusColor!.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                        child: Text(display, style: TextStyle(fontSize: ResponsiveUtils.sp(context, 13), fontWeight: FontWeight.w700, color: statusColor)),
                      )
                    : Text(display, style: TextStyle(fontSize: ResponsiveUtils.sp(context, 14), fontWeight: FontWeight.w600, color: _kTextDark)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Extension
extension _StringExt on String {
  String capitalize() => isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';
}
