import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:hybstockadvisor/models/market_stock.dart';
import 'package:hybstockadvisor/theme/format.dart';
import 'package:hybstockadvisor/theme/tokens.dart';

/// Daily closes drawn honestly: straight segments between real closes (no
/// smoothing that invents values), a labelled price axis, the period's high
/// and low marked on the line, a dashed baseline at the first close, and the
/// exact close and date on tap. The last close tapped stays in a readout
/// under the chart after the finger lifts.
class PriceChart extends StatefulWidget {
  final List<DailyBar> bars;
  final String currency;
  final double height;
  const PriceChart({
    super.key,
    required this.bars,
    this.currency = 'NGN',
    this.height = 200,
  });

  @override
  State<PriceChart> createState() => _PriceChartState();
}

class _PriceChartState extends State<PriceChart> {
  int? _selected;

  @override
  void didUpdateWidget(PriceChart old) {
    super.didUpdateWidget(old);
    if (old.bars != widget.bars) _selected = null;
  }

  List<DailyBar> get bars => widget.bars;
  String get currency => widget.currency;
  double get height => widget.height;

  Widget _readout(BuildContext context) {
    final t = context.text;
    final i = _selected;
    if (i == null || i >= bars.length) {
      return Text('Tap the line to read a close.', style: t.bodySmall);
    }
    final b = bars[i];
    final prev = i > 0 ? bars[i - 1].close : null;
    final pct = prev == null || prev == 0 ? null : (b.close - prev) / prev * 100;
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: '${Fmt.dateWeekday(b.date)}: close '),
          TextSpan(
            text: Fmt.money(b.close, currency: currency),
            style: TextStyle(color: context.pal.ink, fontWeight: FontWeight.w600),
          ),
          if (pct != null) ...[
            const TextSpan(text: ', '),
            TextSpan(
              text: '${Fmt.arrow(pct).isEmpty ? '' : '${Fmt.arrow(pct)} '}${Fmt.pct(pct)}',
              style: TextStyle(color: context.pal.signed(pct), fontWeight: FontWeight.w600),
            ),
            const TextSpan(text: ' on the day'),
          ],
        ],
      ),
      style: t.bodySmall,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _chart(context),
        const SizedBox(height: 6),
        _readout(context),
      ],
    );
  }

  Widget _chart(BuildContext context) {
    final p = context.pal;
    final t = context.text;
    if (bars.length < 2) {
      return SizedBox(
        height: height,
        child: Center(
          child: Text('Not enough closes to draw a chart.', style: t.bodySmall),
        ),
      );
    }

    final closes = bars.map((b) => b.close).toList();
    final hiIdx = _argExtreme(closes, max: true);
    final loIdx = _argExtreme(closes, max: false);
    final hi = closes[hiIdx];
    final lo = closes[loIdx];
    final start = closes.first;

    // Axis: round to a "nice" step so labels are readable figures.
    final span = (hi - lo).abs() < 1e-9 ? math.max(hi.abs() * 0.04, 0.01) : hi - lo;
    final step = _niceStep(span / 3);
    final minY = lo - span * 0.14;
    final maxY = hi + span * 0.16;
    bool onStep(double v) => ((v / step) - (v / step).round()).abs() < 1e-6;
    final decimals = step >= 1 ? 0 : (step >= 0.1 ? 1 : 2);
    final axisStyle = t.bodySmall!.copyWith(fontSize: 10.5);
    final lastX = (bars.length - 1).toDouble();

    String axisLabel(double v) => Fmt.money(v, currency: currency, decimals: decimals);

    return SizedBox(
      height: height,
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: lastX,
          minY: minY,
          maxY: maxY,
          clipData: const FlClipData.none(),
          borderData: FlBorderData(
            show: true,
            border: Border(bottom: BorderSide(color: p.inkMuted, width: Stroke.hairline)),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: step,
            checkToShowHorizontalLine: onStep,
            getDrawingHorizontalLine: (_) =>
                FlLine(color: p.rule, strokeWidth: Stroke.hairline),
          ),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 56,
                interval: step,
                getTitlesWidget: (value, meta) {
                  if (!onStep(value) || value <= meta.min || value >= meta.max) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: Text(axisLabel(value), style: axisStyle),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 22,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  final i = value.round();
                  if ((value - i).abs() > 0.01) return const SizedBox.shrink();
                  final mid = (bars.length - 1) ~/ 2;
                  if (i != 0 && i != mid && i != bars.length - 1) {
                    return const SizedBox.shrink();
                  }
                  return SideTitleWidget(
                    meta: meta,
                    fitInside: SideTitleFitInsideData.fromTitleMeta(meta, distanceFromEdge: 0),
                    child: Text(Fmt.dateShort(bars[i].date), style: axisStyle),
                  );
                },
              ),
            ),
          ),
          extraLinesData: ExtraLinesData(
            horizontalLines: [
              HorizontalLine(
                y: start,
                color: p.inkFaint,
                strokeWidth: 0.8,
                dashArray: [3, 3],
                // At the left end the line starts on the baseline, so label the
                // right end, on whichever side the last close leaves clear.
                label: HorizontalLineLabel(
                  show: true,
                  alignment: closes.last >= start ? Alignment.bottomRight : Alignment.topRight,
                  padding: const EdgeInsets.only(right: 2, top: 2, bottom: 2),
                  style: axisStyle.copyWith(color: p.inkMuted),
                  labelResolver: (_) => 'Start ${Fmt.money(start, currency: currency)}',
                ),
              ),
            ],
          ),
          lineTouchData: LineTouchData(
            handleBuiltInTouches: true,
            touchCallback: (event, response) {
              final spots = response?.lineBarSpots;
              if (spots == null || spots.isEmpty) return;
              final i = spots.first.x.round().clamp(0, bars.length - 1);
              if (i != _selected) setState(() => _selected = i);
            },
            getTouchedSpotIndicator: (bar, indexes) => indexes
                .map(
                  (_) => TouchedSpotIndicatorData(
                    FlLine(color: p.inkMuted, strokeWidth: Stroke.hairline),
                    FlDotData(
                      getDotPainter: (_, _, _, _) => FlDotCirclePainter(
                        radius: 3.5,
                        color: p.paper,
                        strokeWidth: 1.6,
                        strokeColor: p.ink,
                      ),
                    ),
                  ),
                )
                .toList(),
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => p.ink,
              tooltipBorderRadius: BorderRadius.circular(Radii.xs),
              tooltipPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              fitInsideHorizontally: true,
              fitInsideVertically: true,
              getTooltipItems: (spots) => spots.map((s) {
                final i = s.x.round().clamp(0, bars.length - 1);
                return LineTooltipItem(
                  Fmt.money(bars[i].close, currency: currency),
                  t.labelMedium!.copyWith(color: p.paper),
                  children: [
                    TextSpan(
                      text: '\n${Fmt.dateWeekday(bars[i].date)}',
                      style: t.bodySmall!.copyWith(color: p.paper.withValues(alpha: 0.8)),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: [
                for (var i = 0; i < bars.length; i++) FlSpot(i.toDouble(), closes[i]),
              ],
              isCurved: false,
              color: p.ink,
              barWidth: 1.5,
              isStrokeCapRound: false,
              belowBarData: BarAreaData(show: false),
              dotData: FlDotData(
                show: true,
                checkToShowDot: (spot, _) {
                  final i = spot.x.round();
                  return i == hiIdx || i == loIdx || i == bars.length - 1;
                },
                getDotPainter: (spot, _, _, _) {
                  final i = spot.x.round();
                  if (i == hiIdx || i == loIdx) {
                    final isHigh = i == hiIdx;
                    return _LabelledDot(
                      label: '${isHigh ? 'High' : 'Low'} ${Fmt.money(isHigh ? hi : lo, currency: currency)}',
                      above: isHigh,
                      align: i < bars.length * 0.3
                          ? _LabelAlign.right
                          : i > bars.length * 0.7
                          ? _LabelAlign.left
                          : _LabelAlign.center,
                      color: p.ink,
                      fill: p.paper,
                      textStyle: axisStyle.copyWith(color: p.ink, fontWeight: FontWeight.w600),
                    );
                  }
                  return FlDotCirclePainter(
                    radius: 3,
                    color: p.ink,
                    strokeWidth: 0,
                  );
                },
              ),
            ),
          ],
        ),
        duration: Duration.zero,
      ),
    );
  }

  static int _argExtreme(List<double> v, {required bool max}) {
    var idx = 0;
    for (var i = 1; i < v.length; i++) {
      if (max ? v[i] > v[idx] : v[i] < v[idx]) idx = i;
    }
    return idx;
  }

  static double _niceStep(double raw) {
    if (raw <= 0) return 1;
    final exp = math.pow(10, (math.log(raw) / math.ln10).floor()).toDouble();
    final f = raw / exp;
    final nice = f < 1.5 ? 1 : (f < 3 ? 2 : (f < 7 ? 5 : 10));
    return nice * exp;
  }
}

enum _LabelAlign { left, center, right }

/// A ring dot with a short text label above or below it.
class _LabelledDot extends FlDotPainter {
  final String label;
  final bool above;
  final _LabelAlign align;
  final Color color;
  final Color fill;
  final TextStyle textStyle;

  const _LabelledDot({
    required this.label,
    required this.above,
    required this.align,
    required this.color,
    required this.fill,
    required this.textStyle,
  });

  @override
  void draw(Canvas canvas, FlSpot spot, Offset offsetInCanvas) {
    canvas.drawCircle(offsetInCanvas, 3.2, Paint()..color = fill);
    canvas.drawCircle(
      offsetInCanvas,
      3.2,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );
    final tp = TextPainter(
      text: TextSpan(text: label, style: textStyle),
      textDirection: TextDirection.ltr,
    )..layout();
    final dx = switch (align) {
      _LabelAlign.left => offsetInCanvas.dx - tp.width + 4,
      _LabelAlign.center => offsetInCanvas.dx - tp.width / 2,
      _LabelAlign.right => offsetInCanvas.dx - 4,
    };
    final dy = above ? offsetInCanvas.dy - tp.height - 6 : offsetInCanvas.dy + 6;
    tp.paint(canvas, Offset(dx, dy));
  }

  @override
  Size getSize(FlSpot spot) => const Size(8, 8);

  @override
  Color get mainColor => color;

  @override
  FlDotPainter lerp(FlDotPainter a, FlDotPainter b, double t) => b;

  @override
  List<Object?> get props => [label, above, align, color, fill, textStyle];
}
