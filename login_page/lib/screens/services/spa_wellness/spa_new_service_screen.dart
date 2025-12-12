import 'package:flutter/material.dart';

class SpaNewServiceScreen extends StatefulWidget {
  const SpaNewServiceScreen({super.key});

  @override
  State<SpaNewServiceScreen> createState() => _SpaNewServiceScreenState();
}

class _SpaNewServiceScreenState extends State<SpaNewServiceScreen> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  int _durationMinutes = 60;
  double _price = 0.0;

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        title: const Text('Yeni Spa Hizmeti'),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          )
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _Section(
            title: 'Hizmet Görseli',
            child: _ImagePickerPlaceholder(
              onTap: () {
                // TODO: open image picker
              },
            ),
          ),
          const SizedBox(height: 12),
          _Section(
            title: 'Hizmet Adı',
            child: TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                hintText: 'Örn: Aromaterapi Masajı',
                border: OutlineInputBorder(),
                filled: true,
              ),
            ),
          ),
          const SizedBox(height: 12),
          _Section(
            title: 'Açıklama',
            child: TextField(
              controller: _descController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Hizmet detaylarını buraya yazın...',
                border: OutlineInputBorder(),
                filled: true,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _Section(
                  title: 'Süre (dk)',
                  child: _StepperField(
                    valueText: _durationMinutes.toString(),
                    onMinus: () => setState(() {
                      if (_durationMinutes > 5) _durationMinutes -= 5;
                    }),
                    onPlus: () => setState(() {
                      _durationMinutes += 5;
                    }),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _Section(
                  title: 'Fiyat (₺)',
                  child: _StepperField(
                    valueText: _price.toStringAsFixed(2),
                    onMinus: () => setState(() {
                      _price = (_price - 5).clamp(0, double.infinity);
                    }),
                    onPlus: () => setState(() {
                      _price += 5;
                    }),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                // TODO: Save new service via DatabaseService
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0057FF),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text(
                'Hizmeti Ekle',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final Widget child;
  const _Section({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(12),
          child: child,
        ),
      ],
    );
  }
}

class _ImagePickerPlaceholder extends StatelessWidget {
  final VoidCallback onTap;
  const _ImagePickerPlaceholder({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 160,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid, width: 1.5),
          color: const Color(0xFFF9FAFB),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.camera_alt, size: 32, color: Colors.blue),
            SizedBox(height: 8),
            Text('Fotoğraf Ekle', style: TextStyle(fontWeight: FontWeight.w600)),
            SizedBox(height: 4),
            Text('PNG, JPG veya JPEG', style: TextStyle(color: Colors.black54)),
          ],
        ),
      ),
    );
  }
}

class _StepperField extends StatelessWidget {
  final String valueText;
  final VoidCallback onMinus;
  final VoidCallback onPlus;
  const _StepperField({required this.valueText, required this.onMinus, required this.onPlus});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _RoundButton(icon: Icons.remove, onTap: onMinus),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Text(valueText, style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
        ),
        const SizedBox(width: 10),
        _RoundButton(icon: Icons.add, onTap: onPlus),
      ],
    );
  }
}

class _RoundButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _RoundButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, size: 18),
        ),
      ),
    );
  }
}
