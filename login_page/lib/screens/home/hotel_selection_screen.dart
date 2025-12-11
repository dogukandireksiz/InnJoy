import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../service/database_service.dart';

import 'home_screen.dart';

class HotelSelectionScreen extends StatefulWidget {
  const HotelSelectionScreen({super.key});

  @override
  State<HotelSelectionScreen> createState() => _HotelSelectionScreenState();
}

class _HotelSelectionScreenState extends State<HotelSelectionScreen> {
  final List<Map<String, String>> _hotels = [
    {
      'name': 'Urban Joy Hotel',
      'image': 'https://images.unsplash.com/photo-1566073771259-6a8506099945?ixlib=rb-4.0.3&auto=format&fit=crop&w=1170&q=80',
    },
    {
      'name': 'Grand Horizon Suites',
      'image': 'https://images.unsplash.com/photo-1582719508461-905c673771fd?ixlib=rb-4.0.3&auto=format&fit=crop&w=1025&q=80',
    },
    {
      'name': 'Sunset Bay Inn',
      'image': 'https://images.unsplash.com/photo-1571003123894-1f0594d2b5d9?ixlib=rb-4.0.3&auto=format&fit=crop&w=1049&q=80',
    },
    {
      'name': 'Cityscape Central Hotel',
      'image': 'https://images.unsplash.com/photo-1542314831-068cd1dbfeeb?ixlib=rb-4.0.3&auto=format&fit=crop&w=1170&q=80',
    },
  ];

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

  void _onHotelSelected(String hotelName) {
    // Eğer kullanıcı zaten bu otele kayıtlıysa direkt ana ekrana git
    if (_currentHotelName != null && _currentHotelName == hotelName) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => HomeScreen(userName: 'Misafir')),
      );
    } else {
      // Değilse PNR sor
      _showPnrDialog(context, hotelName);
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredHotels = _hotels.where((hotel) {
      final name = hotel['name']!.toLowerCase();
      final query = _searchQuery.toLowerCase();
      return name.contains(query);
    }).toList();

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
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Hotel List
              if (filteredHotels.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Text('No hotels found', style: TextStyle(color: Colors.grey)),
                  ),
                )
              else
                ...filteredHotels.map((hotel) => _HotelCard(
                      name: hotel['name']!,
                      imageUrl: hotel['image']!,
                      onSelect: () => _onHotelSelected(hotel['name']!),
                    )),
            ],
          ),
        ),
      ),
    );
  }

  void _showPnrDialog(BuildContext context, String hotelName) {
    final TextEditingController pnrController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$hotelName Girişi'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Lütfen resepsiyondan aldığınız 6 haneli PNR kodunu giriniz.'),
            const SizedBox(height: 16),
            TextField(
              controller: pnrController,
              decoration: const InputDecoration(
                labelText: 'PNR Kodu',
                border: OutlineInputBorder(),
                hintText: 'Örn: XK92M4',
              ),
              textCapitalization: TextCapitalization.characters,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
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
                builder: (ctx) => const Center(child: CircularProgressIndicator()),
              );

              // PNR Doğrulama
              bool isValid = await DatabaseService().verifyAndRedeemPnr(
                pnrController.text.trim().toUpperCase(),
                 hotelName, 
                 userId
              );

              // Loading kapat
              navigator.pop();

              if (isValid) {
                // Başarılı -> PreTripScreen'e yönlendir
                navigator.pushReplacement(
                  MaterialPageRoute(builder: (_) => HomeScreen(userName: 'Misafir')),
                );
              } else {
                // Hata göster
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('Geçersiz veya kullanılmış PNR kodu!'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5A67D8),
              foregroundColor: Colors.white,
            ),
            child: const Text('Giriş Yap'),
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

  const _HotelCard({
    required this.name,
    required this.imageUrl,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 240,
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        image: DecorationImage(
          image: NetworkImage(imageUrl),
          fit: BoxFit.cover,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
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
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.7),
                ],
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
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
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
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: onSelect,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(0.4)),
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
