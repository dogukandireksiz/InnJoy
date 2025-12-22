import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../services/database_service.dart';

/// Customer Requests Screen
/// 
/// İsteklerin takip edildiği ekran - Housekeeping ve Room Service siparişleri
/// gösterilir, tarih seÇimi ve durum filtreleme yapılabilir.
class CustomerRequestsScreen extends StatefulWidget {
  final String hotelName;

  const CustomerRequestsScreen({super.key, required this.hotelName});

  @override
  State<CustomerRequestsScreen> createState() => _CustomerRequestsScreenState();
}

class _CustomerRequestsScreenState extends State<CustomerRequestsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime _selectedDate = DateTime.now();
  String _selectedFilter = 'All';
  final DatabaseService _db = DatabaseService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildTabBar(),
            _buildDateAndFilterRow(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildRoomServiceList(),
                  _buildHousekeepingList(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Color(0xFFF6F7FB),
        border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF111827)),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'My Requests',
              style: TextStyle(
                color: Color(0xFF111827),
                fontSize: 20,
                fontWeight: FontWeight.bold,
                fontFamily: 'Inter',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: const Color(0xFF137fec),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey[600],
        labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
        padding: const EdgeInsets.all(4),
        tabs: const [
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.room_service, size: 18),
                SizedBox(width: 8),
                Text('Room Service'),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.cleaning_services, size: 18),
                SizedBox(width: 8),
                Text('Housekeeping'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateAndFilterRow() {
    final filters = ['All', 'Active', 'Completed', 'Cancelled'];

    return SizedBox(
      height: 56,
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
                color: const Color(0xFF137fec).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF137fec)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_month, color: Color(0xFF137fec), size: 18),
                  const SizedBox(width: 6),
                  Text(
                    _isToday(_selectedDate)
                        ? 'Today'
                        : DateFormat('dd MMM').format(_selectedDate),
                    style: const TextStyle(
                      color: Color(0xFF137fec),
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  if (!_isToday(_selectedDate)) ...[
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: () => setState(() => _selectedDate = DateTime.now()),
                      child: const Icon(Icons.close, size: 16, color: Color(0xFF137fec)),
                    ),
                  ],
                ],
              ),
            ),
          ),
          // Status Chips
          ...filters.map((filter) {
            final isSelected = _selectedFilter == filter;
            return GestureDetector(
              onTap: () => setState(() => _selectedFilter = filter),
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF137fec) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: isSelected ? const Color(0xFF137fec) : const Color(0xFFE5E7EB)),
                ),
                child: Text(
                  filter,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey[700],
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  // --- HOUSEKEEPING LIST ---
  Widget _buildHousekeepingList() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _db.getMyHousekeepingRequests(widget.hotelName),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}', style: TextStyle(color: Colors.grey[600])),
          );
        }

        final requests = snapshot.data ?? [];
        final filtered = _filterByDateAndStatus(requests);

        if (filtered.isEmpty) {
          return _buildEmptyState('No housekeeping requests', Icons.cleaning_services);
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: filtered.length,
          separatorBuilder: (_, e) => const SizedBox(height: 12),
          itemBuilder: (context, index) => _HousekeepingCard(
            data: filtered[index],
            hotelName: widget.hotelName,
          ),
        );
      },
    );
  }

  // --- ROOM SERVICE LIST ---
  Widget _buildRoomServiceList() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _db.getMyRoomServiceOrders(widget.hotelName),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}', style: TextStyle(color: Colors.grey[600])),
          );
        }

        final orders = snapshot.data ?? [];
        final filtered = _filterByDateAndStatus(orders);

        if (filtered.isEmpty) {
          return _buildEmptyState('No room service orders', Icons.room_service);
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: filtered.length,
          separatorBuilder: (_, e) => const SizedBox(height: 12),
          itemBuilder: (context, index) => _RoomServiceCard(
            data: filtered[index],
            hotelName: widget.hotelName,
          ),
        );
      },
    );
  }

  List<Map<String, dynamic>> _filterByDateAndStatus(List<Map<String, dynamic>> items) {
    return items.where((item) {
      // Date filter
      final timestamp = item['timestamp'] as Timestamp?;
      if (timestamp == null) return false;
      final itemDate = timestamp.toDate();
      if (!_isSameDay(itemDate, _selectedDate)) return false;

      // Status filter
      if (_selectedFilter == 'All') return true;

      final status = (item['status'] ?? 'Active').toString().toLowerCase();
      final filterLower = _selectedFilter.toLowerCase();

      // Active = pending, active, in progress, preparing (beklemede olan herşey)
      if (filterLower == 'active') {
        return status == 'active' || status == 'pending' || status == 'in progress' || status == 'preparing';
      }
      if (filterLower == 'completed') return status == 'completed';
      if (filterLower == 'cancelled') return status == 'cancelled';

      return true;
    }).toList();
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(fontSize: 16, color: Colors.grey[500]),
          ),
          const SizedBox(height: 8),
          Text(
            _isToday(_selectedDate)
                ? 'for today'
                : 'for ${DateFormat('dd MMM yyyy').format(_selectedDate)}',
            style: TextStyle(fontSize: 14, color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }
}

// --- HOUSEKEEPING REQUEST CARD ---
class _HousekeepingCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String hotelName;

  const _HousekeepingCard({required this.data, required this.hotelName});

  @override
  Widget build(BuildContext context) {
    final status = data['status'] ?? 'Active';
    final requestType = data['requestType'] ?? 'Housekeeping';
    final details = data['details'] ?? '';
    final timestamp = data['timestamp'] as Timestamp?;
    final timeStr = timestamp != null
        ? DateFormat('HH:mm').format(timestamp.toDate())
        : '--:--';
    final requestId = data['id'] ?? '';
    final isActive = status.toLowerCase() == 'active' || 
                     status.toLowerCase() == 'pending' || 
                     status.toLowerCase() == 'in progress';

    final style = _getStatusStyle(status);

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
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
            child: Container(color: style['color'] as Color),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStatusBadge(style),
                    Text(
                      timeStr,
                      style: const TextStyle(
                        color: Color(0xFF6B7280),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Request type
                Row(
                  children: [
                    Icon(Icons.cleaning_services, size: 20, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Text(
                      requestType,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF111827),
                      ),
                    ),
                  ],
                ),
                if (details.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    details,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                // Cancel button for active requests
                if (isActive && requestId.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _cancelRequest(context, requestId),
                      icon: const Icon(Icons.close, size: 16, color: Colors.red),
                      label: const Text('Cancel Request'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _cancelRequest(BuildContext context, String requestId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Request'),
        content: const Text('Are you sure you want to cancel this housekeeping request?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () {
              final messenger = ScaffoldMessenger.of(context);
              FirebaseFirestore.instance
                  .collection('hotels')
                  .doc(hotelName)
                  .collection('housekeeping_requests')
                  .doc(requestId)
                  .update({'status': 'Cancelled'}).then((_) {
                Navigator.pop(ctx);
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('Request cancelled'),
                    backgroundColor: Colors.red,
                  ),
                );
              });
            },
            child: const Text('Yes, Cancel', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(Map<String, dynamic> style) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: style['bg'] as Color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: style['color'] as Color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            style['label'] as String,
            style: TextStyle(
              color: style['text'] as Color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _getStatusStyle(String status) {
    switch (status.toLowerCase()) {
      case 'active':
      case 'pending':
      case 'in progress':
        return {
          'label': 'Active',
          'color': Colors.blue,
          'bg': Colors.blue[50]!,
          'text': Colors.blue[800]!,
        };
      case 'completed':
        return {
          'label': 'Completed',
          'color': Colors.green,
          'bg': Colors.green[50]!,
          'text': Colors.green[800]!,
        };
      case 'cancelled':
        return {
          'label': 'Cancelled',
          'color': Colors.red,
          'bg': Colors.red[50]!,
          'text': Colors.red[800]!,
        };
      default:
        return {
          'label': 'Active',
          'color': Colors.blue,
          'bg': Colors.blue[50]!,
          'text': Colors.blue[800]!,
        };
    }
  }
}

// --- ROOM SERVICE ORDER CARD ---
class _RoomServiceCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String hotelName;

  const _RoomServiceCard({required this.data, required this.hotelName});

  @override
  Widget build(BuildContext context) {
    final status = data['status'] ?? 'Active';
    final totalPrice = data['totalPrice'] ?? 0;
    final items = (data['items'] as List<dynamic>?) ?? [];
    final timestamp = data['timestamp'] as Timestamp?;
    final timeStr = timestamp != null
        ? DateFormat('HH:mm').format(timestamp.toDate())
        : '--:--';
    final orderId = data['id'] ?? '';
    final isActive = status.toLowerCase() == 'active' || 
                     status.toLowerCase() == 'pending' || 
                     status.toLowerCase() == 'preparing';

    final style = _getStatusStyle(status);
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
              blurRadius: 6,
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
              child: Container(color: style['color'] as Color),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildStatusBadge(style),
                      Text(
                        timeStr,
                        style: const TextStyle(
                          color: Color(0xFF6B7280),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Order items
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.restaurant_menu, size: 20, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          itemNames.isNotEmpty ? itemNames : 'No items',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF374151),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Total
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${items.length} item${items.length != 1 ? 's' : ''}',
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        '₺${totalPrice.toStringAsFixed(0)}',
                        style: const TextStyle(
                          color: Color(0xFF137fec),
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  // Cancel button for active orders
                  if (isActive && orderId.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _cancelOrder(context, orderId),
                        icon: const Icon(Icons.close, size: 16, color: Colors.red),
                        label: const Text('Cancel Order'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _cancelOrder(BuildContext context, String orderId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Order'),
        content: const Text('Are you sure you want to cancel this room service order?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () {
              final messenger = ScaffoldMessenger.of(context);
              FirebaseFirestore.instance
                  .collection('hotels')
                  .doc(hotelName)
                  .collection('room_service')
                  .doc('orders')
                  .collection('items')
                  .doc(orderId)
                  .update({'status': 'Cancelled'}).then((_) {
                Navigator.pop(ctx);
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('Order cancelled'),
                    backgroundColor: Colors.red,
                  ),
                );
              });
            },
            child: const Text('Yes, Cancel', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showOrderDetails(BuildContext context) {
    final items = (data['items'] as List<dynamic>?) ?? [];
    final totalPrice = data['totalPrice'] ?? 0;
    final timestamp = data['timestamp'] as Timestamp?;
    final dateStr = timestamp != null
        ? DateFormat('dd MMM yyyy, HH:mm').format(timestamp.toDate())
        : 'Unknown';
    final status = data['status'] ?? 'Pending';

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: Colors.white,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Order Details',
                  style: TextStyle(
                    fontSize: 20,
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
            const SizedBox(height: 8),
            Text(
              dateStr,
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
            // Items list
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
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  '₺${totalPrice.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF137fec),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Status
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: _getStatusStyle(status)['bg'] as Color,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Status: ${_getStatusStyle(status)['label']}',
                  style: TextStyle(
                    color: _getStatusStyle(status)['text'] as Color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(Map<String, dynamic> style) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: style['bg'] as Color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: style['color'] as Color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            style['label'] as String,
            style: TextStyle(
              color: style['text'] as Color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _getStatusStyle(String status) {
    switch (status.toLowerCase()) {
      case 'active':
      case 'pending':
      case 'preparing':
      case 'in progress':
        return {
          'label': 'Active',
          'color': Colors.blue,
          'bg': Colors.blue[50]!,
          'text': Colors.blue[800]!,
        };
      case 'completed':
      case 'delivered':
        return {
          'label': 'Completed',
          'color': Colors.green,
          'bg': Colors.green[50]!,
          'text': Colors.green[800]!,
        };
      case 'cancelled':
        return {
          'label': 'Cancelled',
          'color': Colors.red,
          'bg': Colors.red[50]!,
          'text': Colors.red[800]!,
        };
      default:
        return {
          'label': 'Active',
          'color': Colors.blue,
          'bg': Colors.blue[50]!,
          'text': Colors.blue[800]!,
        };
    }
  }
}









