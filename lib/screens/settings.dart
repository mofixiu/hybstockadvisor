import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hybstockadvisor/providers/theme_provider.dart';
import 'package:provider/provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1A1A2E) : const Color(0xFFF2F4F7);
    final cardColor = isDark ? const Color(0xFF2A2D3E) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A2E);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: bgColor,
        centerTitle: true,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.only(left: 16),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4),
              ],
            ),
            child: Icon(Icons.arrow_back_ios_new, size: 16, color: textColor),
          ),
        ),
        title: Text(
          'Settings',
          style: TextStyle(
            color: textColor,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),

              // ── APPEARANCE ──
              _SectionLabel(label: 'APPEARANCE', isDark: isDark),
              const SizedBox(height: 12),
              _buildCard(
                cardColor: cardColor,
                children: [
                  _ToggleRow(
                    icon: Icons.dark_mode_outlined,
                    iconBg: const Color(0xFF2A2D3E),
                    iconColor: const Color(0xFFBBC5E8),
                    label: 'Dark Mode',
                    textColor: textColor,
                    isDark: isDark,
                    value: isDark,
                    onChanged: (val) async {
                      context.read<ThemeProvider>().toggleTheme(val);
                      final box = await Hive.openBox('user');
                      await box.put('theme_dark', val);
                    },
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // ── DATA ──
              _SectionLabel(label: 'DATA', isDark: isDark),
              const SizedBox(height: 12),
              _buildCard(
                cardColor: cardColor,
                children: [
                  _TapRow(
                    icon: Icons.cleaning_services_outlined,
                    iconBg: const Color(0xFFFFF3E0),
                    iconColor: const Color(0xFFF59E0B),
                    label: 'Clear Cache',
                    textColor: textColor,
                    isDark: isDark,
                    onTap: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          backgroundColor: cardColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          title: Text(
                            'Clear Cache',
                            style: TextStyle(color: textColor),
                          ),
                          content: Text(
                            'This will clear locally cached data. Your account and portfolio data will not be affected.',
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
                                'Clear',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      );

                      if (confirm == true && mounted) {
                        final box = await Hive.openBox('user');
                        // Preserve account-critical keys
                        final keep = {
                          'first_name': box.get('first_name'),
                          'last_name': box.get('last_name'),
                          'has_setup_portfolio': box.get('has_setup_portfolio'),
                          'avatar_path': box.get('avatar_path'),
                          'theme_dark': box.get('theme_dark'),
                        };
                        await box.clear();
                        for (final e in keep.entries) {
                          if (e.value != null) await box.put(e.key, e.value);
                        }
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Cache cleared successfully'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      }
                    },
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // ── APP INFO ──
              _SectionLabel(label: 'APP INFO', isDark: isDark),
              const SizedBox(height: 12),
              _buildCard(
                cardColor: cardColor,
                children: [
                  _InfoRow(
                    icon: Icons.info_outline,
                    iconBg: const Color(0xFFDCEAFF),
                    iconColor: const Color(0xFF2979FF),
                    label: 'Version',
                    value: '1.0.0',
                    textColor: textColor,
                  ),
                ],
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard({
    required Color cardColor,
    required List<Widget> children,
  }) {
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
      child: Column(children: children),
    );
  }
}

// ─────────────────────────────────────────────
// Toggle Row (switch)
// ─────────────────────────────────────────────
class _ToggleRow extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String label;
  final Color textColor;
  final bool isDark;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleRow({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.label,
    required this.textColor,
    required this.isDark,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: textColor,
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF0A3D62),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Tap Row (with chevron)
// ─────────────────────────────────────────────
class _TapRow extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String label;
  final Color textColor;
  final bool isDark;
  final VoidCallback onTap;

  const _TapRow({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.label,
    required this.textColor,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: textColor,
                ),
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey[400], size: 20),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Info Row (label + value, no chevron)
// ─────────────────────────────────────────────
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String label;
  final String value;
  final Color textColor;

  const _InfoRow({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.textColor,
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
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: textColor,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
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
