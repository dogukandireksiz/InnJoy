
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../service/database_service.dart';
import '../../model/menu_item_model.dart';

class RoomServiceCartScreen extends StatefulWidget {
  final String hotelName;
  final Map<MenuItem, int> cart;
  final ValueChanged<Map<MenuItem, int>> onCartUpdated;
  final VoidCallback onOrderPlaced;

  const RoomServiceCartScreen({
    super.key,
    required this.hotelName,
    required this.cart,
    required this.onCartUpdated,
    required this.onOrderPlaced,
  });

  @override
  State<RoomServiceCartScreen> createState() => _RoomServiceCartScreenState();
}

class _RoomServiceCartScreenState extends State<RoomServiceCartScreen> {
  late Map<MenuItem, int> _currentCart;
  bool _isPlacingOrder = false;
  final TextEditingController _noteController = TextEditingController();
  
  // Delivery Info State
  String _roomNumber = 'Loading...';
  String _guestName = 'Loading...';

  @override
  void initState() {
    super.initState();
    _currentCart = Map.from(widget.cart);
    _fetchUserInfo();
  }

  Future<void> _fetchUserInfo() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userData = await DatabaseService().getUser(user.uid);
      if (mounted && userData != null) {
        setState(() {
          _roomNumber = userData['roomNumber'] ?? 'Unknown';
          _guestName = userData['name_username'] ?? 'Guest';
        });
      }
    }
  }

  double get _subtotal => _currentCart.entries.fold(0.0, (sum, e) => sum + (e.key.price * e.value));
  double get _totalPrice => _subtotal;

  void _updateQuantity(MenuItem item, int change) {
    setState(() {
      final currentQty = _currentCart[item] ?? 0;
      final newQty = currentQty + change;
      if (newQty <= 0) {
        _currentCart.remove(item);
      } else {
        _currentCart[item] = newQty;
      }
      widget.onCartUpdated(_currentCart);
    });
  }

  Future<void> _placeOrder() async {
    setState(() => _isPlacingOrder = true);
    try {
      final List<Map<String, dynamic>> orderItems = _currentCart.entries.map((e) {
        return {
          'name': e.key.name, 
          'quantity': e.value, 
          'price': e.key.price,
          'imageUrl': e.key.imageUrl 
        };
      }).toList();

      await DatabaseService().placeRoomServiceOrder(
        widget.hotelName,
        _roomNumber,
        _guestName,
        orderItems,
        _totalPrice,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Your order has been placed!"), backgroundColor: Colors.green),
        );
        widget.onOrderPlaced();
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isPlacingOrder = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        title: const Text('Confirm Order', style: TextStyle(color: Color(0xFF0d141b), fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: const Color(0xFFF6F7FB),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF0d141b)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   // 1. Delivery Info
                   _buildSectionTitle('Delivery Information'),
                   _buildDeliveryInfoCard(),
                   
                   // 2. Order List
                   _buildSectionTitle('Order List'),
                   if (_currentCart.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                        child: const Column(
                          children: [
                             Icon(Icons.shopping_cart_outlined, size: 48, color: Colors.grey),
                             SizedBox(height: 12),
                             Text("Your cart is empty.", style: TextStyle(color: Colors.grey, fontSize: 16)),
                          ],
                        ),
                      )
                   else
                      ..._currentCart.entries.map((e) => _buildCartItem(e.key, e.value)),


                   // 3. Note
                   _buildSectionTitle('Order Notes'),
                   _buildNoteSection(),

                   // 4. Payment Method
                   _buildSectionTitle('Payment Method'),
                   _buildPaymentMethodSection(),

                   // 5. Summary
                   _buildSectionTitle('Order Summary'),
                   _buildWebSummaryCard(),
                ],
              ),
            ),
       bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          color: Color(0xFF0d141b),
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildDeliveryInfoCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)],
      ),
      child: Column(
        children: [
          _buildInfoRow(Icons.meeting_room, 'Room Number', _roomNumber),
          const Divider(height: 1, indent: 60),
          _buildInfoRow(Icons.person, 'Guest Name', _guestName),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: const Color(0xFF0d141b)),
          ),
          const SizedBox(width: 16),
          Expanded(child: Text(label, style: const TextStyle(color: Colors.grey))),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildCartItem(MenuItem item, int qty) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)],
      ),
      child: Row(
        children: [
          // Image
          Container(
            width: 70, 
            height: 70,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              image: item.imageUrl.isNotEmpty 
                  ? DecorationImage(image: NetworkImage(item.imageUrl), fit: BoxFit.cover)
                  : null,
              color: Colors.grey[200],
            ),
            child: item.imageUrl.isEmpty ? const Icon(Icons.fastfood, color: Colors.grey) : null,
          ),
          const SizedBox(width: 12),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text(
                  '${item.price}₺', 
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0d141b)),
                ),
              ],
            ),
          ),
          // Qty Control
          Row(
            children: [
              _buildQtyBtn(Icons.remove, () => _updateQuantity(item, -1)),
              SizedBox(width: 30, child: Center(child: Text('$qty', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)))),
              _buildQtyBtn(Icons.add, () => _updateQuantity(item, 1), isPrimary: true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQtyBtn(IconData icon, VoidCallback onTap, {bool isPrimary = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: isPrimary ? const Color(0xFF137fec) : Colors.grey[100],
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 18, color: isPrimary ? Colors.white : Colors.black),
      ),
    );
  }

  Widget _buildNoteSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        controller: _noteController,
        maxLines: 3,
        decoration: InputDecoration(
          hintText: 'Do you have any special requests or need extra napkins?',
          hintStyle: TextStyle(color: Colors.grey[400]),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.all(16),
        ),
      ),
    );
  }

  Widget _buildPaymentMethodSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          _buildRadioOption('room_charge', Icons.receipt_long, 'Charge to Room', 'Will be added to your total bill at checkout.'),
        ],
      ),
    );
  }

  Widget _buildRadioOption(String value, IconData icon, String title, String subtitle) {
    // Only one option, so it's always selected (groupValue matches value)
    return RadioListTile(
      value: value,
      groupValue: value, // Always selected
      onChanged: null, // Read-only
      activeColor: const Color(0xFF137fec),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 14, color: Colors.black87)),
      secondary: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: const Color(0xFF137fec).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: const Color(0xFF137fec)),
      ),
    );
  }

  Widget _buildWebSummaryCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _buildSummaryRow('Subtotal', _subtotal),
          const Divider(height: 24),
          _buildSummaryRow('Total Amount', _totalPrice, isTotal: true),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, double amount, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: isTotal ? 18 : 14, fontWeight: isTotal ? FontWeight.bold : FontWeight.w500, color: isTotal ? Colors.black : Colors.grey)),
          Text('${amount.toStringAsFixed(2)}₺', style: TextStyle(fontSize: isTotal ? 18 : 14, fontWeight: isTotal ? FontWeight.bold : FontWeight.w500, color: isTotal ? const Color(0xFF137fec) : Colors.black)),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
      ),
      child: SafeArea(
        child: ElevatedButton(
          onPressed: _currentCart.isEmpty || _isPlacingOrder ? null : _placeOrder,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF137fec),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 4,
          ),
          child: _isPlacingOrder 
              ? const CircularProgressIndicator(color: Colors.white)
              : Text('Place Order • ${_totalPrice.toStringAsFixed(2)}₺', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
        ),
      ),
    );
  }
}
