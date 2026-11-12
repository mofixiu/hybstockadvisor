import 'package:flutter/material.dart';
import 'package:hybstockadvisor/models/market_stock.dart';
import 'package:hybstockadvisor/models/research_signal.dart';
import 'package:hybstockadvisor/providers/market_data_provider.dart';
import 'package:hybstockadvisor/services/api_service.dart';
import 'package:hybstockadvisor/theme/format.dart';
import 'package:hybstockadvisor/theme/tokens.dart';
import 'package:hybstockadvisor/widgets/ask_sheet.dart';
import 'package:hybstockadvisor/widgets/bottomNavBar.dart';
import 'package:hybstockadvisor/widgets/stock_logo.dart';
import 'package:hybstockadvisor/widgets/stock_picker_sheet.dart';
import 'package:hybstockadvisor/widgets/ui.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

/// Research: an analyst's note for the selected stock, built only from what
/// `/api/insights/{ticker}` returns. Direction, probability against the base
/// rate, horizon, data date and source, numbered evidence, and the model's
/// track record against a baseline. Nothing is shown for data the backend
/// does not send.
class AiInsights extends StatefulWidget {
  const AiInsights({super.key});

  @override
  State<AiInsights> createState() => _AiInsightsState();
}

class _AiInsightsState extends State<AiInsights> {
  String _ticker = ApiService.currentTicker;
  bool _loading = true;
  String? _error;
  Map<String, dynamic> _data = {};
  ResearchSignal _signal = ResearchSignal.unavailable;
  List<MarketStock> _market = [];

  MarketStock? get _stock {
    for (final s in _market) {
      if (s.symbol == _ticker) return s;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _load();
    _loadMarket();
  }

  Future<void> _loadMarket() async {
    final res = await context.read<MarketDataProvider>().getMarketSummary();
    if (!mounted) return;
    setState(() => _market = MarketStock.listFromSummary(res));
  }

  Future<void> _load({bool force = false}) async {
    final ticker = _ticker;
    setState(() {
      _loading = true;
      _error = null;
    });
    final res = await context.read<MarketDataProvider>().getInsights(ticker, force: force);
    if (!mounted || ticker != _ticker) return;
    if (res == null || res['status'] != 'success' || res['data'] is! Map) {
      setState(() {
        _loading = false;
        _error = ApiService.failureFor('insights:$ticker') ?? "Couldn't load the note for $ticker. Try again.";
      });
      return;
    }
    final data = Map<String, dynamic>.from(res['data'] as Map);
    setState(() {
      _data = data;
      _signal = ResearchSignal.fromJson(data['signal'], dataStale: data['data_stale'] == true);
      _loading = false;
    });
  }

  Future<void> _pickStock() async {
    if (_market.isEmpty) return;
    final picked = await showStockPicker(context, stocks: _market, selected: _ticker);
    if (picked == null || !mounted) return;
    ApiService.currentTicker = picked.symbol;
    setState(() => _ticker = picked.symbol);
    _load();
  }

  Future<void> _openBroker() async {
    final url = Uri.parse('https://app.investbamboo.com/');
    try {
      final ok = await launchUrl(url, mode: LaunchMode.inAppBrowserView);
      if (!ok && mounted) showNotice(context, "Couldn't open Bamboo.");
    } catch (_) {
      if (mounted) showNotice(context, "Couldn't open Bamboo.");
    }
  }

  void _ask() {
    final price = _data['price'];
    showAskSheet(
      context,
      about: AskContext(
        ticker: _ticker,
        price: price is num ? price.toDouble() : null,
        currency: _data['currency']?.toString() ?? 'NGN',
        asOf: _data['data_as_of'],
        stale: _data['data_stale'] == true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: const BottomNavBar(currentIndex: 1),
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: context.pal.accent,
          onRefresh: () => _load(force: true),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: Gap.xxl),
            children: [
              const PageTitle('Research'),
              _stockRow(context),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Gap.page),
                child: _loading
                    ? const _NoteSkeleton()
                    : _error != null
                    ? MessageBlock(
                        title: 'Note not loaded',
                        body: _error,
                        actionLabel: 'Try again',
                        onAction: () => _load(force: true),
                      )
                    : _note(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stockRow(BuildContext context) {
    final t = context.text;
    final p = context.pal;
    final s = _stock;
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: Gap.page),
          child: HeavyRule(),
        ),
        InkWell(
          onTap: _market.isEmpty ? null : _pickStock,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(Gap.page, Gap.md, Gap.md, Gap.md),
            child: Row(
              children: [
                StockLogo(symbol: _ticker, size: 36),
                const SizedBox(width: Gap.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_ticker, style: t.titleMedium),
                      Text(
                        s?.name ?? 'NGX',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: t.bodySmall,
                      ),
                    ],
                  ),
                ),
                if (_market.isNotEmpty) ...[
                  Text('Change', style: t.labelLarge?.copyWith(color: p.accent)),
                  Icon(Icons.expand_more, color: p.accent, size: 20),
                ],
              ],
            ),
          ),
        ),
        const Hairline(indent: Gap.page, endIndent: Gap.page),
      ],
    );
  }

  Widget _note(BuildContext context) {
    final t = context.text;
    final p = context.pal;
    final sig = _signal;
    final stale = _data['data_stale'] == true;
    final hasData = _data['price'] is num;
    final currency = _data['currency']?.toString() ?? 'NGN';

    final headline = sig.available && sig.direction != null
        ? '${sig.isPositive ? 'Positive' : 'Negative'} research signal for $_ticker over the next ${sig.horizon} trading days'
        : !hasData
        ? 'No verified data for $_ticker yet'
        : stale
        ? 'No signal for $_ticker: the data is stale'
        : 'No reviewed signal for $_ticker';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: Gap.lg),
        Kicker(
          'Research note · NGX${_data['data_as_of'] != null ? ' · ${Fmt.date(_data['data_as_of'])}' : ''}',
          color: p.accent,
        ),
        const SizedBox(height: Gap.sm),
        Text(headline, style: t.headlineSmall),
        const SizedBox(height: Gap.md),
        Text(
          _data['explanation']?.toString() ?? 'No explanation was returned.',
          style: t.bodyLarge?.copyWith(color: p.inkMuted),
        ),

        // ── Key facts ──
        const SectionHead('Key facts'),
        if (sig.available && sig.direction != null) ...[
          LabelValueRow(
            'Direction',
            valueWidget: Text(
              '${sig.isPositive ? Fmt.up : Fmt.down} ${sig.isPositive ? 'Positive' : 'Negative'}',
              style: t.titleMedium?.copyWith(color: sig.isPositive ? p.up : p.down),
            ),
          ),
          LabelValueRow(
            'Chance of a positive return',
            value: Fmt.probability(sig.probability),
            note: 'Model estimate for the ${sig.horizon}-day horizon',
            strong: true,
          ),
          LabelValueRow(
            'Base rate',
            value: sig.baseRate == null ? 'Not reported' : Fmt.probability(sig.baseRate),
            note: 'How often ${sig.horizon}-day returns were positive in the training period',
          ),
          if (sig.edge != null) _EdgeRow(edge: sig.edge!),
          LabelValueRow(
            'Horizon',
            value: '${sig.horizon} trading days',
            note: 'Evaluated over ${sig.horizonMin} to ${sig.horizonMax} days',
          ),
        ],
        LabelValueRow(
          'Last close',
          value: hasData ? Fmt.money(_data['price'] as num, currency: currency) : 'Not available',
          strong: hasData,
        ),
        LabelValueRow(
          'Data date',
          value: _data['data_as_of'] == null
              ? 'Not reported'
              : '${Fmt.date(_data['data_as_of'])}, ${Fmt.timeWat(_data['data_as_of'])}',
        ),
        LabelValueRow(
          'Freshness',
          valueWidget: !hasData
              ? Text('No verified close', style: t.bodyMedium?.copyWith(fontWeight: FontWeight.w500))
              : stale
              ? const StaleTag(label: 'Stale: older than 4 days')
              : Text('Current', style: t.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
          note: !hasData
              ? 'The server has no verified close for this stock'
              : stale
              ? 'Signals are hidden until newer closes arrive'
              : null,
        ),
        LabelValueRow(
          'Source',
          value: _data['data_source']?.toString() ?? 'Not reported',
        ),
        for (final (key, label) in const [('rsi_impact', 'RSI momentum'), ('ema_impact', 'EMA-50 trend')])
          if (_data[key] is num)
            _DriverRow(label: label, value: (_data[key] as num).toDouble()),

        // ── Evidence ──
        const SectionHead('Evidence'),
        if (sig.evidence.isEmpty)
          Text(
            sig.available
                ? 'The model published no evidence lines for this signal.'
                : !hasData
                ? 'No evidence is shown without a verified close.'
                : stale
                ? 'No evidence is shown while the data is stale.'
                : 'No evidence is published because no signal has passed review for this close.',
            style: t.bodyMedium?.copyWith(color: p.inkMuted),
          )
        else
          for (var i = 0; i < sig.evidence.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: Gap.md),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 26,
                    child: Text('${i + 1}.', style: AppType.serif(size: 16, color: p.accent)),
                  ),
                  Expanded(child: Text(sig.evidence[i], style: t.bodyMedium)),
                ],
              ),
            ),

        // ── Track record ──
        if (sig.validation != null) _trackRecord(context, sig.validation!),

        // ── Footer ──
        const SizedBox(height: Gap.xl),
        const HeavyRule(),
        const SizedBox(height: Gap.md),
        Text(
          'This is a research signal, not advice. It is uncertain and may be wrong. '
          'HybStockAdvisor does not place trades.',
          style: t.bodySmall,
        ),
        const SizedBox(height: Gap.lg),
        QuietButton('Ask about this note', onPressed: _ask),
        const SizedBox(height: Gap.xs),
        Align(
          alignment: Alignment.centerLeft,
          child: LinkText('Open Bamboo, an external broker ↗', arrow: false, onTap: _openBroker),
        ),
      ],
    );
  }

  Widget _trackRecord(BuildContext context, SignalValidation v) {
    final t = context.text;
    final p = context.pal;
    String scores(double? model, double? baseline) => model == null || baseline == null
        ? 'Not reported'
        : '${Fmt.number(model, decimals: 3)} vs ${Fmt.number(baseline, decimals: 3)}';
    String? verdict(double? model, double? baseline) {
      if (model == null || baseline == null) return null;
      final diff = baseline - model;
      if (diff > 0) return 'Model beats the baseline by ${Fmt.number(diff, decimals: 3)}';
      if (diff < 0) return 'Model is worse than the baseline by ${Fmt.number(-diff, decimals: 3)}';
      return 'Model is level with the baseline';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHead('How reliable has this model been?'),
        Text(
          'The Brier score measures how close a model’s probabilities were to what happened. '
          '0 is perfect. The baseline always predicts the base rate. Lower is better, so the '
          'model only adds information when its score is below the baseline’s.',
          style: t.bodyMedium?.copyWith(color: p.inkMuted),
        ),
        const SizedBox(height: Gap.sm),
        LabelValueRow(
          'Paper predictions',
          value: Fmt.number(v.paperSamples),
          note: 'Recorded before the outcome was known',
        ),
        LabelValueRow('Hit rate', value: Fmt.probability(v.paperHitRate)),
        LabelValueRow(
          'Brier score, paper tracking',
          value: scores(v.paperBrier, v.paperBaselineBrier),
          note: verdict(v.paperBrier, v.paperBaselineBrier),
        ),
        LabelValueRow(
          'Brier score, backtest',
          value: scores(v.backtestBrier, v.backtestBaselineBrier),
          note: verdict(v.backtestBrier, v.backtestBaselineBrier),
        ),
        if (v.paperMeanReturnPct != null)
          LabelValueRow(
            'Average return per paper signal',
            valueWidget: ChangeText(pct: v.paperMeanReturnPct, arrow: false),
            note: 'After costs, in the signal’s direction',
          ),
        if (v.backtestExcessPct != null)
          LabelValueRow(
            'Backtest return vs benchmark',
            valueWidget: ChangeText(pct: v.backtestExcessPct, arrow: false),
            note: 'Average per signal, after costs',
          ),
        LabelValueRow(
          'Model',
          value: [
            v.modelVersion ?? 'Version not reported',
            if (v.reviewer != null || v.reviewedAt != null)
              'reviewed${v.reviewer != null ? ' by ${v.reviewer}' : ''}${v.reviewedAt != null ? ' on ${Fmt.date(v.reviewedAt)}' : ''}',
          ].join(', '),
          showRule: false,
        ),
      ],
    );
  }
}

/// Model probability minus base rate on a diverging bar.
class _EdgeRow extends StatelessWidget {
  final double edge;
  const _EdgeRow({required this.edge});

  @override
  Widget build(BuildContext context) {
    final t = context.text;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 11),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Difference from the base rate',
                      style: t.bodyMedium?.copyWith(color: context.pal.inkMuted),
                    ),
                  ),
                  Text(
                    '${Fmt.arrow(edge).isEmpty ? '' : '${Fmt.arrow(edge)} '}${Fmt.points(edge)}',
                    style: t.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: context.pal.signed(edge),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Gap.sm),
              // ±25 points fills the bar.
              DivergingBar(value: (edge / 0.25).clamp(-1.0, 1.0)),
            ],
          ),
        ),
        const Hairline(),
      ],
    );
  }
}

/// A driver score from −1 to 1 sent by the backend (shown only when present).
class _DriverRow extends StatelessWidget {
  final String label;
  final double value;
  const _DriverRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final t = context.text;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 11),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(child: Text(label, style: t.bodyMedium?.copyWith(color: context.pal.inkMuted))),
                  Text(Fmt.number(value, decimals: 2), style: t.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: Gap.sm),
              DivergingBar(value: value.clamp(-1.0, 1.0)),
            ],
          ),
        ),
        const Hairline(),
      ],
    );
  }
}

/// A bar that grows left (negative) or right (positive) from a centre line,
/// with a Negative / Neutral / Positive axis underneath.
class DivergingBar extends StatelessWidget {
  /// From −1 to 1.
  final double value;
  const DivergingBar({super.key, required this.value});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final t = context.text;
    final color = value >= 0 ? p.up : p.down;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder: (context, c) {
            final half = c.maxWidth / 2;
            final w = half * value.abs();
            return SizedBox(
              height: 14,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: p.rule, width: Stroke.hairline),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 2,
                    bottom: 2,
                    left: value >= 0 ? half : half - w,
                    width: w,
                    child: Container(color: color.withValues(alpha: 0.85)),
                  ),
                  Positioned(
                    top: 0,
                    bottom: 0,
                    left: half - 0.5,
                    width: 1,
                    child: Container(color: p.ink),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Negative', style: t.bodySmall?.copyWith(fontSize: 11)),
            Text('Neutral', style: t.bodySmall?.copyWith(fontSize: 11)),
            Text('Positive', style: t.bodySmall?.copyWith(fontSize: 11)),
          ],
        ),
      ],
    );
  }
}

class _NoteSkeleton extends StatelessWidget {
  const _NoteSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Skeleton(
      child: Padding(
        padding: EdgeInsets.only(top: Gap.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SkeletonBox(width: 150, height: 10),
            SizedBox(height: 12),
            SkeletonBox(width: double.infinity, height: 22),
            SizedBox(height: 8),
            SkeletonBox(width: 220, height: 22),
            SizedBox(height: 16),
            SkeletonBox(width: double.infinity, height: 13),
            SizedBox(height: 6),
            SkeletonBox(width: double.infinity, height: 13),
            SizedBox(height: 6),
            SkeletonBox(width: 180, height: 13),
            SizedBox(height: 28),
            HeavyRule(),
            SizedBox(height: 14),
            SkeletonBox(width: 110, height: 18),
            SizedBox(height: 16),
            SkeletonBox(width: double.infinity, height: 16),
            SizedBox(height: 18),
            SkeletonBox(width: double.infinity, height: 16),
            SizedBox(height: 18),
            SkeletonBox(width: double.infinity, height: 16),
            SizedBox(height: 18),
            SkeletonBox(width: double.infinity, height: 16),
          ],
        ),
      ),
    );
  }
}
