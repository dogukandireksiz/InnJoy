import 'package:flutter/material.dart';
import 'package:login_page/l10n/app_localizations.dart'; // Çeviri paketi
import 'dining/dining_pricelist_screen.dart';
import 'dining/dining_booking_screen.dart';
import 'spa_wellness/spa_wellness_pricelist_screen.dart';
import 'spa_wellness/spa_wellness_booking_screen.dart';

class ServiceScreen extends StatefulWidget {
  const ServiceScreen({super.key});

  @override
  State<ServiceScreen> createState() => _ServiceScreenState();
}

class _ServiceScreenState extends State<ServiceScreen> {
  final TextEditingController _searchController = TextEditingController();
  String? _selectedCategory;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Servis listesini build içinde oluşturuyoruz ki dil değişince güncellensin
  List<_ServiceItem> _getServices(AppLocalizations texts) {
    return [
      _ServiceItem(
        title: 'The Azure Restaurant',
        description: texts.azureDesc,
        imagePath: 'assets/images/arkaplan.jpg',
        badgeText: texts.reservationsRecommended,
        category: 'Dining',
        primaryAction: texts.seePricelist,
        secondaryAction: texts.bookTreatment,
      ),
      _ServiceItem(
        title: 'Serenity Spa',
        description: texts.serenitySpaDesc,
        imagePath: 'assets/images/arkaplanyok1.png',
        badgeText: texts.appointmentsOnly,
        category: 'Spa & Wellness',
        primaryAction: texts.seePricelist,
        secondaryAction: texts.bookTreatment,
      ),
      _ServiceItem(
        title: '24/7 Fitness Center',
        description: texts.fitnessDesc,
        imagePath: 'assets/images/arkaplanyok.png',
        badgeText: texts.open24Hours,
        category: 'Fitness',
        primaryAction: texts.viewClasses,
        secondaryAction: null,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final texts = AppLocalizations.of(context)!;
    final allServices = _getServices(texts);

    // Kategori isimlerini çeviriyoruz
    final categoryMap = {
      'Dining': texts.dining,
      'Spa & Wellness': texts.spaWellness,
      'Fitness': texts.fitness,
      'Recreation': texts.recreation,
    };

    final q = _searchController.text.trim().toLowerCase();

    final filteredServices = allServices.where((s) {
      // Kategori kontrolü (İngilizce key üzerinden yapıyoruz)
      final matchesCategory =
          _selectedCategory == null || s.category == _selectedCategory;
      if (!matchesCategory) return false;

      if (q.isEmpty) return true;
      return s.title.toLowerCase().contains(q) ||
          s.description.toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      appBar: AppBar(title: Text(texts.ourServices), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SearchBar(
            controller: _searchController,
            hintText: texts.searchServices,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          _CategoryChips(
            selected: _selectedCategory,
            categoryMap: categoryMap,
            onSelected: (key) => setState(() => _selectedCategory = key),
          ),
          const SizedBox(height: 16),
          for (final s in filteredServices) ...[
            _ServiceCard(
              title: s.title,
              badgeText: s.badgeText,
              imagePath: s.imagePath,
              description: s.description,
              primaryAction: s.primaryAction,
              secondaryAction: s.secondaryAction,
              category: s.category,
              onPrimaryAction: () {
                if (s.category == 'Dining' &&
                    s.primaryAction == texts.seePricelist) {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => DiningPricelistScreen(venueName: s.title),
                    ),
                  );
                } else if (s.category == 'Spa & Wellness' &&
                    s.primaryAction == texts.seePricelist) {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          SpaWellnessPricelistScreen(venueName: s.title),
                    ),
                  );
                }
              },
              onSecondaryAction: () {
                if (s.category == 'Dining' &&
                    s.secondaryAction == texts.bookTreatment) {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          DiningBookingScreen(preselectedVenue: s.title),
                    ),
                  );
                } else if (s.category == 'Spa & Wellness' &&
                    s.secondaryAction == texts.bookTreatment) {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const SpaWellnessBookingScreen(),
                    ),
                  );
                }
              },
            ),
            const SizedBox(height: 16),
          ],
          if (filteredServices.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Center(child: Text(texts.noServicesFound)),
            ),
        ],
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final String hintText;
  const _SearchBar({this.controller, this.onChanged, required this.hintText});
  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hintText,
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
  final Map<String, String> categoryMap;

  const _CategoryChips({
    required this.selected,
    required this.onSelected,
    required this.categoryMap,
  });

  @override
  Widget build(BuildContext context) {
    // Key'leri (Dining, Spa vs.) kullanıyoruz ama ekranda Value'ları (Yeme İçme, Spa vs.) gösteriyoruz
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final entry in categoryMap.entries) ...[
            ChoiceChip(
              label: Text(entry.value), // Çevrilmiş metin
              selected: selected == entry.key,
              onSelected: (isSelected) =>
                  onSelected(selected == entry.key ? null : entry.key),
            ),
            const SizedBox(width: 8),
          ],
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
  final String? category;
  final VoidCallback? onPrimaryAction;
  final VoidCallback? onSecondaryAction;

  const _ServiceCard({
    required this.title,
    required this.description,
    required this.imagePath,
    required this.badgeText,
    this.primaryAction,
    this.secondaryAction,
    this.category,
    this.onPrimaryAction,
    this.onSecondaryAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color.fromRGBO(0, 0, 0, 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Image.asset(
            imagePath,
            height: 160,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
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
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Text(
                        badgeText,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.green,
                        ),
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
                          onPressed: onPrimaryAction,
                          child: Text(primaryAction!),
                        ),
                      ),
                    if (secondaryAction != null) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: onSecondaryAction,
                          child: Text(secondaryAction!),
                        ),
                      ),
                    ],
                  ],
                ),
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
