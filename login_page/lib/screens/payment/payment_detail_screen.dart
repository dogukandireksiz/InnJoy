import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Timestamp için gerekli
import '../../service/database_service.dart';

class PaymentDetailScreen extends StatefulWidget {
  const PaymentDetailScreen({Key? key}) : super(key: key);

  @override
  _PaymentDetailScreenState createState() => _PaymentDetailScreenState();
}

class _PaymentDetailScreenState extends State<PaymentDetailScreen> {
  // 0: This Stay (Hepsi), 1: Last 24 Hours (Filtreli)
  int _selectedFilterIndex = 0; 

  // Kullanıcı bilgisini al
  final User? user = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    String displayName = user?.displayName ?? user?.email ?? "Misafir";
    String roomInfo = "Room 101"; 

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Spending", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: DatabaseService().getOrderHistory(),
        builder: (context, snapshot) {
          
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // 1. TÜM SİPARİŞLERİ HAM OLARAK AL
          final allOrders = snapshot.data ?? [];
          
          // 2. FİLTRELEME MANTIĞI
          List<Map<String, dynamic>> displayedOrders = [];

          if (_selectedFilterIndex == 0) {
            // "This Stay" seçiliyse hepsini göster
            displayedOrders = allOrders;
          } else {
            // "Last 24 Hours" seçiliyse filtrele
            final now = DateTime.now();
            final yesterday = now.subtract(const Duration(hours: 24));

            displayedOrders = allOrders.where((order) {
              // Timestamp kontrolü
              if (order['timestamp'] != null && order['timestamp'] is Timestamp) {
                DateTime orderDate = (order['timestamp'] as Timestamp).toDate();
                return orderDate.isAfter(yesterday); // Dünden sonraysa listeye ekle
              }
              return false; // Tarihi olmayanları gösterme
            }).toList();
          }
          
          // 3. EKRANDA GÖSTERİLECEK TUTARI HESAPLA (Filtrelenmiş listeye göre)
          double totalBalance = 0;
          for (var order in displayedOrders) {
             if (order['totalPrice'] != null) {
               var p = order['totalPrice'];
               if (p is int) totalBalance += p.toDouble();
               else if (p is double) totalBalance += p;
               else if (p is String) totalBalance += double.tryParse(p) ?? 0.0;
             }
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- YEŞİL KART ---
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(25),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF009688), Color(0xFF00796B)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.teal.withOpacity(0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Current Balance",
                            style: TextStyle(color: Colors.white70, fontSize: 16),
                          ),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.account_balance_wallet, color: Colors.white, size: 20),
                          )
                        ],
                      ),
                      const SizedBox(height: 10),
                      
                      // TUTAR (Filtreye göre değişir)
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: Text(
                          "\$${totalBalance.toStringAsFixed(2)}",
                          key: ValueKey<double>(totalBalance), // Animasyon için key
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 42,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 5),
                      Text(
                        "$displayName, $roomInfo",
                        style: const TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      const SizedBox(height: 25),
                      
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Ödeme ekranına yönlendiriliyor..."))
                            );
                          },
                          icon: const Icon(Icons.credit_card, color: Color(0xFF00796B)),
                          label: const Text(
                            "Settle Full Bill", 
                            style: TextStyle(color: Color(0xFF00796B), fontWeight: FontWeight.bold, fontSize: 16)
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                            elevation: 0,
                          ),
                        ),
                      )
                    ],
                  ),
                ),

                const SizedBox(height: 25),
                
                // --- FİLTRE BUTONLARI ---
                Row(
                  children: [
                    _buildFilterButton("This Stay", 0),
                    const SizedBox(width: 15),
                    _buildFilterButton("Last 24 Hours", 1),
                  ],
                ),

                const SizedBox(height: 25),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Spending Breakdown", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                    // Küçük bir bilgi yazısı
                    Text(
                      _selectedFilterIndex == 0 ? "Tüm Harcamalar" : "Son 24 Saat",
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    )
                  ],
                ),
                const SizedBox(height: 15),

                // --- HARCAMA LİSTESİ (FİLTRELİ) ---
                displayedOrders.isEmpty 
                  ? Container(
                      padding: const EdgeInsets.all(40),
                      alignment: Alignment.center,
                      child: Column(
                        children: [
                          Icon(Icons.history_toggle_off, size: 50, color: Colors.grey[300]),
                          const SizedBox(height: 10),
                          Text(
                            _selectedFilterIndex == 1 
                                ? "Son 24 saatte harcama yok." 
                                : "Harcama kaydı bulunamadı.", 
                            style: TextStyle(color: Colors.grey[500])
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: displayedOrders.length,
                      itemBuilder: (context, index) {
                        final order = displayedOrders[index];
                        
                        // Fiyat Çekme
                        double price = 0;
                        if (order['totalPrice'] != null) {
                           var p = order['totalPrice'];
                           if (p is int) price = p.toDouble();
                           else if (p is double) price = p;
                           else if (p is String) price = double.tryParse(p) ?? 0.0;
                        }

                        // Veri Analizi
                        String title = "Harcama";
                        String subtitle = "Genel İşlem";
                        IconData icon = Icons.receipt;
                        Color iconColor = Colors.blue;
                        Color iconBg = Colors.blue.shade50;

                        if (order['items'] != null && (order['items'] as List).isNotEmpty) {
                          var firstItem = order['items'][0];
                          title = firstItem['name'] ?? 'Hizmet';
                          int itemCount = (order['items'] as List).length;
                          subtitle = itemCount > 1 ? "$itemCount kalem ürün" : "Harcama";
                          
                          String cat = (firstItem['category'] ?? '').toString().toLowerCase();
                          
                          if (cat.contains('food') || cat.contains('drink')) { 
                            icon = Icons.restaurant; 
                            iconColor = Colors.teal;
                            iconBg = Colors.teal.shade50;
                            subtitle = "Dining & Restaurants";
                          }
                          else if (cat.contains('spa')) { 
                            icon = Icons.spa; 
                            iconColor = Colors.purple; 
                            iconBg = Colors.purple.shade50;
                            subtitle = "Spa & Wellness";
                          }
                          else if (cat.contains('room')) { 
                            icon = Icons.room_service; 
                            iconColor = Colors.orange; 
                            iconBg = Colors.orange.shade50;
                            subtitle = "Room Service";
                          }
                        } else if (order['serviceName'] != null) {
                           title = order['serviceName'];
                           subtitle = "Spa & Wellness";
                           icon = Icons.spa;
                           iconColor = Colors.purple;
                           iconBg = Colors.purple.shade50;
                        }

                        return Container(
                          margin: const EdgeInsets.only(bottom: 15),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
                            ],
                            border: Border.all(color: Colors.grey.shade100),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: iconBg,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(icon, color: iconColor, size: 24),
                              ),
                              const SizedBox(width: 15),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                    const SizedBox(height: 4),
                                    Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                                  ],
                                ),
                              ),
                              Text(
                                "\$${price.toStringAsFixed(2)}",
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.chevron_right, color: Colors.grey, size: 20)
                            ],
                          ),
                        );
                      },
                    ),
              ],
            ),
          );
        },
      ),
    );
  }

  // Filtre Butonu Tasarımı
  Widget _buildFilterButton(String text, int index) {
    bool isSelected = _selectedFilterIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilterIndex = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE0F2F1) : Colors.transparent, // Seçiliyse Açık Yeşil
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: isSelected ? Colors.transparent : Colors.grey.shade300,
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isSelected ? const Color(0xFF00796B) : Colors.grey[600],
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}