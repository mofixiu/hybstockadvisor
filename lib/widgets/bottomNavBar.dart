import 'package:flutter/material.dart';
import 'package:hybstockadvisor/screens/ai_insights.dart';
import 'package:hybstockadvisor/screens/dashboard.dart';
import 'package:hybstockadvisor/screens/portfolio.dart';
import 'package:hybstockadvisor/screens/profile.dart';
import 'package:hybstockadvisor/theme/tokens.dart';

/// The four tabs: Home, Research, Portfolio, Profile.
///
/// A plain paper bar with a hairline on top. The selected tab is navy with a
/// short rule above it; the others are muted ink.
class BottomNavBar extends StatelessWidget {
  final int currentIndex;

  const BottomNavBar({super.key, required this.currentIndex});

  static const _items = [
    (Icons.home_outlined, Icons.home, 'Home'),
    (Icons.article_outlined, Icons.article, 'Research'),
    (Icons.work_outline, Icons.work, 'Portfolio'),
    (Icons.person_outline, Icons.person, 'Profile'),
  ];

  void _navigate(BuildContext context, int index) {
    if (index == currentIndex) return;
    final Widget next = switch (index) {
      0 => const Dashboard(),
      1 => const AiInsights(),
      2 => const Portfolio(),
      _ => const Profile(),
    };
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, _, _) => next,
        transitionsBuilder: (_, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 120),
        reverseTransitionDuration: const Duration(milliseconds: 120),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: p.paper,
        border: Border(top: BorderSide(color: p.rule, width: Stroke.hairline)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 58,
          child: Row(
            children: [
              for (var i = 0; i < _items.length; i++)
                Expanded(child: _item(context, i)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _item(BuildContext context, int index) {
    final p = context.pal;
    final (icon, activeIcon, label) = _items[index];
    final active = index == currentIndex;
    final color = active ? p.accent : p.inkFaint;
    return Semantics(
      selected: active,
      button: true,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        onTap: () => _navigate(context, index),
        child: Column(
          children: [
            Container(
              height: 2,
              width: 28,
              color: active ? p.accent : Colors.transparent,
            ),
            const Spacer(),
            Icon(active ? activeIcon : icon, color: color, size: 22),
            const SizedBox(height: 3),
            Text(
              label,
              style: context.text.labelMedium?.copyWith(
                color: color,
                fontSize: 11,
                fontWeight: active ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}
