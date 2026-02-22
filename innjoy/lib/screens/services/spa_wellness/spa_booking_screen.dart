import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'package:login_page/services/database_service.dart';
import 'package:login_page/services/notification_service.dart';
import '../../../../utils/connectivity_utils.dart';
import '../../../utils/responsive_utils.dart';

class SpaBookingScreen extends StatefulWidget {
  final String hotelName;
  final Map<String, dynamic> service;

  const SpaBookingScreen({
    super.key,
    required this.hotelName,
    required this.service,
  });

  @override
  State<SpaBookingScreen> createState() => _SpaBookingScreenState();
}

class _SpaBookingScreenState extends State<SpaBookingScreen> {
  DateTime? _selectedDate;
  String? _selectedTimeSlot;
  bool _isLoading = false;
  final String _selectedPaymentMethod = 'room_charge'; // Default
  List<String> _bookedSlots = [];

  // Fix for memory leak: Store subscription to cancel on dispose
  StreamSubscription<List<String>>? _slotsSubscription;

  final List<String> _morningSlots = ['09:00', '10:00', '11:00'];
  final List<String> _afternoonSlots = [
    '13:00',
    '14:00',
    '15:00',
    '16:00',
    '17:00',
  ];

  @override
  void initState() {
    super.initState();
    // Initialize date to tomorrow or today if needed, for now start null
  }

  @override
  void dispose() {
    // Cancel stream subscription to prevent memory leak
    _slotsSubscription?.cancel();
    super.dispose();
  }

  void _fetchBookedSlots(DateTime date) {
    // Cancel previous subscription before creating new one
    _slotsSubscription?.cancel();

    _slotsSubscription = DatabaseService()
        .getSpaBookedSlots(widget.hotelName, date)
        .listen((slots) {
          if (mounted) {
            setState(() {
              _bookedSlots = slots;
            });
          }
        });
  }

  Future<void> _bookAppointment() async {
    if (_selectedDate == null || _selectedTimeSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a date and time.")),
      );
      return;
    }

    // Check internet connectivity before proceeding
    final hasConnection = await ConnectivityUtils.checkAndShowSnackbar(context);
    if (!hasConnection) return;

    setState(() => _isLoading = true);

    try {
      // Combine date and time
      final timeParts = _selectedTimeSlot!.split(':');
      final hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);
      final appointmentDateTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        hour,
        minute,
      );

      // Call Database Service with complete appointment info
      await DatabaseService().bookSpaAppointment(
        serviceName: widget.service['name'] ?? 'Spa Service',
        duration: "${widget.service['duration'] ?? 60} min",
        price: (widget.service['price'] ?? 0).toDouble(),
        appointmentDate: appointmentDateTime,
        timeSlot: _selectedTimeSlot!,
        paymentMethod: _selectedPaymentMethod,
      );

      // Randevudan 1 saat önce hatýrlatýcý bildirim zamanla
      final reminderTime1h = appointmentDateTime.subtract(
        const Duration(hours: 1),
      );
      await NotificationService().scheduleReminderNotification(
        id: NotificationService.generateNotificationId(
          appointmentDateTime,
          'spa_1h',
        ),
        title: '?? Your Spa Appointment is in 1 Hour',
        body: '${widget.service['name']} - Time: $_selectedTimeSlot',
        scheduledTime: reminderTime1h,
        type: 'spa',
      );

      // Randevudan 30 dakika önce ikinci hatýrlatýcý
      final reminderTime30m = appointmentDateTime.subtract(
        const Duration(minutes: 30),
      );
      await NotificationService().scheduleReminderNotification(
        id: NotificationService.generateNotificationId(
          appointmentDateTime,
          'spa_30m',
        ),
        title: '?? Your Spa Appointment is in 30 Minutes',
        body: '${widget.service['name']} - Time: $_selectedTimeSlot',
        scheduledTime: reminderTime30m,
        type: 'spa',
      );

      if (!mounted) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(ResponsiveUtils.spacing(context, 16)),
          ),
          title: const Text("Appointment Created"),
          content: Text(
            "Your appointment for ${widget.service['name']} has been booked.\n\nDate: ${DateFormat('dd MMM yyyy').format(_selectedDate!)}\nTime: $_selectedTimeSlot\n\n?? Reminders set: 1 hour and 30 min before",
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx); // Close dialog
                Navigator.pop(context); // Close screen
              },
              child: const Text("OK"),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final String name = widget.service['name'] ?? 'Service';
    final int duration = widget.service['duration'] ?? 60;
    final double price = (widget.service['price'] ?? 0).toDouble();
    final String description =
        widget.service['description'] ?? 'No description available.';
    final String imageUrl =
        widget.service['imageUrl'] ?? 'https://via.placeholder.com/300';

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F8),
      body: CustomScrollView(
        slivers: [
          // Hero Header
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            leading: Container(
              margin: EdgeInsets.all(ResponsiveUtils.spacing(context, 8)),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Color(0xFF0d141b)),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (ctx, error, stackTrace) =>
                    Container(color: Colors.grey[300]),
              ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 20)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title & Price
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: ResponsiveUtils.sp(context, 24),
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0d141b),
                          ),
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '?${price.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: ResponsiveUtils.sp(context, 24),
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF137fec),
                            ),
                          ),
                          Text(
                            '$duration min',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: ResponsiveUtils.sp(context, 14),
                              color: Color(0xFF4c739a),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: ResponsiveUtils.spacing(context, 16)),

                  // Description
                  Text(
                    description,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: ResponsiveUtils.sp(context, 14),
                      color: Color(0xFF4c739a),
                      height: ResponsiveUtils.hp(context, 1.6 / 844),
                    ),
                  ),
                  SizedBox(height: ResponsiveUtils.spacing(context, 32)),
                  Divider(),
                  SizedBox(height: ResponsiveUtils.spacing(context, 24)),

                  // Date Selection
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 8)),
                        decoration: BoxDecoration(
                          color: const Color(0xFF137fec).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(ResponsiveUtils.spacing(context, 10)),
                        ),
                        child: Icon(
                          Icons.calendar_month_rounded,
                          color: Color(0xFF137fec),
                          size: ResponsiveUtils.iconSize(context) * (20 / 24),
                        ),
                      ),
                      SizedBox(width: ResponsiveUtils.spacing(context, 12)),
                      Text(
                        "Select Date",
                        style: TextStyle(
                          fontSize: ResponsiveUtils.sp(context, 18),
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0d141b),
                          letterSpacing: -0.3,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: ResponsiveUtils.spacing(context, 12)),
                  SizedBox(
                    height: ResponsiveUtils.hp(context, 90 / 844),
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: 14, // Next 2 weeks
                      separatorBuilder: (_, e) => SizedBox(width: ResponsiveUtils.spacing(context, 12)),
                      itemBuilder: (context, index) {
                        final date = DateTime.now().add(Duration(days: index));
                        final isSelected =
                            _selectedDate != null &&
                            _selectedDate!.day == date.day &&
                            _selectedDate!.month == date.month;
                        final isToday = index == 0;

                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedDate = date;
                              _selectedTimeSlot = null; // Reset time
                              _bookedSlots =
                                  []; // Clear previous slots temporarily
                            });
                            _fetchBookedSlots(date);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: ResponsiveUtils.wp(context, 65 / 375),
                            decoration: BoxDecoration(
                              gradient: isSelected
                                  ? const LinearGradient(
                                      colors: [
                                        Color(0xFF137fec),
                                        Color(0xFF0A5EC7),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    )
                                  : null,
                              color: isSelected ? null : Colors.white,
                              borderRadius: BorderRadius.circular(ResponsiveUtils.spacing(context, 16)),
                              border: isSelected
                                  ? null
                                  : Border.all(
                                      color: isToday
                                          ? const Color(
                                              0xFF137fec,
                                            ).withValues(alpha: 0.3)
                                          : Colors.grey[300]!,
                                      width: isToday ? 2 : 1,
                                    ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: const Color(
                                          0xFF137fec,
                                        ).withValues(alpha: 0.4),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ]
                                  : [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.04,
                                        ),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  DateFormat('EEE').format(date),
                                  style: TextStyle(
                                    fontSize: ResponsiveUtils.sp(context, 12),
                                    fontWeight: FontWeight.w500,
                                    color: isSelected
                                        ? Colors.white.withValues(alpha: 0.8)
                                        : Colors.grey[600],
                                  ),
                                ),
                                SizedBox(height: ResponsiveUtils.spacing(context, 6)),
                                Text(
                                  DateFormat('dd').format(date),
                                  style: TextStyle(
                                    fontSize: ResponsiveUtils.sp(context, 22),
                                    fontWeight: FontWeight.bold,
                                    color: isSelected
                                        ? Colors.white
                                        : const Color(0xFF0d141b),
                                  ),
                                ),
                                if (isToday) ...[
                                  SizedBox(height: ResponsiveUtils.spacing(context, 4)),
                                  Container(
                                    width: ResponsiveUtils.wp(context, 6 / 375),
                                    height: ResponsiveUtils.hp(context, 6 / 844),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? Colors.white
                                          : const Color(0xFF137fec),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  SizedBox(height: ResponsiveUtils.spacing(context, 24)),

                  // Time Selection
                  if (_selectedDate != null) ...[
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 8)),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFF137fec,
                            ).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(ResponsiveUtils.spacing(context, 10)),
                          ),
                          child: Icon(
                            Icons.access_time_rounded,
                            color: Color(0xFF137fec),
                            size: ResponsiveUtils.iconSize(context) * (20 / 24),
                          ),
                        ),
                        SizedBox(width: ResponsiveUtils.spacing(context, 12)),
                        Text(
                          "Select Time",
                          style: TextStyle(
                            fontSize: ResponsiveUtils.sp(context, 18),
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0d141b),
                            letterSpacing: -0.3,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: ResponsiveUtils.spacing(context, 16)),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        ..._morningSlots.map((time) => _buildTimeChip(time)),
                        ..._afternoonSlots.map((time) => _buildTimeChip(time)),
                      ],
                    ),
                    SizedBox(height: ResponsiveUtils.spacing(context, 32)),

                    // Payment Method
                    if (_selectedDate != null && _selectedTimeSlot != null) ...[
                      Divider(),
                      SizedBox(height: ResponsiveUtils.spacing(context, 24)),
                      _buildPaymentMethodSection(),
                      SizedBox(height: ResponsiveUtils.spacing(context, 24)),
                      _buildSummarySection(price),
                      SizedBox(height: ResponsiveUtils.spacing(context, 100)), // Bottom padding
                    ] else ...[
                      SizedBox(height: ResponsiveUtils.spacing(context, 100)),
                    ],
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, -8),
            ),
          ],
        ),
        child: SafeArea(
          child: SizedBox(
            width: double.infinity,
            height: ResponsiveUtils.hp(context, 56 / 844),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              decoration: BoxDecoration(
                gradient:
                    (_selectedDate != null &&
                        _selectedTimeSlot != null &&
                        !_isLoading)
                    ? LinearGradient(
                        colors: [Color(0xFF137fec), Color(0xFF0A5EC7)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      )
                    : null,
                color:
                    (_selectedDate == null ||
                        _selectedTimeSlot == null ||
                        _isLoading)
                    ? Colors.grey[200]
                    : null,
                borderRadius: BorderRadius.circular(ResponsiveUtils.spacing(context, 16)),
                boxShadow:
                    (_selectedDate != null &&
                        _selectedTimeSlot != null &&
                        !_isLoading)
                    ? [
                        BoxShadow(
                          color: const Color(0xFF137fec).withValues(alpha: 0.4),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ]
                    : null,
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap:
                      (_selectedDate != null &&
                          _selectedTimeSlot != null &&
                          !_isLoading)
                      ? _bookAppointment
                      : null,
                  borderRadius: BorderRadius.circular(ResponsiveUtils.spacing(context, 16)),
                  child: Center(
                    child: _isLoading
                        ? SizedBox(
                            width: ResponsiveUtils.wp(context, 24 / 375),
                            height: ResponsiveUtils.hp(context, 24 / 844),
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.calendar_today_rounded,
                                size: ResponsiveUtils.iconSize(context) * (20 / 24),
                                color:
                                    (_selectedDate != null &&
                                        _selectedTimeSlot != null)
                                    ? Colors.white
                                    : Colors.grey[400],
                              ),
                              SizedBox(width: ResponsiveUtils.spacing(context, 10)),
                              Text(
                                "Book Appointment",
                                style: TextStyle(
                                  fontSize: ResponsiveUtils.sp(context, 17),
                                  fontWeight: FontWeight.w700,
                                  color:
                                      (_selectedDate != null &&
                                          _selectedTimeSlot != null)
                                      ? Colors.white
                                      : Colors.grey[400],
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimeChip(String time) {
    bool isSelected = _selectedTimeSlot == time;
    bool isBooked = _bookedSlots.contains(time);

    // Check if this time slot is in the past for today
    bool isPastTime = false;
    if (_selectedDate != null) {
      final now = DateTime.now();
      final isToday =
          _selectedDate!.year == now.year &&
          _selectedDate!.month == now.month &&
          _selectedDate!.day == now.day;

      if (isToday) {
        final timeParts = time.split(':');
        final slotHour = int.parse(timeParts[0]);
        final slotMinute = int.parse(timeParts[1]);

        // If current time is past or equal to the slot time, disable it
        if (now.hour > slotHour ||
            (now.hour == slotHour && now.minute >= slotMinute)) {
          isPastTime = true;
        }
      }
    }

    bool isDisabled = isBooked || isPastTime;

    return GestureDetector(
      onTap: isDisabled ? null : () => setState(() => _selectedTimeSlot = time),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: ResponsiveUtils.spacing(context, 20), vertical: ResponsiveUtils.spacing(context, 12)),
        decoration: BoxDecoration(
          color: isDisabled
              ? Colors.grey[100]
              : (isSelected ? const Color(0xFF137fec) : Colors.white),
          borderRadius: BorderRadius.circular(ResponsiveUtils.spacing(context, 12)),
          border: Border.all(
            color: isDisabled
                ? Colors.grey[300]!
                : (isSelected ? const Color(0xFF137fec) : Colors.grey[300]!),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF137fec).withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          time,
          style: TextStyle(
            color: isDisabled
                ? Colors.grey[400]
                : (isSelected ? Colors.white : const Color(0xFF0d141b)),
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            fontSize: ResponsiveUtils.sp(context, 15),
            decoration: isBooked ? TextDecoration.lineThrough : null,
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentMethodSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Payment Method",
          style: TextStyle(
            fontSize: ResponsiveUtils.sp(context, 16),
            fontWeight: FontWeight.bold,
            color: Color(0xFF0d141b),
          ),
        ),
        SizedBox(height: ResponsiveUtils.spacing(context, 12)),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(ResponsiveUtils.spacing(context, 12)),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: ListTile(
            leading: const Icon(Icons.radio_button_checked, color: Color(0xFF137fec)),
            title: Text(
              'Charge to Room',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: ResponsiveUtils.sp(context, 16),
                color: Color(0xFF0d141b),
              ),
            ),
            subtitle: Text(
              'The amount will be added to your checkout bill.',
              style: TextStyle(fontSize: ResponsiveUtils.sp(context, 14), color: Colors.grey),
            ),
            trailing: Container(
              padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 8)),
              decoration: BoxDecoration(
                color: const Color(0xFF137fec).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(ResponsiveUtils.spacing(context, 8)),
              ),
              child: const Icon(Icons.receipt_long, color: Color(0xFF137fec)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummarySection(double price) {
    return Container(
      padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 16)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(ResponsiveUtils.spacing(context, 12)),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Service Fee',
                style: TextStyle(fontSize: ResponsiveUtils.sp(context, 14), color: Colors.grey),
              ),
              Text(
                '?${price.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: ResponsiveUtils.sp(context, 14),
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF0d141b),
                ),
              ),
            ],
          ),
          Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Amount',
                style: TextStyle(
                  fontSize: ResponsiveUtils.sp(context, 16),
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0d141b),
                ),
              ),
              Text(
                '?${price.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: ResponsiveUtils.sp(context, 18),
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF137fec),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
