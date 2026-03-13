import 'package:flutter/foundation.dart';
import 'package:hybstockadvisor/screens/dashboard.dart';
import 'package:hybstockadvisor/services/api_service.dart';

class PortfolioProvider extends ChangeNotifier {
  bool _isLoading = true;
  bool _isRefreshing = false;
  bool _hasError = false;

  bool _isFetchingAssets = false;

  List<NigerianStock> _availableMarketStocks = [];
  List<dynamic> _portfolioRaw = [];
  List<dynamic> _watchlistRaw = [];

  DateTime? _assetsLastFetchedAt;
  static const Duration _assetsTtl = Duration(seconds: 30);

  bool get isLoading => _isLoading;
  bool get isRefreshing => _isRefreshing;
  bool get hasError => _hasError;

  List<NigerianStock> get availableMarketStocks =>
      List.unmodifiable(_availableMarketStocks);
  List<dynamic> get portfolioRaw => List.unmodifiable(_portfolioRaw);
  List<dynamic> get watchlistRaw => List.unmodifiable(_watchlistRaw);

  Future<void> loadInitial() async {
    _isLoading = true;
    _hasError = false;
    notifyListeners();

    final summaryRes = await ApiService.getMarketSummary();
    if (summaryRes != null && summaryRes['status'] == 'success') {
      final List<dynamic> rawList = summaryRes['data'];
      _availableMarketStocks = rawList.map((item) {
        final String sym = item['symbol'];
        return NigerianStock(
          symbol: sym,
          name: item['name'] ?? '$sym Plc',
          marketCap: item['market_cap'] ?? '--',
          price: (item['price'] as num).toDouble(),
          change:
              '${(item['change_pct'] as num).toDouble() >= 0 ? '+' : ''}${(item['change_pct'] as num).toDouble().toStringAsFixed(2)}%',
        );
      }).toList();
    } else {
      _availableMarketStocks = [];
    }

    await refreshAssets(force: true, showRefreshing: false);
  }

  Future<bool> refreshAssets({
    bool force = false,
    bool showRefreshing = true,
  }) async {
    if (_isFetchingAssets) return !_hasError;

    if (!force && _assetsLastFetchedAt != null) {
      final age = DateTime.now().difference(_assetsLastFetchedAt!);
      if (age < _assetsTtl) {
        _isLoading = false;
        if (showRefreshing) _isRefreshing = false;
        notifyListeners();
        return true;
      }
    }

    _isFetchingAssets = true;
    if (showRefreshing && !_isLoading) {
      _isRefreshing = true;
      notifyListeners();
    }

    final data = await ApiService.getUserAssets();

    if (data != null) {
      _portfolioRaw = List<dynamic>.from(data['portfolio'] as List? ?? []);
      _watchlistRaw = List<dynamic>.from(data['watchlist'] as List? ?? []);
      _assetsLastFetchedAt = DateTime.now();
      _hasError = false;
      _isLoading = false;
      _isRefreshing = false;
      _isFetchingAssets = false;
      notifyListeners();
      return true;
    }

    _hasError = true;
    _isLoading = false;
    _isRefreshing = false;
    _isFetchingAssets = false;
    notifyListeners();
    return false;
  }

  Future<Map<String, dynamic>> addToWatchlist({required String ticker}) async {
    _isRefreshing = true;
    notifyListeners();

    final res = await ApiService.addToWatchlist(ticker: ticker);
    if (res['status'] == 'success') {
      await refreshAssets(force: true, showRefreshing: false);
    } else {
      _isRefreshing = false;
      notifyListeners();
    }
    return res;
  }

  Future<Map<String, dynamic>> addToPortfolio({
    required String ticker,
    required double quantity,
    required double avgBuyPrice,
  }) async {
    _isRefreshing = true;
    notifyListeners();

    final res = await ApiService.addToPortfolio(
      ticker: ticker,
      quantity: quantity,
      avgBuyPrice: avgBuyPrice,
    );
    if (res['status'] == 'success') {
      await refreshAssets(force: true, showRefreshing: false);
    } else {
      _isRefreshing = false;
      notifyListeners();
    }
    return res;
  }

  Future<Map<String, dynamic>> removeFromPortfolioOptimistic({
    required String ticker,
  }) async {
    final backup = List<dynamic>.from(_portfolioRaw);
    _portfolioRaw = _portfolioRaw
        .where((item) => item['ticker'] != ticker)
        .toList();
    notifyListeners();

    final res = await ApiService.removeFromPortfolio(ticker: ticker);
    if (res['status'] != 'success') {
      _portfolioRaw = backup;
      notifyListeners();
      return res;
    }

    await refreshAssets(force: true, showRefreshing: false);
    return res;
  }

  Future<Map<String, dynamic>> removeFromWatchlistOptimistic({
    required String ticker,
  }) async {
    final backup = List<dynamic>.from(_watchlistRaw);
    _watchlistRaw = _watchlistRaw
        .where((item) => item['ticker'] != ticker)
        .toList();
    notifyListeners();

    final res = await ApiService.removeFromWatchlist(ticker: ticker);
    if (res['status'] != 'success') {
      _watchlistRaw = backup;
      notifyListeners();
      return res;
    }

    await refreshAssets(force: true, showRefreshing: false);
    return res;
  }
}
