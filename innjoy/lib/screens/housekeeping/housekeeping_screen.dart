import 'package:flutter/material.dart';
import 'package:login_page/services/logger_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/database_service.dart';
import '../../utils/responsive_utils.dart'; // Servis importu

class HousekeepingScreen extends StatefulWidget {
  const HousekeepingScreen({super.key});

  @override
  State<HousekeepingScreen> createState() => _HousekeepingScreenState();
}

class _HousekeepingScreenState extends State<HousekeepingScreen> {
  // --- TASARIM DEĞİŞKENLERİ ---
  bool _doNotDisturb = false;
  int _selectedTimeType = 0; // 0: Hemen Temizle, 1: Belirli Saat Aralığında
  String _selectedTimeRange = '14:00 - 16:00';

  // Malzeme talepleri
  int _extraTowelCount = 0;
  int _pillowCount = 0;
  int _blanketCount = 0;

  final TextEditingController _notesController = TextEditingController();

  //--- MANTIK DEĞİŞKENLERİ ---
  bool _requestSent = false; // UI durumu için
  bool _isLoading = false; // Yükleniyor durumu için

  // User and hotel context
  String? _hotelName;
  String? _roomNumber;

  final List<String> _timeRanges = [
    '08:00 - 10:00',
    '10:00 - 12:00',
    '12:00 - 14:00',
    '14:00 - 16:00',
    '16:00 - 18:00',
    '18:00 - 20:00',
  ];

  @override
  void initState() {
    super.initState();
    _loadUserContext();
  }

  Future<void> _loadUserContext() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        Logger.debug('?? Loading user data for UID: ${user.uid}');

        // Fetch user data directly from Firestore
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists && mounted) {
          final userData = userDoc.data();
          if (userData != null) {
            setState(() {
              _hotelName = userData['hotelName'];
              _roomNumber = userData['roomNumber'];
              _doNotDisturb = userData['doNotDisturb'] ?? false;
            });
            Logger.debug(
              '? User context loaded: Hotel=$_hotelName, Room=$_roomNumber, DND=$_doNotDisturb',
            );
          } else {
            Logger.debug('? User document exists but data is null');
          }
        } else {
          Logger.debug('? User document does not exist for UID: ${user.uid}');
        }
      } catch (e) {
        Logger.debug('? Error loading user context: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error loading user data: $e'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } else {
      Logger.debug('? No authenticated user');
    }
  }

  Future<void> _updateDoNotDisturb(bool? value) async {
    if (value == null) return;

    // Check if user data is loaded (only for customers)
    if (_hotelName == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please wait, loading your hotel information...'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    // For customers, roomNumber is required
    // For admins, roomNumber is optional (they might be testing)
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && _roomNumber == null) {
      // Check if user is admin
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final role = userDoc.data()?['role'];

      // If customer and no roomNumber, show error
      if (role != 'admin') {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Room number not found. Please contact reception.'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
        }
        return;
      }
    }

    setState(() => _doNotDisturb = value);

    try {
      Logger.debug(
        '?? Updating DND to: $value for Hotel=$_hotelName, Room=$_roomNumber',
      );

      // Update room's doNotDisturb status in Firebase (if roomNumber exists)
      if (_roomNumber != null) {
        await FirebaseFirestore.instance
            .collection('hotels')
            .doc(_hotelName)
            .collection('rooms')
            .doc(_roomNumber)
            .set({'doNotDisturb': value}, SetOptions(merge: true));
      }

      // Also update user document
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({'doNotDisturb': value});
      }

      Logger.debug('? DND updated successfully');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              value ? 'Do Not Disturb enabled' : 'Do Not Disturb disabled',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      Logger.debug('? Error updating DND: $e');
      // Revert state on error
      setState(() => _doNotDisturb = !value);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  // --- FIREBASE İSTEK GÖNDERME FONKSİYONU ---
  Future<void> _sendRequest() async {
    setState(() => _isLoading = true);

    // 1. Verileri Hazırla: Tasarımdaki tüm seçimleri birleştiriyoruz
    StringBuffer detailsBuffer = StringBuffer();
    detailsBuffer.writeln(
      "Timing: ${_selectedTimeType == 0 ? 'Now' : _selectedTimeRange}",
    );

    if (_doNotDisturb) {
      detailsBuffer.writeln("STATUS: DO NOT DISTURB");
    }

    if (_extraTowelCount > 0) {
      detailsBuffer.writeln("Extra Towels: $_extraTowelCount");
    }
    if (_pillowCount > 0) detailsBuffer.writeln("Pillows: $_pillowCount");
    if (_blanketCount > 0) detailsBuffer.writeln("Blankets: $_blanketCount");

    // Add user note
    if (_notesController.text.isNotEmpty) {
      detailsBuffer.writeln("\nUser Note: ${_notesController.text}");
    }

    try {
      // 2. Servisi çağır (Kategori otomatik olarak 'Housekeeping')
      await DatabaseService().requestHousekeeping(
        'Housekeeping', // Kategori
        detailsBuffer.toString(), // Hazırladığımız detaylı metin
      );

      if (!mounted) return;

      // 3. Başarılı ise UI güncelle
      setState(() {
        _requestSent = true;
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Your request has been successfully submitted."),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error occurred: $e"),
          backgroundColor: Colors.red,
        ),
      );
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
          'Housekeeping Request',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
            fontSize: ResponsiveUtils.sp(context, 18),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Rahatsız Etmeyin Toggle
            Container(
              padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 16)),
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
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Do Not Disturb',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: ResponsiveUtils.sp(context, 16),
                          ),
                        ),
                        SizedBox(height: ResponsiveUtils.spacing(context, 4)),
                        Text(
                          'Privacy note will be added below.',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: ResponsiveUtils.sp(context, 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _doNotDisturb,
                    onChanged: _updateDoNotDisturb,
                    activeThumbColor: const Color(0xFF1677FF),
                  ),
                ],
              ),
            ),

            SizedBox(height: ResponsiveUtils.spacing(context, 24)),

            // Show cleaning options only if DND is OFF
            if (!_doNotDisturb) ...[
              // Cleaning Request
              Text(
                'Cleaning Request',
                style: TextStyle(fontSize: ResponsiveUtils.sp(context, 18), fontWeight: FontWeight.w700),
              ),
              SizedBox(height: ResponsiveUtils.spacing(context, 12)),

              // Zaman Seçimi Chips
              Row(
                children: [
                  _TimeChip(
                    label: 'Clean Now',
                    isSelected: _selectedTimeType == 0,
                    onTap: () => setState(() => _selectedTimeType = 0),
                  ),
                  SizedBox(width: ResponsiveUtils.spacing(context, 12)),
                  _TimeChip(
                    label: 'Specific Time Range',
                    isSelected: _selectedTimeType == 1,
                    onTap: () => setState(() => _selectedTimeType = 1),
                  ),
                ],
              ),

              // Saat Seçimi (sadece Belirli Saat Aralığında seçiliyse)
              if (_selectedTimeType == 1) ...[
                SizedBox(height: ResponsiveUtils.spacing(context, 16)),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: ResponsiveUtils.spacing(context, 16),
                    vertical: ResponsiveUtils.spacing(context, 12),
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(ResponsiveUtils.spacing(context, 12)),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Select Time',
                        style: TextStyle(color: Colors.black54, fontSize: ResponsiveUtils.sp(context, 15)),
                      ),
                      GestureDetector(
                        onTap: () => _showTimeRangePicker(),
                        child: Row(
                          children: [
                            Text(
                              _selectedTimeRange,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: ResponsiveUtils.sp(context, 15),
                              ),
                            ),
                            SizedBox(width: ResponsiveUtils.spacing(context, 8)),
                            Icon(
                              Icons.keyboard_arrow_down,
                              color: Colors.grey[600],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ], // Close cleaning request if block
            // Show info message when DND is active
            if (_doNotDisturb) ...[
              Container(
                padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 16)),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(ResponsiveUtils.spacing(context, 12)),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.orange[700],
                      size: ResponsiveUtils.iconSize(context) * (24 / 24),
                    ),
                    SizedBox(width: ResponsiveUtils.spacing(context, 12)),
                    Expanded(
                      child: Text(
                        'Cleaning services are disabled while "Do Not Disturb" is active. Turn off DND to request cleaning.',
                        style: TextStyle(
                          color: Colors.orange[900],
                          fontSize: ResponsiveUtils.sp(context, 14),
                          height: ResponsiveUtils.hp(context, 1.4 / 844),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            SizedBox(height: ResponsiveUtils.spacing(context, 24)),

            // Material and Extra Requests (only if DND is OFF)
            if (!_doNotDisturb) ...[
              Text(
                'Material and Extra Requests',
                style: TextStyle(fontSize: ResponsiveUtils.sp(context, 18), fontWeight: FontWeight.w700),
              ),
              SizedBox(height: ResponsiveUtils.spacing(context, 12)),

              _MaterialRequestItem(
                icon: Icons.local_laundry_service,
                label: 'Extra Towels',
                count: _extraTowelCount,
                onDecrement: () {
                  if (_extraTowelCount > 0) {
                    setState(() => _extraTowelCount--);
                  }
                },
                onIncrement: () => setState(() => _extraTowelCount++),
              ),
              SizedBox(height: ResponsiveUtils.spacing(context, 12)),

              _MaterialRequestItem(
                icon: Icons.king_bed,
                label: 'Pillows',
                count: _pillowCount,
                onDecrement: () {
                  if (_pillowCount > 0) {
                    setState(() => _pillowCount--);
                  }
                },
                onIncrement: () => setState(() => _pillowCount++),
              ),
              SizedBox(height: ResponsiveUtils.spacing(context, 12)),

              _MaterialRequestItem(
                icon: Icons.airline_seat_individual_suite,
                label: 'Blankets',
                count: _blanketCount,
                onDecrement: () {
                  if (_blanketCount > 0) {
                    setState(() => _blanketCount--);
                  }
                },
                onIncrement: () => setState(() => _blanketCount++),
              ),
            ], // Close material requests if block

            SizedBox(height: ResponsiveUtils.spacing(context, 24)),

            // Special Requests and Complaints (only if DND is OFF)
            if (!_doNotDisturb) ...[
              Text(
                'Special Requests and Complaints',
                style: TextStyle(fontSize: ResponsiveUtils.sp(context, 18), fontWeight: FontWeight.w700),
              ),
              SizedBox(height: ResponsiveUtils.spacing(context, 12)),

              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(ResponsiveUtils.spacing(context, 12)),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: TextField(
                  controller: _notesController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText:
                        'Please write your special requests or notes here...',
                    hintStyle: TextStyle(color: Colors.grey[400], fontSize: ResponsiveUtils.sp(context, 14)),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(ResponsiveUtils.spacing(context, 16)),
                  ),
                ),
              ),
            ], // Close special requests if block

            SizedBox(height: ResponsiveUtils.spacing(context, 24)),

            // Request Tracking (only if DND is OFF)
            if (!_doNotDisturb) ...[
              Text(
                'Request Tracking',
                style: TextStyle(fontSize: ResponsiveUtils.sp(context, 18), fontWeight: FontWeight.w700),
              ),
              SizedBox(height: ResponsiveUtils.spacing(context, 12)),

              Container(
                padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 16)),
                decoration: BoxDecoration(
                  color: _requestSent ? const Color(0xFFE8F5E9) : Colors.white,
                  borderRadius: BorderRadius.circular(ResponsiveUtils.spacing(context, 12)),
                  border: Border.all(
                    color: _requestSent
                        ? const Color(0xFF4CAF50)
                        : Colors.grey[300]!,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: ResponsiveUtils.wp(context, 40 / 375),
                      height: ResponsiveUtils.hp(context, 40 / 844),
                      decoration: BoxDecoration(
                        color: _requestSent
                            ? const Color(0xFF4CAF50)
                            : Colors.grey[200],
                        borderRadius: BorderRadius.circular(ResponsiveUtils.spacing(context, 20)),
                      ),
                      child: Icon(
                        _requestSent ? Icons.check : Icons.hourglass_empty,
                        color: _requestSent ? Colors.white : Colors.grey[500],
                        size: ResponsiveUtils.iconSize(context) * (20 / 24),
                      ),
                    ),
                    SizedBox(width: ResponsiveUtils.spacing(context, 12)),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _requestSent ? 'Request Sent' : 'Waiting',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: ResponsiveUtils.sp(context, 15),
                              color: _requestSent
                                  ? const Color(0xFF2E7D32)
                                  : Colors.black87,
                            ),
                          ),
                          SizedBox(height: ResponsiveUtils.spacing(context, 2)),
                          Text(
                            _requestSent
                                ? 'Our team will attend to it as soon as possible.'
                                : 'Click the button below to send your request.',
                            style: TextStyle(
                              color: _requestSent
                                  ? const Color(0xFF388E3C)
                                  : Colors.grey[600],
                              fontSize: ResponsiveUtils.sp(context, 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ], // Close request tracking if block

            SizedBox(height: ResponsiveUtils.spacing(context, 100)),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 16)),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: ElevatedButton(
            // Eğer istek gönderildiyse veya şu an yükleniyorsa butona basılmasın
            onPressed: (_requestSent || _isLoading) ? null : _sendRequest,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1677FF),
              disabledBackgroundColor: Colors.grey[300],
              padding: EdgeInsets.symmetric(
                vertical: ResponsiveUtils.spacing(context, 16),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(ResponsiveUtils.spacing(context, 12)),
              ),
            ),
            child: _isLoading
                ? SizedBox(
                    height: ResponsiveUtils.hp(context, 20 / 844),
                    width: ResponsiveUtils.wp(context, 20 / 375),
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    _requestSent ? 'Request Sent' : 'Send Request',
                    style: TextStyle(
                      color: _requestSent ? Colors.grey[600] : Colors.white,
                      fontSize: ResponsiveUtils.sp(context, 16),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  void _showTimeRangePicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 20)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Time Range',
              style: TextStyle(fontSize: ResponsiveUtils.sp(context, 18), fontWeight: FontWeight.w700),
            ),
            SizedBox(height: ResponsiveUtils.spacing(context, 16)),
            ...List.generate(_timeRanges.length, (index) {
              final range = _timeRanges[index];
              final isSelected = range == _selectedTimeRange;
              return ListTile(
                onTap: () {
                  setState(() {
                    _selectedTimeRange = range;
                  });
                  Navigator.pop(context);
                },
                title: Text(
                  range,
                  style: TextStyle(
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.normal,
                    color: isSelected
                        ? const Color(0xFF1677FF)
                        : Colors.black87,
                  ),
                ),
                trailing: isSelected
                    ? const Icon(Icons.check, color: Color(0xFF1677FF))
                    : null,
              );
            }),
            SizedBox(height: ResponsiveUtils.spacing(context, 16)),
          ],
        ),
      ),
    );
  }
}

  // --- YARDIMCI WIDGET'LAR (Tasarım Kodundan) ---

class _TimeChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TimeChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: ResponsiveUtils.spacing(context, 16), vertical: ResponsiveUtils.spacing(context, 10)),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE3F2FD) : Colors.white,
          borderRadius: BorderRadius.circular(ResponsiveUtils.spacing(context, 20)),
          border: Border.all(
            color: isSelected ? const Color(0xFF1677FF) : Colors.grey[300]!,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? const Color(0xFF1677FF) : Colors.black87,
            fontWeight: FontWeight.w500,
            fontSize: ResponsiveUtils.sp(context, 14),
          ),
        ),
      ),
    );
  }
}

class _MaterialRequestItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final int count;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;

  const _MaterialRequestItem({
    required this.icon,
    required this.label,
    required this.count,
    required this.onDecrement,
    required this.onIncrement,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: ResponsiveUtils.spacing(context, 16), vertical: ResponsiveUtils.spacing(context, 12)),
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
      ),
      child: Row(
        children: [
          Container(
            width: ResponsiveUtils.wp(context, 40 / 375),
            height: ResponsiveUtils.hp(context, 40 / 844),
            decoration: BoxDecoration(
              color: const Color(0xFFE3F2FD),
              borderRadius: BorderRadius.circular(ResponsiveUtils.spacing(context, 10)),
            ),
            child: Icon(icon, color: const Color(0xFF1677FF), size: ResponsiveUtils.iconSize(context) * (22 / 24)),
          ),
          SizedBox(width: ResponsiveUtils.spacing(context, 12)),
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontWeight: FontWeight.w500, fontSize: ResponsiveUtils.sp(context, 15)),
            ),
          ),
          // Counter
          Row(
            children: [
              GestureDetector(
                onTap: onDecrement,
                child: Container(
                  width: ResponsiveUtils.wp(context, 32 / 375),
                  height: ResponsiveUtils.hp(context, 32 / 844),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(ResponsiveUtils.spacing(context, 8)),
                  ),
                  child: Icon(
                    Icons.remove,
                    size: ResponsiveUtils.iconSize(context) * (18 / 24),
                    color: Colors.black54,
                  ),
                ),
              ),
              SizedBox(
                width: ResponsiveUtils.wp(context, 40 / 375),
                child: Text(
                  count.toString(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: ResponsiveUtils.sp(context, 16),
                  ),
                ),
              ),
              GestureDetector(
                onTap: onIncrement,
                child: Container(
                  width: ResponsiveUtils.wp(context, 32 / 375),
                  height: ResponsiveUtils.hp(context, 32 / 844),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1677FF),
                    borderRadius: BorderRadius.circular(ResponsiveUtils.spacing(context, 8)),
                  ),
                  child: Icon(Icons.add, size: ResponsiveUtils.iconSize(context) * (18 / 24), color: Colors.white),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
