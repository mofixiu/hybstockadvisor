import 'dart:math';

import 'package:flutter/material.dart';
import 'package:hybstockadvisor/theme/tokens.dart';

/// The company's logo from `assets/images/ngx_logos/{symbol}.png`, on a
/// hairline-bordered square. Falls back to the symbol's first letters.
class StockLogo extends StatelessWidget {
  final String symbol;
  final double size;

  const StockLogo({super.key, required this.symbol, this.size = 36});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final radius = BorderRadius.circular(Radii.sm);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: radius,
        border: Border.all(color: p.rule, width: Stroke.hairline),
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Image.asset(
          'assets/images/ngx_logos/$symbol.png',
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _placeholder(context),
        ),
      ),
    );
  }

  Widget _placeholder(BuildContext context) {
    final p = context.pal;
    return Container(
      color: p.surface,
      alignment: Alignment.center,
      child: Text(
        symbol.substring(0, min(3, symbol.length)),
        style: AppType.sans(
          size: size * 0.28,
          weight: FontWeight.w600,
          color: p.inkMuted,
        ),
      ),
    );
  }
}
