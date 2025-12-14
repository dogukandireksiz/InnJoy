import 'package:flutter/material.dart';

class FitnessNewServiceScreen extends StatefulWidget {
  const FitnessNewServiceScreen({super.key});

  @override
  State<FitnessNewServiceScreen> createState() => _FitnessNewServiceScreenState();
}

class _FitnessNewServiceScreenState extends State<FitnessNewServiceScreen> {
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _descCtrl = TextEditingController();
  final TextEditingController _durationCtrl = TextEditingController(text: '60');
  final TextEditingController _priceCtrl = TextEditingController(text: '250');
  final TextEditingController _capacityCtrl = TextEditingController(text: '10');

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _durationCtrl.dispose();
    _priceCtrl.dispose();
    _capacityCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        title: const Text('Yeni Hizmet Ekle'),
        centerTitle: true,
        backgroundColor: const Color(0xFFF6F7FB),
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _ImageUploader(),
          const SizedBox(height: 16),
          const Text('Hizmet Adı'),
          const SizedBox(height: 6),
          _Input(controller: _nameCtrl, hint: 'Örn: Pilates Dersi'),
          const SizedBox(height: 12),
          const Text('Açıklama'),
          const SizedBox(height: 6),
          _Multiline(controller: _descCtrl, hint: 'Hizmet hakkında kısa bilgi...'),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _NumberField(label: 'Süre (dk)', controller: _durationCtrl, icon: Icons.timer),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _NumberField(label: 'Fiyat (₺)', controller: _priceCtrl, icon: Icons.attach_money),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _NumberField(label: 'Kapasite (Kişi)', controller: _capacityCtrl, icon: Icons.group),
          const SizedBox(height: 16),
          SizedBox(
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Hizmeti Ekle', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(height: 10),
          Center(
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ImageUploader extends StatelessWidget {
  const _ImageUploader();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Hizmet Görseli'),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE0E6F5)),
              ),
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Column(
                children: [
                  const Icon(Icons.camera_alt, color: Colors.black38),
                  const SizedBox(height: 8),
                  const Text('Görsel Yükle', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  const Text('Fotoğraf çekin veya galeriden seçin', style: TextStyle(color: Colors.black54)),
                  const SizedBox(height: 10),
                  OutlinedButton(
                    onPressed: () {},
                    child: const Text('Görsel Seç'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Input extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  const _Input({required this.controller, required this.hint});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class _Multiline extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  const _Multiline({required this.controller, required this.hint});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: 4,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class _NumberField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final IconData icon;
  const _NumberField({required this.label, required this.controller, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            prefixIcon: Icon(icon),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }
}
