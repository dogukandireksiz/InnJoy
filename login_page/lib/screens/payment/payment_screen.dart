import 'package:flutter/material.dart';

// Shared spending data that can be accessed from HomeScreen
class SpendingData {
  static const double baseBalance = 1250.75;
  static const String guestName = 'Ali Veli';
  static const String roomNumber = '1204';

  // Dinamik room service siparişleri için liste
  static final List<TransactionData> _roomServiceOrders = [];

  static double get totalBalance {
    return baseBalance + _roomServiceOrdersTotal;
  }

  static double get _roomServiceOrdersTotal {
    double total = 0;
    for (final order in _roomServiceOrders) {
      total += order.amount;
    }
    return total;
  }

  static double get totalSpending {
    double total = 0;
    for (final cat in categories) {
      total += cat.amount;
    }
    return total;
  }

  // Room service siparişi ekleme metodu
  static void addRoomServiceOrder(String description, double amount) {
    _roomServiceOrders.add(
      TransactionData(description, amount, DateTime.now(), 'Room Service', Icons.room_service),
    );
  }

  // Tüm room service siparişlerini temizleme
  static void clearRoomServiceOrders() {
    _roomServiceOrders.clear();
  }

  static List<CategoryData> get categories => [
    CategoryData(
      id: 'dining',
      icon: Icons.restaurant_menu,
      title: 'Dining & Restaurants',
      amount: 562.84,
      transactions: [
        TransactionData('Lobby Restaurant - Breakfast', 45.00, DateTime(2025, 11, 27, 8, 30), 'Dining & Restaurants', Icons.restaurant_menu),
        TransactionData('Rooftop Bar - Dinner', 189.50, DateTime(2025, 11, 25, 20, 0), 'Dining & Restaurants', Icons.restaurant_menu),
        TransactionData('Pool Cafe - Lunch', 67.34, DateTime(2025, 11, 26, 13, 15), 'Dining & Restaurants', Icons.restaurant_menu),
        TransactionData('Room Service - Late Night', 112.00, DateTime(2025, 11, 27, 1, 30), 'Dining & Restaurants', Icons.restaurant_menu),
        TransactionData('Lobby Restaurant - Brunch', 149.00, DateTime(2025, 11, 24, 11, 0), 'Dining & Restaurants', Icons.restaurant_menu),
      ],
    ),
    CategoryData(
      id: 'spa',
      icon: Icons.spa,
      title: 'Spa & Wellness',
      amount: 375.00,
      transactions: [
        TransactionData('Full Body Massage - 90 min', 375.00, DateTime(2025, 11, 26, 15, 0), 'Spa & Wellness', Icons.spa),
      ],
    ),
    CategoryData(
      id: 'room_service',
      icon: Icons.room_service,
      title: 'Room Service',
      amount: 188.40 + _roomServiceOrdersTotal,
      transactions: [
        TransactionData('Breakfast Delivery', 42.00, DateTime(2025, 11, 27, 7, 45), 'Room Service', Icons.room_service),
        TransactionData('Evening Snacks & Drinks', 146.40, DateTime(2025, 11, 26, 22, 30), 'Room Service', Icons.room_service),
        ..._roomServiceOrders,
      ],
    ),
    CategoryData(
      id: 'minibar',
      icon: Icons.local_bar,
      title: 'Minibar',
      amount: 124.51,
      transactions: [
        TransactionData('Water & Soft Drinks', 18.00, DateTime(2025, 11, 27, 10, 0), 'Minibar', Icons.local_bar),
        TransactionData('Wine Selection', 65.00, DateTime(2025, 11, 25, 19, 30), 'Minibar', Icons.local_bar),
        TransactionData('Snacks & Chocolates', 24.51, DateTime(2025, 11, 27, 14, 20), 'Minibar', Icons.local_bar),
        TransactionData('Premium Spirits', 17.00, DateTime(2025, 11, 23, 21, 0), 'Minibar', Icons.local_bar),
      ],
    ),
  ];
}

class CategoryData {
  final String id;
  final IconData icon;
  final String title;
  final double amount;
  final List<TransactionData> transactions;
  const CategoryData({
    required this.id,
    required this.icon,
    required this.title,
    required this.amount,
    required this.transactions,
  });
}

class TransactionData {
  final String description;
  final double amount;
  final DateTime dateTime;
  final String category;
  final IconData categoryIcon;
  const TransactionData(this.description, this.amount, this.dateTime, this.category, this.categoryIcon);
}

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String? _expandedCategory;
  String _selectedFilter = 'this_stay'; // 'this_stay' or 'last_24h'

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Spending'),
        centerTitle: true,
        scrolledUnderElevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _BalanceCard(),
          const SizedBox(height: 16),
          _TimeFilterChips(
            selectedFilter: _selectedFilter,
            onFilterChanged: (filter) {
              setState(() {
                _selectedFilter = filter;
                _expandedCategory = null;
              });
            },
          ),
          const SizedBox(height: 16),
          if (_selectedFilter == 'this_stay')
            _SpendingBreakdown(
              expandedCategory: _expandedCategory,
              onCategoryTap: (category) {
                setState(() {
                  _expandedCategory = _expandedCategory == category ? null : category;
                });
              },
            )
          else
            const _Last24HoursView(),
        ],
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard();
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF00B4DB), Color(0xFF0083B0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 12, offset: const Offset(0, 6)),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Current Balance', style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 8),
          Text('\$${SpendingData.totalBalance.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('${SpendingData.guestName}, Room ${SpendingData.roomNumber}', style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 12),
            Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.credit_card),
                  label: const Text('Settle Full Bill'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF0083B0),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Ink(
                decoration: const ShapeDecoration(
                  color: Colors.white,
                  shape: CircleBorder(),
                ),
                child: IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.copy_rounded),
                  color: const Color(0xFF0083B0),
                ),
              )
            ],
          ),
        ],
      ),
    );
  }
}

class _TimeFilterChips extends StatelessWidget {
  final String selectedFilter;
  final ValueChanged<String> onFilterChanged;

  const _TimeFilterChips({
    required this.selectedFilter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: () => onFilterChanged('this_stay'),
          child: _Chip('This Stay', selected: selectedFilter == 'this_stay'),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () => onFilterChanged('last_24h'),
          child: _Chip('Last 24 Hours', selected: selectedFilter == 'last_24h'),
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  const _Chip(this.label, {this.selected = false});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFFEAF4FF) : Colors.grey[100],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: selected ? const Color(0xFF1677FF) : Colors.black12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: selected ? const Color(0xFF1677FF) : Colors.black87,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _SpendingBreakdown extends StatelessWidget {
  final String? expandedCategory;
  final ValueChanged<String> onCategoryTap;

  const _SpendingBreakdown({
    required this.expandedCategory,
    required this.onCategoryTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Spending Breakdown', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        for (final cat in SpendingData.categories) ...[
          _BreakdownItem(
            icon: cat.icon,
            title: cat.title,
            subtitle: '${cat.transactions.length} transaction${cat.transactions.length > 1 ? 's' : ''}',
            amount: '\$${cat.amount.toStringAsFixed(2)}',
            isExpanded: expandedCategory == cat.id,
            onTap: () => onCategoryTap(cat.id),
          ),
          if (expandedCategory == cat.id)
            _TransactionList(transactions: cat.transactions),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _TransactionList extends StatelessWidget {
  final List<TransactionData> transactions;
  const _TransactionList({required this.transactions});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 20, top: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        children: [
          for (int i = 0; i < transactions.length; i++) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    transactions[i].description,
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
                Text(
                  '\$${transactions[i].amount.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ],
            ),
            if (i < transactions.length - 1)
              const Divider(height: 16),
          ],
        ],
      ),
    );
  }
}

class _BreakdownItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String amount;
  final bool isExpanded;
  final VoidCallback onTap;

  const _BreakdownItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.amount,
    this.isExpanded = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isExpanded ? const Color(0xFFEAF4FF) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 4))],
          border: isExpanded ? Border.all(color: const Color(0xFF1677FF)) : null,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isExpanded ? Colors.white : Colors.grey[100],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: const Color(0xFF1677FF)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(color: Colors.black54, fontSize: 12)),
                ],
              ),
            ),
            Text(amount, style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(width: 8),
            Icon(
              isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
              color: Colors.black54,
            ),
          ],
        ),
      ),
    );
  }
}

class _Last24HoursView extends StatelessWidget {
  const _Last24HoursView();

  List<TransactionData> _getLast24HoursTransactions() {
    final now = DateTime(2025, 11, 27, 23, 59);
    final yesterday = now.subtract(const Duration(hours: 24));
    
    final allTransactions = <TransactionData>[];
    for (final cat in SpendingData.categories) {
      allTransactions.addAll(cat.transactions);
    }
    
    final filtered = allTransactions
        .where((t) => t.dateTime.isAfter(yesterday))
        .toList();
    
    filtered.sort((a, b) => b.dateTime.compareTo(a.dateTime));
    
    return filtered;
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _formatDate(DateTime dt) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[dt.month - 1]} ${dt.day}';
  }

  @override
  Widget build(BuildContext context) {
    final transactions = _getLast24HoursTransactions();
    final total = transactions.fold(0.0, (sum, t) => sum + t.amount);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Last 24 Hours', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            Text(
              '\$${total.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1677FF)),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '${transactions.length} transaction${transactions.length != 1 ? 's' : ''}',
          style: const TextStyle(color: Colors.black54, fontSize: 13),
        ),
        const SizedBox(height: 12),
        if (transactions.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Text('No transactions in the last 24 hours', style: TextStyle(color: Colors.black54)),
            ),
          )
        else
          for (final t in transactions) ...[
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 4))],
              ),
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF4FF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(t.categoryIcon, color: const Color(0xFF1677FF), size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(t.description, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                        const SizedBox(height: 4),
                        Text(
                          '${t.category} • ${_formatDate(t.dateTime)}, ${_formatTime(t.dateTime)}',
                          style: const TextStyle(color: Colors.black54, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '\$${t.amount.toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
      ],
    );
  }
}
