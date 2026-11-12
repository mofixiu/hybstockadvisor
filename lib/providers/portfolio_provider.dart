import 'package:flutter/foundation.dart';
import 'package:hybstockadvisor/models/market_stock.dart';
import 'package:hybstockadvisor/services/api_service.dart';
import 'package:hybstockadvisor/theme/format.dart';

class PortfolioProvider extends ChangeNotifier {
  bool _isLoading = true;
  bool _isRefreshing = false;
  bool _hasError = false;

  bool _isFetchingAssets = false;

  List<MarketStock> _availableMarketStocks = [];
  List<dynamic> _portfolioRaw = [];
  List<dynamic> _watchlistRaw = [];
  bool _hasFetchedAssetsOnce = false;

  DateTime? _assetsLastFetchedAt;
  DateTime? _summaryAsOf;
  static const Duration _assetsTtl = Duration(minutes: 30);

  bool get isLoading => _isLoading;
  bool get isRefreshing => _isRefreshing;
  bool get hasError => _hasError;

  List<MarketStock> get availableMarketStocks =>
      List.unmodifiable(_availableMarketStocks);
  /// When the market summary's source data was produced.
  DateTime? get summaryAsOf => _summaryAsOf;

  /// Company name from the market summary, or the symbol itself.
  String nameFor(String symbol) {
    for (final s in _availableMarketStocks) {
      if (s.symbol == symbol) return s.name;
    }
    return symbol;
  }

  List<dynamic> get portfolioRaw => List.unmodifiable(_portfolioRaw);
  List<dynamic> get watchlistRaw => List.unmodifiable(_watchlistRaw);

  Future<void> loadInitial({bool force = false}) async {
    final hasFreshAssetsCache =
        !force &&
        _hasFetchedAssetsOnce &&
        _assetsLastFetchedAt != null &&
        DateTime.now().difference(_assetsLastFetchedAt!) < _assetsTtl;
    final hasMarketCache = _availableMarketStocks.isNotEmpty;

    if (hasFreshAssetsCache && hasMarketCache) {
      _isLoading = false;
      _hasError = false;
      notifyListeners();
      return;
    }

    _isLoading = true;
    _hasError = false;
    notifyListeners();

    if (!hasMarketCache) {
      final summaryRes = await ApiService.getMarketSummary();
      _availableMarketStocks = MarketStock.listFromSummary(summaryRes);
      _summaryAsOf = Fmt.parse(
        summaryRes?['meta'] is Map ? summaryRes!['meta']['as_of'] : null,
      );
    }

    await refreshAssets(force: force, showRefreshing: false);
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
        _hasError = false;
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
      _hasFetchedAssetsOnce = true;
      _assetsLastFetchedAt = DateTime.now();
      _hasError = false;
      _isLoading = false;
      _isRefreshing = false;
      _isFetchingAssets = false;
      notifyListeners();
      return true;
    }

    _hasError = true;
    _assetsLastFetchedAt = null;
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

  void resetForSessionChange() {
    _isLoading = true;
    _isRefreshing = false;
    _hasError = false;
    _isFetchingAssets = false;
    _availableMarketStocks = [];
    _portfolioRaw = [];
    _watchlistRaw = [];
    _hasFetchedAssetsOnce = false;
    _assetsLastFetchedAt = null;
    _summaryAsOf = null;
    notifyListeners();
  }
}
