import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:login_page/service/auth.dart';
import '../../widgets/auth_wrapper.dart';
import 'change_password_screen.dart';
import '../../utils/custom_dialog.dart';
import '../legal/legal_constants.dart';
import '../legal/legal_document_screen.dart';
import './notifications_chose_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final user = FirebaseAuth.instance.currentUser;

  String get userName {
    if (user?.displayName != null && user!.displayName!.isNotEmpty) {
      return user!.displayName!;
    }
    // E-posta'dan isim türet
    if (user?.email != null) {
      return user!.email!.split('@').first;
    }
    return 'Guest';
  }

  Stream<Map<String, dynamic>?> _getUserAccommodationStream() {
    if (user == null) return Stream.value(null);
    return FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .snapshots()
        .map((snapshot) => snapshot.data());
  }

  String _monthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Profile',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: Color(0xFF1677FF)),
            onPressed: () {
              // Profil düzenleme
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profil Başlık Alanı
            Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Profil Fotoğrafı
                  Stack(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFFE3F2FD),
                          border: Border.all(
                            color: const Color(0xFF1677FF),
                            width: 3,
                          ),
                        ),
                        child: const Icon(
                          Icons.person,
                          size: 50,
                          color: Color(0xFF1677FF),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1677FF),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // İsim
                  Text(
                    userName,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // E-posta
                  Text(
                    user?.email ?? 'email@example.com',
                    style: TextStyle(fontSize: 15, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Kişisel Bilgiler
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Personal Information',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  _InfoCard(
                    children: [
                      _InfoItem(
                        icon: Icons.person_outline,
                        label: 'Full Name',
                        value: userName,
                      ),
                      const Divider(height: 1),
                      _InfoItem(
                        icon: Icons.email_outlined,
                        label: 'Email',
                        value: user?.email ?? 'email@example.com',
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Konaklama Bilgileri
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Accommodation Details',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  StreamBuilder<Map<String, dynamic>?>(
                    stream: _getUserAccommodationStream(),
                    builder: (context, snapshot) {
                      final data = snapshot.data;
                      final hotelName = data?['hotelName'] ?? 'Not available';
                      final roomNumber = data?['roomNumber'] ?? '-';
                      final checkIn = data?['checkInDate'];
                      final checkOut = data?['checkOutDate'];

                      String checkInStr = '-';
                      String checkOutStr = '-';

                      if (checkIn != null) {
                        final dt = checkIn is Timestamp
                            ? checkIn.toDate()
                            : DateTime.now();
                        checkInStr =
                            '${dt.day} ${_monthName(dt.month)} ${dt.year}';
                      }
                      if (checkOut != null) {
                        final dt = checkOut is Timestamp
                            ? checkOut.toDate()
                            : DateTime.now();
                        checkOutStr =
                            '${dt.day} ${_monthName(dt.month)} ${dt.year}';
                      }

                      return _InfoCard(
                        children: [
                          _InfoItem(
                            icon: Icons.hotel_outlined,
                            label: 'Hotel',
                            value: hotelName,
                          ),
                          const Divider(height: 1),
                          _InfoItem(
                            icon: Icons.door_front_door_outlined,
                            label: 'Room Number',
                            value: roomNumber,
                          ),
                          const Divider(height: 1),
                          _InfoItem(
                            icon: Icons.calendar_today_outlined,
                            label: 'Check-in Date',
                            value: checkInStr,
                          ),
                          const Divider(height: 1),
                          _InfoItem(
                            icon: Icons.event_outlined,
                            label: 'Check-out Date',
                            value: checkOutStr,
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Ayarlar ve Tercihler
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Settings',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  _SettingsCard(
                    children: [
                      _SettingsItem(
                        icon: Icons.notifications_outlined,
                        label: 'Notifications',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const NotificationsChoseScreen(),
                            ),
                          );
                        },
                      ),
                      const Divider(height: 1),
                      _SettingsItem(
                        icon: Icons.language_outlined,
                        label: 'Language',
                        trailing: 'English',
                        onTap: () {},
                      ),
                      const Divider(height: 1),
                      _SettingsItem(
                        icon: Icons.lock_outline,
                        label: 'Change Password',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const ChangePasswordScreen(),
                            ),
                          );
                        },
                      ),
                      const Divider(height: 1),
                      _SettingsItem(
                        icon: Icons.description_outlined, // User Agreement
                        label: 'User Agreement',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const LegalDocumentScreen(
                                titleTr: LegalConstants.userAgreementTitle,
                                contentTr: LegalConstants.userAgreementText,
                                titleEn: LegalConstants.userAgreementTitleEn,
                                contentEn: LegalConstants.userAgreementTextEn,
                              ),
                            ),
                          );
                        },
                      ),
                      const Divider(height: 1),
                      _SettingsItem(
                        icon: Icons.privacy_tip_outlined,
                        label: 'Privacy Policy',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const LegalDocumentScreen(
                                titleTr: LegalConstants.privacyPolicyTitle,
                                contentTr: LegalConstants.privacyPolicyText,
                                titleEn: LegalConstants.privacyPolicyTitleEn,
                                contentEn: LegalConstants.privacyPolicyTextEn,
                              ),
                            ),
                          );
                        },
                      ),
                      const Divider(height: 1),
                      _SettingsItem(
                        icon: Icons.article_outlined, // KVKK
                        label: 'KVKK Text',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const LegalDocumentScreen(
                                titleTr: LegalConstants.kvkkTitle,
                                contentTr: LegalConstants.kvkkText,
                                titleEn: LegalConstants.kvkkTitleEn,
                                contentEn: LegalConstants.kvkkTextEn,
                              ),
                            ),
                          );
                        },
                      ),
                      const Divider(height: 1),
                      _SettingsItem(
                        icon: Icons.help_outline,
                        label: 'Help & Support',
                        onTap: () {},
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Çıkış Yap Butonu
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final shouldLogout = await CustomDialog.show(
                      context,
                      title: 'Log Out',
                      message: 'Are you sure you want to log out?',
                      confirmText: 'Log Out',
                      isDanger: true,
                    );
                    if (shouldLogout == true) {
                      // Login sayfasının bulunduğu AuthWrapper'a yönlendir
                      // Mevcut tüm sayfaları stack'ten temizle
                      await Auth().signOut();
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
                  icon: const Icon(Icons.logout, color: Colors.red),
                  label: const Text(
                    'Log Out',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final List<Widget> children;

  const _InfoCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFE3F2FD),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xFF1677FF), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 15,
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

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;

  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }
}

class _SettingsItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? trailing;
  final VoidCallback onTap;

  const _SettingsItem({
    required this.icon,
    required this.label,
    this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: Colors.black54, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 15,
                ),
              ),
            ),
            if (trailing != null) ...[
              Text(
                trailing!,
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
              const SizedBox(width: 8),
            ],
            Icon(Icons.chevron_right, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }
}









