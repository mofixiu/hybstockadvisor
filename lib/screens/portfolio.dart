// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:hive/hive.dart';
import 'package:hybstockadvisor/widgets/ai_chat_sheet.dart';
import 'package:provider/provider.dart';
import 'package:text_scroll/text_scroll.dart';
import 'package:hybstockadvisor/widgets/bottomNavBar.dart';
import 'dart:math';

import 'package:hybstockadvisor/models/app_notification.dart';
import 'package:hybstockadvisor/providers/notification_provider.dart';
import 'package:hybstockadvisor/providers/portfolio_provider.dart';
// We import Dashboard to access NigerianStock model and default lists
import 'package:hybstockadvisor/screens/dashboard.dart';
import 'package:hybstockadvisor/widgets/stock_logo.dart';

// ─────────────────────────────────────────────
// Sort Options
// ─────────────────────────────────────────────
enum _SortOption { nameAZ, nameZA, priceHigh, priceLow, gainers, losers }

class Portfolio extends StatefulWidget {
  const Portfolio({super.key});

  @override
  State<Portfolio> createState() => _PortfolioState();
}

class _PortfolioState extends State<Portfolio>
    with SingleTickerProviderStateMixin {
  _SortOption _portfolioSort = _SortOption.nameAZ;
  _SortOption _watchlistSort = _SortOption.nameAZ;
  AnimationController? _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _fetchInitialData();
    });
  }

  @override
  void dispose() {
    _shimmerController?.dispose();
    super.dispose();
  }

  Future<void> _fetchInitialData() async {
    final provider = context.read<PortfolioProvider>();
    await provider.loadInitial();
    if (!mounted) return;
    await _firePortfolioNotificationsFromProvider(provider);
  }

  Future<void> _removePortfolioItem(String ticker) async {
    final provider = context.read<PortfolioProvider>();
    final res = await provider.removeFromPortfolioOptimistic(ticker: ticker);
    if (!mounted) return;
    if (res['status'] != 'success') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            res['detail'] ?? 'Failed to remove $ticker from portfolio',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _removeWatchlistItem(String ticker) async {
    final provider = context.read<PortfolioProvider>();
    final res = await provider.removeFromWatchlistOptimistic(ticker: ticker);
    if (!mounted) return;
    if (res['status'] != 'success') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            res['detail'] ?? 'Failed to remove $ticker from watchlist',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _firePortfolioNotifications(
    List<_StockItem> items,
    List<dynamic> rawItems,
  ) async {
    if (!mounted) return;
    final box = await Hive.openBox('user');
    if (!mounted) return;
    if (box.get('notif_price_movement', defaultValue: true) != true) return;

    final provider = Provider.of<NotificationProvider>(context, listen: false);

    for (int i = 0; i < rawItems.length; i++) {
      final raw = rawItems[i];
      final double changePct = (raw['change_pct'] as num).toDouble();
      if (changePct.abs() >= 3.0) {
        final String ticker = raw['ticker'] as String;
        final String changeStr = items[i].change;
        await provider.addNotification(
          title: 'Portfolio Price Alert',
          body: '$ticker moved $changeStr today',
          type: NotificationType.priceMovement,
          ticker: ticker,
        );
      }
    }
  }

  Future<void> _firePortfolioNotificationsFromProvider(
    PortfolioProvider portfolioProvider,
  ) async {
    final rawItems = portfolioProvider.portfolioRaw;
    if (rawItems.isEmpty) return;
    final items = rawItems
        .map((item) => _buildUIStockItem(item, isPortfolio: true))
        .toList();
    await _firePortfolioNotifications(items, rawItems);
  }

  // ── Convert API Data to UI Cards ──
  _StockItem _buildUIStockItem(dynamic item, {required bool isPortfolio}) {
    String symbol = item['ticker'];
    double price = (item['live_price'] as num).toDouble();
    double changePct = (item['change_pct'] as num).toDouble();

    // Parse the 7-day sparkline data
    List<dynamic> rawSpark =
        item['spark_data'] ?? [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0];
    List<double> spark = rawSpark.map((e) => (e as num).toDouble()).toList();

    bool isPositive = changePct >= 0;
    String changeStr = changePct == 0.0
        ? "-"
        : "${isPositive ? '+' : ''}${changePct.toStringAsFixed(2)}%";

    // If portfolio, show total value. If watchlist, show stock name.
    String subtitle = isPortfolio
        ? "${(item['quantity'] as num).toStringAsFixed(0)} units @ ₦${(item['avg_buy_price'] as num).toStringAsFixed(2)}"
        : "$symbol Plc";

    // return _StockItem(
    //   symbol: symbol,
    //   name: subtitle,
    //   price: '₦${price.toStringAsFixed(2)}',
    //   change: changeStr,
    //   isPositive: isPositive,
    //   dotColor: isPositive ? Colors.green : Colors.red,
    //   iconBg: const Color(0xFF1C1C1E),
    //   iconLabel: symbol.substring(0, min(2, symbol.length)),
    //   iconWidget: null,
    //   sparkData: spark,
    //   sparkColor: isPositive ? Colors.green : Colors.red,
    // );
    return _StockItem(
      symbol: symbol,
      name: subtitle,
      price: '₦${price.toStringAsFixed(2)}',
      change: changeStr,
      isPositive: isPositive,
      dotColor: isPositive ? Colors.green : Colors.red,
      iconBg: const Color(0xFF1C1C1E),
      iconLabel: symbol.substring(0, min(2, symbol.length)),
      iconWidget: null,
      sparkData: spark,
      sparkColor: isPositive ? Colors.green : Colors.red,
      // 🚨 NEW: Pass the raw numbers!
      quantity: isPortfolio ? (item['quantity'] as num).toDouble() : null,
      avgBuyPrice: isPortfolio
          ? (item['avg_buy_price'] as num).toDouble()
          : null,
    );
  }

  // ── Sort Helper ──
  List<_StockItem> _getSorted(List<_StockItem> items, _SortOption opt) {
    final list = List<_StockItem>.from(items);
    double parsePrice(String p) =>
        double.tryParse(p.replaceAll('₦', '').replaceAll(',', '')) ?? 0;
    double parseChange(String c) {
      if (c == '-') return 0;
      return double.tryParse(c.replaceAll('%', '').replaceAll('+', '')) ?? 0;
    }

    switch (opt) {
      case _SortOption.nameAZ:
        list.sort((a, b) => a.symbol.compareTo(b.symbol));
      case _SortOption.nameZA:
        list.sort((a, b) => b.symbol.compareTo(a.symbol));
      case _SortOption.priceHigh:
        list.sort((a, b) => parsePrice(b.price).compareTo(parsePrice(a.price)));
      case _SortOption.priceLow:
        list.sort((a, b) => parsePrice(a.price).compareTo(parsePrice(b.price)));
      case _SortOption.gainers:
        list.sort(
          (a, b) => parseChange(b.change).compareTo(parseChange(a.change)),
        );
      case _SortOption.losers:
        list.sort(
          (a, b) => parseChange(a.change).compareTo(parseChange(b.change)),
        );
    }
    return list;
  }

  // ── Sort Sheet ──
  void _showSortSheet({required bool isPortfolio}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1A1A2E) : const Color(0xFFF2F4F7);
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A2E);
    final current = isPortfolio ? _portfolioSort : _watchlistSort;

    final options = [
      (_SortOption.nameAZ, 'Name A → Z', Icons.sort_by_alpha),
      (_SortOption.nameZA, 'Name Z → A', Icons.sort_by_alpha),
      (_SortOption.priceHigh, 'Price High → Low', Icons.arrow_downward),
      (_SortOption.priceLow, 'Price Low → High', Icons.arrow_upward),
      (_SortOption.gainers, 'Best Gainers', Icons.trending_up),
      (_SortOption.losers, 'Worst Losers', Icons.trending_down),
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sort by',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 12),
            ...options.map((o) {
              final isSelected = current == o.$1;
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  o.$3,
                  color: isSelected ? const Color(0xFF0A3D62) : Colors.grey,
                  size: 20,
                ),
                title: Text(
                  o.$2,
                  style: TextStyle(
                    color: isSelected ? const Color(0xFF0A3D62) : textColor,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
                trailing: isSelected
                    ? const Icon(
                        Icons.check,
                        color: Color(0xFF0A3D62),
                        size: 18,
                      )
                    : null,
                onTap: () {
                  setState(() {
                    if (isPortfolio) {
                      _portfolioSort = o.$1;
                    } else {
                      _watchlistSort = o.$1;
                    }
                  });
                  Navigator.pop(ctx);
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  // ── Action Sheet ("Add to Portfolio" vs "Watchlist") ──
  void _showAddActionSheet(bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2A2D3E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Add New Asset',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF1A1A2E),
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF0A3D62).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.pie_chart, color: Color(0xFF0A3D62)),
              ),
              title: const Text(
                'Add to Portfolio',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: const Text(
                'Track stocks you currently own',
                style: TextStyle(fontSize: 12),
              ),
              onTap: () {
                Navigator.pop(ctx);
                _openStockPicker(isDark, isPortfolio: true);
              },
            ),
            const Divider(),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.visibility, color: Colors.orange),
              ),
              title: const Text(
                'Add to Watchlist',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: const Text(
                'Monitor stocks without buying',
                style: TextStyle(fontSize: 12),
              ),
              onTap: () {
                Navigator.pop(ctx);
                _openStockPicker(isDark, isPortfolio: false);
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ── Stock Picker ──
  void _openStockPicker(bool isDark, {required bool isPortfolio}) {
    final portfolioProvider = context.read<PortfolioProvider>();
    List<String> alreadySelected = isPortfolio
        ? portfolioProvider.portfolioRaw
              .map((e) => e['ticker'] as String)
              .toList()
        : portfolioProvider.watchlistRaw
              .map((e) => e['ticker'] as String)
              .toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _StockPickerModal(
        isDark: isDark,
        stocksList: portfolioProvider.availableMarketStocks,
        alreadySelected: alreadySelected,
        onSelected: (stock) async {
          Navigator.pop(context); // Close picker

          if (isPortfolio) {
            _showQuantityDialog(stock, isDark);
          } else {
            final res = await portfolioProvider.addToWatchlist(
              ticker: stock.symbol,
            );
            if (!mounted) return;
            if (res['status'] == 'success') {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${stock.symbol} added to Watchlist!'),
                  backgroundColor: Colors.green,
                ),
              );
              await _firePortfolioNotificationsFromProvider(portfolioProvider);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(res['detail'] ?? 'Error'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
      ),
    );
  }

  // ── Quantity Dialog (For Portfolio) ──
  void _showQuantityDialog(NigerianStock stock, bool isDark) {
    final qtyController = TextEditingController();
    final priceController = TextEditingController(
      text: stock.price.toStringAsFixed(2),
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF2A2D3E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Add ${stock.symbol}',
          style: TextStyle(
            color: isDark ? Colors.white : const Color(0xFF1A1A2E),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: qtyController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              style: TextStyle(
                color: isDark ? Colors.white : const Color(0xFF1A1A2E),
              ),
              decoration: InputDecoration(
                labelText: 'Quantity (units)',
                filled: true,
                fillColor: isDark
                    ? const Color(0xFF1A1A2E)
                    : const Color(0xFFF2F4F7),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: priceController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              style: TextStyle(
                color: isDark ? Colors.white : const Color(0xFF1A1A2E),
              ),
              decoration: InputDecoration(
                labelText: 'Average Buy Price (₦)',
                filled: true,
                fillColor: isDark
                    ? const Color(0xFF1A1A2E)
                    : const Color(0xFFF2F4F7),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0A3D62),
            ),
            onPressed: () async {
              final qty = double.tryParse(qtyController.text.trim());
              final price = double.tryParse(priceController.text.trim());

              if (qty == null || price == null) return;

              Navigator.pop(ctx); // Close dialog
              final portfolioProvider = context.read<PortfolioProvider>();
              final res = await portfolioProvider.addToPortfolio(
                ticker: stock.symbol,
                quantity: qty,
                avgBuyPrice: price,
              );

              if (!mounted) return;
              if (res['status'] == 'success') {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${stock.symbol} added to Portfolio!'),
                    backgroundColor: Colors.green,
                  ),
                );
                await _firePortfolioNotificationsFromProvider(
                  portfolioProvider,
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(res['detail'] ?? 'Error'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Add', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ── Asset Breakdown Sheet ──
  void _showPortfolioDetailsSheet(_StockItem stock, bool isDark) {
    if (stock.quantity == null || stock.avgBuyPrice == null) return;

    final bgColor = isDark ? const Color(0xFF1A1A2E) : const Color(0xFFF2F4F7);
    final cardColor = isDark ? const Color(0xFF2A2D3E) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A2E);

    // 🧮 Do the Math!
    double currentPrice =
        double.tryParse(stock.price.replaceAll('₦', '').replaceAll(',', '')) ??
        0;
    double totalCost = stock.quantity! * stock.avgBuyPrice!;
    double currentValue = stock.quantity! * currentPrice;
    double profitLoss = currentValue - totalCost;
    double profitLossPct = (totalCost > 0)
        ? (profitLoss / totalCost) * 100
        : 0.0;

    bool inProfit = profitLoss >= 0;
    Color pnlColor = inProfit ? Colors.green : Colors.red;
    String sign = inProfit ? "+" : "";

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag Handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 20),

            // Header
            Text(
              '${stock.symbol} Asset Breakdown',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 24),

            // Current Value (Big Number)
            Text(
              "Current Value",
              style: TextStyle(color: Colors.grey[500], fontSize: 14),
            ),
            Text(
              "₦${currentValue.toStringAsFixed(2)}",
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),

            // Profit/Loss Badge
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: pnlColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                "$sign₦${profitLoss.abs().toStringAsFixed(2)} ($sign${profitLossPct.toStringAsFixed(2)}%)",
                style: TextStyle(
                  color: pnlColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(height: 30),

            // Stats Grid
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildStatRow(
                    "Total Investment",
                    "₦${totalCost.toStringAsFixed(2)}",
                    textColor,
                  ),
                  const Divider(height: 24),
                  _buildStatRow(
                    "Quantity Owned",
                    "${stock.quantity?.toStringAsFixed(0)} units",
                    textColor,
                  ),
                  const Divider(height: 24),
                  _buildStatRow(
                    "Average Buy Price",
                    "₦${stock.avgBuyPrice?.toStringAsFixed(2)}",
                    textColor,
                  ),
                  const Divider(height: 24),
                  _buildStatRow(
                    "Current Market Price",
                    "₦${currentPrice.toStringAsFixed(2)}",
                    textColor,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Ask AI Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0A3D62),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(
                  Icons.auto_awesome,
                  color: Colors.white,
                  size: 20,
                ),
                label: Text(
                  "Ask AI about ${stock.symbol}",
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => AiChatSheet(
                      isDark: isDark,
                      currentTicker: stock.symbol,
                    ), // Passes context!
                  );
                },
              ),
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom + 10),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value, Color textColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 14)),
        Text(
          value,
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
      ],
    );
  }

  Widget _buildNetworkError(Color textColor) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.wifi_off_rounded, size: 56, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Could not connect to server',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Check your connection and try again.',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _fetchInitialData,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0A3D62),
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Retry',
                style: TextStyle(color: Colors.white, fontSize: 15),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final portfolioProvider = context.watch<PortfolioProvider>();
    final isLoading = portfolioProvider.isLoading;
    final isRefreshing = portfolioProvider.isRefreshing;
    final hasError = portfolioProvider.hasError;
    final portfolioStocks = portfolioProvider.portfolioRaw
        .map((item) => _buildUIStockItem(item, isPortfolio: true))
        .toList();
    final watchlistStocks = portfolioProvider.watchlistRaw
        .map((item) => _buildUIStockItem(item, isPortfolio: false))
        .toList();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1A1A2E) : const Color(0xFFF2F4F7);
    final cardColor = isDark ? const Color(0xFF2A2D3E) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A2E);

    return Scaffold(
      backgroundColor: bgColor,
      floatingActionButton: SizedBox(
        width: 42,
        height: 42,
        child: FloatingActionButton(
          elevation: 4,
          highlightElevation: 6,
          backgroundColor: const Color(0xFF0A3D62),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          onPressed: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) => AiChatSheet(isDark: isDark),
            );
          },
          child: const Icon(
            Icons.smart_toy_outlined,
            color: Colors.white,
            size: 22,
          ),
        ),
      ),

      bottomNavigationBar: const BottomNavBar(currentIndex: 2),
      body: SafeArea(
        child: isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF0A3D62)),
              )
            : hasError
            ? _buildNetworkError(textColor)
            : CustomScrollView(
                slivers: [
                  // ── Header ──
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Portfolio',
                                style: TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                              ),
                              const Text(
                                'HybStockAdvisor',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF0A3D62),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          GestureDetector(
                            onTap: () => _showAddActionSheet(isDark),
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: cardColor,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.07),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.add,
                                color: Color(0xFF0A3D62),
                                size: 22,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 24)),

                  // ── Your Stocks Header ──
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Your Stocks',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => _showSortSheet(isPortfolio: true),
                            child: const Text(
                              'Sort by',
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF0A3D62),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 12)),

                  // ── Stock List (Portfolio) ──
                  if (isRefreshing && _shimmerController != null)
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (_, __) => Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                          child: _ShimmerCard(
                            animation: _shimmerController!,
                            isDark: isDark,
                            cardColor: cardColor,
                          ),
                        ),
                        childCount: 3,
                      ),
                    )
                  else if (portfolioStocks.isEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 32,
                        ),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.bar_chart_outlined,
                                size: 48,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'No stocks in portfolio.',
                                style: TextStyle(color: Colors.grey[500]),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Tap + to add your first stock.',
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  else
                    Builder(
                      builder: (context) {
                        final sorted = _getSorted(
                          portfolioStocks,
                          _portfolioSort,
                        );
                        return SliverList(
                          delegate: SliverChildBuilderDelegate((
                            context,
                            index,
                          ) {
                            final stock = sorted[index];
                            return Dismissible(
                              key: ValueKey('portfolio_${stock.symbol}'),
                              direction: DismissDirection.endToStart,
                              confirmDismiss: (_) async {
                                return await showDialog<bool>(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        backgroundColor: cardColor,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                        ),
                                        title: Text(
                                          'Remove ${stock.symbol}?',
                                          style: TextStyle(color: textColor),
                                        ),
                                        content: Text(
                                          'Remove ${stock.name} from your portfolio?',
                                          style: TextStyle(
                                            color: Colors.grey[500],
                                            fontSize: 13,
                                          ),
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(ctx, false),
                                            child: Text(
                                              'Cancel',
                                              style: TextStyle(
                                                color: Colors.grey[500],
                                              ),
                                            ),
                                          ),
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(ctx, true),
                                            child: const Text(
                                              'Remove',
                                              style: TextStyle(
                                                color: Colors.red,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ) ??
                                    false;
                              },
                              onDismissed: (_) =>
                                  _removePortfolioItem(stock.symbol),
                              background: Container(
                                margin: const EdgeInsets.fromLTRB(
                                  20,
                                  0,
                                  20,
                                  10,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.85),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 20),
                                child: const Icon(
                                  Icons.delete_outline,
                                  color: Colors.white,
                                  size: 26,
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  20,
                                  0,
                                  20,
                                  10,
                                ),
                                child: _StockCard(
                                  stock: stock,
                                  isDark: isDark,
                                  cardColor: cardColor,
                                  textColor: textColor,
                                  // 🚨 NEW: Trigger the bottom sheet!
                                  onTap: () {
                                    if (stock.quantity != null) {
                                      _showPortfolioDetailsSheet(stock, isDark);
                                    }
                                  },
                                ),
                              ),
                              // child: Padding(
                              //   padding: const EdgeInsets.fromLTRB(
                              //     20,
                              //     0,
                              //     20,
                              //     10,
                              //   ),
                              //   child: _StockCard(
                              //     stock: stock,
                              //     isDark: isDark,
                              //     cardColor: cardColor,
                              //     textColor: textColor,
                              //   ),
                              // ),
                            );
                          }, childCount: sorted.length),
                        );
                      },
                    ),

                  const SliverToBoxAdapter(child: SizedBox(height: 24)),

                  // ── Your Watchlist Header ──
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Your Watchlist',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => _showSortSheet(isPortfolio: false),
                            child: const Text(
                              'Sort by',
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF0A3D62),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 12)),

                  // ── Watch List ──
                  if (isRefreshing && _shimmerController != null)
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (_, __) => Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                          child: _ShimmerCard(
                            animation: _shimmerController!,
                            isDark: isDark,
                            cardColor: cardColor,
                          ),
                        ),
                        childCount: 3,
                      ),
                    )
                  else if (watchlistStocks.isEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 32,
                        ),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.visibility_off,
                                size: 48,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Watchlist is empty.',
                                style: TextStyle(color: Colors.grey[500]),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Tap + to add your first stock.',
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  else
                    Builder(
                      builder: (context) {
                        final sorted = _getSorted(
                          watchlistStocks,
                          _watchlistSort,
                        );
                        return SliverList(
                          delegate: SliverChildBuilderDelegate((
                            context,
                            index,
                          ) {
                            final stock = sorted[index];
                            return Dismissible(
                              key: ValueKey('watchlist_${stock.symbol}'),
                              direction: DismissDirection.endToStart,
                              confirmDismiss: (_) async {
                                return await showDialog<bool>(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        backgroundColor: cardColor,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                        ),
                                        title: Text(
                                          'Remove ${stock.symbol}?',
                                          style: TextStyle(color: textColor),
                                        ),
                                        content: Text(
                                          'Remove ${stock.name} from your watchlist?',
                                          style: TextStyle(
                                            color: Colors.grey[500],
                                            fontSize: 13,
                                          ),
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(ctx, false),
                                            child: Text(
                                              'Cancel',
                                              style: TextStyle(
                                                color: Colors.grey[500],
                                              ),
                                            ),
                                          ),
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(ctx, true),
                                            child: const Text(
                                              'Remove',
                                              style: TextStyle(
                                                color: Colors.red,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ) ??
                                    false;
                              },
                              onDismissed: (_) =>
                                  _removeWatchlistItem(stock.symbol),
                              background: Container(
                                margin: const EdgeInsets.fromLTRB(
                                  20,
                                  0,
                                  20,
                                  10,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.85),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 20),
                                child: const Icon(
                                  Icons.delete_outline,
                                  color: Colors.white,
                                  size: 26,
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  20,
                                  0,
                                  20,
                                  10,
                                ),
                                child: _StockCard(
                                  stock: stock,
                                  isDark: isDark,
                                  cardColor: cardColor,
                                  textColor: textColor,
                                ),
                              ),
                            );
                          }, childCount: sorted.length),
                        );
                      },
                    ),

                  const SliverToBoxAdapter(child: SizedBox(height: 30)),
                ],
              ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Stock Card
// ─────────────────────────────────────────────
// class _StockCard extends StatelessWidget {
//   final _StockItem stock;
//   final bool isDark;
//   final Color cardColor;
//   final Color textColor;

//   const _StockCard({
//     required this.stock,
//     required this.isDark,
//     required this.cardColor,
//     required this.textColor,
//   });

//   @override
//   Widget build(BuildContext context) {
//     // Dynamic chart scaling for the sparkline
//     double maxPrice = stock.sparkData.isNotEmpty
//         ? stock.sparkData.reduce((a, b) => max(a, b))
//         : 100;
//     double minPrice = stock.sparkData.isNotEmpty
//         ? stock.sparkData.reduce((a, b) => min(a, b))
//         : 0;
//     if (maxPrice == minPrice) {
//       maxPrice *= 1.05;
//       minPrice *= 0.95;
//     }
//     double padding = (maxPrice - minPrice) * 0.2;

//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
//       decoration: BoxDecoration(
//         color: cardColor,
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.05),
//             blurRadius: 6,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: Row(
//         children: [
//           // Icon
//           Container(
//             width: 44,
//             height: 44,
//             decoration: BoxDecoration(
//               color: stock.iconBg,
//               borderRadius: BorderRadius.circular(10),
//             ),
//             child: Center(
//               child: Text(
//                 stock.iconLabel,
//                 style: TextStyle(
//                   fontWeight: FontWeight.bold,
//                   fontSize: 14,
//                   color: Colors.white,
//                 ),
//               ),
//             ),
//           ),
//           const SizedBox(width: 12),
//           // Symbol + Name + dot
//           Expanded(
//             flex: 2,
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Row(
//                   children: [
//                     Text(
//                       stock.symbol,
//                       style: TextStyle(
//                         fontWeight: FontWeight.bold,
//                         fontSize: 15,
//                         color: textColor,
//                       ),
//                     ),
//                     const SizedBox(width: 6),
//                     Container(
//                       width: 7,
//                       height: 7,
//                       decoration: BoxDecoration(
//                         color: stock.dotColor,
//                         shape: BoxShape.circle,
//                       ),
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 2),
//                 Text(
//                   stock.name,
//                   style: TextStyle(fontSize: 12, color: Colors.grey[500]),
//                   overflow: TextOverflow.ellipsis,
//                 ),
//               ],
//             ),
//           ),
//           const SizedBox(width: 10),
//           // Sparkline
//           Expanded(
//             flex: 2,
//             child: SizedBox(
//               height: 40,
//               child: LineChart(
//                 LineChartData(
//                   minX: 0,
//                   maxX: (stock.sparkData.length - 1).toDouble(),
//                   minY: minPrice - padding,
//                   maxY: maxPrice + padding,
//                   gridData: FlGridData(show: false),
//                   borderData: FlBorderData(show: false),
//                   titlesData: FlTitlesData(show: false),
//                   lineTouchData: LineTouchData(enabled: false),
//                   lineBarsData: [
//                     LineChartBarData(
//                       spots: stock.sparkData
//                           .asMap()
//                           .entries
//                           .map((e) => FlSpot(e.key.toDouble(), e.value))
//                           .toList(),
//                       isCurved: true,
//                       color: stock.sparkColor,
//                       barWidth: 2,
//                       isStrokeCapRound: true,
//                       dotData: FlDotData(show: false),
//                       belowBarData: BarAreaData(show: false),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//           const SizedBox(width: 10),
//           // Price + Change
//           Column(
//             crossAxisAlignment: CrossAxisAlignment.end,
//             children: [
//               Text(
//                 stock.price,
//                 style: TextStyle(
//                   fontWeight: FontWeight.bold,
//                   fontSize: 14,
//                   color: textColor,
//                 ),
//               ),
//               const SizedBox(height: 2),
//               Text(
//                 stock.change,
//                 style: TextStyle(
//                   fontSize: 12,
//                   fontWeight: FontWeight.w600,
//                   color: stock.isPositive ? Colors.green : Colors.red,
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
// }
// ─────────────────────────────────────────────
// Shimmer Card Placeholder
// ─────────────────────────────────────────────
class _ShimmerCard extends StatelessWidget {
  final Animation<double> animation;
  final bool isDark;
  final Color cardColor;

  const _ShimmerCard({
    required this.animation,
    required this.isDark,
    required this.cardColor,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (_, __) {
        final highlightColor = isDark
            ? const Color(0xFF3A3D4E)
            : const Color(0xFFEAEAEA);
        final baseColor = isDark
            ? const Color(0xFF1E2030)
            : const Color(0xFFD4D4D4);

        final gradient = LinearGradient(
          begin: Alignment(-1.5 + animation.value * 3.0, 0),
          end: Alignment(-0.5 + animation.value * 3.0, 0),
          colors: [baseColor, highlightColor, baseColor],
        );

        Widget box(double w, double h, {double radius = 8}) => Container(
          width: w,
          height: h,
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(radius),
          ),
        );

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              box(44, 44, radius: 10),
              const SizedBox(width: 12),
              Expanded(
                flex: 5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    box(80, 13),
                    const SizedBox(height: 7),
                    box(120, 11),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              box(60, 40, radius: 6),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [box(58, 13), const SizedBox(height: 7), box(40, 11)],
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────
// Stock Card (With Auto-Scrolling Text)
// ─────────────────────────────────────────────
class _StockCard extends StatelessWidget {
  final _StockItem stock;
  final bool isDark;
  final Color cardColor;
  final Color textColor;
  final VoidCallback? onTap;

  const _StockCard({
    required this.stock,
    required this.isDark,
    required this.cardColor,
    required this.textColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Dynamic chart scaling for the sparkline
    double maxPrice = stock.sparkData.isNotEmpty
        ? stock.sparkData.reduce((a, b) => max(a, b))
        : 100;
    double minPrice = stock.sparkData.isNotEmpty
        ? stock.sparkData.reduce((a, b) => min(a, b))
        : 0;
    if (maxPrice == minPrice) {
      maxPrice *= 1.05;
      minPrice *= 0.95;
    }
    double padding = (maxPrice - minPrice) * 0.2;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon
            StockLogo(symbol: stock.symbol),
            const SizedBox(width: 12),

            // Symbol + Auto-Scrolling Name
            Expanded(
              flex: 5, // Give text more room
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        stock.symbol,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: stock.dotColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  // 🚀 THE MAGIC SCROLLING WIDGET 🚀
                  TextScroll(
                    stock.name,
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    velocity: const Velocity(pixelsPerSecond: Offset(30, 0)),
                    delayBefore: const Duration(seconds: 2),
                    pauseBetween: const Duration(seconds: 2),
                    mode: TextScrollMode
                        .bouncing, // Bounces back and forth if it overflows
                  ),
                ],
              ),
            ),

            const SizedBox(width: 10),

            // Sparkline (Given fixed width to stop it from crushing the text)
            SizedBox(
              width: 60,
              height: 40,
              child: LineChart(
                LineChartData(
                  minX: 0,
                  maxX: (stock.sparkData.length - 1).toDouble(),
                  minY: minPrice - padding,
                  maxY: maxPrice + padding,
                  gridData: FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(show: false),
                  lineTouchData: LineTouchData(enabled: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: stock.sparkData
                          .asMap()
                          .entries
                          .map((e) => FlSpot(e.key.toDouble(), e.value))
                          .toList(),
                      isCurved: true,
                      color: stock.sparkColor,
                      barWidth: 2,
                      isStrokeCapRound: true,
                      dotData: FlDotData(show: false),
                      belowBarData: BarAreaData(show: false),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(width: 10),

            // Price + Change
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  stock.price,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  stock.change,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: stock.isPositive ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Reusable Stock Picker Modal
// ─────────────────────────────────────────────
class _StockPickerModal extends StatefulWidget {
  final bool isDark;
  final List<NigerianStock> stocksList;
  final List<String> alreadySelected;
  final ValueChanged<NigerianStock> onSelected;

  const _StockPickerModal({
    required this.isDark,
    required this.stocksList,
    required this.alreadySelected,
    required this.onSelected,
  });

  @override
  State<_StockPickerModal> createState() => _StockPickerModalState();
}

class _StockPickerModalState extends State<_StockPickerModal> {
  final TextEditingController _controller = TextEditingController();
  late List<NigerianStock> _filtered;

  @override
  void initState() {
    super.initState();
    _filtered = widget.stocksList;
  }

  void _onSearch(String query) {
    setState(() {
      _filtered = widget.stocksList
          .where(
            (s) =>
                s.symbol.toLowerCase().contains(query.toLowerCase()) ||
                s.name.toLowerCase().contains(query.toLowerCase()),
          )
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final cardColor = widget.isDark ? const Color(0xFF2A2D3E) : Colors.white;
    final bgColor = widget.isDark
        ? const Color(0xFF1A1A2E)
        : const Color(0xFFF2F4F7);
    final textColor = widget.isDark ? Colors.white : const Color(0xFF1A1A2E);

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      builder: (_, scrollController) => Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  Text(
                    'Select Stock',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Icon(Icons.close, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Container(
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  controller: _controller,
                  onChanged: _onSearch,
                  autofocus: true,
                  style: TextStyle(color: textColor),
                  decoration: InputDecoration(
                    hintText: 'Search...',
                    prefixIcon: const Icon(
                      Icons.search,
                      color: Color(0xFF0A3D62),
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListView.separated(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                itemCount: _filtered.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, i) {
                  final stock = _filtered[i];
                  final alreadyAdded = widget.alreadySelected.contains(
                    stock.symbol,
                  );
                  return GestureDetector(
                    onTap: alreadyAdded ? null : () => widget.onSelected(stock),
                    child: Opacity(
                      opacity: alreadyAdded ? 0.4 : 1.0,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            StockLogo(symbol: stock.symbol),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    stock.symbol,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: textColor,
                                    ),
                                  ),
                                  Text(
                                    stock.name,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey[500],
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            if (alreadyAdded)
                              const Icon(
                                Icons.check_circle,
                                color: Color(0xFF0A3D62),
                                size: 18,
                              )
                            else
                              Text(
                                '₦${stock.price.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Data model
// ─────────────────────────────────────────────
// class _StockItem {
//   final String symbol;
//   final String name;
//   final String price;
//   final String change;
//   final bool isPositive;
//   final Color dotColor;
//   final Color iconBg;
//   final String iconLabel;
//   final Widget? iconWidget;
//   final List<double> sparkData;
//   final Color sparkColor;

//   const _StockItem({
//     required this.symbol,
//     required this.name,
//     required this.price,
//     required this.change,
//     required this.isPositive,
//     required this.dotColor,
//     required this.iconBg,
//     required this.iconLabel,
//     required this.iconWidget,
//     required this.sparkData,
//     required this.sparkColor,
//   });
// }
// ─────────────────────────────────────────────
// Data model
// ─────────────────────────────────────────────
class _StockItem {
  final String symbol;
  final String name;
  final String price;
  final String change;
  final bool isPositive;
  final Color dotColor;
  final Color iconBg;
  final String iconLabel;
  final Widget? iconWidget;
  final List<double> sparkData;
  final Color sparkColor;

  // 🚨 NEW: Added these so we can do math in the bottom sheet!
  final double? quantity;
  final double? avgBuyPrice;

  const _StockItem({
    required this.symbol,
    required this.name,
    required this.price,
    required this.change,
    required this.isPositive,
    required this.dotColor,
    required this.iconBg,
    required this.iconLabel,
    required this.iconWidget,
    required this.sparkData,
    required this.sparkColor,
    this.quantity,
    this.avgBuyPrice,
  });
}
