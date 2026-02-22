import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../services/database_service.dart';
import 'event_details_screen.dart';
import '../../utils/responsive_utils.dart';

class EventsActivitiesScreen extends StatefulWidget {
  final String hotelName;
  const EventsActivitiesScreen({super.key, required this.hotelName});

  @override
  State<EventsActivitiesScreen> createState() => _EventsActivitiesScreenState();
}

class _EventsActivitiesScreenState extends State<EventsActivitiesScreen> {
  int _selectedDayIndex = 7;
  String _query = '';
  DateTime _today = DateTime.now();
  Timer? _dayTick;

  List<DateTime> get _days => List.generate(
    22,
    (i) => DateTime(_today.year, _today.month, _today.day + (i - 7)),
  );

  String _humanDate(DateTime d) {
    return "${_monthName(d.month)} ${d.day}";
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

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _weekdayName(int weekday) {
    const map = {
      1: 'Monday',
      2: 'Tuesday',
      3: 'Wednesday',
      4: 'Thursday',
      5: 'Friday',
      6: 'Saturday',
      7: 'Sunday',
    };
    return map[weekday] ?? '';
  }

  String _headerFor(DateTime d) {
    final baseToday = DateTime(_today.year, _today.month, _today.day);
    final baseTomorrow = baseToday.add(const Duration(days: 1));
    final baseD = DateTime(d.year, d.month, d.day);
    if (_isSameDay(baseD, baseToday)) return 'Today, ${_humanDate(d)}';
    if (_isSameDay(baseD, baseTomorrow)) return 'Tomorrow, ${_humanDate(d)}';
    return '${_weekdayName(d.weekday)}, ${_humanDate(d)}';
  }

  late TextEditingController _searchController;
  late Stream<List<Map<String, dynamic>>> _eventsStream;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _eventsStream = DatabaseService().getHotelEvents(widget.hotelName);
    _startDayWatcher();
  }

  void _startDayWatcher() {
    _dayTick?.cancel();
    _dayTick = Timer.periodic(const Duration(minutes: 1), (_) {
      final now = DateTime.now();
      final nowBase = DateTime(now.year, now.month, now.day);
      final todayBase = DateTime(_today.year, _today.month, _today.day);
      if (nowBase.isAfter(todayBase)) {
        setState(() {
          _today = now;
          _today = now;
          // Keep selection valid or reset to today?
          // If the day passed, index 0 is now the new today.
          if (_selectedDayIndex != 7) {
            _selectedDayIndex = 7; // Reset to Today if day rolls over
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _dayTick?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        title: const Text('Events & Activities'),
        centerTitle: true,
        backgroundColor: const Color(0xFFF6F7FB),
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _eventsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          final allEvents = snapshot.data ?? [];

          // Filter: Published only
          final publishedEvents = allEvents
              .where((e) => e['isPublished'] == true)
              .toList();

          final q = _query.trim().toLowerCase();
          final searching = q.isNotEmpty;

          final filtered = publishedEvents.where((e) {
            // Search filter
            if (searching) {
              final title = (e['title'] ?? '').toString().toLowerCase();
              final loc = (e['location'] ?? '').toString().toLowerCase();
              return title.contains(q) || loc.contains(q);
            }

            // Date filter - Single Day (Only if NOT searching)
            final targetDate = _days[_selectedDayIndex];

            if (e['date'] != null && e['date'] is Timestamp) {
              final eDate = (e['date'] as Timestamp).toDate();
              return _isSameDay(eDate, targetDate);
            }
            return false;
          }).toList();

          return ListView(
            padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 16)),
            children: [
              _SearchBar(
                controller: _searchController,
                onChanged: (v) => setState(() => _query = v),
                onClear: () {
                  setState(() {
                    _query = '';
                    _searchController.clear();
                  });
                },
              ),
              SizedBox(height: ResponsiveUtils.spacing(context, 12)),
              if (!searching) ...[
                _DateScroller(
                  days: _days,
                  selectedIndex: _selectedDayIndex,
                  onSelected: (i) => setState(() => _selectedDayIndex = i),
                ),
                SizedBox(height: ResponsiveUtils.spacing(context, 16)),
              ],
              if (filtered.isEmpty)
                Container(
                  height: MediaQuery.of(context).size.height * 0.5,
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.event_busy_rounded,
                        size: ResponsiveUtils.iconSize(context) * (64 / 24),
                        color: Colors.grey[300],
                      ),
                      SizedBox(height: ResponsiveUtils.spacing(context, 16)),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: ResponsiveUtils.spacing(context, 40)),
                        child: Text(
                          searching
                              ? 'No events found matching your search.'
                              : 'No events scheduled for today. Try checking other dates!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: ResponsiveUtils.sp(context, 16),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                ..._buildGroupedResults(filtered),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _buildGroupedResults(List<Map<String, dynamic>> items) {
    final widgets = <Widget>[];
    items.sort((a, b) {
      final da = (a['date'] as Timestamp?)?.toDate() ?? DateTime(0);
      final db = (b['date'] as Timestamp?)?.toDate() ?? DateTime(0);
      return da.compareTo(db);
    });

    DateTime? lastDate;
    for (var i = 0; i < items.length; i++) {
      final e = items[i];
      final dateTs = e['date'] as Timestamp?;
      final date = dateTs?.toDate() ?? DateTime.now();

      if (lastDate == null || !_isSameDay(lastDate, date)) {
        if (lastDate != null) widgets.add(SizedBox(height: ResponsiveUtils.spacing(context, 16)));
        widgets.add(
          Text(
            _headerFor(date),
            style: TextStyle(fontSize: ResponsiveUtils.sp(context, 16), fontWeight: FontWeight.w700),
          ),
        );
        widgets.add(SizedBox(height: ResponsiveUtils.spacing(context, 12)));
        lastDate = DateTime(date.year, date.month, date.day);
      }
      widgets.add(
        _EventItem(
          title: e['title'] ?? 'Unnamed Event',
          time: e['time'] ?? '',
          location: e['location'] ?? '',
          imageAsset: e['imageAsset'] ?? 'assets/images/no_image.png',
          capacity: e['capacity'] ?? 0,
          registered: e['registered'] ?? 0,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    EventDetailsScreen(event: e, hotelName: widget.hotelName),
              ),
            );
          },
          date: date,
        ),
      );
      if (i != items.length - 1) widgets.add(SizedBox(height: ResponsiveUtils.spacing(context, 10)));
    }
    return widgets;
  }
}

class _DateScroller extends StatefulWidget {
  final List<DateTime> days;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  const _DateScroller({
    required this.days,
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  State<_DateScroller> createState() => _DateScrollerState();
}

class _DateScrollerState extends State<_DateScroller> {
  late ScrollController _controller;

  @override
  void initState() {
    super.initState();
    // Item width (64) + Separator (8) = 72
    final initialOffset = widget.selectedIndex * 72.0;
    _controller = ScrollController(initialScrollOffset: initialOffset);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: ResponsiveUtils.hp(context, 70 / 844),
      child: ListView.separated(
        key: const PageStorageKey('guest_events_date_scroll_v2'),
        controller: _controller,
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, i) {
          final d = widget.days[i];
          final selected = i == widget.selectedIndex;
          return GestureDetector(
            onTap: () => widget.onSelected(i),
            child: Container(
              width: ResponsiveUtils.wp(context, 64 / 375),
              height: ResponsiveUtils.hp(context, 64 / 844),
              decoration: BoxDecoration(
                color: selected
                    ? (_isToday(d) ? Colors.green : const Color(0xFF137FEC))
                    : Colors.white,
                borderRadius: BorderRadius.circular(ResponsiveUtils.spacing(context, 32)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
                border: _isToday(d) && !selected
                    ? Border.all(color: Colors.green, width: 2)
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _dayLabel(d.weekday),
                    style: TextStyle(
                      color: selected
                          ? Colors.white
                          : (_isToday(d)
                                ? Colors.green
                                : const Color(0xFF0D141B)),
                      fontSize: ResponsiveUtils.sp(context, 14),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: ResponsiveUtils.spacing(context, 2)),
                  Text(
                    d.day.toString(),
                    style: TextStyle(
                      color: selected
                          ? Colors.white
                          : (_isToday(d)
                                ? Colors.green
                                : const Color(0xFF0D141B)),
                      fontSize: ResponsiveUtils.sp(context, 20),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (_isToday(d))
                    Container(
                      margin: EdgeInsets.only(top: 4),
                      width: ResponsiveUtils.wp(context, 4 / 375),
                      height: ResponsiveUtils.hp(context, 4 / 844),
                      decoration: BoxDecoration(
                        color: selected ? Colors.white : Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
            ),
          );
        },
        separatorBuilder: (_, e) => SizedBox(width: ResponsiveUtils.spacing(context, 8)),
        itemCount: widget.days.length,
      ),
    );
  }

  String _dayLabel(int weekday) {
    const map = {
      1: 'Mon',
      2: 'Tue',
      3: 'Wed',
      4: 'Thu',
      5: 'Fri',
      6: 'Sat',
      7: 'Sun',
    };
    return map[weekday] ?? '';
  }

  bool _isToday(DateTime d) {
    final now = DateTime.now();
    return d.year == now.year && d.month == now.month && d.day == now.day;
  }
}

class _EventItem extends StatelessWidget {
  final String title;
  final String time;
  final String location;
  final String imageAsset;
  final int capacity;
  final int registered;
  final VoidCallback? onTap;

  const _EventItem({
    required this.title,
    required this.time,
    required this.location,
    required this.imageAsset,
    required this.capacity,
    required this.registered,
    this.onTap,
    required this.date,
  });

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    // Basic logic for fullness
    final isFull = capacity > 0 && registered >= capacity;

    // Past Check Logic
    bool isPast = false;
    final now = DateTime.now();

    // Parse time string "HH:mm"
    TimeOfDay? timeOfDay;
    if (time.isNotEmpty && time.contains(':')) {
      try {
        final parts = time.split(':');
        timeOfDay = TimeOfDay(
          hour: int.parse(parts[0]),
          minute: int.parse(parts[1]),
        );
      } catch (_) {}
    }

    final checkDateTime = DateTime(
      date.year,
      date.month,
      date.day,
      timeOfDay?.hour ?? 23,
      timeOfDay?.minute ?? 59,
    );

    if (checkDateTime.isBefore(now)) {
      isPast = true;
    }

    return Card(
      // Use Card for elevation/shape to hold InkWell correctly
      elevation: isPast ? 0 : 2,
      color: isPast
          ? Colors.grey[100]
          : (isFull ? Colors.grey[200] : Colors.white),
      surfaceTintColor: Colors.transparent, // No pink tint
      margin: EdgeInsets.only(bottom: 16), // Add margin if listed
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ResponsiveUtils.spacing(context, 12)),
        side: isPast ? BorderSide(color: Colors.grey[300]!) : BorderSide.none,
      ),
      child: InkWell(
        // Visual feedback!
        onTap: onTap,
        borderRadius: BorderRadius.circular(ResponsiveUtils.spacing(context, 12)),
        child: Opacity(
          opacity: isPast ? 0.7 : 1.0,
          child: Padding(
            padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 16)),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    title,
                                    style: TextStyle(
                                      fontSize: ResponsiveUtils.sp(context, 20),
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFF0D141B),
                                    ),
                                  ),
                                ),
                                if (isFull && !isPast)
                                  Container(
                                    margin: EdgeInsets.only(
                                      left: ResponsiveUtils.spacing(context, 8),
                                    ),
                                    padding: EdgeInsets.symmetric(
                                      horizontal: ResponsiveUtils.spacing(context, 8),
                                      vertical: ResponsiveUtils.spacing(context, 4),
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      borderRadius: BorderRadius.circular(ResponsiveUtils.spacing(context, 4)),
                                    ),
                                    child: Text(
                                      'FULL',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: ResponsiveUtils.sp(context, 10),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                if (isPast)
                                  Container(
                                    margin: EdgeInsets.only(
                                      left: ResponsiveUtils.spacing(context, 8),
                                    ),
                                    padding: EdgeInsets.symmetric(
                                      horizontal: ResponsiveUtils.spacing(context, 8),
                                      vertical: ResponsiveUtils.spacing(context, 4),
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[600],
                                      borderRadius: BorderRadius.circular(ResponsiveUtils.spacing(context, 4)),
                                    ),
                                    child: Text(
                                      'ENDED',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: ResponsiveUtils.sp(context, 10),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            SizedBox(height: ResponsiveUtils.spacing(context, 12)),
                            Row(
                              children: [
                                Icon(
                                  Icons.schedule,
                                  size: ResponsiveUtils.iconSize(context) * (22 / 24),
                                  color: Colors.blueGrey[700],
                                ),
                                SizedBox(width: ResponsiveUtils.spacing(context, 8)),
                                Text(
                                  time,
                                  style: TextStyle(
                                    color: Colors.blueGrey[700],
                                    fontSize: ResponsiveUtils.sp(context, 16),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: ResponsiveUtils.spacing(context, 8)),
                            Row(
                              children: [
                                Icon(
                                  Icons.location_on,
                                  size: ResponsiveUtils.iconSize(context) * (22 / 24),
                                  color: Colors.blueGrey[700],
                                ),
                                SizedBox(width: ResponsiveUtils.spacing(context, 8)),
                                Text(
                                  location,
                                  style: TextStyle(
                                    color: Colors.blueGrey[700],
                                    fontSize: ResponsiveUtils.sp(context, 16),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: ResponsiveUtils.spacing(context, 8)),
                            Row(
                              children: [
                                Icon(
                                  Icons.people,
                                  size: ResponsiveUtils.iconSize(context) * (22 / 24),
                                  color: Colors.blueGrey[700],
                                ),
                                SizedBox(width: ResponsiveUtils.spacing(context, 8)),
                                Text(
                                  '$registered / $capacity Registered',
                                  style: TextStyle(
                                    color: isFull
                                        ? Colors.red
                                        : Colors.blueGrey[700],
                                    fontSize: ResponsiveUtils.sp(context, 14),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        SizedBox(height: ResponsiveUtils.spacing(context, 16)),
                        // Button looking widget but just visual since whole card is InkWell
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(ResponsiveUtils.spacing(context, 8)),
                          ),
                          padding: EdgeInsets.symmetric(
                            vertical: ResponsiveUtils.spacing(context, 10),
                            horizontal: ResponsiveUtils.spacing(context, 16),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'View Details',
                                style: TextStyle(
                                  color: Color(0xFF0D141B),
                                  fontWeight: FontWeight.w600,
                                  fontSize: ResponsiveUtils.sp(context, 14),
                                ),
                              ),
                              SizedBox(width: ResponsiveUtils.spacing(context, 6)),
                              Icon(
                                Icons.arrow_forward,
                                size: ResponsiveUtils.iconSize(context) * (18 / 24),
                                color: Color(0xFF0D141B),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: ResponsiveUtils.spacing(context, 16)),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(ResponsiveUtils.spacing(context, 8)),
                    child: (imageAsset.startsWith('http'))
                        ? Image.network(
                            imageAsset,
                            width: ResponsiveUtils.wp(context, 112 / 375),
                            height: ResponsiveUtils.hp(context, 120 / 844),
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                _buildErrorImage(context),
                          )
                        : Image.asset(
                            imageAsset,
                            width: ResponsiveUtils.wp(context, 112 / 375),
                            height: ResponsiveUtils.hp(context, 120 / 844),
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                _buildErrorImage(context),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorImage(BuildContext context) {
    return Container(
      width: ResponsiveUtils.wp(context, 112 / 375),
      height: ResponsiveUtils.hp(context, 120 / 844),
      color: Colors.grey[300],
      child: const Icon(Icons.image, color: Colors.grey),
    );
  }
}

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  const _SearchBar({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: 'Search events...',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: controller.text.isNotEmpty
            ? IconButton(icon: const Icon(Icons.close), onPressed: onClear)
            : null,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ResponsiveUtils.spacing(context, 12)),
          borderSide: BorderSide.none,
        ),
        contentPadding: EdgeInsets.symmetric(
          vertical: ResponsiveUtils.spacing(context, 12),
          horizontal: ResponsiveUtils.spacing(context, 12),
        ),
      ),
      textInputAction: TextInputAction.search,
    );
  }
}
