import 'package:flutter/material.dart';
import '../../../services/database_service.dart';
import '../../../models/menu_item_model.dart';
import 'add_menu_item_screen.dart';

class MenuManagementScreen extends StatefulWidget {
  final String hotelName;

  const MenuManagementScreen({super.key, required this.hotelName});

  @override
  State<MenuManagementScreen> createState() => _MenuManagementScreenState();
}

class _MenuManagementScreenState extends State<MenuManagementScreen> {
  // Define categories to match Customer View + "All"
  // Define categories to match Customer View + "All"
  // Define categories to match Customer View + "All"
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
    }, // Emoji: cake slice
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

  String _selectedCategory = 'All';
  final String _restaurantId = 'Aurora Restaurant'; // Specific restaurant name for this hotel

  // Colors from Design
  final primaryColor = const Color(0xFF137fec);
  final textDarkColor = const Color(0xFF101922);

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
                            final catItems = displayedItems
                                .where((i) => i.category == cat['name'])
                                .toList();
                            if (catItems.isEmpty) {
                              return const SizedBox.shrink();
                            }

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
                  'Menu Management',
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
          final isSelected = _selectedCategory == category['name'];
          final Color catColor = category['color'] as Color;

          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = category['name']),
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
                  if (category['icon'] != null) ...[
                    Icon(
                      category['icon'],
                      size: 16,
                      color: isSelected ? Colors.white : catColor,
                    ),
                    const SizedBox(width: 6),
                  ] else if (category['emoji'] != null) ...[
                    Text(
                      category['emoji'],
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(width: 6),
                  ],
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
    // HTML Design:
    // <div class="group flex flex-row bg-white dark:bg-slate-800 rounded-2xl p-3 shadow-[0_2px_8px_rgba(0,0,0,0.04)] dark:shadow-none border border-slate-100 dark:border-slate-700 gap-3.5 transition-all">
    
    return Container(
      padding: const EdgeInsets.all(12), // p-3 -> 0.75rem -> 12px
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E2A38) : Colors.white,
        borderRadius: BorderRadius.circular(16), // rounded-2xl -> 1rem -> 16px
        border: Border.all(
          color: isDarkMode ? const Color(0xFF334155) : const Color(0xFFF1F5F9), // border-slate-100 / slate-700
          width: 1,
        ),
        boxShadow: isDarkMode ? null : [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04), // shadow-[0_2px_8px_rgba(0,0,0,0.04)]
            blurRadius: 8,
            offset: const Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image Section
          // <div class="w-24 h-24 shrink-0 bg-gray-100 rounded-xl overflow-hidden relative">
          Container(
            width: 96, // w-24 -> 6rem -> 96px
            height: 96, // h-24
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12), // rounded-xl -> 0.75rem -> 12px
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                item.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Icon(Icons.fastfood, color: Colors.grey[400]),
              ),
            ),
          ),
          
          const SizedBox(width: 14), // gap-3.5 -> 0.875rem -> 14px

          // Content Section
          Expanded(
            child: SizedBox(
               // minHeight ensures alignment with image, but allows growth
              // height: 96, // Removed to allow auto-sizing
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top part (Title, Description, Price)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        item.name,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : const Color(0xFF0f172a), 
                          height: 1.25, 
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      // Description (Replacing Category)
                      Padding(
                        padding: const EdgeInsets.only(top: 2.0), 
                        child: Text(
                          item.description, 
                          style: TextStyle(
                            fontSize: 12, // Slightly smaller
                            fontWeight: FontWeight.w400,
                            color: isDarkMode ? Colors.grey[400] : const Color(0xFF64748B), 
                          ),
                          maxLines: 2, // Limit lines to prevent massive expansion
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // Price
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0), 
                        child: Text(
                          '?${item.price.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  // Bottom part (Status badge + Buttons)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Status Badge
                      // <span class="inline-flex items-center rounded-md bg-emerald-50 ... px-2 py-1 text-[11px] ...">Aktif</span>
                      // Status Badge removed as per user request
                      const SizedBox.shrink(),

                      // Actions
                      // <div class="flex items-center gap-2">
                      Row(
                        children: [
                          // Delete Button
                          // <button class="flex items-center justify-center w-8 h-8 rounded-lg text-slate-400 hover:text-red-500 ...">
                           InkWell(
                            onTap: () => _deleteItem(item),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              width: 32,
                              height: 32,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                color: Colors.transparent, // Default transparent
                              ),
                              child: Icon(Icons.delete, size: 20, color: Colors.grey[400]),
                            ),
                          ),
                          
                          const SizedBox(width: 8),

                          // Edit Button
                          // <button class="flex items-center gap-1 px-3 h-8 rounded-lg bg-primary/10 hover:bg-primary/20 text-primary text-[13px] font-semibold ...">
                          InkWell(
                            onTap: () => _navigateToAddEditScreen(context, item: item),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              height: 32,
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                color: primaryColor.withValues(alpha: 0.1), // bg-primary/10
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.edit, size: 16, color: primaryColor),
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

  // _buildActionButton removed as it's now inline for specific styling per HTML

  void _navigateToAddEditScreen(BuildContext context, {MenuItem? item}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AddMenuItemScreen(
          hotelName: widget.hotelName,
          restaurantId: _restaurantId,
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









