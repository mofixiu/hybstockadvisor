import 'package:flutter/widgets.dart';
import 'package:hive/hive.dart';
import 'package:hybstockadvisor/models/app_notification.dart';
import 'package:hybstockadvisor/models/market_stock.dart';
import 'package:hybstockadvisor/providers/market_data_provider.dart';
import 'package:hybstockadvisor/providers/notification_provider.dart';
import 'package:hybstockadvisor/services/api_service.dart';
import 'package:hybstockadvisor/theme/format.dart';
import 'package:provider/provider.dart';

/// Builds the in-app notifications for a session: a Friday weekly summary,
/// reviewed research signals for holdings, and price moves of 3% or more.
/// Stale closes never produce an alert. At most seven per session.
class NotificationFeed {
  NotificationFeed._();

  static const int _maxPerSession = 7;

  static Future<void> fire(BuildContext context, List<MarketStock> market) async {
    final provider = context.read<NotificationProvider>();
    final marketData = context.read<MarketDataProvider>();
    final box = await Hive.openBox('user');

    final notifForecast = box.get('notif_ai_forecast', defaultValue: true) == true;
    final notifPrice = box.get('notif_price_movement', defaultValue: true) == true;
    final notifWeekly = box.get('notif_weekly_summary', defaultValue: true) == true;

    // (priority, title, body, type, ticker). Lower priority fires first.
    final candidates = <(int, String, String, NotificationType, String?)>[];

    final data = await ApiService.getUserAssets();
    final portfolio = data?['portfolio'] as List? ?? const [];

    if (notifWeekly && DateTime.now().weekday == DateTime.friday && data != null) {
      candidates.add(_weekly(portfolio, market));
    }

    final tickers = portfolio.map((e) => e['ticker'] as String).toList();
    if (tickers.isNotEmpty && (notifForecast || notifPrice)) {
      // Keep requests bounded: the hosted backend has a small connection pool.
      final forecasts = <Map<String, dynamic>?>[];
      for (var start = 0; start < tickers.length; start += 3) {
        forecasts.addAll(
          await Future.wait(
            tickers.skip(start).take(3).map(marketData.getStockForecast),
          ),
        );
      }

      for (var i = 0; i < tickers.length; i++) {
        final ticker = tickers[i];
        final response = forecasts[i];
        if (response == null || response['status'] != 'success') continue;
        final history = response['data'] is List ? response['data'] as List : const [];
        if (history.isEmpty) continue;
        final meta = response['meta'] is Map ? response['meta'] as Map : const {};
        final signal = response['signal'] is Map ? response['signal'] as Map : const {};
        final stale = meta['stale'] == true;

        if (notifForecast && signal['available'] == true && !stale) {
          final direction = signal['direction']?.toString() ?? 'directional';
          final horizon = signal['horizon'] is Map
              ? (signal['horizon'] as Map)['primary'] ?? 10
              : 10;
          final positive = direction == 'positive';
          candidates.add((
            positive ? 2 : 3,
            positive ? 'Positive research signal: $ticker' : 'Research update: $ticker',
            '$ticker has a reviewed $direction signal for $horizon trading days.',
            NotificationType.aiForecast,
            ticker,
          ));
        }

        if (notifPrice && history.length >= 2 && !stale) {
          final today = history.last['close'];
          final before = history[history.length - 2]['close'];
          if (today is! num || before is! num || before == 0) continue;
          final pct = (today - before) / before * 100;
          if (pct.abs() >= 3.0) {
            candidates.add((
              4,
              'Price move: $ticker',
              '$ticker closed ${Fmt.pct(pct)} at ${Fmt.money(today)} on ${Fmt.date(history.last['date'])}.',
              NotificationType.priceMovement,
              ticker,
            ));
          }
        }
      }
    }

    candidates.sort((a, b) => a.$1.compareTo(b.$1));
    for (final (_, title, body, type, ticker) in candidates.take(_maxPerSession)) {
      await provider.addNotification(title: title, body: body, type: type, ticker: ticker);
    }
  }

  static (int, String, String, NotificationType, String?) _weekly(
    List portfolio,
    List<MarketStock> market,
  ) {
    final priced = portfolio
        .where((item) => item['change_pct'] is num && item['stale'] != true)
        .toList();

    String summary;
    if (portfolio.isEmpty) {
      summary = 'Your portfolio is empty. Add holdings to get a weekly recap.';
    } else if (priced.isEmpty) {
      summary = 'Current closing prices are not available for your holdings.';
    } else {
      var total = 0.0;
      String? topUp;
      String? topDown;
      var best = double.negativeInfinity;
      var worst = double.infinity;
      for (final item in priced) {
        final ticker = item['ticker'] as String;
        final change = (item['change_pct'] as num).toDouble();
        total += change;
        if (change > best) {
          best = change;
          topUp = ticker;
        }
        if (change < worst) {
          worst = change;
          topDown = ticker;
        }
      }
      summary = 'Average daily change across your holdings: ${Fmt.pct(total / priced.length)}.';
      if (topUp != null) summary += ' Best: $topUp ${Fmt.pct(best)}.';
      if (topDown != null && topDown != topUp) summary += ' Worst: $topDown ${Fmt.pct(worst)}.';
    }

    MarketStock? mover;
    for (final s in market) {
      if (s.stale || s.changePct == null) continue;
      if (mover == null || s.changePct! > mover.changePct!) mover = s;
    }
    if (mover != null) {
      summary += ' Biggest NGX gain today: ${mover.symbol} ${Fmt.pct(mover.changePct)}.';
    }
    return (0, 'Weekly summary', summary, NotificationType.weeklySummary, 'weekly');
  }
}
