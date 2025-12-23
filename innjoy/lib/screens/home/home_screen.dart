import 'package:flutter/material.dart';
import 'package:login_page/services/logger_service.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../emergency/emergency_screen.dart';
import 'dart:ui';
import '../services/service_screen.dart';
import '../events_activities/events_activities_screen.dart';
import '../events_activities/event_details_screen.dart';
import '../room_service/room_service_screen.dart';
import '../housekeeping/housekeeping_screen.dart';
import '../profile/profile_screen.dart';
import '../../services/database_service.dart';
import '../../utils/dialogs/custom_dialog.dart';
import 'hotel_selection_screen.dart';
import '../../widgets/auth_wrapper.dart';
import '../customer/my_plans_screen.dart';
import '../requests/customer_requests_screen.dart';
import '../payment/spending_tracker_screen.dart';
import '../../map/map_screen.dart';
import 'admin_home_screen.dart';
import '../../widgets/common/custom_top_navigation_bar.dart';
import '../../widgets/admin/admin_action_bar.dart';
import 'package:latlong2/latlong.dart';

/// Ana Ekran (Home Screen)
///
/// Kullanıcının otel deneyimini yönettiği, hizmetlere, etkinliklere
/// ve fatura detaylarına erişebildiği ana kontrol panelidir.
class HomeScreen extends StatefulWidget {
  final String userName;
  final bool? isAdmin; // Gecikmeyi önlemek iÇin opsiyonel parametre
  final String? hotelName; // Admin Guest View iÇin opsiyonel

  const HomeScreen({
    super.key,
    required this.userName,
    this.isAdmin,
    this.hotelName,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late bool _isAdmin;
  String? _hotelName;
  String? _roomNumber;
  DateTime? _checkIn;
  DateTime? _checkOut;
  String? _userName; // Added for dynamic name
  String? _qrCodeData; // QR kod verisi

  // Data caching flags to prevent flicker on navigation back
  bool _isLoading = true;
  bool _dataLoaded = false;

  // PageView State
  int _selectedIndex = 0;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    // Ežğer parametre geldiyse direkt onu kullan (Gecikme olmaz)
    // Gelmediyse varsayılan false ve asenkron kontrol
    _isAdmin = widget.isAdmin ?? false;
    _hotelName = widget.hotelName;

    // Parametre gelmediyse veya otel adı yoksa kontrol et (User ise)
    if (widget.isAdmin == null || (_hotelName == null && !_isAdmin)) {
      _checkUserRole();
    } else {
      // Data already provided via parameters, no loading needed
      _isLoading = false;
      _dataLoaded = true;
    }
  }

  Future<void> _checkUserRole() async {
    // Skip if data already loaded (prevents flicker on navigation back)
    if (_dataLoaded) {
      if (mounted && _isLoading) {
        setState(() => _isLoading = false);
      }
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userData = await DatabaseService().getUserData(user.uid);
      final role = userData?['role'];
      final hotel = userData?['hotelName'];
      final room = userData?['roomNumber'];

      // Robust Date Parsing
      DateTime? checkInDate;
      DateTime? checkOutDate;

      // 1. Try fetching from User Profile
      try {
        final rawCheckIn = userData?['checkInDate'];
        if (rawCheckIn is Timestamp) {
          checkInDate = rawCheckIn.toDate();
        } else if (rawCheckIn is String) {
          checkInDate = DateTime.tryParse(rawCheckIn);
        }

        final rawCheckOut = userData?['checkOutDate'];
        if (rawCheckOut is Timestamp) {
          checkOutDate = rawCheckOut.toDate();
        } else if (rawCheckOut is String) {
          checkOutDate = DateTime.tryParse(rawCheckOut);
        }
      } catch (e) {
        Logger.debug("Date parsing error: $e");
      }

      // 2. Always Fetch from Active Reservation to ensure latest dates (Database is source of truth)
      if (hotel != null) {
        try {
          final query = await FirebaseFirestore.instance
              .collection('hotels')
              .doc(hotel)
              .collection('reservations')
              .where('usedBy', isEqualTo: user.uid)
              .where('status', isEqualTo: 'used')
              .limit(1)
              .get();

          if (query.docs.isNotEmpty) {
            final resData = query.docs.first.data();
            final rawResCheckIn = resData['checkInDate'];
            final rawResCheckOut = resData['checkOutDate'];

            // Note: Timestamps are often stored as Midnight Local Time.
            // If the device is in a different timezone (e.g. UTC), Midnight +3 becomes 9PM Previous Day.
            // We add a few hours to ensure we land on the correct calendar day for display purposes.
            if (rawResCheckIn is Timestamp) {
              checkInDate = rawResCheckIn.toDate().add(
                const Duration(hours: 12),
              );
            }
            if (rawResCheckOut is Timestamp) {
              checkOutDate = rawResCheckOut.toDate().add(
                const Duration(hours: 12),
              );
            }
            // QR Kod verisini al
            if (resData['qrCodeData'] != null) {
              _qrCodeData = resData['qrCodeData'];
            }
          }
        } catch (e) {
          Logger.debug("Reservation fetch error: $e");
        }
      }

      if (mounted) {
        setState(() {
          // Ežğer admin parametresi geldiyse onu ezme, sadece hotelName al
          if (widget.isAdmin == null) _isAdmin = role == 'admin';
          _hotelName ??= hotel;
          _roomNumber = room ?? _roomNumber;
          // Fetch user name
          if (userData?['name_username'] != null) {
            _userName = userData!['name_username'];
          }
          _checkIn = checkInDate;
          _checkOut = checkOutDate;
          _isLoading = false;
          _dataLoaded = true; // Mark data as loaded to prevent future fetches
        });
      }
    } else {
      // No user, still mark loading as complete
      if (mounted) {
        setState(() {
          _isLoading = false;
          _dataLoaded = true;
        });
      }
    }
  }

  /// Force refresh all cached data - call this after profile updates, room changes, etc.
  Future<void> _forceRefreshData() async {
    setState(() {
      _isLoading = true;
      _dataLoaded = false; // Reset cache flag to allow re-fetch
    });
    await _checkUserRole();
  }

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;
    _pageController.jumpToPage(index);
  }

  void _onPageChanged(int index) {
    if (index != _selectedIndex) {
      if (mounted) {
        setState(() => _selectedIndex = index);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true, // Transparent bottom bar
      backgroundColor: const Color(0xFFF6F7FB),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: SizedBox(
        height: 52,
        width: 52,
        child: FloatingActionButton(
          onPressed: () {
            Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const EmergencyScreen()));
          },
          backgroundColor: Colors.red,
          elevation: 4,
          child: const Icon(
            Icons.warning_amber_rounded,
            color: Colors.white,
            size: 26,
          ),
        ),
      ),
      bottomNavigationBar: _CustomBottomBar(
        selectedIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        physics: const ClampingScrollPhysics(),
        children: [
          // 0: Home Page
          _HomeDashboard(
            userName:
                _userName ?? (widget.userName.isEmpty ? 'Guest' : widget.userName),
            isAdmin: _isAdmin,
            hotelName: _hotelName,
            roomNumber: _roomNumber,
            checkIn: _checkIn,
            checkOut: _checkOut,
            qrCodeData: _qrCodeData,
            onRefresh: _forceRefreshData,
            onNavigateToProfile: () => _onItemTapped(3),
          ),
          // 1: Map Page
          const MapScreen(
            selectedLocation: LatLng(37.21597166446968, 28.3524471232014584),
            isTabView: true,
          ),
          // 2: Services Page
          ServiceScreen(hotelName: _hotelName, isTabView: true),
          // 3: Profile Page
          const ProfileScreen(isTabView: true),
        ],
      ),
    );
  }
}

class _HomeDashboard extends StatelessWidget {
  final String userName;
  final bool isAdmin;
  final String? hotelName;
  final String? roomNumber;
  final DateTime? checkIn;
  final DateTime? checkOut;
  final String? qrCodeData;
  final Future<void> Function() onRefresh;
  final VoidCallback onNavigateToProfile;

  const _HomeDashboard({
    required this.userName,
    required this.isAdmin,
    this.hotelName,
    this.roomNumber,
    this.checkIn,
    this.checkOut,
    this.qrCodeData,
    required this.onRefresh,
    required this.onNavigateToProfile,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, // Background handled by outer page/scaffold or set here
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFF6F7FB),
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        titleSpacing: 0,
        // PreTripScreen'e geri dönüş butonu (login_page projesinden korundu)
        leading: isAdmin
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.grey),
                onPressed: () {
                  // Müşteri ise otel seÇimine gitsin
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (_) => const HotelSelectionScreen(),
                    ),
                  );
                },
                tooltip: 'Back',
              ),
        actions: [
          if (isAdmin)
            Padding(
              padding: const EdgeInsets.only(right: 12, top: 16),
              child: AdminActionBar(
                activeView: AdminPanelView.guest,
                theme: ToggleTheme.light,
                onGuestViewTap: () {},
                onAdminPanelTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const AdminHomeScreen()),
                  );
                },
                onLogoutTap: () async {
                  final shouldLogout = await CustomDialog.show(
                    context,
                    title: 'Log Out',
                    message: 'Are you sure you want to log out?',
                    confirmText: 'Log Out',
                    cancelText: 'Cancel',
                    isDanger: true,
                  );
                  if (shouldLogout == true) {
                    await FirebaseAuth.instance.signOut();
                    if (context.mounted) {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                          builder: (context) => const AuthWrapper(),
                        ),
                        (route) => false,
                      );
                    }
                  }
                },
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: GestureDetector(
                onTap: onNavigateToProfile,
                child: StreamBuilder<User?>(
                  stream: FirebaseAuth.instance.userChanges(),
                  builder: (context, snapshot) {
                    final user = snapshot.data;
                    return Container(
                      width: 45,
                      height: 45,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFE3F2FD),
                        image: DecorationImage(
                          image: user?.photoURL != null
                              ? (user!.photoURL!.startsWith('assets/')
                                  ? AssetImage(user.photoURL!) as ImageProvider
                                  : NetworkImage(user.photoURL!))
                              : const AssetImage(
                                  'assets/avatars/default_avatar.png'),
                          fit: BoxFit.cover,
                        ),
                      ),
                      child: null,
                    );
                  },
                ),
              ),
            ),
        ],
        title: isAdmin
            ? null
            : Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Welcome back,',
                          style: TextStyle(color: Colors.black54, fontSize: 14),
                        ),
                        Text(
                          userName,
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
      ),
      body: RefreshIndicator(
        onRefresh: onRefresh,
        color: const Color(0xFF0057FF),
        child: SingleChildScrollView(
          physics:
              const AlwaysScrollableScrollPhysics(), // Enable pull even when content is short
          padding: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 90),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _HotelCard(
                hotelName: hotelName ?? 'InnJoy Hotel',
                roomNumber: roomNumber,
                checkIn: checkIn,
                checkOut: checkOut,
                qrCodeData: qrCodeData,
              ),
              const SizedBox(height: 16),

              // My Plans Button
              InkWell(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const MyPlansScreen()),
                  );
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0057FF).withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.calendar_today,
                          color: Color(0xFF0057FF),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'My Plans',
                            style: TextStyle(
                              color: Color(0xFF0D141B),
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'View your itinerary',
                            style: TextStyle(color: Colors.grey, fontSize: 14),
                          ),
                        ],
                      ),
                      const Spacer(),
                      const Icon(Icons.arrow_forward, color: Colors.grey),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // My Requests Button
              InkWell(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => CustomerRequestsScreen(
                        hotelName: hotelName ?? 'InnJoy Hotel',
                      ),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.receipt_long,
                          color: Colors.orange,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'My Requests',
                            style: TextStyle(
                              color: Color(0xFF0D141B),
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Track your orders & requests',
                            style: TextStyle(color: Colors.grey, fontSize: 14),
                          ),
                        ],
                      ),
                      const Spacer(),
                      const Icon(Icons.arrow_forward, color: Colors.grey),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              const Text(
                'Need Something?',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _ServiceTile(
                      icon: Icons.cleaning_services,
                      label: 'Housekeeping',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const HousekeepingScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ServiceTile(
                      icon: Icons.room_service,
                      label: 'Room Service',
                      onTap: () {
                        Navigator.of(context)
                            .push(
                              MaterialPageRoute(
                                builder: (_) => RoomServiceScreen(
                                  hotelName: hotelName ?? 'InnJoy Hotel',
                                ),
                              ),
                            )
                            .then((_) => onRefresh());
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "What's On Today",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => EventsActivitiesScreen(
                            hotelName: hotelName ?? 'InnJoy Hotel',
                          ),
                        ),
                      );
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.black87,
                      padding: EdgeInsets.zero,
                    ),
                    child: const Row(
                      children: [
                        Text('All Events'),
                        SizedBox(width: 4),
                        Icon(Icons.chevron_right, size: 20),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 160,
                child: hotelName == null
                    ? const Center(child: CircularProgressIndicator())
                    : StreamBuilder<List<Map<String, dynamic>>>(
                        stream: DatabaseService().getHotelEvents(hotelName!),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }
                          if (snapshot.hasError) {
                            return const Center(child: Text("Failed to load"));
                          }

                          final allEvents = snapshot.data ?? [];
                          final now = DateTime.now();

                          // Filter: Published AND Today
                          final events = allEvents.where((e) {
                            if (e['isPublished'] != true) return false;

                            final dateTs = e['date'] as Timestamp?;
                            if (dateTs == null) return false;

                            final d = dateTs.toDate();
                            return d.year == now.year &&
                                d.month == now.month &&
                                d.day == now.day;
                          }).toList();

                          // Sort by date (time)
                          events.sort((a, b) {
                            final da = (a['date'] as Timestamp).toDate();
                            final db = (b['date'] as Timestamp).toDate();
                            return da.compareTo(db);
                          });

                          if (events.isEmpty) {
                            return Container(
                              width: double.infinity,
                              margin: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              padding: const EdgeInsets.symmetric(
                                vertical: 16,
                                horizontal: 16,
                              ), // Reduced padding
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.grey.withValues(alpha: 0.1),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.03),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(
                                      8,
                                    ), // Reduced padding
                                    decoration: BoxDecoration(
                                      color: Colors.blue.withValues(alpha: 0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.event_busy_rounded,
                                      color: Colors.blue,
                                      size: 28,
                                    ), // Reduced size
                                  ),
                                  const SizedBox(height: 8), // Reduced spacing
                                  const Text(
                                    "No events scheduled for today.",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 16, // Reduced font size
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF0D141B),
                                    ),
                                  ),
                                  const SizedBox(height: 4), // Reduced spacing
                                  Text(
                                    "Feel free to browse other days!",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 14, // Reduced font size
                                      color: Colors.grey[600],
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }

                          return ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: events.length,
                            separatorBuilder: (_, e) =>
                                const SizedBox(width: 12),
                            itemBuilder: (context, index) {
                              final e = events[index];
                              final title = e['title'] ?? 'Unnamed Event';
                              final time = e['time'] ?? '';
                              final location =
                                  e['location'] ?? ''; // Extract location
                              final imageAsset = e['imageAsset'];

                              return _EventCard(
                                title: title,
                                time: time, // Pass time
                                location: location, // Pass location
                                imageAsset: imageAsset,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => EventDetailsScreen(
                                        event: e,
                                        hotelName: hotelName!,
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          );
                        },
                      ),
              ),
              const SizedBox(height: 20),

              const Text(
                'Spending Summary',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              _SpendingCard(hotelName: hotelName),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

/// Otel Bilgi Kartı
///
/// Kullanıcının konakladığı otel adı, oda numarası ve tarih aralığını gösterir.
/// Ayrıca kapı kilit aÇma (Unlock) butonu burada bulunur.
class _HotelCard extends StatefulWidget {
  final String hotelName;
  final String? roomNumber;
  final DateTime? checkIn;
  final DateTime? checkOut;
  final String? qrCodeData;

  const _HotelCard({
    required this.hotelName,
    this.roomNumber,
    this.checkIn,
    this.checkOut,
    this.qrCodeData,
  });

  @override
  State<_HotelCard> createState() => _HotelCardState();
}

class _HotelCardState extends State<_HotelCard> {
  String? _cachedImageUrl;
  bool _imageLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadHotelImage();
  }

  @override
  void didUpdateWidget(covariant _HotelCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reload image if hotel name changed (e.g., after refresh)
    if (oldWidget.hotelName != widget.hotelName) {
      _imageLoaded = false;
      _cachedImageUrl = null;
      _loadHotelImage();
    }
  }

  Future<void> _loadHotelImage() async {
    if (_imageLoaded) return; // Skip if already loaded

    try {
      final hotelInfo = await DatabaseService()
          .getHotelInfo(widget.hotelName)
          .first;
      if (mounted && hotelInfo != null) {
        setState(() {
          _cachedImageUrl = hotelInfo['imageUrl'];
          _imageLoaded = true;
        });
      } else if (mounted) {
        setState(() => _imageLoaded = true);
      }
    } catch (e) {
      Logger.debug("Hotel image load error: $e");
      if (mounted) {
        setState(() => _imageLoaded = true);
      }
    }
  }

  void _showComingSoonDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
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
                // Icon with gradient background
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0057FF), Color(0xFF00A3FF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0057FF).withValues(alpha: 0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.nfc_rounded,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 24),
                // Title
                const Text(
                  'Coming Soon!',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1C1C1E),
                  ),
                ),
                const SizedBox(height: 12),
                // Message
                Text(
                  'We are working on NFC Keyless Entry. Soon you will be able to unlock your room just by tapping your phone!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey[600],
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                // Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0057FF),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Got it',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showQrCodeDialog(BuildContext context) {
    if (widget.qrCodeData == null || widget.qrCodeData!.isEmpty) {
      // QR kodu yok - bilgi mesajı göster
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('QR code not available yet. Please check back later.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
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
                // Header
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0057FF), Color(0xFF00A3FF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.qr_code_2,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Your Room QR Code',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1C1C1E),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Room ${widget.roomNumber ?? "N/A"}',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                const SizedBox(height: 20),
                // QR Code
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.grey.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: QrImageView(
                    data: widget.qrCodeData!,
                    version: QrVersions.auto,
                    size: 200,
                    backgroundColor: Colors.white,
                    eyeStyle: const QrEyeStyle(
                      eyeShape: QrEyeShape.square,
                      color: Color(0xFF0057FF),
                    ),
                    dataModuleStyle: const QrDataModuleStyle(
                      dataModuleShape: QrDataModuleShape.square,
                      color: Color(0xFF1C1C1E),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Show this QR code for room access',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                ),
                const SizedBox(height: 20),
                // Close Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0057FF),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Close',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    String dateRange = 'Date Info Unavailable';
    if (widget.checkIn != null && widget.checkOut != null) {
      final fmt = DateFormat('MMM dd');
      dateRange =
          '${fmt.format(widget.checkIn!)} - ${fmt.format(widget.checkOut!)}';
    } else if (widget.checkIn != null) {
      dateRange = 'Since ${DateFormat('MMM dd').format(widget.checkIn!)}';
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          _buildHotelImage(),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.hotelName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.roomNumber != null
                      ? 'Room ${widget.roomNumber}'
                      : 'Not Assigned',
                  style: const TextStyle(color: Colors.black54),
                ),
                Text(dateRange, style: const TextStyle(color: Colors.black54)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // QR Kod Butonu
          IconButton(
            onPressed: () => _showQrCodeDialog(context),
            icon: const Icon(Icons.qr_code_2, color: Color(0xFF0057FF)),
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFF0057FF).withValues(alpha: 0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(12),
            ),
          ),
          // Kapı AÇma Düğmesi (Unlock Button)
          ElevatedButton(
            onPressed: () {
              _showComingSoonDialog(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0057FF),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              foregroundColor: Colors.white,
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.meeting_room, size: 20),
                SizedBox(width: 8),
                Text(
                  'Unlock',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHotelImage() {
    // Case 1: Valid Network URL
    if (_cachedImageUrl != null &&
        _cachedImageUrl!.isNotEmpty &&
        _cachedImageUrl!.startsWith('http')) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          _cachedImageUrl!,
          width: 60,
          height: 60,
          fit: BoxFit.cover,
          loadingBuilder: (ctx, child, progress) {
            if (progress == null) return child;
            return Container(
              color: Colors.grey[200],
              width: 60,
              height: 60,
              child: const Center(
                child: Icon(Icons.image, size: 20, color: Colors.grey),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) => _buildFallbackImage(),
        ),
      );
    }
    // Case 2: Asset Path (Data exists but is local path like 'assets/...')
    else if (_cachedImageUrl != null && _cachedImageUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.asset(
          _cachedImageUrl!,
          width: 60,
          height: 60,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            Logger.debug("Asset load failed for: $_cachedImageUrl");
            return _buildFallbackImage();
          },
        ),
      );
    }

    // Case 3: No data or still loading -> Fallback
    return _buildFallbackImage();
  }

  Widget _buildFallbackImage() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(Icons.hotel, color: Colors.grey),
    );
  }
}

class _ServiceTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  const _ServiceTile({required this.icon, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 90,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.blueAccent),
              const SizedBox(height: 8),
              Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  final String title;
  final String time;
  final String location;
  final String? imageAsset;
  final VoidCallback? onTap;

  const _EventCard({
    required this.title,
    required this.time,
    required this.location,
    this.imageAsset,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 180, // Increased width per user request
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        clipBehavior: Clip.hardEdge,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildEventImage(imageAsset),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16, // Increased from 15
                      color: Color(0xFF1C1C1E),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  // Merged Time & Location Row
                  Row(
                    children: [
                      // Time
                      Icon(
                        Icons.access_time_rounded,
                        size: 14,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          time,
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 14, // Increased from 12
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                      const SizedBox(width: 8),
                      Text('•', style: TextStyle(color: Colors.grey[400])),
                      const SizedBox(width: 8),

                      // Location
                      Icon(
                        Icons.location_on_rounded,
                        size: 14,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          location,
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 14, // Increased from 12
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventImage(String? imageAsset) {
    const fallbackAsset = 'assets/images/arkaplanyok1.png';
    const double imageHeight = 80;

    // No image provided
    if (imageAsset == null || imageAsset.isEmpty) {
      return Image.asset(
        fallbackAsset,
        width: double.infinity,
        height: imageHeight,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
      );
    }

    // Network image (URL)
    if (imageAsset.startsWith('http')) {
      return Image.network(
        imageAsset,
        width: double.infinity,
        height: imageHeight,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
      );
    }

    // Asset image
    return Image.asset(
      imageAsset,
      width: double.infinity,
      height: imageHeight,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: double.infinity,
      height: 80,
      color: Colors.grey[200],
      child: const Icon(Icons.broken_image, color: Colors.grey),
    );
  }
}

class _SpendingCard extends StatelessWidget {
  final String? hotelName;
  const _SpendingCard({this.hotelName});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Current Balance',
                  style: TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 6),
                StreamBuilder<Map<String, dynamic>?>(
                  stream: hotelName != null
                      ? DatabaseService().getMySpending(hotelName!)
                      : Stream.value(null),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Text(
                        '₺0.00',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                        ),
                      );
                    }

                    // Get currentBalance from reservation data
                    final data = snapshot.data;
                    double total = 0.0;
                    if (data != null && data['currentBalance'] != null) {
                      final balance = data['currentBalance'];
                      if (balance is int) {
                        total = balance.toDouble();
                      } else if (balance is double) {
                        total = balance;
                      }
                    }

                    return Text(
                      '₺${total.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          // View Spending Button
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const SpendingTrackerScreen(),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0057FF),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              minimumSize: Size.zero,
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.pie_chart, size: 18),
                SizedBox(width: 6),
                Text(
                  'View Spending',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}



/// Çâ€œzel Alt Navigasyon Çubuğu (Custom Bottom Bar)
///
/// Saydam (yarı opak) ve blur efektli bir görünüme sahiptir.
class _CustomBottomBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;

  const _CustomBottomBar({
    super.key,
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const labelStyle = TextStyle(
      fontSize: 11,
      color: Colors.black87,
      height: 1.1,
    );

    // Helper to determine color based on selection
    Color getColor(int index) {
      return selectedIndex == index ? const Color(0xFF0057FF) : Colors.black54;
    }

    FontWeight getWeight(int index) {
      return selectedIndex == index ? FontWeight.bold : FontWeight.normal;
    }

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
        child: BottomAppBar(
          color: Colors.white.withValues(alpha: 0.9),
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          shape: const CircularNotchedRectangle(),
          notchMargin: 10,
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: 56,
              child: Row(
                children: [
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _BottomBarItem(
                          icon: Icons.home,
                          label: 'Home',
                          labelStyle: labelStyle.copyWith(
                            color: getColor(0),
                            fontWeight: getWeight(0),
                          ),
                          iconColor: getColor(0),
                          onTap: () => onTap(0),
                        ),
                        _BottomBarItem(
                          icon: Icons.map,
                          label: 'Map',
                          labelStyle: labelStyle.copyWith(
                            color: getColor(1),
                            fontWeight: getWeight(1),
                          ),
                          iconColor: getColor(1),
                          onTap: () => onTap(1),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 68),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _BottomBarItem(
                          icon: Icons.apps,
                          label: 'Services',
                          labelStyle: labelStyle.copyWith(
                            color: getColor(2),
                            fontWeight: getWeight(2),
                          ),
                          iconColor: getColor(2),
                          onTap: () => onTap(2),
                        ),
                        _BottomBarItem(
                          icon: Icons.person,
                          label: 'Profile',
                          labelStyle: labelStyle.copyWith(
                            color: getColor(3),
                            fontWeight: getWeight(3),
                          ),
                          iconColor: getColor(3),
                          onTap: () => onTap(3),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BottomBarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final TextStyle labelStyle;
  final VoidCallback onTap;
  final Color? iconColor;

  const _BottomBarItem({
    required this.icon,
    required this.label,
    required this.labelStyle,
    required this.onTap,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: iconColor ?? labelStyle.color,
              size: 24,
            ),
            const SizedBox(height: 2),
            Text(label, style: labelStyle),
          ],
        ),
      ),
    );
  }
}


