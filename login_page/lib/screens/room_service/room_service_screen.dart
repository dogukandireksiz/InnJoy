import 'package:flutter/material.dart';
import 'room_service_cart_screen.dart';
import 'menu_data.dart';
import '../../service/database_service.dart';
import '../../model/menu_item_model.dart';
import 'room_service_cart_screen.dart';


class RoomServiceScreen extends StatefulWidget {
  const RoomServiceScreen({super.key});

  @override
  State<RoomServiceScreen> createState() => _RoomServiceScreenState();
}

class _RoomServiceScreenState extends State<RoomServiceScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final Map<MenuItem, int> _cart = {};
  final DatabaseService _dbService = DatabaseService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  int get _totalItems => _cart.values.fold(0, (sum, qty) => sum + qty);
  double get _totalPrice => _cart.entries.fold(0.0, (sum, e) => sum + (e.key.price * e.value));

  void _addToCart(MenuItem item) {
    setState(() {
      _cart[item] = (_cart[item] ?? 0) + 1;
    });
  }

  void _goToCart() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RoomServiceCartScreen(
          cart: Map.from(_cart),
          onCartUpdated: (updatedCart) {
            setState(() {
              _cart.clear();
              _cart.addAll(updatedCart);
            });
          },
          onOrderPlaced: () {
            setState(() => _cart.clear());
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Oda Servisi',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart_outlined, color: Colors.black87),
                onPressed: _cart.isNotEmpty ? _goToCart : null,
              ),
              if (_totalItems > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Color(0xFF1677FF),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$_totalItems',
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF1677FF),
          unselectedLabelColor: Colors.black54,
          indicatorColor: const Color(0xFF1677FF),
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          isScrollable: true,
          tabs: const [
            Tab(text: 'Kahvaltı'),
            Tab(text: 'Öğle/Akşam'),
            Tab(text: 'İçecekler'),
            Tab(text: 'Gece Menüsü'),
          ],
        ),
      ),
      body: StreamBuilder<List<MenuItem>>(
        stream: _dbService.getMenuItems(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Hata: ${snapshot.error}"));
          }

          final allItems = snapshot.data ?? [];

          // Gelen verileri kategorilerine göre filtreliyoruz
          final breakfastItems = allItems.where((i) => i.category == 'breakfast').toList();
          final mainItems = allItems.where((i) => i.category == 'main').toList();
          final drinkItems = allItems.where((i) => i.category == 'drink').toList();
          final nightItems = allItems.where((i) => i.category == 'night').toList();

          return TabBarView(
            controller: _tabController,
            children: [
              _MenuGrid(items: breakfastItems, cart: _cart, onAdd: _addToCart),
              _MenuGrid(items: mainItems, cart: _cart, onAdd: _addToCart),
              _MenuGrid(items: drinkItems, cart: _cart, onAdd: _addToCart),
              _MenuGrid(items: nightItems, cart: _cart, onAdd: _addToCart),
            ],
          );
        },
      ),
      bottomNavigationBar: _totalItems > 0
          ? Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: ElevatedButton(
                  onPressed: _goToCart,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1677FF),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.shopping_cart, color: Colors.white),
                      const SizedBox(width: 8),
                      Text(
                        '$_totalItems ürün',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(width: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Sepeti Görüntüle ₺${_totalPrice.toStringAsFixed(2)}',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          : null,
    );
  }
}

class _MenuGrid extends StatelessWidget {
  final List<MenuItem> items;
  final Map<MenuItem, int> cart;
  final ValueChanged<MenuItem> onAdd;

  const _MenuGrid({
    required this.items,
    required this.cart,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
        if (items.isEmpty) {
      return const Center(child: Text("Bu kategoride ürün bulunamadı."));
    }
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final quantity = cart[item] ?? 0;
        return _MenuItemCard(
          item: item,
          quantity: quantity,
          onAdd: () => onAdd(item),
        );
      },
    );
  }
}

class _MenuItemCard extends StatelessWidget {
  final MenuItem item;
  final int quantity;
  final VoidCallback onAdd;

  const _MenuItemCard({
    required this.item,
    required this.quantity,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image placeholder with add button
          Stack(
            children: [
              Container(
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Center(
                  child: Icon(
                    _getIconForItem(item.name),
                    size: 48,
                    color: Colors.grey[400],
                  ),
                ),
              ),
              Positioned(
                right: 8,
                bottom: 8,
                child: GestureDetector(
                  onTap: onAdd,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1677FF),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: quantity > 0
                        ? Center(
                            child: Text(
                              '$quantity',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          )
                        : const Icon(Icons.add, color: Colors.white, size: 18),
                  ),
                ),
              ),
            ],
          ),
          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.description,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 11,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Spacer(),
                  Text(
                    '${item.price.toStringAsFixed(0)} TL',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: Color(0xFF1677FF),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIconForItem(String name) {
    final lowerName = name.toLowerCase();
    if (lowerName.contains('kahve') || lowerName.contains('latte')) return Icons.coffee;
    if (lowerName.contains('çay')) return Icons.local_cafe;
    if (lowerName.contains('su') || lowerName.contains('limonata') || lowerName.contains('smoothie')) return Icons.local_drink;
    if (lowerName.contains('kahvaltı') || lowerName.contains('yumurta')) return Icons.egg_alt;
    if (lowerName.contains('tost') || lowerName.contains('sandviç')) return Icons.bakery_dining;
    if (lowerName.contains('pizza')) return Icons.local_pizza;
    if (lowerName.contains('burger')) return Icons.lunch_dining;
    if (lowerName.contains('salata')) return Icons.grass;
    if (lowerName.contains('meyve')) return Icons.apple;
    if (lowerName.contains('dondurma') || lowerName.contains('sufle')) return Icons.icecream;
    if (lowerName.contains('köfte') || lowerName.contains('tavuk') || lowerName.contains('kanat')) return Icons.restaurant;
    if (lowerName.contains('patates')) return Icons.fastfood;
    if (lowerName.contains('pancake')) return Icons.breakfast_dining;
    return Icons.restaurant_menu;
  }
}
