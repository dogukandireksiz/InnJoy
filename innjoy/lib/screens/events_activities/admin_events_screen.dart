import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../service/database_service.dart';
import 'events_activities_manage_screen.dart';
import 'event_participants_screen.dart';

class AdminEventsScreen extends StatefulWidget {
  final String hotelName;
  const AdminEventsScreen({super.key, required this.hotelName});

  @override
  State<AdminEventsScreen> createState() => _AdminEventsScreenState();
}

class _AdminEventsScreenState extends State<AdminEventsScreen> {
  int _selectedDayIndex = 7;
  String _query = '';

  DateTime _today = DateTime.now();
  Timer? _dayTick;

  // Generate date range: 7 days past + Today + 14 days future = 22 days
  List<DateTime> get _days => List.generate(
    22,
    (i) => DateTime(_today.year, _today.month, _today.day + (i - 7)),
  );

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;


  late TextEditingController _searchController;
  late Stream<List<Map<String, dynamic>>> _eventsStream;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(); // Initialize controller
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
          if (_selectedDayIndex != 7) {
            _selectedDayIndex = 7;
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _dayTick?.cancel();
    super.dispose();
  }

  String _headerFor(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final input = DateTime(date.year, date.month, date.day);

    if (input == today) return 'Today';
    if (input == today.subtract(const Duration(days: 1))) return 'Yesterday';

    // Using simple approach if locale not available or just hardcoding English months
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
    return '${input.day} ${months[input.month - 1]}';
  }

  Widget _buildPastList(List<Map<String, dynamic>> items) {
    // 1. Sort by date descending (Newest first)
    items.sort((a, b) {
      final da = (a['date'] as Timestamp?)?.toDate() ?? DateTime(0);
      final db = (b['date'] as Timestamp?)?.toDate() ?? DateTime(0);
      return db.compareTo(da); // Descending
    });

    // 2. Build list with headers
    final widgets = <Widget>[];
    DateTime? lastDate;

    for (var i = 0; i < items.length; i++) {
      final e = items[i];
      final dateTs = e['date'] as Timestamp?;
      final date = dateTs?.toDate() ?? DateTime.now(); // Fallback

      // Check if day changed
      if (lastDate == null || !_isSameDay(lastDate, date)) {
        if (lastDate != null) {
          widgets.add(const SizedBox(height: 24)); // Space between groups
        }
        widgets.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Text(
              _headerFor(date),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.grey[500],
                letterSpacing: 0.5,
              ),
            ),
          ),
        );
        lastDate = date;
      }

      widgets.add(
        _AdminEventItem(
          hotelName: widget.hotelName,
          data: e,
          onEdit: () => _editEvent(context, e),
          onDelete: () => _deleteEvent(context, e),
        ),
      );

      // Spacing between items in same group
      if (i < items.length - 1) {
        final nextDate =
            (items[i + 1]['date'] as Timestamp?)?.toDate() ?? DateTime.now();
        if (_isSameDay(date, nextDate)) {
          widgets.add(const SizedBox(height: 12));
        }
      }
    }

    return ListView(padding: const EdgeInsets.all(16), children: widgets);
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF6F7FB),
        appBar: AppBar(
          title: const Text('Event Management'),
          centerTitle: true,
          backgroundColor: const Color(0xFFF6F7FB),
          elevation: 0,
          scrolledUnderElevation: 0,
          bottom: const TabBar(
            indicatorColor: Color(0xFF3366FF),
            labelColor: Color(0xFF3366FF),
            unselectedLabelColor: Colors.grey,
            labelStyle: TextStyle(fontWeight: FontWeight.bold),
            tabs: [
              Tab(text: 'Upcoming'),
              Tab(text: 'Past'),
            ],
          ),
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
            final q = _query.trim().toLowerCase();
            final searching = q.isNotEmpty;

            // Dates used for filtering
            final now = DateTime.now();
            final todayStart = DateTime(now.year, now.month, now.day);

            // 1. FILTER: SEARCH
            // Common search filter for both tabs
            bool matchesSearch(Map<String, dynamic> e) {
              if (!searching) return true;
              final title = (e['title'] ?? '').toString().toLowerCase();
              final loc = (e['location'] ?? '').toString().toLowerCase();
              return title.contains(q) || loc.contains(q);
            }

            // 2. SPLIT EVENTS (Upcoming vs Past)

            // UPCOMING/CALENDAR: Includes last 7 days + future
            // Calculates the start date for the calendar view (7 days ago)
            final calendarStartDate = todayStart.subtract(
              const Duration(days: 7),
            );

            final upcomingEvents = allEvents.where((e) {
              if (!matchesSearch(e)) return false;

              if (e['date'] != null && e['date'] is Timestamp) {
                final eDate = (e['date'] as Timestamp).toDate();
                final eDateBase = DateTime(eDate.year, eDate.month, eDate.day);
                // Include events within the calendar range (last 7 days + future)
                return !eDateBase.isBefore(calendarStartDate);
              }
              return false;
            }).toList();

            // PAST: Date < Today
            final pastEvents = allEvents.where((e) {
              if (!matchesSearch(e)) return false;

              if (e['date'] != null && e['date'] is Timestamp) {
                final eDate = (e['date'] as Timestamp).toDate();
                final eDateBase = DateTime(eDate.year, eDate.month, eDate.day);
                return eDateBase.isBefore(todayStart);
              }
              return false;
            }).toList();

            // 3. SORTING

            // Sort Upcoming: Ascending (Nearest first)
            // But wait, the "Upcoming" view also relies on the Day Scroller.
            // So we need to further filter 'upcomingEvents' by the selected day for the list view.

            // Sort Past: Descending (Newest first)
            pastEvents.sort((a, b) {
              final da = (a['date'] as Timestamp?)?.toDate() ?? DateTime(0);
              final db = (b['date'] as Timestamp?)?.toDate() ?? DateTime(0);
              return db.compareTo(da);
            });

            // UPCOMING VIEW LOGIC (Calendar View)
            final targetDate = _days[_selectedDayIndex];
            final upcomingForSelectedDay = upcomingEvents.where((e) {
              // If searching, ignore date filter
              if (searching) return true;

              if (e['date'] != null && e['date'] is Timestamp) {
                final eDate = (e['date'] as Timestamp).toDate();
                return _isSameDay(eDate, targetDate);
              }
              return false;
            }).toList();

            // Sort selected day events by time
            upcomingForSelectedDay.sort((a, b) {
              final da = (a['date'] as Timestamp?)?.toDate() ?? DateTime(0);
              final db = (b['date'] as Timestamp?)?.toDate() ?? DateTime(0);
              return da.compareTo(db);
            });

            return Column(
              children: [
                Container(
                  color: const Color(0xFFF6F7FB),
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: _SearchBar(
                    controller: _searchController,
                    onChanged: (v) => setState(() => _query = v),
                    onClear: () {
                      setState(() {
                        _query = '';
                        _searchController.clear();
                      });
                    },
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      // --- TAB 1: UPCOMING ---
                      Column(
                        children: [
                          // SearchBar removed from here
                          const SizedBox(height: 8),
                          if (!searching)
                            _DateScroller(
                              days: _days,
                              selectedIndex: _selectedDayIndex,
                              onSelected: (i) =>
                                  setState(() => _selectedDayIndex = i),
                            ),
                          if (!searching)
                            const SizedBox(height: 16), // Conditional spacing
                          Expanded(
                            child: upcomingForSelectedDay.isEmpty
                                ? Container(
                                    height:
                                        MediaQuery.of(context).size.height *
                                        0.4,
                                    alignment: Alignment.center,
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.event_busy_rounded,
                                          size: 64,
                                          color: Colors.grey[300],
                                        ),
                                        const SizedBox(height: 16),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 40,
                                          ),
                                          child: Text(
                                            searching
                                                ? 'No events match your criteria.'
                                                : 'No events for this date.',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              color: Colors.grey[500],
                                              fontSize: 16,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : ListView.separated(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    itemCount: upcomingForSelectedDay.length,
                                    separatorBuilder: (_, e) =>
                                        const SizedBox(height: 16),
                                    itemBuilder: (context, index) {
                                      final e = upcomingForSelectedDay[index];
                                      return _AdminEventItem(
                                        hotelName: widget.hotelName,
                                        data: e,
                                        onEdit: () => _editEvent(context, e),
                                        onDelete: () =>
                                            _deleteEvent(context, e),
                                      );
                                    },
                                  ),
                          ),
                        ],
                      ),

                      // --- TAB 2: PAST ---
                      Column(
                        children: [
                          // SearchBar removed from here
                          const SizedBox(height: 8),
                          Expanded(
                            child: pastEvents.isEmpty
                                ? Container(
                                    height:
                                        MediaQuery.of(context).size.height *
                                        0.5,
                                    alignment: Alignment.center,
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.history_toggle_off,
                                          size: 64,
                                          color: Colors.grey[300],
                                        ),
                                        const SizedBox(height: 16),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 40,
                                          ),
                                          child: Text(
                                            'No past events found.',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              color: Colors.grey[500],
                                              fontSize: 16,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : _buildPastList(pastEvents),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    EventsActivitiesManageScreen(hotelName: widget.hotelName),
              ),
            );
          },
          backgroundColor: Colors.blue,
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text(
            'New Event',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }

  void _editEvent(BuildContext context, Map<String, dynamic> event) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EventsActivitiesManageScreen(
          hotelName: widget.hotelName,
          eventToEdit: event,
        ),
      ),
    );
  }

  void _deleteEvent(BuildContext context, Map<String, dynamic> event) {
    _showDeleteConfirmation(context, event);
  }

  void _showDeleteConfirmation(
    BuildContext context,
    Map<String, dynamic> event,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Event'),
        content: Text(
          'Are you sure you want to delete ${event['title']}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              Navigator.of(context).pop();
              try {
                await DatabaseService().deleteEvent(
                  widget.hotelName,
                  event['id'],
                );
                messenger.showSnackBar(
                  SnackBar(
                    content: Text('${event['title']} deleted'),
                    backgroundColor: Colors.red,
                  ),
                );
              } catch (e) {
                messenger.showSnackBar(
                  SnackBar(
                    content: Text('Error: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
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
  void didUpdateWidget(covariant _DateScroller oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Optional: Animate if selection changes programmatically?
    // For now, let's just stick to initial offset logic for the specialized "Start at Today" requirement.
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 70,
      child: ListView.separated(
        key: const PageStorageKey('admin_events_date_scroll_v2'),
        controller: _controller,
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, i) {
          final d = widget.days[i];
          final selected = i == widget.selectedIndex;
          return GestureDetector(
            onTap: () => widget.onSelected(i),
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: selected
                    ? (_isToday(d) ? Colors.green : const Color(0xFF137FEC))
                    : Colors.white,
                borderRadius: BorderRadius.circular(32),
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
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    d.day.toString(),
                    style: TextStyle(
                      color: selected
                          ? Colors.white
                          : (_isToday(d)
                                ? Colors.green
                                : const Color(0xFF0D141B)),
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (_isToday(d))
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      width: 4,
                      height: 4,
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
        separatorBuilder: (_, e) => const SizedBox(width: 8),
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

class _AdminEventItem extends StatefulWidget {
  final Map<String, dynamic> data;
  final String hotelName;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _AdminEventItem({
    required this.data,
    required this.hotelName,
    this.onEdit,
    this.onDelete,
  });

  @override
  State<_AdminEventItem> createState() => _AdminEventItemState();
}

class _AdminEventItemState extends State<_AdminEventItem> {
  bool _isLoading = false;

  Future<void> _updateStatus(bool newValue) async {
    setState(() => _isLoading = true);
    try {
      await DatabaseService().updateEvent(widget.hotelName, widget.data['id'], {
        'isPublished': newValue,
      });
      // UI update will happen automatically via StreamBuilder parent
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not update status: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.data['title'] ?? 'Unnamed Event';
    final time = widget.data['time'] ?? '';
    final location = widget.data['location'] ?? '';
    final imageAsset =
        widget.data['imageAsset'] ?? 'assets/images/arkaplanyok.png';
    final capacity = widget.data['capacity'] ?? 0;
    final registered = widget.data['registered'] ?? 0;
    final isPublished = widget.data['isPublished'] ?? false;
    final isFull = capacity > 0 && registered >= capacity;

    // -- Past Check Logic --
    bool isPast = false;
    if (widget.data['date'] != null && widget.data['date'] is Timestamp) {
      final date = (widget.data['date'] as Timestamp).toDate();
      final now = DateTime.now();

      // Parse time string "HH:mm" if exists
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
    }

    return Opacity(
      opacity: isPast ? 0.7 : 1.0,
      child: Container(
        decoration: BoxDecoration(
          color: isPast ? Colors.grey[50] : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: isPast ? Border.all(color: Colors.grey[300]!) : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            // Top Section: Image and Details
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image (Left)
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      image: DecorationImage(
                        image: (imageAsset.startsWith('http')) 
                          ? NetworkImage(imageAsset) 
                          : AssetImage(imageAsset) as ImageProvider,
                        fit: BoxFit.cover,
                        onError: (_, e) {}, // Simple error handling
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Details (Right)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: isPast 
                                ? const Color(0xFF0F172A).withValues(alpha: 0.6) 
                                : const Color(0xFF0F172A),
                            decoration: isPast
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),

                        // Date/Time
                        Row(
                          children: [
                            Icon(
                              Icons.schedule,
                              size: 18,
                              color: Colors.grey[500],
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                time,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),

                        // Location
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 16,
                              color: Colors.grey[500],
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                location,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ),
                          ],
                        ),

                        // Status Badge & Switch
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Capacity Badge
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: isFull
                                      ? Colors.red.withValues(alpha: 0.1)
                                      : Colors.blue.withValues(alpha: 0.1), // blue-50 or red-50
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: BoxDecoration(
                                        color: isFull
                                            ? Colors.red
                                            : const Color(0xFF137FEC), // primary
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Flexible(
                                      child: Text(
                                        isFull
                                            ? 'FULL ($registered/$capacity)'
                                            : '$registered/$capacity Registered',
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: isFull
                                              ? Colors.red
                                              : const Color(0xFF137FEC),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(width: 8),

                            // Custom Toggle
                            if (_isLoading)
                              const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            else
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Inactive',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: !isPublished
                                          ? Colors.black54
                                          : Colors.grey[400],
                                    ),
                                  ),
                                  Switch(
                                    value: isPublished,
                                    onChanged: _updateStatus,
                                    activeThumbColor: Colors.green,
                                    activeTrackColor: Colors.green.withValues(alpha: 0.4),
                                    materialTapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  Text(
                                    'Published',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: isPublished
                                          ? Colors.green
                                          : Colors.grey[400],
                                    ),
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

            // Divider
            const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),

            // Bottom Action Bar
            Row(
              children: [
                // Edit (Indigo)
                Expanded(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: widget.onEdit,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          border: Border(
                            right: BorderSide(color: Colors.grey[100]!),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.edit_outlined,
                              size: 18,
                              color: Colors.indigo[600],
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Edit',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.indigo[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // Participants (Teal)
                Expanded(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => EventParticipantsScreen(
                              hotelName: widget.hotelName,
                              eventId: widget.data['id'] ?? '',
                              eventTitle: title,
                            ),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          border: Border(
                            right: BorderSide(color: Colors.grey[100]!),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.people_outline,
                              size: 18,
                              color: Colors.teal[600],
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Participants',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.teal[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // Delete (Red)
                Expanded(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: widget.onDelete,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.delete_outline,
                              size: 18,
                              color: Colors.red[600],
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Delete',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.red[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
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
      controller: controller, // Use external controller
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: 'Search events...',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: controller.text.isNotEmpty
            ? IconButton(icon: const Icon(Icons.close), onPressed: onClear)
            : null,
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 12,
          horizontal: 12,
        ),
      ),
      textInputAction: TextInputAction.search,
    );
  }
}











