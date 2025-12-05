import 'package:flutter/material.dart';
import '../../service/database_service.dart'; // Servis importu

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
  bool _isLoading = false;   // Yükleniyor durumu için

  final List<String> _timeRanges = [
    '08:00 - 10:00',
    '10:00 - 12:00',
    '12:00 - 14:00',
    '14:00 - 16:00',
    '16:00 - 18:00',
    '18:00 - 20:00',
  ];

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
    detailsBuffer.writeln("Zamanlama: ${_selectedTimeType == 0 ? 'Hemen' : _selectedTimeRange}");
    
    if (_doNotDisturb) {
      detailsBuffer.writeln("DURUM: RAHATSIZ ETMEYİN");
    }

    if (_extraTowelCount > 0) detailsBuffer.writeln("Ekstra Havlu: $_extraTowelCount");
    if (_pillowCount > 0) detailsBuffer.writeln("Yastık: $_pillowCount");
    if (_blanketCount > 0) detailsBuffer.writeln("Battaniye: $_blanketCount");
    
    // Kullanıcı notunu da ekle
    if (_notesController.text.isNotEmpty) {
      detailsBuffer.writeln("\nKullanıcı Notu: ${_notesController.text}");
    }

    try {
      // 2. Servisi Çağır (Kategori otomatik olarak 'Housekeeping')
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
        const SnackBar(content: Text("Talebiniz başarıyla iletildi."), backgroundColor: Colors.green),
      );

    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Hata oluştu: $e"), backgroundColor: Colors.red),
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
        title: const Text(
          'Housekeeping Request',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600, fontSize: 18),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Rahatsız Etmeyin Toggle
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
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
                        const Text(
                          'Rahatsız Etmeyin',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Aşağıya gizlilik notu eklenecektir.',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _doNotDisturb,
                    onChanged: (value) {
                      setState(() {
                        _doNotDisturb = value;
                      });
                    },
                    activeColor: const Color(0xFF1677FF),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Temizlik Talebi
            const Text(
              'Temizlik Talebi',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            
            // Zaman Seçimi Chips
            Row(
              children: [
                _TimeChip(
                  label: 'Hemen Temizle',
                  isSelected: _selectedTimeType == 0,
                  onTap: () => setState(() => _selectedTimeType = 0),
                ),
                const SizedBox(width: 12),
                _TimeChip(
                  label: 'Belirli Saat Aralığında',
                  isSelected: _selectedTimeType == 1,
                  onTap: () => setState(() => _selectedTimeType = 1),
                ),
              ],
            ),
            
            // Saat Seçimi (sadece Belirli Saat Aralığında seçiliyse)
            if (_selectedTimeType == 1) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Saat Seçin',
                      style: TextStyle(
                        color: Colors.black54,
                        fontSize: 15,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _showTimeRangePicker(),
                      child: Row(
                        children: [
                          Text(
                            _selectedTimeRange,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(Icons.keyboard_arrow_down, color: Colors.grey[600]),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            const SizedBox(height: 24),
            
            // Malzeme ve Ekstra Talepler
            const Text(
              'Malzeme ve Ekstra Talepler',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            
            _MaterialRequestItem(
              icon: Icons.dry_cleaning,
              label: 'Ekstra Havlu',
              count: _extraTowelCount,
              onDecrement: () {
                if (_extraTowelCount > 0) {
                  setState(() => _extraTowelCount--);
                }
              },
              onIncrement: () => setState(() => _extraTowelCount++),
            ),
            const SizedBox(height: 12),
            
            _MaterialRequestItem(
              icon: Icons.bed,
              label: 'Yastık',
              count: _pillowCount,
              onDecrement: () {
                if (_pillowCount > 0) {
                  setState(() => _pillowCount--);
                }
              },
              onIncrement: () => setState(() => _pillowCount++),
            ),
            const SizedBox(height: 12),
            
            _MaterialRequestItem(
              icon: Icons.nights_stay,
              label: 'Battaniye',
              count: _blanketCount,
              onDecrement: () {
                if (_blanketCount > 0) {
                  setState(() => _blanketCount--);
                }
              },
              onIncrement: () => setState(() => _blanketCount++),
            ),
            
            const SizedBox(height: 24),
            
            // Özel İstekler ve Şikayet
            const Text(
              'Özel İstekler ve Şikayet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: TextField(
                controller: _notesController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Lütfen özel isteklerinizi veya notlarınızı buraya yazın...',
                  hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Talep Takibi
            const Text(
              'Talep Takibi',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _requestSent ? const Color(0xFFE8F5E9) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _requestSent ? const Color(0xFF4CAF50) : Colors.grey[300]!,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _requestSent ? const Color(0xFF4CAF50) : Colors.grey[200],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      _requestSent ? Icons.check : Icons.hourglass_empty,
                      color: _requestSent ? Colors.white : Colors.grey[500],
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _requestSent ? 'Talebiniz Gönderildi' : 'Bekliyor',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            color: _requestSent ? const Color(0xFF2E7D32) : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _requestSent
                              ? 'Ekibimiz en kısa sürede ilgilenecektir.'
                              : 'Talebinizi göndermek için aşağıdaki butona tıklayın.',
                          style: TextStyle(
                            color: _requestSent ? const Color(0xFF388E3C) : Colors.grey[600],
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
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
              color: Colors.black.withOpacity(0.05),
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
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: _isLoading 
              ? const SizedBox(
                  height: 20, width: 20, 
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                )
              : Text(
                  _requestSent ? 'Talep Gönderildi' : 'Talep Gönder',
                  style: TextStyle(
                    color: _requestSent ? Colors.grey[600] : Colors.white,
                    fontSize: 16,
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
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Saat Aralığı Seçin',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
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
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    color: isSelected ? const Color(0xFF1677FF) : Colors.black87,
                  ),
                ),
                trailing: isSelected
                    ? const Icon(Icons.check, color: Color(0xFF1677FF))
                    : null,
              );
            }),
            const SizedBox(height: 16),
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE3F2FD) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF1677FF) : Colors.grey[300]!,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? const Color(0xFF1677FF) : Colors.black87,
            fontWeight: FontWeight.w500,
            fontSize: 14,
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFE3F2FD),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xFF1677FF), size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 15,
              ),
            ),
          ),
          // Counter
          Row(
            children: [
              GestureDetector(
                onTap: onDecrement,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.remove, size: 18, color: Colors.black54),
                ),
              ),
              SizedBox(
                width: 40,
                child: Text(
                  count.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
              GestureDetector(
                onTap: onIncrement,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1677FF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.add, size: 18, color: Colors.white),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}