import 'dart:async';
import 'package:flutter/material.dart';

class EventsActivitiesScreen extends StatefulWidget {
  const EventsActivitiesScreen({super.key});

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
            _selectedDayIndexes = {0}; // reset to Today only if a day is selected
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

  List<_EventData> get _events => [
        // Today
        _EventData(
          date: DateTime(_today.year, _today.month, _today.day),
          title: 'Sunset Yoga Session',
          time: '4:00 PM - 5:00 PM',
          location: 'Poolside Deck',
          imageAsset: 'assets/images/arkaplanyok.png',
        ),
        _EventData(
          date: DateTime(_today.year, _today.month, _today.day),
          title: 'Live Jazz at the Lounge',
          time: '8:00 PM - 10:00 PM',
          location: 'The Oak Bar',
          imageAsset: 'assets/images/arkaplanyok1.png',
        ),
        // Tomorrow
        _EventData(
          date: DateTime(_today.year, _today.month, _today.day + 1),
          title: 'Cooking Masterclass',
          time: '11:00 AM - 1:00 PM',
          location: 'Gourmet Kitchen',
          imageAsset: 'assets/images/arkaplan.jpg',
        ),
        // Day +2
        _EventData(
          date: DateTime(_today.year, _today.month, _today.day + 2),
          title: 'Wine Tasting',
          time: '6:00 PM - 7:30 PM',
          location: 'Cellar Room',
          imageAsset: 'assets/images/arkaplanyok1.png',
        ),
        // Day +3
        _EventData(
          date: DateTime(_today.year, _today.month, _today.day + 3),
          title: 'Pool Games',
          time: '3:00 PM - 4:00 PM',
          location: 'Main Pool',
          imageAsset: 'assets/images/arkaplanyok.png',
        ),
        // Day +4
        _EventData(
          date: DateTime(_today.year, _today.month, _today.day + 4),
          title: 'City Walking Tour',
          time: '10:00 AM - 12:00 PM',
          location: 'Lobby Start',
          imageAsset: 'assets/images/arkaplan.jpg',
        ),
      ];

  @override
  Widget build(BuildContext context) {
    final selectedDates = _selectedDayIndexes.map((i) {
      final d = _days[i];
      return DateTime(d.year, d.month, d.day);
    }).toList();
    final q = _query.trim().toLowerCase();
    final searching = q.isNotEmpty;
    final allFiltered = _events.where((e) {
      if (!searching) return false; // only used when searching
      return e.title.toLowerCase().contains(q) ||
          e.location.toLowerCase().contains(q) ||
          e.time.toLowerCase().contains(q);
    }).toList();
    final items = searching
      ? allFiltered
      : (_selectedDayIndexes.isEmpty
        ? [..._events]
        : _events.where((e) => selectedDates.any((d) => _isSameDay(e.date, d))).toList());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Events & Activities'),
        centerTitle: true,
      ),
      body: ListView(
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
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  searching
                      ? 'No events match your search.'
                      : (_selectedDayIndexes.isEmpty
                          ? 'No upcoming events.'
                          : 'No events for selected dates.'),
                ),
              ),
            )
          else ...[
            ..._buildGroupedResults(items),
          ],
        ],
      ),
    );
  }
}

extension on _EventsActivitiesScreenState {
  List<Widget> _buildGroupedResults(List<_EventData> items) {
    final widgets = <Widget>[];
    final sorted = [...items]..sort((a, b) => a.date.compareTo(b.date));
    DateTime? lastDate;
    for (var i = 0; i < sorted.length; i++) {
      final e = sorted[i];
      if (lastDate == null || !_isSameDay(lastDate, e.date)) {
        if (lastDate != null) widgets.add(const SizedBox(height: 16));
        widgets.add(Text(
          _headerFor(e.date),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ));
        widgets.add(const SizedBox(height: 12));
        lastDate = DateTime(e.date.year, e.date.month, e.date.day);
      }
      widgets.add(_EventItem(
        title: e.title,
        time: e.time,
        location: e.location,
        imageAsset: e.imageAsset,
      ));
      if (i != sorted.length - 1) widgets.add(const SizedBox(height: 10));
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
      height: 72,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, i) {
          final d = days[i];
          final selected = selectedIndexes.contains(i);
          return GestureDetector(
            onTap: () => onToggle(i),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: selected ? Colors.blue : Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: Colors.black12),
                    boxShadow: [
                      if (selected)
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                    ],
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _dayLabel(d.weekday),
                          style: TextStyle(
                            color: selected ? Colors.white : Colors.black54,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          d.day.toString(),
                          style: TextStyle(
                            color: selected ? Colors.white : Colors.black,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(width: 12),
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
  const _EventItem({
    required this.title,
    required this.time,
    required this.location,
    required this.imageAsset,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.schedule, size: 16, color: Colors.black54),
                    const SizedBox(width: 6),
                    Text(time, style: const TextStyle(color: Colors.black54)),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.place, size: 16, color: Colors.black54),
                    const SizedBox(width: 6),
                    Text(location, style: const TextStyle(color: Colors.black54)),
                  ],
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.chevron_right, size: 18),
                  label: const Text('View Details'),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(imageAsset, width: 96, height: 96, fit: BoxFit.cover),
          ),
        ],
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

class _EventData {
  final DateTime date;
  final String title;
  final String time;
  final String location;
  final String imageAsset;
  const _EventData({
    required this.date,
    required this.title,
    required this.time,
    required this.location,
    required this.imageAsset,
  });
}
