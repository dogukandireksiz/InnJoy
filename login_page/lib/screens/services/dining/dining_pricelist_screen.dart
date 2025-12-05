import 'package:flutter/material.dart';
import 'package:login_page/l10n/app_localizations.dart'; // Çeviri
import 'dining_booking_screen.dart';

class DiningMenuItem {
  final String name;
  final String description;
  final double price;
  final String? imagePath;
  const DiningMenuItem({
    required this.name,
    required this.description,
    required this.price,
    this.imagePath,
  });
}

class DiningMenuCategory {
  final String name;
  final List<DiningMenuItem> items;
  const DiningMenuCategory({required this.name, required this.items});
}

class DiningVenue {
  final String name;
  final String description;
  final String? headerImagePath;
  final List<DiningMenuCategory> menuCategories;
  const DiningVenue({
    required this.name,
    required this.description,
    this.headerImagePath,
    required this.menuCategories,
  });
}

// Global fonksiyon: Dili alıp Venue Map'ini döndürür
Map<String, DiningVenue> getDiningVenues(AppLocalizations texts) {
  return {
    'The Azure Restaurant': DiningVenue(
      name: 'The Azure Restaurant',
      description: texts.azureDesc,
      headerImagePath: 'assets/images/arkaplan.jpg',
      menuCategories: [
        DiningMenuCategory(
          name: 'Appetizers', // İstenirse texts.appetizers eklenebilir
          items: [
            DiningMenuItem(
              name: 'Seared Scallops',
              description: 'With saffron risotto...',
              price: 24.00,
              imagePath: 'assets/images/arkaplan.jpg',
            ),
            DiningMenuItem(
              name: 'Burrata Caprese',
              description: 'Fresh burrata, heirloom tomatoes...',
              price: 18.00,
              imagePath: 'assets/images/arkaplan.jpg',
            ),
          ],
        ),
        DiningMenuCategory(
          name: 'Main Courses',
          items: [
            DiningMenuItem(
              name: 'Grilled Ribeye Steak',
              description: 'Prime beef with truffle mash...',
              price: 48.00,
              imagePath: 'assets/images/arkaplan.jpg',
            ),
            DiningMenuItem(
              name: 'Pan-Seared Salmon',
              description: 'Atlantic salmon with asparagus...',
              price: 38.00,
              imagePath: 'assets/images/arkaplan.jpg',
            ),
          ],
        ),
      ],
    ),
    'Rooftop Bar': DiningVenue(
      name: 'Rooftop Bar',
      description: texts.rooftopDesc,
      headerImagePath: 'assets/images/arkaplanyok1.png',
      menuCategories: [
        DiningMenuCategory(
          name: 'Signature Cocktails',
          items: [
            DiningMenuItem(
              name: 'Azure Sunset',
              description: 'Vodka, passion fruit...',
              price: 18.00,
            ),
          ],
        ),
      ],
    ),
    'Pool Cafe': DiningVenue(
      name: 'Pool Cafe',
      description: texts.poolCafeDesc,
      headerImagePath: 'assets/images/arkaplanyok.png',
      menuCategories: [
        DiningMenuCategory(
          name: 'Light Meals',
          items: [
            DiningMenuItem(
              name: 'Club Sandwich',
              description: 'Triple-decker with chicken...',
              price: 18.00,
            ),
          ],
        ),
      ],
    ),
  };
}

class DiningPricelistScreen extends StatefulWidget {
  final String venueName;
  const DiningPricelistScreen({super.key, required this.venueName});

  @override
  State<DiningPricelistScreen> createState() => _DiningPricelistScreenState();
}

class _DiningPricelistScreenState extends State<DiningPricelistScreen> {
  int _selectedCategoryIndex = 0;

  @override
  Widget build(BuildContext context) {
    final texts = AppLocalizations.of(context)!;
    // Verileri dinamik çekiyoruz
    final venues = getDiningVenues(texts);
    final venue = venues[widget.venueName];

    if (venue == null) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: const Center(child: Text('Venue not found')),
      );
    }

    final categories = venue.menuCategories;
    final selectedCategory = categories.isNotEmpty
        ? categories[_selectedCategoryIndex]
        : null;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                decoration: const BoxDecoration(
                  color: Color.fromRGBO(255, 255, 255, 0.9),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.black87),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: venue.headerImagePath != null
                  ? Image.asset(venue.headerImagePath!, fit: BoxFit.cover)
                  : Container(color: const Color(0xFF1677FF)),
            ),
          ),
          SliverToBoxAdapter(
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    venue.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    venue.description,
                    style: TextStyle(fontSize: 15, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Container(
              color: Colors.white,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: List.generate(categories.length, (index) {
                    final isSelected = index == _selectedCategoryIndex;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () =>
                            setState(() => _selectedCategoryIndex = index),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF1677FF)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(25),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFF1677FF)
                                  : Colors.grey[300]!,
                            ),
                          ),
                          child: Text(
                            categories[index].name,
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.black87,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          if (selectedCategory != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  selectedCategory.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 12)),
          if (selectedCategory != null)
            SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final item = selectedCategory.items[index];
                return _MenuItemCard(item: item);
              }, childCount: selectedCategory.items.length),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: const Color.fromRGBO(0, 0, 0, 0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      DiningBookingScreen(preselectedVenue: widget.venueName),
                ),
              );
            },
            icon: const Icon(Icons.calendar_today, color: Colors.white),
            label: Text(
              texts.bookTable,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1677FF),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MenuItemCard extends StatelessWidget {
  final DiningMenuItem item;
  const _MenuItemCard({required this.item});
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color.fromRGBO(0, 0, 0, 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.description,
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Text(
                  '\$${item.price.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1677FF),
                  ),
                ),
              ],
            ),
          ),
          if (item.imagePath != null) ...[
            const SizedBox(width: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                item.imagePath!,
                width: 80,
                height: 80,
                fit: BoxFit.cover,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
