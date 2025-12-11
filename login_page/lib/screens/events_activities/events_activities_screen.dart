import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../service/database_service.dart';
import 'event_details_screen.dart';

class EventsActivitiesScreen extends StatefulWidget {
  final String hotelName;
  const EventsActivitiesScreen({super.key, required this.hotelName});

  @override
  State<EventsActivitiesScreen> createState() => _EventsActivitiesScreenState();
}

class _EventsActivitiesScreenState extends State<EventsActivitiesScreen> {
  Set<int> _selectedDayIndexes = {0};
  String _query = '';
  DateTime _today = DateTime.now();
  Timer? _dayTick;

  List<DateTime> get _days =>
      List.generate(5, (i) => DateTime(_today.year, _today.month, _today.day + i));

  String _humanDate(DateTime d) {
    return "${_monthName(d.month)} ${d.day}";
  }

  String _monthName(int m) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[m - 1];
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _weekdayName(int weekday) {
    const map = {1: 'Monday', 2: 'Tuesday', 3: 'Wednesday', 4: 'Thursday', 5: 'Friday', 6: 'Saturday', 7: 'Sunday'};
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

  @override
  void initState() {
    super.initState();
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
          if (_selectedDayIndexes.isNotEmpty) {
            _selectedDayIndexes = {0};
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
        stream: DatabaseService().getHotelEvents(widget.hotelName),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
             return Center(child: Text("Error: ${snapshot.error}"));
          }
          
          final allEvents = snapshot.data ?? [];
          
          // Filter: Published only
          final publishedEvents = allEvents.where((e) => e['isPublished'] == true).toList();

          final selectedDates = _selectedDayIndexes.map((i) {
            final d = _days[i];
            return DateTime(d.year, d.month, d.day);
          }).toList();
          
          final q = _query.trim().toLowerCase();
          final searching = q.isNotEmpty;

          final filtered = publishedEvents.where((e) {
             // Search filter
             if (searching) {
               final title = (e['title'] ?? '').toString().toLowerCase();
               final loc = (e['location'] ?? '').toString().toLowerCase();
               return title.contains(q) || loc.contains(q);
             }
             
             // Date filter
             if (_selectedDayIndexes.isEmpty) return true;
             
             if (e['date'] != null && e['date'] is Timestamp) {
               final eDate = (e['date'] as Timestamp).toDate();
               return selectedDates.any((d) => _isSameDay(eDate, d));
             }
             return false;
          }).toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _SearchBar(
                initialValue: _query,
                onChanged: (v) => setState(() => _query = v),
                onClear: () => setState(() => _query = ''),
              ),
              const SizedBox(height: 12),
              _DateScroller(
                days: _days,
                selectedIndexes: _selectedDayIndexes,
                onToggle: (i) => setState(() {
                  if (_selectedDayIndexes.contains(i)) {
                    _selectedDayIndexes.remove(i);
                  } else {
                    _selectedDayIndexes.add(i);
                  }
                }),
              ),
              const SizedBox(height: 16),
              if (filtered.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text(
                      searching
                          ? 'No events match your search.'
                          : (_selectedDayIndexes.isEmpty
                              ? 'No upcoming events.'
                              : 'No events for selected dates.'),
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ),
                )
              else 
                ..._buildGroupedResults(filtered),
            ],
          );
        }
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
        if (lastDate != null) widgets.add(const SizedBox(height: 16));
        widgets.add(Text(
          _headerFor(date),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ));
        widgets.add(const SizedBox(height: 12));
        lastDate = DateTime(date.year, date.month, date.day);
      }
      widgets.add(_EventItem(
        title: e['title'] ?? 'Unnamed Event',
        time: e['time'] ?? '',
        location: e['location'] ?? '',
        imageAsset: e['imageAsset'] ?? 'assets/images/arkaplanyok.png',
        capacity: e['capacity'] ?? 0,
        registered: e['registered'] ?? 0,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
               builder: (_) => EventDetailsScreen(
                 event: e,
                 hotelName: widget.hotelName, 
               ),
            ),
          );
        },
      ));
      if (i != items.length - 1) widgets.add(const SizedBox(height: 10));
    }
    return widgets;
  }
}

class _DateScroller extends StatelessWidget {
  final List<DateTime> days;
  final Set<int> selectedIndexes;
  final ValueChanged<int> onToggle;
  const _DateScroller({required this.days, required this.selectedIndexes, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 70,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, i) {
          final d = days[i];
          final selected = selectedIndexes.contains(i);
          return GestureDetector(
            onTap: () => onToggle(i),
            child: Container(
              width: 64, // w-16 ~ 64px
              height: 64, // h-16 ~ 64px
              decoration: BoxDecoration(
                color: selected ? const Color(0xFF137FEC) : Colors.white, // bg-primary
                borderRadius: BorderRadius.circular(32), // rounded-full
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05), // shadow-sm
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _dayLabel(d.weekday),
                    style: TextStyle(
                      color: selected ? Colors.white : const Color(0xFF0D141B), 
                      fontSize: 14, 
                      fontWeight: FontWeight.w500
                    ),
                  ),
                  Text(
                    d.day.toString(),
                    style: TextStyle(
                      color: selected ? Colors.white : const Color(0xFF0D141B),
                      fontSize: 20, // text-xl
                      fontWeight: FontWeight.bold
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemCount: days.length,
      ),
    );
  }

  String _dayLabel(int weekday) {
    const map = {1: 'Mon', 2: 'Tue', 3: 'Wed', 4: 'Thu', 5: 'Fri', 6: 'Sat', 7: 'Sun'};
    return map[weekday] ?? '';
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
  });

  @override
  Widget build(BuildContext context) {
    // Basic logic for fullness
    final isFull = capacity > 0 && registered >= capacity;

    return Card( // Use Card for elevation/shape to hold InkWell correctly
      elevation: 2,
      color: isFull ? Colors.grey[200] : Colors.white, // Grey bg if full
      surfaceTintColor: Colors.transparent, // No pink tint
      margin: const EdgeInsets.only(bottom: 16), // Add margin if listed
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell( // Visual feedback!
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
            padding: const EdgeInsets.all(16),
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
                                    style: const TextStyle(
                                      fontSize: 20, 
                                      fontWeight: FontWeight.w900, 
                                      color: Color(0xFF0D141B) 
                                    )
                                  ),
                                ),
                                if (isFull)
                                  Container(
                                    margin: const EdgeInsets.only(left: 8),
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text('DOLDU', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Icon(Icons.schedule, size: 22, color: Colors.blueGrey[700]), 
                                const SizedBox(width: 8),
                                Text(time, style: TextStyle(color: Colors.blueGrey[700], fontSize: 16, fontWeight: FontWeight.w600)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(Icons.location_on, size: 22, color: Colors.blueGrey[700]),
                                const SizedBox(width: 8),
                                Text(location, style: TextStyle(color: Colors.blueGrey[700], fontSize: 16, fontWeight: FontWeight.w600)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(Icons.people, size: 22, color: Colors.blueGrey[700]),
                                const SizedBox(width: 8),
                                Text(
                                  '$registered / $capacity Kayıtlı', 
                                  style: TextStyle(
                                    color: isFull ? Colors.red : Colors.blueGrey[700], 
                                    fontSize: 14, 
                                    fontWeight: FontWeight.w600
                                  )
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Button looking widget but just visual since whole card is InkWell
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9), 
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('View Details', style: TextStyle(color: Color(0xFF0D141B), fontWeight: FontWeight.w600, fontSize: 14)),
                              SizedBox(width: 6),
                              Icon(Icons.arrow_forward, size: 18, color: Color(0xFF0D141B)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset(
                      imageAsset, 
                      width: 112, 
                      height: 120, 
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 112,
                          height: 120,
                          color: Colors.grey[300],
                          child: const Icon(Icons.image, color: Colors.grey),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  final String initialValue;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  const _SearchBar({
    required this.initialValue,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final controller = TextEditingController(text: initialValue);
    controller.selection = TextSelection.fromPosition(
      TextPosition(offset: controller.text.length),
    );
    return TextField(
      controller: controller,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: 'Search events',
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
        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      ),
      textInputAction: TextInputAction.search,
    );
  }
}
