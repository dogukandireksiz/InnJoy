import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'custom_top_navigation_bar.dart';

/// Admin ve Guest ekranlarında kullanılan toggle + logout bar widget'ı.
/// Her iki ekranda da aynı pozisyon ve boşluklarla görünür.
class AdminActionBar extends StatelessWidget {
  /// Hangi görünüm aktif (guest veya admin)
  final AdminPanelView activeView;
  
  /// Guest View butonuna tıklandığında
  final VoidCallback onGuestViewTap;
  
  /// Admin Panel butonuna tıklandığında
  final VoidCallback onAdminPanelTap;
  
  /// Logout butonuna tıklandığında
  final VoidCallback onLogoutTap;
  
  /// Toggle teması (dark: koyu arka plan için, light: açık arka plan için)
  final ToggleTheme theme;

  const AdminActionBar({
    super.key,
    required this.activeView,
    required this.onGuestViewTap,
    required this.onAdminPanelTap,
    required this.onLogoutTap,
    this.theme = ToggleTheme.dark,
  });

  @override
  Widget build(BuildContext context) {
    // Tema bazlı logout butonu renkleri
    final logoutBgColor = theme == ToggleTheme.dark
        ? Colors.white.withValues(alpha: 0.1)
        : const Color(0xFFFEE2E2); // Light red for light theme
    
    final logoutIconColor = theme == ToggleTheme.dark
        ? const Color(0xFFFCA5A5) // Light red for dark theme
        : const Color(0xFFEF4444); // Red for light theme

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CustomTopNavigationBar(
          activeView: activeView,
          theme: theme,
          onGuestViewTap: onGuestViewTap,
          onAdminPanelTap: onAdminPanelTap,
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: onLogoutTap,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: logoutBgColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Transform.rotate(
              angle: math.pi,
              child: Icon(
                Icons.logout,
                color: logoutIconColor,
                size: 20,
              ),
            ),
          ),
        ),
      ],
    );
  }
}








