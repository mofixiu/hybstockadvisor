import 'package:flutter/material.dart';

/// Custom page route with smooth fade transition
class FadePageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  FadePageRoute({required this.page})
    : super(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 250),
        reverseTransitionDuration: const Duration(milliseconds: 200),
      );
}

/// Custom page route with slide from right transition (iOS-style)
class SlidePageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  SlidePageRoute({required this.page})
    : super(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOut;

          var tween = Tween(
            begin: begin,
            end: end,
          ).chain(CurveTween(curve: curve));

          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
        reverseTransitionDuration: const Duration(milliseconds: 250),
      );
}

/// Custom page route with scale + fade transition (modern)
class ScalePageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  ScalePageRoute({required this.page})
    : super(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const curve = Curves.easeInOutCubic;

          var scaleTween = Tween<double>(
            begin: 0.92,
            end: 1.0,
          ).chain(CurveTween(curve: curve));

          var fadeTween = Tween<double>(
            begin: 0.0,
            end: 1.0,
          ).chain(CurveTween(curve: curve));

          return ScaleTransition(
            scale: animation.drive(scaleTween),
            child: FadeTransition(
              opacity: animation.drive(fadeTween),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 350),
        reverseTransitionDuration: const Duration(milliseconds: 300),
      );
}

/// Custom page route with slide up transition (modal-style)
class SlideUpPageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  SlideUpPageRoute({required this.page})
    : super(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(0.0, 1.0);
          const end = Offset.zero;
          const curve = Curves.easeOutCubic;

          var tween = Tween(
            begin: begin,
            end: end,
          ).chain(CurveTween(curve: curve));

          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 400),
        reverseTransitionDuration: const Duration(milliseconds: 350),
      );
}

/// Extension on BuildContext for easy navigation with custom transitions
extension NavigationExtension on BuildContext {
  /// Navigate with fade transition
  Future<T?> pushFade<T>(Widget page) {
    return Navigator.push(this, FadePageRoute(page: page));
  }

  /// Navigate and replace with fade transition
  Future<T?> pushReplacementFade<T, TO>(Widget page) {
    return Navigator.pushReplacement(this, FadePageRoute(page: page));
  }

  /// Navigate with slide transition
  Future<T?> pushSlide<T>(Widget page) {
    return Navigator.push(this, SlidePageRoute(page: page));
  }

  /// Navigate and replace with slide transition
  Future<T?> pushReplacementSlide<T, TO>(Widget page) {
    return Navigator.pushReplacement(this, SlidePageRoute(page: page));
  }

  /// Navigate with scale transition
  Future<T?> pushScale<T>(Widget page) {
    return Navigator.push(this, ScalePageRoute(page: page));
  }

  /// Navigate and replace with scale transition
  Future<T?> pushReplacementScale<T, TO>(Widget page) {
    return Navigator.pushReplacement(this, ScalePageRoute(page: page));
  }

  /// Navigate with slide up transition
  Future<T?> pushSlideUp<T>(Widget page) {
    return Navigator.push(this, SlideUpPageRoute(page: page));
  }
}
