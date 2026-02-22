import 'package:flutter/material.dart';
import '../../services/database_service.dart';
import '../../utils/responsive_utils.dart';

class NotificationsChoseScreen extends StatefulWidget {
  const NotificationsChoseScreen({super.key});

  @override
  State<NotificationsChoseScreen> createState() =>
      _NotificationsChoseScreenState();
}

class _NotificationsChoseScreenState extends State<NotificationsChoseScreen> {
  static const List<String> _labels = [
    'Entertainment',
    'Wellness & Life',
    'Sports',
    'Kids',
    'Food & Beverage',
    'Other',
  ];

  final List<bool> _values = List<bool>.filled(6, false);

  @override
  void initState() {
    super.initState();
    _loadUserInterests();
  }

  Future<void> _loadUserInterests() async {
    final interests = await DatabaseService().getUserInterests();
    if (!mounted) return;

    setState(() {
      for (int i = 0; i < _labels.length; i++) {
        if (interests.contains(_labels[i])) {
          _values[i] = true;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool hasAnyOn = _values.any((v) => v);
    final bool allOn = _values.every((v) => v);
    const subtitles = [
      'Movies, shows, and events',
      'Health tips and lifestyle',
      'Live scores and updates',
      'Family friendly content',
      'Recipes and deals',
      'Miscellaneous updates',
    ];
    const icons = <IconData>[
      Icons.movie_creation_outlined,
      Icons.self_improvement,
      Icons.sports_basketball_outlined,
      Icons.child_care_outlined,
      Icons.restaurant_outlined,
      Icons.more_horiz,
    ];
    final List<Color> cardBg = [
      const Color(0xFFF2ECFF),
      const Color(0xFFE6FFF6),
      const Color(0xFFFFF3E4),
      const Color(0xFFEFF5FF),
      const Color(0xFFFFEEEE),
      const Color(0xFFF3F4F6),
    ];
    final List<Color> iconBg = [
      const Color(0xFFE5D6FF),
      const Color(0xFFCFFAEA),
      const Color(0xFFFFE3C6),
      const Color(0xFFDDE9FF),
      const Color(0xFFFFD8D8),
      const Color(0xFFE7E8EB),
    ];
    final List<Color> iconFg = [
      const Color(0xFF7E57C2),
      const Color(0xFF21B79F),
      const Color(0xFFFB8C00),
      const Color(0xFF4F7FFF),
      const Color(0xFFEF5350),
      const Color(0xFF6B7280),
    ];
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
          'Notifications',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
            fontSize: ResponsiveUtils.sp(context, 18),
          ),
        ),
      ),
      body: ListView.separated(
        padding: EdgeInsets.fromLTRB(16, 12, 16, 12),
        itemCount: 7,
        separatorBuilder: (_, e) => SizedBox(height: ResponsiveUtils.spacing(context, 12)),
        itemBuilder: (context, i) {
          if (i == 0) {
            return _CardBlock(
              label: 'All Events',
              subtitle: 'Enable notifications for all categories',
              icon: Icons.notifications_active_outlined,
              cardColor: const Color(0xFFF2F5FA),
              badgeColor: const Color(0xFFD6ECFF),
              iconColor: Colors.blue,
              value: allOn,
              showLock: false,
              usePurpleToggle: false,
              onChanged: (v) => setState(() {
                for (var idx = 0; idx < _values.length; idx++) {
                  _values[idx] = v;
                }
              }),
            );
          }
          final idx = i - 1;
          return _CardBlock(
            label: _labels[idx],
            subtitle: subtitles[idx],
            icon: icons[idx],
            cardColor: cardBg[idx],
            badgeColor: iconBg[idx],
            iconColor: iconFg[idx],
            value: _values[idx],
            onChanged: (v) => setState(() => _values[idx] = v),
          );
        },
      ),
      bottomNavigationBar: AnimatedSlide(
        offset: hasAnyOn ? const Offset(0, 0) : const Offset(0, 1),
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 250),
          opacity: hasAnyOn ? 1 : 0,
          child: SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: SizedBox(
                height: ResponsiveUtils.hp(context, 48 / 844),
                child: ElevatedButton(
                  onPressed: hasAnyOn
                      ? () async {
                          // Seçili kategorileri listele
                          List<String> selectedInterests = [];
                          for (int i = 0; i < _values.length; i++) {
                            if (_values[i]) {
                              selectedInterests.add(_labels[i]);
                            }
                          }

                          // Veritabanına kaydet
                          await DatabaseService().updateUserInterests(selectedInterests);

                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Preferences saved ✅'),
                              ),
                            );
                            Navigator.pop(context);
                          }
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(ResponsiveUtils.spacing(context, 12)),
                    ),
                  ),
                  child: const Text('Save'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CardBlock extends StatelessWidget {
  final String label;
  final String subtitle;
  final IconData icon;
  final Color cardColor;
  final Color badgeColor;
  final Color iconColor;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool showLock;
  final bool usePurpleToggle;

  const _CardBlock({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.cardColor,
    required this.badgeColor,
    required this.iconColor,
    required this.value,
    required this.onChanged,
    this.showLock = true,
    this.usePurpleToggle = true,
  });

  @override
  Widget build(BuildContext context) {
    final Color activeColor = usePurpleToggle
        ? const Color(0xFF7E57C2)
        : Colors.blue;
    return Container(
      height: ResponsiveUtils.hp(context, 96 / 844),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(ResponsiveUtils.spacing(context, 16)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: EdgeInsets.symmetric(horizontal: ResponsiveUtils.spacing(context, 14), vertical: ResponsiveUtils.spacing(context, 12)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: ResponsiveUtils.wp(context, 48 / 375),
            height: ResponsiveUtils.hp(context, 48 / 844),
            decoration: BoxDecoration(
              color: badgeColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor),
          ),
          SizedBox(width: ResponsiveUtils.spacing(context, 12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: ResponsiveUtils.sp(context, 16),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: ResponsiveUtils.spacing(context, 4)),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Color(0xFF7A7F87),
                    fontSize: ResponsiveUtils.sp(context, 12.5),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: ResponsiveUtils.spacing(context, 12)),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (showLock)
                TweenAnimationBuilder<Color?>(
                  duration: const Duration(milliseconds: 220),
                  tween: ColorTween(
                    begin: const Color(0xFFB0B4BB),
                    end: value ? activeColor : const Color(0xFFB0B4BB),
                  ),
                  builder: (context, color, _) =>
                      Icon(Icons.notifications_none, size: ResponsiveUtils.iconSize(context) * (16 / 24), color: color),
                )
              else
                SizedBox(height: ResponsiveUtils.spacing(context, 16)),
              const Spacer(),
              _Toggle(
                value: value,
                onChanged: onChanged,
                purpleTheme: usePurpleToggle,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Toggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool purpleTheme;

  const _Toggle({
    required this.value,
    required this.onChanged,
    this.purpleTheme = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        width: ResponsiveUtils.wp(context, 58 / 375),
        height: ResponsiveUtils.hp(context, 32 / 844),
        decoration: BoxDecoration(
          color: value
              ? (purpleTheme ? const Color(0xFFDAD4FF) : Colors.blue.shade200)
              : const Color(0xFFE9E5EF),
          borderRadius: BorderRadius.circular(ResponsiveUtils.spacing(context, 20)),
          border: Border.all(
            color: value
                ? (purpleTheme ? const Color(0xFF7E57C2) : Colors.blue)
                : const Color(0xFF8E8A98),
            width: ResponsiveUtils.wp(context, 2 / 375),
          ),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 220),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: ResponsiveUtils.spacing(context, 7)),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: ResponsiveUtils.wp(context, 18 / 375),
              height: ResponsiveUtils.hp(context, 18 / 844),
              decoration: BoxDecoration(
                color: value
                    ? (purpleTheme ? const Color(0xFF7E57C2) : Colors.blue)
                    : const Color(0xFF7A7484),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
