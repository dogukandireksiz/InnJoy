import 'package:flutter/material.dart';
import 'dining_booking_screen.dart';

// Menü öğesi modeli
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

// Menü kategorisi modeli
class DiningMenuCategory {
  final String name;
  final List<DiningMenuItem> items;

  const DiningMenuCategory({
    required this.name,
    required this.items,
  });
}

// Restoran/Bar modeli
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

// Örnek veri - Tüm restoranlar ve barlar için menüler
class DiningData {
  static final Map<String, DiningVenue> venues = {
    'The Azure Restaurant': DiningVenue(
      name: 'The Azure Restaurant',
      description: 'Fine dining with a panoramic city view, featuring a modern European menu.',
      headerImagePath: 'assets/images/arkaplan.jpg',
      menuCategories: [
        DiningMenuCategory(
          name: 'Appetizers',
          items: [
            DiningMenuItem(
              name: 'Seared Scallops',
              description: 'With saffron risotto and a lemon-butter sauce.',
              price: 24.00,
              imagePath: 'assets/images/arkaplan.jpg',
            ),
            DiningMenuItem(
              name: 'Burrata Caprese',
              description: 'Fresh burrata, heirloom tomatoes, basil, and balsamic glaze.',
              price: 18.00,
              imagePath: 'assets/images/arkaplan.jpg',
            ),
            DiningMenuItem(
              name: 'Tuna Tartare',
              description: 'Ahi tuna, avocado, soy-lime dressing, and crispy wontons.',
              price: 22.00,
              imagePath: 'assets/images/arkaplan.jpg',
            ),
            DiningMenuItem(
              name: 'Mushroom Vol-au-Vent',
              description: 'Puff pastry filled with a creamy wild mushroom ragout.',
              price: 19.00,
              imagePath: 'assets/images/arkaplan.jpg',
            ),
          ],
        ),
        DiningMenuCategory(
          name: 'Main Courses',
          items: [
            DiningMenuItem(
              name: 'Grilled Ribeye Steak',
              description: 'Prime beef with truffle mashed potatoes and red wine jus.',
              price: 48.00,
              imagePath: 'assets/images/arkaplan.jpg',
            ),
            DiningMenuItem(
              name: 'Pan-Seared Salmon',
              description: 'Atlantic salmon with asparagus and hollandaise sauce.',
              price: 38.00,
              imagePath: 'assets/images/arkaplan.jpg',
            ),
            DiningMenuItem(
              name: 'Lobster Thermidor',
              description: 'Classic preparation with brandy cream sauce.',
              price: 65.00,
              imagePath: 'assets/images/arkaplan.jpg',
            ),
            DiningMenuItem(
              name: 'Truffle Risotto',
              description: 'Creamy Arborio rice with black truffle shavings.',
              price: 32.00,
              imagePath: 'assets/images/arkaplan.jpg',
            ),
          ],
        ),
        DiningMenuCategory(
          name: 'Desserts',
          items: [
            DiningMenuItem(
              name: 'Chocolate Fondant',
              description: 'Warm chocolate cake with molten center and vanilla ice cream.',
              price: 14.00,
              imagePath: 'assets/images/arkaplan.jpg',
            ),
            DiningMenuItem(
              name: 'Crème Brûlée',
              description: 'Classic French custard with caramelized sugar top.',
              price: 12.00,
              imagePath: 'assets/images/arkaplan.jpg',
            ),
            DiningMenuItem(
              name: 'Tiramisu',
              description: 'Italian classic with espresso-soaked ladyfingers.',
              price: 13.00,
              imagePath: 'assets/images/arkaplan.jpg',
            ),
          ],
        ),
      ],
    ),
    'Rooftop Bar': DiningVenue(
      name: 'Rooftop Bar',
      description: 'Stunning views with signature cocktails and light bites.',
      headerImagePath: 'assets/images/arkaplanyok1.png',
      menuCategories: [
        DiningMenuCategory(
          name: 'Signature Cocktails',
          items: [
            DiningMenuItem(
              name: 'Azure Sunset',
              description: 'Vodka, passion fruit, orange liqueur, lime.',
              price: 18.00,
            ),
            DiningMenuItem(
              name: 'Midnight Manhattan',
              description: 'Bourbon, sweet vermouth, bitters, cherry.',
              price: 16.00,
            ),
            DiningMenuItem(
              name: 'Garden Mojito',
              description: 'White rum, fresh mint, lime, soda.',
              price: 14.00,
            ),
          ],
        ),
        DiningMenuCategory(
          name: 'Wine Selection',
          items: [
            DiningMenuItem(
              name: 'Château Margaux 2015',
              description: 'Full-bodied Bordeaux with notes of dark fruit.',
              price: 85.00,
            ),
            DiningMenuItem(
              name: 'Cloudy Bay Sauvignon Blanc',
              description: 'Crisp New Zealand white with citrus notes.',
              price: 45.00,
            ),
          ],
        ),
        DiningMenuCategory(
          name: 'Bar Bites',
          items: [
            DiningMenuItem(
              name: 'Truffle Fries',
              description: 'Crispy fries with truffle oil and parmesan.',
              price: 12.00,
            ),
            DiningMenuItem(
              name: 'Oysters (6 pcs)',
              description: 'Fresh oysters with mignonette sauce.',
              price: 28.00,
            ),
            DiningMenuItem(
              name: 'Cheese Board',
              description: 'Selection of artisanal cheeses with crackers.',
              price: 24.00,
            ),
          ],
        ),
      ],
    ),
    'Pool Cafe': DiningVenue(
      name: 'Pool Cafe',
      description: 'Casual dining by the pool with refreshing drinks and snacks.',
      headerImagePath: 'assets/images/arkaplanyok.png',
      menuCategories: [
        DiningMenuCategory(
          name: 'Light Meals',
          items: [
            DiningMenuItem(
              name: 'Club Sandwich',
              description: 'Triple-decker with chicken, bacon, lettuce, tomato.',
              price: 18.00,
            ),
            DiningMenuItem(
              name: 'Caesar Salad',
              description: 'Romaine lettuce, parmesan, croutons, caesar dressing.',
              price: 16.00,
            ),
            DiningMenuItem(
              name: 'Grilled Chicken Wrap',
              description: 'Marinated chicken with vegetables in a tortilla.',
              price: 15.00,
            ),
          ],
        ),
        DiningMenuCategory(
          name: 'Refreshments',
          items: [
            DiningMenuItem(
              name: 'Fresh Fruit Smoothie',
              description: 'Blend of seasonal fruits with yogurt.',
              price: 10.00,
            ),
            DiningMenuItem(
              name: 'Iced Coffee',
              description: 'Cold brew with your choice of milk.',
              price: 8.00,
            ),
            DiningMenuItem(
              name: 'Fresh Coconut',
              description: 'Chilled young coconut with straw.',
              price: 12.00,
            ),
          ],
        ),
      ],
    ),
  };

  static DiningVenue? getVenue(String name) => venues[name];
}

class DiningPricelistScreen extends StatefulWidget {
  final String venueName;

  const DiningPricelistScreen({
    super.key,
    required this.venueName,
  });

  @override
  State<DiningPricelistScreen> createState() => _DiningPricelistScreenState();
}

class _DiningPricelistScreenState extends State<DiningPricelistScreen> {
  int _selectedCategoryIndex = 0;

  DiningVenue? get _venue => DiningData.getVenue(widget.venueName);

  @override
  Widget build(BuildContext context) {
    final venue = _venue;

    if (venue == null) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: const Center(
          child: Text('Venue not found'),
        ),
      );
    }

    final categories = venue.menuCategories;
    final selectedCategory = categories.isNotEmpty ? categories[_selectedCategoryIndex] : null;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      body: CustomScrollView(
        slivers: [
          // Header with image
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
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
                  ? Image.asset(
                      venue.headerImagePath!,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      color: const Color(0xFF1677FF),
                    ),
            ),
          ),

          // Venue info
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
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Category tabs
          SliverToBoxAdapter(
            child: Container(
              color: Colors.white,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: List.generate(categories.length, (index) {
                    final isSelected = index == _selectedCategoryIndex;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedCategoryIndex = index),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFF1677FF) : Colors.white,
                            borderRadius: BorderRadius.circular(25),
                            border: Border.all(
                              color: isSelected ? const Color(0xFF1677FF) : Colors.grey[300]!,
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

          // Category title
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

          // Menu items
          if (selectedCategory != null)
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final item = selectedCategory.items[index];
                  return _MenuItemCard(item: item);
                },
                childCount: selectedCategory.items.length,
              ),
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
              color: Colors.black.withOpacity(0.05),
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
                  builder: (_) => DiningBookingScreen(preselectedVenue: widget.venueName),
                ),
              );
            },
            icon: const Icon(Icons.calendar_today, color: Colors.white),
            label: const Text(
              'Book a Table',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1677FF),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
            color: Colors.black.withOpacity(0.05),
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
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
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
