import 'package:flutter/material.dart';
import '../services/dining/dining_booking_screen.dart';
import '../../models/menu_item_model.dart';
import '../../services/database_service.dart';
import '../../utils/responsive_utils.dart';

class CustomerMenuScreen extends StatefulWidget {
  final String hotelName;
  final String restaurantName;
  final String restaurantId; // For Firebase path

  const CustomerMenuScreen({
    super.key,
    required this.hotelName,
    required this.restaurantName,
    this.restaurantId = 'Aurora Restaurant', // Updated default
  });

  @override
  State<CustomerMenuScreen> createState() => _CustomerMenuScreenState();
}

class _CustomerMenuScreenState extends State<CustomerMenuScreen> {
  final DatabaseService _databaseService = DatabaseService();
  late Stream<List<MenuItem>> _menuStream;
  String _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    _menuStream = _databaseService.getRestaurantMenu(
      widget.hotelName,
      widget.restaurantId,
    );
  }

  // Categories matching the Admin design
  final List<Map<String, dynamic>> _categories = [
    {'name': 'All', 'icon': Icons.list, 'color': Colors.grey},
    {'name': 'Specials', 'icon': Icons.star, 'color': Colors.orange},
    {
      'name': 'Starters',
      'icon': Icons.soup_kitchen,
      'color': Colors.lightGreen,
    },
    {
      'name': 'Main Courses',
      'icon': Icons.restaurant,
      'color': Colors.redAccent,
    },
    {
      'name': 'Desserts',
      'icon': null,
      'emoji': '??',
      'color': Colors.pinkAccent,
    },
    {
      'name': 'Alcoholic Drinks',
      'icon': Icons.wine_bar,
      'color': Colors.purple,
    },
    {
      'name': 'Non-Alcoholic Drinks',
      'icon': Icons.local_drink,
      'color': Colors.teal,
    },
    {'name': 'Breakfast', 'icon': Icons.bakery_dining, 'color': Colors.amber},
    {'name': 'Snacks', 'icon': Icons.fastfood, 'color': Colors.deepOrange},
    {'name': 'Kids Menu', 'icon': Icons.child_care, 'color': Colors.cyan},
  ];

  @override
  Widget build(BuildContext context) {
    // Tailwind colors converted to Flutter
    final primaryColor = const Color(0xFF137fec);
    final bgLight = const Color(0xFFf6f7f8);
    // final bgDark = const Color(0xFF101922); // Use for dark mode if needed

    return Scaffold(
      backgroundColor: bgLight,
      body: StreamBuilder<List<MenuItem>>(
        stream: _menuStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final allItems = snapshot.data ?? [];

          // Filter items based on selection
          // Mapping Turkish content to English categories if necessary
          // For now assuming data matches categories or we show all if category not found?
          // The design shows specific category sections.
          // Let's filter by _selectedCategory.

          List<MenuItem> displayedItems = allItems.where((item) {
            if (_selectedCategory == 'All') return true;
            // Legacy Turkish category name support
            if (_selectedCategory == 'Starters' &&
                (item.category == 'Appetizers' ||
                    item.category == 'Starters' ||
                    item.category == 'Başlangıçlar')) {
              return true;
            }
            return item.category == _selectedCategory;
          }).toList();

          // Debug: if no items, maybe show dummy for visualization as requested "design"
          if (allItems.isEmpty) {
            // return _buildDesignPreview(); // Fallback to design preview if no data
          }

          return CustomScrollView(
            slivers: [
              _buildSliverAppBar(context),
              SliverToBoxAdapter(child: _buildCategoryList()),
              SliverPadding(
                padding: const EdgeInsets.only(bottom: 100),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final item = displayedItems[index];
                    return _buildMenuItemCard(item);
                  }, childCount: displayedItems.length),
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 16)),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => DiningBookingScreen(
                    hotelName: widget.hotelName,
                    restaurantId: widget.restaurantId,
                    restaurantName: widget.restaurantName,
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(ResponsiveUtils.spacing(context, 12)),
              ),
              elevation: 0,
            ),
            child: Text(
              'Book a Table',
              style: TextStyle(
                fontSize: ResponsiveUtils.sp(context, 18),
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context) {
    return StreamBuilder<Map<String, dynamic>?>(
      stream: _databaseService.getRestaurantSettings(
        widget.hotelName,
        widget.restaurantId,
      ),
      builder: (context, snapshot) {
        final data = snapshot.data;
        // Prefer DB data, fallback to widget.restaurantName for name
        final String displayName = data?['name'] ?? widget.restaurantName;
        final String description =
            data?['description'] ?? "Welcome to ${widget.restaurantName}";
        // Fallback to empty if not found, handle UI below
        final String imageUrl = data?['imageUrl'] ?? "";

        return SliverAppBar(
          expandedHeight: 250.0,
          floating: false,
          pinned: true,
          backgroundColor: Colors.transparent,
          flexibleSpace: FlexibleSpaceBar(
            background: Stack(
              fit: StackFit.expand,
              children: [
                if (imageUrl.isNotEmpty)
                  Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Image.asset(
                      'assets/images/arkaplan.jpg',
                      fit: BoxFit.cover,
                    ),
                  )
                else
                  Image.asset('assets/images/arkaplan.jpg', fit: BoxFit.cover),

                // Gradient Overlay
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.white.withValues(alpha: 0.5),
                        const Color(0xFFf6f7f8),
                      ],
                      stops: const [0.5, 0.8, 1.0],
                    ),
                  ),
                ),
                Positioned(
                  bottom: 16,
                  left: 16,
                  right: 16,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: TextStyle(
                          color: Color(0xFF101922),
                          fontSize: ResponsiveUtils.sp(context, 32),
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                          height: ResponsiveUtils.hp(context, 1.1 / 844),
                        ),
                      ),
                      SizedBox(height: ResponsiveUtils.spacing(context, 8)),
                      Text(
                        description,
                        style: TextStyle(
                          color: Color(0xFF475569),
                          fontSize: ResponsiveUtils.sp(context, 15),
                          fontWeight: FontWeight.w500,
                          height: ResponsiveUtils.hp(context, 1.4 / 844),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          leading: Container(
            margin: EdgeInsets.all(ResponsiveUtils.spacing(context, 8)),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.8),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCategoryList() {
    return Container(
      height: ResponsiveUtils.hp(context, 60 / 844),
      padding: EdgeInsets.symmetric(vertical: 10),
      color: const Color(0xFFf6f7f8),
      child: ListView.separated(
        key: const PageStorageKey('categories'),
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: ResponsiveUtils.spacing(context, 16)),
        itemCount: _categories.length,
        separatorBuilder: (_, e) => SizedBox(width: ResponsiveUtils.spacing(context, 8)),
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = _selectedCategory == category['name'];
          final Color catColor = category['color'] as Color;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedCategory = category['name'];
              });
            },
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: ResponsiveUtils.spacing(context, 16), vertical: ResponsiveUtils.spacing(context, 8)),
              decoration: BoxDecoration(
                color: isSelected ? catColor : Colors.white,
                borderRadius: BorderRadius.circular(ResponsiveUtils.spacing(context, 20)),
                boxShadow: [
                  if (!isSelected)
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                ],
                border: Border.all(
                  color: isSelected ? catColor : Colors.grey[300]!,
                ),
              ),
              alignment: Alignment.center,
              child: Row(
                children: [
                  if (category['icon'] != null) ...[
                    Icon(
                      category['icon'],
                      size: ResponsiveUtils.iconSize(context) * (18 / 24),
                      color: isSelected ? Colors.white : catColor,
                    ),
                    SizedBox(width: ResponsiveUtils.spacing(context, 6)),
                  ] else if (category['emoji'] != null) ...[
                    Text(
                      category['emoji'],
                      style: TextStyle(fontSize: ResponsiveUtils.sp(context, 18)),
                    ),
                    SizedBox(width: ResponsiveUtils.spacing(context, 6)),
                  ],
                  Text(
                    category['name'],
                    style: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : const Color(0xFF101922),
                      fontWeight: FontWeight.w600,
                      fontSize: ResponsiveUtils.sp(context, 14),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMenuItemCard(MenuItem item) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: ResponsiveUtils.spacing(context, 16), vertical: ResponsiveUtils.spacing(context, 8)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(ResponsiveUtils.spacing(context, 12)), // rounded-xl (~12px)
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1), // shadow-md
            blurRadius: 6, // Approximate shadow-md
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 16)),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: TextStyle(
                      // text-slate-800
                      color: Color(0xFF1e293b),
                      fontSize: ResponsiveUtils.sp(context, 18), // text-lg
                      fontWeight: FontWeight.w600, // font-semibold
                      height: ResponsiveUtils.hp(context, 1.375 / 844), // leading-snug
                    ),
                  ),
                  SizedBox(height: ResponsiveUtils.spacing(context, 4)), // mt-1
                  Text(
                    item.description,
                    style: TextStyle(
                      // text-slate-600
                      color: Color(0xFF475569),
                      fontSize: ResponsiveUtils.sp(context, 14), // text-sm
                      fontWeight: FontWeight.normal, // font-normal
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: ResponsiveUtils.spacing(context, 8)), // mt-2
                  Text(
                    '₺${item.price.toStringAsFixed(2)}',
                    style: TextStyle(
                      // text-slate-900
                      color: Color(0xFF0f172a),
                      fontSize: ResponsiveUtils.sp(context, 14),
                  ),
                ),
                ],
              ),
            ),
            SizedBox(width: ResponsiveUtils.spacing(context, 16)), // gap-4
            ClipRRect(
              borderRadius: BorderRadius.circular(ResponsiveUtils.spacing(context, 8)), // rounded-lg
              child: Container(
                color: Colors.grey[200], // bg-slate-200
                child: Image.network(
                  item.imageUrl,
                  width: ResponsiveUtils.wp(context, 96 / 375), // w-24 (6rem = 96px)
                  height: ResponsiveUtils.hp(context, 96 / 844), // h-24
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: ResponsiveUtils.wp(context, 96 / 375),
                    height: ResponsiveUtils.hp(context, 96 / 844),
                    color: Colors.grey[200],
                    child: const Icon(Icons.fastfood, color: Colors.grey),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

