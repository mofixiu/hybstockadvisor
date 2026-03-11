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
const Map<String, Map<String, String>> stockMetadata = {
  'AIRTELAFRI': {'name': 'Airtel Africa Plc', 'marketCap': '23.58T'},
  'MTNN': {'name': 'MTN Nigeria Communications PLC', 'marketCap': '16.36T'},
  'BUAFOODS': {'name': 'BUA Foods PLC', 'marketCap': '14.34T'},
  'DANGCEM': {'name': 'Dangote Cement Plc', 'marketCap': '13.57T'},
  'BUACEMENT': {'name': 'BUA Cement Plc', 'marketCap': '7.42T'},
  'ARADEL': {'name': 'Aradel Holdings Plc', 'marketCap': '5.65T'},
  'SEPLAT': {'name': 'Seplat Energy Plc', 'marketCap': '4.81T'},
  'GTCO': {'name': 'Guaranty Trust Holding Company Plc', 'marketCap': '4.35T'},
  'ZENITHBANK': {'name': 'Zenith Bank Plc', 'marketCap': '3.78T'},
  'WAPCO': {'name': 'Lafarge Africa Plc', 'marketCap': '3.38T'},
  'PRESCO': {'name': 'Presco Plc', 'marketCap': '2.70T'},
  'INTBREW': {'name': 'International Breweries Plc', 'marketCap': '2.57T'},
  'NB': {'name': 'Nigerian Breweries Plc', 'marketCap': '2.49T'},
  'NESTLE': {'name': 'Nestlé Nigeria Plc', 'marketCap': '2.46T'},
  'FIRSTHOLDCO': {'name': 'First HoldCo Plc', 'marketCap': '2.36T'},
  'TRANSPOWER': {'name': 'Transcorp Power Plc', 'marketCap': '2.30T'},
  'UBA': {'name': 'United Bank for Africa Plc', 'marketCap': '2.10T'},
  'STANBIC': {'name': 'Stanbic IBTC Holdings PLC', 'marketCap': '2.00T'},
  'TRANSCOHOT': {'name': 'Transcorp Hotels Plc', 'marketCap': '1.94T'},
  'OKOMUOIL': {'name': 'The Okomu Oil Palm Company Plc', 'marketCap': '1.68T'},
  'ACCESSCORP': {'name': 'Access Holdings Plc', 'marketCap': '1.37T'},
  'WEMABANK': {'name': 'Wema Bank PLC', 'marketCap': '1.12T'},
  'DANGSUGAR': {'name': 'Dangote Sugar Refinery Plc', 'marketCap': '907.37B'},
  'GUINNESS': {'name': 'Guinness Nigeria Plc', 'marketCap': '766.63B'},
  'FCMB': {'name': 'FCMB Group Plc', 'marketCap': '582.08B'},
  'NAHCO': {
    'name': 'Nigerian Aviation Handling Company Plc',
    'marketCap': '331.34B',
  },
  'OANDO': {'name': 'Oando PLC', 'marketCap': '729.48B'},
  'UNILEVER': {'name': 'Unilever Nigeria Plc', 'marketCap': '542.20B'},
  'GEREGU': {'name': 'Geregu Power Plc', 'marketCap': '2.85T'},
  'FIDELITYBK': {'name': 'Fidelity Bank Plc', 'marketCap': '1.00T'},
};

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

        String name = stockMetadata[sym]?['name'] ?? '$sym Plc';
        String cap = stockMetadata[sym]?['marketCap'] ?? '--';

        String changeStr = '-';
        if (pct > 0)
          changeStr = '+${pct.toStringAsFixed(2)}%';
        else if (pct < 0)
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
          if (pct > 0)
            changeStr = "+${pct.toStringAsFixed(2)}%";
          else if (pct < 0)
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

        // Fire in-app notifications based on user preferences
        if (mounted) {
          _fireNotifications(
            (todayData['Safety_Index'] as num).toDouble(),
            changeStr,
          );
        }
      }
    } else {
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  Future<void> _fireNotifications(double safetyIdx, String changeStr) async {
    if (!mounted) return;
    final box = await Hive.openBox('user');
    if (!mounted) return;
    final provider = Provider.of<NotificationProvider>(context, listen: false);

    // AI Forecast notification (once per day)
    if (box.get('notif_ai_forecast', defaultValue: true) == true) {
      await provider.addNotification(
        title: 'AI Forecast Updated',
        body: 'New forecast for ${_selectedStock.symbol}: $_recommendation',
        type: NotificationType.aiForecast,
      );
    }

    // Safety Index notification (once per day)
    if (box.get('notif_safety_index', defaultValue: true) == true) {
      await provider.addNotification(
        title: 'Safety Index Update',
        body:
            '${_selectedStock.symbol} safety index: ${safetyIdx.toStringAsFixed(1)} — $_recommendation',
        type: NotificationType.safetyIndex,
      );
    }

    // Price movement notification (only if ≥ 3% change)
    if (box.get('notif_price_movement', defaultValue: true) == true) {
      double pct = 0.0;
      try {
        pct = double.parse(changeStr.replaceAll('%', '').replaceAll('+', ''));
      } catch (_) {}
      if (pct.abs() >= 3.0) {
        await provider.addNotification(
          title: 'Price Movement Alert',
          body: '${_selectedStock.symbol} moved $changeStr today',
          type: NotificationType.priceMovement,
        );
      }
    }
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
                        if (idx < 0 || idx >= _last5DaysDates.length)
                          return const SizedBox.shrink();
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
                        if (idx < 0 || idx >= _last5DaysDates.length)
                          return const SizedBox.shrink();
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
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF2979FF,
                                  ).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Center(
                                  child: Text(
                                    stock.symbol.substring(
                                      0,
                                      min(3, stock.symbol.length),
                                    ),
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF2979FF),
                                    ),
                                  ),
                                ),
                              ),
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
