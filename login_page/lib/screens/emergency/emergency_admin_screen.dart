import 'package:flutter/material.dart';

class EmergencyAdminScreen extends StatefulWidget {
  const EmergencyAdminScreen({super.key});

  @override
  State<EmergencyAdminScreen> createState() => _EmergencyAdminScreenState();
}

class _EmergencyAdminScreenState extends State<EmergencyAdminScreen> {
  String _activeFilter = 'Tümü';

  final List<_EmergencyItem> _items = const [
    _EmergencyItem(title: 'Yangın', place: 'Oda 508', person: 'Ali Veli', minutesAgo: 5, category: 'Yangın', status: 'İşleniyor'),
    _EmergencyItem(title: 'Su Baskını', place: 'Spa Merkezi', person: 'Canan Güler', minutesAgo: 8, category: 'Deprem', status: 'İşleniyor'),
    _EmergencyItem(title: 'Tıbbi Yardım', place: 'Lobi', person: 'Ayşe Yılmaz', minutesAgo: 12, category: 'Tıbbi', status: 'Bekliyor'),
    _EmergencyItem(title: 'Güvenlik', place: 'Restoran', person: 'Mehmet Kaya', minutesAgo: 28, category: 'Güvenlik', status: 'Bekliyor'),
    _EmergencyItem(title: 'Yangın', place: 'Oda 201', person: 'Fatma Öztürk', minutesAgo: 120, category: 'Yangın', status: 'Çözüldü'),
    _EmergencyItem(title: 'Diğer', place: 'Havuz', person: 'Zeynep Demir', minutesAgo: 240, category: 'Diğer', status: 'Çözüldü'),
  ];

  int get _activeCount => _items.where((e) => e.status == 'İşleniyor' || e.status == 'Bekliyor').length;

  List<_EmergencyItem> get _visibleItems {
    if (_activeFilter == 'Tümü') return _items;
    return _items.where((e) => e.category == _activeFilter).toList();
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'İşleniyor':
        return const Color(0xFFFACC15); // amber
      case 'Bekliyor':
        return const Color(0xFF94A3B8); // slate
      case 'Çözüldü':
        return const Color(0xFF22C55E); // green
      default:
        return Colors.grey;
    }
  }

  IconData _categoryIcon(String category) {
    switch (category) {
      case 'Yangın':
        return Icons.local_fire_department;
      case 'Deprem':
        return Icons.waves;
      case 'Tıbbi':
        return Icons.medical_services;
      case 'Güvenlik':
        return Icons.shield;
      default:
        return Icons.ac_unit;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('Acil Durumlar'),
        centerTitle: true,
        backgroundColor: const Color(0xFF121212),
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('Acil Durumlar', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                      SizedBox(height: 6),
                      Text('Otel genelindeki acil durumları yönetin', style: TextStyle(color: Colors.white70)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFACC15).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFFACC15).withOpacity(0.6)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.flash_on, color: Color(0xFFFACC15), size: 18),
                      const SizedBox(width: 6),
                      Text('$_activeCount Aktif', style: const TextStyle(color: Color(0xFFFACC15), fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _FilterChip(
                  label: 'Tümü',
                  selected: _activeFilter == 'Tümü',
                  onTap: () => setState(() => _activeFilter = 'Tümü'),
                ),
                _FilterChip(label: 'Yangın', selected: _activeFilter == 'Yangın', onTap: () => setState(() => _activeFilter = 'Yangın')),
                _FilterChip(label: 'Deprem', selected: _activeFilter == 'Deprem', onTap: () => setState(() => _activeFilter = 'Deprem')),
                _FilterChip(label: 'Tıbbi', selected: _activeFilter == 'Tıbbi', onTap: () => setState(() => _activeFilter = 'Tıbbi')),
                _FilterChip(label: 'Güvenlik', selected: _activeFilter == 'Güvenlik', onTap: () => setState(() => _activeFilter = 'Güvenlik')),
                _FilterChip(label: 'Diğer', selected: _activeFilter == 'Diğer', onTap: () => setState(() => _activeFilter = 'Diğer')),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              itemCount: _visibleItems.length,
              itemBuilder: (ctx, i) {
                final item = _visibleItems[i];
                return _EmergencyCard(
                  icon: _categoryIcon(item.category),
                  title: item.title,
                  place: item.place,
                  person: item.person,
                  minutesAgo: item.minutesAgo,
                  status: item.status,
                  statusColor: _statusColor(item.status),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;
  const _FilterChip({required this.label, this.selected = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? Colors.white.withOpacity(0.12) : const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? Colors.white24 : Colors.white10),
        ),
        child: Text(
          label,
          style: TextStyle(color: selected ? Colors.white : Colors.white70, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

class _EmergencyCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String place;
  final String person;
  final int minutesAgo;
  final String status;
  final Color statusColor;

  const _EmergencyCard({
    required this.icon,
    required this.title,
    required this.place,
    required this.person,
    required this.minutesAgo,
    required this.status,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: status == 'İşleniyor' ? const Color(0xFFFACC15).withOpacity(0.4) : Colors.white10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.08), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: Colors.white70, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: statusColor.withOpacity(0.18), borderRadius: BorderRadius.circular(8), border: Border.all(color: statusColor.withOpacity(0.6))),
                      child: Text(status, style: TextStyle(color: statusColor, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text('$place  •  $person', style: const TextStyle(color: Colors.white70)),
                const SizedBox(height: 6),
                Text('${minutesAgo} dakika önce', style: const TextStyle(color: Colors.white38, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmergencyItem {
  final String title;
  final String place;
  final String person;
  final int minutesAgo;
  final String category;
  final String status;
  const _EmergencyItem({
    required this.title,
    required this.place,
    required this.person,
    required this.minutesAgo,
    required this.category,
    required this.status,
  });
}
