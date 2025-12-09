import 'dart:async';
import 'package:flutter/material.dart';
import 'events_activities_manage_screen.dart';

class AdminEventsScreen extends StatefulWidget {
  const AdminEventsScreen({super.key});

  @override
  State<AdminEventsScreen> createState() => _AdminEventsScreenState();
}

class _AdminEventsScreenState extends State<AdminEventsScreen> {
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

  List<_EventData> get _events => [
        _EventData(
          date: DateTime(_today.year, _today.month, _today.day),
          title: 'Sunset Yoga Session',
          time: '4:00 PM - 5:00 PM',
          location: 'Poolside Deck',
          imageAsset: 'assets/images/arkaplanyok.png',
          capacity: 20,
          registered: 15,
          isPublished: true,
        ),
        _EventData(
          date: DateTime(_today.year, _today.month, _today.day),
          title: 'Live Jazz at the Lounge',
          time: '8:00 PM - 10:00 PM',
          location: 'The Oak Bar',
          imageAsset: 'assets/images/arkaplanyok1.png',
          capacity: 50,
          registered: 32,
          isPublished: true,
        ),
        _EventData(
          date: DateTime(_today.year, _today.month, _today.day + 1),
          title: 'Cooking Masterclass',
          time: '11:00 AM - 1:00 PM',
          location: 'Gourmet Kitchen',
          imageAsset: 'assets/images/arkaplan.jpg',
          capacity: 15,
          registered: 10,
          isPublished: true,
        ),
        _EventData(
          date: DateTime(_today.year, _today.month, _today.day + 2),
          title: 'Wine Tasting',
          time: '6:00 PM - 7:30 PM',
          location: 'Cellar Room',
          imageAsset: 'assets/images/arkaplanyok1.png',
          capacity: 25,
          registered: 18,
          isPublished: false,
        ),
        _EventData(
          date: DateTime(_today.year, _today.month, _today.day + 3),
          title: 'Pool Games',
          time: '3:00 PM - 4:00 PM',
          location: 'Main Pool',
          imageAsset: 'assets/images/arkaplanyok.png',
          capacity: 30,
          registered: 8,
          isPublished: true,
        ),
        _EventData(
          date: DateTime(_today.year, _today.month, _today.day + 4),
          title: 'City Walking Tour',
          time: '10:00 AM - 12:00 PM',
          location: 'Lobby Start',
          imageAsset: 'assets/images/arkaplan.jpg',
          capacity: 20,
          registered: 5,
          isPublished: false,
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
      if (!searching) return false;
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
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        title: const Text('Etkinlik Yönetimi'),
        centerTitle: true,
        backgroundColor: const Color(0xFFF6F7FB),
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.admin_panel_settings, color: Colors.orange, size: 16),
                SizedBox(width: 4),
                Text(
                  'Admin',
                  style: TextStyle(
                    color: Colors.orange,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
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
                      ? 'Aramanızla eşleşen etkinlik bulunamadı.'
                      : (_selectedDayIndexes.isEmpty
                          ? 'Yaklaşan etkinlik yok.'
                          : 'Seçili tarihlerde etkinlik yok.'),
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
            )
          else ...[
            ..._buildGroupedResults(items),
          ],
          const SizedBox(height: 80), // FAB için boşluk
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const EventsActivitiesManageScreen(),
            ),
          );
        },
        backgroundColor: Colors.blue,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Yeni Etkinlik',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

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
      widgets.add(_AdminEventItem(
        title: e.title,
        time: e.time,
        location: e.location,
        imageAsset: e.imageAsset,
        capacity: e.capacity,
        registered: e.registered,
        isPublished: e.isPublished,
        onEdit: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${e.title} düzenleme - Backend bekleniyor'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.orange,
            ),
          );
        },
        onDelete: () {
          _showDeleteConfirmation(context, e.title);
        },
      ));
      if (i != sorted.length - 1) widgets.add(const SizedBox(height: 10));
    }
    return widgets;
  }

  void _showDeleteConfirmation(BuildContext context, String eventTitle) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Etkinliği Sil'),
        content: Text('$eventTitle etkinliğini silmek istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('$eventTitle silindi (Backend bekleniyor)'),
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: Colors.red,
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
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

class _AdminEventItem extends StatelessWidget {
  final String title;
  final String time;
  final String location;
  final String imageAsset;
  final int capacity;
  final int registered;
  final bool isPublished;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _AdminEventItem({
    required this.title,
    required this.time,
    required this.location,
    required this.imageAsset,
    required this.capacity,
    required this.registered,
    required this.isPublished,
    this.onEdit,
    this.onDelete,
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
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isPublished 
                            ? Colors.green.withOpacity(0.1) 
                            : Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        isPublished ? 'Yayında' : 'Taslak',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: isPublished ? Colors.green : Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.schedule, size: 16, color: Colors.black54),
                    const SizedBox(width: 6),
                    Text(time, style: const TextStyle(color: Colors.black54, fontSize: 13)),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.place, size: 16, color: Colors.black54),
                    const SizedBox(width: 6),
                    Text(location, style: const TextStyle(color: Colors.black54, fontSize: 13)),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.people, size: 16, color: Colors.black54),
                    const SizedBox(width: 6),
                    Text(
                      '$registered / $capacity kayıt',
                      style: TextStyle(
                        color: registered >= capacity ? Colors.red : Colors.black54,
                        fontSize: 13,
                        fontWeight: registered >= capacity ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit, size: 16),
                      label: const Text('Düzenle'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        textStyle: const TextStyle(fontSize: 12),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete, size: 16, color: Colors.red),
                      label: const Text('Sil', style: TextStyle(color: Colors.red)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        textStyle: const TextStyle(fontSize: 12),
                        side: const BorderSide(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(imageAsset, width: 80, height: 80, fit: BoxFit.cover),
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
        hintText: 'Etkinlik ara...',
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
  final int capacity;
  final int registered;
  final bool isPublished;

  const _EventData({
    required this.date,
    required this.title,
    required this.time,
    required this.location,
    required this.imageAsset,
    required this.capacity,
    required this.registered,
    required this.isPublished,
  });
}
