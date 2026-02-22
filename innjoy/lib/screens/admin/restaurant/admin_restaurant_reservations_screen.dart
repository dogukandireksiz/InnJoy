import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../services/database_service.dart';
import '../../../utils/responsive_utils.dart';

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
                padding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
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
                          icon: Icon(Icons.arrow_back_ios, size: ResponsiveUtils.iconSize(context) * (18 / 24)),
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
                              Icon(Icons.calendar_today, size: ResponsiveUtils.iconSize(context) * (20 / 24), color: primaryColor),
                              SizedBox(width: ResponsiveUtils.spacing(context, 8)),
                              Text(
                                "${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}",
                                style: TextStyle(
                                  fontSize: ResponsiveUtils.sp(context, 18), 
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF101922),
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => setState(() => _selectedDate = _selectedDate.add(const Duration(days: 1))),
                          icon: Icon(Icons.arrow_forward_ios, size: ResponsiveUtils.iconSize(context) * (18 / 24)),
                        ),
                      ],
                    ),
                    SizedBox(height: ResponsiveUtils.spacing(context, 12)),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _SummaryChip(
                          label: 'Total Guests',
                          value: dailyReservations.fold<int>(0, (totalCount, item) => totalCount + (item['partySize'] as int)).toString(),
                          icon: Icons.people,
                          color: Colors.orange,
                        ),
                        SizedBox(width: ResponsiveUtils.spacing(context, 12)),
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
                            Icon(Icons.event_note, size: ResponsiveUtils.iconSize(context) * (80 / 24), color: Colors.grey[300]),
                            SizedBox(height: ResponsiveUtils.spacing(context, 16)),
                            Text(
                              'No reservations for this date',
                              style: TextStyle(color: Colors.grey[500], fontSize: ResponsiveUtils.sp(context, 16)),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 16)),
                        itemCount: dailyReservations.length,
                        itemBuilder: (context, index) {
                          final res = dailyReservations[index];
                          final hasNote = res['note'] != null && res['note'].toString().isNotEmpty;

                          return Container(
                            margin: EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(ResponsiveUtils.spacing(context, 16)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                Padding(
                                  padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 16)),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Table Indicator
                                      Container(
                                        padding: EdgeInsets.symmetric(horizontal: ResponsiveUtils.spacing(context, 12), vertical: ResponsiveUtils.spacing(context, 8)),
                                        decoration: BoxDecoration(
                                          color: primaryColor.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(ResponsiveUtils.spacing(context, 12)),
                                          border: Border.all(color: primaryColor.withValues(alpha: 0.2)),
                                        ),
                                        child: Column(
                                          children: [
                                            Text(
                                              'TABLE',
                                              style: TextStyle(
                                                fontSize: ResponsiveUtils.sp(context, 10), 
                                                fontWeight: FontWeight.bold, 
                                                color: primaryColor
                                              ),
                                            ),
                                            Text(
                                              '${res['tableNumber']}',
                                              style: TextStyle(
                                                fontSize: ResponsiveUtils.sp(context, 24), 
                                                fontWeight: FontWeight.bold, 
                                                color: primaryColor
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      SizedBox(width: ResponsiveUtils.spacing(context, 16)),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              res['userName'] ?? 'Guest',
                                              style: TextStyle(
                                                fontSize: ResponsiveUtils.sp(context, 18), 
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF101922),
                                              ),
                                            ),
                                            SizedBox(height: ResponsiveUtils.spacing(context, 4)),
                                            Row(
                                              children: [
                                                Icon(Icons.access_time, size: ResponsiveUtils.iconSize(context) * (14 / 24), color: Colors.grey[600]),
                                                SizedBox(width: ResponsiveUtils.spacing(context, 4)),
                                                Text(
                                                  '20:00', 
                                                  style: TextStyle(color: Colors.grey[600], fontSize: ResponsiveUtils.sp(context, 13))
                                                ),
                                                SizedBox(width: ResponsiveUtils.spacing(context, 12)),
                                                Icon(Icons.people_outline, size: ResponsiveUtils.iconSize(context) * (14 / 24), color: Colors.grey[600]),
                                                SizedBox(width: ResponsiveUtils.spacing(context, 4)),
                                                Text(
                                                  '${res['partySize']} Guests', 
                                                  style: TextStyle(color: Colors.grey[600], fontSize: ResponsiveUtils.sp(context, 13))
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      // Status Chip
                                      Container(
                                        padding: EdgeInsets.symmetric(horizontal: ResponsiveUtils.spacing(context, 8), vertical: ResponsiveUtils.spacing(context, 4)),
                                        decoration: BoxDecoration(
                                          color: Colors.green.shade50,
                                          borderRadius: BorderRadius.circular(ResponsiveUtils.spacing(context, 8)),
                                          border: Border.all(color: Colors.green.shade100),
                                        ),
                                        child: Text(
                                          'Confirmed',
                                          style: TextStyle(
                                            fontSize: ResponsiveUtils.sp(context, 12), 
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
                                    padding: EdgeInsets.symmetric(horizontal: ResponsiveUtils.spacing(context, 16), vertical: ResponsiveUtils.spacing(context, 12)),
                                    decoration: BoxDecoration(
                                      color: Colors.amber.shade50,
                                      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                                    ),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Icon(Icons.notes, size: ResponsiveUtils.iconSize(context) * (16 / 24), color: Colors.amber.shade800),
                                        SizedBox(width: ResponsiveUtils.spacing(context, 8)),
                                        Expanded(
                                          child: Text(
                                            'Note: ${res['note']}',
                                            style: TextStyle(
                                              color: Colors.amber.shade900,
                                              fontSize: ResponsiveUtils.sp(context, 13),
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
      padding: EdgeInsets.symmetric(horizontal: ResponsiveUtils.spacing(context, 12), vertical: ResponsiveUtils.spacing(context, 8)),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(ResponsiveUtils.spacing(context, 20)),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: ResponsiveUtils.iconSize(context) * (16 / 24), color: color),
          SizedBox(width: ResponsiveUtils.spacing(context, 8)),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: ResponsiveUtils.sp(context, 14),
                  color: color,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: ResponsiveUtils.sp(context, 10),
                  color: color.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}









