// import 'package:flutter/material.dart';
// import 'menu_data.dart';
// import 'room_service_confirm_screen.dart';

// class RoomServiceCartScreen extends StatefulWidget {
//   final Map<MenuItem, int> cart;
//   final ValueChanged<Map<MenuItem, int>> onCartUpdated;
//   final VoidCallback onOrderPlaced;

//   const RoomServiceCartScreen({
//     super.key,
//     required this.cart,
//     required this.onCartUpdated,
//     required this.onOrderPlaced,
//   });

//   @override
//   State<RoomServiceCartScreen> createState() => _RoomServiceCartScreenState();
// }

// class _RoomServiceCartScreenState extends State<RoomServiceCartScreen> {
//   late Map<MenuItem, int> _cart;
//   final TextEditingController _noteController = TextEditingController();
  
//   // Fiyatlandırma
//   static const double _serviceCharge = 35.0;
//   static const double _discount = 20.0;

//   @override
//   void initState() {
//     super.initState();
//     _cart = Map.from(widget.cart);
//   }

//   @override
//   void dispose() {
//     _noteController.dispose();
//     super.dispose();
//   }

//   double get _subtotal => _cart.entries.fold(0.0, (sum, e) => sum + (e.key.price * e.value));
//   double get _total => _subtotal - _discount + _serviceCharge;

//   void _addItem(MenuItem item) {
//     setState(() {
//       _cart[item] = (_cart[item] ?? 0) + 1;
//     });
//     widget.onCartUpdated(_cart);
//   }

//   void _removeItem(MenuItem item) {
//     setState(() {
//       if (_cart[item] != null && _cart[item]! > 1) {
//         _cart[item] = _cart[item]! - 1;
//       } else {
//         _cart.remove(item);
//       }
//     });
//     widget.onCartUpdated(_cart);
//   }

//   void _goToConfirm() {
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (_) => RoomServiceConfirmScreen(
//           cart: _cart,
//           subtotal: _subtotal,
//           discount: _discount,
//           serviceCharge: _serviceCharge,
//           total: _total,
//           onOrderPlaced: () {
//             widget.onOrderPlaced();
//           },
//         ),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFF6F7FB),
//       appBar: AppBar(
//         backgroundColor: Colors.white,
//         elevation: 0,
//         scrolledUnderElevation: 0,
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back_ios, color: Colors.black87),
//           onPressed: () => Navigator.pop(context),
//         ),
//         title: const Text(
//           'Sipariş Sepeti',
//           style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600),
//         ),
//         centerTitle: true,
//       ),
//       body: _cart.isEmpty
//           ? _buildEmptyCart()
//           : Column(
//               children: [
//                 Expanded(
//                   child: SingleChildScrollView(
//                     padding: const EdgeInsets.all(16),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         // Sipariş Listesi Başlık
//                         const Text(
//                           'Sipariş Listesi',
//                           style: TextStyle(
//                             fontSize: 18,
//                             fontWeight: FontWeight.w600,
//                           ),
//                         ),
//                         const SizedBox(height: 16),
                        
//                         // Sipariş Öğeleri
//                         ..._cart.entries.map((entry) => _CartItemCard(
//                           item: entry.key,
//                           quantity: entry.value,
//                           onAdd: () => _addItem(entry.key),
//                           onRemove: () => _removeItem(entry.key),
//                         )),
                        
//                         const SizedBox(height: 24),
                        
//                         // Sipariş Notu
//                         const Text(
//                           'Sipariş Notunuz',
//                           style: TextStyle(
//                             fontSize: 16,
//                             fontWeight: FontWeight.w600,
//                           ),
//                         ),
//                         const SizedBox(height: 12),
//                         Container(
//                           decoration: BoxDecoration(
//                             color: Colors.white,
//                             borderRadius: BorderRadius.circular(12),
//                             border: Border.all(color: Colors.grey[300]!),
//                           ),
//                           child: TextField(
//                             controller: _noteController,
//                             maxLines: 3,
//                             decoration: InputDecoration(
//                               hintText: 'Alerjiler veya özel talepleriniz için...',
//                               hintStyle: TextStyle(color: Colors.grey[400]),
//                               border: InputBorder.none,
//                               contentPadding: const EdgeInsets.all(16),
//                             ),
//                           ),
//                         ),
                        
//                         const SizedBox(height: 24),
                        
//                         // Toplam Hesap Özeti
//                         const Text(
//                           'Toplam Hesap Özeti',
//                           style: TextStyle(
//                             fontSize: 16,
//                             fontWeight: FontWeight.w600,
//                           ),
//                         ),
//                         const SizedBox(height: 12),
//                         Container(
//                           padding: const EdgeInsets.all(16),
//                           decoration: BoxDecoration(
//                             color: Colors.white,
//                             borderRadius: BorderRadius.circular(12),
//                           ),
//                           child: Column(
//                             children: [
//                               _PriceRow(label: 'Alt Toplam', amount: _subtotal),
//                               const SizedBox(height: 12),
//                               _PriceRow(
//                                 label: 'İndirimler',
//                                 amount: -_discount,
//                                 isDiscount: true,
//                               ),
//                               const SizedBox(height: 12),
//                               _PriceRow(label: 'Servis Ücreti', amount: _serviceCharge),
//                               const Padding(
//                                 padding: EdgeInsets.symmetric(vertical: 12),
//                                 child: Divider(),
//                               ),
//                               Row(
//                                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                                 children: [
//                                   const Text(
//                                     'Ödenecek Toplam Tutar',
//                                     style: TextStyle(
//                                       fontWeight: FontWeight.w600,
//                                       fontSize: 15,
//                                     ),
//                                   ),
//                                   Text(
//                                     '₺${_total.toStringAsFixed(2)}',
//                                     style: const TextStyle(
//                                       fontWeight: FontWeight.w700,
//                                       fontSize: 20,
//                                       color: Color(0xFF1677FF),
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                             ],
//                           ),
//                         ),
                        
//                         const SizedBox(height: 100), // Bottom button için boşluk
//                       ],
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//       bottomNavigationBar: _cart.isNotEmpty
//           ? Container(
//               padding: const EdgeInsets.all(16),
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 boxShadow: [
//                   BoxShadow(
//                     color: Colors.black.withOpacity(0.05),
//                     blurRadius: 10,
//                     offset: const Offset(0, -2),
//                   ),
//                 ],
//               ),
//               child: SafeArea(
//                 child: ElevatedButton(
//                   onPressed: _goToConfirm,
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: const Color(0xFF1677FF),
//                     padding: const EdgeInsets.symmetric(vertical: 16),
//                     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//                   ),
//                   child: const Text(
//                     'Devam Et',
//                     style: TextStyle(
//                       color: Colors.white,
//                       fontSize: 16,
//                       fontWeight: FontWeight.w600,
//                     ),
//                   ),
//                 ),
//               ),
//             )
//           : null,
//     );
//   }

//   Widget _buildEmptyCart() {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(
//             Icons.shopping_cart_outlined,
//             size: 80,
//             color: Colors.grey[300],
//           ),
//           const SizedBox(height: 16),
//           Text(
//             'Sepetiniz boş',
//             style: TextStyle(
//               fontSize: 18,
//               fontWeight: FontWeight.w600,
//               color: Colors.grey[600],
//             ),
//           ),
//           const SizedBox(height: 8),
//           Text(
//             'Menüden ürün ekleyerek başlayın',
//             style: TextStyle(
//               color: Colors.grey[500],
//             ),
//           ),
//           const SizedBox(height: 24),
//           ElevatedButton(
//             onPressed: () => Navigator.pop(context),
//             style: ElevatedButton.styleFrom(
//               backgroundColor: const Color(0xFF1677FF),
//               padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
//               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//             ),
//             child: const Text(
//               'Menüye Dön',
//               style: TextStyle(color: Colors.white),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _CartItemCard extends StatelessWidget {
//   final MenuItem item;
//   final int quantity;
//   final VoidCallback onAdd;
//   final VoidCallback onRemove;

//   const _CartItemCard({
//     required this.item,
//     required this.quantity,
//     required this.onAdd,
//     required this.onRemove,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       margin: const EdgeInsets.only(bottom: 12),
//       padding: const EdgeInsets.all(12),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(12),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.03),
//             blurRadius: 8,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: Row(
//         children: [
//           // Ürün görseli
//           Container(
//             width: 70,
//             height: 70,
//             decoration: BoxDecoration(
//               color: Colors.grey[100],
//               borderRadius: BorderRadius.circular(10),
//             ),
//             child: Center(
//               child: Icon(
//                 getIconForItem(item.name),
//                 size: 32,
//                 color: Colors.grey[400],
//               ),
//             ),
//           ),
//           const SizedBox(width: 12),
          
//           // Ürün bilgileri
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     Expanded(
//                       child: Text(
//                         item.name,
//                         style: const TextStyle(
//                           fontWeight: FontWeight.w600,
//                           fontSize: 15,
//                         ),
//                       ),
//                     ),
//                     Text(
//                       '${item.price.toStringAsFixed(2)}₺',
//                       style: const TextStyle(
//                         fontWeight: FontWeight.w600,
//                         fontSize: 15,
//                       ),
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 4),
//                 Text(
//                   item.description,
//                   style: TextStyle(
//                     color: Colors.grey[500],
//                     fontSize: 12,
//                   ),
//                   maxLines: 1,
//                   overflow: TextOverflow.ellipsis,
//                 ),
//                 const SizedBox(height: 8),
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     // Not Ekle butonu
//                     GestureDetector(
//                       onTap: () {
//                         // Not ekleme işlevi
//                       },
//                       child: const Text(
//                         'Not Ekle',
//                         style: TextStyle(
//                           color: Color(0xFF1677FF),
//                           fontSize: 13,
//                           fontWeight: FontWeight.w500,
//                         ),
//                       ),
//                     ),
//                     // Miktar kontrolleri
//                     Row(
//                       children: [
//                         GestureDetector(
//                           onTap: onRemove,
//                           child: Container(
//                             padding: const EdgeInsets.all(4),
//                             decoration: BoxDecoration(
//                               color: Colors.grey[100],
//                               borderRadius: BorderRadius.circular(6),
//                             ),
//                             child: const Icon(Icons.remove, size: 18, color: Colors.black54),
//                           ),
//                         ),
//                         Padding(
//                           padding: const EdgeInsets.symmetric(horizontal: 12),
//                           child: Text(
//                             '$quantity',
//                             style: const TextStyle(
//                               fontWeight: FontWeight.w600,
//                               fontSize: 15,
//                             ),
//                           ),
//                         ),
//                         GestureDetector(
//                           onTap: onAdd,
//                           child: Container(
//                             padding: const EdgeInsets.all(4),
//                             decoration: BoxDecoration(
//                               color: const Color(0xFF1677FF),
//                               borderRadius: BorderRadius.circular(6),
//                             ),
//                             child: const Icon(Icons.add, size: 18, color: Colors.white),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _PriceRow extends StatelessWidget {
//   final String label;
//   final double amount;
//   final bool isDiscount;

//   const _PriceRow({
//     required this.label,
//     required this.amount,
//     this.isDiscount = false,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//       children: [
//         Text(
//           label,
//           style: TextStyle(
//             color: Colors.grey[600],
//             fontSize: 14,
//           ),
//         ),
//         Text(
//           '${isDiscount ? '' : ''}${amount.toStringAsFixed(2)}₺',
//           style: TextStyle(
//             fontWeight: FontWeight.w500,
//             fontSize: 14,
//             color: isDiscount ? Colors.green : Colors.black87,
//           ),
//         ),
//       ],
//     );
//   }
// }


import 'package:flutter/material.dart';
import '../../model/menu_item_model.dart'; // Model dosyanın yolu burası olmalı

class RoomServiceCartScreen extends StatefulWidget {
  // Senin _goToCart fonksiyonunun göndermek istediği parametreler bunlar:
  final Map<MenuItem, int> cart;
  final ValueChanged<Map<MenuItem, int>> onCartUpdated;
  final VoidCallback onOrderPlaced;

  const RoomServiceCartScreen({
    super.key,
    required this.cart,
    required this.onCartUpdated,
    required this.onOrderPlaced,
  });

  @override
  State<RoomServiceCartScreen> createState() => _RoomServiceCartScreenState();
}

class _RoomServiceCartScreenState extends State<RoomServiceCartScreen> {
  late Map<MenuItem, int> _currentCart;

  @override
  void initState() {
    super.initState();
    // Gelen sepeti kopyala ki üzerinde rahatça değişiklik yapabilelim
    _currentCart = Map.from(widget.cart);
  }

  // Toplam fiyat hesaplama
  double get _totalPrice => _currentCart.entries.fold(0.0, (sum, e) => sum + (e.key.price * e.value));

  void _placeOrder() {
    // Burada ileride veritabanı işlemi yapılacak
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Siparişiniz alındı!"), backgroundColor: Colors.green),
    );
    
    // Ana sayfaya "Sipariş verildi, sepeti temizle" emrini gönder
    widget.onOrderPlaced();
    
    // Sayfayı kapat
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Sepetim")),
      body: _currentCart.isEmpty
          ? const Center(child: Text("Sepetiniz boş"))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _currentCart.length,
              itemBuilder: (context, index) {
                final item = _currentCart.keys.elementAt(index);
                final quantity = _currentCart[item]!;
                
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: item.imageUrl.isNotEmpty 
                      ? Image.network(item.imageUrl, width: 50, height: 50, fit: BoxFit.cover)
                      : const Icon(Icons.fastfood),
                    title: Text(item.name),
                    subtitle: Text("${item.price} TL x $quantity"),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text("${(item.price * quantity).toStringAsFixed(2)} TL", 
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                          onPressed: () {
                            setState(() {
                              if (quantity > 1) {
                                _currentCart[item] = quantity - 1;
                              } else {
                                _currentCart.remove(item);
                              }
                              // Değişikliği anında ana sayfaya bildir
                              widget.onCartUpdated(_currentCart);
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            onPressed: _currentCart.isEmpty ? null : _placeOrder,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1677FF),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: Text(
              "Siparişi Tamamla (₺${_totalPrice.toStringAsFixed(2)})", 
              style: const TextStyle(color: Colors.white, fontSize: 18)
            ),
          ),
        ),
      ),
    );
  }
}