import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../payment/payment_screen.dart';

class SpaWellnessBookingScreen extends StatefulWidget {
  final String? preselectedTreatment;
  final String? preselectedDuration;
  final double? preselectedPrice;

  const SpaWellnessBookingScreen({
    super.key,
    this.preselectedTreatment,
    this.preselectedDuration,
    this.preselectedPrice,
  });

  @override
  State<SpaWellnessBookingScreen> createState() => _SpaWellnessBookingScreenState();
}

class _SpaWellnessBookingScreenState extends State<SpaWellnessBookingScreen> {
  // Firebase user
  final user = FirebaseAuth.instance.currentUser;
  
  // Hizmet Seçimi
  String? _selectedService;
  String? _selectedDuration;
  
  // Tarih ve Saat
  DateTime _selectedDate = DateTime.now();
  String? _selectedTime;
  
  // Terapist
  String _selectedTherapist = 'Any Available Therapist';
  
  // İletişim Bilgileri - dinamik olarak doldurulacak
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  final _roomNumberController = TextEditingController(text: '1204');
  
  // Özel Notlar
  final _notesController = TextEditingController();

  // Kullanıcı adını parçala
  String get _firstName {
    if (user?.displayName != null && user!.displayName!.isNotEmpty) {
      final parts = user!.displayName!.split(' ');
      return parts.first;
    }
    if (user?.email != null) {
      return user!.email!.split('@').first;
    }
    return '';
  }

  String get _lastName {
    if (user?.displayName != null && user!.displayName!.isNotEmpty) {
      final parts = user!.displayName!.split(' ');
      if (parts.length > 1) {
        return parts.sublist(1).join(' ');
      }
    }
    return '';
  }

  final List<String> _services = [
    'Aromaterapi Masajı',
    'İsveç Masajı',
    'Derin Doku Masajı',
    'Hot Stone Masajı',
    'Klasik Yüz Bakımı',
    'Anti-Aging Bakımı',
    'Hydrafacial',
    'Vücut Peelingi',
    'Detox Vücut Sargısı',
    'Çikolata Terapisi',
  ];

  final List<String> _durations = [
    '30 dakika',
    '45 dakika',
    '60 dakika',
    '75 dakika',
    '90 dakika',
    '120 dakika',
  ];

  final List<String> _timeSlots = [
    '09:00',
    '10:00',
    '11:00',
    '13:00',
    '14:00',
    '15:00',
    '16:00',
    '17:00',
  ];

  final List<String> _therapists = [
    'Any Available Therapist',
    'Maria S.',
    'John D.',
    'Emma W.',
    'Michael R.',
  ];

  double get _totalPrice {
    if (widget.preselectedPrice != null) {
      return widget.preselectedPrice!;
    }
    // Varsayılan fiyatlar
    if (_selectedService == null || _selectedDuration == null) return 0;
    
    Map<String, double> basePrices = {
      'Aromaterapi Masajı': 110,
      'İsveç Masajı': 95,
      'Derin Doku Masajı': 120,
      'Hot Stone Masajı': 140,
      'Klasik Yüz Bakımı': 75,
      'Anti-Aging Bakımı': 150,
      'Hydrafacial': 185,
      'Vücut Peelingi': 65,
      'Detox Vücut Sargısı': 95,
      'Çikolata Terapisi': 125,
    };
    
    double basePrice = basePrices[_selectedService] ?? 95;
    
    // Süreye göre çarpan
    Map<String, double> durationMultipliers = {
      '30 dakika': 0.6,
      '45 dakika': 0.8,
      '60 dakika': 1.0,
      '75 dakika': 1.2,
      '90 dakika': 1.4,
      '120 dakika': 1.8,
    };
    
    double multiplier = durationMultipliers[_selectedDuration] ?? 1.0;
    return basePrice * multiplier;
  }

  @override
  void initState() {
    super.initState();
    
    // Controller'ları dinamik değerlerle başlat
    _firstNameController = TextEditingController(text: _firstName);
    _lastNameController = TextEditingController(text: _lastName);
    
    // Preselected değer listede varsa kullan, yoksa ilk elemanı kullan
    if (widget.preselectedTreatment != null && _services.contains(widget.preselectedTreatment)) {
      _selectedService = widget.preselectedTreatment;
    } else {
      _selectedService = _services.first;
    }
    
    // Duration için de aynı kontrol
    if (widget.preselectedDuration != null) {
      // "60 minutes" -> "60 dakika" dönüşümü
      String convertedDuration = widget.preselectedDuration!
          .replaceAll('minutes', 'dakika')
          .replaceAll(' dakika', ' dakika');
      if (_durations.contains(convertedDuration)) {
        _selectedDuration = convertedDuration;
      } else if (_durations.contains(widget.preselectedDuration)) {
        _selectedDuration = widget.preselectedDuration;
      } else {
        _selectedDuration = '60 dakika';
      }
    } else {
      _selectedDuration = '60 dakika';
    }
    
    _selectedTime = _timeSlots[0];
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _roomNumberController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Book Spa Treatment',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hizmet Seçimi Section
                  _buildSectionCard(
                    title: 'Hizmet Seçimi',
                    children: [
                      _buildDropdownField(
                        label: 'Service',
                        value: _selectedService,
                        items: _services,
                        onChanged: (val) => setState(() => _selectedService = val),
                      ),
                      const SizedBox(height: 16),
                      _buildDropdownField(
                        label: 'Duration',
                        value: _selectedDuration,
                        items: _durations,
                        onChanged: (val) => setState(() => _selectedDuration = val),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Tarih ve Saat Seçimi
                  _buildSectionCard(
                    title: 'Tarih ve Saat Seçimi',
                    children: [
                      _buildCalendar(),
                      const SizedBox(height: 16),
                      _buildTimeSlots(),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Terapist Seçimi
                  _buildSectionCard(
                    title: 'Terapist Seçimi (Optional)',
                    children: [
                      _buildDropdownField(
                        label: '',
                        value: _selectedTherapist,
                        items: _therapists,
                        onChanged: (val) => setState(() => _selectedTherapist = val ?? _therapists.first),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // İletişim ve Oda Bilgisi
                  _buildSectionCard(
                    title: 'İletişim ve Oda Bilgisi',
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              label: 'Name',
                              controller: _firstNameController,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildTextField(
                              label: 'Surname',
                              controller: _lastNameController,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        label: 'Room Number',
                        controller: _roomNumberController,
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Özel Notlar
                  _buildSectionCard(
                    title: 'Özel Notlar',
                    children: [
                      TextField(
                        controller: _notesController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: 'Please mention any health conditions, allergies, or preferences (e.g., Hamilelik).',
                          hintStyle: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 14,
                          ),
                          filled: true,
                          fillColor: Colors.grey[100],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.all(16),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Onay ve İptal Politikası
                  _buildPolicySection(),
                  
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
          
          // Bottom Bar
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty) ...[
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
        ],
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey[600]),
              items: items.map((item) {
                return DropdownMenuItem(
                  value: item,
                  child: Text(
                    item,
                    style: const TextStyle(fontSize: 14),
                  ),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey[100],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          style: const TextStyle(fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildCalendar() {
    final now = DateTime.now();
    final firstDayOfMonth = DateTime(now.year, now.month, 1);
    final lastDayOfMonth = DateTime(now.year, now.month + 1, 0);
    final daysInMonth = lastDayOfMonth.day;
    final firstWeekday = firstDayOfMonth.weekday;

    return Column(
      children: [
        // Month Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left, size: 20),
              onPressed: () {},
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            Text(
              _getMonthName(now.month) + ' ${now.year}',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right, size: 20),
              onPressed: () {},
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        // Weekday Headers
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'].map((day) {
            return SizedBox(
              width: 36,
              child: Text(
                day,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
        
        // Calendar Grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            childAspectRatio: 1,
          ),
          itemCount: 42,
          itemBuilder: (context, index) {
            final dayOffset = index - (firstWeekday - 1);
            if (dayOffset < 1 || dayOffset > daysInMonth) {
              return const SizedBox();
            }
            
            final date = DateTime(now.year, now.month, dayOffset);
            final isSelected = _selectedDate.day == dayOffset &&
                _selectedDate.month == now.month;
            final isToday = now.day == dayOffset;
            final isPast = date.isBefore(DateTime(now.year, now.month, now.day));
            
            return GestureDetector(
              onTap: isPast ? null : () {
                setState(() {
                  _selectedDate = date;
                });
              },
              child: Container(
                margin: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: isSelected 
                      ? const Color(0xFF1E88E5) 
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: isToday && !isSelected
                      ? Border.all(color: const Color(0xFF1E88E5), width: 1)
                      : null,
                ),
                child: Center(
                  child: Text(
                    '$dayOffset',
                    style: TextStyle(
                      fontSize: 13,
                      color: isSelected 
                          ? Colors.white 
                          : isPast 
                              ? Colors.grey[400]
                              : Colors.black87,
                      fontWeight: isSelected || isToday 
                          ? FontWeight.w600 
                          : FontWeight.normal,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }

  Widget _buildTimeSlots() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _timeSlots.map((time) {
        final isSelected = _selectedTime == time;
        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedTime = time;
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF1E88E5) : Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected ? const Color(0xFF1E88E5) : Colors.grey[300]!,
              ),
            ),
            child: Text(
              time,
              style: TextStyle(
                fontSize: 13,
                color: isSelected ? Colors.white : Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPolicySection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Onay ve İptal Politikası',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          _buildPolicyItem('Spa Opening Hours: 09:00 - 20:00'),
          _buildPolicyItem('Please arrive 15 minutes prior to your appointment.'),
          _buildPolicyItem('Cancellation must be made at least 4 hours in advance to avoid a 50% charge.'),
          _buildPolicyItem('No-shows will be charged the full price of the treatment.'),
        ],
      ),
    );
  }

  Widget _buildPolicyItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6),
            width: 5,
            height: 5,
            decoration: const BoxDecoration(
              color: Color(0xFF1E88E5),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[700],
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Total Price',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  '\$${_totalPrice.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 24),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  _showConfirmationDialog();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E88E5),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Confirm Booking',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showConfirmationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green[50],
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.check, color: Colors.green[600], size: 24),
            ),
            const SizedBox(width: 12),
            const Text('Rezervasyon Onaylandı'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Spa randevunuz başarıyla oluşturuldu!',
              style: TextStyle(color: Colors.grey[700]),
            ),
            const SizedBox(height: 16),
            _buildConfirmationRow('Hizmet', _selectedService ?? ''),
            _buildConfirmationRow('Tarih', '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}'),
            _buildConfirmationRow('Saat', _selectedTime ?? ''),
            _buildConfirmationRow('Süre', _selectedDuration ?? ''),
            _buildConfirmationRow('Toplam', '\$${_totalPrice.toStringAsFixed(2)}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              // SpendingData'ya spa siparişini ekle
              SpendingData.addSpaOrder(
                '${_selectedService} - ${_selectedDuration}',
                _totalPrice,
              );
              
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back to previous screen
            },
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmationRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 13,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
