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
  Set<int> _selectedDayIndexes = {0};
  String _query = '';

  DateTime _today = DateTime.now();
  Timer? _dayTick;

  // Generate next 5 days for the scroller
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
        title: const Text('Etkinlik Yönetimi'),
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
             return Center(child: Text("Hata: ${snapshot.error}"));
          }
          
          final allEvents = snapshot.data ?? [];
          
          // Filter and Process
          final selectedDates = _selectedDayIndexes.map((i) {
            final d = _days[i];
            return DateTime(d.year, d.month, d.day);
          }).toList();
          
          final q = _query.trim().toLowerCase();
          final searching = q.isNotEmpty;

          // Map to internal logic objects if needed, or just use Maps.
          // Let's filter first.
          final filtered = allEvents.where((e) {
             // Search filter
             if (searching) {
               final title = (e['title'] ?? '').toString().toLowerCase();
               final loc = (e['location'] ?? '').toString().toLowerCase();
               return title.contains(q) || loc.contains(q);
             }
             
             // Date filter
             if (_selectedDayIndexes.isEmpty) return true; // Should not happen with current logic (default 0)
             
             // Check if event date matches any selected date
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
                          ? 'Aramanızla eşleşen etkinlik bulunamadı.'
                          : 'Seçili tarihlerde etkinlik yok.',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ),
                )
              else 
                ..._buildGroupedResults(filtered),
                
              const SizedBox(height: 80), 
            ],
          );
        }
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => EventsActivitiesManageScreen(hotelName: widget.hotelName),
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

  List<Widget> _buildGroupedResults(List<Map<String, dynamic>> items) {
    final widgets = <Widget>[];
    // Sort logic handled by Firestore mostly, but good to re-sort if we merged lists or something.
    // Ensure we parse dates for sorting
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
      
      widgets.add(_AdminEventItem(
        data: e,
        hotelName: widget.hotelName, // Pass hotelName
        onEdit: () {
            Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => EventsActivitiesManageScreen(
                hotelName: widget.hotelName,
                eventToEdit: e,
              ),
            ),
          );
        },
        onDelete: () {
          _showDeleteConfirmation(context, e);
        },
      ));
      if (i != items.length - 1) widgets.add(const SizedBox(height: 10));
    }
    return widgets;
  }

  void _showDeleteConfirmation(BuildContext context, Map<String, dynamic> event) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Etkinliği Sil'),
        content: Text('${event['title']} etkinliğini silmek istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                await DatabaseService().deleteEvent(widget.hotelName, event['id']);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${event['title']} silindi'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } catch (e) {
                 if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Hata: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
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
  Widget build(BuildContext context) {
    final title = data['title'] ?? 'Adsız Etkinlik';
    final time = data['time'] ?? ''; // Using display string
    final location = data['location'] ?? '';
    final imageAsset = data['imageAsset'] ?? 'assets/images/arkaplanyok.png';
    final capacity = data['capacity'] ?? 0;
    final registered = data['registered'] ?? 0;
    final isPublished = data['isPublished'] ?? false;

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
      padding: const EdgeInsets.all(16), // Increased padding
      constraints: const BoxConstraints(minHeight: 160), // Enforce taller card
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: isPublished 
                            ? Colors.green.withOpacity(0.1) 
                            : Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        isPublished ? 'Yayında' : 'Taslak',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isPublished ? Colors.green : Colors.grey[700],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.schedule, size: 18, color: Colors.black54),
                    const SizedBox(width: 6),
                    Text(time, style: const TextStyle(color: Colors.black54, fontSize: 15, fontWeight: FontWeight.w500)),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.place, size: 18, color: Colors.black54),
                    const SizedBox(width: 6),
                    Text(location, style: const TextStyle(color: Colors.black54, fontSize: 15, fontWeight: FontWeight.w500)),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.people, size: 18, color: Colors.black54),
                    const SizedBox(width: 6),
                    Text(
                      '$registered / $capacity kayıt',
                      style: TextStyle(
                        color: registered >= capacity ? Colors.red : Colors.black54,
                        fontSize: 14,
                        fontWeight: registered >= capacity ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20), // More space before buttons
                Wrap( // Use Wrap to prevent overflow if buttons need more space
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit, size: 18),
                      label: const Text('Düzenle'),
                      style: OutlinedButton.styleFrom(
                         padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                         textStyle: const TextStyle(fontSize: 13),
                         visualDensity: VisualDensity.compact,
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                      label: const Text('Sil', style: TextStyle(color: Colors.red)),
                      style: OutlinedButton.styleFrom(
                         padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                         textStyle: const TextStyle(fontSize: 13),
                         side: const BorderSide(color: Colors.red),
                         visualDensity: VisualDensity.compact,
                      ),
                    ),
                    OutlinedButton.icon( // Participants button moved here
                      onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => EventParticipantsScreen(
                                hotelName: hotelName, 
                                eventId: data['id'] ?? '',
                                eventTitle: title,
                              ),
                            ),
                          );
                      },
                      icon: const Icon(Icons.groups, size: 18, color: Colors.blue),
                      label: const Text('Katılımcılar', style: TextStyle(color: Colors.blue)),
                      style: OutlinedButton.styleFrom(
                         padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                         textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                         side: const BorderSide(color: Colors.blue),
                         visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(width: 16),

          // Image Right (Significantly Bigger)
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.asset(
              imageAsset, 
              width: 140, // Significantly bigger
              height: 140, // Significantly bigger
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 140,
                  height: 140,
                  color: Colors.grey[300],
                  child: const Icon(Icons.image, color: Colors.grey),
                );
              },
            ),
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
