import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hybstockadvisor/screens/auth/login.dart';
import 'package:hybstockadvisor/screens/notification_settings.dart';
import 'package:hybstockadvisor/screens/personal_info.dart';
import 'package:hybstockadvisor/screens/settings.dart';
import 'package:hybstockadvisor/services/api_service.dart';
import 'package:hybstockadvisor/widgets/bottomNavBar.dart';
import 'package:hybstockadvisor/widgets/custom_page_route.dart';

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  String _fullName = 'Loading...';
  String? _avatarPath;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final box = await Hive.openBox('user');
    final firstName = box.get('first_name', defaultValue: '');
    final lastName = box.get('last_name', defaultValue: '');
    final name = '$firstName $lastName'.trim();
    if (mounted) {
      setState(() {
        if (name.isNotEmpty) _fullName = name;
        _avatarPath = box.get('avatar_path');
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  // Reload data when returning from PersonalInfo
  void _reloadOnReturn(BuildContext context, Widget page) async {
    await context.pushFade(page);
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1A1A2E) : const Color(0xFFF2F4F7);
    final cardColor = isDark ? const Color(0xFF2A2D3E) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A2E);

    return Scaffold(
      backgroundColor: bgColor,
      bottomNavigationBar: const BottomNavBar(currentIndex: 3),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: bgColor,
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: Text(
          'Profile',
          style: TextStyle(
            color: textColor,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ── App Bar ──
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    const SizedBox(height: 10),

                    // ── Avatar ──
                    Stack(
                      children: [
                        Container(
                          width: 110,
                          height: 110,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.grey[200],
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: _avatarPath != null
                                ? Image.file(
                                    File(_avatarPath!),
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Icon(
                                      Icons.person,
                                      size: 60,
                                      color: Colors.grey[400],
                                    ),
                                  )
                                : Image.asset(
                                    'assets/images/avatar.png',
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Icon(
                                      Icons.person,
                                      size: 60,
                                      color: Colors.grey[400],
                                    ),
                                  ),
                          ),
                        ),
                        // Green checkmark badge
                        Positioned(
                          bottom: 4,
                          right: 4,
                          child: Container(
                            width: 26,
                            height: 26,
                            decoration: BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 14,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // ── Name ──
                    Text(
                      _fullName,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),

                    const SizedBox(height: 8),

                    // ── Premium Badge ──
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF1E2A4A)
                            : const Color(0xFFEAF1FF),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(
                            Icons.verified,
                            color: Color(0xFF0A3D62),
                            size: 16,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Premium Investor',
                            style: TextStyle(
                              color: Color(0xFF0A3D62),
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // // ── Stats Row ──
                    // Row(
                    //   children: [
                    //     // Portfolio
                    //     Container(
                    //       padding: const EdgeInsets.symmetric(
                    //         vertical: 18,
                    //         horizontal: 16,
                    //       ),
                    //       decoration: BoxDecoration(
                    //         color: cardColor,
                    //         borderRadius: BorderRadius.circular(16),
                    //         boxShadow: [
                    //           BoxShadow(
                    //             color: Colors.black.withOpacity(0.05),
                    //             blurRadius: 8,
                    //             offset: const Offset(0, 2),
                    //           ),
                    //         ],
                    //       ),
                    //       child: Column(
                    //         crossAxisAlignment: CrossAxisAlignment.start,
                    //         children: [
                    //           Text(
                    //             'PORTFOLIO',
                    //             style: TextStyle(
                    //               fontSize: 10,
                    //               letterSpacing: 1.1,
                    //               color: Colors.grey[500],
                    //               fontWeight: FontWeight.w600,
                    //             ),
                    //           ),
                    //           const SizedBox(height: 6),
                    //           Text(
                    //             '+14.5%',
                    //             style: TextStyle(
                    //               fontSize: 24,
                    //               fontWeight: FontWeight.bold,
                    //               color: textColor,
                    //             ),
                    //           ),
                    //         ],
                    //       ),
                    //     ),
                    //   ],
                    // ),
                    const SizedBox(height: 28),

                    // ── Account Settings ──
                    _SectionLabel(label: 'ACCOUNT SETTINGS', isDark: isDark),
                    const SizedBox(height: 12),

                    _SettingsCard(
                      isDark: isDark,
                      cardColor: cardColor,
                      textColor: textColor,
                      items: [
                        _SettingsItem(
                          icon: Icons.person_outline,
                          iconBg: const Color(0xFFDCEAFF),
                          iconColor: const Color(0xFF2979FF),
                          label: 'Personal Info',
                          onTap: () =>
                              _reloadOnReturn(context, const PersonalInfo()),
                        ),
                        _SettingsItem(
                          icon: Icons.settings_outlined,
                          iconBg: const Color(0xFFFFE0E0),
                          iconColor: const Color(0xFFF44336),
                          label: 'Settings',
                          onTap: () => context.pushFade(const SettingsScreen()),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // ── Preferences ──
                    _SectionLabel(label: 'PREFERENCES', isDark: isDark),
                    const SizedBox(height: 12),

                    _SettingsCard(
                      isDark: isDark,
                      cardColor: cardColor,
                      textColor: textColor,
                      items: [
                        _SettingsItem(
                          icon: Icons.notifications_outlined,
                          iconBg: const Color(0xFFFFF3E0),
                          iconColor: const Color(0xFFF59E0B),
                          label: 'Notifications',
                          onTap: () =>
                              context.pushFade(const NotificationSettings()),
                        ),
                        _SettingsItem(
                          icon: Icons.shield_outlined,
                          iconBg: const Color(0xFFD6F5E3),
                          iconColor: const Color(0xFF2DBD6E),
                          label: 'Security',
                          onTap: () =>
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Coming soon'),
                                  duration: Duration(seconds: 2),
                                ),
                              ),
                        ),
                        _SettingsItem(
                          icon: Icons.help_outline,
                          iconBg: const Color(0xFFE8E8E8),
                          iconColor: const Color(0xFF555555),
                          label: 'Help & Support',
                          onTap: () =>
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Coming soon'),
                                  duration: Duration(seconds: 2),
                                ),
                              ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 28),

                    // ── Sign Out ──
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.red.withOpacity(0.3)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextButton.icon(
                        onPressed: () async {
                          // Show confirmation dialog first
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              backgroundColor: cardColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              title: Text(
                                'Sign Out',
                                style: TextStyle(color: textColor),
                              ),
                              content: Text(
                                'Are you sure you want to sign out?',
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 13,
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: Text(
                                    'Cancel',
                                    style: TextStyle(color: Colors.grey[500]),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  child: const Text(
                                    'Sign Out',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                            ),
                          );

                          if (confirm == true && context.mounted) {
                            // Clear all saved user data & token
                            await ApiService.clearUserData();

                            if (!context.mounted) return;
                            // Navigate to Login and CLEAR the entire stack
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(builder: (_) => const Login()),
                              (route) => false,
                            );
                          }
                        },
                        icon: const Icon(
                          Icons.logout,
                          color: Colors.red,
                          size: 20,
                        ),
                        label: const Text(
                          'Sign Out',
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    Text(
                      'Version 1.0.0',
                      style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Section Label
// ─────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String label;
  final bool isDark;

  const _SectionLabel({required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          letterSpacing: 1.3,
          fontWeight: FontWeight.w600,
          color: Colors.grey[500],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Settings Card (grouped items)
// ─────────────────────────────────────────────
class _SettingsCard extends StatelessWidget {
  final bool isDark;
  final Color cardColor;
  final Color textColor;
  final List<_SettingsItem> items;

  const _SettingsCard({
    required this.isDark,
    required this.cardColor,
    required this.textColor,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: items.asMap().entries.map((entry) {
          final i = entry.key;
          final item = entry.value;
          final isLast = i == items.length - 1;

          return Column(
            children: [
              GestureDetector(
                onTap: item.onTap,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  child: Row(
                    children: [
                      // Icon container
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: item.iconBg,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(item.icon, color: item.iconColor, size: 20),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          item.label,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: textColor,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        color: Colors.grey[400],
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
              if (!isLast)
                Divider(
                  height: 1,
                  indent: 70,
                  color: isDark
                      ? Colors.white.withOpacity(0.06)
                      : Colors.grey.withOpacity(0.15),
                ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Settings Item data model
// ─────────────────────────────────────────────
class _SettingsItem {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String label;
  final VoidCallback? onTap;

  const _SettingsItem({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.label,
    this.onTap,
  });
}
