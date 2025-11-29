import 'package:flutter/material.dart';

class ServiceScreen extends StatefulWidget {
  const ServiceScreen({super.key});

  @override
  State<ServiceScreen> createState() => _ServiceScreenState();
}

class _ServiceScreenState extends State<ServiceScreen> {
  final TextEditingController _searchController = TextEditingController();
  String? _selectedCategory; // null => show all services

  final List<_ServiceItem> _allServices = const [
    _ServiceItem(
      title: 'The Azure Restaurant',
      description:
          'Fine dining with a panoramic city view, featuring a modern European menu.',
      imagePath: 'assets/images/arkaplan.jpg',
      badgeText: 'Reservations Recommended',
      category: 'Dining',
      primaryAction: 'See Pricelist',
      secondaryAction: 'Book Treatment',
    ),
    _ServiceItem(
      title: 'Serenity Spa',
      description:
          'Indulge in our signature treatments and find your inner peace.',
      imagePath: 'assets/images/arkaplanyok1.png',
      badgeText: 'Appointments Only',
      category: 'Spa & Wellness',
      primaryAction: 'See Pricelist',
      secondaryAction: 'Book Treatment',
    ),
    _ServiceItem(
      title: '24/7 Fitness Center',
      description:
          'State-of-the-art equipment for all your fitness needs, anytime you need it.',
      imagePath: 'assets/images/arkaplanyok.png',
      badgeText: 'Open 24 Hours',
      category: 'Fitness',
      primaryAction: 'View Classes',
      secondaryAction: null,
    ),
  ];

  List<_ServiceItem> get _filteredServices {
    final q = _searchController.text.trim().toLowerCase();
    return _allServices.where((s) {
      final matchesCategory = _selectedCategory == null || s.category == _selectedCategory;
      if (!matchesCategory) return false;
      if (q.isEmpty) return true;
      return s.title.toLowerCase().contains(q) || s.description.toLowerCase().contains(q);
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Our Services'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SearchBar(controller: _searchController, onChanged: (_) => setState(() {})),
          const SizedBox(height: 12),
          _CategoryChips(
            selected: _selectedCategory,
            onSelected: (value) => setState(() => _selectedCategory = value),
          ),
          const SizedBox(height: 16),
          for (final s in _filteredServices) ...[
            _ServiceCard(
              title: s.title,
              badgeText: s.badgeText,
              imagePath: s.imagePath,
              description: s.description,
              primaryAction: s.primaryAction,
              secondaryAction: s.secondaryAction,
            ),
            const SizedBox(height: 16),
          ],
          if (_filteredServices.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Text('No services found for this category.'),
              ),
            ),
        ],
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  const _SearchBar({this.controller, this.onChanged});
  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: 'Search for services...',
        prefixIcon: const Icon(Icons.search),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class _CategoryChips extends StatelessWidget {
  final String? selected;
  final ValueChanged<String?> onSelected;
  const _CategoryChips({required this.selected, required this.onSelected});
  @override
  Widget build(BuildContext context) {
    final categories = [
      'Dining',
      'Spa & Wellness',
      'Fitness',
      'Recreation',
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final c in categories) ...[
            ChoiceChip(
              label: Text(c),
              selected: selected == c,
              onSelected: (isSelected) => onSelected(selected == c ? null : c),
            ),
            const SizedBox(width: 8),
          ]
        ],
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final String title;
  final String description;
  final String imagePath;
  final String badgeText;
  final String? primaryAction;
  final String? secondaryAction;

  const _ServiceCard({
    required this.title,
    required this.description,
    required this.imagePath,
    required this.badgeText,
    this.primaryAction,
    this.secondaryAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Image.asset(imagePath, height: 160, width: double.infinity, fit: BoxFit.cover),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Text(
                        badgeText,
                        style: const TextStyle(fontSize: 12, color: Colors.green),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: const TextStyle(color: Colors.black87),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    if (primaryAction != null)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {},
                          child: Text(primaryAction!),
                        ),
                      ),
                    if (secondaryAction != null) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {},
                          child: Text(secondaryAction!),
                        ),
                      ),
                    ],
                  ],
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ServiceItem {
  final String title;
  final String description;
  final String imagePath;
  final String badgeText;
  final String category;
  final String? primaryAction;
  final String? secondaryAction;
  const _ServiceItem({
    required this.title,
    required this.description,
    required this.imagePath,
    required this.badgeText,
    required this.category,
    this.primaryAction,
    this.secondaryAction,
  });
}
