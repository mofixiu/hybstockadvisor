import 'dart:ui' show ImageFilter;
import 'package:hybstockadvisor/screens/dashboard.dart';
import 'package:hybstockadvisor/screens/profile.dart';
import 'package:hybstockadvisor/screens/ai_insights.dart';
import 'package:hybstockadvisor/screens/portfolio.dart';
import 'package:hybstockadvisor/themes/theme.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;

  const BottomNavBar({super.key, required this.currentIndex});

  void _navigate(BuildContext context, int index) {
    if (index == currentIndex) return;

    Widget nextPage;
    switch (index) {
      case 0:
        nextPage = const Dashboard();
        break;
      case 1:
        nextPage = const AiInsights();
        break;
      case 2:
        nextPage = const Portfolio();
        break;
      case 3:
        nextPage = const Profile();
        break;
      default:
        return;
    }

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => nextPage,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          // Smooth fade transition
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 150),
        reverseTransitionDuration: const Duration(milliseconds: 150),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get theme-aware colors
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Glassmorphic configurations - optimized for true "liquid glass" premium finish
    final glassColor = isDarkMode
        ? Colors.black.withOpacity(0.25)
        : Colors.white.withOpacity(0.65);
    final borderColor = isDarkMode
        ? Colors.white.withOpacity(0.12)
        : Colors.white.withOpacity(0.4);
    final activeGlowColor = isDarkMode
        ? const Color(0xFF2979FF).withOpacity(0.12)
        : HybStockAdvisor.lightButtonBackground.withOpacity(0.08);
    
    final activeItemColor = isDarkMode
        ? const Color(0xFF2979FF)
        : HybStockAdvisor.lightButtonBackground;
    final inactiveItemColor = isDarkMode
        ? Colors.white.withOpacity(0.45)
        : Colors.grey[600]!;

    return Container(
      height: 95,
      color: Colors.transparent, // Ensures it overlays cleanly on scrollable body
      padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20, top: 5),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: isDarkMode
                  ? Colors.black.withOpacity(0.35)
                  : Colors.black.withOpacity(0.06),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16.0, sigmaY: 16.0),
            child: Container(
              decoration: BoxDecoration(
                color: glassColor,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: borderColor,
                  width: 1.2,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildNavItem(
                    context: context,
                    index: 0,
                    icon: Icons.home_rounded,
                    label: "Home",
                    isActive: currentIndex == 0,
                    activeColor: activeItemColor,
                    inactiveColor: inactiveItemColor,
                    glowColor: activeGlowColor,
                  ),
                  _buildNavItem(
                    context: context,
                    index: 1,
                    icon: FontAwesomeIcons.codePullRequest,
                    label: "AI-Insights",
                    isActive: currentIndex == 1,
                    activeColor: activeItemColor,
                    inactiveColor: inactiveItemColor,
                    glowColor: activeGlowColor,
                    isFa: true,
                  ),
                  _buildNavItem(
                    context: context,
                    index: 2,
                    icon: FontAwesomeIcons.briefcase,
                    label: "Portfolio",
                    isActive: currentIndex == 2,
                    activeColor: activeItemColor,
                    inactiveColor: inactiveItemColor,
                    glowColor: activeGlowColor,
                    isFa: true,
                  ),
                  _buildNavItem(
                    context: context,
                    index: 3,
                    icon: FontAwesomeIcons.person,
                    label: "Profile",
                    isActive: currentIndex == 3,
                    activeColor: activeItemColor,
                    inactiveColor: inactiveItemColor,
                    glowColor: activeGlowColor,
                    isFa: true,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required int index,
    required IconData icon,
    required String label,
    required bool isActive,
    required Color activeColor,
    required Color inactiveColor,
    required Color glowColor,
    bool isFa = false,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: () => _navigate(context, index),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isActive ? glowColor : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  isFa
                      ? FaIcon(
                          icon,
                          color: isActive ? activeColor : inactiveColor,
                          size: isActive ? 20 : 18,
                        )
                      : Icon(
                          icon,
                          color: isActive ? activeColor : inactiveColor,
                          size: isActive ? 22 : 20,
                        ),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                      color: isActive ? activeColor : inactiveColor,
                      letterSpacing: 0.15,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
