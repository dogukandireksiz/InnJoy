import 'package:flutter/material.dart';

class FitnessEditServiceScreen extends StatefulWidget {
  final String title;
  final String subtitle;
  final String imageAsset;
  const FitnessEditServiceScreen({super.key, required this.title, required this.subtitle, required this.imageAsset});

  @override
  State<FitnessEditServiceScreen> createState() => _FitnessEditServiceScreenState();
}

class _FitnessEditServiceScreenState extends State<FitnessEditServiceScreen> {
  late TextEditingController _nameCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _scheduleCtrl;
  late TextEditingController _capacityCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.title);
    _descCtrl = TextEditingController(text: '24 saat açık modern spor salonu, en son teknoloji kardiyo ve ağırlık ekipmanları ile misafirlerimizin hizmetindedir.');
    _scheduleCtrl = TextEditingController(text: widget.subtitle);
    _capacityCtrl = TextEditingController(text: '25');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _scheduleCtrl.dispose();
    _capacityCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        title: const Text('Hizmeti Düzenle'),
        centerTitle: true,
        backgroundColor: const Color(0xFFF6F7FB),
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _ImageHeader(imageAsset: widget.imageAsset, onChange: () {}),
          const SizedBox(height: 16),
          const Text('Hizmet Adı'),
          const SizedBox(height: 6),
          _Input(textCtrl: _nameCtrl, hint: 'Gym Access'),
          const SizedBox(height: 12),
          const Text('Açıklama'),
          const SizedBox(height: 6),
          _Multiline(textCtrl: _descCtrl),
          const SizedBox(height: 12),
          const Text('Çalışma Saatleri'),
          const SizedBox(height: 6),
          _Input(textCtrl: _scheduleCtrl, hint: 'Her Gün 06:00 - 22:00'),
          const SizedBox(height: 12),
          const Text('Kapasite'),
          const SizedBox(height: 6),
          _Number(textCtrl: _capacityCtrl, icon: Icons.group),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('İptal'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {
                    // TODO: Save changes
                    Navigator.pop(context);
                  },
                  child: const Text('Kaydet', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: () {
              // TODO: Delete service
            },
            icon: const Icon(Icons.delete, color: Colors.red),
            label: const Text('Bu Hizmeti Sil', style: TextStyle(color: Colors.red)),
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

class _Number extends StatelessWidget {
  final TextEditingController textCtrl;
  final IconData icon;
  const _Number({required this.textCtrl, required this.icon});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: textCtrl,
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
    );
  }
}
