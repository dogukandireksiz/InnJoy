import 'package:flutter/material.dart';
import 'package:login_page/service/logger_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EmergencyAdminScreen extends StatefulWidget {
  const EmergencyAdminScreen({super.key});

  @override
  State<EmergencyAdminScreen> createState() => _EmergencyAdminScreenState();
}

class _EmergencyAdminScreenState extends State<EmergencyAdminScreen> {
  String _activeFilter = 'Tümü';

  // Firebase referansı
  final CollectionReference _emergenciesRef = FirebaseFirestore.instance
      .collection('emergency_alerts');

  Color _statusColor(String status) {
    switch (status) {
      case 'İşleniyor':
        return const Color(0xFFFACC15); // amber
      case 'Bekliyor':
        return const Color(0xFF94A3B8); // slate
      case 'Çözüldü':
        return const Color(0xFF22C55E); // green
      default:
        return Colors.grey;
    }
  }

  IconData _categoryIcon(String category) {
    switch (category) {
      case 'Yangın':
        return Icons.local_fire_department;
      case 'Deprem':
        return Icons.waves;
      default:
        return Icons.warning;
    }
  }

  // --- YENİ EKLENEN FONKSİYON: DURUMU GÜNCELLE ---
  Future<void> _markAsSolved(String docId, String currentStatus) async {
    // Eğer zaten çözüldüyse işlem yapma (veya isteğe göre geri al özelliği eklenebilir)
    if (currentStatus == 'Çözüldü') return;

    try {
      // Kullanıcıya emin misin diye soralım (Opsiyonel, istemezsen direkt update kısmını kullan)
      bool? confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          title: const Text(
            "Durum Güncelleme",
            style: TextStyle(color: Colors.white),
          ),
          content: const Text(
            "Bu acil durumu 'Çözüldü' olarak işaretlemek istiyor musunuz?",
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("İptal", style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text(
                "Evet, Çözüldü",
                style: TextStyle(color: Color(0xFF22C55E)),
              ),
            ),
          ],
        ),
      );

      if (confirm == true) {
        // Firebase güncellemesi: status -> 'solved'
        await _emergenciesRef.doc(docId).update({'status': 'solved'});

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Durum güncellendi!"),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 1),
            ),
          );
        }
      }
    } catch (e) {
      Logger.debug("Güncelleme hatası: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Hata: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Acil Durumlar',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF121212),
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _emergenciesRef
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFFACC15)),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Hata: ${snapshot.error}',
                style: const TextStyle(color: Colors.white),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'Kayıt bulunamadı (Liste Boş)',
                style: TextStyle(color: Colors.white70),
              ),
            );
          }

          final allItems = snapshot.data!.docs.map((doc) {
            try {
              return _EmergencyItem.fromFirestore(doc);
            } catch (e) {
              return _EmergencyItem(
                id: doc.id, // ID eklendi
                title: 'HATA',
                place: '-',
                person: '-',
                timestamp: Timestamp.now(),
                category: 'Diğer',
                status: 'Bekliyor',
              );
            }
          }).toList();

          final activeCount = allItems
              .where((e) => e.status == 'İşleniyor' || e.status == 'Bekliyor')
              .length;

          final visibleItems = _activeFilter == 'Tümü'
              ? allItems
              : allItems.where((e) => e.category == _activeFilter).toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Acil Durumlar',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'Otel genelindeki acil durumları yönetin',
                            style: TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFACC15).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFFFACC15).withValues(alpha: 0.6),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.flash_on,
                            color: Color(0xFFFACC15),
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '$activeCount Aktif',
                            style: const TextStyle(
                              color: Color(0xFFFACC15),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    _FilterChip(
                      label: 'Tümü',
                      selected: _activeFilter == 'Tümü',
                      onTap: () => setState(() => _activeFilter = 'Tümü'),
                    ),
                    _FilterChip(
                      label: 'Yangın',
                      selected: _activeFilter == 'Yangın',
                      onTap: () => setState(() => _activeFilter = 'Yangın'),
                    ),
                    _FilterChip(
                      label: 'Deprem',
                      selected: _activeFilter == 'Deprem',
                      onTap: () => setState(() => _activeFilter = 'Deprem'),
                    ),
                    _FilterChip(
                      label: 'Diğer',
                      selected: _activeFilter == 'Diğer',
                      onTap: () => setState(() => _activeFilter = 'Diğer'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: visibleItems.isEmpty
                    ? const Center(
                        child: Text(
                          "Kayıt bulunamadı",
                          style: TextStyle(color: Colors.white38),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        itemCount: visibleItems.length,
                        itemBuilder: (ctx, i) {
                          final item = visibleItems[i];
                          return _EmergencyCard(
                            icon: _categoryIcon(item.category),
                            title: item.title,
                            place: item.place,
                            person: item.person,
                            minutesAgo: item.minutesAgo,
                            status: item.status,
                            statusColor: _statusColor(item.status),
                            // --- TIKLAMA OLAYINI BURADA BAĞLIYORUZ ---
                            onStatusTap: () {
                              _markAsSolved(item.id, item.status);
                            },
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;
  const _FilterChip({required this.label, this.selected = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? Colors.white.withValues(alpha: 0.12)
              : const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? Colors.white24 : Colors.white10),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.white70,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

// --- KART GÜNCELLEMESİ (TIKLANABİLİR YAPILDI) ---
class _EmergencyCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String place;
  final String person;
  final int minutesAgo;
  final String status;
  final Color statusColor;
  final VoidCallback onStatusTap; // Yeni callback

  const _EmergencyCard({
    required this.icon,
    required this.title,
    required this.place,
    required this.person,
    required this.minutesAgo,
    required this.status,
    required this.statusColor,
    required this.onStatusTap, // Constructor'a eklendi
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: status == 'İşleniyor'
              ? const Color(0xFFFACC15).withValues(alpha: 0.4)
              : Colors.white10,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.white70, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    // --- BURASI DEĞİŞTİ: InkWell ile sarmalandı ---
                    InkWell(
                      onTap: onStatusTap,
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: statusColor.withValues(alpha: 0.6),
                          ),
                        ),
                        child: Text(
                          status,
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '$place  •  $person',
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 6),
                Text(
                  '$minutesAgo dakika önce',
                  style: const TextStyle(color: Colors.white38, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// --- MODEL GÜNCELLEMESİ (ID ALANI EKLENDİ) ---
class _EmergencyItem {
  final String id; // Doküman ID'si
  final String title;
  final String place;
  final String person;
  final Timestamp timestamp;
  final String category;
  final String status;

  const _EmergencyItem({
    required this.id, // Constructor'a eklendi
    required this.title,
    required this.place,
    required this.person,
    required this.timestamp,
    required this.category,
    required this.status,
  });

  factory _EmergencyItem.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    String rawStatus = data['status'] ?? '';
    String uiStatus = 'Bekliyor';
    if (rawStatus == 'active') {
      uiStatus = 'İşleniyor';
    } else if (rawStatus == 'solved' || rawStatus == 'closed') {
      uiStatus = 'Çözüldü';
    }

    String typeData = data['type'] ?? 'Diğer';
    String categoryData = typeData;
    if (typeData.contains('Diğer')) {
      categoryData = 'Diğer';
    }

    String locationKey = data['location_context'] ?? '';
    String roomNum = data['room_number'] ?? '?';
    String placeText;
    switch (locationKey) {
      case 'my_room':
        placeText = 'Oda $roomNum';
        break;
      case 'restaurant':
        placeText = 'Restoran';
        break;
      case 'fitness':
        placeText = 'Spor Salonu';
        break;
      case 'spa':
        placeText = 'Spa Merkezi';
        break;
      case 'reception':
        placeText = 'Resepsiyon';
        break;
      default:
        placeText = locationKey;
    }

    // ignore: unused_local_variable
    String uid = data['user_uid'] ?? 'Anonim';
    String personText = 'Misafir - Oda $roomNum';

    return _EmergencyItem(
      id: doc.id, // Doküman ID'sini alıyoruz
      title: typeData,
      category: categoryData,
      place: placeText,
      person: personText,
      timestamp: data['timestamp'] ?? Timestamp.now(),
      status: uiStatus,
    );
  }

  int get minutesAgo {
    final now = DateTime.now();
    final date = timestamp.toDate();
    return now.difference(date).inMinutes;
  }
}











