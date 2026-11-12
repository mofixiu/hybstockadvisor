import 'package:hybstockadvisor/theme/format.dart';

/// One row of the NGX market summary (`GET /api/summary`).
class MarketStock {
  final String symbol;
  final String name;

  /// Market capitalisation in [currency], when the source provides it.
  final double? marketCap;
  final double price;

  /// Change from the previous close, in percent. Null when unknown.
  final double? changePct;
  final String currency;

  /// When the source produced this price.
  final DateTime? asOf;
  final String? source;

  /// The backend marks a close older than four days as stale.
  final bool stale;

  const MarketStock({
    required this.symbol,
    required this.name,
    required this.price,
    this.marketCap,
    this.changePct,
    this.currency = 'NGN',
    this.asOf,
    this.source,
    this.stale = false,
  });

  factory MarketStock.fromSummary(Map<String, dynamic> item) {
    final symbol = item['symbol'].toString();
    final rawName = item['name']?.toString().trim();
    final change = item['change_pct'];
    return MarketStock(
      symbol: symbol,
      name: rawName == null || rawName.isEmpty ? symbol : rawName,
      marketCap: Fmt.parseCompact(item['market_cap']),
      price: (item['price'] as num).toDouble(),
      changePct: change is num ? change.toDouble() : null,
      currency: item['currency']?.toString() ?? 'NGN',
      asOf: Fmt.parse(item['as_of']),
      source: item['source']?.toString(),
      stale: item['stale'] == true,
    );
  }

  /// Parses the `data` list of a market summary response.
  static List<MarketStock> listFromSummary(Map<String, dynamic>? response) {
    if (response == null || response['status'] != 'success') return const [];
    final raw = response['data'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((e) => MarketStock.fromSummary(Map<String, dynamic>.from(e)))
        .toList();
  }

  MarketStock copyWith({double? price, double? changePct, DateTime? asOf, bool? stale}) =>
      MarketStock(
        symbol: symbol,
        name: name,
        marketCap: marketCap,
        price: price ?? this.price,
        changePct: changePct ?? this.changePct,
        currency: currency,
        asOf: asOf ?? this.asOf,
        source: source,
        stale: stale ?? this.stale,
      );
}

/// One daily bar from `GET /api/forecast/{ticker}`.
class DailyBar {
  final DateTime date;
  final double close;
  final double? high;
  final double? low;

  const DailyBar({required this.date, required this.close, this.high, this.low});

  static List<DailyBar> listFrom(Object? raw) {
    if (raw is! List) return const [];
    final out = <DailyBar>[];
    for (final item in raw) {
      if (item is! Map) continue;
      final d = DateTime.tryParse(item['date']?.toString() ?? '');
      final c = item['close'];
      if (d == null || c is! num) continue;
      out.add(DailyBar(
        date: d,
        close: c.toDouble(),
        high: (item['high'] as num?)?.toDouble(),
        low: (item['low'] as num?)?.toDouble(),
      ));
    }
    return out;
  }
}

/// What the assistant sheet shows about the stock it was opened from, so its
/// price and date match the screen the user came from.
class AskContext {
  final String ticker;
  final double? price;
  final String currency;
  final Object? asOf;
  final bool stale;

  const AskContext({
    required this.ticker,
    this.price,
    this.currency = 'NGN',
    this.asOf,
    this.stale = false,
  });
}
