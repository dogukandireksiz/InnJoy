import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../services/database_service.dart';
import '../../utils/responsive_utils.dart';

/// Admin Requests Screen
/// 
/// Displays all housekeeping requests and room service orders from all rooms.
/// Similar to CustomerRequestsScreen but shows data from all guests.
class AdminRequestsScreen extends StatefulWidget {
  final String hotelName;

  const AdminRequestsScreen({super.key, required this.hotelName});

  @override
  State<AdminRequestsScreen> createState() => _AdminRequestsScreenState();
}

class _AdminRequestsScreenState extends State<AdminRequestsScreen>
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
    return Material(
      color: const Color(0xFFF6F7FB),
      child: SafeArea(
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
      padding: EdgeInsets.symmetric(horizontal: ResponsiveUtils.spacing(context, 20), vertical: ResponsiveUtils.spacing(context, 16)),
      decoration: const BoxDecoration(
        color: Color(0xFFF6F7FB),
        border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: Row(
        children: [
          Text(
            'All Requests',
            style: TextStyle(
              color: Color(0xFF111827),
              fontSize: ResponsiveUtils.sp(context, 20),
              fontWeight: FontWeight.bold,
              fontFamily: 'Inter',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: ResponsiveUtils.spacing(context, 16), vertical: ResponsiveUtils.spacing(context, 8)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(ResponsiveUtils.spacing(context, 12)),
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
          borderRadius: BorderRadius.circular(ResponsiveUtils.spacing(context, 10)),
          color: const Color(0xFF137fec),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey[600],
        labelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: ResponsiveUtils.sp(context, 14)),
        unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w500, fontSize: ResponsiveUtils.sp(context, 14)),
        padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 4)),
        tabs: [
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.room_service, size: ResponsiveUtils.iconSize(context) * (18 / 24)),
                SizedBox(width: ResponsiveUtils.spacing(context, 8)),
                Text('Room Service'),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.cleaning_services, size: ResponsiveUtils.iconSize(context) * (18 / 24)),
                SizedBox(width: ResponsiveUtils.spacing(context, 8)),
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
      height: ResponsiveUtils.hp(context, 56 / 844),
      child: ListView(
        padding: EdgeInsets.symmetric(horizontal: ResponsiveUtils.spacing(context, 16), vertical: ResponsiveUtils.spacing(context, 8)),
        scrollDirection: Axis.horizontal,
        children: [
          // Calendar Button
          GestureDetector(
            onTap: () => _selectDate(context),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: EdgeInsets.symmetric(horizontal: ResponsiveUtils.spacing(context, 12), vertical: ResponsiveUtils.spacing(context, 8)),
              decoration: BoxDecoration(
                color: const Color(0xFF137fec).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(ResponsiveUtils.spacing(context, 20)),
                border: Border.all(color: const Color(0xFF137fec)),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_month, color: Color(0xFF137fec), size: ResponsiveUtils.iconSize(context) * (18 / 24)),
                  SizedBox(width: ResponsiveUtils.spacing(context, 6)),
                  Text(
                    _isToday(_selectedDate)
                        ? 'Today'
                        : DateFormat('dd MMM').format(_selectedDate),
                    style: TextStyle(
                      color: Color(0xFF137fec),
                      fontWeight: FontWeight.bold,
                      fontSize: ResponsiveUtils.sp(context, 13),
                    ),
                  ),
                  if (!_isToday(_selectedDate)) ...[
                    SizedBox(width: ResponsiveUtils.spacing(context, 4)),
                    GestureDetector(
                      onTap: () => setState(() => _selectedDate = DateTime.now()),
                      child: Icon(Icons.close, size: ResponsiveUtils.iconSize(context) * (16 / 24), color: Color(0xFF137fec)),
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
                margin: EdgeInsets.only(right: 8),
                padding: EdgeInsets.symmetric(horizontal: ResponsiveUtils.spacing(context, 14)),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF137fec) : Colors.white,
                  borderRadius: BorderRadius.circular(ResponsiveUtils.spacing(context, 20)),
                  border: Border.all(
                      color: isSelected ? const Color(0xFF137fec) : const Color(0xFFE5E7EB)),
                ),
                child: Text(
                  filter,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey[700],
                    fontWeight: FontWeight.w500,
                    fontSize: ResponsiveUtils.sp(context, 13),
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
      stream: _db.getHotelHousekeepingRequests(widget.hotelName),
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
          padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 16)),
          itemCount: filtered.length,
          separatorBuilder: (_, e) => SizedBox(height: ResponsiveUtils.spacing(context, 12)),
          itemBuilder: (context, index) => _AdminHousekeepingCard(
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
      stream: _db.getAllRoomServiceOrders(widget.hotelName),
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
          padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 16)),
          itemCount: filtered.length,
          separatorBuilder: (_, e) => SizedBox(height: ResponsiveUtils.spacing(context, 12)),
          itemBuilder: (context, index) => _AdminRoomServiceCard(
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

      // Active = pending, active, in progress, preparing
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
          Icon(icon, size: ResponsiveUtils.iconSize(context) * (64 / 24), color: Colors.grey[300]),
          SizedBox(height: ResponsiveUtils.spacing(context, 16)),
          Text(
            message,
            style: TextStyle(fontSize: ResponsiveUtils.sp(context, 16), color: Colors.grey[500]),
          ),
          SizedBox(height: ResponsiveUtils.spacing(context, 8)),
          Text(
            _isToday(_selectedDate)
                ? 'for today'
                : 'for ${DateFormat('dd MMM yyyy').format(_selectedDate)}',
            style: TextStyle(fontSize: ResponsiveUtils.sp(context, 14), color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }
}

// --- ADMIN HOUSEKEEPING REQUEST CARD ---
class _AdminHousekeepingCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String hotelName;

  const _AdminHousekeepingCard({required this.data, required this.hotelName});

  @override
  Widget build(BuildContext context) {
    final status = data['status'] ?? 'Active';
    final requestType = data['requestType'] ?? 'Housekeeping';
    final details = data['details'] ?? '';
    final roomNumber = data['roomNumber'] ?? 'Unknown';
    final guestName = data['guestName'] ?? 'Guest';
    final timestamp = data['timestamp'] as Timestamp?;
    final timeStr = timestamp != null
        ? DateFormat('HH:mm').format(timestamp.toDate())
        : '--:--';
    final requestId = data['id'] ?? '';

    final style = _getStatusStyle(status);

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(ResponsiveUtils.spacing(context, 12)),
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
            width: ResponsiveUtils.wp(context, 4 / 375),
            child: Container(color: style['color'] as Color),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        _buildStatusBadge(context, style),
                        SizedBox(width: ResponsiveUtils.spacing(context, 8)),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: ResponsiveUtils.spacing(context, 8), vertical: ResponsiveUtils.spacing(context, 4)),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(ResponsiveUtils.spacing(context, 8)),
                          ),
                          child: Text(
                            'Room $roomNumber',
                            style: TextStyle(
                              color: Colors.orange,
                              fontSize: ResponsiveUtils.sp(context, 12),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      timeStr,
                      style: TextStyle(
                        color: Color(0xFF6B7280),
                        fontSize: ResponsiveUtils.sp(context, 13),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: ResponsiveUtils.spacing(context, 12)),
                // Request type
                Row(
                  children: [
                    Icon(Icons.cleaning_services, size: ResponsiveUtils.iconSize(context) * (20 / 24), color: Colors.grey[600]),
                    SizedBox(width: ResponsiveUtils.spacing(context, 8)),
                    Text(
                      requestType,
                      style: TextStyle(
                        fontSize: ResponsiveUtils.sp(context, 16),
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF111827),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: ResponsiveUtils.spacing(context, 8)),
                // Guest name
                Row(
                  children: [
                    Icon(Icons.person, size: ResponsiveUtils.iconSize(context) * (16 / 24), color: Colors.grey[500]),
                    SizedBox(width: ResponsiveUtils.spacing(context, 6)),
                    Text(
                      guestName,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: ResponsiveUtils.sp(context, 13),
                      ),
                    ),
                  ],
                ),
                if (details.isNotEmpty) ...[
                  SizedBox(height: ResponsiveUtils.spacing(context, 8)),
                  Text(
                    details,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: ResponsiveUtils.sp(context, 14),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                // Action buttons
                if (requestId.isNotEmpty) ...[
                  SizedBox(height: ResponsiveUtils.spacing(context, 12)),
                  Row(
                    children: [
                      if (status.toLowerCase() != 'completed' && status.toLowerCase() != 'cancelled')
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _updateStatus(context, requestId, 'Completed'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.green,
                              side: const BorderSide(color: Colors.green),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(ResponsiveUtils.spacing(context, 8)),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                            child: const Text('Complete'),
                          ),
                        ),
                      if (status.toLowerCase() != 'completed' && status.toLowerCase() != 'cancelled')
                        SizedBox(width: ResponsiveUtils.spacing(context, 8)),
                      if (status.toLowerCase() != 'cancelled')
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _updateStatus(context, requestId, 'Cancelled'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              side: const BorderSide(color: Colors.red),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(ResponsiveUtils.spacing(context, 8)),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                            child: const Text('Cancel'),
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _updateStatus(BuildContext context, String requestId, String newStatus) {
    final messenger = ScaffoldMessenger.of(context);
    FirebaseFirestore.instance
        .collection('hotels')
        .doc(hotelName)
        .collection('housekeeping_requests')
        .doc(requestId)
        .update({'status': newStatus}).then((_) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Request marked as $newStatus'),
          backgroundColor: newStatus == 'Completed' ? Colors.green : Colors.red,
        ),
      );
    });
  }

  Widget _buildStatusBadge(BuildContext context, Map<String, dynamic> style) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: ResponsiveUtils.spacing(context, 10), vertical: ResponsiveUtils.spacing(context, 4)),
      decoration: BoxDecoration(
        color: style['bg'] as Color,
        borderRadius: BorderRadius.circular(ResponsiveUtils.spacing(context, 20)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: ResponsiveUtils.wp(context, 6 / 375),
            height: ResponsiveUtils.hp(context, 6 / 844),
            decoration: BoxDecoration(
              color: style['color'] as Color,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: ResponsiveUtils.spacing(context, 6)),
          Text(
            style['label'] as String,
            style: TextStyle(
              color: style['text'] as Color,
              fontSize: ResponsiveUtils.sp(context, 12),
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

// --- ADMIN ROOM SERVICE ORDER CARD ---
class _AdminRoomServiceCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String hotelName;

  const _AdminRoomServiceCard({required this.data, required this.hotelName});

  @override
  Widget build(BuildContext context) {
    final status = data['status'] ?? 'Active';
    final totalPrice = data['totalPrice'] ?? 0;
    final items = (data['items'] as List<dynamic>?) ?? [];
    final roomNumber = data['roomNumber'] ?? 'Unknown';
    final guestName = data['guestName'] ?? 'Guest';
    final timestamp = data['timestamp'] as Timestamp?;
    final timeStr = timestamp != null
        ? DateFormat('HH:mm').format(timestamp.toDate())
        : '--:--';
    final orderId = data['id'] ?? '';

    final style = _getStatusStyle(status);
    final itemNames = items.map((i) => i['name']).join(', ');

    return GestureDetector(
      onTap: () => _showOrderDetails(context),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(ResponsiveUtils.spacing(context, 12)),
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
              width: ResponsiveUtils.wp(context, 4 / 375),
              child: Container(color: style['color'] as Color),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          _buildStatusBadge(context, style),
                          SizedBox(width: ResponsiveUtils.spacing(context, 8)),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: ResponsiveUtils.spacing(context, 8), vertical: ResponsiveUtils.spacing(context, 4)),
                            decoration: BoxDecoration(
                              color: Colors.orange.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(ResponsiveUtils.spacing(context, 8)),
                            ),
                            child: Text(
                              'Room $roomNumber',
                              style: TextStyle(
                                color: Colors.orange,
                                fontSize: ResponsiveUtils.sp(context, 12),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        timeStr,
                        style: TextStyle(
                          color: Color(0xFF6B7280),
                          fontSize: ResponsiveUtils.sp(context, 13),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: ResponsiveUtils.spacing(context, 12)),
                  // Order items
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.restaurant_menu, size: ResponsiveUtils.iconSize(context) * (20 / 24), color: Colors.grey[600]),
                      SizedBox(width: ResponsiveUtils.spacing(context, 8)),
                      Expanded(
                        child: Text(
                          itemNames.isNotEmpty ? itemNames : 'No items',
                          style: TextStyle(
                            fontSize: ResponsiveUtils.sp(context, 14),
                            color: Color(0xFF374151),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: ResponsiveUtils.spacing(context, 8)),
                  // Guest name
                  Row(
                    children: [
                      Icon(Icons.person, size: ResponsiveUtils.iconSize(context) * (16 / 24), color: Colors.grey[500]),
                      SizedBox(width: ResponsiveUtils.spacing(context, 6)),
                      Text(
                        guestName,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: ResponsiveUtils.sp(context, 13),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: ResponsiveUtils.spacing(context, 12)),
                  // Total
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${items.length} item${items.length != 1 ? 's' : ''}',
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: ResponsiveUtils.sp(context, 13),
                        ),
                      ),
                      Text(
                        '₺${totalPrice.toStringAsFixed(0)}',
                        style: TextStyle(
                          color: Color(0xFF137fec),
                          fontWeight: FontWeight.bold,
                          fontSize: ResponsiveUtils.sp(context, 16),
                        ),
                      ),
                    ],
                  ),
                  // Action buttons
                  if (orderId.isNotEmpty) ...[
                    SizedBox(height: ResponsiveUtils.spacing(context, 12)),
                    Row(
                      children: [
                        if (status.toLowerCase() != 'completed' && status.toLowerCase() != 'cancelled')
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => _updateStatus(context, orderId, 'Completed'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.green,
                                side: const BorderSide(color: Colors.green),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(ResponsiveUtils.spacing(context, 8)),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 10),
                              ),
                              child: const Text('Complete'),
                            ),
                          ),
                        if (status.toLowerCase() != 'completed' && status.toLowerCase() != 'cancelled')
                          SizedBox(width: ResponsiveUtils.spacing(context, 8)),
                        if (status.toLowerCase() != 'cancelled')
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => _updateStatus(context, orderId, 'Cancelled'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                                side: const BorderSide(color: Colors.red),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(ResponsiveUtils.spacing(context, 8)),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 10),
                              ),
                              child: const Text('Cancel'),
                            ),
                          ),
                      ],
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

  void _updateStatus(BuildContext context, String orderId, String newStatus) {
    final messenger = ScaffoldMessenger.of(context);
    FirebaseFirestore.instance
        .collection('hotels')
        .doc(hotelName)
        .collection('room_service')
        .doc('orders')
        .collection('items')
        .doc(orderId)
        .update({'status': newStatus}).then((_) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Order marked as $newStatus'),
          backgroundColor: newStatus == 'Completed' ? Colors.green : Colors.red,
        ),
      );
    });
  }

  void _showOrderDetails(BuildContext context) {
    final items = (data['items'] as List<dynamic>?) ?? [];
    final totalPrice = data['totalPrice'] ?? 0;
    final timestamp = data['timestamp'] as Timestamp?;
    final dateStr = timestamp != null
        ? DateFormat('dd MMM yyyy, HH:mm').format(timestamp.toDate())
        : 'Unknown';
    final status = data['status'] ?? 'Pending';
    final roomNumber = data['roomNumber'] ?? 'Unknown';
    final guestName = data['guestName'] ?? 'Guest';

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: Colors.white,
      builder: (ctx) => Padding(
        padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 24)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Order Details',
                  style: TextStyle(
                    fontSize: ResponsiveUtils.sp(context, 20),
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
            SizedBox(height: ResponsiveUtils.spacing(context, 16)),
            // Room & Guest Info
            Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: ResponsiveUtils.spacing(context, 12), vertical: ResponsiveUtils.spacing(context, 6)),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(ResponsiveUtils.spacing(context, 8)),
                  ),
                  child: Text(
                    'Room $roomNumber',
                    style: const TextStyle(
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(width: ResponsiveUtils.spacing(context, 12)),
                Text(
                  guestName,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: ResponsiveUtils.sp(context, 14),
                  ),
                ),
              ],
            ),
            SizedBox(height: ResponsiveUtils.spacing(context, 12)),
            Text('Status: $status', style: TextStyle(color: Colors.grey[600])),
            Text('Date: $dateStr', style: TextStyle(color: Colors.grey[500])),
            SizedBox(height: ResponsiveUtils.spacing(context, 16)),
            Divider(),
            SizedBox(height: ResponsiveUtils.spacing(context, 8)),
            Text(
              'Items',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: ResponsiveUtils.sp(context, 16)),
            ),
            SizedBox(height: ResponsiveUtils.spacing(context, 8)),
            ...items.map((item) {
              final name = item['name'] ?? 'Unknown';
              final quantity = item['quantity'] ?? 1;
              final price = item['price'] ?? 0;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('$quantity x $name'),
                    Text('₺${(price * quantity).toStringAsFixed(0)}'),
                  ],
                ),
              );
            }),
            Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: ResponsiveUtils.sp(context, 18)),
                ),
                Text(
                  '₺${totalPrice.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: ResponsiveUtils.sp(context, 18),
                    color: Color(0xFF137fec),
                  ),
                ),
              ],
            ),
            SizedBox(height: ResponsiveUtils.spacing(context, 16)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context, Map<String, dynamic> style) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: ResponsiveUtils.spacing(context, 10), vertical: ResponsiveUtils.spacing(context, 4)),
      decoration: BoxDecoration(
        color: style['bg'] as Color,
        borderRadius: BorderRadius.circular(ResponsiveUtils.spacing(context, 20)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: ResponsiveUtils.wp(context, 6 / 375),
            height: ResponsiveUtils.hp(context, 6 / 844),
            decoration: BoxDecoration(
              color: style['color'] as Color,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: ResponsiveUtils.spacing(context, 6)),
          Text(
            style['label'] as String,
            style: TextStyle(
              color: style['text'] as Color,
              fontSize: ResponsiveUtils.sp(context, 14),
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










