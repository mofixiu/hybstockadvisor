import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hybstockadvisor/theme/tokens.dart';
import 'package:hybstockadvisor/widgets/ui.dart';

/// Which in-app alerts to create. Stored in the Hive `user` box.
class NotificationSettings extends StatefulWidget {
  const NotificationSettings({super.key});

  @override
  State<NotificationSettings> createState() => _NotificationSettingsState();
}

class _NotificationSettingsState extends State<NotificationSettings> {
  bool _priceMovement = true;
  bool _researchSignals = true;
  bool _weeklySummary = true;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final box = await Hive.openBox('user');
    if (!mounted) return;
    setState(() {
      _priceMovement = box.get('notif_price_movement', defaultValue: true) == true;
      _researchSignals = box.get('notif_ai_forecast', defaultValue: true) == true;
      _weeklySummary = box.get('notif_weekly_summary', defaultValue: true) == true;
    });
  }

  Future<void> _save(Map<String, bool> values) async {
    final box = await Hive.openBox('user');
    for (final e in values.entries) {
      await box.put(e.key, e.value);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Scaffold(
      backgroundColor: p.paper,
      appBar: AppBar(title: const Text('Notifications')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: Gap.xxl),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(Gap.page, Gap.sm, Gap.page, 0),
              child: Text(
                'Alerts are created in the app when it loads new closing data. '
                'Stale data never triggers an alert.',
                style: context.text.bodySmall,
              ),
            ),
            const _Group('Holdings'),
            _ToggleRow(
              icon: Icons.show_chart,
              label: 'Price moves',
              subtitle: 'When a holding closes 3% or more up or down on the day',
              value: _priceMovement,
              onChanged: (v) {
                setState(() => _priceMovement = v);
                _save({'notif_price_movement': v});
              },
            ),
            _ToggleRow(
              icon: Icons.article_outlined,
              label: 'Research signals',
              subtitle: 'When a reviewed research signal is published for a holding',
              value: _researchSignals,
              // The dashboard reads both keys for signal alerts; keep them in step.
              onChanged: (v) {
                setState(() => _researchSignals = v);
                _save({'notif_ai_forecast': v});
              },
              last: true,
            ),
            const _Group('Summaries'),
            _ToggleRow(
              icon: Icons.calendar_today_outlined,
              label: 'Weekly summary',
              subtitle: 'A Friday recap of how your holdings moved',
              value: _weeklySummary,
              onChanged: (v) {
                setState(() => _weeklySummary = v);
                _save({'notif_weekly_summary': v});
              },
              last: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _Group extends StatelessWidget {
  final String label;
  const _Group(this.label);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(Gap.page, Gap.xl, Gap.page, 0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Kicker(label),
        const SizedBox(height: Gap.sm),
        const Hairline(),
      ],
    ),
  );
}

class _ToggleRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool last;

  const _ToggleRow({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.last = false,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final t = context.text;
    return MergeSemantics(
      child: InkWell(
        onTap: () => onChanged(!value),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Gap.page, vertical: 10),
              child: Row(
                children: [
                  Icon(icon, size: 20, color: p.ink),
                  const SizedBox(width: Gap.lg),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(label, style: t.bodyLarge),
                        const SizedBox(height: 2),
                        Text(subtitle, style: t.bodySmall),
                      ],
                    ),
                  ),
                  const SizedBox(width: Gap.sm),
                  Switch(value: value, onChanged: onChanged),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Gap.page),
              child: last ? const Hairline() : const Hairline(indent: 36),
            ),
          ],
        ),
      ),
    );
  }
}
