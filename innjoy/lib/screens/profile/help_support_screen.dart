import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../legal/legal_constants.dart';
import '../legal/legal_document_screen.dart';
import '../../map/map_screen.dart';
import 'package:latlong2/latlong.dart';
import '../../utils/responsive_utils.dart';

/// Help & Support Screen
/// 
/// Kullanıcılara yardım ve destek sağlayan ekran.
/// Quick Actions ve Important Links bölümleri içerir.
class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  String _appVersion = '';

  @override
  void initState() {
    super.initState();
    _loadAppVersion();
  }

  Future<void> _loadAppVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      setState(() {
        _appVersion = packageInfo.version;
      });
    } catch (e) {
      setState(() {
        _appVersion = '1.0.0';
      });
    }
  }

  void _showComingSoonDialog(String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ResponsiveUtils.spacing(context, 16)),
        ),
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 8)),
              decoration: BoxDecoration(
                color: const Color(0xFF1677FF).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.info_outline,
                color: Color(0xFF1677FF),
                size: ResponsiveUtils.iconSize(context) * (24 / 24),
              ),
            ),
            SizedBox(width: ResponsiveUtils.spacing(context, 12)),
            Expanded(
              child: Text(
                'Coming Soon',
                style: TextStyle(
                  fontSize: ResponsiveUtils.sp(context, 18),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          '$feature will be available in a future update.',
          style: TextStyle(fontSize: ResponsiveUtils.sp(context, 15)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'OK',
              style: TextStyle(
                color: Color(0xFF1677FF),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFAQItem(String question, String answer) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.symmetric(horizontal: ResponsiveUtils.spacing(context, 16), vertical: ResponsiveUtils.spacing(context, 4)),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        leading: Container(
          width: ResponsiveUtils.wp(context, 32 / 375),
          height: ResponsiveUtils.hp(context, 32 / 844),
          decoration: BoxDecoration(
            color: const Color(0xFFE3F2FD),
            borderRadius: BorderRadius.circular(ResponsiveUtils.spacing(context, 8)),
          ),
          child: Icon(
            Icons.help_outline,
            color: Color(0xFF1677FF),
            size: ResponsiveUtils.iconSize(context) * (18 / 24),
          ),
        ),
        title: Text(
          question,
          style: TextStyle(
            fontSize: ResponsiveUtils.sp(context, 15),
            fontWeight: FontWeight.w600,
            color: Color(0xFF1C1C1E),
          ),
        ),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              answer,
              style: TextStyle(
                fontSize: ResponsiveUtils.sp(context, 14),
                color: Colors.grey[700],
                height: ResponsiveUtils.hp(context, 1.5 / 844),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF6F7FB),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Help & Support',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
            fontSize: ResponsiveUtils.sp(context, 18),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // FAQ Section
            Text(
              'Frequently Asked Questions',
              style: TextStyle(fontSize: ResponsiveUtils.sp(context, 18), fontWeight: FontWeight.w700),
            ),
            SizedBox(height: ResponsiveUtils.spacing(context, 12)),
            _FAQCard(
              children: [
                _buildFAQItem(
                  'How do I check in to the hotel?',
                  'You can check in at the reception desk. Your reservation details will be loaded automatically in the app once you log in.',
                ),
                const Divider(height: 1),
                _buildFAQItem(
                  'How do I order room service?',
                  'Go to Home → Room Service → Select items from menu → Place Order. You can track your order in My Requests.',
                ),
                const Divider(height: 1),
                _buildFAQItem(
                  'How do I connect to hotel WiFi?',
                  'Profile → WiFi Connection → Scan QR code or copy password manually.',
                ),
                const Divider(height: 1),
                _buildFAQItem(
                  'How do I book a spa appointment?',
                  'Services → Serenity Spa → Select treatment → Choose date and time → Book Treatment.',
                ),
                const Divider(height: 1),
                _buildFAQItem(
                  'How do I make a restaurant reservation?',
                  'Services → Aurora Restaurant → Book Table → Select date, time, and party size.',
                ),
                const Divider(height: 1),
                _buildFAQItem(
                  'Where can I see my expenses?',
                  'On the Home screen, tap on Spending Summary card to view all your expenses categorized.',
                ),
                const Divider(height: 1),
                _buildFAQItem(
                  'What should I do in an emergency?',
                  'Press the red Emergency button on the Home screen for immediate assistance.',
                ),
                const Divider(height: 1),
                _buildFAQItem(
                  'How do I cancel my order/request?',
                  'Go to My Requests → Select the active order → Tap Cancel Order button.',
                ),
                Divider(height: 1),
                _buildFAQItem(
                  'Can I change my profile picture?',
                  'Yes! Profile → Tap on your photo → Choose from gallery, URL, or default avatars.',
                ),
                Divider(height: 1),
                _buildFAQItem(
                  'How do I reset my password?',
                  'Profile → Change Password → Enter current and new password.',
                ),
              ],
            ),

            SizedBox(height: ResponsiveUtils.spacing(context, 24)),

            // Quick Actions Section
            Text(
              'Quick Actions',
              style: TextStyle(fontSize: ResponsiveUtils.sp(context, 18), fontWeight: FontWeight.w700),
            ),
            SizedBox(height: ResponsiveUtils.spacing(context, 12)),
            _QuickActionsCard(
              children: [
                _QuickActionItem(
                  icon: Icons.phone,
                  label: 'Call Reception',
                  onTap: () => _showComingSoonDialog('Call Reception'),
                ),
                const Divider(height: 1),
                _QuickActionItem(
                  icon: Icons.chat_bubble_outline,
                  label: 'Live Chat Support',
                  onTap: () => _showComingSoonDialog('Live Chat Support'),
                ),
                const Divider(height: 1),
                _QuickActionItem(
                  icon: Icons.email_outlined,
                  label: 'Email Support',
                  onTap: () => _showComingSoonDialog('Email Support'),
                ),
                const Divider(height: 1),
                _QuickActionItem(
                  icon: Icons.map_outlined,
                  label: 'Hotel Map',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const MapScreen(
                          selectedLocation: LatLng(37.216097, 28.351872),
                        ),
                      ),
                    );
                  },
                ),
                Divider(height: 1),
                _QuickActionItem(
                  icon: Icons.menu_book_outlined,
                  label: 'User Guide',
                  onTap: () => _showComingSoonDialog('User Guide'),
                ),
              ],
            ),

            SizedBox(height: ResponsiveUtils.spacing(context, 24)),

            // Important Links Section
            Text(
              'Important Links',
              style: TextStyle(fontSize: ResponsiveUtils.sp(context, 18), fontWeight: FontWeight.w700),
            ),
            SizedBox(height: ResponsiveUtils.spacing(context, 12)),
            _ImportantLinksCard(
              children: [
                _ImportantLinkItem(
                  icon: Icons.description_outlined,
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
                _ImportantLinkItem(
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
                _ImportantLinkItem(
                  icon: Icons.article_outlined,
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
                Divider(height: 1),
                _ImportantLinkItem(
                  icon: Icons.info_outline,
                  label: 'App Version & Updates',
                  trailing: Text(
                    'v$_appVersion',
                    style: TextStyle(
                      color: Color(0xFF6B7280),
                      fontSize: ResponsiveUtils.sp(context, 14),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(ResponsiveUtils.spacing(context, 16)),
                        ),
                        title: const Text('App Information'),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Version: $_appVersion'),
                            SizedBox(height: ResponsiveUtils.spacing(context, 8)),
                            Text('InnJoy - Hotel Guest Experience'),
                            SizedBox(height: ResponsiveUtils.spacing(context, 8)),
                            Text(
                              'You are using the latest version.',
                              style: TextStyle(
                                color: Colors.green[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(
                              'OK',
                              style: TextStyle(color: Color(0xFF1677FF)),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),

            SizedBox(height: ResponsiveUtils.spacing(context, 32)),
          ],
        ),
      ),
    );
  }
}

class _FAQCard extends StatelessWidget {
  final List<Widget> children;

  const _FAQCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(ResponsiveUtils.spacing(context, 12)),
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

class _QuickActionsCard extends StatelessWidget {
  final List<Widget> children;

  const _QuickActionsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(ResponsiveUtils.spacing(context, 12)),
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

class _ImportantLinksCard extends StatelessWidget {
  final List<Widget> children;

  const _ImportantLinksCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(ResponsiveUtils.spacing(context, 12)),
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

class _QuickActionItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: ResponsiveUtils.spacing(context, 16), vertical: ResponsiveUtils.spacing(context, 14)),
        child: Row(
          children: [
            Container(
              width: ResponsiveUtils.wp(context, 40 / 375),
              height: ResponsiveUtils.hp(context, 40 / 844),
              decoration: BoxDecoration(
                color: const Color(0xFFE3F2FD),
                borderRadius: BorderRadius.circular(ResponsiveUtils.spacing(context, 10)),
              ),
              child: Icon(icon, color: const Color(0xFF1677FF), size: ResponsiveUtils.iconSize(context) * (20 / 24)),
            ),
            SizedBox(width: ResponsiveUtils.spacing(context, 12)),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: ResponsiveUtils.sp(context, 15),
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF1C1C1E),
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }
}

class _ImportantLinkItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget? trailing;
  final VoidCallback onTap;

  const _ImportantLinkItem({
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
        padding: EdgeInsets.symmetric(horizontal: ResponsiveUtils.spacing(context, 16), vertical: ResponsiveUtils.spacing(context, 14)),
        child: Row(
          children: [
            Container(
              width: ResponsiveUtils.wp(context, 40 / 375),
              height: ResponsiveUtils.hp(context, 40 / 844),
              decoration: BoxDecoration(
                color: const Color(0xFFE3F2FD),
                borderRadius: BorderRadius.circular(ResponsiveUtils.spacing(context, 10)),
              ),
              child: Icon(icon, color: const Color(0xFF1677FF), size: ResponsiveUtils.iconSize(context) * (20 / 24)),
            ),
            SizedBox(width: ResponsiveUtils.spacing(context, 12)),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: ResponsiveUtils.sp(context, 14),
                ),
              ),
            ),
            if (trailing != null) trailing!,
            SizedBox(width: ResponsiveUtils.spacing(context, 8)),
            const Icon(
              Icons.chevron_right,
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }
}

