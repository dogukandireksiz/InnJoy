import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:login_page/l10n/app_localizations.dart';
import 'package:login_page/providers/language_provider.dart';

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
    return 'Guest'; // Misafir -> Guest (Varsayılan)
  }

  // 🔥 Dil Seçme Penceresi
  void _showLanguageSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Select Language / Dil Seçiniz",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              // Türkçe Seçeneği
              ListTile(
                leading: const Text("🇹🇷", style: TextStyle(fontSize: 24)),
                title: const Text("Türkçe"),
                trailing:
                    context.read<LanguageProvider>().appLocale.languageCode ==
                        'tr'
                    ? const Icon(Icons.check_circle, color: Colors.green)
                    : null,
                onTap: () {
                  context.read<LanguageProvider>().changeLanguage(
                    const Locale('tr'),
                  );
                  Navigator.pop(context);
                },
              ),
              const Divider(),
              // İngilizce Seçeneği
              ListTile(
                leading: const Text("🇺🇸", style: TextStyle(fontSize: 24)),
                title: const Text("English"),
                trailing:
                    context.read<LanguageProvider>().appLocale.languageCode ==
                        'en'
                    ? const Icon(Icons.check_circle, color: Colors.green)
                    : null,
                onTap: () {
                  context.read<LanguageProvider>().changeLanguage(
                    const Locale('en'),
                  );
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Çeviri dosyasına erişim
    final texts = AppLocalizations.of(context)!;

    // Anlık dili takip et
    final currentLanguageCode = context
        .watch<LanguageProvider>()
        .appLocale
        .languageCode;

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
        title: Text(
          texts.profileSettings,
          style: const TextStyle(
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
                  Text(
                    texts.personalInfoTitle, // "Personal Information"
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _InfoCard(
                    children: [
                      _InfoItem(
                        icon: Icons.person_outline,
                        label: texts.nameSurname, // "Name Surname"
                        value: userName,
                      ),
                      const Divider(height: 1),
                      _InfoItem(
                        icon: Icons.email_outlined,
                        label: texts.email, // "E-mail"
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
                  Text(
                    texts.accommodationInfoTitle, // "Accommodation Info"
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _InfoCard(
                    children: [
                      _InfoItem(
                        icon: Icons.hotel_outlined,
                        label: texts.hotel, // "Hotel"
                        value:
                            'GrandHyatt Hotel', // Burası veritabanından gelecek, şimdilik sabit
                      ),
                      const Divider(height: 1),
                      _InfoItem(
                        icon: Icons.door_front_door_outlined,
                        label: texts.roomNumber, // "Room Number"
                        value: '1204',
                      ),
                      const Divider(height: 1),
                      _InfoItem(
                        icon: Icons.calendar_today_outlined,
                        label: texts.checkInDate, // "Check-in Date"
                        value: '10 Nov 2025',
                      ),
                      const Divider(height: 1),
                      _InfoItem(
                        icon: Icons.event_outlined,
                        label: texts.checkOutDate, // "Check-out Date"
                        value: '15 Nov 2025',
                      ),
                      const Divider(height: 1),
                      _InfoItem(
                        icon: Icons.people_outline,
                        label: texts.guestCount, // "Guest Count"
                        value: '2 Adults',
                      ),
                    ],
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
                  Text(
                    texts.settingsTitle, // "Settings"
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _SettingsCard(
                    children: [
                      _SettingsItem(
                        icon: Icons.notifications_outlined,
                        label: texts.notifications, // "Notifications"
                        onTap: () {},
                      ),
                      const Divider(height: 1),

                      // DİL KISMI
                      _SettingsItem(
                        icon: Icons.language_outlined,
                        label: texts.changeLanguage,
                        // "Türkçe" veya "English" yazısı dinamik kalabilir
                        trailing: currentLanguageCode == 'tr'
                            ? 'Türkçe'
                            : 'English',
                        onTap: () {
                          _showLanguageSelector(context);
                        },
                      ),

                      const Divider(height: 1),
                      _SettingsItem(
                        icon: Icons.lock_outline,
                        label: texts.changePassword, // "Change Password"
                        onTap: () {},
                      ),
                      const Divider(height: 1),
                      _SettingsItem(
                        icon: Icons.privacy_tip_outlined,
                        label: texts.privacyPolicy, // "Privacy Policy"
                        onTap: () {},
                      ),
                      const Divider(height: 1),
                      _SettingsItem(
                        icon: Icons.help_outline,
                        label: texts.helpSupport, // "Help & Support"
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
                    final shouldLogout = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text(texts.logoutConfirmationTitle), // "Log Out"
                        content: Text(
                          texts.logoutConfirmationMessage,
                        ), // "Are you sure..."
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: Text(texts.cancel), // "Cancel"
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.red,
                            ),
                            child: Text(texts.logout), // "Log Out"
                          ),
                        ],
                      ),
                    );
                    if (shouldLogout == true) {
                      await FirebaseAuth.instance.signOut();
                      if (context.mounted) {
                        Navigator.of(
                          context,
                        ).popUntil((route) => route.isFirst);
                      }
                    }
                  },
                  icon: const Icon(Icons.logout, color: Colors.red),
                  label: Text(
                    texts.logout, // "Log Out"
                    style: const TextStyle(
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

// ... Yardımcı Widgetlar (Aynı kalıyor) ...
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
            color: Color.fromRGBO(0, 0, 0, 0.05),
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
            color: Color.fromRGBO(0, 0, 0, 0.05),
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
