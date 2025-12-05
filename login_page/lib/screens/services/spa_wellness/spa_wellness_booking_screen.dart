import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:login_page/l10n/app_localizations.dart'; // Çeviri
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
  State<SpaWellnessBookingScreen> createState() =>
      _SpaWellnessBookingScreenState();
}

class _SpaWellnessBookingScreenState extends State<SpaWellnessBookingScreen> {
  final user = FirebaseAuth.instance.currentUser;
  String? _selectedService;
  String? _selectedDuration;
  DateTime _selectedDate = DateTime.now();
  String? _selectedTime;
  String _selectedTherapist = 'Any Available Therapist';
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  final _roomNumberController = TextEditingController(text: '1204');
  final _notesController = TextEditingController();

  String get _firstName {
    if (user?.displayName != null && user!.displayName!.isNotEmpty)
      return user!.displayName!.split(' ').first;
    if (user?.email != null) return user!.email!.split('@').first;
    return '';
  }

  String get _lastName {
    if (user?.displayName != null && user!.displayName!.isNotEmpty) {
      final parts = user!.displayName!.split(' ');
      if (parts.length > 1) return parts.sublist(1).join(' ');
    }
    return '';
  }

  final List<String> _services = [
    'Aromaterapi Masajı',
    'İsveç Masajı',
    'Derin Doku Masajı',
  ]; // Kısaltıldı
  final List<String> _durations = [
    '30 dakika',
    '45 dakika',
    '60 dakika',
    '90 dakika',
  ];
  final List<String> _timeSlots = ['09:00', '10:00', '11:00', '13:00', '15:00'];

  // Terapist listesi sabit kalabilir veya çevrilebilir
  final List<String> _therapists = [
    'Any Available Therapist',
    'Maria S.',
    'John D.',
  ];

  double get _totalPrice {
    if (widget.preselectedPrice != null) return widget.preselectedPrice!;
    return 95.0; // Varsayılan basit hesap
  }

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController(text: _firstName);
    _lastNameController = TextEditingController(text: _lastName);
    _selectedService = widget.preselectedTreatment ?? _services.first;
    _selectedDuration = widget.preselectedDuration ?? '60 dakika';
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
    final texts = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          texts.bookTreatment,
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ), // texts.bookSpa = "Book Spa Treatment"
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildSectionCard(
                    title: texts.serviceSelection,
                    children: [
                      _buildDropdownField(
                        label: 'Service',
                        value: _selectedService,
                        items: _services,
                        onChanged: (val) =>
                            setState(() => _selectedService = val),
                      ),
                      const SizedBox(height: 16),
                      _buildDropdownField(
                        label: texts.duration,
                        value: _selectedDuration,
                        items: _durations,
                        onChanged: (val) =>
                            setState(() => _selectedDuration = val),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildSectionCard(
                    title: texts.dateTimeSelection,
                    children: [
                      _buildCalendar(),
                      const SizedBox(height: 16),
                      _buildTimeSlots(),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildSectionCard(
                    title: texts.therapistSelection,
                    children: [
                      _buildDropdownField(
                        label: '',
                        value: _selectedTherapist,
                        items: _therapists,
                        onChanged: (val) => setState(
                          () => _selectedTherapist = val ?? _therapists.first,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildSectionCard(
                    title: texts.contactRoomInfo,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              label: texts.name,
                              controller: _firstNameController,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildTextField(
                              label: texts.surname,
                              controller: _lastNameController,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        label: texts.roomNumber,
                        controller: _roomNumberController,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildSectionCard(
                    title: texts.specialNotes,
                    children: [
                      TextField(
                        controller: _notesController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: texts.specialNotesHint,
                          filled: true,
                          fillColor: Colors.grey[100],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildPolicySection(texts),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
          _buildBottomBar(texts),
        ],
      ),
    );
  }

  // ... (buildSectionCard, buildDropdownField, buildTextField, buildCalendar, buildTimeSlots AYNI KALACAK) ...
  // Sadece metin içeren yardımcı widget'ları aşağıya ekliyorum:

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
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  // Dropdown ve TextField yardımcıları aynı kalır...

  Widget _buildCalendar() {
    /* Takvim kodu aynı */
    return const Text("Calendar Placeholder");
  }

  Widget _buildTimeSlots() {
    /* Saat kodu aynı */
    return const Text("Time Slots");
  }

  Widget _buildDropdownField({
    required String label,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return const Text("Dropdown");
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
  }) {
    return const Text("TextField");
  }

  Widget _buildPolicySection(AppLocalizations texts) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            texts.policyTitle,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Text(
            'Spa Opening Hours: 09:00 - 20:00',
          ), // Bunları da ARB'ye ekleyebilirsin
        ],
      ),
    );
  }

  Widget _buildBottomBar(AppLocalizations texts) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(color: Colors.white),
      child: SafeArea(
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(texts.totalPrice),
                Text(
                  '\$${_totalPrice.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 24),
            Expanded(
              child: ElevatedButton(
                onPressed: () => _showConfirmationDialog(texts),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E88E5),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  texts.confirmBooking,
                  style: const TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showConfirmationDialog(AppLocalizations texts) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.check, color: Colors.green),
            const SizedBox(width: 12),
            Text(texts.bookingConfirmed),
          ],
        ),
        content: Text(texts.spaBookingSuccess),
        actions: [
          TextButton(
            onPressed: () {
              SpendingData.addSpaOrder('$_selectedService', _totalPrice);
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }
}
