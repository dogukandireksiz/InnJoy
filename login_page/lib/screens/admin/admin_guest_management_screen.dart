import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../service/database_service.dart';

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
          // Arama Çubuğu
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
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
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
                        Icon(Icons.person_search, size: 80, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isEmpty ? 'No guests yet.' : 'No records found.',
                          style: TextStyle(color: Colors.grey[600], fontSize: 16),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: reservations.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final res = reservations[index];
                    final isUsed = res['status'] == 'used';
                    final checkOut = (res['checkOutDate'] as Timestamp).toDate();

                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
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
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0F2F5),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Room',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  res['roomNumber'] ?? '-',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: Color(0xFF2E5077),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          
                          // Bilgiler
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  res['guestName'] ?? 'Unnamed',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(Icons.vpn_key, size: 14, color: Colors.grey[600]),
                                    const SizedBox(width: 4),
                                    Text(
                                      'PNR: ${res['pnr']}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF2E5077),
                                        letterSpacing: 1.0,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Check-out: ${DateFormat('dd MMM yyyy').format(checkOut)}',
                                      style: TextStyle(
                                        fontSize: 12,
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
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: isUsed ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              isUsed ? 'Active' : 'Pending', // Used = Checked in, active at hotel
                              style: TextStyle(
                                color: isUsed ? Colors.green : Colors.orange,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
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
                  const SizedBox(height: 16),
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
                    
                    try {
                      await DatabaseService().createReservation(
                        widget.hotelName,
                        _roomController.text,
                        _guestNameController.text,
                        DateTime.now(), // Check-in Date (Default: Now)
                        _checkOutDate,
                      );
                      if (mounted) Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('PNR created successfully')),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: $e')),
                      );
                    } finally {
                      setState(() => _isLoading = false);
                    }
                  }
                },
                child: _isLoading 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) 
                  : const Text('Create'),
              ),
            ],
          );
        },
      ),
    );
  }
}
