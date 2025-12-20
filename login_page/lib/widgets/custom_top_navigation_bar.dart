import 'package:flutter/material.dart';

/// Enum to indicate which view is currently active
enum AdminPanelView { guest, admin }

/// Enum for toggle theme based on screen background
enum ToggleTheme { dark, light }

/// A reusable toggle switch for switching between Guest View and Admin Panel.
/// 
/// This widget provides:
/// - Icon-only design for compact display
/// - Theme-aware colors (dark theme for dark headers, light theme for white screens)
/// - Pill-shaped toggle with smooth switching
class CustomTopNavigationBar extends StatelessWidget {
  /// Which view is currently active
  final AdminPanelView activeView;
  
  /// Callback when Guest View button is tapped
  final VoidCallback onGuestViewTap;
  
  /// Callback when Admin Panel button is tapped
  final VoidCallback onAdminPanelTap;
  
  /// Theme for the toggle (dark for dark backgrounds, light for white/light backgrounds)
  final ToggleTheme theme;

  /// Fixed dimensions for consistent layout - now compact (icon only)
  static const double kToggleHeight = 40.0;
  static const double kToggleWidth = 90.0;

  const CustomTopNavigationBar({
    super.key,
    required this.activeView,
    required this.onGuestViewTap,
    required this.onAdminPanelTap,
    this.theme = ToggleTheme.dark, // Default to dark theme (for admin header)
  });

  @override
  Widget build(BuildContext context) {
    // Colors based on theme
    final backgroundColor = theme == ToggleTheme.dark
        ? const Color(0xFF475569) // Slate gray for dark headers
        : const Color(0xFFE5E7EB); // Light gray for white screens
    
    final inactiveIconColor = theme == ToggleTheme.dark
        ? Colors.white70
        : const Color(0xFF6B7280); // Gray for light theme
    
    return Container(
      width: kToggleWidth,
      height: kToggleHeight,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        children: [
          // Guest View Button
          Expanded(
            child: _ToggleButton(
              isActive: activeView == AdminPanelView.guest,
              icon: Icons.visibility,
              onTap: onGuestViewTap,
              activeColor: const Color(0xFF10B981), // Emerald green
              inactiveIconColor: inactiveIconColor,
            ),
          ),
          // Admin Panel Button
          Expanded(
            child: _ToggleButton(
              isActive: activeView == AdminPanelView.admin,
              icon: Icons.security,
              onTap: onAdminPanelTap,
              activeColor: const Color(0xFFF97316), // Orange
              inactiveIconColor: inactiveIconColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _ToggleButton extends StatelessWidget {
  final bool isActive;
  final IconData icon;
  final VoidCallback onTap;
  final Color activeColor;
  final Color inactiveIconColor;

  const _ToggleButton({
    required this.isActive,
    required this.icon,
    required this.onTap,
    required this.activeColor,
    required this.inactiveIconColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isActive ? activeColor : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Center(
          child: Icon(
            icon,
            color: isActive ? Colors.white : inactiveIconColor,
            size: 18,
          ),
        ),
      ),
    );
  }
}
