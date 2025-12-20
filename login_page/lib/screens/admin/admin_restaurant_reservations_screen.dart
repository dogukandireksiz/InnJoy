import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../service/database_service.dart';

class AdminRestaurantReservationsScreen extends StatefulWidget {
  final String hotelName;
  final String restaurantId;

  const AdminRestaurantReservationsScreen({
    super.key,
    required this.hotelName,
    required this.restaurantId,
  });

  @override
  State<AdminRestaurantReservationsScreen> createState() => _AdminRestaurantReservationsScreenState();
}

class _AdminRestaurantReservationsScreenState extends State<AdminRestaurantReservationsScreen> {
  final DatabaseService _db = DatabaseService();
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF137fec);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        title: const Text('Reservations'),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _db.getRestaurantReservations(widget.hotelName, widget.restaurantId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final allReservations = snapshot.data ?? [];
          
          // Client-side filtering
          final dailyReservations = allReservations.where((res) {
            if (res['date'] == null) return false;
            DateTime resDate = (res['date'] as Timestamp).toDate();
            return resDate.year == _selectedDate.year &&
                   resDate.month == _selectedDate.month &&
                   resDate.day == _selectedDate.day;
          }).toList();

          return Column(
            children: [
              // 1. Date Navigation & Summary
              Container(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          onPressed: () => setState(() => _selectedDate = _selectedDate.subtract(const Duration(days: 1))),
                          icon: const Icon(Icons.arrow_back_ios, size: 18),
                        ),
                        GestureDetector(
                          onTap: () async {
                             final picked = await showDatePicker(
                               context: context,
                               initialDate: _selectedDate,
                               firstDate: DateTime.now().subtract(const Duration(days: 30)),
                               lastDate: DateTime.now().add(const Duration(days: 90)),
                             );
                             if (picked != null) {
                               setState(() => _selectedDate = picked);
                             }
                          },
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today, size: 20, color: primaryColor),
                              const SizedBox(width: 8),
                              Text(
                                "${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}",
                                style: const TextStyle(
                                  fontSize: 18, 
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF101922),
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => setState(() => _selectedDate = _selectedDate.add(const Duration(days: 1))),
                          icon: const Icon(Icons.arrow_forward_ios, size: 18),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _SummaryChip(
                          label: 'Total Guests',
                          value: dailyReservations.fold<int>(0, (sum, item) => sum + (item['partySize'] as int)).toString(),
                          icon: Icons.people,
                          color: Colors.orange,
                        ),
                        const SizedBox(width: 12),
                        _SummaryChip(
                          label: 'Bookings',
                          value: dailyReservations.length.toString(),
                          icon: Icons.restaurant,
                          color: Colors.green,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // 2. Reservation List
              Expanded(
                child: dailyReservations.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.event_note, size: 80, color: Colors.grey[300]),
                            const SizedBox(height: 16),
                            Text(
                              'No reservations for this date',
                              style: TextStyle(color: Colors.grey[500], fontSize: 16),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: dailyReservations.length,
                        itemBuilder: (context, index) {
                          final res = dailyReservations[index];
                          final hasNote = res['note'] != null && res['note'].toString().isNotEmpty;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Table Indicator
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: primaryColor.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: primaryColor.withOpacity(0.2)),
                                        ),
                                        child: Column(
                                          children: [
                                            const Text(
                                              'TABLE',
                                              style: TextStyle(
                                                fontSize: 10, 
                                                fontWeight: FontWeight.bold, 
                                                color: primaryColor
                                              ),
                                            ),
                                            Text(
                                              '${res['tableNumber']}',
                                              style: const TextStyle(
                                                fontSize: 24, 
                                                fontWeight: FontWeight.bold, 
                                                color: primaryColor
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              res['userName'] ?? 'Guest',
                                              style: const TextStyle(
                                                fontSize: 18, 
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF101922),
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                                                const SizedBox(width: 4),
                                                Text(
                                                  '20:00', 
                                                  style: TextStyle(color: Colors.grey[600], fontSize: 13)
                                                ),
                                                const SizedBox(width: 12),
                                                Icon(Icons.people_outline, size: 14, color: Colors.grey[600]),
                                                const SizedBox(width: 4),
                                                Text(
                                                  '${res['partySize']} Guests', 
                                                  style: TextStyle(color: Colors.grey[600], fontSize: 13)
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      // Status Chip
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.green.shade50,
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: Colors.green.shade100),
                                        ),
                                        child: const Text(
                                          'Confirmed',
                                          style: TextStyle(
                                            fontSize: 12, 
                                            fontWeight: FontWeight.bold,
                                            color: Colors.green
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (hasNote)
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    decoration: BoxDecoration(
                                      color: Colors.amber.shade50,
                                      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                                    ),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Icon(Icons.notes, size: 16, color: Colors.amber.shade800),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'Note: ${res['note']}',
                                            style: TextStyle(
                                              color: Colors.amber.shade900,
                                              fontSize: 13,
                                              fontStyle: FontStyle.italic,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryChip({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: color,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: color.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
