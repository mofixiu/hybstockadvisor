import 'package:flutter/material.dart';
import 'dart:math';

/// Displays a stock logo from `assets/images/ngx_logos/{symbol}.png`.
/// Falls back to a styled box with the abbreviated symbol text if the
/// image is not bundled.
class StockLogo extends StatelessWidget {
  final String symbol;
  final double size;

  const StockLogo({super.key, required this.symbol, this.size = 44});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.23), // ≈10 for 44
      child: Image.asset(
        'assets/images/ngx_logos/$symbol.png',
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _placeholder(),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFF2979FF).withOpacity(0.1),
        borderRadius: BorderRadius.circular(size * 0.23),
      ),
      child: Center(
        child: Text(
          symbol.substring(0, min(3, symbol.length)),
          style: TextStyle(
            fontSize: size * 0.23,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF0A3D62),
          ),
        ),
      ),
    );
  }
}
