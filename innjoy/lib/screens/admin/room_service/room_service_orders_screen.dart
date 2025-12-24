
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class RoomServiceOrdersScreen extends StatefulWidget {
  final String hotelName;

  const RoomServiceOrdersScreen({super.key, required this.hotelName});

  @override
  State<RoomServiceOrdersScreen> createState() => _RoomServiceOrdersScreenState();
}

class _RoomServiceOrdersScreenState extends State<RoomServiceOrdersScreen> {
  String _selectedFilter = 'Active Orders';
  DateTime? _selectedDate;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      body: SafeArea(
        child: Column(
          children: [
             _buildHeader(),
             _buildSearchBar(),
             _buildFilterChips(),
             Expanded(child: _buildOrderList()),
          ],
        ),
      ),
    );
  }



  // Helper for Date Selection
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2023),
      lastDate: DateTime(2026),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        // Optionally clear other filters or keep them combined
      });
    }
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Color(0xFFF6F7FB),
        border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Color(0xFF111827)),
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(width: 8),
              const Text(
                'Room Service Management',
                style: TextStyle(
                  color: Color(0xFF111827),
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Inter',
                ),
              ),
            ],
          ),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 1)),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.notifications_outlined, color: Color(0xFF111827)),
              onPressed: () {},
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB)),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 2, offset: const Offset(0, 1)),
          ],
        ),
        child: Row(
          children: [
            const Padding(
              padding: EdgeInsets.only(left: 16, right: 12),
              child: Icon(Icons.search, color: Color(0xFF9CA3AF)),
            ),
            Expanded(
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search room service orders...',
                  hintStyle: TextStyle(color: Colors.grey[400], fontSize: 16),
                  border: InputBorder.none,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = [
      {'label': 'Active Orders'},
      {'label': 'Completed'},
      {'label': 'Cancelled'},
    ];

    return SizedBox(
      height: 60,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        scrollDirection: Axis.horizontal,
        children: [
          // Calendar Button
          GestureDetector(
            onTap: () => _selectDate(context),
            child: Container(
               margin: const EdgeInsets.only(right: 8),
               padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
               decoration: BoxDecoration(
                 color: _selectedDate != null ? const Color(0xFF137fec).withValues(alpha: 0.1) : Colors.white,
                 borderRadius: BorderRadius.circular(20),
                 border: Border.all(
                   color: _selectedDate != null ? const Color(0xFF137fec) : const Color(0xFFE5E7EB)
                 ),
               ),
               child: Row(
                 children: [
                   Icon(
                     Icons.calendar_month, 
                     color: _selectedDate != null ? const Color(0xFF137fec) : Colors.grey[600], 
                     size: 20
                   ),
                   if (_selectedDate != null) ...[
                     const SizedBox(width: 6),
                     Text(
                       DateFormat('dd MMM').format(_selectedDate!),
                       style: const TextStyle(
                         color: Color(0xFF137fec),
                         fontWeight: FontWeight.bold,
                         fontSize: 12,
                       ),
                     ),
                     const SizedBox(width: 4),
                     GestureDetector(
                       onTap: () => setState(() => _selectedDate = null),
                       child: const Icon(Icons.close, size: 16, color: Color(0xFF137fec)),
                     ),
                   ],
                 ],
               ),
             ),
          ),
          
          // Status Chips
          ...filters.map((filter) {
            final label = filter['label'] as String;
            final isSelected = _selectedFilter == label;
            
            return GestureDetector(
              onTap: () => setState(() => _selectedFilter = label),
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF137fec) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isSelected ? const Color(0xFF137fec) : const Color(0xFFE5E7EB)),
                   boxShadow: isSelected ? [
                     BoxShadow(color: const Color(0xFF137fec).withValues(alpha: 0.3), blurRadius: 4, offset: const Offset(0, 2))
                   ] : null,
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey[700],
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildOrderList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('hotels')
          .doc(widget.hotelName)
          .collection('room_service')
          .doc('orders')
          .collection('items')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          if (snapshot.error.toString().contains('requires an index')) {
             return const Center(
               child: Padding(
                 padding: EdgeInsets.all(16.0),
                 child: Text('Database index is being created... Please wait a moment or notify the developer.'),
               ),
             );
          }
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final docs = snapshot.data?.docs ?? [];
        
        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.restaurant_menu, size: 64, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text(
                  'No orders yet',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Text(
                  'Orders will appear here',
                  style: TextStyle(fontSize: 14, color: Colors.grey[400]),
                ),
              ],
            ),
          );
        }

        // Filter orders based on selected filter and date
        final filteredDocs = docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final status = data['status'] ?? 'Preparing';
          final timestamp = data['timestamp'] as Timestamp?;
          
          // Date filter logic - only apply if date is selected OR if not Active Orders
          if (timestamp == null) return false;
          final orderDate = timestamp.toDate();
          
          // For Active Orders without date selection, show ALL active orders (no date filter)
          // For other filters or when date is selected, apply date filter
          if (_selectedDate != null) {
            final filterDate = _selectedDate!;
            final isSameDay = orderDate.year == filterDate.year && 
                              orderDate.month == filterDate.month && 
                              orderDate.day == filterDate.day;
            if (!isSameDay) return false;
          } else if (_selectedFilter != 'Active Orders') {
            // For Completed/Cancelled without date, default to today
            final today = DateTime.now();
            final isSameDay = orderDate.year == today.year && 
                              orderDate.month == today.month && 
                              orderDate.day == today.day;
            if (!isSameDay) return false;
          }
          // If Active Orders and no date selected, show all (no date filter applied)

          // Status Filter
          if (_selectedFilter == 'Active Orders') {
            // Active covers: Active, Pending, Preparing
            return status == 'Active' || status == 'Pending' || status == 'Preparing';
          } else if (_selectedFilter == 'Completed') {
            return status == 'Completed';
          } else if (_selectedFilter == 'Cancelled') {
             return status == 'Cancelled';
          }

          return true;
        }).toList();

        if (filteredDocs.isEmpty) {
           return Center(
             child: Column(
               mainAxisAlignment: MainAxisAlignment.center,
               children: [
                 Icon(Icons.filter_list_off, size: 64, color: Colors.grey[300]),
                 const SizedBox(height: 16),
                 Text('No orders match these criteria.', style: TextStyle(color: Colors.grey[500])),
               ],
             ),
           );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: filteredDocs.length,
          separatorBuilder: (_, e) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
             final data = filteredDocs[index].data() as Map<String, dynamic>;
             return _OrderCard(
               id: filteredDocs[index].id,
               data: data,
               hotelName: widget.hotelName,
               onStatusUpdate: (id, newStatus) {
                 // Update in Firebase
                 FirebaseFirestore.instance
                     .collection('hotels')
                     .doc(widget.hotelName)
                     .collection('room_service')
                     .doc('orders')
                     .collection('items')
                     .doc(id)
                     .update({'status': newStatus});
               },
             );
          },
        );
      },
    );
  }
}

class _OrderCard extends StatelessWidget {
  final String id;
  final Map<String, dynamic> data;
  final String hotelName;
  final Function(String id, String newStatus) onStatusUpdate;

  const _OrderCard({
    required this.id,
    required this.data,
    required this.hotelName,
    required this.onStatusUpdate,
  });

  @override
  Widget build(BuildContext context) {
    final status = data['status'] ?? 'Active';
    final room = data['roomNumber'] ?? 'Unknown';
    final totalPrice = data['totalPrice'] ?? 0;
    final items = (data['items'] as List<dynamic>?) ?? [];
    final timestamp = data['timestamp'] as Timestamp?;
    final timeStr = timestamp != null ? DateFormat('HH:mm').format(timestamp.toDate()) : '--:--';
    final dateStr = timestamp != null ? DateFormat('dd MMM').format(timestamp.toDate()) : '';

    // Status Styling Map
    final statusStyles = {
      'Active': {
        'label': 'Active',
        'color': Colors.blue,
        'bg': Colors.blue[50],
        'text': Colors.blue[800],
      },
      'Pending': {
        'label': 'Active',
        'color': Colors.blue,
        'bg': Colors.blue[50],
        'text': Colors.blue[800],
      },
      'Preparing': {
        'label': 'Active',
        'color': Colors.blue,
        'bg': Colors.blue[50],
        'text': Colors.blue[800],
      },
      'Completed': {
        'label': 'Completed',
        'color': Colors.green,
        'bg': Colors.green[50],
        'text': Colors.green[800],
      },
      'Cancelled': {
        'label': 'Cancelled',
        'color': Colors.red,
        'bg': Colors.red[50],
        'text': Colors.red[800],
      },
    };

    final style = statusStyles[status] ?? statusStyles['Active']!;
    final color = style['color'] as Color;
    final bgColor = style['bg'] as Color?;
    final textColor = style['text'] as Color?;
    final label = style['label'] as String;

    final itemNames = items.map((i) => i['name']).join(', ');

    return GestureDetector(
      onTap: () => _showOrderDetails(context),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Stack(
          children: [
            // Left colored strip
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: 4,
              child: Container(color: color),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header: Status Badge and Room/Name
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: bgColor,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: color,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  label,
                                  style: TextStyle(
                                    color: textColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Room $room',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF111827),
                            ),
                          ),
                          Text(
                            data['guestName'] ?? 'Guest',
                            style: const TextStyle(
                              color: Color(0xFF6B7280),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      // Date & Time display
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            dateStr,
                            style: const TextStyle(
                              color: Color(0xFF137fec),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            timeStr,
                            style: const TextStyle(
                              color: Color(0xFF111827),
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Divider(color: Colors.grey[200]),
                  const SizedBox(height: 12),
                  
                  // Content: Items
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Order Items',
                              style: TextStyle(
                                color: Color(0xFF4B5563),
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              itemNames.isNotEmpty ? itemNames : 'No items',
                              style: const TextStyle(
                                color: Color(0xFF6B7280),
                                fontSize: 14,
                                height: 1.5,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text(
                            'Total',
                            style: TextStyle(
                              color: Color(0xFF9CA3AF),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            '₺${totalPrice.toStringAsFixed(0)}',
                            style: const TextStyle(
                              color: Color(0xFF111827),
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
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
    );
  }

  void _showOrderDetails(BuildContext context) {
    final status = data['status'] ?? 'Active';
    final room = data['roomNumber'] ?? 'Unknown';
    final totalPrice = data['totalPrice'] ?? 0;
    final items = (data['items'] as List<dynamic>?) ?? [];
    final timestamp = data['timestamp'] as Timestamp?;
    final dateStr = timestamp != null ? DateFormat('dd MMMM yyyy, HH:mm', 'en_US').format(timestamp.toDate()) : 'Unknown';
    final guestName = data['guestName'] ?? 'Guest';
    final notes = data['notes'] ?? '';

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(24),
          constraints: const BoxConstraints(maxWidth: 500),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Order Details',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF111827),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Order Info
                _buildInfoRow('Room Number', room.toString()),
                _buildInfoRow('Guest', guestName),
                _buildInfoRow('Date & Time', dateStr),
                _buildInfoRow('Status', _getStatusLabel(status)),
                
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),
                
                // Items List
                const Text(
                  'Order Items',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 12),
                ...items.map((item) {
                  final name = item['name'] ?? '';
                  final quantity = item['quantity'] ?? 1;
                  final price = item['price'] ?? 0;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            '$quantity x $name',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                        Text(
                          '₺${(price * quantity).toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                
                if (notes.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 16),
                  const Text(
                    'Notes',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    notes,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
                
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),
                
                // Total
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total Amount',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '₺${totalPrice.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF137fec),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // Action Buttons (only show if not completed or cancelled)
                if (status != 'Completed' && status != 'Cancelled')
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            _updateOrderStatus(context, 'Cancelled');
                            Navigator.pop(ctx);
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: const BorderSide(color: Colors.red),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            _updateOrderStatus(context, 'Completed');
                            Navigator.pop(ctx);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Completed',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF111827),
            ),
          ),
        ],
      ),
    );
  }

  String _getStatusLabel(String status) {
    final labels = {
      'Preparing': 'Preparing',
      'Completed': 'Delivered',
      'Cancelled': 'Cancelled',
    };
    return labels[status] ?? status;
  }

  void _updateOrderStatus(BuildContext context, String newStatus) {
    onStatusUpdate(id, newStatus);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Order status updated: ${_getStatusLabel(newStatus)}'),
        backgroundColor: newStatus == 'Completed' ? Colors.green : Colors.red,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}









