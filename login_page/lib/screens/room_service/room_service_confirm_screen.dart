import 'package:flutter/material.dart';
import 'package:login_page/l10n/app_localizations.dart'; // Çeviri paketi
import 'menu_data.dart';
import '../payment/payment_screen.dart';

class RoomServiceConfirmScreen extends StatefulWidget {
  final Map<MenuItem, int> cart;
  final double subtotal;
  final double discount;
  final double serviceCharge;
  final double total;
  final VoidCallback onOrderPlaced;

  const RoomServiceConfirmScreen({
    super.key,
    required this.cart,
    required this.subtotal,
    required this.discount,
    required this.serviceCharge,
    required this.total,
    required this.onOrderPlaced,
  });

  @override
  State<RoomServiceConfirmScreen> createState() =>
      _RoomServiceConfirmScreenState();
}

class _RoomServiceConfirmScreenState extends State<RoomServiceConfirmScreen> {
  final TextEditingController _noteController = TextEditingController();

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _confirmOrder(AppLocalizations texts) {
    // Siparişleri SpendingData'ya ekle
    for (final entry in widget.cart.entries) {
      final item = entry.key;
      final quantity = entry.value;
      final itemTotal = item.price * quantity;
      SpendingData.addRoomServiceOrder('${item.name} x$quantity', itemTotal);
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 28),
            const SizedBox(width: 8),
            Text(texts.orderConfirmedTitle), // "Sipariş Onaylandı"
          ],
        ),
        content: Text(
          texts.orderConfirmedMsg, // "35-45 dakika içinde..."
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Dialog kapat
              widget.onOrderPlaced();
              Navigator.pop(context); // Confirm ekranından çık
              Navigator.pop(context); // Cart ekranından çık
            },
            child: Text(texts.okButton), // "Tamam"
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final texts = AppLocalizations.of(context)!;

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
        title: Text(
          texts.confirmOrderTitle, // "Siparişi Onayla"
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Teslimat Bilgisi
            Text(
              texts.deliveryInfo, // "Teslimat Bilgisi"
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),

            // Oda Numarası
            _InfoRow(
              icon: Icons.door_front_door_outlined,
              label: texts.roomNumber, // "Oda Numarası"
              value: '1204',
            ),
            const SizedBox(height: 12),

            // Misafir Adı
            _InfoRow(
              icon: Icons.person_outline,
              label: texts.guestName, // "Misafir Adı"
              value: 'Ali Veli', // Dinamik kalacak
            ),

            const SizedBox(height: 24),

            // Teslimat Notu
            Text(
              texts.deliveryNote, // "Teslimat Notu"
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: TextField(
                controller: _noteController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: texts.deliveryNoteHint, // "Ekstra peçete..."
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Tahmini Süre
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFE3F2FD),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.access_time,
                      color: Color(0xFF1677FF),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          texts.estimatedTime, // "Tahmini Süre"
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            color: Color(0xFF1677FF),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          texts.estimatedTimeMsg, // "35-45 dakika..."
                          style: const TextStyle(
                            color: Colors.black54,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Ödeme Bilgilendirmesi
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8E1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFFB300)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.info_outline,
                      color: Color(0xFFFFB300),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          texts.paymentInfo, // "Ödeme Bilgisi"
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            color: Color(0xFFE65100),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          // Dinamik metin: "Sipariş tutarı (500 TL) oda hesabınıza..."
                          texts.paymentInfoMsg(
                            '${widget.total.toStringAsFixed(2)}₺',
                          ),
                          style: const TextStyle(
                            color: Colors.black87,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 100),
          ],
        ),
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
          child: ElevatedButton(
            onPressed: () => _confirmOrder(texts), // texts parametresi eklendi
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1677FF),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              texts.placeOrderButton, // "Sipariş Ver ve Onayla"
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey[600], size: 22),
        const SizedBox(width: 12),
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 15)),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ],
    );
  }
}
