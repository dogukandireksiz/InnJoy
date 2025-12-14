import 'package:flutter/material.dart';
import 'spa_admin_placeholder_screen.dart';

class SpaEditServiceScreen extends StatefulWidget {
  final SpaServiceItem item;
  const SpaEditServiceScreen({super.key, required this.item});

  @override
  State<SpaEditServiceScreen> createState() => _SpaEditServiceScreenState();
}

class _SpaEditServiceScreenState extends State<SpaEditServiceScreen> {
  late TextEditingController _nameCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _durationCtrl;
  late TextEditingController _priceCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.item.title);
    _descCtrl = TextEditingController(text:
        'Rahatlatıcı ve klasik bir masaj deneyimi sunan İsveç masajı, kas gerginliğini azaltmak ve kan dolaşımını hızlandırmak için idealdir.');
    _durationCtrl = TextEditingController(text: widget.item.duration.replaceAll(' min', ''));
    _priceCtrl = TextEditingController(text: widget.item.priceRange.replaceAll(RegExp(r'[^0-9]'), ''));
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _durationCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        title: const Text('Hizmet Düzenle'),
        centerTitle: true,
        backgroundColor: const Color(0xFFF6F7FB),
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _ImageHeader(imageAsset: widget.item.imageAsset, onChange: () {}),
          const SizedBox(height: 16),
          const Text('Hizmet Adı'),
          const SizedBox(height: 6),
          _Input(textCtrl: _nameCtrl, hint: 'İsveç Masajı'),
          const SizedBox(height: 12),
          const Text('Açıklama'),
          const SizedBox(height: 6),
          _Multiline(textCtrl: _descCtrl),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _LabeledNumber(
                  label: 'Süre (dk)',
                  controller: _durationCtrl,
                  icon: Icons.timer,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _LabeledNumber(
                  label: 'Fiyat (₺)',
                  controller: _priceCtrl,
                  icon: Icons.attach_money,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                // TODO: Save changes to backend
                Navigator.pop(context);
              },
              child: const Text('Kaydet', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: () {
              // TODO: Delete service
            },
            icon: const Icon(Icons.delete, color: Colors.red),
            label: const Text('Hizmeti Sil', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _ImageHeader extends StatelessWidget {
  final String imageAsset;
  final VoidCallback onChange;
  const _ImageHeader({required this.imageAsset, required this.onChange});

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
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.asset(imageAsset, fit: BoxFit.cover),
              ),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: onChange,
              icon: const Icon(Icons.camera_alt, size: 18),
              label: const Text('Görseli Değiştir'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Input extends StatelessWidget {
  final TextEditingController textCtrl;
  final String hint;
  const _Input({required this.textCtrl, required this.hint});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: textCtrl,
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
  final TextEditingController textCtrl;
  const _Multiline({required this.textCtrl});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: textCtrl,
      maxLines: 4,
      decoration: InputDecoration(
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

class _LabeledNumber extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final IconData icon;
  const _LabeledNumber({required this.label, required this.controller, required this.icon});

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
