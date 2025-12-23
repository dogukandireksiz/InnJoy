import 'package:flutter/material.dart';

/// Management Panel that slides in from the left side
/// Used in admin home screen for quick navigation
class ManagementPanel extends StatelessWidget {
  final String hotelName;
  final String userName;
  final void Function(String route) onNavigate;
  final VoidCallback onSignOut;

  const ManagementPanel({
    super.key,
    required this.hotelName,
    required this.userName,
    required this.onNavigate,
    required this.onSignOut,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(Icons.apartment, color: Colors.blue),
                  SizedBox(width: 8),
                  Text('Innjoy', style: TextStyle(fontWeight: FontWeight.w700)),
                ],
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF6F7FB),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.blue,
                  child: Icon(Icons.person, color: Colors.white),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const Text(
                        'Front Desk Manager',
                        style: TextStyle(color: Colors.black54, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _PanelItem(
            icon: Icons.dashboard_rounded,
            label: 'Dashboard',
            selected: true,
            onTap: () => onNavigate('dashboard'),
          ),
          _PanelItem(
            icon: Icons.bed,
            label: 'Rooms',
            onTap: () => onNavigate('rooms'),
          ),
          _PanelItem(
            icon: Icons.inbox,
            label: 'Requests',
            onTap: () => onNavigate('requests'),
          ),
          _PanelItem(
            icon: Icons.edit,
            label: 'Edits',
            onTap: () => onNavigate('edits'),
          ),
          _PanelItem(
            icon: Icons.emergency_share,
            label: 'Emergencies',
            onTap: () => onNavigate('emergency'),
          ),
          const Spacer(),
          const Divider(),
          _PanelItem(
            icon: Icons.settings,
            label: 'Settings',
            onTap: () => onNavigate('settings'),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: onSignOut,
            icon: const Icon(Icons.logout),
            label: const Text('Sign Out'),
          ),
          const SizedBox(height: 4),
          const Text(
            'v2.4.0 • Innjoy Management',
            style: TextStyle(color: Colors.black38, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _PanelItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _PanelItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: selected
                    ? Colors.blue.withValues(alpha: 0.12)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: selected ? Colors.blue : Colors.black87),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                  color: Colors.black87,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Helper function to show the management panel as a modal sheet from the right
void showManagementPanel({
  required BuildContext context,
  required String hotelName,
  required String userName,
  required void Function(String route) onNavigate,
  required VoidCallback onSignOut,
}) {
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Management Panel',
    barrierColor: Colors.black.withValues(alpha: 0.25),
    transitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (context, animation, secondaryAnimation) {
      return const SizedBox.shrink();
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final width = MediaQuery.of(context).size.width;
      final panelWidth = width * 0.82;

      final slideAnimation = Tween<Offset>(
        begin: const Offset(1, 0), // Start from right
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));

      return Stack(
        children: [
          // Dismiss on tap outside
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(color: Colors.transparent),
          ),
          // Panel from right
          Align(
            alignment: Alignment.centerRight,
            child: SlideTransition(
              position: slideAnimation,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: panelWidth,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      bottomLeft: Radius.circular(20),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 18,
                        offset: const Offset(-6, 0),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    bottom: false, // No bottom gap
                    left: false,
                    right: false,
                    child: ManagementPanel(
                      hotelName: hotelName,
                      userName: userName,
                      onNavigate: onNavigate,
                      onSignOut: onSignOut,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    },
  );
}
