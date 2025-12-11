import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../service/database_service.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart'; // EKLENDİ

class AdminRoomManagementScreen extends StatefulWidget {
  final String hotelName;

  const AdminRoomManagementScreen({super.key, required this.hotelName});

  @override
  State<AdminRoomManagementScreen> createState() => _AdminRoomManagementScreenState();
}

class _AdminRoomManagementScreenState extends State<AdminRoomManagementScreen> {
  String _selectedFilter = 'Tümü'; // Tümü, Boş, Dolu, Temizlikte, Bakımda
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('tr_TR', null); // EKLENDİ
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        title: const Text('Odalar', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 24)),
        backgroundColor: const Color(0xFFF6F7FB),
        elevation: 0,
        automaticallyImplyLeading: false, // Panelden yönetildiği için geri butonu yok
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.black54),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // Filtreler
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _FilterChip(label: 'Tümü', isSelected: _selectedFilter == 'Tümü', onTap: () => setState(() => _selectedFilter = 'Tümü')),
                const SizedBox(width: 8),
                _FilterChip(label: 'Boş', isSelected: _selectedFilter == 'Boş', onTap: () => setState(() => _selectedFilter = 'Boş')),
                const SizedBox(width: 8),
                _FilterChip(label: 'Dolu', isSelected: _selectedFilter == 'Dolu', onTap: () => setState(() => _selectedFilter = 'Dolu')),
                const SizedBox(width: 8),
                _FilterChip(label: 'Temizlikte', isSelected: _selectedFilter == 'Temizlikte', onTap: () => setState(() => _selectedFilter = 'Temizlikte')),
                const SizedBox(width: 8),
                _FilterChip(label: 'Bakımda', isSelected: _selectedFilter == 'Bakımda', onTap: () => setState(() => _selectedFilter = 'Bakımda')),
              ],
            ),
          ),
          
          Expanded(
            child: StreamBuilder<Map<String, dynamic>?>(
              stream: DatabaseService().getHotelInfo(widget.hotelName),
              builder: (context, infoSnapshot) {
                int totalRooms = 20; // Varsayılan
                if (infoSnapshot.hasData && infoSnapshot.data != null) {
                  totalRooms = infoSnapshot.data!['totalRooms'] ?? 20;
                }

                return StreamBuilder<List<Map<String, dynamic>>>(
                  stream: DatabaseService().getHotelReservations(widget.hotelName),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final reservations = snapshot.data!;
                    
                    // MOCK ROOM DATA GENERATION
                    final List<Map<String, dynamic>> allRooms = _generateMockRooms(reservations, totalRooms);

                    // Filtering
                    final filteredRooms = allRooms.where((room) {
                      final status = room['status'];
                      
                      if (_searchQuery.isNotEmpty && !room['number'].toString().contains(_searchQuery)) {
                        return false;
                      }

                      if (_selectedFilter == 'Tümü') return true;
                      if (_selectedFilter == 'Boş' && status == 'Empty') return true;
                      if (_selectedFilter == 'Dolu' && status == 'Occupied') return true;
                      if (_selectedFilter == 'Temizlikte' && status == 'Cleaning') return true;
                      if (_selectedFilter == 'Bakımda' && status == 'Maintenance') return true;
                      
                      return false;
                    }).toList();

                    return GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.1, // Kareye yakın
                      ),
                      itemCount: filteredRooms.length,
                      itemBuilder: (context, index) {
                        return _RoomGridCard(room: filteredRooms[index]);
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _showCreatePnrDialog(context);
        },
        backgroundColor: const Color(0xFF2E5077),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Yeni Misafir / PNR', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  // Dinamik ve statik odaları birleştirir
  List<Map<String, dynamic>> _generateMockRooms(List<Map<String, dynamic>> reservations, int totalRooms) {
    List<Map<String, dynamic>> rooms = [];
    
    // 1. Önce veritabanındaki tüm aktif rezervasyonları listeye ekle
    Set<String> occupiedRoomNumbers = {};
    
    for (var res in reservations) {
      if (res['status'] == 'active' || res['status'] == 'used') {
        final roomNum = res['roomNumber'] ?? 'Unknown';
        occupiedRoomNumbers.add(roomNum);
        
        rooms.add({
          'number': roomNum,
          'status': 'Occupied',
          'guestName': res['guestName'] ?? 'Misafir',
          'pnr': res['pnr'] ?? '-',
          'checkOut': res['checkOutDate'], // Timestamp object
          'data': res, 
        });
      }
    }

    // 2. 1'den totalRooms'a kadar odaları kontrol et
    for (int i = 1; i <= totalRooms; i++) {
      String roomNumber = i.toString();
      if (!occupiedRoomNumbers.contains(roomNumber)) {
        rooms.add({
          'number': roomNumber,
          'status': 'Empty',
          'guestName': null,
        });
      }
    }

    // 3. Oda numarasına göre sırala
    rooms.sort((a, b) {
      // Sayısal sıralama denemesi
      int? numA = int.tryParse(a['number']);
      int? numB = int.tryParse(b['number']);
      if (numA != null && numB != null) {
        return numA.compareTo(numB);
      }
      return a['number'].compareTo(b['number']);
    });

    return rooms;
  }
  // ...

  void _showCreatePnrDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final guestNameController = TextEditingController();
    String? selectedRoomNumber;
    DateTime checkInDate = DateTime.now();
    DateTime checkOutDate = DateTime.now().add(const Duration(days: 1));
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Yeni Misafir Girişi'),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              content: SizedBox(
                width: double.maxFinite,
                child: StreamBuilder<Map<String, dynamic>?>(
                  stream: DatabaseService().getHotelInfo(widget.hotelName),
                  builder: (context, infoSnapshot) {
                    if (!infoSnapshot.hasData) return const Center(child: CircularProgressIndicator());
                    
                    int totalRooms = infoSnapshot.data!['totalRooms'] ?? 20;

                    return StreamBuilder<List<Map<String, dynamic>>>(
                      stream: DatabaseService().getHotelReservations(widget.hotelName),
                      builder: (context, resSnapshot) {
                        if (!resSnapshot.hasData) return const Center(child: CircularProgressIndicator());
                        
                        // Boş odaları hesapla
                        List<Map<String, dynamic>> reservations = resSnapshot.data!;
                        Set<String> occupiedRooms = {};
                        for (var res in reservations) {
                          if (res['status'] == 'active' || res['status'] == 'used') {
                            occupiedRooms.add(res['roomNumber'] ?? '');
                          }
                        }

                        List<String> emptyRooms = [];
                        for (int i = 1; i <= totalRooms; i++) {
                          if (!occupiedRooms.contains(i.toString())) {
                            emptyRooms.add(i.toString());
                          }
                        }

                        if (emptyRooms.isEmpty) {
                          return const Center(child: Text('Maalesef tüm odalar dolu!'));
                        }

                        return Form(
                          key: formKey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Oda Seçimi Dropdown
                              DropdownButtonFormField<String>(
                                value: selectedRoomNumber,
                                decoration: InputDecoration(
                                  labelText: 'Oda Seçiniz',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  prefixIcon: const Icon(Icons.meeting_room),
                                ),
                                items: emptyRooms.map((roomNum) {
                                  return DropdownMenuItem(
                                    value: roomNum,
                                    child: Text('Oda $roomNum'),
                                  );
                                }).toList(),
                                onChanged: (val) => setState(() => selectedRoomNumber = val),
                                validator: (v) => v == null ? 'Lütfen bir oda seçin' : null,
                              ),
                              const SizedBox(height: 16),
                              
                              // Misafir Adı
                              TextFormField(
                                controller: guestNameController,
                                decoration: InputDecoration(
                                  labelText: 'Misafir Adı',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  prefixIcon: const Icon(Icons.person),
                                ),
                                validator: (v) => v!.isEmpty ? 'Misafir adı gerekli' : null,
                              ),
                              const SizedBox(height: 16),
                              
                              // Giriş Tarihi
                              ListTile(
                                title: const Text('Giriş Tarihi'),
                                subtitle: Text(DateFormat('dd MMMM yyyy', 'tr_TR').format(checkInDate), style: const TextStyle(fontWeight: FontWeight.bold)),
                                trailing: const Icon(Icons.login, color: Color(0xFF2E5077)),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: Colors.grey.withOpacity(0.5) != null ? BorderSide(color: Colors.grey.withOpacity(0.5)) : BorderSide.none,
                                ),
                                onTap: () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: checkInDate,
                                    firstDate: DateTime.now().subtract(const Duration(days: 30)), // Geçmişe dönük giriş olabilir mi? Evet
                                    lastDate: DateTime.now().add(const Duration(days: 365)),
                                    locale: const Locale('tr', 'TR'),
                                  );
                                  if (picked != null) {
                                    setState(() {
                                      checkInDate = picked;
                                      // Çıkış tarihi giriş tarihinden önceyse, çıkışı girişten 1 gün sonraya ayarla
                                      if (checkOutDate.isBefore(checkInDate)) {
                                          checkOutDate = checkInDate.add(const Duration(days: 1));
                                      }
                                    });
                                  }
                                },
                              ),
                              const SizedBox(height: 8),

                              // Çıkış Tarihi
                              ListTile(
                                title: const Text('Çıkış Tarihi'),
                                subtitle: Text(DateFormat('dd MMMM yyyy', 'tr_TR').format(checkOutDate), style: const TextStyle(fontWeight: FontWeight.bold)),
                                trailing: const Icon(Icons.logout, color: Color(0xFF2E5077)),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: Colors.grey.withOpacity(0.5) != null ? BorderSide(color: Colors.grey.withOpacity(0.5)) : BorderSide.none,
                                ),
                                onTap: () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: checkOutDate,
                                    firstDate: checkInDate.add(const Duration(days: 1)), // Giriş tarihinden sonra olmalı
                                    lastDate: DateTime.now().add(const Duration(days: 365)),
                                    locale: const Locale('tr', 'TR'),
                                  );
                                  if (picked != null) {
                                    setState(() => checkOutDate = picked);
                                  }
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('İptal', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E5077),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: isLoading ? null : () async {
                    if (formKey.currentState!.validate()) {
                      setState(() => isLoading = true);
                      try {
                        await DatabaseService().createReservation(
                          widget.hotelName,
                          selectedRoomNumber!,
                          guestNameController.text,
                          checkInDate,
                          checkOutDate,
                        );
                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Kayıt başarıyla oluşturuldu!'), backgroundColor: Colors.green),
                          );
                        }
                      } catch (e) {
                         if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Hata oluştu: $e'), backgroundColor: Colors.red),
                          );
                         }
                      } finally {
                        if (context.mounted) setState(() => isLoading = false);
                      }
                    }
                  },
                  child: isLoading 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('PNR Oluştur', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF3B82F6) : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _RoomGridCard extends StatelessWidget {
  final Map<String, dynamic> room;

  const _RoomGridCard({required this.room});

  @override
  Widget build(BuildContext context) {
    final status = room['status'];
    final bool isOccupied = status == 'Occupied';
    
    // Daha Keskin/Vivid Renkler
    Color accentColor = const Color(0xFF10B981); // Canlı Yeşil (Emerald)
    Color bgColor = Colors.white;
    IconData statusIcon = Icons.check_circle;
    String statusText = 'Müsait';

    if (isOccupied) {
      accentColor = const Color(0xFFF59E0B); // Canlı Turuncu (Amber)
      statusIcon = Icons.person;
      statusText = 'Dolu';
    } else if (status == 'Cleaning') {
      accentColor = const Color(0xFF3B82F6); // Canlı Mavi
      statusIcon = Icons.cleaning_services;
      statusText = 'Temizlikte';
    } else if (status == 'Maintenance') {
      accentColor = const Color(0xFFEF4444); // Canlı Kırmızı
      statusIcon = Icons.build;
      statusText = 'Bakımda';
    }

    return Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12), // Biraz daha az yuvarlatılmış
          border: Border.all(color: accentColor, width: 2), // Kalın, belirgin çerçeve
          boxShadow: [
            BoxShadow(
              color: accentColor.withOpacity(0.15), // Gölge rengi statüyle eşleşsin
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Oda No + İkon (Solid header efekti)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: accentColor, // Başlık tamamen renkli
                borderRadius: const BorderRadius.vertical(top: Radius.circular(9)), // İç border uyumu için
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'ODA ${room['number']}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      color: Colors.white, // Beyaz yazı
                      letterSpacing: 1.0,
                    ),
                  ),
                  Icon(statusIcon, color: Colors.white, size: 18),
                ],
              ),
            ),
            
            // Content: İsim veya Durum
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: isOccupied 
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          room['guestName'] ?? 'Misafir',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18, // Büyütüldü (15 -> 18)
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 6),
                         Container(
                           padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                           decoration: BoxDecoration(
                             color: Colors.grey[100],
                             borderRadius: BorderRadius.circular(4),
                             border: Border.all(color: Colors.grey[300]!),
                           ),
                           child: Text(
                            'PNR: ${room['pnr']}',
                            style: TextStyle(
                              fontSize: 13, // Büyütüldü (10 -> 13)
                              fontWeight: FontWeight.w800,
                              color: Colors.grey[800],
                            ),
                           ),
                         ),
                         const SizedBox(height: 6),
                         Row(
                           children: [
                             Icon(Icons.calendar_today_outlined, size: 16, color: accentColor), // Icon büyütüldü
                             const SizedBox(width: 4),
                             Text(
                               room['checkOut'] != null 
                                 ? DateFormat('dd MMM', 'tr_TR').format((room['checkOut'] as Timestamp).toDate()) 
                                 : '-',
                               style: TextStyle(
                                 fontSize: 14, // Büyütüldü (12 -> 14)
                                 fontWeight: FontWeight.bold,
                                 color: accentColor,
                               ),
                             ),
                           ],
                         ),
                      ],
                    )
                  : Center(
                      child: Text(
                        statusText.toUpperCase(),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 22, // Büyütüldü (18 -> 22)
                          fontWeight: FontWeight.w900, 
                          color: accentColor, 
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
            ),
          ),
          ],
        ),
    );
  }


}
