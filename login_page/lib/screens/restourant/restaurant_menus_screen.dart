import 'package:flutter/material.dart';

class RestaurantMenusScreen extends StatefulWidget {
  const RestaurantMenusScreen({super.key});

  @override
  State<RestaurantMenusScreen> createState() => _RestaurantMenusScreenState();
}

class _RestaurantMenusScreenState extends State<RestaurantMenusScreen> {
  String _activeTab = 'Tüm Yemekler';
  String _activeFilter = 'Tümü';
  String _query = '';

  final List<_MenuItem> _items = const [
    _MenuItem(title: 'Serpme Kahvaltı', category: 'Kahvaltı', price: '₺350.00', status: 'Aktif'),
    _MenuItem(title: 'Izgara Köfte', category: 'Ana Yemek', price: '₺420.00', status: 'Aktif'),
    _MenuItem(title: 'Sezar Salata', category: 'Salata', price: '₺280.00', status: 'Taslak'),
    _MenuItem(title: 'San Sebastian Cheesecake', category: 'Tatlı', price: '₺190.00', status: 'Aktif'),
    // Weekly menu examples
    _MenuItem(title: 'Çorba (Haftalık)', category: 'Öğle', price: '₺90.00', status: 'Aktif', weekly: true),
    _MenuItem(title: 'Makarna (Haftalık)', category: 'Akşam', price: '₺150.00', status: 'Taslak', weekly: true),
  ];

  List<_MenuItem> get _visibleItems {
    // Filter by tab (all vs weekly)
    final tabFiltered = _activeTab == 'Haftanın Menüsü'
        ? _items.where((e) => e.weekly).toList()
        : _items.where((e) => !e.weekly).toList();

    // Filter by category chip
    final chipFiltered = _activeFilter == 'Tümü'
        ? tabFiltered
        : tabFiltered.where((e) => e.category == _activeFilter).toList();

    // Filter by text query
    final queryLower = _query.toLowerCase();
    final queryFiltered = _query.isEmpty
        ? chipFiltered
        : chipFiltered.where((e) => e.title.toLowerCase().contains(queryLower)).toList();

    return queryFiltered;
  }

  void _setTab(String tab) => setState(() => _activeTab = tab);
  void _setFilter(String filter) => setState(() => _activeFilter = filter);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        title: const Text('Menü Yönetimi'),
        centerTitle: true,
        backgroundColor: const Color(0xFFF6F7FB),
        elevation: 0,
        scrolledUnderElevation: 0,
        // Removed settings icon from the app bar
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            borderRadius: BorderRadius.circular(24),
                            onTap: () => _setTab('Tüm Yemekler'),
                            child: Center(
                              child: Text(
                                'Tüm Yemekler',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: _activeTab == 'Tüm Yemekler' ? Colors.black : Colors.black54,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: InkWell(
                            borderRadius: BorderRadius.circular(24),
                            onTap: () => _setTab('Haftanın Menüsü'),
                            child: Center(
                              child: Text(
                                'Haftanın Menüsü',
                                style: TextStyle(
                                  color: _activeTab == 'Haftanın Menüsü' ? Colors.black : Colors.black54,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  height: 44,
                  width: 44,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(22),
                    onTap: () async {
                      final result = await showDialog<String>(
                        context: context,
                        builder: (ctx) {
                          String localQuery = _query;
                          return AlertDialog(
                            title: const Text('Ara'),
                            content: TextField(
                              autofocus: true,
                              decoration: const InputDecoration(hintText: 'Yemek adı...'),
                              onChanged: (v) => localQuery = v,
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: const Text('İptal'),
                              ),
                              ElevatedButton(
                                onPressed: () => Navigator.pop(ctx, localQuery),
                                child: const Text('Uygula'),
                              ),
                            ],
                          );
                        },
                      );
                      if (result != null) {
                        setState(() => _query = result);
                      }
                    },
                    child: const Icon(Icons.search, color: Colors.black54),
                  ),
                ),
              ],
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _FilterChip(label: 'Tümü', selected: _activeFilter == 'Tümü', onTap: () => _setFilter('Tümü')),
                _FilterChip(label: 'Jll.', selected: _activeFilter == 'Jll.', onTap: () => _setFilter('Jll.')),
                _FilterChip(label: 'Kahvaltı', selected: _activeFilter == 'Kahvaltı', onTap: () => _setFilter('Kahvaltı')),
                _FilterChip(label: 'Öğle', selected: _activeFilter == 'Öğle', onTap: () => _setFilter('Öğle')),
                _FilterChip(label: 'Akşam', selected: _activeFilter == 'Akşam', onTap: () => _setFilter('Akşam')),
                _FilterChip(label: 'Tatlı', selected: _activeFilter == 'Tatlı', onTap: () => _setFilter('Tatlı')),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              physics: const BouncingScrollPhysics(),
              children: [
                for (final item in _visibleItems)
                  _MenuItemCard(
                    imageUrl: null,
                    fallbackColor: const Color(0xFFF8FAFC),
                    title: item.title,
                    category: item.category,
                    price: item.price,
                    statusLabel: item.status,
                    statusColor: item.status == 'Aktif' ? const Color(0xFF22C55E) : const Color(0xFF94A3B8),
                  ),
                if (_visibleItems.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Center(
                      child: Text('Sonuç bulunamadı'),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF2563EB),
        onPressed: () {
          // Placeholder action to verify interactivity
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Yeni menü öğesi ekle')),
          );
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class _MenuItem {
  final String title;
  final String category;
  final String price;
  final String status;
  final bool weekly;
  const _MenuItem({
    required this.title,
    required this.category,
    required this.price,
    required this.status,
    this.weekly = false,
  });
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;
  const _FilterChip({required this.label, this.selected = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? Colors.black : Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _MenuItemCard extends StatelessWidget {
  final String? imageUrl;
  final Color fallbackColor;
  final String title;
  final String category;
  final String price;
  final String statusLabel;
  final Color statusColor;
  const _MenuItemCard({
    required this.imageUrl,
    required this.fallbackColor,
    required this.title,
    required this.category,
    required this.price,
    required this.statusLabel,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              height: 64,
              width: 64,
              decoration: BoxDecoration(
                color: fallbackColor,
                borderRadius: BorderRadius.circular(12),
                image: imageUrl != null
                    ? DecorationImage(
                        image: NetworkImage(imageUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(category, style: const TextStyle(color: Colors.black54)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(price, style: const TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.w700)),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          statusLabel,
                          style: TextStyle(color: statusColor, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              children: [
                InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Sil: $title')),
                    );
                  },
                  child: const Icon(Icons.delete_outline, color: Colors.black38),
                ),
                const SizedBox(height: 10),
                InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Düzenle: $title')),
                    );
                  },
                  child: const Icon(Icons.edit_outlined, color: Color(0xFF2563EB)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
