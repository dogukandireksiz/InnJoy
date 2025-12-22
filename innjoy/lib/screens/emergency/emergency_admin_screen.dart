import 'package:flutter/material.dart';
import 'package:login_page/services/logger_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EmergencyAdminScreen extends StatefulWidget {
  const EmergencyAdminScreen({super.key});

  @override
  State<EmergencyAdminScreen> createState() => _EmergencyAdminScreenState();
}

class _EmergencyAdminScreenState extends State<EmergencyAdminScreen> {
  String _activeFilter = 'All';

  // Firebase referans�
  final CollectionReference _emergenciesRef = FirebaseFirestore.instance
      .collection('emergency_alerts');

  Color _statusColor(String status) {
    switch (status) {
      case 'Processing':
        return const Color(0xFFFACC15); // amber
      case 'Pending':
        return const Color(0xFF94A3B8); // slate
      case 'Resolved':
        return const Color(0xFF22C55E); // green
      default:
        return Colors.grey;
    }
  }

  IconData _categoryIcon(String category) {
    switch (category) {
      case 'Fire':
        return Icons.local_fire_department;
      case 'Earthquake':
        return Icons.waves;
      default:
        return Icons.warning;
    }
  }

  // --- YEN� EKLENEN FONKS�YON: DURUMU G�NCELLE ---
  Future<void> _markAsSolved(String docId, String currentStatus) async {
    // E�er zaten ��z�ld�yse i�lem yapma (veya iste�e g�re geri al �zelli�i eklenebilir)
    if (currentStatus == 'Resolved') return;

    try {
      // Kullan�c�ya emin misin diye soral�m (Opsiyonel, istemezsen direkt update k�sm�n� kullan)
      bool? confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          title: const Text(
            "Status Update",
            style: TextStyle(color: Colors.white),
          ),
          content: const Text(
            "Do you want to mark this emergency as 'Resolved'?",
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text(
                "Yes, Resolved",
                style: TextStyle(color: Color(0xFF22C55E)),
              ),
            ),
          ],
        ),
      );

      if (confirm == true) {
        // Firebase g�ncellemesi: status -> 'solved'
        await _emergenciesRef.doc(docId).update({'status': 'solved'});

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Status updated!"),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 1),
            ),
          );
        }
      }
    } catch (e) {
      Logger.debug("Update error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
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
        title: const Text('Emergencies', style: TextStyle(color: Colors.white)),
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
                'Error: ${snapshot.error}',
                style: const TextStyle(color: Colors.white),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'No records found (Empty List)',
                style: TextStyle(color: Colors.white70),
              ),
            );
          }

          final allItems = snapshot.data!.docs.map((doc) {
            try {
              return _EmergencyItem.fromFirestore(doc);
            } catch (e) {
              return _EmergencyItem(
                id: doc.id,
                title: 'ERROR',
                place: '-',
                person: '-',
                timestamp: Timestamp.now(),
                category: 'Other',
                status: 'Pending',
              );
            }
          }).toList();

          final activeCount = allItems
              .where((e) => e.status == 'Processing' || e.status == 'Pending')
              .length;

          final visibleItems = _activeFilter == 'All'
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
                            'Emergencies',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'Manage hotel-wide emergencies',
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
                            '$activeCount Active',
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
                      label: 'All',
                      selected: _activeFilter == 'All',
                      onTap: () => setState(() => _activeFilter = 'All'),
                    ),
                    _FilterChip(
                      label: 'Fire',
                      selected: _activeFilter == 'Fire',
                      onTap: () => setState(() => _activeFilter = 'Fire'),
                    ),
                    _FilterChip(
                      label: 'Earthquake',
                      selected: _activeFilter == 'Earthquake',
                      onTap: () => setState(() => _activeFilter = 'Earthquake'),
                    ),
                    _FilterChip(
                      label: 'Other',
                      selected: _activeFilter == 'Other',
                      onTap: () => setState(() => _activeFilter = 'Other'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: visibleItems.isEmpty
                    ? const Center(
                        child: Text(
                          "No records found",
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
                            // --- TIKLAMA OLAYINI BURADA BA�LIYORUZ ---
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

// --- KART G�NCELLEMES� (TIKLANAB�L�R YAPILDI) ---
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
          color: status == 'Processing'
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
                    // --- BURASI DE���T�: InkWell ile sarmaland� ---
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
                  '$place  �  $person',
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 6),
                Text(
                  '$minutesAgo minutes ago',
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

// --- MODEL G�NCELLEMES� (ID ALANI EKLEND�) ---
class _EmergencyItem {
  final String id; // Dok�man ID'si
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
    String uiStatus = 'Pending';
    if (rawStatus == 'active') {
      uiStatus = 'Processing';
    } else if (rawStatus == 'solved' || rawStatus == 'closed') {
      uiStatus = 'Resolved';
    }

    String typeData = data['type'] ?? 'Other';
    String categoryData = typeData;
    if (typeData.contains('Other')) {
      categoryData = 'Other';
    }

    String locationKey = data['location_context'] ?? '';
    String roomNum = data['room_number'] ?? '?';
    String placeText;
    switch (locationKey) {
      case 'my_room':
        placeText = 'Room $roomNum';
        break;
      case 'restaurant':
        placeText = 'Restaurant';
        break;
      case 'fitness':
        placeText = 'Fitness Center';
        break;
      case 'spa':
        placeText = 'Spa Center';
        break;
      case 'reception':
        placeText = 'Reception';
        break;
      default:
        placeText = locationKey;
    }

    // ignore: unused_local_variable
    String uid = data['user_uid'] ?? 'Anonymous';
    String personText = 'Guest - Room $roomNum';

    return _EmergencyItem(
      id: doc.id, // Dok�man ID'sini al�yoruz
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
