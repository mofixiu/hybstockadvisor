import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hybstockadvisor/models/app_notification.dart';
import 'package:hybstockadvisor/models/market_stock.dart';
import 'package:hybstockadvisor/providers/notification_provider.dart';
import 'package:hybstockadvisor/providers/portfolio_provider.dart';
import 'package:hybstockadvisor/theme/format.dart';
import 'package:hybstockadvisor/theme/tokens.dart';
import 'package:hybstockadvisor/widgets/ask_sheet.dart';
import 'package:hybstockadvisor/widgets/bottomNavBar.dart';
import 'package:hybstockadvisor/widgets/sparkline.dart';
import 'package:hybstockadvisor/widgets/stock_logo.dart';
import 'package:hybstockadvisor/widgets/stock_picker_sheet.dart';
import 'package:hybstockadvisor/widgets/ui.dart';
import 'package:provider/provider.dart';

enum _Sort { nameAZ, nameZA, priceHigh, priceLow, gainers, losers }

const _sortLabels = {
  _Sort.nameAZ: 'Symbol, A to Z',
  _Sort.nameZA: 'Symbol, Z to A',
  _Sort.priceHigh: 'Price, high to low',
  _Sort.priceLow: 'Price, low to high',
  _Sort.gainers: 'Day change, best first',
  _Sort.losers: 'Day change, worst first',
};

/// One holding or watchlist row, parsed from `/api/user/{id}/assets`.
class _Row {
  final String symbol;
  final double? quantity;
  final double? avgPrice;
  final double? price;
  final double? changePct;
  final List<double> spark;
  final String currency;
  final DateTime? asOf;
  final String? source;
  final bool stale;

  const _Row({
    required this.symbol,
    this.quantity,
    this.avgPrice,
    this.price,
    this.changePct,
    this.spark = const [],
    this.currency = 'NGN',
    this.asOf,
    this.source,
    this.stale = true,
  });

  factory _Row.from(Map raw) {
    final spark = raw['spark_data'] is List
        ? (raw['spark_data'] as List).whereType<num>().map((e) => e.toDouble()).toList()
        : <double>[];
    double? d(Object? v) => v is num ? v.toDouble() : null;
    return _Row(
      symbol: raw['ticker'].toString(),
      quantity: d(raw['quantity']),
      avgPrice: d(raw['avg_buy_price']),
      price: d(raw['live_price']),
      changePct: d(raw['change_pct']),
      spark: spark,
      currency: raw['currency']?.toString() ?? 'NGN',
      asOf: Fmt.parse(raw['as_of']),
      source: raw['source']?.toString(),
      stale: raw['stale'] == true,
    );
  }

  bool get isHolding => quantity != null && avgPrice != null;

  /// A price that is current enough to value the holding.
  bool get priced => price != null && !stale;

  double? get cost => isHolding ? quantity! * avgPrice! : null;
  double? get value => isHolding && price != null ? quantity! * price! : null;
  double? get gain => value != null && cost != null ? value! - cost! : null;
  double? get gainPct => gain != null && cost != null && cost! > 0 ? gain! / cost! * 100 : null;

  /// Today's change in money for the whole holding.
  double? get dayAmount {
    if (!isHolding || price == null || changePct == null) return null;
    final prev = price! / (1 + changePct! / 100);
    return quantity! * (price! - prev);
  }

  /// Day change shown in tables: hidden when the close is stale.
  double? get dayPct => stale ? null : changePct;
}

class Portfolio extends StatefulWidget {
  const Portfolio({super.key});

  @override
  State<Portfolio> createState() => _PortfolioState();
}

class _PortfolioState extends State<Portfolio> {
  _Sort _holdingSort = _Sort.nameAZ;
  _Sort _watchSort = _Sort.nameAZ;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  Future<void> _load({bool force = false}) async {
    final provider = context.read<PortfolioProvider>();
    if (force && provider.availableMarketStocks.isNotEmpty) {
      await provider.refreshAssets(force: true, showRefreshing: false);
    } else {
      await provider.loadInitial(force: force);
    }
    if (mounted) await _priceAlerts(provider);
  }

  /// A 3% move in a holding raises one alert per stock per day.
  Future<void> _priceAlerts(PortfolioProvider provider) async {
    final box = await Hive.openBox('user');
    if (!mounted || box.get('notif_price_movement', defaultValue: true) != true) return;
    final notifications = context.read<NotificationProvider>();
    for (final raw in provider.portfolioRaw) {
      final row = _Row.from(raw as Map);
      final pct = row.dayPct;
      if (pct == null || pct.abs() < 3) continue;
      await notifications.addNotification(
        title: 'Price move: ${row.symbol}',
        body: '${row.symbol} closed ${Fmt.pct(pct)} at ${Fmt.money(row.price, currency: row.currency)} on ${Fmt.date(row.asOf)}.',
        type: NotificationType.priceMovement,
        ticker: row.symbol,
      );
    }
  }

  List<_Row> _sorted(List<_Row> rows, _Sort sort) {
    final list = List<_Row>.from(rows);
    int byNum(double? a, double? b, {bool desc = true}) {
      if (a == null && b == null) return 0;
      if (a == null) return 1;
      if (b == null) return -1;
      return desc ? b.compareTo(a) : a.compareTo(b);
    }

    switch (sort) {
      case _Sort.nameAZ:
        list.sort((a, b) => a.symbol.compareTo(b.symbol));
      case _Sort.nameZA:
        list.sort((a, b) => b.symbol.compareTo(a.symbol));
      case _Sort.priceHigh:
        list.sort((a, b) => byNum(a.price, b.price));
      case _Sort.priceLow:
        list.sort((a, b) => byNum(a.price, b.price, desc: false));
      case _Sort.gainers:
        list.sort((a, b) => byNum(a.dayPct, b.dayPct));
      case _Sort.losers:
        list.sort((a, b) => byNum(a.dayPct, b.dayPct, desc: false));
    }
    return list;
  }

  Future<void> _chooseSort({required bool holdings}) async {
    final current = holdings ? _holdingSort : _watchSort;
    final picked = await showAppSheet<_Sort>(
      context,
      (ctx) => SheetFrame(
        title: 'Sort ${holdings ? 'holdings' : 'watchlist'}',
        padding: EdgeInsets.zero,
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final s in _Sort.values) ...[
              InkWell(
                onTap: () => Navigator.pop(ctx, s),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: Gap.page, vertical: 14),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _sortLabels[s]!,
                          style: ctx.text.bodyLarge?.copyWith(
                            color: s == current ? ctx.pal.accent : null,
                            fontWeight: s == current ? FontWeight.w600 : null,
                          ),
                        ),
                      ),
                      if (s == current) Icon(Icons.check, color: ctx.pal.accent, size: 20),
                    ],
                  ),
                ),
              ),
              const Hairline(indent: Gap.page),
            ],
          ],
        ),
      ),
    );
    if (picked == null) return;
    setState(() => holdings ? _holdingSort = picked : _watchSort = picked);
  }

  Future<void> _add() async {
    final choice = await showAppSheet<bool>(
      context,
      (ctx) => SheetFrame(
        title: 'Add a stock',
        padding: EdgeInsets.zero,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _choiceRow(ctx, 'To portfolio', 'A stock you own, with quantity and average price', true),
            const Hairline(indent: Gap.page),
            _choiceRow(ctx, 'To watchlist', 'A stock you want to follow', false),
            const SizedBox(height: Gap.md),
          ],
        ),
      ),
    );
    if (choice == null || !mounted) return;
    final provider = context.read<PortfolioProvider>();
    if (provider.availableMarketStocks.isEmpty) {
      showNotice(context, 'The NGX stock list is not loaded yet. Pull down to refresh.');
      return;
    }
    final already = (choice ? provider.portfolioRaw : provider.watchlistRaw)
        .map((e) => e['ticker'].toString())
        .toList();
    final stock = await showStockPicker(
      context,
      stocks: provider.availableMarketStocks,
      disabled: already,
      title: choice ? 'Add to portfolio' : 'Add to watchlist',
    );
    if (stock == null || !mounted) return;
    if (choice) {
      await _addHolding(stock);
    } else {
      final res = await provider.addToWatchlist(ticker: stock.symbol);
      if (!mounted) return;
      showNotice(
        context,
        res['status'] == 'success'
            ? '${stock.symbol} added to your watchlist.'
            : res['detail']?.toString() ?? "Couldn't add ${stock.symbol}.",
      );
    }
  }

  Widget _choiceRow(BuildContext ctx, String title, String body, bool value) => InkWell(
    onTap: () => Navigator.pop(ctx, value),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: Gap.page, vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: ctx.text.titleMedium),
                const SizedBox(height: 2),
                Text(body, style: ctx.text.bodySmall),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: ctx.pal.inkFaint),
        ],
      ),
    ),
  );

  Future<void> _addHolding(MarketStock stock) async {
    final qty = TextEditingController();
    final price = TextEditingController(text: stock.price.toStringAsFixed(2));
    String? error;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text('Add ${stock.symbol}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(stock.name, style: ctx.text.bodySmall),
              const SizedBox(height: Gap.lg),
              TextField(
                controller: qty,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Quantity (shares)'),
              ),
              const SizedBox(height: Gap.md),
              TextField(
                controller: price,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Average buy price (${Fmt.symbol(stock.currency).trim()})',
                  helperText: 'Last close ${Fmt.money(stock.price, currency: stock.currency)} on ${Fmt.date(stock.asOf)}',
                ),
              ),
              if (error != null) ...[
                const SizedBox(height: Gap.sm),
                Text(error!, style: ctx.text.bodySmall?.copyWith(color: ctx.pal.down)),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('Cancel', style: TextStyle(color: ctx.pal.inkMuted)),
            ),
            TextButton(
              onPressed: () {
                final q = double.tryParse(qty.text.trim().replaceAll(',', ''));
                final p = double.tryParse(price.text.trim().replaceAll(',', ''));
                if (q == null || q <= 0 || p == null || p <= 0) {
                  setLocal(() => error = 'Enter a quantity and price above zero.');
                  return;
                }
                Navigator.pop(ctx, true);
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true || !mounted) return;
    final res = await context.read<PortfolioProvider>().addToPortfolio(
      ticker: stock.symbol,
      quantity: double.parse(qty.text.trim().replaceAll(',', '')),
      avgBuyPrice: double.parse(price.text.trim().replaceAll(',', '')),
    );
    if (!mounted) return;
    showNotice(
      context,
      res['status'] == 'success'
          ? '${stock.symbol} added to your portfolio.'
          : res['detail']?.toString() ?? "Couldn't add ${stock.symbol}.",
    );
  }

  Future<bool> _confirmRemove(_Row row, {required bool holding}) => confirmAction(
    context,
    title: 'Remove ${row.symbol}?',
    message: holding
        ? 'This removes ${row.symbol} from your portfolio. It does not sell anything.'
        : 'This removes ${row.symbol} from your watchlist.',
    confirmLabel: 'Remove',
    destructive: true,
  );

  Future<void> _remove(_Row row, {required bool holding}) async {
    final provider = context.read<PortfolioProvider>();
    final res = holding
        ? await provider.removeFromPortfolioOptimistic(ticker: row.symbol)
        : await provider.removeFromWatchlistOptimistic(ticker: row.symbol);
    if (!mounted || res['status'] == 'success') return;
    showNotice(context, res['detail']?.toString() ?? "Couldn't remove ${row.symbol}.");
  }

  void _openHolding(_Row row, String name) {
    showAppSheet<void>(context, (ctx) => _BreakdownSheet(row: row, name: name));
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PortfolioProvider>();
    final holdings = provider.portfolioRaw.map((e) => _Row.from(e as Map)).toList();
    final watch = provider.watchlistRaw.map((e) => _Row.from(e as Map)).toList();
    final loading = provider.isLoading || provider.isRefreshing;
    final scale = Sparkline.commonScale([...holdings, ...watch].map((r) => r.spark));

    return Scaffold(
      bottomNavigationBar: const BottomNavBar(currentIndex: 2),
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: context.pal.accent,
          onRefresh: () => _load(force: true),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: Gap.xxl),
            children: [
              PageTitle(
                'Portfolio',
                actions: [
                  TextButton.icon(
                    onPressed: _add,
                    icon: const Icon(Icons.add, size: 20),
                    label: const Text('Add'),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Gap.page),
                child: provider.hasError
                    ? MessageBlock(
                        title: 'Portfolio not loaded',
                        body: "Couldn't reach the server. Check your connection and try again.",
                        actionLabel: 'Try again',
                        onAction: () => _load(force: true),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const HeavyRule(),
                          if (loading)
                            const _TableSkeleton(summary: true)
                          else ...[
                            _Summary(rows: holdings),
                            SectionHead(
                              'Holdings',
                              trailing: holdings.length > 1
                                  ? TextButton(
                                      onPressed: () => _chooseSort(holdings: true),
                                      child: const Text('Sort'),
                                    )
                                  : null,
                            ),
                            if (holdings.isEmpty)
                              const MessageBlock(
                                title: 'No holdings yet',
                                body: 'Tap Add to record a stock you own. Prices update from verified NGX closes.',
                              )
                            else ...[
                              const _Header(holding: true),
                              for (final r in _sorted(holdings, _holdingSort))
                                _dismissible(
                                  r,
                                  holding: true,
                                  child: _HoldingRow(
                                    row: r,
                                    scale: scale,
                                    onTap: () => _openHolding(r, provider.nameFor(r.symbol)),
                                  ),
                                ),
                            ],
                          ],
                          SectionHead(
                            'Watchlist',
                            trailing: !loading && watch.length > 1
                                ? TextButton(
                                    onPressed: () => _chooseSort(holdings: false),
                                    child: const Text('Sort'),
                                  )
                                : null,
                          ),
                          if (loading)
                            const _TableSkeleton()
                          else if (watch.isEmpty)
                            const MessageBlock(
                              title: 'Nothing on your watchlist',
                              body: 'Tap Add to follow a stock without recording a holding.',
                            )
                          else ...[
                            const _Header(holding: false),
                            for (final r in _sorted(watch, _watchSort))
                              _dismissible(
                                r,
                                holding: false,
                                child: _WatchRow(
                                  row: r,
                                  name: provider.nameFor(r.symbol),
                                  scale: scale,
                                  onAsk: () => showAskSheet(
                                    context,
                                    about: AskContext(
                                      ticker: r.symbol,
                                      price: r.price,
                                      currency: r.currency,
                                      asOf: r.asOf,
                                      stale: r.stale,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                          if (!loading && (holdings.isNotEmpty || watch.isNotEmpty)) ...[
                            const SizedBox(height: Gap.md),
                            Text(
                              'Charts show the last seven closes on one shared scale '
                              '(±${Fmt.number(scale, decimals: 0)}% from each first close), '
                              'so small moves look small. Swipe a row left to remove it.',
                              style: context.text.bodySmall,
                            ),
                          ],
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dismissible(_Row r, {required bool holding, required Widget child}) => Dismissible(
    key: ValueKey('${holding ? 'h' : 'w'}_${r.symbol}'),
    direction: DismissDirection.endToStart,
    confirmDismiss: (_) => _confirmRemove(r, holding: holding),
    onDismissed: (_) => _remove(r, holding: holding),
    background: Container(
      color: context.pal.down,
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: Gap.lg),
      child: Text('Remove', style: context.text.labelLarge?.copyWith(color: context.pal.paper)),
    ),
    child: child,
  );
}

/// Total value, day change and return for holdings with a current close.
class _Summary extends StatelessWidget {
  final List<_Row> rows;
  const _Summary({required this.rows});

  @override
  Widget build(BuildContext context) {
    final t = context.text;
    final p = context.pal;
    final included = rows.where((r) => r.isHolding && r.priced).toList();
    final excluded = rows.where((r) => r.isHolding && !r.priced).toList();
    final value = included.fold<double>(0, (s, r) => s + r.value!);
    final cost = included.fold<double>(0, (s, r) => s + r.cost!);
    final day = included.fold<double>(0, (s, r) => s + (r.dayAmount ?? 0));
    final prevValue = value - day;
    final dayPct = prevValue > 0 ? day / prevValue * 100 : null;
    final gain = value - cost;
    final gainPct = cost > 0 ? gain / cost * 100 : null;
    final latest = included
        .map((r) => r.asOf)
        .whereType<DateTime>()
        .fold<DateTime?>(null, (a, b) => a == null || b.isAfter(a) ? b : a);
    final currency = included.isNotEmpty ? included.first.currency : 'NGN';

    if (rows.isEmpty) return const SizedBox(height: Gap.sm);

    return Padding(
      padding: const EdgeInsets.only(top: Gap.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Kicker('Total value'),
          const SizedBox(height: 6),
          Text(
            included.isEmpty ? Fmt.missing : Fmt.money(value, currency: currency),
            style: AppType.figure(size: 34, color: p.ink),
          ),
          const SizedBox(height: Gap.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _stat(context, 'Day change', day, dayPct, currency, included.isEmpty)),
              const SizedBox(width: Gap.md),
              Expanded(child: _stat(context, 'Total return', gain, gainPct, currency, included.isEmpty)),
            ],
          ),
          const SizedBox(height: Gap.md),
          Text(
            [
              'Cost ${included.isEmpty ? Fmt.missing : Fmt.money(cost, currency: currency)}',
              '${included.length} of ${rows.length} holdings priced',
              if (latest != null) 'closes as of ${Fmt.date(latest)}',
            ].join(' · '),
            style: t.bodySmall,
          ),
          if (excluded.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: 'Not counted: ',
                    style: TextStyle(color: p.warn, fontWeight: FontWeight.w600),
                  ),
                  TextSpan(
                    text: '${excluded.map((r) => r.symbol).join(', ')} '
                        '(${excluded.any((r) => r.price == null) ? 'no verified close' : 'stale close'}).',
                  ),
                ],
              ),
              style: t.bodySmall,
            ),
          ],
        ],
      ),
    );
  }

  Widget _stat(BuildContext context, String label, double amount, double? pct, String currency, bool empty) {
    final t = context.text;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Kicker(label),
        const SizedBox(height: 4),
        if (empty)
          Text(Fmt.missing, style: t.titleMedium)
        else ...[
          ChangeText(pct: null, amount: amount, currency: currency, style: t.titleMedium),
          ChangeText(pct: pct, arrow: false, style: t.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
        ],
      ],
    );
  }
}

/// Column heads for the dense tables.
class _Header extends StatelessWidget {
  final bool holding;
  const _Header({required this.holding});

  /// Column head: one line, or two stacked to mirror two-line rows.
  Widget _head(String top, [String? bottom]) => Column(
    crossAxisAlignment: CrossAxisAlignment.end,
    mainAxisSize: MainAxisSize.min,
    children: [Kicker(top), if (bottom != null) Kicker(bottom)],
  );

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Padding(
        padding: const EdgeInsets.only(top: 2, bottom: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(child: Kicker(holding ? 'Holding' : 'Stock')),
            const SizedBox(width: 64, child: Kicker('7 days')),
            SizedBox(
              width: 92,
              child: Align(
                alignment: Alignment.centerRight,
                child: holding ? _head('Last', 'Value') : _head('Last'),
              ),
            ),
            SizedBox(
              width: 72,
              child: Align(
                alignment: Alignment.centerRight,
                child: holding ? _head('Day', 'Return') : _head('Day'),
              ),
            ),
          ],
        ),
      ),
      const Hairline(),
    ],
  );
}

class _HoldingRow extends StatelessWidget {
  final _Row row;
  final double scale;
  final VoidCallback onTap;
  const _HoldingRow({required this.row, required this.scale, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = context.text;
    final p = context.pal;
    final small = t.bodySmall!;
    final figure = t.bodyMedium!.copyWith(fontWeight: FontWeight.w500);
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 9),
            child: Row(
              children: [
                StockLogo(symbol: row.symbol, size: 28),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(row.symbol, style: t.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                      Text(
                        '${Fmt.quantity(row.quantity)} @ ${Fmt.money(row.avgPrice, currency: row.currency)}',
                        style: small,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 64,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Sparkline(values: row.spark, scalePct: scale),
                  ),
                ),
                SizedBox(
                  width: 92,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        Fmt.money(row.price, currency: row.currency),
                        style: figure.copyWith(color: row.stale ? p.inkFaint : null),
                        maxLines: 1,
                      ),
                      Text(Fmt.compactMoney(row.value, currency: row.currency), style: small, maxLines: 1),
                    ],
                  ),
                ),
                SizedBox(
                  width: 72,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      row.stale
                          ? const StaleTag()
                          : ChangeText(pct: row.dayPct, arrow: false, style: figure),
                      ChangeText(pct: row.gainPct, arrow: false, style: small),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Hairline(),
        ],
      ),
    );
  }
}

class _WatchRow extends StatelessWidget {
  final _Row row;
  final String name;
  final double scale;
  final VoidCallback onAsk;
  const _WatchRow({required this.row, required this.name, required this.scale, required this.onAsk});

  @override
  Widget build(BuildContext context) {
    final t = context.text;
    final p = context.pal;
    final figure = t.bodyMedium!.copyWith(fontWeight: FontWeight.w500);
    return InkWell(
      onTap: onAsk,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 9),
            child: Row(
              children: [
                StockLogo(symbol: row.symbol, size: 28),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(row.symbol, style: t.titleSmall),
                      Text(name, style: t.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                SizedBox(
                  width: 64,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Sparkline(values: row.spark, scalePct: scale),
                  ),
                ),
                SizedBox(
                  width: 92,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        Fmt.money(row.price, currency: row.currency),
                        style: figure.copyWith(color: row.stale ? p.inkFaint : null),
                      ),
                      if (row.stale) Text(Fmt.date(row.asOf), style: t.bodySmall),
                    ],
                  ),
                ),
                SizedBox(
                  width: 72,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: row.stale
                        ? const StaleTag()
                        : ChangeText(pct: row.dayPct, arrow: false, style: figure),
                  ),
                ),
              ],
            ),
          ),
          const Hairline(),
        ],
      ),
    );
  }
}

/// The label/value breakdown for one holding.
class _BreakdownSheet extends StatelessWidget {
  final _Row row;
  final String name;
  const _BreakdownSheet({required this.row, required this.name});

  @override
  Widget build(BuildContext context) {
    final t = context.text;
    final p = context.pal;
    return SheetFrame(
      title: row.symbol,
      subtitle: Text(name, style: t.bodySmall),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: Gap.lg),
            Kicker(row.stale ? 'Value at last close · stale' : 'Value at last close',
                color: row.stale ? p.warn : null),
            const SizedBox(height: 6),
            Text(
              row.value == null ? 'Not available' : Fmt.money(row.value, currency: row.currency),
              style: AppType.figure(size: 32, color: p.ink),
            ),
            const SizedBox(height: 6),
            if (row.gain != null)
              Row(
                children: [
                  ChangeText(pct: row.gainPct, amount: row.gain, currency: row.currency, style: t.titleMedium),
                  const SizedBox(width: 6),
                  Text('since purchase', style: t.bodySmall),
                ],
              )
            else
              Text('Profit and loss need a verified close.', style: t.bodySmall),
            const SizedBox(height: Gap.lg),
            const Hairline(),
            LabelValueRow('Quantity', value: '${Fmt.quantity(row.quantity)} shares'),
            LabelValueRow('Average buy price', value: Fmt.money(row.avgPrice, currency: row.currency)),
            LabelValueRow('Cost', value: Fmt.money(row.cost, currency: row.currency)),
            LabelValueRow('Last close', value: Fmt.money(row.price, currency: row.currency), strong: true),
            LabelValueRow(
              'Day change',
              valueWidget: row.stale
                  ? const StaleTag()
                  : ChangeText(pct: row.dayPct, amount: row.dayAmount, currency: row.currency),
            ),
            LabelValueRow(
              'Value',
              value: Fmt.money(row.value, currency: row.currency),
              showRule: false,
            ),
            const SizedBox(height: Gap.sm),
            FreshnessLine(asOf: row.asOf, source: row.source, stale: row.stale),
            const SizedBox(height: Gap.xl),
            QuietButton(
              'Ask about ${row.symbol}',
              onPressed: () {
                Navigator.pop(context);
                showAskSheet(
                  context,
                  about: AskContext(
                    ticker: row.symbol,
                    price: row.price,
                    currency: row.currency,
                    asOf: row.asOf,
                    stale: row.stale,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _TableSkeleton extends StatelessWidget {
  final bool summary;
  const _TableSkeleton({this.summary = false});

  @override
  Widget build(BuildContext context) {
    return Skeleton(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (summary) ...[
            const SizedBox(height: Gap.lg),
            const SkeletonBox(width: 80, height: 10),
            const SizedBox(height: 10),
            const SkeletonBox(width: 220, height: 32),
            const SizedBox(height: 14),
            const Row(
              children: [
                Expanded(child: SkeletonBox(height: 30)),
                SizedBox(width: Gap.md),
                Expanded(child: SkeletonBox(height: 30)),
              ],
            ),
            const SizedBox(height: Gap.xl),
            const HeavyRule(),
            const SizedBox(height: Gap.md),
          ],
          for (var i = 0; i < 4; i++) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Row(
                children: [
                  SkeletonBox(width: 28, height: 28, radius: Radii.sm),
                  SizedBox(width: 10),
                  Expanded(child: SkeletonBox(height: 26)),
                  SizedBox(width: 12),
                  SkeletonBox(width: 56, height: 22),
                  SizedBox(width: 12),
                  SkeletonBox(width: 70, height: 26),
                ],
              ),
            ),
            const Hairline(),
          ],
        ],
      ),
    );
  }
}
