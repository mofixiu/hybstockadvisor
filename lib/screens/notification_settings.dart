import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

class NotificationSettings extends StatefulWidget {
  const NotificationSettings({super.key});

  @override
  State<NotificationSettings> createState() => _NotificationSettingsState();
}

class _NotificationSettingsState extends State<NotificationSettings> {
  // Alert toggles
  bool _priceMovement = true;
  bool _aiForecast = true;
  bool _safetyIndex = true;
  // General toggles
  bool _appUpdates = true;
  bool _weeklySummary = false;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final box = await Hive.openBox('user');
    setState(() {
      _priceMovement = box.get('notif_price_movement', defaultValue: true);
      _aiForecast = box.get('notif_ai_forecast', defaultValue: true);
      _safetyIndex = box.get('notif_safety_index', defaultValue: true);
      _appUpdates = box.get('notif_app_updates', defaultValue: true);
      _weeklySummary = box.get('notif_weekly_summary', defaultValue: false);
    });
  }

  Future<void> _savePref(String key, bool value) async {
    final box = await Hive.openBox('user');
    await box.put(key, value);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1A1A2E) : const Color(0xFFF2F4F7);
    final cardColor = isDark ? const Color(0xFF2A2D3E) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A2E);
    final dividerColor = isDark
        ? Colors.white.withOpacity(0.06)
        : Colors.grey.withOpacity(0.15);

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
          'Notifications',
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

              // ── ALERTS ──
              _SectionLabel(label: 'ALERTS', isDark: isDark),
              const SizedBox(height: 12),
              _buildCard(
                cardColor: cardColor,
                dividerColor: dividerColor,
                children: [
                  _NotifRow(
                    icon: Icons.show_chart,
                    iconBg: const Color(0xFFDCEAFF),
                    iconColor: const Color(0xFF2979FF),
                    label: 'Price Movement Alerts',
                    subtitle: 'Get notified on significant stock movements',
                    textColor: textColor,
                    value: _priceMovement,
                    onChanged: (val) {
                      setState(() => _priceMovement = val);
                      _savePref('notif_price_movement', val);
                    },
                  ),
                  _NotifRow(
                    icon: Icons.auto_awesome,
                    iconBg: const Color(0xFFEDE7FF),
                    iconColor: const Color(0xFF7C3AED),
                    label: 'AI Forecast Ready',
                    subtitle: 'When a new AI forecast is available',
                    textColor: textColor,
                    value: _aiForecast,
                    onChanged: (val) {
                      setState(() => _aiForecast = val);
                      _savePref('notif_ai_forecast', val);
                    },
                  ),
                  _NotifRow(
                    icon: Icons.security,
                    iconBg: const Color(0xFFD6F5E3),
                    iconColor: const Color(0xFF2DBD6E),
                    label: 'Safety Index Change',
                    subtitle: 'Alert when safety index changes significantly',
                    textColor: textColor,
                    value: _safetyIndex,
                    onChanged: (val) {
                      setState(() => _safetyIndex = val);
                      _savePref('notif_safety_index', val);
                    },
                    isLast: true,
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // ── GENERAL ──
              _SectionLabel(label: 'GENERAL', isDark: isDark),
              const SizedBox(height: 12),
              _buildCard(
                cardColor: cardColor,
                dividerColor: dividerColor,
                children: [
                  _NotifRow(
                    icon: Icons.system_update_outlined,
                    iconBg: const Color(0xFFFFF3E0),
                    iconColor: const Color(0xFFF59E0B),
                    label: 'App Updates',
                    subtitle: 'News about new features and updates',
                    textColor: textColor,
                    value: _appUpdates,
                    onChanged: (val) {
                      setState(() => _appUpdates = val);
                      _savePref('notif_app_updates', val);
                    },
                  ),
                  _NotifRow(
                    icon: Icons.calendar_today_outlined,
                    iconBg: const Color(0xFFFFE4EC),
                    iconColor: const Color(0xFFE91E63),
                    label: 'Weekly Summary',
                    subtitle: 'Receive a weekly portfolio performance summary',
                    textColor: textColor,
                    value: _weeklySummary,
                    onChanged: (val) {
                      setState(() => _weeklySummary = val);
                      _savePref('notif_weekly_summary', val);
                    },
                    isLast: true,
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
    required Color dividerColor,
    required List<_NotifRow> children,
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
      child: Column(
        children: children.asMap().entries.map((e) {
          final isLast = e.key == children.length - 1;
          return Column(
            children: [
              e.value,
              if (!isLast) Divider(height: 1, indent: 70, color: dividerColor),
            ],
          );
        }).toList(),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Notification Toggle Row
// ─────────────────────────────────────────────
class _NotifRow extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String label;
  final String subtitle;
  final Color textColor;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool isLast;

  const _NotifRow({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.label,
    required this.subtitle,
    required this.textColor,
    required this.value,
    required this.onChanged,
    this.isLast = false,
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
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
