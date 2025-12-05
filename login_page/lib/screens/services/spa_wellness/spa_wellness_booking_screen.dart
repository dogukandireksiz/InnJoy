import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../payment/payment_screen.dart';
import '../../../../service/database_service.dart';

class SpaWellnessBookingScreen extends StatefulWidget {


  const SpaWellnessBookingScreen({
    super.key,

  });

  @override
  State<SpaWellnessBookingScreen> createState() => _SpaWellnessBookingScreenState();
}

class _SpaWellnessBookingScreenState extends State<SpaWellnessBookingScreen> {
  // Firebase user
  String _selectedService = 'Masaj Terapisi';
  String _selectedDuration = '60 dk';
  double _totalPrice = 1200.0;
  bool _isLoading = false;

  final Map<String, double> _services = {
    'Masaj Terapisi': 1200.0,
    'Cilt Bakımı': 850.0,
    'Sauna & Buhar': 400.0,
    'Aroma Terapi': 1500.0,
  };

  final List<String> _durations = ['30 dk', '60 dk', '90 dk'];

  // Fiyat hesaplama
  void _updatePrice() {
    double basePrice = _services[_selectedService] ?? 0;
    if (_selectedDuration == '30 dk') basePrice *= 0.6;
    if (_selectedDuration == '90 dk') basePrice *= 1.4;
    setState(() {
      _totalPrice = basePrice;
    });
  }

  // --- RANDEVU OLUŞTURMA FONKSİYONU ---
  Future<void> _bookSpa() async {
    setState(() => _isLoading = true);

    try {
      // BURASI DÜZELDİ: Artık SpendingData yerine DatabaseService kullanıyoruz
      await DatabaseService().bookSpaAppointment(
        _selectedService,
        _selectedDuration,
        _totalPrice,
      );

      if (!mounted) return;

      // Başarılı Dialogu
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Text("Randevu Onaylandı"),
          content: Text(
            "$_selectedService ($_selectedDuration) randevunuz oluşturuldu.\n\nTutar: ${_totalPrice.toStringAsFixed(2)} ₺ hesabınıza işlendi.",
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx); // Dialog kapa
                Navigator.pop(context); // Ekrandan çık
              },
              child: const Text("Tamam"),
            )
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Hata: $e")),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
                  const Text("Hizmet Seçin:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  DropdownButton<String>(
                    value: _selectedService,
                    isExpanded: true,
                    items: _services.keys.map((String key) {
                      return DropdownMenuItem(value: key, child: Text(key));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _selectedService = val);
                        _updatePrice();
                      }
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                    const Text("Süre Seçin:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Row(
                      children: _durations.map((d) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: ChoiceChip(
                            label: Text(d),
                            selected: _selectedDuration == d,
                            onSelected: (selected) {
                              if (selected) {
                                setState(() => _selectedDuration = d);
                                _updatePrice();
                              }
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  
                  const SizedBox(height: 16),
                  
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Toplam Tutar:", style: TextStyle(fontSize: 18)),
                        Text(
                          "${_totalPrice.toStringAsFixed(2)} ₺",
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.blue),
                        ),
                      ],
                    ),
                  ),
                        
                  const SizedBox(height: 16),
                  
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _bookSpa,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                      child: _isLoading 
                        ? const CircularProgressIndicator(color: Colors.white) 
                        : const Text("Randevuyu Onayla ve Hesaba İşle", style: TextStyle(fontSize: 16, color: Colors.white)),
                    ),
                  ),
                  
                ],
              ),
            ),
          ),
          
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


  String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
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
