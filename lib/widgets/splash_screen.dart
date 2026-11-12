import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hybstockadvisor/screens/auth/auth_scaffold.dart';
import 'package:hybstockadvisor/screens/auth/login.dart';
import 'package:hybstockadvisor/screens/dashboard.dart';
import 'package:hybstockadvisor/services/api_service.dart';
import 'package:hybstockadvisor/theme/tokens.dart';

/// Wordmark on paper while the saved session is checked.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fade = AnimationController(
    duration: const Duration(milliseconds: 600),
    vsync: this,
  );

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    await _fade.forward();
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;

    // A saved session is a token plus a user id. The Dio 401 interceptor
    // handles server-side expiry.
    var isLoggedIn = false;
    try {
      final token = await ApiService.readToken();
      if (token != null && token.isNotEmpty) {
        final authBox = await Hive.openBox('auth');
        isLoggedIn = authBox.get('user_id') != null;
      }
    } catch (_) {
      // Secure storage can fail after a reinstall on some devices.
      isLoggedIn = false;
    }

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, _, _) => isLoggedIn ? const Dashboard() : const Login(),
        transitionsBuilder: (_, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  @override
  void dispose() {
    _fade.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Scaffold(
      backgroundColor: p.paper,
      body: Center(
        child: FadeTransition(
          opacity: _fade,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Wordmark(size: 34, align: TextAlign.center),
              const SizedBox(height: Gap.sm),
              SizedBox(width: 56, child: Container(height: Stroke.heavy, color: p.ruleStrong)),
              const SizedBox(height: Gap.sm),
              Text(
                'Research companion for NGX investors',
                textAlign: TextAlign.center,
                style: context.text.bodyMedium?.copyWith(color: p.inkMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
