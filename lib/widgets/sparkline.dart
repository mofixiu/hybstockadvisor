import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:hybstockadvisor/theme/tokens.dart';

/// A small price line drawn as percentage change from its first close.
///
/// Every sparkline in a table shares the same [scalePct], so a +0.97% week
/// looks small next to a +10% week instead of filling the box. A dotted line
/// marks the starting close.
class Sparkline extends StatelessWidget {
  final List<double> values;

  /// Half the vertical range, in percent, shared by the whole table.
  final double scalePct;
  final double width;
  final double height;
  const Sparkline({
    super.key,
    required this.values,
    required this.scalePct,
    this.width = 56,
    this.height = 26,
  });

  /// The shared scale for a set of series: the largest move from the first
  /// close, with a floor of ±3% so flat weeks stay flat.
  static double commonScale(Iterable<List<double>> series, {double floor = 3}) {
    var maxMove = floor;
    for (final s in series) {
      if (s.length < 2 || s.first == 0) continue;
      for (final v in s) {
        maxMove = math.max(maxMove, ((v - s.first) / s.first * 100).abs());
      }
    }
    return maxMove;
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    if (values.length < 2 || values.first == 0) {
      return SizedBox(
        width: width,
        height: height,
        child: Center(child: Container(height: Stroke.hairline, color: p.rule)),
      );
    }
    return CustomPaint(
      size: Size(width, height),
      painter: _SparkPainter(
        values: values,
        scalePct: scalePct,
        line: p.inkMuted,
        base: p.rule,
        end: p.ink,
      ),
    );
  }
}

class _SparkPainter extends CustomPainter {
  final List<double> values;
  final double scalePct;
  final Color line;
  final Color base;
  final Color end;
  _SparkPainter({
    required this.values,
    required this.scalePct,
    required this.line,
    required this.base,
    required this.end,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final mid = size.height / 2;
    final first = values.first;
    double y(double v) => mid - ((v - first) / first * 100) / scalePct * (mid - 1.5);
    final dx = size.width / (values.length - 1);

    final dash = Paint()
      ..color = base
      ..strokeWidth = 1;
    for (var x = 0.0; x < size.width; x += 4) {
      canvas.drawLine(Offset(x, mid), Offset(math.min(x + 2, size.width), mid), dash);
    }

    final path = Path()..moveTo(0, y(values.first));
    for (var i = 1; i < values.length; i++) {
      path.lineTo(dx * i, y(values[i]));
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = line
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.3
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.drawCircle(Offset(size.width, y(values.last)), 1.8, Paint()..color = end);
  }

  @override
  bool shouldRepaint(_SparkPainter old) =>
      old.values != values || old.scalePct != scalePct || old.line != line;
}
