import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/database_service.dart';

import 'home_screen.dart';

class HotelSelectionScreen extends StatefulWidget {
  const HotelSelectionScreen({super.key});

  @override
  State<HotelSelectionScreen> createState() => _HotelSelectionScreenState();
}

class _HotelSelectionScreenState extends State<HotelSelectionScreen> {
  String _searchQuery = '';
  String? _currentHotelName;

  @override
  void initState() {
    super.initState();
    _fetchUserHotel();
  }

  Future<void> _fetchUserHotel() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userData = await DatabaseService().getUserData(user.uid);
      if (mounted && userData != null) {
        setState(() {
          _currentHotelName = userData['hotelName'];
        });
      }
    }
  }

  void _onHotelSelected(String hotelName, {String? hotelId}) {
    // Eğer kullanıcı zaten bu otele kayıtlıysa direkt ana ekrana git
    if (_currentHotelName != null && _currentHotelName == hotelName) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => HomeScreen(userName: 'Guest')),
      );
    } else {
      // Değilse PNR sor
      // Use hotelId if available (for database lookups), otherwise fall back to hotelName
      _showPnrDialog(context, hotelName, hotelId: hotelId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  RichText(
                    text: const TextSpan(
                      children: [
                        TextSpan(
                          text: 'Inn',
                          style: TextStyle(
                            color: Color(0xFF5A67D8), // Indigo
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        TextSpan(
                          text: 'joy',
                          style: TextStyle(
                            color: Colors.orange,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ],
                    ),
                  ),
                  CircleAvatar(
                    backgroundColor: Colors.grey[100],
                    child: Icon(Icons.person, color: Colors.grey[600]),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Search Bar
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search, color: Colors.grey),
                    hintText: 'Search Hotel',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Hotel List (StreamBuilder)
              StreamBuilder<List<Map<String, dynamic>>>(
                stream: DatabaseService().getHotels(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  final hotels = snapshot.data ?? [];

                  // FORCE SHOW: Urban Joy Hotel (Client-side Only)
                  // Ensures it appears in the list even if parent doc is missing (Ghost Doc)
                  // Details will be fetched from 'hotel information' subcollection by the card.
                  if (!hotels.any(
                    (h) =>
                        h['name'] == 'Urban Joy Hotel' ||
                        h['id'] == 'Urban Joy Hotel',
                  )) {
                    hotels.add({
                      'id': 'Urban Joy Hotel',
                      'name': 'Urban Joy Hotel',
                      'hotelName': 'Urban Joy Hotel',
                      'isManual': true,
                    });
                  }

                  // Ensure current user's hotel is in the list if plausible
                  if (_currentHotelName != null &&
                      _currentHotelName!.isNotEmpty) {
                    final exists = hotels.any(
                      (h) =>
                          (h['name'] == _currentHotelName) ||
                          (h['hotelName'] == _currentHotelName) ||
                          (h['id'] == _currentHotelName),
                    );

                    if (!exists) {
                      // Manually add the current hotel so the user can select it
                      // We assume the stored _currentHotelName is the ID or Name
                      hotels.add({
                        'id': _currentHotelName,
                        'name': _currentHotelName,
                        'hotelName': _currentHotelName,
                        'isManual': true, // Marker
                      });
                    }
                  }

                  final filteredHotels = hotels.where((hotel) {
                    // Use the same name resolution logic as the card
                    String? name = hotel['name'];
                    String? hotelName = hotel['hotelName'];
                    String? id = hotel['id'];

                    String displayName = (name != null && name.isNotEmpty)
                        ? name
                        : (hotelName != null && hotelName.isNotEmpty)
                        ? hotelName
                        : (id ?? 'Unknown Hotel');

                    final query = _searchQuery.toLowerCase();
                    return displayName.toLowerCase().contains(query);
                  }).toList();

                  // Sort: User's hotel first
                  if (_currentHotelName != null) {
                    filteredHotels.sort((a, b) {
                      final aId = a['id'];
                      final aName = a['name'] ?? a['hotelName'];

                      final bId = b['id'];
                      final bName = b['name'] ?? b['hotelName'];

                      bool isA =
                          (aId == _currentHotelName ||
                          aName == _currentHotelName);
                      bool isB =
                          (bId == _currentHotelName ||
                          bName == _currentHotelName);

                      if (isA && !isB) return -1;
                      if (!isA && isB) return 1;
                      return 0;
                    });
                  }

                  if (filteredHotels.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20.0),
                        child: Text(
                          'No hotels found',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    );
                  }

                  return Column(
                    children: filteredHotels.map((hotel) {
                      final String hotelId = hotel['id'];

                      // Check if this is the user's hotel
                      bool isUserHotel = false;
                      if (_currentHotelName != null) {
                        isUserHotel =
                            (hotelId == _currentHotelName) ||
                            (hotel['name'] == _currentHotelName) ||
                            (hotel['hotelName'] == _currentHotelName);
                      }

                      // Base name from the 'hotels' collection document
                      final String baseName =
                          hotel['name'] ?? hotel['hotelName'] ?? hotelId;

                      return StreamBuilder<Map<String, dynamic>?>(
                        stream: DatabaseService().getHotelInfo(hotelId),
                        builder: (context, infoSnapshot) {
                          String displayName = baseName;
                          // Default image if missing
                          String imageUrl =
                              'https://images.unsplash.com/photo-1566073771259-6a8506099945?ixlib=rb-4.0.3&auto=format&fit=crop&w=1170&q=80';

                          if (infoSnapshot.hasData &&
                              infoSnapshot.data != null) {
                            final info = infoSnapshot.data!;
                            if (info['name'] != null &&
                                info['name'].toString().isNotEmpty) {
                              displayName = info['name'];
                            }
                            // Also check 'hotelName' inside info, just in case
                            else if (info['hotelName'] != null &&
                                info['hotelName'].toString().isNotEmpty) {
                              displayName = info['hotelName'];
                            }

                            if (info['imageUrl'] != null &&
                                info['imageUrl'].toString().isNotEmpty) {
                              imageUrl = info['imageUrl'];
                            }
                          }

                          // If we are still loading the detailed info, show the card with base info
                          // instead of waiting or showing nothing.
                          return _HotelCard(
                            name: displayName,
                            imageUrl: imageUrl,
                            isUserHotel: isUserHotel,
                            onSelect: () =>
                                _onHotelSelected(displayName, hotelId: hotelId),
                          );
                        },
                      );
                    }).toList(),
                  );
                },
              ),
              // Debug info (Temporary - unseen but useful if we could see logs)
              if (_currentHotelName != null)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    "Current Hotel: $_currentHotelName",
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPnrDialog(
    BuildContext context,
    String hotelName, {
    String? hotelId,
  }) {
    final TextEditingController pnrController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$hotelName Check-In'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Please enter the 6-digit PNR code you received from reception.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: pnrController,
              decoration: const InputDecoration(
                labelText: 'PNR Code',
                border: OutlineInputBorder(),
                hintText: 'e.g. XK92M4',
              ),
              textCapitalization: TextCapitalization.characters,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (pnrController.text.isEmpty) return;

              final messenger = ScaffoldMessenger.of(context);
              final navigator = Navigator.of(context);
              final userId = FirebaseAuth.instance.currentUser?.uid;

              if (userId == null) return;

              // Dialogu kapat ve loading göster
              navigator.pop();
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (ctx) =>
                    const Center(child: CircularProgressIndicator()),
              );

              // PNR Doğrulama
              bool isValid = await DatabaseService().verifyAndRedeemPnr(
                pnrController.text.trim().toUpperCase(),
                hotelId ?? hotelName, // Use ID if available, otherwise name
                userId,
              );

              // Loading kapat
              navigator.pop();

              if (isValid) {
                // Başarılı -> PreTripScreen'e yönlendir
                navigator.pushReplacement(
                  MaterialPageRoute(
                    builder: (_) => HomeScreen(userName: 'Guest'),
                  ),
                );
              } else {
                // Hata göster
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('Invalid or already used PNR code!'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5A67D8),
              foregroundColor: Colors.white,
            ),
            child: const Text('Check In'),
          ),
        ],
      ),
    );
  }
}

class _HotelCard extends StatelessWidget {
  final String name;
  final String imageUrl;
  final VoidCallback onSelect;
  final bool isUserHotel;

  const _HotelCard({
    required this.name,
    required this.imageUrl,
    required this.onSelect,
    this.isUserHotel = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 240,
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        image: DecorationImage(
          image: imageUrl.startsWith('http')
              ? NetworkImage(imageUrl) as ImageProvider
              : AssetImage(imageUrl),
          fit: BoxFit.cover,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Gradient Overlay
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black.withValues(alpha: 0.7)],
              ),
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Row(
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22, // Reduced slightly to fit badge if needed
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            offset: Offset(0, 2),
                            blurRadius: 4,
                            color: Colors.black54,
                          ),
                        ],
                      ),
                    ),
                    if (isUserHotel)
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Text(
                          'Your Hotel',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: onSelect,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
                      // Backdrop filter is hard in simple Container, usually needs ClipRect + BackdropFilter widget
                    ),
                    child: const Text(
                      'Select Hotel',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}









