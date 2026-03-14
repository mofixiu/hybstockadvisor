import 'package:flutter/foundation.dart';
import 'package:hybstockadvisor/services/api_service.dart';

class MarketDataProvider extends ChangeNotifier {
  static const Duration ttl = Duration(minutes: 15);

  final Map<String, Map<String, dynamic>?> _cache = {};
  final Map<String, DateTime> _cacheTime = {};
  final Map<String, Future<Map<String, dynamic>?>> _inFlight = {};

  Future<Map<String, dynamic>?> _fetchWithCache(
    String key,
    Future<Map<String, dynamic>?> Function() fetcher, {
    bool force = false,
  }) async {
    final active = _inFlight[key];
    if (active != null) return active;

    if (!force) {
      final last = _cacheTime[key];
      final hasCached = _cache.containsKey(key);
      if (last != null && hasCached && DateTime.now().difference(last) < ttl) {
        return _cache[key];
      }
    }

    final future = () async {
      final result = await fetcher();
      _cache[key] = result;
      _cacheTime[key] = DateTime.now();
      return result;
    }();

    _inFlight[key] = future;

    try {
      return await future;
    } finally {
      _inFlight.remove(key);
    }
  }

  Future<Map<String, dynamic>?> getMarketSummary({bool force = false}) {
    return _fetchWithCache(
      'market_summary',
      () => ApiService.getMarketSummary(),
      force: force,
    );
  }

  Future<Map<String, dynamic>?> getStockForecast(
    String ticker, {
    bool force = false,
  }) {
    return _fetchWithCache(
      'stock_forecast_$ticker',
      () => ApiService.getStockForecast(ticker),
      force: force,
    );
  }

  Future<Map<String, dynamic>?> getInsights(
    String ticker, {
    bool force = false,
  }) {
    return _fetchWithCache(
      'insights_$ticker',
      () => ApiService.getInsights(ticker),
      force: force,
    );
  }

  void clearCache() {
    _cache.clear();
    _cacheTime.clear();
    _inFlight.clear();
    notifyListeners();
  }
}
