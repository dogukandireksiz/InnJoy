import 'package:flutter/material.dart';
import '../../service/database_service.dart';
import '../../model/menu_item_model.dart';
import 'add_menu_item_screen.dart';

class RoomServiceMenuManagementScreen extends StatefulWidget {
  final String hotelName;

  const RoomServiceMenuManagementScreen({super.key, required this.hotelName});

  @override
  State<RoomServiceMenuManagementScreen> createState() =>
      _RoomServiceMenuManagementScreenState();
}

class _RoomServiceMenuManagementScreenState
    extends State<RoomServiceMenuManagementScreen> {
  // Standardized Categories
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

  String _selectedCategory = 'All';
  final String _restaurantId = 'room_service';
  final String _dbRestaurantId = 'room_service'; // For database consistency

  // Colors from Design
  final primaryColor = const Color(0xFF137fec);
  final textDarkColor = const Color(0xFF101922);

  // ... (build method remains mostly same, just ensure _categories usage is correct)

  @override
  Widget build(BuildContext context) {
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode
          ? const Color(0xFF101922)
          : const Color(0xFFF6F7FB),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(isDarkMode),
            _buildCategoryFilter(isDarkMode),
            Expanded(
              child: StreamBuilder<List<MenuItem>>(
                stream: DatabaseService().getRestaurantMenu(
                  widget.hotelName,
                  _restaurantId,
                ),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  final allItems = snapshot.data ?? [];

                  // Filter logic
                  final displayedItems = _selectedCategory == 'All'
                      ? allItems
                      : allItems
                            .where((item) => item.category == _selectedCategory)
                            .toList();

                  if (displayedItems.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.restaurant_menu,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No items found',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    );
                  }

                  // Group by category for 'All' view for better UX
                  if (_selectedCategory == 'All') {
                    return ListView(
                      padding: const EdgeInsets.all(16),
                      children: _categories
                          .where(
                            (c) =>
                                c['name'] !=
                                'All', // Show all categories except the 'All' label itself
                          )
                          .map((cat) {
                            final catId = cat['id'];
                            final catItems = allItems
                                .where((i) => i.category == catId)
                                .toList();
                            if (catItems.isEmpty)
                              return const SizedBox.shrink();

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                  ),
                                  child: Text(
                                    cat['name'],
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: isDarkMode
                                          ? Colors.white
                                          : Colors.black87,
                                    ),
                                  ),
                                ),
                                ...catItems.map(
                                  (item) => Padding(
                                    padding: const EdgeInsets.only(bottom: 16),
                                    child: _buildPremiumMenuItemCard(
                                      item,
                                      isDarkMode,
                                    ),
                                  ),
                                ),
                              ],
                            );
                          })
                          .toList(),
                    );
                  }

                  // Standard filtered list view
                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: displayedItems.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      return _buildPremiumMenuItemCard(
                        displayedItems[index],
                        isDarkMode,
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToAddEditScreen(context),
        backgroundColor: primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  // ... _buildHeader, _buildCategoryFilter, _buildPremiumMenuItemCard, etc. need to be re-added or ensured they exist.
  // Wait, I messed up the previous replace. It seems I deleted everything between _categories and _seedMenu?
  // I need to put back ALL the UI building code.

  Widget _buildHeader(bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey[800] : Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.arrow_back,
                color: isDarkMode ? Colors.white : Colors.black,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Room Service Menu',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : textDarkColor,
                  ),
                ),
                Text(
                  'Manage ${widget.hotelName} Menu',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter(bool isDarkMode) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        separatorBuilder: (context, index) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final category = _categories[index];
          final catId = category['id'] as String;
          final isSelected = _selectedCategory == catId;
          final Color catColor = category['color'] as Color;

          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = catId),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? catColor
                    : (isDarkMode ? Colors.grey[800] : Colors.white),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? catColor
                      : (isDarkMode ? Colors.grey[700]! : Colors.grey[300]!),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    category['icon'],
                    size: 16,
                    color: isSelected ? Colors.white : catColor,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    category['name'],
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? Colors.white
                          : (isDarkMode ? Colors.grey[200] : textDarkColor),
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

  Widget _buildPremiumMenuItemCard(MenuItem item, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E2A38) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDarkMode ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
          width: 1,
        ),
        boxShadow: isDarkMode
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                  spreadRadius: 0,
                ),
              ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                item.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    Icon(Icons.fastfood, color: Colors.grey[400]),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: SizedBox(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode
                              ? Colors.white
                              : const Color(0xFF0f172a),
                          height: 1.25,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 2.0),
                        child: Text(
                          item.description,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: isDarkMode
                                ? Colors.grey[400]
                                : const Color(0xFF64748B),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          '₺${item.price.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Status Badge removed
                      const SizedBox.shrink(),
                      Row(
                        children: [
                          InkWell(
                            onTap: () => _deleteItem(item),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              width: 32,
                              height: 32,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                color: Colors.transparent,
                              ),
                              child: Icon(
                                Icons.delete,
                                size: 20,
                                color: Colors.grey[400],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          InkWell(
                            onTap: () =>
                                _navigateToAddEditScreen(context, item: item),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              height: 32,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                color: primaryColor.withOpacity(0.1),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.edit,
                                    size: 16,
                                    color: primaryColor,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Düzenle',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: primaryColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToAddEditScreen(BuildContext context, {MenuItem? item}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AddMenuItemScreen(
          hotelName: widget.hotelName,
          restaurantId: _restaurantId, // Passing 'Room Service'
          item: item,
        ),
      ),
    );
  }

  void _deleteItem(MenuItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete'),
        content: Text('Delete ${item.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await DatabaseService().deleteMenuItem(
                widget.hotelName,
                _restaurantId,
                item.id,
              );
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
