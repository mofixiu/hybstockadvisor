import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hybstockadvisor/providers/notification_provider.dart';
import 'package:hybstockadvisor/providers/portfolio_provider.dart';
import 'package:hybstockadvisor/providers/profile_provider.dart';
import 'package:hybstockadvisor/screens/auth/login.dart';
import 'package:hybstockadvisor/screens/notification_settings.dart';
import 'package:hybstockadvisor/screens/personal_info.dart';
import 'package:hybstockadvisor/screens/settings.dart';
import 'package:hybstockadvisor/services/api_service.dart';
import 'package:hybstockadvisor/theme/tokens.dart';
import 'package:hybstockadvisor/widgets/bottomNavBar.dart';
import 'package:hybstockadvisor/widgets/custom_page_route.dart';
import 'package:hybstockadvisor/widgets/ui.dart';
import 'package:provider/provider.dart';

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<ProfileProvider>().load();
    });
  }

  Future<void> _refresh() => context.read<ProfileProvider>().load(force: true);

  /// Opens Personal Info and reloads the profile if it was saved.
  Future<void> _openPersonalInfo() async {
    final saved = await context.pushFade<bool>(const PersonalInfo());
    if (!mounted) return;
    if (saved == true) await context.read<ProfileProvider>().load(force: true);
  }

  Future<void> _signOut() async {
    final confirm = await confirmAction(
      context,
      title: 'Sign out?',
      message: 'You will need to log in again to see your portfolio.',
      confirmLabel: 'Sign out',
      destructive: true,
    );
    if (!confirm || !mounted) return;

    await context.read<NotificationProvider>().clearAll();
    if (!mounted) return;
    context.read<ProfileProvider>().resetForSessionChange();
    context.read<PortfolioProvider>().resetForSessionChange();
    await ApiService.clearUserData();
    if (!mounted) return;
    context.pushFadeAndRemoveUntil(const Login(), (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileProvider>();
    final p = context.pal;
    final t = context.text;
    final loading = profile.isLoading && profile.fullName.isEmpty;

    return Scaffold(
      backgroundColor: p.paper,
      bottomNavigationBar: const BottomNavBar(currentIndex: 3),
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: Gap.xxl),
            children: [
              const PageTitle('Profile'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Gap.page),
                child: loading
                    ? const Skeleton(
                        child: Row(
                          children: [
                            SkeletonBox(width: 64, height: 64, radius: 32),
                            SizedBox(width: Gap.lg),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SkeletonBox(width: 180, height: 22),
                                  SizedBox(height: Gap.sm),
                                  SkeletonBox(width: 140, height: 14),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )
                    : Row(
                        children: [
                          _Avatar(path: profile.avatarPath, name: profile.fullName),
                          const SizedBox(width: Gap.lg),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  profile.fullName.isEmpty ? 'Your account' : profile.fullName,
                                  style: t.headlineSmall,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  profile.countsLine ?? 'Holdings unavailable right now',
                                  style: t.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: Gap.page),
                child: SectionHead('Account'),
              ),
              _MenuRow(
                icon: Icons.person_outline,
                label: 'Personal info',
                onTap: _openPersonalInfo,
              ),
              _MenuRow(
                icon: Icons.settings_outlined,
                label: 'Settings',
                onTap: () => context.pushFade(const SettingsScreen()),
              ),
              _MenuRow(
                icon: Icons.notifications_none,
                label: 'Notifications',
                onTap: () => context.pushFade(const NotificationSettings()),
              ),
              const _MenuRow(
                icon: Icons.shield_outlined,
                label: 'Security',
                note: 'Not available yet',
              ),
              const _MenuRow(
                icon: Icons.help_outline,
                label: 'Help and support',
                note: 'Not available yet',
                showRule: false,
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(Gap.page, Gap.xl, Gap.page, 0),
                child: Hairline(),
              ),
              InkWell(
                onTap: _signOut,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: Gap.page, vertical: 14),
                  child: Row(
                    children: [
                      Icon(Icons.logout, size: 20, color: p.down),
                      const SizedBox(width: Gap.lg),
                      Text(
                        'Sign out',
                        style: t.bodyLarge?.copyWith(color: p.down, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: Gap.page),
                child: Hairline(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Photo if one is saved, otherwise the person's initials.
class _Avatar extends StatelessWidget {
  final String? path;
  final String name;
  const _Avatar({required this.path, required this.name});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final initials = name
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .take(2)
        .map((w) => w[0].toUpperCase())
        .join();
    final fallback = Center(
      child: Text(
        initials.isEmpty ? '?' : initials,
        style: AppType.serif(size: 24, color: p.inkMuted),
      ),
    );
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: p.surface,
        border: Border.all(color: p.rule),
      ),
      child: ClipOval(
        child: path == null
            ? fallback
            : Image.file(
                File(path!),
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => fallback,
              ),
      ),
    );
  }
}

/// A plain row: ink icon, label, chevron (or a note when unavailable).
class _MenuRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final String? note;
  final bool showRule;
  const _MenuRow({
    required this.icon,
    required this.label,
    this.onTap,
    this.note,
    this.showRule = true,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final t = context.text;
    final enabled = onTap != null;
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Gap.page, vertical: 14),
            child: Row(
              children: [
                Icon(icon, size: 20, color: enabled ? p.ink : p.inkFaint),
                const SizedBox(width: Gap.lg),
                Expanded(
                  child: Text(
                    label,
                    style: t.bodyLarge?.copyWith(color: enabled ? p.ink : p.inkFaint),
                  ),
                ),
                if (note != null)
                  Text(note!, style: t.bodySmall)
                else
                  Icon(Icons.chevron_right, size: 20, color: p.inkFaint),
              ],
            ),
          ),
          if (showRule) const Hairline(indent: Gap.page + 36, endIndent: Gap.page),
        ],
      ),
    );
  }
}
