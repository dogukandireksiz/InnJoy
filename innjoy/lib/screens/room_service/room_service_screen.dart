import 'package:flutter/material.dart';
import '../../models/menu_item_model.dart';
import '../../services/database_service.dart';
import 'room_service_cart_screen.dart';
import '../../utils/responsive_utils.dart';

class RoomServiceScreen extends StatefulWidget {
  final String hotelName;
  const RoomServiceScreen({super.key, required this.hotelName});

  @override
  State<RoomServiceScreen> createState() => _RoomServiceScreenState();
}

class _RoomServiceScreenState extends State<RoomServiceScreen> {
  final DatabaseService _dbService = DatabaseService();
  late Stream<List<MenuItem>> _menuStream; // Stream stored in state
  final ScrollController _categoryScrollController = ScrollController(); // Persist scroll
  
  String _selectedCategory = 'All';
  
  // Cart state
  final Map<String, int> _cart = {};
  double _totalPrice = 0.0;
  int _totalItems = 0;
  List<MenuItem> _allItems = []; // Store fetched items
  
  @override
  void initState() {
    super.initState();
    // Initialize stream once to prevent reloading on setState
    _menuStream = _dbService.getRoomServiceMenu(widget.hotelName);
  }

  @override
  void dispose() {
    _categoryScrollController.dispose();
    super.dispose();
  }

  // Standard Categories (matching Admin)
  final List<Map<String, dynamic>> _categories = [
    {'name': 'All', 'id': 'All', 'icon': Icons.list, 'color': Colors.grey},
    {
      'name': 'Breakfast',
      'id': 'Breakfast',
      'icon': Icons.bakery_dining,
      'color': Colors.amber,
    },
    {
      'name': 'Starters',
      'id': 'Starters',
      'icon': Icons.soup_kitchen,
      'color': Colors.lightGreen,
    },
    {
      'name': 'Main Courses',
      'id': 'Main Courses',
      'icon': Icons.restaurant,
      'color': Colors.redAccent,
    },
    {
      'name': 'Desserts',
      'id': 'Desserts',
      'icon': Icons.cake,
      'color': Colors.pink,
    },
    {
      'name': 'Drinks',
      'id': 'Drinks',
      'icon': Icons.local_drink,
      'color': Colors.teal,
    },
    {
      'name': 'Night Menu',
      'id': 'Night Menu',
      'icon': Icons.nights_stay,
      'color': Colors.indigo,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      body: StreamBuilder<List<MenuItem>>(
        stream: _menuStream, // Use initialized stream
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          _allItems = snapshot.data ?? [];

          return Stack(
            children: [
              CustomScrollView(
                slivers: [
                  _buildSliverAppBar(),
                  SliverToBoxAdapter(
                    child: _buildCategoryFilters(),
                  ),
                  _buildContentSlivers(),
                  SliverToBoxAdapter(child: SizedBox(height: ResponsiveUtils.spacing(context, 100))), // Bottom padding
                ],
              ),
              if (_totalItems > 0) _buildCartSummary(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 200.0,
      floating: false,
      pinned: true,
      backgroundColor: Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              'https://images.squarespace-cdn.com/content/v1/5a74702ce45a7cd601df944b/1619081310495-24HJYGFI7DYQ73O95WYF/hotel-room-service.jpg',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey[300]),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.2),
                    Colors.black.withValues(alpha: 0.6),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 16,
              left: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Room Service',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: ResponsiveUtils.sp(context, 28),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: ResponsiveUtils.spacing(context, 4)),
                  Text(
                    'Delicious meals delivered to your door',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: ResponsiveUtils.sp(context, 14),
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
  }

  Widget _buildCategoryFilters() {
    return Container(
      height: ResponsiveUtils.hp(context, 60 / 844),
      margin: EdgeInsets.only(top: 16, bottom: 8),
      child: ListView.separated(
        controller: _categoryScrollController, // Use persisted controller
        padding: EdgeInsets.symmetric(horizontal: ResponsiveUtils.spacing(context, 16)),
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        separatorBuilder: (_, e) => SizedBox(width: ResponsiveUtils.spacing(context, 12)),
        itemBuilder: (context, index) {
          final cat = _categories[index];
          final isSelected = _selectedCategory == cat['id'];
          final color = cat['color'] as Color;

          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = cat['id']),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: ResponsiveUtils.spacing(context, 16), vertical: ResponsiveUtils.spacing(context, 8)),
              decoration: BoxDecoration(
                color: isSelected ? color : Colors.white,
                borderRadius: BorderRadius.circular(ResponsiveUtils.spacing(context, 20)),
                boxShadow: [
                  if (!isSelected)
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                ],
              ),
              child: Row(
                children: [
                  Icon(
                    cat['icon'],
                    size: ResponsiveUtils.iconSize(context) * (18 / 24),
                    color: isSelected ? Colors.white : color,
                  ),
                  SizedBox(width: ResponsiveUtils.spacing(context, 8)),
                  Text(
                    cat['name'],
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.bold,
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

  Widget _buildContentSlivers() {
    // Data is now passed via _allItems since StreamBuilder is hoisted
    if (_allItems.isEmpty) {
       return const SliverFillRemaining(
        child: Center(child: Text("Menu is currently empty")),
      );
    }

    if (_selectedCategory == 'All') {
      return _buildSectionedList();
    } else {
      return _buildFilteredList();
    }
  }

  Widget _buildSectionedList() {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          // We need to build sections: Header + Items
          // This is a bit tricky with SliverList dynamic index. 
          // Easier approach: Build a list of widgets (Headers and Items) manually?
          // No, let's use a Column inside a single SliverToBoxAdapter PER CATEGORY?
          // Or one big column? 
          
          // Better approach for Sliver: 
          // Iterate over categories (skip 'All').
          // If category has items, show header + Grid/List of items.
          
          // Filter active categories first to match display logic if needed,
          // OR iterate over all _categories but check if they have items.
          // Since we want sections for things that exist:
          
          final category = _categories[index + 1]; // Skip 'All'
          final catId = category['id'];
          final items = _allItems.where((i) => i.category == catId && i.isActive).toList();

          // If no items, this section shouldn't even be called if we used displayCategories in childCount.
          // Yet we are using _categories. Let's fix loop to use unique categories found in items?
          // The previous code iterated _categories. 
          // If we want consistency, we should iterate over categories that have items.
          
          if (items.isEmpty) return const SizedBox.shrink();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(16, 24, 16, 12),
                child: Row(
                  children: [
                    Text(
                      category['name'],
                      style: TextStyle(
                        fontSize: ResponsiveUtils.sp(context, 20),
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF101922),
                      ),
                    ),
                  ],
                ),
              ),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: ResponsiveUtils.spacing(context, 16)),
                itemCount: items.length,
                itemBuilder: (context, i) => _buildMenuItemCard(items[i]),
              ),
            ],
          );
        },
        childCount: _categories.length - 1, // Exclude 'All'
      ),
    );
  }

  Widget _buildFilteredList() {
    final items = _allItems.where((i) => i.category == _selectedCategory && i.isActive).toList();
    
    if (items.isEmpty) {
      return const SliverFillRemaining(
        child: Center(child: Text("No items in this category")),
      );
    }

    return SliverPadding(
      padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 16)),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) => _buildMenuItemCard(items[index]),
          childCount: items.length,
        ),
      ),
    );
  }

  Widget _buildMenuItemCard(MenuItem item) {
    final quantity = _cart[item.id] ?? 0;

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(ResponsiveUtils.spacing(context, 16)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 12)),
        child: Row(
          children: [
            // Image
            ClipRRect(
              borderRadius: BorderRadius.circular(ResponsiveUtils.spacing(context, 12)),
              child: Image.network(
                item.imageUrl,
                width: ResponsiveUtils.wp(context, 100 / 375),
                height: ResponsiveUtils.hp(context, 100 / 844),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: ResponsiveUtils.wp(context, 100 / 375),
                  height: ResponsiveUtils.hp(context, 100 / 844),
                  color: Colors.grey[200],
                  child: const Icon(Icons.fastfood, color: Colors.grey),
                ),
              ),
            ),
            SizedBox(width: ResponsiveUtils.spacing(context, 16)),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: ResponsiveUtils.sp(context, 16),
                      color: Color(0xFF101922),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: ResponsiveUtils.spacing(context, 4)),
                  Text(
                    item.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: ResponsiveUtils.sp(context, 12),
                    ),
                  ),
                  SizedBox(height: ResponsiveUtils.spacing(context, 8)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '₺${item.price.toStringAsFixed(0)}',
                        style: TextStyle(
                          color: Color(0xFF137fec),
                          fontWeight: FontWeight.bold,
                          fontSize: ResponsiveUtils.sp(context, 16),
                        ),
                      ),
                      // Add Button / Counter
                      quantity == 0
                        ? InkWell(
                            onTap: () => _updateCart(item, 1),
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: ResponsiveUtils.spacing(context, 12), vertical: ResponsiveUtils.spacing(context, 6)),
                              decoration: BoxDecoration(
                                color: const Color(0xFF137fec),
                                borderRadius: BorderRadius.circular(ResponsiveUtils.spacing(context, 20)),
                              ),
                              child: Text(
                                "ADD",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: ResponsiveUtils.sp(context, 12),
                                ),
                              ),
                            ),
                          )
                        : Row(
                            children: [
                              _buildQtyIcon(Icons.remove, () => _updateCart(item, -1)),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: ResponsiveUtils.spacing(context, 8)),
                                child: Text(
                                  '$quantity',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              _buildQtyIcon(Icons.add, () => _updateCart(item, 1)),
                            ],
                          ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQtyIcon(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 4)),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: ResponsiveUtils.iconSize(context) * (16 / 24), color: const Color(0xFF137fec)),
      ),
    );
  }

  Widget _buildCartSummary() {
    return Positioned(
      bottom: 24,
      left: 16,
      right: 16,
      child: GestureDetector(
        onTap: _goToCart,
        child: Container(
          padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 16)),
          decoration: BoxDecoration(
            color: const Color(0xFF137fec),
            borderRadius: BorderRadius.circular(ResponsiveUtils.spacing(context, 16)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF137fec).withValues(alpha: 0.4),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: ResponsiveUtils.spacing(context, 12), vertical: ResponsiveUtils.spacing(context, 6)),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(ResponsiveUtils.spacing(context, 12)),
                ),
                child: Text(
                  '$_totalItems ${_totalItems == 1 ? "item" : "items"}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Flexible(
                child: Text(
                  'Go to Cart • ₺$_totalPrice',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: ResponsiveUtils.sp(context, 14),
                    ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: Colors.white, size: ResponsiveUtils.iconSize(context) * (16 / 24)),
            ],
          ),
        ),
      ),
    );
  }

  void _updateCart(MenuItem item, int change) {
    setState(() {
      final currentQty = _cart[item.id] ?? 0;
      final newQty = currentQty + change;

      if (newQty <= 0) {
        _cart.remove(item.id);
      } else {
        _cart[item.id] = newQty;
      }
      
      _recalculateTotal();
    });
  }

  void _recalculateTotal() {
    int items = 0;
    double price = 0;
    
    _cart.forEach((itemId, qty) {
      final item = _allItems.firstWhere((i) => i.id == itemId);
      items += qty;
      price += item.price * qty;
    });

    _totalItems = items;
    _totalPrice = price;
  }

  void _goToCart() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RoomServiceCartScreen(
          hotelName: widget.hotelName,
          cart: _cart.map((key, value) {
            final item = _allItems.firstWhere((i) => i.id == key);
            return MapEntry(item, value);
          }),
          onCartUpdated: (newCart) {
            setState(() {
              _cart.clear();
              newCart.forEach((item, qty) => _cart[item.id] = qty);
              _recalculateTotal();
            });
          },
          onOrderPlaced: () {
            setState(() {
              _cart.clear();
              _recalculateTotal();
            });
          },
        ),
      ),
    ).then((completed) {
      if (completed == true) {
        // Clear cart if order placed
        setState(() {
          _cart.clear();
          _recalculateTotal();
        });
      }
    });
  }
}










