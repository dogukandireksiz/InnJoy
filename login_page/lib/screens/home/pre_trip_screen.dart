import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../service/auth.dart';
import '../../widgets/auth_wrapper.dart';
import '../profile/profile_screen.dart';
import '../../service/database_service.dart';
import 'home_screen.dart';
import 'admin_home_screen.dart';

class PreTripScreen extends StatefulWidget {
  final String userName;
  const PreTripScreen({super.key, required this.userName});

  @override
  State<PreTripScreen> createState() => _PreTripScreenState();
}

class _PreTripScreenState extends State<PreTripScreen> {
  bool _isAdmin = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkUserRole();
  }

  Future<void> _checkUserRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final role = await DatabaseService().getUserRole(user.uid);
      setState(() {
        _isAdmin = role == 'admin';
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFF6F7FB),
        scrolledUnderElevation: 0,
        titleSpacing: 0,
        actions: [
          IconButton(
            onPressed: () async {
              final shouldLogout = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Çıkış Yap'),
                  content: const Text('Çıkmak istediğinize emin misiniz?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('İptal'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                      child: const Text('Çıkış Yap'),
                    ),
                  ],
                ),
              );
              if (shouldLogout == true) {
                await Auth().signOut();
                if (context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const AuthWrapper()),
                    (route) => false,
                  );
                }
              }
            },
            icon: const Icon(Icons.exit_to_app, color: Colors.red),
          ),
        ],
        title: Padding(
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
                    widget.userName.isEmpty ? 'Guest' : widget.userName,
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 40),
            
            // Placeholder - İleride otel seçimi eklenecek
            Center(
              child: Column(
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(60),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 20,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      _isAdmin ? Icons.admin_panel_settings : Icons.hotel,
                      size: 60,
                      color: _isAdmin ? Colors.orange : const Color(0xFF1677FF),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    _isAdmin ? 'Hoş Geldiniz, Yönetici!' : 'Tatiliniz Yaklaşıyor!',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isAdmin 
                        ? 'Otelinizi yönetmek veya\nmisafir görünümüne geçmek için seçim yapın.'
                        : 'Otel seçimi ve rezervasyon doğrulaması\nyakında bu ekranda yapılacak.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 40),
                  
                  // Admin için: Otelinizi Düzenleyin butonu
                  if (_isAdmin) ...[
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const AdminHomeScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.settings),
                      label: const Text(
                        'Otelinizi Düzenleyin',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  
                  // Tatile Başla butonu (herkes için)
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (_) => HomeScreen(userName: widget.userName),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1677FF),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      _isAdmin ? 'Misafir Görünümü' : 'Tatile Başla',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 60),
          ],
        ),
      ),
      bottomNavigationBar: _PreTripBottomBar(
        onTap: (item) {
          switch (item) {
            case _BottomItem.home:
              // Zaten buradayız
              break;
            case _BottomItem.theme:
              // Theme değişikliği - ileride eklenecek
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Tema ayarları yakında!'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
              break;
            case _BottomItem.profile:
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
              break;
          }
        },
      ),
    );
  }
}

enum _BottomItem { home, theme, profile }

class _PreTripBottomBar extends StatelessWidget {
  final ValueChanged<_BottomItem>? onTap;
  const _PreTripBottomBar({this.onTap});

  @override
  Widget build(BuildContext context) {
    const labelStyle = TextStyle(fontSize: 11, color: Colors.black87, height: 1.1);
    return BottomAppBar(
      elevation: 8,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 56,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _BottomBarItem(
                icon: Icons.home,
                label: 'Home',
                labelStyle: labelStyle,
                onTap: () => onTap?.call(_BottomItem.home),
              ),
              _BottomBarItem(
                icon: Icons.brightness_6,
                label: 'Theme',
                labelStyle: labelStyle,
                onTap: () => onTap?.call(_BottomItem.theme),
              ),
              _BottomBarItem(
                icon: Icons.person,
                label: 'Profile',
                labelStyle: labelStyle,
                onTap: () => onTap?.call(_BottomItem.profile),
              ),
            ],
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
  const _BottomBarItem({
    required this.icon,
    required this.label,
    required this.labelStyle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.black87, size: 22),
            const SizedBox(height: 2),
            Text(label, style: labelStyle),
          ],
        ),
      ),
    );
  }
}
