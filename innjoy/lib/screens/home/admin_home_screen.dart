import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth.dart';
import 'home_screen.dart';
import '../../widgets/auth_wrapper.dart';
import '../events_activities/admin_events_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../admin/admin_room_management_screen.dart';
import '../../services/database_service.dart';
import '../services/spa_wellness/spa_management_screen.dart';
import '../admin/restaurant/restaurant_management_screen.dart';
import '../admin/room_service/room_service_management_screen.dart';
import '../admin/admin_requests_screen.dart';
import '../admin/admin_housekeeping_screen.dart';
import '../../widgets/common/custom_top_navigation_bar.dart';
import '../../widgets/admin/admin_action_bar.dart';
import '../edit/chose_edit_screen.dart';
import '../emergency/emergency_admin_screen.dart';
import '../../widgets/admin/management_panel.dart';

import 'dart:math' as math;

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  final user = FirebaseAuth.instance.currentUser;
  String? _hotelName;
  
  // Data caching flags to prevent flicker on navigation back
  bool _isLoading = true;
  bool _dataLoaded = false;

  @override
  void initState() {
    super.initState();
    // Temporarily seed Urban Joy Hotel data as requested
    DatabaseService().seedDefaultServices('Urban Joy Hotel');
    _fetchHotelName();
  }

  Future<void> _fetchHotelName() async {
    // Skip if data already loaded (prevents flicker on navigation back)
    if (_dataLoaded) {
      if (mounted && _isLoading) {
        setState(() => _isLoading = false);
      }
      return;
    }
    
    if (user == null) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _dataLoaded = true;
        });
      }
      return;
    }
    
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .get();
    if (doc.exists && mounted) {
      setState(() {
        _hotelName = doc.data()?['hotelName'];
        _isLoading = false;
        _dataLoaded = true;
      });
    } else if (mounted) {
      setState(() {
        _isLoading = false;
        _dataLoaded = true;
      });
    }
  }

  /// Force refresh all cached data - call this on pull-to-refresh
  Future<void> _forceRefresh() async {
    setState(() {
      _isLoading = true;
      _dataLoaded = false; // Reset cache flag to allow re-fetch
    });
    await _fetchHotelName();
  }

  String get userName {
    if (user?.displayName != null && user!.displayName!.isNotEmpty) {
      return user!.displayName!;
    }
    if (user?.email != null) {
      return user!.email!.split('@').first;
    }
    return 'Admin';
  }

  int _selectedIndex = 0;
  final List<int> _navigationHistory = [0]; // Stack to track navigation history

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return; // Don't add to history if same tab
    
    if (index == 0) {
      setState(() {
        _selectedIndex = 0;
        _navigationHistory.clear();
        _navigationHistory.add(0);
      });
    } else if (index == 1) {
      if (_hotelName != null) {
        setState(() {
          _navigationHistory.add(index);
          _selectedIndex = 1;
        });
      } else {
        _showComingSoonDialog(context, 'Loading hotel info...');
      }
    } else if (index == 2) {
      // All Requests - show as tab (like Rooms)
      if (_hotelName != null) {
        setState(() {
          _navigationHistory.add(index);
          _selectedIndex = 2;
        });
      } else {
        _showComingSoonDialog(context, 'Loading hotel info...');
      }
    } else if (index == 3) {
      _openManagementPanel(context);
    }
  }

  void _goBack() {
    if (_navigationHistory.length > 1) {
      _navigationHistory.removeLast(); // Remove current
      setState(() {
        _selectedIndex = _navigationHistory.last;
      });
    }
  }

  void _openManagementPanel(BuildContext context) {
    showManagementPanel(
      context: context,
      hotelName: _hotelName ?? 'Innjoy',
      userName: userName,
      onNavigate: (route) {
        // Close panel first
        Navigator.pop(context);
        // Handle routes
        switch (route) {
          case 'dashboard':
            setState(() => _selectedIndex = 0);
            break;
          case 'rooms':
            if (_hotelName != null) setState(() => _selectedIndex = 1);
            break;
          case 'housekeeping':
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => AdminHousekeepingScreen(hotelName: _hotelName ?? 'Innjoy')),
            );
            break;
          case 'requests':
            if (_hotelName != null) setState(() => _selectedIndex = 2);
            break;
          case 'edits':
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ChoseEditScreen(hotelName: _hotelName)),
            );
            break;
          case 'emergency':
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const EmergencyAdminScreen()),
            );
            break;
          case 'settings':
            _showComingSoonDialog(context, 'Settings');
            break;
        }
      },
      onSignOut: () async {
        await Auth().signOut();
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const AuthWrapper()),
            (route) => false,
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _navigationHistory.length <= 1, // Only allow pop if at root (Dashboard)
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _navigationHistory.length > 1) {
          _goBack();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF3F4F6),
        body: _buildBody(),
        bottomNavigationBar: _ModernBottomNav(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
        ),
      ),
    );
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return _buildDashboard();
      case 1:
        return AdminRoomManagementScreen(
          hotelName: _hotelName!,
          onBack: () => _onItemTapped(0),
        );
      case 2:
        return AdminRequestsScreen(
          hotelName: _hotelName!,
        );
      default:
        return _buildDashboard();
    }
  }


  Widget _buildDashboard() {
    return RefreshIndicator(
      onRefresh: _forceRefresh,
      color: const Color(0xFF334155),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Curved Header
            _buildCurvedHeader(),
            
            const SizedBox(height: 16),
            
            // Main Content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  
                  // Quick Access Section
                  const Text(
                    'Quick Access',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 16),
                    
                    // Quick Access Grid
                    Row(
                      children: [
                        Expanded(
                          child: _QuickAccessCard(
                            icon: Icons.room_service,
                            label: 'Room Service',
                            subtitle: 'Edit Menu',
                            color: const Color(0xFFFFA726), // Orange 400
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => RoomServiceManagementScreen(
                                    hotelName: _hotelName ?? '',
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _QuickAccessCard(
                            icon: Icons.restaurant,
                            label: 'Dining',
                            subtitle: 'Restaurant & Bar',
                            color: const Color(0xFF66BB6A), // Green 400
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => RestaurantManagementScreen(
                                    hotelName: _hotelName ?? 'Urban Joy Hotel',
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _QuickAccessCard(
                            icon: Icons.spa,
                            label: 'Spa & Wellness',
                            subtitle: 'Appointments',
                            color: const Color(0xFFEC407A), // Pink 400
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => SpaManagementScreen(
                                    hotelName: _hotelName ?? '',
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _QuickAccessCard(
                            icon: Icons.event,
                            label: 'Events',
                            subtitle: 'Event Management',
                            color: const Color(0xFF5C6BC0), // Indigo 400
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      AdminEventsScreen(hotelName: _hotelName ?? ''),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _QuickAccessCard(
                            icon: Icons.edit,
                            label: 'Edit Services',
                            subtitle: 'Manage Content',
                            color: const Color(0xFF26C6DA), // Cyan 400 (using Housekeeping/clean color)
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ChoseEditScreen(hotelName: _hotelName),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _QuickAccessCard(
                            icon: Icons.emergency,
                            label: 'Emergency',
                            subtitle: 'Alerts & Safety',
                            color: const Color(0xFFEF5350), // Red 400
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const EmergencyAdminScreen(),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 100), // Bottom padding for nav bar
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildCurvedHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF334155), Color(0xFF1e293b)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(
            children: [
              // Top Action Buttons
              Row(
                children: [
                  const Spacer(),
                  AdminActionBar(
                    activeView: AdminPanelView.admin,
                    theme: ToggleTheme.dark,
                    onGuestViewTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => HomeScreen(
                            userName: userName,
                            isAdmin: true,
                            hotelName: _hotelName,
                          ),
                        ),
                      );
                    },
                    onAdminPanelTap: () {},
                    onLogoutTap: () async {
                      final shouldLogout = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Log Out'),
                          content: const Text('Are you sure you want to log out?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(true),
                              style: TextButton.styleFrom(foregroundColor: Colors.red),
                              child: const Text('Log Out'),
                            ),
                          ],
                        ),
                      );
                      if (shouldLogout == true && context.mounted) {
                        final navigator = Navigator.of(context);
                        await Auth().signOut();
                        navigator.pushAndRemoveUntil(
                          MaterialPageRoute(builder: (context) => const AuthWrapper()),
                          (route) => false,
                        );
                      }
                    },
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Hotel Info Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _hotelName ?? 'Loading...',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          userName,
                          style: const TextStyle(
                            color: Color(0xFFBFDBFE),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // User Avatar
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Icon(
                        Icons.person,
                        color: Color(0xFF6B7280),
                        size: 28,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Today's Summary Title
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Today's Summary",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Occupancy Stats Row
              if (_hotelName != null && _hotelName!.isNotEmpty)
                _buildOccupancyStats()
              else
                const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOccupancyStats() {
    return StreamBuilder<Map<String, dynamic>?>(
      stream: DatabaseService().getHotelInfo(_hotelName!),
      builder: (context, infoSnapshot) {
        int totalRooms = 0;

        if (infoSnapshot.hasData && infoSnapshot.data != null) {
          final data = infoSnapshot.data!;
          totalRooms = data['totalRooms'] ?? 0;
        }

        return StreamBuilder<List<Map<String, dynamic>>>(
          stream: DatabaseService().getHotelReservations(_hotelName!),
          builder: (context, resSnapshot) {
            int occupiedRooms = 0;
            int checkInsToday = 0;
            int checkOutsToday = 0;

            if (resSnapshot.hasData && resSnapshot.data != null) {
              final reservations = resSnapshot.data!;
              occupiedRooms = reservations
                  .where((r) => r['status'] == 'active' || r['status'] == 'used')
                  .length;
              
              // Calculate today's check-ins and check-outs
              final now = DateTime.now();
              final today = DateTime(now.year, now.month, now.day);
              
              for (var res in reservations) {
                // Check-ins: reservations starting today
                if (res['checkInDate'] != null) {
                  DateTime? checkIn;
                  if (res['checkInDate'] is String) {
                    checkIn = DateTime.tryParse(res['checkInDate']);
                  }
                  if (checkIn != null) {
                    final checkInDay = DateTime(checkIn.year, checkIn.month, checkIn.day);
                    if (checkInDay == today) {
                      checkInsToday++;
                    }
                  }
                }
                
                // Check-outs: reservations ending today
                if (res['checkOutDate'] != null) {
                  DateTime? checkOut;
                  if (res['checkOutDate'] is String) {
                    checkOut = DateTime.tryParse(res['checkOutDate']);
                  }
                  if (checkOut != null) {
                    final checkOutDay = DateTime(checkOut.year, checkOut.month, checkOut.day);
                    if (checkOutDay == today) {
                      checkOutsToday++;
                    }
                  }
                }
              }
            }

            final availableRooms = totalRooms - occupiedRooms;
            final occupancyPercent = totalRooms > 0 
                ? ((occupiedRooms / totalRooms) * 100).round() 
                : 0;

            return StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('hotels')
                  .doc(_hotelName!)
                  .collection('room_service')
                  .doc('orders')
                  .collection('items')
                  .where('status', whereIn: ['Active', 'Pending', 'Preparing'])
                  .snapshots(),
              builder: (context, ordersSnapshot) {
                int activeOrders = 0;
                if (ordersSnapshot.hasData) {
                  activeOrders = ordersSnapshot.data!.docs.length;
                }
                
                return StreamBuilder<List<Map<String, dynamic>>>(
                  stream: DatabaseService().getHotelHousekeepingRequests(_hotelName!),
                  builder: (context, housekeepingSnapshot) {
                    int activeRequests = 0;
                    if (housekeepingSnapshot.hasData) {
                      activeRequests = housekeepingSnapshot.data!
                          .where((r) => r['status'] == 'Active' || r['status'] == 'Pending' || r['status'] == 'In Progress')
                          .length;
                    }
                    
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        children: [
                          // First Row: Occupancy Chart + Room Stats
                          Row(
                            children: [
                              // Circular Progress Chart
                              SizedBox(
                                width: 80,
                                height: 80,
                                child: _CircularOccupancyChart(
                                  percentage: occupancyPercent,
                                ),
                              ),
                              const SizedBox(width: 16),
                              // Stats
                              Expanded(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                  children: [
                                    _HeaderStatItem(
                                      icon: Icons.meeting_room,
                                      iconColor: const Color(0xFF93C5FD),
                                      value: totalRooms.toString(),
                                      label: 'Total',
                                    ),
                                    _HeaderStatItem(
                                      icon: Icons.person,
                                      iconColor: const Color(0xFFFDBA74),
                                      value: occupiedRooms.toString(),
                                      label: 'Occupied',
                                    ),
                                    _HeaderStatItem(
                                      icon: Icons.check_circle,
                                      iconColor: const Color(0xFF86EFAC),
                                      value: availableRooms.toString(),
                                      label: 'Available',
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Divider
                          Container(
                            height: 1,
                            color: Colors.white.withValues(alpha: 0.2),
                          ),
                          const SizedBox(height: 16),
                          // Second Row: Check-ins, Check-outs, Orders, Requests
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _HeaderStatItem(
                                icon: Icons.login,
                                iconColor: const Color(0xFF10B981),
                                value: checkInsToday.toString(),
                                label: 'Check-ins',
                              ),
                              _HeaderStatItem(
                                icon: Icons.logout,
                                iconColor: const Color(0xFFF97316),
                                value: checkOutsToday.toString(),
                                label: 'Check-outs',
                              ),
                              _HeaderStatItem(
                                icon: Icons.room_service,
                                iconColor: Colors.orange,
                                value: activeOrders.toString(),
                                label: 'Orders',
                              ),
                              _HeaderStatItem(
                                icon: Icons.cleaning_services,
                                iconColor: const Color(0xFF22C55E),
                                value: activeRequests.toString(),
                                label: 'Requests',
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  void _showComingSoonDialog(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature - Backend integration pending'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.orange,
      ),
    );
  }
}

// Circular Occupancy Chart Widget
class _CircularOccupancyChart extends StatelessWidget {
  final int percentage;

  const _CircularOccupancyChart({required this.percentage});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _CircularChartPainter(percentage: percentage),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$percentage%',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Text(
              'Occupied',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 8,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CircularChartPainter extends CustomPainter {
  final int percentage;

  _CircularChartPainter({required this.percentage});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;

    // Background circle
    final bgPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6;

    canvas.drawCircle(center, radius, bgPaint);

    // Progress arc
    final progressPaint = Paint()
      ..color = const Color(0xFFFB923C) // Orange
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    final sweepAngle = (percentage / 100) * 2 * math.pi;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Header Stat Item Widget
class _HeaderStatItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;

  const _HeaderStatItem({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: iconColor, size: 22),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFFBFDBFE),
            fontSize: 9,
          ),
        ),
      ],
    );
  }
}

// Quick Access Card Widget
class _QuickAccessCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback? onTap;

  const _QuickAccessCard({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 16),
            Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Modern Bottom Navigation
class _ModernBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const _ModernBottomNav({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.grid_view,
                label: 'Dashboard',
                isActive: currentIndex == 0,
                onTap: () => onTap(0),
              ),
              _NavItem(
                icon: Icons.bed,
                label: 'Rooms',
                isActive: currentIndex == 1,
                onTap: () => onTap(1),
              ),
              _NavItem(
                icon: Icons.assignment_ind,
                label: 'Requests',
                isActive: currentIndex == 2,
                onTap: () => onTap(2),
              ),
              _NavItem(
                icon: Icons.menu,
                label: 'Menu',
                isActive: currentIndex == 3,
                onTap: () => onTap(3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isActive ? const Color(0xFFF97316) : Colors.black87,
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isActive ? const Color(0xFFF97316) : Colors.black87,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}









