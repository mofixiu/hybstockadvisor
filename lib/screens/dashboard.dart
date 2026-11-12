import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hybstockadvisor/models/market_stock.dart';
import 'package:hybstockadvisor/models/research_signal.dart';
import 'package:hybstockadvisor/providers/market_data_provider.dart';
import 'package:hybstockadvisor/providers/notification_provider.dart';
import 'package:hybstockadvisor/screens/ai_insights.dart';
import 'package:hybstockadvisor/screens/notification_center.dart';
import 'package:hybstockadvisor/services/api_service.dart';
import 'package:hybstockadvisor/services/notification_feed.dart';
import 'package:hybstockadvisor/theme/format.dart';
import 'package:hybstockadvisor/theme/tokens.dart';
import 'package:hybstockadvisor/widgets/ask_sheet.dart';
import 'package:hybstockadvisor/widgets/bottomNavBar.dart';
import 'package:hybstockadvisor/widgets/custom_page_route.dart';
import 'package:hybstockadvisor/widgets/price_chart.dart';
import 'package:hybstockadvisor/widgets/stock_logo.dart';
import 'package:hybstockadvisor/widgets/stock_picker_sheet.dart';
import 'package:hybstockadvisor/widgets/ui.dart';
import 'package:provider/provider.dart';

/// Home: the selected NGX stock's last close, its research signal, and one
/// chart of daily closes.
class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

enum _Range { m1, m3, m6 }

class _DashboardState extends State<Dashboard> {
  List<MarketStock> _market = [];
  MarketStock? _stock;
  DateTime? _marketAsOf;

  bool _loadingMarket = true;
  bool _loadingStock = true;
  String? _error;

  List<DailyBar> _bars = [];
  ResearchSignal _signal = ResearchSignal.unavailable;
  Map<String, dynamic> _meta = {};
  _Range _range = _Range.m3;
  String _firstName = '';
  bool _notificationsFired = false;

  @override
  void initState() {
    super.initState();
    _loadName();
    _loadMarket();
  }

  Future<void> _loadName() async {
    final box = await Hive.openBox('user');
    final name = box.get('first_name');
    if (name is String && mounted) setState(() => _firstName = name);
  }

  Future<void> _loadMarket({bool force = false}) async {
    setState(() {
      _loadingMarket = true;
      _error = null;
    });
    final res = await context.read<MarketDataProvider>().getMarketSummary(force: force);
    if (!mounted) return;
    final list = MarketStock.listFromSummary(res);
    final meta = res?['meta'] is Map ? res!['meta'] as Map : const {};
    if (list.isEmpty) {
      setState(() {
        _market = [];
        _stock = null;
        _loadingMarket = false;
        _loadingStock = false;
        _error = res == null
            ? "Couldn't reach the server. Check your connection and try again."
            : meta['reason'] == 'market_data_not_enabled_for_this_account'
            ? 'Verified NGX data is not enabled for this account yet.'
            : 'No verified NGX closing data is available right now.';
      });
      return;
    }
    final selected = list.firstWhere(
      (s) => s.symbol == ApiService.currentTicker,
      orElse: () => list.first,
    );
    setState(() {
      _market = list;
      _marketAsOf = Fmt.parse(meta['as_of']);
      _stock = selected;
      _loadingMarket = false;
    });
    await _loadStock(selected.symbol, force: force);
    if (!_notificationsFired && mounted) {
      _notificationsFired = true;
      NotificationFeed.fire(context, _market);
    }
  }

  Future<void> _loadStock(String ticker, {bool force = false}) async {
    ApiService.currentTicker = ticker;
    setState(() {
      _loadingStock = true;
      _error = null;
    });
    final res = await context.read<MarketDataProvider>().getStockForecast(ticker, force: force);
    if (!mounted || ApiService.currentTicker != ticker) return;
    if (res == null || res['status'] != 'success') {
      setState(() {
        _loadingStock = false;
        _error = "Couldn't load $ticker. Check your connection and try again.";
      });
      return;
    }
    final meta = res['meta'] is Map ? Map<String, dynamic>.from(res['meta'] as Map) : <String, dynamic>{};
    final bars = DailyBar.listFrom(res['data']);
    final stale = meta['stale'] == true;
    setState(() {
      _meta = meta;
      _bars = bars;
      _signal = ResearchSignal.fromJson(res['signal'], dataStale: stale);
      _loadingStock = false;
      if (bars.isNotEmpty && _stock != null) {
        final last = bars.last.close;
        final prev = bars.length > 1 ? bars[bars.length - 2].close : null;
        _stock = _stock!.copyWith(
          price: last,
          changePct: prev == null || prev == 0 ? null : (last - prev) / prev * 100,
          stale: stale,
        );
      }
    });
  }

  Future<void> _pickStock() async {
    final picked = await showStockPicker(
      context,
      stocks: _market,
      selected: _stock?.symbol,
    );
    if (picked == null || !mounted) return;
    setState(() => _stock = picked);
    _loadStock(picked.symbol);
  }

  void _ask() {
    final s = _stock;
    if (s == null) return;
    showAskSheet(
      context,
      about: AskContext(
        ticker: s.symbol,
        price: _bars.isNotEmpty ? _bars.last.close : s.price,
        currency: s.currency,
        asOf: _bars.isNotEmpty ? _bars.last.date : s.asOf,
        stale: s.stale,
      ),
    );
  }

  String _greeting() {
    final h = DateTime.now().hour;
    final part = h < 12 ? 'Good morning' : (h < 17 ? 'Good afternoon' : 'Good evening');
    return _firstName.isEmpty ? part : '$part, $_firstName';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: const BottomNavBar(currentIndex: 0),
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: context.pal.accent,
          onRefresh: () => _loadMarket(force: true),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: Gap.xxl),
            children: [
              _masthead(context),
              if (_loadingMarket)
                const _HomeSkeleton()
              else if (_stock == null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: Gap.page),
                  child: MessageBlock(
                    title: 'No market data',
                    body: _error,
                    actionLabel: 'Try again',
                    onAction: () => _loadMarket(force: true),
                  ),
                )
              else ...[
                _stockRow(context, _stock!),
                if (_loadingStock)
                  const _HomeSkeleton(showStockRow: false)
                else if (_error != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: Gap.page),
                    child: MessageBlock(
                      title: 'Not loaded',
                      body: _error,
                      actionLabel: 'Try again',
                      onAction: () => _loadStock(_stock!.symbol, force: true),
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: Gap.page),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _priceBlock(context, _stock!),
                        _signalBlock(context, _stock!),
                        _chartBlock(context, _stock!),
                        _recentCloses(context, _stock!),
                        const SizedBox(height: Gap.xl),
                        QuietButton('Ask about ${_stock!.symbol}', onPressed: _ask),
                      ],
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _masthead(BuildContext context) {
    final p = context.pal;
    final t = context.text;
    return Padding(
      padding: const EdgeInsets.fromLTRB(Gap.page, Gap.md, Gap.sm, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'HybStockAdvisor',
                  style: AppType.serif(size: 24, weight: FontWeight.w700, color: p.ink),
                ),
              ),
              Consumer<NotificationProvider>(
                builder: (context, n, _) {
                  final count = n.unreadCount;
                  return IconButton(
                    tooltip: count > 0 ? 'Notifications, $count unread' : 'Notifications',
                    onPressed: () => context.pushFade(const NotificationCenter()),
                    icon: Badge(
                      isLabelVisible: count > 0,
                      backgroundColor: p.accentFill,
                      textColor: p.onAccentFill,
                      label: Text(count > 99 ? '99+' : '$count'),
                      child: Icon(Icons.notifications_none, color: p.ink, size: 24),
                    ),
                  );
                },
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(right: Gap.md, bottom: Gap.sm),
            child: Text(
              '${Fmt.dateline(DateTime.now())} · ${_greeting()}',
              style: t.bodySmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: Gap.md),
            child: const HeavyRule(),
          ),
        ],
      ),
    );
  }

  /// The selected stock, with an honest "Change" control (it opens a list).
  Widget _stockRow(BuildContext context, MarketStock s) {
    final t = context.text;
    final p = context.pal;
    return Column(
      children: [
        InkWell(
          onTap: _pickStock,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(Gap.page, Gap.md, Gap.md, Gap.md),
            child: Row(
              children: [
                StockLogo(symbol: s.symbol, size: 40),
                const SizedBox(width: Gap.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s.symbol, style: t.titleMedium),
                      Text(
                        s.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: t.bodySmall,
                      ),
                    ],
                  ),
                ),
                Text('Change', style: t.labelLarge?.copyWith(color: p.accent)),
                Icon(Icons.expand_more, color: p.accent, size: 20),
              ],
            ),
          ),
        ),
        const Hairline(indent: Gap.page, endIndent: Gap.page),
      ],
    );
  }

  Widget _priceBlock(BuildContext context, MarketStock s) {
    final t = context.text;
    final last = _bars.isNotEmpty ? _bars.last : null;
    final prev = _bars.length > 1 ? _bars[_bars.length - 2] : null;
    final amount = last != null && prev != null ? last.close - prev.close : null;
    return Padding(
      padding: const EdgeInsets.only(top: Gap.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Kicker(s.stale ? 'Last close · stale' : 'Last close', color: s.stale ? context.pal.warn : null),
          const SizedBox(height: 6),
          Text(
            Fmt.money(last?.close ?? s.price, currency: s.currency),
            style: AppType.figure(size: 36, color: context.pal.ink),
          ),
          const SizedBox(height: 6),
          ChangeText(
            pct: s.changePct,
            amount: amount,
            currency: s.currency,
            style: t.titleMedium,
          ),
          const SizedBox(height: 4),
          Text('Change from the previous close', style: t.bodySmall),
          const SizedBox(height: Gap.sm),
          FreshnessLine(
            tradeDate: last?.date,
            asOf: _meta['as_of'],
            source: _meta['source']?.toString() ?? s.source,
            stale: s.stale,
          ),
          if (s.marketCap != null) ...[
            const SizedBox(height: 2),
            Text(
              'Market cap ${Fmt.compactMoney(s.marketCap, currency: s.currency)}',
              style: t.bodySmall,
            ),
          ],
        ],
      ),
    );
  }

  Widget _signalBlock(BuildContext context, MarketStock s) {
    final t = context.text;
    final p = context.pal;
    final sig = _signal;
    final List<Widget> body;
    if (sig.available && sig.direction != null) {
      final color = sig.isPositive ? p.up : p.down;
      body = [
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: '${sig.isPositive ? Fmt.up : Fmt.down} ${sig.isPositive ? 'Positive' : 'Negative'}',
                style: TextStyle(color: color),
              ),
              TextSpan(
                text: ' over ${sig.horizon} trading days',
                style: TextStyle(color: p.ink, fontWeight: FontWeight.w400),
              ),
            ],
          ),
          style: t.titleLarge,
        ),
        const SizedBox(height: 6),
        Text(
          _probabilitySentence(sig),
          style: t.bodyMedium?.copyWith(color: p.inkMuted),
        ),
      ];
    } else if (sig.status == 'stale_data' || s.stale) {
      body = [
        Text('No signal: the data is stale', style: t.titleLarge),
        const SizedBox(height: 6),
        Text(
          'The last verified close is from ${Fmt.date(_bars.isNotEmpty ? _bars.last.date : s.asOf)}. '
          'Signals stay hidden until newer closes arrive.',
          style: t.bodyMedium?.copyWith(color: p.inkMuted),
        ),
      ];
    } else {
      body = [
        Text('No reviewed signal', style: t.titleLarge),
        const SizedBox(height: 6),
        Text(
          'Verified closes are available, but no model signal for ${s.symbol} has passed review. '
          'This page shows market context only.',
          style: t.bodyMedium?.copyWith(color: p.inkMuted),
        ),
      ];
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHead(
          'Research signal',
          trailing: LinkText(
            'Read the note',
            onTap: () => context.pushFade(const AiInsights()),
          ),
        ),
        ...body,
      ],
    );
  }

  static String _probabilitySentence(ResearchSignal sig) {
    final p = sig.probability;
    if (p == null) return 'Probability not reported.';
    final base = sig.baseRate;
    final chance = '${Fmt.probability(p)} chance of a positive ${sig.horizon}-day return';
    return base == null
        ? '$chance. Base rate not reported.'
        : '$chance, against a base rate of ${Fmt.probability(base)}.';
  }

  List<DailyBar> get _windowBars {
    final n = switch (_range) {
      _Range.m1 => 22,
      _Range.m3 => 66,
      _Range.m6 => 130,
    };
    return _bars.length <= n ? _bars : _bars.sublist(_bars.length - n);
  }

  Widget _chartBlock(BuildContext context, MarketStock s) {
    final t = context.text;
    final bars = _windowBars;
    final first = bars.isNotEmpty ? bars.first.close : null;
    final last = bars.isNotEmpty ? bars.last.close : null;
    final move = first != null && last != null && first != 0 ? (last - first) / first * 100 : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHead(
          'Daily closes',
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final r in _Range.values)
                _RangeButton(
                  label: switch (r) {
                    _Range.m1 => '1M',
                    _Range.m3 => '3M',
                    _Range.m6 => '6M',
                  },
                  selected: r == _range,
                  onTap: () => setState(() => _range = r),
                ),
            ],
          ),
        ),
        if (bars.length >= 2) ...[
          Text.rich(
            TextSpan(
              children: [
                TextSpan(text: '${bars.length} sessions, ${Fmt.date(bars.first.date)} to ${Fmt.date(bars.last.date)}: '),
                WidgetSpan(
                  alignment: PlaceholderAlignment.baseline,
                  baseline: TextBaseline.alphabetic,
                  child: ChangeText(pct: move, style: t.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            style: t.bodySmall,
          ),
          const SizedBox(height: Gap.lg),
        ],
        PriceChart(bars: bars, currency: s.currency, height: 210),
      ],
    );
  }

  Widget _recentCloses(BuildContext context, MarketStock s) {
    final t = context.text;
    final n = _bars.length;
    final rows = <Widget>[];
    for (var i = n - 1; i >= (n > 5 ? n - 5 : 0); i--) {
      final b = _bars[i];
      final prev = i > 0 ? _bars[i - 1].close : null;
      final pct = prev == null || prev == 0 ? null : (b.close - prev) / prev * 100;
      rows.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 9),
          child: Row(
            children: [
              Expanded(flex: 5, child: Text(Fmt.dateWeekday(b.date), style: t.bodyMedium)),
              Expanded(
                flex: 4,
                child: Text(
                  Fmt.money(b.close, currency: s.currency),
                  textAlign: TextAlign.right,
                  style: t.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                ),
              ),
              Expanded(
                flex: 4,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: ChangeText(pct: pct, style: t.bodyMedium),
                ),
              ),
            ],
          ),
        ),
      );
      rows.add(const Hairline());
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHead('Recent closes'),
        Row(
          children: [
            Expanded(flex: 5, child: Kicker('Session')),
            Expanded(flex: 4, child: Align(alignment: Alignment.centerRight, child: Kicker('Close'))),
            Expanded(flex: 4, child: Align(alignment: Alignment.centerRight, child: Kicker('Change'))),
          ],
        ),
        const SizedBox(height: 4),
        const Hairline(),
        ...rows,
        if (_marketAsOf != null) ...[
          const SizedBox(height: Gap.sm),
          Text(
            'NGX market list updated ${Fmt.date(_marketAsOf)}, ${Fmt.timeWat(_marketAsOf)}.',
            style: t.bodySmall,
          ),
        ],
      ],
    );
  }
}

class _RangeButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _RangeButton({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Semantics(
      selected: selected,
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Radii.xs),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: selected ? p.accent : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Text(
            label,
            style: context.text.labelMedium?.copyWith(
              color: selected ? p.accent : p.inkFaint,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

/// Placeholder while the market list and the stock load.
class _HomeSkeleton extends StatelessWidget {
  final bool showStockRow;
  const _HomeSkeleton({this.showStockRow = true});

  @override
  Widget build(BuildContext context) {
    return Skeleton(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Gap.page, vertical: Gap.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showStockRow) ...[
              const Row(
                children: [
                  SkeletonBox(width: 40, height: 40, radius: Radii.sm),
                  SizedBox(width: Gap.md),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SkeletonBox(width: 70, height: 14),
                      SizedBox(height: 6),
                      SkeletonBox(width: 180, height: 11),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: Gap.lg),
              const Hairline(),
            ],
            const SizedBox(height: Gap.lg),
            const SkeletonBox(width: 80, height: 10),
            const SizedBox(height: 10),
            const SkeletonBox(width: 190, height: 34),
            const SizedBox(height: 10),
            const SkeletonBox(width: 150, height: 14),
            const SizedBox(height: Gap.xl),
            const HeavyRule(),
            const SizedBox(height: Gap.md),
            const SkeletonBox(width: 160, height: 18),
            const SizedBox(height: 10),
            const SkeletonBox(width: double.infinity, height: 12),
            const SizedBox(height: 6),
            const SkeletonBox(width: 240, height: 12),
            const SizedBox(height: Gap.xl),
            const HeavyRule(),
            const SizedBox(height: Gap.md),
            const SkeletonBox(width: double.infinity, height: 200),
          ],
        ),
      ),
    );
  }
}
