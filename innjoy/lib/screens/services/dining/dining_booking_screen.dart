import 'package:flutter/material.dart';
import '../../../services/database_service.dart';
import 'package:flutter/cupertino.dart';

class DiningBookingScreen extends StatefulWidget {
  final String hotelName;
  final String restaurantId;
  final String restaurantName;
  final String? imageUrl;

  const DiningBookingScreen({
    super.key,
    required this.hotelName,
    required this.restaurantId,
    required this.restaurantName,
    this.imageUrl,
  });

  @override
  State<DiningBookingScreen> createState() => _DiningBookingScreenState();
}

class _DiningBookingScreenState extends State<DiningBookingScreen> {
  DateTime _selectedDate = DateTime.now();
  int _guestCount = 2;
  // Fixed time as requested
  TimeOfDay _selectedTime = const TimeOfDay(hour: 20, minute: 0); 
  final TextEditingController _specialRequestsController = TextEditingController();
  final DatabaseService _db = DatabaseService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // If current time is after 20:00, default to tomorrow
    final now = DateTime.now();
    if (now.hour >= 20) {
      _selectedDate = now.add(const Duration(days: 1));
    }
  }

  @override
  void dispose() {
    _specialRequestsController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final now = DateTime.now();
    // Determine the first selectable date:
    // If it's past 20:00 today, the earliest slot is tomorrow.
    // Otherwise, it's today.
    final firstDate = now.hour >= 20 ? now.add(const Duration(days: 1)) : now;
    
    // If current _selectedDate is older than firstDate (e.g. stale state), update it
    if (_selectedDate.isBefore(DateTime(firstDate.year, firstDate.month, firstDate.day))) {
      _selectedDate = firstDate;
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: firstDate,
      lastDate: DateTime.now().add(const Duration(days: 90)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF137fec), // App Primary Color
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }


  void _selectTime() {
    showCupertinoModalPopup(
      context: context,
      builder: (_) => Container(
        height: 300,
        color: Colors.white,
        child: Column(
          children: [
            SizedBox(
              height: 200,
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.time,
                use24hFormat: true,
                initialDateTime: DateTime(
                  DateTime.now().year,
                  DateTime.now().month,
                  DateTime.now().day,
                  _selectedTime.hour,
                  _selectedTime.minute,
                ),
                onDateTimeChanged: (val) {
                  setState(() {
                    _selectedTime = TimeOfDay.fromDateTime(val);
                  });
                },
              ),
            ),
            // Close button
            CupertinoButton(
              child: const Text('OK', style: TextStyle(
                color: Color(0xFF137fec), 
                fontSize: 18, 
                fontWeight: FontWeight.bold
              )),
              onPressed: () => Navigator.of(context).pop(),
            )
          ],
        ),
      ),
    );
  }

  // Helper for 24h formatting
  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Future<void> _confirmReservation() async {
    setState(() => _isLoading = true);

    // Construct the full DateTime for 20:00 on the selected day
    final reservationDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    final result = await _db.makeReservation(
      widget.hotelName,
      widget.restaurantId,
      widget.restaurantName,
      reservationDateTime,
      _guestCount,
      _specialRequestsController.text,
    );

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (result['success'] == true) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.check_rounded, color: Colors.green.shade600, size: 40),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Reservation Confirmed!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF101922),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your table is ready for you.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                const SizedBox(height: 24),
                
                // Details Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF6F7FB),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    children: [
                      _buildDetailRow(Icons.restaurant, widget.restaurantName),
                      const SizedBox(height: 12),
                      _buildDetailRow(Icons.calendar_today, _formatDate(_selectedDate)),
                      const SizedBox(height: 12),
                      _buildDetailRow(Icons.access_time, _formatTime(_selectedTime)),
                      const SizedBox(height: 12),
                      _buildDetailRow(Icons.people, '$_guestCount Guests'),
                      const Divider(height: 24),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF137fec).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF137fec).withValues(alpha: 0.2)),
                        ),
                        child: Text(
                          'Table ${result['tableNumber']}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 16, 
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF137fec),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context); // Close dialog
                      Navigator.pop(context); // Close screen
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF137fec),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: const Text('Done', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Reservation failed'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Widget _buildDetailRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Color(0xFF101922),
            ),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  Widget _buildHeaderImage() {
    if (widget.imageUrl != null && widget.imageUrl!.isNotEmpty) {
      final isNetwork = widget.imageUrl!.startsWith('http');
      return Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
          image: DecorationImage(
            image: isNetwork 
                ? NetworkImage(widget.imageUrl!) as ImageProvider
                : AssetImage(widget.imageUrl!),
            fit: BoxFit.cover,
          ),
        ),
      );
    }

    
    // Fallback: Fetch from settings if not passed (e.g. from FAB)
    return StreamBuilder<Map<String, dynamic>?>(
      stream: _db.getRestaurantSettings(widget.hotelName, widget.restaurantId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        final data = snapshot.data;
        final String? dynamicUrl = data?['imageUrl']; 
        
        if (dynamicUrl != null && dynamicUrl.isNotEmpty) {
          final isNetwork = dynamicUrl.startsWith('http');
          return Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              image: DecorationImage(
                image: isNetwork 
                    ? NetworkImage(dynamicUrl) as ImageProvider
                    : AssetImage(dynamicUrl),
                fit: BoxFit.cover,
              ),
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
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
        title: const Text(
          'Book a Table',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Restaurant Info Card with Image
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeaderImage(),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.restaurantName,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF101922),
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Exclusive Dining Experience',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),

            // Date & Guests Row
            Row(
              children: [
                // Date Selector
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Date',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black54),
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: _selectDate,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: Row(
                            children: [
                              Text(
                                _formatDate(_selectedDate),
                                style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
                              ),
                              const Spacer(),
                              Icon(Icons.calendar_today_outlined, color: Colors.grey[600], size: 20),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                // Guest Counter
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Guests',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black54),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              if (_guestCount > 1) setState(() => _guestCount--);
                            },
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.remove, size: 18),
                            ),
                          ),
                          SizedBox(
                            width: 40,
                            child: Text(
                              _guestCount.toString(),
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              if (_guestCount < 20) setState(() => _guestCount++);
                            },
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: const Color(0xFF137fec),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.add, size: 18, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Time Selection (Fixed)
            const Text(
              'Time',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black54),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _selectTime,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF137fec),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF137fec).withValues(alpha: 0.4), // Stronger shadow
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.access_time_filled, color: Colors.white, size: 24),
                    const SizedBox(width: 10),
                    Text(
                      _formatTime(_selectedTime),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Center(
              child: Text(
                'Select your preferred seating time.',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ),

            const SizedBox(height: 24),

            // Special Requests
            const Text(
              'Special Requests (Optional)',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black54),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: TextField(
                controller: _specialRequestsController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'e.g. allergies, high chair needed, window seat...',
                  hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
            ),

            const SizedBox(height: 100),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
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
            onPressed: _isLoading ? null : _confirmReservation,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF137fec),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: _isLoading 
              ? const SizedBox(
                  width: 24, height: 24, 
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                )
              : const Text(
                  'Confirm Reservation',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
          ),
        ),
      ),
    );
  }
}










