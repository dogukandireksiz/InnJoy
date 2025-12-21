import 'package:flutter/material.dart';
import 'package:login_page/service/logger_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../service/database_service.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart'; // EKLENDİ
import 'package:qr_flutter/qr_flutter.dart';

class AdminRoomManagementScreen extends StatefulWidget {
  final String hotelName;
  final VoidCallback? onBack;

  const AdminRoomManagementScreen({
    super.key,
    required this.hotelName,
    this.onBack,
  });

  @override
  State<AdminRoomManagementScreen> createState() =>
      _AdminRoomManagementScreenState();
}

class _AdminRoomManagementScreenState extends State<AdminRoomManagementScreen> {
  String _selectedFilter = 'All'; // All, Empty, Occupied, Cleaning, Maintenance
  String _searchQuery = '';

  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  bool _localeInitialized = false;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('tr_TR', null).then((_) {
      if (mounted) {
        setState(() {
          _localeInitialized = true;
        });
      }
    });

    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_localeInitialized) {
      return const Scaffold(
        backgroundColor: Color(0xFFF6F7FB),
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF6F7FB),
        appBar: AppBar(
          title: _isSearching
              ? TextField(
                  controller: _searchController,
                  autofocus: true,
                  decoration: const InputDecoration(
                    hintText: 'Room No, Guest or PNR...',
                    border: InputBorder.none,
                    hintStyle: TextStyle(color: Colors.grey),
                  ),
                  style: const TextStyle(color: Colors.black, fontSize: 18),
                )
              : const Text(
                  'Rooms',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                  ),
                ),
          backgroundColor: const Color(0xFFF6F7FB),
          elevation: 0,
          automaticallyImplyLeading: false,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () {
              if (_isSearching) {
                setState(() {
                  _isSearching = false;
                  _searchController.clear();
                  _searchQuery = '';
                });
              } else {
                if (widget.onBack != null) {
                  widget.onBack!();
                } else {
                  Navigator.of(context).pop();
                }
              }
            },
          ),
          actions: [
            if (!_isSearching)
              IconButton(
                icon: const Icon(Icons.search, color: Colors.black54),
                onPressed: () {
                  setState(() {
                    _isSearching = true;
                  });
                },
              )
            else
              IconButton(
                icon: const Icon(Icons.close, color: Colors.black54),
                onPressed: () {
                  setState(() {
                    _isSearching = false;
                    _searchController.clear();
                    _searchQuery = '';
                  });
                },
              ),
          ],
          bottom: const TabBar(
            labelColor: Color(0xFF2E5077),
            unselectedLabelColor: Colors.grey,
            indicatorColor: Color(0xFF2E5077),
            indicatorWeight: 3,
            labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            tabs: [
              Tab(text: 'Rooms'),
              Tab(text: 'History'),
            ],
          ),
        ),
        body: TabBarView(
          children: [_buildActiveRoomsTab(), _buildHistoryTab()],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            _showCreatePnrDialog(context);
          },
          backgroundColor: const Color(0xFF2E5077),
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text(
            'New Guest / PNR',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  // Dinamik ve statik odaları birleştirir
  List<Map<String, dynamic>> _generateMockRooms(
    List<Map<String, dynamic>> reservations,
    int totalRooms,
    List<Map<String, dynamic>> roomDocs,
  ) {
    List<Map<String, dynamic>> rooms = [];

    // Room Docs Map for fast lookup (ID -> Data)
    Map<String, Map<String, dynamic>> roomMap = {
      for (var r in roomDocs) r['id']: r,
    };

    // 1. Önce veritabanındaki tüm aktif rezervasyonları listeye ekle
    Set<String> occupiedRoomNumbers = {};

    for (var res in reservations) {
      if (res['status'] == 'active' || res['status'] == 'used') {
        final roomNumId = res['roomNumber'] ?? 'Unknown';
        occupiedRoomNumbers.add(roomNumId);

        // Resolve Real Room Name
        String displayRoomNumber = roomNumId;
        bool isDnd = false;

        if (roomMap.containsKey(roomNumId)) {
          final rData = roomMap[roomNumId]!;
          // Try 'name', 'roomName', 'number' or fallback to ID
          displayRoomNumber =
              rData['name']?.toString() ??
              rData['roomName']?.toString() ??
              rData['number']?.toString() ??
              roomNumId;

          isDnd = rData['doNotDisturb'] == true;
        }

        rooms.add({
          'number': displayRoomNumber, // Resolved Name
          'id': roomNumId, // Keep ID for reference
          'status': 'Occupied',
          'guestName': res['guestName'] ?? 'Guest',
          'pnr': res['pnr'] ?? '-',
          'checkOut': res['checkOutDate'], // Timestamp object
          'data': res,
          'isDnd': isDnd,
        });
      }
    }

    // 2. 1'den totalRooms'a kadar odaları kontrol et (VEYA roomDocs'tan kalanları ekle)
    // Eğer roomDocs varsa, oradan iterate edelim, yoksa 1..20 varsayalım
    if (roomDocs.isNotEmpty) {
      for (var doc in roomDocs) {
        final roomId = doc['id'];
        if (!occupiedRoomNumbers.contains(roomId)) {
          String displayRoomNumber =
              doc['name']?.toString() ??
              doc['roomName']?.toString() ??
              doc['number']?.toString() ??
              roomId;
          bool isDnd = doc['doNotDisturb'] == true;

          rooms.add({
            'number': displayRoomNumber,
            'id': roomId,
            'status': 'Empty',
            'guestName': null,
            'isDnd': isDnd,
          });
        }
      }
    } else {
      // Fallback old logic if no room docs found
      for (int i = 1; i <= totalRooms; i++) {
        String roomNumber = i.toString();
        if (!occupiedRoomNumbers.contains(roomNumber)) {
          rooms.add({
            'number': roomNumber,
            'id': roomNumber,
            'status': 'Empty',
            'guestName': null,
            'isDnd': false,
          });
        }
      }
    }

    // 3. Oda numarasına göre sırala
    rooms.sort((a, b) {
      // Sayısal sıralama denemesi
      String numStrA = a['number'].toString();
      String numStrB = b['number'].toString();

      int? numA = int.tryParse(numStrA);
      int? numB = int.tryParse(numStrB);

      if (numA != null && numB != null) {
        return numA.compareTo(numB);
      }
      return numStrA.compareTo(numStrB);
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
              title: const Text('New Guest Check-In'),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: StreamBuilder<Map<String, dynamic>?>(
                  stream: DatabaseService().getHotelInfo(widget.hotelName),
                  builder: (context, infoSnapshot) {
                    if (!infoSnapshot.hasData)
                      return const Center(child: CircularProgressIndicator());

                    int totalRooms = infoSnapshot.data!['totalRooms'] ?? 20;

                    return StreamBuilder<List<Map<String, dynamic>>>(
                      stream: DatabaseService().getHotelReservations(
                        widget.hotelName,
                      ),
                      builder: (context, resSnapshot) {
                        if (!resSnapshot.hasData)
                          return const Center(
                            child: CircularProgressIndicator(),
                          );

                        // Boş odaları hesapla
                        List<Map<String, dynamic>> reservations =
                            resSnapshot.data!;
                        Set<String> occupiedRooms = {};
                        for (var res in reservations) {
                          if (res['status'] == 'active' ||
                              res['status'] == 'used') {
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
                          return const Center(
                            child: Text('Sorry, all rooms are occupied!'),
                          );
                        }

                        // CRASH FIX: Eğer seçili oda artık listede yoksa (ör: yeni rezerve edildiyse), null yap.
                        if (selectedRoomNumber != null &&
                            !emptyRooms.contains(selectedRoomNumber)) {
                          selectedRoomNumber = null;
                        }

                        return Form(
                          key: formKey,
                          child: SingleChildScrollView(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Oda Seçimi Dropdown
                                DropdownButtonFormField<String>(
                                  value: selectedRoomNumber,
                                  decoration: InputDecoration(
                                    labelText: 'Select Room',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    prefixIcon: const Icon(Icons.meeting_room),
                                  ),
                                  items: emptyRooms.map((roomNum) {
                                    return DropdownMenuItem(
                                      value: roomNum,
                                      child: Text('Room $roomNum'),
                                    );
                                  }).toList(),
                                  onChanged: (val) =>
                                      setState(() => selectedRoomNumber = val),
                                  validator: (v) =>
                                      v == null ? 'Please select a room' : null,
                                ),
                                const SizedBox(height: 16),

                                // Misafir Adı
                                TextFormField(
                                  controller: guestNameController,
                                  decoration: InputDecoration(
                                    labelText: 'Guest Name',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    prefixIcon: const Icon(Icons.person),
                                  ),
                                  validator: (v) =>
                                      v!.isEmpty ? 'Guest name required' : null,
                                ),
                                const SizedBox(height: 16),

                                // Giriş Tarihi
                                ListTile(
                                  title: const Text('Check-In Date'),
                                  subtitle: Text(
                                    DateFormat(
                                      'dd MMMM yyyy',
                                      'tr_TR',
                                    ).format(checkInDate),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  trailing: const Icon(
                                    Icons.login,
                                    color: Color(0xFF2E5077),
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: BorderSide(
                                      color: Colors.grey.withValues(alpha: 0.5),
                                    ),
                                  ),
                                  onTap: () async {
                                    final picked = await showDatePicker(
                                      context: context,
                                      initialDate: checkInDate,
                                      firstDate: DateTime.now().subtract(
                                        const Duration(days: 30),
                                      ), // Geçmişe dönük giriş olabilir mi? Evet
                                      lastDate: DateTime.now().add(
                                        const Duration(days: 365),
                                      ),
                                      locale: const Locale('tr', 'TR'),
                                    );
                                    if (picked != null) {
                                      setState(() {
                                        checkInDate = picked;
                                        // Çıkış tarihi giriş tarihinden önceyse, çıkışı girişten 1 gün sonraya ayarla
                                        if (checkOutDate.isBefore(
                                          checkInDate,
                                        )) {
                                          checkOutDate = checkInDate.add(
                                            const Duration(days: 1),
                                          );
                                        }
                                      });
                                    }
                                  },
                                ),
                                const SizedBox(height: 8),

                                // Çıkış Tarihi
                                ListTile(
                                  title: const Text('Check-Out Date'),
                                  subtitle: Text(
                                    DateFormat(
                                      'dd MMMM yyyy',
                                      'tr_TR',
                                    ).format(checkOutDate),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  trailing: const Icon(
                                    Icons.logout,
                                    color: Color(0xFF2E5077),
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: BorderSide(
                                      color: Colors.grey.withValues(alpha: 0.5),
                                    ),
                                  ),
                                  onTap: () async {
                                    final picked = await showDatePicker(
                                      context: context,
                                      initialDate: checkOutDate,
                                      firstDate: checkInDate.add(
                                        const Duration(days: 1),
                                      ), // Giriş tarihinden sonra olmalı
                                      lastDate: DateTime.now().add(
                                        const Duration(days: 365),
                                      ),
                                      locale: const Locale('tr', 'TR'),
                                    );
                                    if (picked != null) {
                                      setState(() => checkOutDate = picked);
                                    }
                                  },
                                ),
                              ],
                            ),
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
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E5077),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: isLoading
                      ? null
                      : () async {
                          if (formKey.currentState!.validate()) {
                            setState(() => isLoading = true);
                            try {
                              // FIX: Async işlem sırasında selectedRoomNumber null'a dönebilir (stream update yüzünden).
                              // O yüzden değeri işlem başlamadan önce yerel değişkene alıyoruz.
                              final roomToBook = selectedRoomNumber!;

                              final pnr = await DatabaseService()
                                  .createReservation(
                                    widget.hotelName,
                                    roomToBook,
                                    guestNameController.text,
                                    checkInDate,
                                    checkOutDate,
                                  );
                              if (context.mounted) {
                                Navigator.pop(context);
                                _showPnrSuccessDialog(
                                  context,
                                  pnr,
                                  guestNameController.text,
                                  roomToBook,
                                  checkInDate,
                                  checkOutDate,
                                );
                              }
                            } catch (e, stackTrace) {
                              Logger.debug("PNR Creation Error: $e");
                              Logger.debug(stackTrace.toString());
                              if (context.mounted) {
                                showDialog(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('Error Occurred'),
                                    content: Text(e.toString()),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(ctx),
                                        child: const Text('OK'),
                                      ),
                                    ],
                                  ),
                                );
                              }
                            } finally {
                              if (context.mounted)
                                setState(() => isLoading = false);
                            }
                          }
                        },
                  child: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Create PNR',
                          style: TextStyle(color: Colors.white),
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // --- TAB METHODS ---

  Widget _buildActiveRoomsTab() {
    return Column(
      children: [
        // Filtreler
        if (!_isSearching)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _FilterChip(
                  label: 'All',
                  isSelected: _selectedFilter == 'All',
                  onTap: () => setState(() => _selectedFilter = 'All'),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Empty',
                  isSelected: _selectedFilter == 'Empty',
                  onTap: () => setState(() => _selectedFilter = 'Empty'),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Occupied',
                  isSelected: _selectedFilter == 'Occupied',
                  onTap: () => setState(() => _selectedFilter = 'Occupied'),
                ),
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

              // 1. Fetch Rooms First
              return StreamBuilder<List<Map<String, dynamic>>>(
                stream: DatabaseService().getRooms(widget.hotelName),
                builder: (context, roomSnapshot) {
                  // If rooms loading, we can still show loading or wait.
                  // Let's pass empty if not ready to avoid blocking UI too much, or wait.
                  final roomDocs = roomSnapshot.data ?? [];

                  // 2. Fetch Reservations
                  return StreamBuilder<List<Map<String, dynamic>>>(
                    stream: DatabaseService().getHotelReservations(
                      widget.hotelName,
                    ),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final reservations = snapshot.data!;
                      _checkAutoExpiry(reservations); // Check Expiry Here

                      // MOCK ROOM DATA GENERATION (With Room Docs)
                      final List<Map<String, dynamic>> allRooms =
                          _generateMockRooms(
                            reservations,
                            totalRooms,
                            roomDocs,
                          );

                      // Filtering
                      final filteredRooms = allRooms.where((room) {
                        final status = room['status'];

                        // Search Logic
                        if (_searchQuery.isNotEmpty) {
                          final roomNo = room['number']
                              .toString()
                              .toLowerCase();
                          final guestName = (room['guestName'] ?? '')
                              .toString()
                              .toLowerCase();
                          final pnr = (room['pnr'] ?? '')
                              .toString()
                              .toLowerCase();

                          bool matches =
                              roomNo.contains(_searchQuery) ||
                              guestName.contains(_searchQuery) ||
                              pnr.contains(_searchQuery);

                          if (!matches) return false;
                        }

                        if (_selectedFilter == 'All') return true;
                        if (_selectedFilter == 'Empty' && status == 'Empty')
                          return true;
                        if (_selectedFilter == 'Occupied' &&
                            status == 'Occupied')
                          return true;
                        if (_selectedFilter == 'Cleaning' &&
                            status == 'Cleaning')
                          return true;
                        if (_selectedFilter == 'Maintenance' &&
                            status == 'Maintenance')
                          return true;

                        return false;
                      }).toList();

                      return GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio:
                                  0.85, // Taller card to prevent overflow
                            ),
                        itemCount: filteredRooms.length,
                        itemBuilder: (context, index) {
                          return _RoomGridCard(
                            room: filteredRooms[index],
                            onTap: () =>
                                _showRoomDetails(context, filteredRooms[index]),
                          );
                        },
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryTab() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: DatabaseService().getHotelReservations(widget.hotelName),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());

        // Filter for 'past' or expired reservations
        final history = snapshot.data!.where((res) {
          return res['status'] == 'past';
        }).toList();

        // Sort by checkOutDate descending (newest first)
        history.sort((a, b) {
          Timestamp? tA = a['checkOutDate'];
          Timestamp? tB = b['checkOutDate'];
          if (tA == null || tB == null) return 0;
          return tB.compareTo(tA);
        });

        if (history.isEmpty) {
          return const Center(child: Text('No history records yet.'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: history.length,
          itemBuilder: (context, index) {
            final res = history[index];
            final guestName = res['guestName'] ?? 'Unknown Guest';
            final roomNum = res['roomNumber'] ?? '?';
            final pnr = res['pnr'] ?? '';
            // final checkIn = (res['checkInDate'] as Timestamp?)?.toDate(); // Unused
            // final checkOut = (res['checkOutDate'] as Timestamp?)?.toDate(); // Unused
            // final email = res['guestEmail']; // Unused

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.grey[200],
                  child: const Icon(Icons.history, color: Colors.grey),
                ),
                title: Text(
                  guestName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text('Room: $roomNum  •  PNR: $pnr'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  _showHistoryDetails(context, res);
                },
              ),
            );
          },
        );
      },
    );
  }

  void _checkAutoExpiry(List<Map<String, dynamic>> reservations) {
    final now = DateTime.now();
    for (var res in reservations) {
      if (res['status'] == 'active' || res['status'] == 'used') {
        final val = res['checkOutDate'];
        if (val != null && val is Timestamp) {
          final checkOutDate = val.toDate();

          // Bugun, cikis tarihinden sonraysa (cikis tarihi < simdi)
          if (now.isAfter(checkOutDate)) {
            // AUTO EXPIRE
            final roomNumber = res['roomNumber'];
            Logger.debug("Auto-expiring room: $roomNumber");
            DatabaseService().updateReservationStatus(
              widget.hotelName,
              roomNumber,
              'past',
            );
          }
        }
      }
    }
  }

  void _showPnrSuccessDialog(
    BuildContext context,
    String pnr,
    String guestName,
    String roomNumber,
    DateTime checkIn,
    DateTime checkOut,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false, // Kullanıcı bilerek kapatmalı
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: const [
              Icon(Icons.check_circle, color: Colors.green, size: 28),
              SizedBox(width: 8),
              Expanded(child: Text('Reservation Successful!')),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4), // Açık yeşil arka plan
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.green.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Generated PNR Code',
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      pnr,
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: Colors.black87,
                        letterSpacing: 2.0,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _detailRow('Guest:', guestName),
              _detailRow('Room:', roomNumber),
              const Divider(),
              _detailRow(
                'Check-In:',
                DateFormat('dd MMM yyyy', 'tr_TR').format(checkIn),
              ),
              _detailRow(
                'Check-Out:',
                DateFormat('dd MMM yyyy', 'tr_TR').format(checkOut),
              ),
            ],
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E5077),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () {
                  Navigator.of(ctx).pop(); // Dialogu kapat
                },
                child: const Text(
                  'OK',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showHistoryDetails(BuildContext context, Map<String, dynamic> res) {
    final checkIn = (res['checkInDate'] as Timestamp?)?.toDate();
    final checkOut = (res['checkOutDate'] as Timestamp?)?.toDate();
    final fmt = DateFormat('dd MMM yyyy', 'tr_TR');
    final pnr = res['pnr'] ?? '-';

    // CLAIMED NAME LOGIC (History için de geçerli olabilir)
    final String? claimedName = res['claimedGuestName'];
    final String displayName = (claimedName != null && claimedName.isNotEmpty)
        ? claimedName
        : (res['guestName'] ?? 'Guest');
    final bool isClaimed = claimedName != null && claimedName.isNotEmpty;

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header: Avatar & Name
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100], // Grey for history
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey[300]!, width: 2),
                    ),
                    child: const Icon(Icons.history, color: Colors.grey),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: const Text(
                            'History Record',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close, color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Info Grid
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
                ),
                child: Column(
                  children: [
                    _detailRowStyled(
                      Icons.person,
                      'Guest Name',
                      displayName,
                      isBold: true,
                    ),
                    const Divider(height: 24),
                    _detailRowStyled(
                      Icons.confirmation_number_outlined,
                      'PNR Code',
                      pnr,
                      isBold: true,
                    ),
                    if (isClaimed && res['guestName'] != null) ...[
                      const Divider(height: 24),
                      _detailRowStyled(
                        Icons.info_outline,
                        'Reservation Name',
                        res['guestName'],
                      ),
                    ],
                    const Divider(height: 24),
                    _detailRowStyled(
                      Icons.email_outlined,
                      'Email',
                      res['guestEmail'] ?? '-',
                    ),
                    const Divider(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: _detailRowStyled(
                            Icons.login,
                            'Check-In',
                            checkIn != null ? fmt.format(checkIn) : '-',
                            isSmall: true,
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 40,
                          color: Colors.grey.withValues(alpha: 0.2),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _detailRowStyled(
                            Icons.logout,
                            'Check-Out',
                            checkOut != null ? fmt.format(checkOut) : '-',
                            isSmall: true,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    _detailRowStyled(
                      Icons.meeting_room,
                      'Room',
                      res['roomNumber'] ?? '-',
                      isBold: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- ROOM DETAILS & DELETE ---
  void _showRoomDetails(BuildContext context, Map<String, dynamic> room) {
    final bool isOccupied = room['status'] == 'Occupied';
    if (!isOccupied) return;

    final checkIn = (room['checkIn'] as Timestamp?)?.toDate();
    final checkOut = (room['checkOut'] as Timestamp?)?.toDate();
    final fmt = DateFormat('dd MMM yyyy', 'tr_TR');
    final pnr = room['pnr'] ?? '-';

    // CLAIMED NAME LOGIC
    final String? claimedName = room['data'] != null
        ? room['data']['claimedGuestName']
        : null;
    final String displayName = (claimedName != null && claimedName.isNotEmpty)
        ? claimedName
        : (room['guestName'] ?? 'Guest');
    final bool isClaimed = claimedName != null && claimedName.isNotEmpty;

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        // AlertDialog yerine Custom Dialog
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header: Avatar & Name
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF), // Blue 50
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFBFDBFE),
                        width: 2,
                      ),
                    ),
                    child: Text(
                      room['number'].toString(),
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1D4ED8),
                        fontSize: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green[50],
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.green[100]!),
                          ),
                          child: Text(
                            isClaimed ? 'Checked-In Guest' : 'Pending',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close, color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Info Grid
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
                ),
                child: Column(
                  children: [
                    _detailRowStyled(
                      Icons.person,
                      'Guest Name',
                      displayName,
                      isBold: true,
                    ),
                    const Divider(height: 24),
                    _detailRowStyled(
                      Icons.confirmation_number_outlined,
                      'PNR Code',
                      pnr,
                      isBold: true,
                    ),
                    if (isClaimed && room['guestName'] != null) ...[
                      const Divider(height: 24),
                      _detailRowStyled(
                        Icons.info_outline,
                        'Reservation Name',
                        room['guestName'],
                      ),
                    ],
                    const Divider(height: 24),
                    _detailRowStyled(
                      Icons.email_outlined,
                      'Email',
                      room['guestEmail'] ?? '-',
                    ),
                    const Divider(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: _detailRowStyled(
                            Icons.login,
                            'Check-In',
                            checkIn != null ? fmt.format(checkIn) : '-',
                            isSmall: true,
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 40,
                          color: Colors.grey.withValues(alpha: 0.2),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _detailRowStyled(
                            Icons.logout,
                            'Check-Out',
                            checkOut != null ? fmt.format(checkOut) : '-',
                            isSmall: true,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // QR Code Section
              if (room['data'] != null &&
                  room['data']['qrCodeData'] != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F7FF),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFBFDBFE)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.qr_code_2,
                            color: const Color(0xFF2E5077),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Room QR Code',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2E5077),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: QrImageView(
                          data: room['data']['qrCodeData'],
                          version: QrVersions.auto,
                          size: 150,
                          backgroundColor: Colors.white,
                          eyeStyle: const QrEyeStyle(
                            eyeShape: QrEyeShape.square,
                            color: Color(0xFF2E5077),
                          ),
                          dataModuleStyle: const QrDataModuleStyle(
                            dataModuleShape: QrDataModuleShape.square,
                            color: Color(0xFF1C1C1E),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // Actions
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _confirmAndDeleteReservation(
                      context,
                      room['number'].toString(),
                    );
                  },
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  label: const Text(
                    'End Reservation',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.red.withValues(alpha: 0.3)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRowStyled(
    IconData icon,
    String label,
    String value, {
    bool isBold = false,
    bool isSmall = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey[400]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: isSmall ? 14 : 15,
                  fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
                  color: Colors.black87,
                  letterSpacing: isBold ? 1.0 : 0,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _confirmAndDeleteReservation(BuildContext context, String roomNumber) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red[50], // Soft red
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.red,
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Delete Reservation?',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Reservation for room $roomNumber will be deleted.\nThis action cannot be undone.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () async {
                        Navigator.pop(ctx);
                        // Loading
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (_) =>
                              const Center(child: CircularProgressIndicator()),
                        );
                        try {
                          await DatabaseService().deleteReservation(
                            widget.hotelName,
                            roomNumber,
                          );
                          if (context.mounted) {
                            Navigator.pop(context); // Close loading
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Deleted!'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: $e')),
                            );
                          }
                        }
                      },
                      child: const Text(
                        'Delete',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value ?? '-',
              style: const TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

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
  final VoidCallback? onTap;

  const _RoomGridCard({required this.room, this.onTap});

  @override
  Widget build(BuildContext context) {
    final status = room['status'];
    final bool isOccupied = status == 'Occupied';

    // Daha Keskin/Vivid Renkler
    Color accentColor = const Color(0xFF10B981); // Canlı Yeşil (Emerald)
    Color bgColor = Colors.white;
    IconData statusIcon = Icons.check_circle;
    String statusText = 'Available';

    if (isOccupied) {
      accentColor = const Color(0xFFF59E0B); // Canlı Turuncu (Amber)
      statusIcon = Icons.person;
      statusText = 'Occupied';
    } else if (status == 'Cleaning') {
      accentColor = const Color(0xFF3B82F6); // Canlı Mavi
      statusIcon = Icons.cleaning_services;
      statusText = 'Cleaning';
    } else if (status == 'Maintenance') {
      accentColor = const Color(0xFFEF4444); // Canlı Kırmızı
      statusIcon = Icons.build;
      statusText = 'Maintenance';
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(
            12,
          ), // Biraz daha az yuvarlatılmış
          border: Border.all(
            color: accentColor,
            width: 2,
          ), // Kalın, belirgin çerçeve
          boxShadow: [
            BoxShadow(
              color: accentColor.withValues(
                alpha: 0.15,
              ), // Gölge rengi statüyle eşleşsin
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
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(9),
                ), // İç border uyumu için
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'ROOM ${room['number']}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      color: Colors.white, // Beyaz yazı
                      letterSpacing: 1.0,
                    ),
                  ),
                  Row(
                    children: [
                      // DND ICON
                      if (room['isDnd'] == true) ...[
                        const Icon(
                          Icons.do_not_disturb_on,
                          color: Colors.white,
                          size: 18,
                        ),
                        const SizedBox(width: 4),
                      ],
                      Icon(statusIcon, color: Colors.white, size: 18),
                    ],
                  ),
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
                          // 1. Misafir İsmi
                          // Eğer gerçek kullanıcı giriş yapmışsa onun adını göster
                          Builder(
                            builder: (context) {
                              final String? claimedName = room['data'] != null
                                  ? room['data']['claimedGuestName']
                                  : null;
                              final String displayName =
                                  (claimedName != null &&
                                      claimedName.isNotEmpty)
                                  ? claimedName
                                  : (room['guestName'] ?? 'Guest');

                              final bool isClaimed =
                                  claimedName != null && claimedName.isNotEmpty;

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    displayName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 17,
                                      color: isClaimed
                                          ? const Color(0xFF047857)
                                          : const Color(
                                              0xFF1E293B,
                                            ), // Green if claimed
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  if (isClaimed)
                                    const Text(
                                      '(Checked In)',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.green,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 8),

                          // 2. PNR Chip & Status
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEFF6FF), // Blue 50
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: const Color(0xFFBFDBFE),
                                  ), // Blue 200
                                ),
                                child: Text(
                                  room['pnr'] ?? '',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF1E40AF), // Blue 800
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Eğer statüsü 'used' ise (Müşteri PNR girmis)
                              if (room['data'] != null &&
                                  room['data']['status'] == 'used')
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFECFDF5), // Green 50
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: const Color(0xFF6EE7B7),
                                    ), // Green 300
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.check_circle,
                                        size: 12,
                                        color: Color(0xFF059669),
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        'Active',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF047857),
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              else if (room['data'] != null &&
                                  room['data']['status'] == 'active')
                                Container(
                                  // Bekliyor
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFF7ED), // Orange 50
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: const Color(0xFFFDBA74),
                                    ), // Orange 300
                                  ),
                                  child: const Text(
                                    'Pending',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFFC2410C),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const Spacer(),

                          // 3. Tarih Bilgisi (Giriş - Çıkış)
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.grey.withValues(alpha: 0.2),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.date_range,
                                  size: 14,
                                  color: Colors.grey,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    (room['checkOut'] != null &&
                                            room['checkOut'] is Timestamp)
                                        ? DateFormat('dd MMM', 'tr_TR').format(
                                            (room['checkOut'] as Timestamp)
                                                .toDate(),
                                          )
                                        : '-',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: accentColor,
                                    ),
                                  ),
                                ),
                                const Icon(
                                  Icons.logout,
                                  size: 14,
                                  color: Colors.grey,
                                ),
                              ],
                            ),
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
      ),
    );
  }
}
