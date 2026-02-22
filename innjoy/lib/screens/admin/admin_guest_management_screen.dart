import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../services/database_service.dart';
import '../../utils/responsive_utils.dart';

class AdminGuestManagementScreen extends StatefulWidget {
  final String hotelName;

  const AdminGuestManagementScreen({super.key, required this.hotelName});

  @override
  State<AdminGuestManagementScreen> createState() => _AdminGuestManagementScreenState();
}

class _AdminGuestManagementScreenState extends State<AdminGuestManagementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _roomController = TextEditingController();
  final _guestNameController = TextEditingController();
  DateTime _checkOutDate = DateTime.now().add(const Duration(days: 1));
  bool _isLoading = false;

  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        title: const Text('Guest Management'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black87,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddGuestDialog,
        backgroundColor: const Color(0xFF2E5077),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('New Guest / PNR', style: TextStyle(color: Colors.white)),
      ),
      body: Column(
        children: [
          // Arama Çubuğu
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 5),
            color: const Color(0xFFF6F7FB),
            child: TextField(
              onChanged: (val) {
                setState(() {
                  _searchQuery = val;
                });
              },
              decoration: InputDecoration(
                hintText: 'Search: Name, Room No, PNR...',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: Colors.white,
                contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(ResponsiveUtils.spacing(context, 12)),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(ResponsiveUtils.spacing(context, 12)),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          
          // Liste
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: DatabaseService().getHotelReservations(widget.hotelName),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final allReservations = snapshot.data ?? [];
                
                // Filtreleme
                final reservations = allReservations.where((res) {
                  final q = _searchQuery.toLowerCase();
                  final name = (res['guestName'] ?? '').toString().toLowerCase();
                  final pnr = (res['pnr'] ?? '').toString().toLowerCase();
                  final room = (res['roomNumber'] ?? '').toString().toLowerCase();
                  
                  return name.contains(q) || pnr.contains(q) || room.contains(q);
                }).toList();

                if (reservations.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.person_search, size: ResponsiveUtils.iconSize(context) * (80 / 24), color: Colors.grey[400]),
                        SizedBox(height: ResponsiveUtils.spacing(context, 16)),
                        Text(
                          _searchQuery.isEmpty ? 'No guests yet.' : 'No records found.',
                          style: TextStyle(color: Colors.grey[600], fontSize: ResponsiveUtils.sp(context, 16)),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 16)),
                  itemCount: reservations.length,
                  separatorBuilder: (_, e) => SizedBox(height: ResponsiveUtils.spacing(context, 12)),
                  itemBuilder: (context, index) {
                    final res = reservations[index];
                    final isUsed = res['status'] == 'used';
                    final checkOut = (res['checkOutDate'] as Timestamp).toDate();

                    return Container(
                      padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 16)),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(ResponsiveUtils.spacing(context, 12)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                        border: isUsed 
                          ? Border(left: BorderSide(color: Colors.green.shade400, width: 4))
                          : Border(left: BorderSide(color: Colors.orange.shade400, width: 4)),
                      ),
                      child: Row(
                        children: [
                          // Oda Numarası
                          Container(
                            width: ResponsiveUtils.wp(context, 60 / 375),
                            height: ResponsiveUtils.hp(context, 60 / 844),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0F2F5),
                              borderRadius: BorderRadius.circular(ResponsiveUtils.spacing(context, 12)),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Room',
                                  style: TextStyle(
                                    fontSize: ResponsiveUtils.sp(context, 10),
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  res['roomNumber'] ?? '-',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: ResponsiveUtils.sp(context, 18),
                                    color: Color(0xFF2E5077),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: ResponsiveUtils.spacing(context, 16)),
                          
                          // Bilgiler
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  res['guestName'] ?? 'Unnamed',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: ResponsiveUtils.sp(context, 16),
                                  ),
                                ),
                                SizedBox(height: ResponsiveUtils.spacing(context, 4)),
                                Row(
                                  children: [
                                    Icon(Icons.vpn_key, size: ResponsiveUtils.iconSize(context) * (14 / 24), color: Colors.grey[600]),
                                    SizedBox(width: ResponsiveUtils.spacing(context, 4)),
                                    Text(
                                      'PNR: ${res['pnr']}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF2E5077),
                                        letterSpacing: 1.0,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: ResponsiveUtils.spacing(context, 4)),
                                Row(
                                  children: [
                                    Icon(Icons.calendar_today, size: ResponsiveUtils.iconSize(context) * (14 / 24), color: Colors.grey[600]),
                                    SizedBox(width: ResponsiveUtils.spacing(context, 4)),
                                    Text(
                                      'Check-out: ${DateFormat('dd MMM yyyy').format(checkOut)}',
                                      style: TextStyle(
                                        fontSize: ResponsiveUtils.sp(context, 12),
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          // Durum Badge
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: ResponsiveUtils.spacing(context, 10), vertical: ResponsiveUtils.spacing(context, 6)),
                            decoration: BoxDecoration(
                              color: isUsed ? Colors.green.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(ResponsiveUtils.spacing(context, 20)),
                            ),
                            child: Text(
                              isUsed ? 'Active' : 'Pending', // Used = Checked in, active at hotel
                              style: TextStyle(
                                color: isUsed ? Colors.green : Colors.orange,
                                fontWeight: FontWeight.w600,
                                fontSize: ResponsiveUtils.sp(context, 14),
                            ),
                          ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showAddGuestDialog() {
    _roomController.clear();
    _guestNameController.clear();
    _checkOutDate = DateTime.now().add(const Duration(days: 1));

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('New Guest / PNR'),
            content: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _roomController,
                    decoration: const InputDecoration(labelText: 'Room Number'),
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                  TextFormField(
                    controller: _guestNameController,
                    decoration: const InputDecoration(labelText: 'Guest Name'),
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                  SizedBox(height: ResponsiveUtils.spacing(context, 16)),
                  ListTile(
                    title: const Text('Check-out Date'),
                    subtitle: Text(DateFormat('dd MMM yyyy').format(_checkOutDate)),
                    trailing: const Icon(Icons.calendar_month),
                    contentPadding: EdgeInsets.zero,
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _checkOutDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) {
                        setState(() => _checkOutDate = picked);
                      }
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: _isLoading ? null : () async {
                  if (_formKey.currentState!.validate()) {
                    setState(() => _isLoading = true);
                    final navigator = Navigator.of(context);
                    final messenger = ScaffoldMessenger.of(context);
                    
                    try {
                      await DatabaseService().createReservation(
                        widget.hotelName,
                        _roomController.text,
                        _guestNameController.text,
                        DateTime.now(), // Check-in Date (Default: Now)
                        _checkOutDate,
                      );
                      navigator.pop();
                      messenger.showSnackBar(
                        SnackBar(content: Text('PNR created successfully')),
                      );
                    } catch (e) {
                      messenger.showSnackBar(
                        SnackBar(content: Text('Error: $e')),
                      );
                    } finally {
                      setState(() => _isLoading = false);
                    }
                  }
                },
                child: _isLoading 
                  ? SizedBox(width: ResponsiveUtils.wp(context, 20 / 375), height: ResponsiveUtils.hp(context, 20 / 844), child: CircularProgressIndicator(strokeWidth: 2)) 
                  : const Text('Create'),
              ),
            ],
          );
        },
      ),
    );
  }
}










