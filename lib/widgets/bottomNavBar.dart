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
    final backgroundColor = isDarkMode
        ? HybStockAdvisor.darkCardBackground
        : Color(0xFFF2F4F7);
    final selectedItemColor = HybStockAdvisor.lightButtonBackground;
    final unselectedItemColor = Colors.grey[600];

    return SizedBox(
      height: 95,
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) => _navigate(context, index),
        backgroundColor: backgroundColor,
        selectedItemColor: selectedItemColor,
        unselectedItemColor: unselectedItemColor,
        type: BottomNavigationBarType.fixed,
        elevation: 8.0,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(
            icon: FaIcon(FontAwesomeIcons.codePullRequest),
            label: "AI-Insights",
          ),
          BottomNavigationBarItem(
            icon: FaIcon(FontAwesomeIcons.briefcase),
            label: "Portfolio",
          ),
          BottomNavigationBarItem(
            icon: FaIcon(FontAwesomeIcons.person),
            label: "Profile",
          ),
        ],
      ),
    );
  }
}
