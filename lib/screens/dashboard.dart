import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'package:hybstockadvisor/screens/ai_insights.dart';
import 'package:hybstockadvisor/screens/notification_center.dart';
import 'package:hybstockadvisor/widgets/ai_chat_sheet.dart';
import 'package:hybstockadvisor/widgets/bottomNavBar.dart';
import 'package:provider/provider.dart';
import 'dart:math';

import 'package:hybstockadvisor/models/app_notification.dart';
import 'package:hybstockadvisor/providers/notification_provider.dart';
import 'package:hybstockadvisor/services/api_service.dart';
import 'package:hybstockadvisor/widgets/custom_page_route.dart';
import 'package:hybstockadvisor/widgets/stock_logo.dart';

// ─────────────────────────────────────────────
// Stock Data Model
// ─────────────────────────────────────────────
class NigerianStock {
  final String symbol;
  final String name;
  final String marketCap;
  final double price;
  final String change;

  const NigerianStock({
    required this.symbol,
    required this.name,
    required this.marketCap,
    required this.price,
    required this.change,
  });
}

// Static fallback data so the app doesn't look empty before the API loads
final List<NigerianStock> defaultNigerianStocks = [
  const NigerianStock(
    symbol: 'GTCO',
    name: 'Guaranty Trust Holding Company Plc',
    marketCap: '4.35T',
    price: 119.00,
    change: '-',
  ),
  const NigerianStock(
    symbol: 'MTNN',
    name: 'MTN Nigeria Communications PLC',
    marketCap: '16.36T',
    price: 790.00,
    change: '-',
  ),
  const NigerianStock(
    symbol: 'DANGCEM',
    name: 'Dangote Cement Plc',
    marketCap: '13.57T',
    price: 809.90,
    change: '-',
  ),
];

// Dictionary to map API tickers to real company names and market caps
// stockMetadata removed — name & market_cap now come from the API

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard>
    with SingleTickerProviderStateMixin {
  // Live API Data List
  List<NigerianStock> _searchableStocks = List.from(defaultNigerianStocks);
  NigerianStock _selectedStock = defaultNigerianStocks.first;

  // --- AI State Variables ---
  bool _isLoading = true;
  bool _hasError = false;
  double _safetyIndex = 0.0;
  String _recommendation = "LOADING";
  double _currentPrice = 0.0;
  String _priceChange = "-";
  List<double> _last5DaysPrices = [0, 0, 0, 0, 0];
  List<String> _last5DaysDates = ['-', '-', '-', '-', '-'];
  String _username = 'User'; // default fallback
  AnimationController? _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
    _loadUsername();
    _fetchMarketSummaryAndStart();
  }

  @override
  void dispose() {
    _shimmerController?.dispose();
    super.dispose();
  }

  // 1. Fetch the entire market list first
  Future<void> _fetchMarketSummaryAndStart() async {
    final summaryRes = await ApiService.getMarketSummary();

    if (summaryRes != null && summaryRes['status'] == 'success') {
      List<dynamic> rawList = summaryRes['data'];
      List<NigerianStock> liveList = [];

      for (var item in rawList) {
        String sym = item['symbol'];
        double price = (item['price'] as num).toDouble();
        double pct = (item['change_pct'] as num).toDouble();

        String name = item['name'] ?? '$sym Plc';
        String cap = item['market_cap'] ?? '--';

        String changeStr = '-';
        if (pct > 0) {
          changeStr = '+${pct.toStringAsFixed(2)}%';
        } else if (pct < 0)
          // ignore: curly_braces_in_flow_control_structures
          changeStr = '${pct.toStringAsFixed(2)}%';

        liveList.add(
          NigerianStock(
            symbol: sym,
            name: name,
            marketCap: cap,
            price: price,
            change: changeStr,
          ),
        );
      }

      setState(() {
        _searchableStocks = liveList;
        // Default to GTCO or the first available stock
        _selectedStock = liveList.firstWhere(
          (s) => s.symbol == ApiService.currentTicker,
          orElse: () => liveList.first,
        );
      });
    }

    // 2. Fetch the AI Insights for the selected stock
    _fetchAIInsights(_selectedStock.symbol);

    // 3. Fire notifications (capped at 7 per session, prioritized)
    _fireAllNotifications();
  }

  Future<void> _fetchAIInsights(String ticker) async {
    ApiService.currentTicker = ticker;

    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    final response = await ApiService.getStockForecast(ticker);

    if (response != null && response['status'] == 'success') {
      List<dynamic> historicalData = response['data'];

      if (historicalData.isNotEmpty) {
        var todayData = historicalData.last;

        List<double> prices = [];
        List<String> dates = [];

        var recentData = historicalData.length >= 5
            ? historicalData.sublist(historicalData.length - 5)
            : historicalData;

        for (var day in recentData) {
          prices.add((day['close'] as num).toDouble());
          DateTime dt = DateTime.parse(day['date']);
          const weekdays = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
          dates.add(weekdays[dt.weekday - 1]);
        }

        // Dynamic change logic (handles flat lines properly)
        String changeStr = "-";
        if (prices.length >= 2) {
          double today = prices.last;
          double yesterday = prices[prices.length - 2];
          double pct = ((today - yesterday) / yesterday) * 100;
          if (pct > 0) {
            changeStr = "+${pct.toStringAsFixed(2)}%";
          } else if (pct < 0)
            // ignore: curly_braces_in_flow_control_structures
            changeStr = "${pct.toStringAsFixed(2)}%";
        }

        setState(() {
          _safetyIndex = (todayData['Safety_Index'] as num).toDouble();
          _recommendation = todayData['Recommendation']
              .toString()
              .replaceAll(RegExp(r'[^\w\s]'), '')
              .trim();
          _currentPrice = (todayData['close'] as num).toDouble();
          _last5DaysPrices = prices;
          _last5DaysDates = dates;
          _priceChange = changeStr;

          // Update the specific stock instance in the UI
          _selectedStock = NigerianStock(
            symbol: ticker,
            name: _selectedStock.name,
            marketCap: _selectedStock.marketCap,
            price: _currentPrice,
            change: _priceChange,
          );

          _isLoading = false;
        });

        // Fire in-app notifications for portfolio stocks (not just selected)
        // Dedup in provider prevents duplicates if called again
      }
    } else {
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  // ── Notification priority: lower number = higher priority ──
  // Weekly=0, Sell/StrongSell=1, StrongBuy=2, AIInsight=3, PriceAlert=4
  static const int _maxNotificationsPerSession = 7;

  /// Master notification dispatcher. Collects all candidates, sorts by
  /// priority, then fires only the top [_maxNotificationsPerSession].
  Future<void> _fireAllNotifications() async {
    if (!mounted) return;
    final box = await Hive.openBox('user');
    if (!mounted) return;
    final provider = Provider.of<NotificationProvider>(context, listen: false);

    final bool notifForecast =
        box.get('notif_ai_forecast', defaultValue: true) == true;
    final bool notifSafety =
        box.get('notif_safety_index', defaultValue: true) == true;
    final bool notifPrice =
        box.get('notif_price_movement', defaultValue: true) == true;
    final bool notifWeekly =
        box.get('notif_weekly_summary', defaultValue: false) == true;

    // Each candidate: (priority, title, body, type, ticker)
    final List<(int, String, String, NotificationType, String?)> candidates =
        [];

    // ── 1. Weekly Summary (priority 0) ──
    if (notifWeekly) {
      final weeklyCand = await _collectWeeklySummary();
      if (weeklyCand != null) candidates.add(weeklyCand);
    }

    // ── 2-4. Portfolio-based notifications ──
    final data = await ApiService.getUserAssets();
    if (data != null && mounted) {
      final portfolioItems = data['portfolio'] as List? ?? [];
      final tickers = portfolioItems.map((e) => e['ticker'] as String).toList();

      if (tickers.isNotEmpty) {
        final forecasts = await Future.wait(
          tickers.map((t) => ApiService.getStockForecast(t)),
        );
        if (!mounted) return;

        for (int i = 0; i < tickers.length; i++) {
          final ticker = tickers[i];
          final response = forecasts[i];
          if (response == null || response['status'] != 'success') continue;

          final List<dynamic> history = response['data'];
          if (history.isEmpty) continue;

          final todayData = history.last;
          final double safetyIdx = (todayData['Safety_Index'] as num)
              .toDouble();
          final String recommendation = todayData['Recommendation']
              .toString()
              .replaceAll(RegExp(r'[^\w\s]'), '')
              .trim();
          final recLower = recommendation.toLowerCase();

          // Sell / Strong Sell (priority 1)
          if (recLower.contains('sell')) {
            final isSS = recLower.contains('strong');
            candidates.add((
              1,
              isSS ? 'Strong Sell Alert' : 'Sell Alert',
              '$ticker is rated "$recommendation". Consider reviewing your position.',
              NotificationType.aiForecast,
              '${ticker}_sell',
            ));
          }

          // AI Insight — only when notable: safety < 4 or > 7 (priority 3)
          if ((notifForecast || notifSafety) &&
              (safetyIdx < 4.0 || safetyIdx > 7.0)) {
            candidates.add((
              3,
              'AI Insight: $ticker',
              '$ticker is rated "$recommendation" with a safety index of ${safetyIdx.toStringAsFixed(1)}',
              NotificationType.aiForecast,
              ticker,
            ));
          }

          // Price movement ≥ 3% (priority 4)
          if (notifPrice && history.length >= 2) {
            final today = (history.last['close'] as num).toDouble();
            final yesterday = (history[history.length - 2]['close'] as num)
                .toDouble();
            final pct = ((today - yesterday) / yesterday) * 100;
            if (pct.abs() >= 3.0) {
              final changeStr = pct > 0
                  ? '+${pct.toStringAsFixed(2)}%'
                  : '${pct.toStringAsFixed(2)}%';
              candidates.add((
                4,
                'Portfolio Price Alert',
                '$ticker moved $changeStr today',
                NotificationType.priceMovement,
                ticker,
              ));
            }
          }
        }
      }
    }

    // ── 5. Strong Buy alerts (priority 2) — top 3 from all market stocks ──
    if (notifForecast && mounted) {
      final strongBuyCandidates = await _collectStrongBuyCandidates();
      candidates.addAll(strongBuyCandidates);
    }

    if (!mounted) return;

    // ── Sort by priority (ascending) and cap ──
    candidates.sort((a, b) => a.$1.compareTo(b.$1));
    final capped = candidates.take(_maxNotificationsPerSession);

    for (final (_, title, body, type, ticker) in capped) {
      await provider.addNotification(
        title: title,
        body: body,
        type: type,
        ticker: ticker,
      );
    }
  }

  /// Collect strong buy candidates from all market stocks (priority 2).
  Future<List<(int, String, String, NotificationType, String?)>>
  _collectStrongBuyCandidates() async {
    final tickers = _searchableStocks.map((s) => s.symbol).toList();
    if (tickers.isEmpty) return [];

    final forecasts = await Future.wait(
      tickers.map((t) => ApiService.getStockForecast(t)),
    );
    if (!mounted) return [];

    final List<({String ticker, String recommendation, double safetyIndex})>
    raw = [];

    for (int i = 0; i < tickers.length; i++) {
      final response = forecasts[i];
      if (response == null || response['status'] != 'success') continue;

      final List<dynamic> history = response['data'];
      if (history.isEmpty) continue;

      final todayData = history.last;
      final String rec = todayData['Recommendation']
          .toString()
          .replaceAll(RegExp(r'[^\w\s]'), '')
          .trim();

      if (rec.toLowerCase().contains('strong') &&
          rec.toLowerCase().contains('buy')) {
        raw.add((
          ticker: tickers[i],
          recommendation: rec,
          safetyIndex: (todayData['Safety_Index'] as num).toDouble(),
        ));
      }
    }

    raw.sort((a, b) => b.safetyIndex.compareTo(a.safetyIndex));
    return raw
        .take(3)
        .map(
          (c) => (
            2,
            'Strong Buy Alert',
            '${c.ticker} is rated "${c.recommendation}" (Safety: ${c.safetyIndex.toStringAsFixed(1)}). This could be a buying opportunity.',
            NotificationType.aiForecast,
            '${c.ticker}_strongbuy' as String?,
          ),
        )
        .toList();
  }

  /// Collect a weekly summary candidate (priority 0). Returns null if not Friday.
  Future<(int, String, String, NotificationType, String?)?>
  _collectWeeklySummary() async {
    final now = DateTime.now();
    if (now.weekday != DateTime.friday) return null;

    final data = await ApiService.getUserAssets();
    if (data == null || !mounted) return null;

    final portfolioItems = data['portfolio'] as List? ?? [];

    String portfolioSummary;
    if (portfolioItems.isEmpty) {
      portfolioSummary =
          'Your portfolio is empty. Add stocks to get weekly recaps.';
    } else {
      double totalChange = 0;
      String topGainer = '';
      double topGain = double.negativeInfinity;
      String topLoser = '';
      double topLoss = double.infinity;

      for (final item in portfolioItems) {
        final String ticker = item['ticker'] as String;
        final double changePct = (item['change_pct'] as num).toDouble();
        totalChange += changePct;
        if (changePct > topGain) {
          topGain = changePct;
          topGainer = ticker;
        }
        if (changePct < topLoss) {
          topLoss = changePct;
          topLoser = ticker;
        }
      }
      final avgChange = totalChange / portfolioItems.length;
      final sign = avgChange >= 0 ? '+' : '';
      portfolioSummary =
          'Your portfolio averaged $sign${avgChange.toStringAsFixed(2)}% this week.';
      if (topGainer.isNotEmpty) {
        final gSign = topGain >= 0 ? '+' : '';
        portfolioSummary +=
            ' Top gainer: $topGainer ($gSign${topGain.toStringAsFixed(1)}%).';
      }
      if (topLoser.isNotEmpty && topLoser != topGainer) {
        portfolioSummary +=
            ' Top loser: $topLoser (${topLoss.toStringAsFixed(1)}%).';
      }
    }

    String marketOverview = '';
    if (_searchableStocks.isNotEmpty) {
      NigerianStock? marketTopGainer;
      double marketTopGain = double.negativeInfinity;
      for (final stock in _searchableStocks) {
        if (stock.change == '-') continue;
        final pct =
            double.tryParse(
              stock.change.replaceAll('%', '').replaceAll('+', ''),
            ) ??
            0;
        if (pct > marketTopGain) {
          marketTopGain = pct;
          marketTopGainer = stock;
        }
      }
      if (marketTopGainer != null) {
        marketOverview =
            ' Market mover: ${marketTopGainer.symbol} (${marketTopGainer.change}).';
      }
    }

    return (
      0,
      'Weekly Summary',
      '$portfolioSummary$marketOverview',
      NotificationType.weeklySummary,
      'weekly' as String?,
    );
  }

  void _openStockSearch(bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _StockSearchModal(
        isDark: isDark,
        stocksList: _searchableStocks, // Pass the live data!
        onSelected: (stock) {
          setState(() {
            _selectedStock = stock;
            _fetchAIInsights(stock.symbol);
          });
          Navigator.pop(context);
        },
      ),
    );
  }

  Future<void> _loadUsername() async {
    final box = await Hive.openBox('user');
    final name = box.get('first_name');
    if (name != null && mounted) {
      setState(() => _username = name);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1A1A2E) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A2E);
    final username = _username;

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
              builder: (context) => AiChatSheet(
                isDark: isDark,
                currentTicker: _selectedStock.symbol,
              ),
            );
          },
          child: const Icon(
            Icons.smart_toy_outlined,
            color: Colors.white,
            size: 22,
          ),
        ),
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 0),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(isDark),
            Expanded(
              child: RefreshIndicator(
                color: const Color(0xFF0A3D62),
                onRefresh: _fetchMarketSummaryAndStart,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        () {
                          final hour = DateTime.now().hour;
                          if (hour < 12) return 'Good Morning, $username';
                          if (hour < 17) return 'Good Afternoon, $username';
                          return 'Good Evening, $username';
                        }(),
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF1A1A2E),
                        ),
                      ),
                      const SizedBox(height: 20),

                      _buildSearchBar(isDark),
                      const SizedBox(height: 20),

                      if (_isLoading && _shimmerController != null)
                        _DashboardShimmer(
                          controller: _shimmerController!,
                          isDark: isDark,
                        )
                      else if (_hasError)
                        SizedBox(
                          height: 380,
                          child: _buildNetworkError(
                            textColor,
                            () => _fetchAIInsights(_selectedStock.symbol),
                          ),
                        )
                      else if (!_isLoading) ...[
                        _buildSafetyIndexCard(isDark),
                        const SizedBox(height: 5),
                        Center(
                          child: GestureDetector(
                            onTap: () => context.pushFade(const AiInsights()),
                            child: Text(
                              "For safety index explanation, click here",
                              style: TextStyle(
                                color: Color(0xFF3D5A80),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        _buildCurrentPriceCard(isDark),
                        const SizedBox(height: 16),
                        _buildLast5DaysCard(isDark),
                        const SizedBox(height: 20),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNetworkError(Color textColor, VoidCallback onRetry) {
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
              onPressed: onRetry,
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

  Widget _buildHeader(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            // backgroundColor: const Color(0xFFF4C6A0),
            backgroundColor: Colors.white,
            child: Image.asset('assets/images/logo.png', width: 50, height: 50),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'HybStockAdvisor',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                ),
              ),
              Text(
                'Welcome back',
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
            ],
          ),
          const Spacer(),
          Consumer<NotificationProvider>(
            builder: (context, notifProvider, _) {
              final count = notifProvider.unreadCount;
              return GestureDetector(
                onTap: () => context.pushFade(const NotificationCenter()),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(
                      Icons.notifications,
                      color: isDark ? Colors.white70 : const Color(0xFF3D5A80),
                    ),
                    if (count > 0)
                      Positioned(
                        top: -4,
                        right: -4,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            count > 99 ? '99+' : '$count',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(bool isDark) {
    final changeIsPositive = _priceChange.startsWith('+');
    final changeIsNeutral = _priceChange == '-';

    return GestureDetector(
      onTap: () => _openStockSearch(isDark),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2A2D3E) : const Color(0xFFF2F4F7),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.search, color: Color(0xFF2979FF), size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_selectedStock.symbol} (${_selectedStock.name.split(' ').take(2).join(' ')})',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '₦${_currentPrice.toStringAsFixed(2)}  •  Mkt Cap: ${_selectedStock.marketCap}',
                    style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
            if (!changeIsNeutral)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: (changeIsPositive ? Colors.green : Colors.red)
                      .withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _priceChange,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: changeIsPositive ? Colors.green : Colors.red,
                  ),
                ),
              ),
            const SizedBox(width: 8),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              color: isDark ? Colors.white54 : Colors.grey[600],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSafetyIndexCard(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A2D3E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 220,
            width: 220,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    startDegreeOffset: -210,
                    sectionsSpace: 0,
                    centerSpaceRadius: 100,
                    sections: [
                      PieChartSectionData(
                        value: _safetyIndex,
                        color: const Color(0xFF2979FF), // Strict Blue Restored
                        radius: 18,
                        showTitle: false,
                      ),
                      PieChartSectionData(
                        value: 100 - _safetyIndex,
                        color: isDark
                            ? Colors.white12
                            : Colors.grey.withOpacity(0.15),
                        radius: 18,
                        showTitle: false,
                      ),
                    ],
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'SAFETY INDEX',
                      style: TextStyle(
                        fontSize: 14,
                        letterSpacing: 1.2,
                        color: Colors.black,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: _safetyIndex.toStringAsFixed(1),
                            style: TextStyle(
                              fontSize: 38,
                              fontWeight: FontWeight.bold,
                              fontFamily: GoogleFonts.montserrat().fontFamily,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF1A1A2E),
                            ),
                          ),
                          TextSpan(
                            text: '%',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF5E6A3), // Strict Yellow Restored
              borderRadius: BorderRadius.circular(30),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.stop_circle,
                  color: Color(0xFF7A5C00),
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  _recommendation,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                    color: Color(0xFF7A5C00), // Strict Brown Restored
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLast5DaysCard(bool isDark) {
    double maxPrice = _last5DaysPrices.isNotEmpty
        ? _last5DaysPrices.reduce(max)
        : 100;
    double minPrice = _last5DaysPrices.isNotEmpty
        ? _last5DaysPrices.reduce(min)
        : 0;

    // FIX: Perfect centering for flat lines (when price doesn't change for 5 days)
    if (maxPrice == minPrice) {
      maxPrice = maxPrice * 1.05;
      minPrice = minPrice * 0.95;
    }
    double padding = (maxPrice - minPrice) * 0.2;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A2D3E) : const Color(0xFFF2F4F7),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'LAST 5 DAYS',
            style: TextStyle(
              fontSize: 12,
              letterSpacing: 1.2,
              color: isDark ? Colors.white70 : Colors.black,
              fontWeight: FontWeight.w500,
            ),
          ),
          Row(
            children: [
              Text(
                '₦${_selectedStock.price.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                ),
              ),
              const SizedBox(width: 8),
              if (_selectedStock.change != '-')
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color:
                        (_selectedStock.change.startsWith('+')
                                ? Colors.green
                                : Colors.red)
                            .withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _selectedStock.change,
                    style: TextStyle(
                      color: _selectedStock.change.startsWith('+')
                          ? Colors.green
                          : Colors.red,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 20),
          SizedBox(
            height: 130,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxPrice + padding,
                minY: maxPrice - (maxPrice * 0.5),
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= _last5DaysDates.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            _last5DaysDates[idx],
                            style: TextStyle(
                              fontSize: 10,
                              color: isDark
                                  ? Colors.white70
                                  : const Color(0xFF1A1A2E),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      },
                      reservedSize: 22,
                    ),
                  ),
                ),
                gridData: FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(_last5DaysPrices.length, (i) {
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: _last5DaysPrices[i],
                        color: isDark
                            ? Colors.white.withOpacity(0.15)
                            : Colors.grey, // Grey Bar Restored
                        width: 32,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentPriceCard(bool isDark) {
    final changeIsPositive = _priceChange.startsWith('+');
    final changeIsNeutral = _priceChange == '-';

    List<FlSpot> spots = [];
    for (int i = 0; i < _last5DaysPrices.length; i++) {
      spots.add(FlSpot(i.toDouble(), _last5DaysPrices[i]));
    }

    double maxPrice = _last5DaysPrices.isNotEmpty
        ? _last5DaysPrices.reduce(max)
        : 100;
    double minPrice = _last5DaysPrices.isNotEmpty
        ? _last5DaysPrices.reduce(min)
        : 0;

    // FIX: Perfect centering for flat lines
    if (maxPrice == minPrice) {
      maxPrice = maxPrice * 1.05;
      minPrice = minPrice * 0.95;
    }
    double padding = (maxPrice - minPrice) * 0.1;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A2D3E) : const Color(0xFFF2F4F7),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CURRENT PRICE',
                    style: TextStyle(
                      fontSize: 11,
                      letterSpacing: 1.4,
                      color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '₦${_currentPrice.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              if (!changeIsNeutral)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: (changeIsPositive ? Colors.green : Colors.red)
                            .withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            changeIsPositive
                                ? Icons.trending_up
                                : Icons.trending_down,
                            color: changeIsPositive ? Colors.green : Colors.red,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _priceChange,
                            style: TextStyle(
                              color: changeIsPositive
                                  ? Colors.green
                                  : Colors.red,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 170,
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: 4,
                minY: minPrice - padding,
                maxY: maxPrice + padding,
                clipData: const FlClipData.all(),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: isDark
                        ? Colors.white.withOpacity(0.08)
                        : Colors.grey.withOpacity(0.15),
                    strokeWidth: 1,
                    dashArray: [5, 5],
                  ),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= _last5DaysDates.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            _last5DaysDates[idx],
                            style: TextStyle(
                              color: isDark
                                  ? Colors.white70
                                  : const Color(0xFF1A1A2E),
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                lineTouchData: LineTouchData(enabled: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    curveSmoothness: 0.35,
                    color: const Color(0xFF2979FF), // Strict Blue Restored
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      checkToShowDot: (spot, _) => spot.x == spots.last.x,
                      getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                        radius: 8,
                        color: isDark ? const Color(0xFF2A2D3E) : Colors.white,
                        strokeWidth: 3,
                        strokeColor: const Color(
                          0xFF2979FF,
                        ), // Strict Blue Restored
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          const Color(0xFF2979FF).withOpacity(0.2),
                          const Color(0xFF2979FF).withOpacity(0.0),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Stock Search Modal
// ─────────────────────────────────────────────
class _StockSearchModal extends StatefulWidget {
  final bool isDark;
  final List<NigerianStock> stocksList; // Takes the dynamically fetched list
  final ValueChanged<NigerianStock> onSelected;

  const _StockSearchModal({
    // ignore: unused_element_parameter
    super.key,
    required this.isDark,
    required this.stocksList,
    required this.onSelected,
  });

  @override
  State<_StockSearchModal> createState() => _StockSearchModalState();
}

class _StockSearchModalState extends State<_StockSearchModal> {
  final TextEditingController _controller = TextEditingController();
  late List<NigerianStock> _filtered;

  @override
  void initState() {
    super.initState();
    _filtered = widget.stocksList; // Initialize with API list
  }

  void _onSearch(String query) {
    setState(() {
      _filtered = widget.stocksList.where((s) {
        final q = query.toLowerCase();
        return s.symbol.toLowerCase().contains(q) ||
            s.name.toLowerCase().contains(q);
      }).toList();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cardColor = widget.isDark ? const Color(0xFF2A2D3E) : Colors.white;
    final bgColor = widget.isDark
        ? const Color(0xFF1A1A2E)
        : const Color(0xFFF2F4F7);
    final textColor = widget.isDark ? Colors.white : const Color(0xFF1A1A2E);

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _controller,
                      onChanged: _onSearch,
                      autofocus: true,
                      style: TextStyle(color: textColor),
                      decoration: InputDecoration(
                        hintText: 'Search symbol or company...',
                        hintStyle: TextStyle(color: Colors.grey[400]),
                        prefixIcon: const Icon(
                          Icons.search,
                          color: Color(0xFF2979FF),
                        ),
                        suffixIcon: _controller.text.isNotEmpty
                            ? GestureDetector(
                                onTap: () {
                                  _controller.clear();
                                  _onSearch('');
                                },
                                child: Icon(
                                  Icons.clear,
                                  color: Colors.grey[400],
                                  size: 18,
                                ),
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 14,
                        ),
                      ),
                    ),
                  ),
                ),

                // RESTORED: The Stock Count Indicator
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 4,
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '${_filtered.length} Live Stocks',
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
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
                      final isPositive = stock.change.startsWith('+');
                      final isNeutral = stock.change == '-';

                      return GestureDetector(
                        onTap: () => widget.onSelected(stock),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
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
                                        fontSize: 14,
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
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '₦${stock.price.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: textColor,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    isNeutral ? stock.marketCap : stock.change,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: isNeutral
                                          ? Colors.grey[500]
                                          : isPositive
                                          ? Colors.green
                                          : Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Dashboard Loading Shimmer
// ─────────────────────────────────────────────
class _DashboardShimmer extends StatelessWidget {
  final AnimationController controller;
  final bool isDark;

  const _DashboardShimmer({required this.controller, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final baseColor = isDark
        ? const Color(0xFF2A2D3E)
        : const Color(0xFFE0E0E0);
    final highlightColor = isDark
        ? const Color(0xFF3A3D4E)
        : const Color(0xFFF5F5F5);
    final cardBg = isDark ? const Color(0xFF2A2D3E) : Colors.white;
    final altCardBg = isDark
        ? const Color(0xFF2A2D3E)
        : const Color(0xFFF2F4F7);

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final shimmer = LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [baseColor, highlightColor, baseColor],
          stops: [
            (controller.value - 0.3).clamp(0.0, 1.0),
            controller.value.clamp(0.0, 1.0),
            (controller.value + 0.3).clamp(0.0, 1.0),
          ],
        );

        Widget box(double w, double h, {double r = 8}) => Container(
          width: w,
          height: h,
          decoration: BoxDecoration(
            gradient: shimmer,
            borderRadius: BorderRadius.circular(r),
          ),
        );

        return Column(
          children: [
            // ── Safety Index Card placeholder ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Container(
                    width: 220,
                    height: 220,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: shimmer,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: 140,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: shimmer,
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Current Price Card placeholder ──
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: altCardBg,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          box(100, 12),
                          const SizedBox(height: 8),
                          box(150, 36),
                        ],
                      ),
                      const Spacer(),
                      box(72, 32),
                    ],
                  ),
                  const SizedBox(height: 20),
                  box(double.infinity, 170),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Last 5 Days Card placeholder ──
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: altCardBg,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  box(80, 12),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      box(120, 32),
                      const SizedBox(width: 8),
                      box(52, 22, r: 4),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      box(32, 80, r: 6),
                      box(32, 110, r: 6),
                      box(32, 65, r: 6),
                      box(32, 95, r: 6),
                      box(32, 75, r: 6),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: List.generate(5, (_) => box(28, 10, r: 3)),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
