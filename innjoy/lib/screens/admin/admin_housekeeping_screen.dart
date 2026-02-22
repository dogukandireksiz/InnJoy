import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../utils/responsive_utils.dart';

class AdminHousekeepingScreen extends StatefulWidget {
  final String hotelName;

  const AdminHousekeepingScreen({super.key, required this.hotelName});

  @override
  State<AdminHousekeepingScreen> createState() => _AdminHousekeepingScreenState();
}

class _AdminHousekeepingScreenState extends State<AdminHousekeepingScreen> {
  String _selectedFilter = 'Active';
  DateTime? _selectedDate;

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
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Housekeeping Management',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
            fontSize: ResponsiveUtils.sp(context, 18),
          ),
        ),
      ),
      body: Column(
        children: [
          _buildDateAndFilterRow(),
          Expanded(child: _buildRequestList()),
        ],
      ),
    );
  }


  Widget _buildDateAndFilterRow() {
    final filters = ['Active', 'Completed', 'Cancelled'];
    
    return SizedBox(
      height: ResponsiveUtils.hp(context, 60 / 844),
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
                color: _selectedDate != null ? const Color(0xFF137fec).withValues(alpha: 0.1) : Colors.white,
                borderRadius: BorderRadius.circular(ResponsiveUtils.spacing(context, 20)),
                border: Border.all(
                  color: _selectedDate != null ? const Color(0xFF137fec) : const Color(0xFFE5E7EB)
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_month,
                    color: _selectedDate != null ? const Color(0xFF137fec) : Colors.grey[600],
                    size: ResponsiveUtils.iconSize(context) * (20 / 24)
                  ),
                  if (_selectedDate != null) ...[
                    SizedBox(width: ResponsiveUtils.spacing(context, 6)),
                    Text(
                      DateFormat('dd MMM').format(_selectedDate!),
                      style: TextStyle(
                        color: Color(0xFF137fec),
                        fontWeight: FontWeight.bold,
                        fontSize: ResponsiveUtils.sp(context, 12),
                      ),
                    ),
                    SizedBox(width: ResponsiveUtils.spacing(context, 4)),
                    GestureDetector(
                      onTap: () => setState(() => _selectedDate = null),
                      child: Icon(Icons.close, size: ResponsiveUtils.iconSize(context) * (16 / 24), color: Color(0xFF137fec)),
                    ),
                  ],
                ],
              ),
            ),
          ),
          
          // Status Filter Chips
          ...filters.map((filter) {
            final isSelected = _selectedFilter == filter;
            
            return GestureDetector(
              onTap: () => setState(() => _selectedFilter = filter),
              child: Container(
                margin: EdgeInsets.only(right: 8),
                padding: EdgeInsets.symmetric(horizontal: ResponsiveUtils.spacing(context, 16)),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF137fec) : Colors.white,
                  borderRadius: BorderRadius.circular(ResponsiveUtils.spacing(context, 20)),
                  border: Border.all(color: isSelected ? const Color(0xFF137fec) : const Color(0xFFE5E7EB)),
                  boxShadow: isSelected ? [
                    BoxShadow(color: const Color(0xFF137fec).withValues(alpha: 0.3), blurRadius: 4, offset: const Offset(0, 2))
                  ] : null,
                ),
                child: Text(
                  filter,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey[700],
                    fontWeight: FontWeight.w500,
                    fontSize: ResponsiveUtils.sp(context, 14),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildRequestList() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('hotels')
          .doc(widget.hotelName)
          .collection('housekeeping_requests')
          .where('status', isNotEqualTo: 'archived')
          .snapshots()
          .map((snapshot) {
            final requests = snapshot.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              return data;
            }).toList();
            // Sort by timestamp descending
            requests.sort((a, b) {
              final aTime = a['timestamp'] as Timestamp?;
              final bTime = b['timestamp'] as Timestamp?;
              if (aTime == null || bTime == null) return 0;
              return bTime.compareTo(aTime);
            });
            return requests;
          }),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: ResponsiveUtils.iconSize(context) * (64 / 24), color: Colors.red[300]),
                SizedBox(height: ResponsiveUtils.spacing(context, 16)),
                Text(
                  'Error loading requests',
                  style: TextStyle(fontSize: ResponsiveUtils.sp(context, 18), color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        final allRequests = snapshot.data ?? [];
        
        if (allRequests.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.cleaning_services, size: ResponsiveUtils.iconSize(context) * (64 / 24), color: Colors.grey[300]),
                SizedBox(height: ResponsiveUtils.spacing(context, 16)),
                Text(
                  'No housekeeping requests',
                  style: TextStyle(fontSize: ResponsiveUtils.sp(context, 18), color: Colors.grey[600]),
                ),
                SizedBox(height: ResponsiveUtils.spacing(context, 8)),
                Text(
                  'Requests from guests will appear here',
                  style: TextStyle(fontSize: ResponsiveUtils.sp(context, 14), color: Colors.grey[400]),
                ),
              ],
            ),
          );
        }

        // Filter requests based on selected filter and date
        final filteredRequests = allRequests.where((request) {
          final status = (request['status'] ?? 'Active') as String;
          final timestamp = request['timestamp'] as Timestamp?;
          
          // Date Filter (if date is selected)
          if (_selectedDate != null && timestamp != null) {
            final requestDate = timestamp.toDate();
            final isSameDay = requestDate.year == _selectedDate!.year && 
                              requestDate.month == _selectedDate!.month && 
                              requestDate.day == _selectedDate!.day;
            
            if (!isSameDay) return false;
          }

          // Status Filter
          // Active covers: Active, Pending, In Progress
          if (_selectedFilter == 'Active') {
            return status == 'Active' || status == 'Pending' || status == 'In Progress';
          }
          return status == _selectedFilter;
        }).toList();

        if (filteredRequests.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.filter_list_off, size: ResponsiveUtils.iconSize(context) * (64 / 24), color: Colors.grey[300]),
                SizedBox(height: ResponsiveUtils.spacing(context, 16)),
                Text('No requests match these criteria.', style: TextStyle(color: Colors.grey[500])),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 16)),
          itemCount: filteredRequests.length,
          separatorBuilder: (_, e) => SizedBox(height: ResponsiveUtils.spacing(context, 16)),
          itemBuilder: (context, index) {
            final request = filteredRequests[index];
            return _RequestCard(
              id: request['id'] as String,
              data: request,
              hotelName: widget.hotelName,
            );
          },
        );
      },
    );
  }
}

class _RequestCard extends StatelessWidget {
  final String id;
  final Map<String, dynamic> data;
  final String hotelName;

  const _RequestCard({
    required this.id,
    required this.data,
    required this.hotelName,
  });

  @override
  Widget build(BuildContext context) {
    final status = (data['status'] ?? 'Pending') as String;
    final roomNumber = (data['roomNumber'] ?? 'Unknown') as String;
    final guestName = (data['guestName'] ?? 'Guest') as String;
    final details = (data['details'] ?? '') as String;
    final timestamp = data['timestamp'] as Timestamp?;
    final timeStr = timestamp != null 
        ? DateFormat('dd MMM, HH:mm').format(timestamp.toDate())
        : 'Unknown';

    // Status styling
    final statusColors = {
      'Active': {'color': Colors.blue, 'bg': Colors.blue[50]},
      'Pending': {'color': Colors.blue, 'bg': Colors.blue[50]},
      'In Progress': {'color': Colors.blue, 'bg': Colors.blue[50]},
      'Completed': {'color': Colors.green, 'bg': Colors.green[50]},
      'Cancelled': {'color': Colors.red, 'bg': Colors.red[50]},
    };

    final statusStyle = statusColors[status] ?? statusColors['Active']!;
    final statusColor = statusStyle['color'] as Color;
    final statusBg = statusStyle['bg'];

    return GestureDetector(
      onTap: () => _showRequestDetails(context),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(ResponsiveUtils.spacing(context, 12)),
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
              width: ResponsiveUtils.wp(context, 4 / 375),
              child: Container(
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    bottomLeft: Radius.circular(12),
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 16)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Room and Guest Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Room $roomNumber',
                                  style: TextStyle(
                                    fontSize: ResponsiveUtils.sp(context, 18),
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF111827),
                                  ),
                                ),
                                SizedBox(width: ResponsiveUtils.spacing(context, 8)),
                                // Do Not Disturb Badge (check room status)
                                StreamBuilder<DocumentSnapshot>(
                                  stream: FirebaseFirestore.instance
                                      .collection('hotels')
                                      .doc(hotelName)
                                      .collection('rooms')
                                      .doc(roomNumber)
                                      .snapshots(),
                                  builder: (context, roomSnapshot) {
                                    if (roomSnapshot.hasData && roomSnapshot.data!.exists) {
                                      final roomData = roomSnapshot.data!.data() as Map<String, dynamic>?;
                                      final doNotDisturb = roomData?['doNotDisturb'] ?? false;
                                      
                                      if (doNotDisturb) {
                                        return Container(
                                          padding: EdgeInsets.symmetric(horizontal: ResponsiveUtils.spacing(context, 8), vertical: ResponsiveUtils.spacing(context, 4)),
                                          decoration: BoxDecoration(
                                            color: Colors.red[50],
                                            borderRadius: BorderRadius.circular(ResponsiveUtils.spacing(context, 12)),
                                            border: Border.all(color: Colors.red[300]!),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.do_not_disturb, size: ResponsiveUtils.iconSize(context) * (14 / 24), color: Colors.red[700]),
                                              SizedBox(width: ResponsiveUtils.spacing(context, 4)),
                                              Text(
                                                'DND',
                                                style: TextStyle(
                                                  fontSize: ResponsiveUtils.sp(context, 11),
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.red[700],
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      }
                                    }
                                    return const SizedBox.shrink();
                                  },
                                ),
                              ],
                            ),
                            SizedBox(height: ResponsiveUtils.spacing(context, 4)),
                            Text(
                              guestName,
                              style: TextStyle(
                                color: Color(0xFF6B7280),
                                fontSize: ResponsiveUtils.sp(context, 14),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Status Badge
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: ResponsiveUtils.spacing(context, 12), vertical: ResponsiveUtils.spacing(context, 6)),
                        decoration: BoxDecoration(
                          color: statusBg,
                          borderRadius: BorderRadius.circular(ResponsiveUtils.spacing(context, 20)),
                        ),
                        child: Text(
                          status == 'Pending' || status == 'In Progress' ? 'Active' : status,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: ResponsiveUtils.sp(context, 12),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: ResponsiveUtils.spacing(context, 12)),
                  Divider(color: Colors.grey[200]),
                  SizedBox(height: ResponsiveUtils.spacing(context, 12)),
                  
                  // Request Details Preview
                  Text(
                    details.split('\n').first,
                    style: TextStyle(
                      color: Color(0xFF374151),
                      fontSize: ResponsiveUtils.sp(context, 14),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: ResponsiveUtils.spacing(context, 12)),
                  
                  // Footer
                  Row(
                    children: [
                      Icon(Icons.access_time, size: ResponsiveUtils.iconSize(context) * (16 / 24), color: Colors.grey[400]),
                      SizedBox(width: ResponsiveUtils.spacing(context, 4)),
                      Text(
                        timeStr,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: ResponsiveUtils.sp(context, 12),
                        ),
                      ),
                      Spacer(),
                      Text(
                        'Tap for details',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: ResponsiveUtils.sp(context, 12),
                          fontStyle: FontStyle.italic,
                        ),
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

  void _showRequestDetails(BuildContext context) {
    final status = (data['status'] ?? 'Active') as String;
    final roomNumber = (data['roomNumber'] ?? 'Unknown') as String;
    final guestName = (data['guestName'] ?? 'Guest') as String;
    final details = (data['details'] ?? '') as String;
    final timestamp = data['timestamp'] as Timestamp?;
    final dateStr = timestamp != null 
        ? DateFormat('dd MMMM yyyy, HH:mm').format(timestamp.toDate())
        : 'Unknown';

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(ResponsiveUtils.spacing(context, 20))),
        child: Container(
          padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 24)),
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
                    Text(
                      'Request Details',
                      style: TextStyle(
                        fontSize: ResponsiveUtils.sp(context, 22),
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
                
                // Info Rows
                _buildInfoRow(context, 'Room Number', roomNumber),
                _buildInfoRow(context, 'Guest Name', guestName),
                _buildInfoRow(context, 'Date & Time', dateStr),
                _buildInfoRow(context, 'Status', status),
                
                SizedBox(height: ResponsiveUtils.spacing(context, 16)),
                Divider(),
                SizedBox(height: ResponsiveUtils.spacing(context, 16)),
                
                // Full Details
                Text(
                  'Request Details',
                  style: TextStyle(
                    fontSize: ResponsiveUtils.sp(context, 16),
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827),
                  ),
                ),
                SizedBox(height: ResponsiveUtils.spacing(context, 12)),
                Container(
                  padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 16)),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(ResponsiveUtils.spacing(context, 8)),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Parse and display details as structured rows
                      ...details.split('\n').where((line) => line.trim().isNotEmpty).map((line) {
                        if (line.contains(':')) {
                          final parts = line.split(':');
                          final label = parts[0].trim();
                          final value = parts.sublist(1).join(':').trim();
                          
                          return Padding(
                            padding: EdgeInsets.only(bottom: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  width: ResponsiveUtils.wp(context, 120 / 375),
                                  child: Text(
                                    label,
                                    style: TextStyle(
                                      color: Color(0xFF6B7280),
                                      fontSize: ResponsiveUtils.sp(context, 14),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    value,
                                    style: TextStyle(
                                      color: Color(0xFF111827),
                                      fontSize: ResponsiveUtils.sp(context, 14),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        } else {
                          // Lines without colon (like notes)
                          return Padding(
                            padding: EdgeInsets.only(bottom: 8),
                            child: Text(
                              line,
                              style: TextStyle(
                                fontSize: ResponsiveUtils.sp(context, 14),
                                color: Color(0xFF374151),
                                height: ResponsiveUtils.hp(context, 1.5 / 844),
                              ),
                            ),
                          );
                        }
                      }),
                    ],
                  ),
                ),
                
                SizedBox(height: ResponsiveUtils.spacing(context, 24)),
                
                // Action Buttons (only show if not completed or cancelled)
                if (status != 'Completed' && status != 'Cancelled')
                  Column(
                    children: [
                      if (status == 'Pending' || status == 'Active' || status == 'In Progress')
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              _updateStatus(context, 'Completed');
                              Navigator.pop(ctx);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              padding: EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(ResponsiveUtils.spacing(context, 12)),
                              ),
                            ),
                            child: Text(
                              'Mark Completed',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: ResponsiveUtils.sp(context, 16),
                              ),
                            ),
                          ),
                        ),
                      SizedBox(height: ResponsiveUtils.spacing(context, 12)),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () {
                            _updateStatus(context, 'Cancelled');
                            Navigator.pop(ctx);
                          },
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 14),
                            side: const BorderSide(color: Colors.red),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(ResponsiveUtils.spacing(context, 12)),
                            ),
                          ),
                          child: Text(
                            'Cancel Request',
                            style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                              fontSize: ResponsiveUtils.sp(context, 16),
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

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: ResponsiveUtils.wp(context, 120 / 375),
            child: Text(
              label,
              style: TextStyle(
                color: Color(0xFF6B7280),
                fontSize: ResponsiveUtils.sp(context, 14),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: Color(0xFF111827),
                fontSize: ResponsiveUtils.sp(context, 14),
            ),
          ),
          ),
        ],
      ),
    );
  }

  void _updateStatus(BuildContext context, String newStatus) {
    // Capture ScaffoldMessenger before async gap to avoid BuildContext issues
    final messenger = ScaffoldMessenger.of(context);
    
    FirebaseFirestore.instance
        .collection('hotels')
        .doc(hotelName)
        .collection('housekeeping_requests')
        .doc(id)
        .update({'status': newStatus}).then((_) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Request status updated to $newStatus'),
          backgroundColor: newStatus == 'Completed' ? Colors.green : 
                          newStatus == 'In Progress' ? Colors.blue : Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    }).catchError((error) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Error: $error'),
          backgroundColor: Colors.red,
        ),
      );
    });
  }
}










