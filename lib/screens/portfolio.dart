// import 'package:flutter/material.dart';
// import 'package:fl_chart/fl_chart.dart';
// import 'package:hybstockadvisor/widgets/bottomNavBar.dart';

// class Portfolio extends StatefulWidget {
//   const Portfolio({super.key});

//   @override
//   State<Portfolio> createState() => _PortfolioState();
// }

// class _PortfolioState extends State<Portfolio> {
//   // int _selectedFilter = 0;
//   // final List<String> _filters = [
//   //   'All Stocks',
//   //   'Safe Bets',
//   //   'High Growth',
//   //   'Crypto',
//   // ];

//   final List<_StockItem> _stocks = [
//     _StockItem(
//       symbol: 'DANGCEM',
//       name: 'Dangote Cement',
//       price: '\₦809.90',
//       change: '+0.85%',
//       isPositive: true,
//       dotColor: Colors.green,
//       iconBg: const Color(0xFF1C1C1E),
//       iconLabel: '',
//       iconWidget: Icon(Icons.apple, color: Colors.white, size: 20),
//       sparkData: [2.0, 2.5, 2.2, 2.8, 3.0, 2.9, 3.2],
//       sparkColor: Colors.green,
//     ),
//     _StockItem(
//       symbol: 'ARADEL',
//       name: 'ARADEL Holdings PLC',
//       price: '\₦1300.40',
//       change: '-0.12%',
//       isPositive: false,
//       dotColor: Colors.orange,
//       iconBg: const Color(0xFF1C1C1E),
//       iconLabel: 'T',
//       iconWidget: null,
//       sparkData: [3.0, 2.5, 3.2, 2.8, 3.1, 2.7, 2.9],
//       sparkColor: Colors.orange,
//     ),
//     _StockItem(
//       symbol: 'GTCO',
//       name: 'Guaranty Trust',
//       price: '\₦119.00',
//       change: '-2.45%',
//       isPositive: false,
//       dotColor: Colors.red,
//       iconBg: const Color(0xFFEEEEFF),
//       iconLabel: 'GT',
//       iconWidget: null,
//       sparkData: [3.5, 3.2, 2.9, 2.5, 2.2, 2.0, 1.8],
//       sparkColor: Colors.red,
//     ),
//     _StockItem(
//       symbol: 'BUACEMENT',
//       name: 'BUA Cement Plc.',
//       price: '\₦219.18',
//       change: '+4.20%',
//       isPositive: true,
//       dotColor: Colors.green,
//       iconBg: const Color(0xFF1C1C1E),
//       iconLabel: '',
//       iconWidget: Icon(Icons.memory, color: Colors.green, size: 20),
//       sparkData: [1.8, 2.2, 2.5, 2.8, 3.0, 3.3, 3.5],
//       sparkColor: Colors.green,
//     ),
//     _StockItem(
//       symbol: 'SEPLAT',
//       name: 'Seplat Energy PLC',
//       price: '\₦9099.90',
//       change: '-0.85%',
//       isPositive: false,
//       dotColor: Colors.red,
//       iconBg: const Color(0xFFFFF3E0),
//       iconLabel: '₿',
//       iconWidget: null,
//       sparkData: [2.8, 2.5, 2.9, 2.7, 3.0, 2.8, 3.1],
//       sparkColor: Colors.orange,
//     ),
//   ];
//   final List<_StockItem> _watchlist = [
//     _StockItem(
//       symbol: 'DANGCEM',
//       name: 'Dangote Cement',
//       price: '\₦809.90',
//       change: '+0.85%',
//       isPositive: true,
//       dotColor: Colors.green,
//       iconBg: const Color(0xFF1C1C1E),
//       iconLabel: '',
//       iconWidget: Icon(Icons.apple, color: Colors.white, size: 20),
//       sparkData: [2.0, 2.5, 2.2, 2.8, 3.0, 2.9, 3.2],
//       sparkColor: Colors.green,
//     ),
//     _StockItem(
//       symbol: 'ARADEL',
//       name: 'ARADEL Holdings PLC',
//       price: '\₦1300.40',
//       change: '-0.12%',
//       isPositive: false,
//       dotColor: Colors.orange,
//       iconBg: const Color(0xFF1C1C1E),
//       iconLabel: 'T',
//       iconWidget: null,
//       sparkData: [3.0, 2.5, 3.2, 2.8, 3.1, 2.7, 2.9],
//       sparkColor: Colors.orange,
//     ),
//     _StockItem(
//       symbol: 'GTCO',
//       name: 'Guaranty Trust',
//       price: '\₦119.00',
//       change: '-2.45%',
//       isPositive: false,
//       dotColor: Colors.red,
//       iconBg: const Color(0xFFEEEEFF),
//       iconLabel: 'GT',
//       iconWidget: null,
//       sparkData: [3.5, 3.2, 2.9, 2.5, 2.2, 2.0, 1.8],
//       sparkColor: Colors.red,
//     ),
//     _StockItem(
//       symbol: 'BUACEMENT',
//       name: 'BUA Cement Plc.',
//       price: '\₦219.18',
//       change: '+4.20%',
//       isPositive: true,
//       dotColor: Colors.green,
//       iconBg: const Color(0xFF1C1C1E),
//       iconLabel: '',
//       iconWidget: Icon(Icons.memory, color: Colors.green, size: 20),
//       sparkData: [1.8, 2.2, 2.5, 2.8, 3.0, 3.3, 3.5],
//       sparkColor: Colors.green,
//     ),
//     _StockItem(
//       symbol: 'SEPLAT',
//       name: 'Seplat Energy PLC',
//       price: '\₦9099.90',
//       change: '-0.85%',
//       isPositive: false,
//       dotColor: Colors.red,
//       iconBg: const Color(0xFFFFF3E0),
//       iconLabel: '₿',
//       iconWidget: null,
//       sparkData: [2.8, 2.5, 2.9, 2.7, 3.0, 2.8, 3.1],
//       sparkColor: Colors.orange,
//     ),
//   ];

//   @override
//   Widget build(BuildContext context) {
//     final isDark = Theme.of(context).brightness == Brightness.dark;
//     final bgColor = isDark ? const Color(0xFF1A1A2E) : const Color(0xFFF2F4F7);
//     final cardColor = isDark ? const Color(0xFF2A2D3E) : Colors.white;
//     final textColor = isDark ? Colors.white : const Color(0xFF1A1A2E);

//     return Scaffold(
//       backgroundColor: bgColor,
//       bottomNavigationBar: const BottomNavBar(currentIndex: 2),
//       body: SafeArea(
//         child: CustomScrollView(
//           slivers: [
//             // ── Header ──
//             SliverToBoxAdapter(
//               child: Padding(
//                 padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
//                 child: Row(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(
//                           'Portfolio',
//                           style: TextStyle(
//                             fontSize: 26,
//                             fontWeight: FontWeight.bold,
//                             color: textColor,
//                           ),
//                         ),
//                         Text(
//                           'HybStockAdvisor',
//                           style: TextStyle(
//                             fontSize: 13,
//                             color: const Color(0xFF2979FF),
//                             fontWeight: FontWeight.w500,
//                           ),
//                         ),
//                       ],
//                     ),
//                     const Spacer(),
//                     Container(
//                       width: 40,
//                       height: 40,
//                       decoration: BoxDecoration(
//                         color: cardColor,
//                         shape: BoxShape.circle,
//                         boxShadow: [
//                           BoxShadow(
//                             color: Colors.black.withOpacity(0.07),
//                             blurRadius: 6,
//                             offset: const Offset(0, 2),
//                           ),
//                         ],
//                       ),
//                       child: Icon(
//                         Icons.add,
//                         color: const Color(0xFF2979FF),
//                         size: 22,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),

//             // ── Search Bar ──
//             SliverToBoxAdapter(
//               child: Padding(
//                 padding: const EdgeInsets.symmetric(
//                   horizontal: 20,
//                   vertical: 14,
//                 ),
//                 child: Container(
//                   padding: const EdgeInsets.symmetric(
//                     horizontal: 16,
//                     vertical: 12,
//                   ),
//                   decoration: BoxDecoration(
//                     color: cardColor,
//                     borderRadius: BorderRadius.circular(14),
//                     boxShadow: [
//                       BoxShadow(
//                         color: Colors.black.withOpacity(0.05),
//                         blurRadius: 6,
//                         offset: const Offset(0, 2),
//                       ),
//                     ],
//                   ),
//                   child: Row(
//                     children: [
//                       Icon(Icons.search, color: Colors.grey[400], size: 20),
//                       const SizedBox(width: 10),
//                       Text(
//                         'Search symbol, company...',
//                         style: TextStyle(color: Colors.grey[400], fontSize: 14),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ),

//             // // ── Filter Chips ──
//             // SliverToBoxAdapter(
//             //   child: SizedBox(
//             //     height: 40,
//             //     child: ListView.separated(
//             //       scrollDirection: Axis.horizontal,
//             //       padding: const EdgeInsets.symmetric(horizontal: 20),
//             //       itemCount: _filters.length,
//             //       separatorBuilder: (_, __) => const SizedBox(width: 10),
//             //       itemBuilder: (context, i) {
//             //         final selected = _selectedFilter == i;
//             //         return GestureDetector(
//             //           onTap: () => setState(() => _selectedFilter = i),
//             //           child: AnimatedContainer(
//             //             duration: const Duration(milliseconds: 200),
//             //             padding: const EdgeInsets.symmetric(
//             //               horizontal: 18,
//             //               vertical: 8,
//             //             ),
//             //             decoration: BoxDecoration(
//             //               color: selected ? Color(0xFF0A3D62) : cardColor,
//             //               borderRadius: BorderRadius.circular(20),
//             //               boxShadow: [
//             //                 BoxShadow(
//             //                   color: Colors.black.withOpacity(0.05),
//             //                   blurRadius: 4,
//             //                 ),
//             //               ],
//             //             ),
//             //             child: Text(
//             //               _filters[i],
//             //               style: TextStyle(
//             //                 color: selected ? Colors.white : Colors.grey[500],
//             //                 fontWeight: selected
//             //                     ? FontWeight.bold
//             //                     : FontWeight.normal,
//             //                 fontSize: 13,
//             //               ),
//             //             ),
//             //           ),
//             //         );
//             //       },
//             //     ),
//             //   ),
//             // ),
//             // const SliverToBoxAdapter(child: SizedBox(height: 16)),

//             // // ── Portfolio Health Card ──
//             // SliverToBoxAdapter(
//             //   child: Padding(
//             //     padding: const EdgeInsets.symmetric(horizontal: 20),
//             //     child: Container(
//             //       padding: const EdgeInsets.all(20),
//             //       decoration: BoxDecoration(
//             //         color: cardColor,
//             //         borderRadius: BorderRadius.circular(18),
//             //         boxShadow: [
//             //           BoxShadow(
//             //             color: Colors.black.withOpacity(0.06),
//             //             blurRadius: 8,
//             //             offset: const Offset(0, 2),
//             //           ),
//             //         ],
//             //       ),
//             //       child: Row(
//             //         children: [
//             //           Expanded(
//             //             child: Column(
//             //               crossAxisAlignment: CrossAxisAlignment.start,
//             //               children: [
//             //                 Text(
//             //                   'PORTFOLIO HEALTH',
//             //                   style: TextStyle(
//             //                     fontSize: 10,
//             //                     letterSpacing: 1.2,
//             //                     color: Colors.grey[500],
//             //                     fontWeight: FontWeight.w600,
//             //                   ),
//             //                 ),
//             //                 const SizedBox(height: 6),
//             //                 Text(
//             //                   '\$24,593.00',
//             //                   style: TextStyle(
//             //                     fontSize: 26,
//             //                     fontWeight: FontWeight.bold,
//             //                     color: textColor,
//             //                   ),
//             //                 ),
//             //                 const SizedBox(height: 8),
//             //                 Row(
//             //                   children: [
//             //                     Container(
//             //                       padding: const EdgeInsets.symmetric(
//             //                         horizontal: 8,
//             //                         vertical: 4,
//             //                       ),
//             //                       decoration: BoxDecoration(
//             //                         color: Colors.green.withOpacity(0.12),
//             //                         borderRadius: BorderRadius.circular(6),
//             //                       ),
//             //                       child: Row(
//             //                         children: const [
//             //                           Icon(
//             //                             Icons.trending_up,
//             //                             color: Colors.green,
//             //                             size: 13,
//             //                           ),
//             //                           SizedBox(width: 4),
//             //                           Text(
//             //                             '+1.2%',
//             //                             style: TextStyle(
//             //                               color: Colors.green,
//             //                               fontSize: 12,
//             //                               fontWeight: FontWeight.bold,
//             //                             ),
//             //                           ),
//             //                         ],
//             //                       ),
//             //                     ),
//             //                     const SizedBox(width: 8),
//             //                     Text(
//             //                       'Today',
//             //                       style: TextStyle(
//             //                         color: Colors.grey[500],
//             //                         fontSize: 12,
//             //                       ),
//             //                     ),
//             //                   ],
//             //                 ),
//             //               ],
//             //             ),
//             //           ),
//             //           // Mini sparkline
//             //           SizedBox(
//             //             width: 110,
//             //             height: 60,
//             //             child: LineChart(
//             //               LineChartData(
//             //                 minX: 0,
//             //                 maxX: 6,
//             //                 minY: 0,
//             //                 maxY: 5,
//             //                 gridData: FlGridData(show: false),
//             //                 borderData: FlBorderData(show: false),
//             //                 titlesData: FlTitlesData(
//             //                   leftTitles: AxisTitles(
//             //                     sideTitles: SideTitles(showTitles: false),
//             //                   ),
//             //                   rightTitles: AxisTitles(
//             //                     sideTitles: SideTitles(showTitles: false),
//             //                   ),
//             //                   topTitles: AxisTitles(
//             //                     sideTitles: SideTitles(showTitles: false),
//             //                   ),
//             //                   bottomTitles: AxisTitles(
//             //                     sideTitles: SideTitles(showTitles: false),
//             //                   ),
//             //                 ),
//             //                 lineTouchData: LineTouchData(enabled: false),
//             //                 lineBarsData: [
//             //                   LineChartBarData(
//             //                     spots: const [
//             //                       FlSpot(0, 2.0),
//             //                       FlSpot(1, 2.8),
//             //                       FlSpot(2, 2.3),
//             //                       FlSpot(3, 3.2),
//             //                       FlSpot(4, 2.7),
//             //                       FlSpot(5, 3.8),
//             //                       FlSpot(6, 3.5),
//             //                     ],
//             //                     isCurved: true,
//             //                     color: const Color(0xFF2979FF),
//             //                     barWidth: 2.5,
//             //                     isStrokeCapRound: true,
//             //                     dotData: FlDotData(show: false),
//             //                     belowBarData: BarAreaData(
//             //                       show: true,
//             //                       gradient: LinearGradient(
//             //                         begin: Alignment.topCenter,
//             //                         end: Alignment.bottomCenter,
//             //                         colors: [
//             //                           const Color(0xFF2979FF).withOpacity(0.18),
//             //                           const Color(0xFF2979FF).withOpacity(0.0),
//             //                         ],
//             //                       ),
//             //                     ),
//             //                   ),
//             //                 ],
//             //               ),
//             //             ),
//             //           ),
//             //         ],
//             //       ),
//             //     ),
//             //   ),
//             // ),
//             const SliverToBoxAdapter(child: SizedBox(height: 24)),

//             // ── Your Stocks Header ──
//             SliverToBoxAdapter(
//               child: Padding(
//                 padding: const EdgeInsets.symmetric(horizontal: 20),
//                 child: Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     Text(
//                       'Your Stocks',
//                       style: TextStyle(
//                         fontSize: 18,
//                         fontWeight: FontWeight.bold,
//                         color: textColor,
//                       ),
//                     ),
//                     Text(
//                       'Sort by',
//                       style: TextStyle(
//                         fontSize: 13,
//                         color: const Color(0xFF2979FF),
//                         fontWeight: FontWeight.w500,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),

//             const SliverToBoxAdapter(child: SizedBox(height: 12)),

//             // ── Stock List ──
//             SliverList(
//               delegate: SliverChildBuilderDelegate((context, index) {
//                 final stock = _stocks[index];
//                 return Padding(
//                   padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
//                   child: _StockCard(
//                     stock: stock,
//                     isDark: isDark,
//                     cardColor: cardColor,
//                     textColor: textColor,
//                   ),
//                 );
//               }, childCount: _stocks.length),
//             ),

//             const SliverToBoxAdapter(child: SizedBox(height: 12)),
//             // ── Your Watchlist Header ──
//             SliverToBoxAdapter(
//               child: Padding(
//                 padding: const EdgeInsets.symmetric(horizontal: 20),
//                 child: Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     Text(
//                       'Your Watchlist',
//                       style: TextStyle(
//                         fontSize: 18,
//                         fontWeight: FontWeight.bold,
//                         color: textColor,
//                       ),
//                     ),
//                     Text(
//                       'Sort by',
//                       style: TextStyle(
//                         fontSize: 13,
//                         color: const Color(0xFF2979FF),
//                         fontWeight: FontWeight.w500,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),

//             const SliverToBoxAdapter(child: SizedBox(height: 12)),

//             // ── Watch List ──
//             SliverList(
//               delegate: SliverChildBuilderDelegate((context, index) {
//                 final stock = _watchlist[index];
//                 return Padding(
//                   padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
//                   child: _StockCard(
//                     stock: stock,
//                     isDark: isDark,
//                     cardColor: cardColor,
//                     textColor: textColor,
//                   ),
//                 );
//               }, childCount: _watchlist.length),
//             ),

//             const SliverToBoxAdapter(child: SizedBox(height: 12)),
//           ],
//         ),
//       ),
//     );
//   }
// }

// // ─────────────────────────────────────────────
// // Stock Card
// // ─────────────────────────────────────────────
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
//             child: stock.iconWidget != null
//                 ? Center(child: stock.iconWidget)
//                 : Center(
//                     child: Text(
//                       stock.iconLabel,
//                       style: TextStyle(
//                         fontWeight: FontWeight.bold,
//                         fontSize: stock.iconLabel.length > 1 ? 13 : 16,
//                         color: stock.iconBg == const Color(0xFFEEEEFF)
//                             ? const Color(0xFF2979FF)
//                             : stock.iconBg == const Color(0xFFFFF3E0)
//                             ? Colors.orange
//                             : Colors.white,
//                       ),
//                     ),
//                   ),
//           ),

//           const SizedBox(width: 12),

//           // Symbol + Name + dot
//           Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Row(
//                 children: [
//                   Text(
//                     stock.symbol,
//                     style: TextStyle(
//                       fontWeight: FontWeight.bold,
//                       fontSize: 15,
//                       color: textColor,
//                     ),
//                   ),
//                   const SizedBox(width: 6),
//                   Container(
//                     width: 7,
//                     height: 7,
//                     decoration: BoxDecoration(
//                       color: stock.dotColor,
//                       shape: BoxShape.circle,
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 2),
//               Text(
//                 stock.name,
//                 style: TextStyle(fontSize: 12, color: Colors.grey[500]),
//               ),
//             ],
//           ),

//           const SizedBox(width: 10),

//           // Sparkline
//           Expanded(
//             child: SizedBox(
//               height: 40,
//               child: LineChart(
//                 LineChartData(
//                   minX: 0,
//                   maxX: 6,
//                   minY: 0,
//                   maxY: 5,
//                   gridData: FlGridData(show: false),
//                   borderData: FlBorderData(show: false),
//                   titlesData: FlTitlesData(
//                     leftTitles: AxisTitles(
//                       sideTitles: SideTitles(showTitles: false),
//                     ),
//                     rightTitles: AxisTitles(
//                       sideTitles: SideTitles(showTitles: false),
//                     ),
//                     topTitles: AxisTitles(
//                       sideTitles: SideTitles(showTitles: false),
//                     ),
//                     bottomTitles: AxisTitles(
//                       sideTitles: SideTitles(showTitles: false),
//                     ),
//                   ),
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

// // ─────────────────────────────────────────────
// // Data model
// // ─────────────────────────────────────────────
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
// import 'dart:math';

// import 'package:flutter/material.dart';
// import 'package:fl_chart/fl_chart.dart';
// import 'package:hybstockadvisor/widgets/bottomNavBar.dart';
// import 'package:hybstockadvisor/services/api_service.dart';

// // Your static metadata map (copied from dashboard so we can get company names)
// const Map<String, Map<String, String>> stockMetadata = {
//   'AIRTELAFRI': {'name': 'Airtel Africa Plc'},
//   'MTNN': {'name': 'MTN Nigeria Communications PLC'},
//   'BUAFOODS': {'name': 'BUA Foods PLC'},
//   'DANGCEM': {'name': 'Dangote Cement Plc'},
//   'BUACEMENT': {'name': 'BUA Cement Plc'},
//   'ARADEL': {'name': 'Aradel Holdings Plc'},
//   'SEPLAT': {'name': 'Seplat Energy Plc'},
//   'GTCO': {'name': 'Guaranty Trust Holding Company Plc'},
//   'ZENITHBANK': {'name': 'Zenith Bank Plc'},
//   'WAPCO': {'name': 'Lafarge Africa Plc'},
//   'PRESCO': {'name': 'Presco Plc'},
//   'INTBREW': {'name': 'International Breweries Plc'},
//   'NB': {'name': 'Nigerian Breweries Plc'},
//   'NESTLE': {'name': 'Nestlé Nigeria Plc'},
//   'FIRSTHOLDCO': {'name': 'First HoldCo Plc'},
//   'TRANSPOWER': {'name': 'Transcorp Power Plc'},
//   'UBA': {'name': 'United Bank for Africa Plc'},
//   'STANBIC': {'name': 'Stanbic IBTC Holdings PLC'},
//   'TRANSCOHOT': {'name': 'Transcorp Hotels Plc'},
//   'OKOMUOIL': {'name': 'The Okomu Oil Palm Company Plc'},
//   'ACCESSCORP': {'name': 'Access Holdings Plc'},
//   'WEMABANK': {'name': 'Wema Bank PLC'},
//   'DANGSUGAR': {'name': 'Dangote Sugar Refinery Plc'},
//   'GUINNESS': {'name': 'Guinness Nigeria Plc'},
//   'FCMB': {'name': 'FCMB Group Plc'},
//   'NAHCO': {'name': 'Nigerian Aviation Handling Company Plc'},
//   'OANDO': {'name': 'Oando PLC'},
//   'UNILEVER': {'name': 'Unilever Nigeria Plc'},
// };

// class Portfolio extends StatefulWidget {
//   const Portfolio({super.key});

//   @override
//   State<Portfolio> createState() => _PortfolioState();
// }

// class _PortfolioState extends State<Portfolio> {
//   bool _isLoading = true;
//   List<_StockItem> _portfolioStocks = [];
//   List<_StockItem> _watchlistStocks = [];

//   @override
//   void initState() {
//     super.initState();
//     _fetchUserAssets();
//   }

//   Future<void> _fetchUserAssets() async {
//     setState(() => _isLoading = true);

//     final data = await ApiService.getUserAssets();

//     if (data != null) {
//       List<_StockItem> parsedPortfolio = [];
//       List<_StockItem> parsedWatchlist = [];

//       // Parse Portfolio
//       for (var item in data['portfolio']) {
//         parsedPortfolio.add(_buildUIStockItem(item));
//       }

//       // Parse Watchlist
//       for (var item in data['watchlist']) {
//         parsedWatchlist.add(_buildUIStockItem(item));
//       }

//       setState(() {
//         _portfolioStocks = parsedPortfolio;
//         _watchlistStocks = parsedWatchlist;
//         _isLoading = false;
//       });
//     } else {
//       setState(() => _isLoading = false);
//     }
//   }

//   // Helper function to map API Data to your beautiful UI layout
//   _StockItem _buildUIStockItem(dynamic item) {
//     String symbol = item['ticker'];
//     String name = stockMetadata[symbol]?['name'] ?? '$symbol Plc';
//     double price = (item['live_price'] as num).toDouble();
//     double changePct = (item['change_pct'] as num).toDouble();

//     // Parse the Sparkline data sent by Python
//     List<dynamic> rawSpark = item['spark_data'] ?? [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0];
//     List<double> spark = rawSpark.map((e) => (e as num).toDouble()).toList();

//     bool isPositive = changePct >= 0;
//     String changeStr = changePct == 0.0 ? "-" : "${isPositive ? '+' : ''}${changePct.toStringAsFixed(2)}%";

//     return _StockItem(
//       symbol: symbol,
//       name: name,
//       price: '₦${price.toStringAsFixed(2)}',
//       change: changeStr,
//       isPositive: isPositive,
//       dotColor: isPositive ? Colors.green : Colors.red,
//       iconBg: const Color(0xFF1C1C1E), // Default dark icon bg
//       iconLabel: symbol.substring(0, min(2, symbol.length)),
//       iconWidget: null,
//       sparkData: spark,
//       sparkColor: isPositive ? Colors.green : Colors.red,
//     );
//   }

//   // ── The Bottom Sheet for the '+' Icon ──
//   void _showAddActionSheet(bool isDark) {
//     showModalBottomSheet(
//       context: context,
//       backgroundColor: Colors.transparent,
//       builder: (context) => Container(
//         padding: const EdgeInsets.all(24),
//         decoration: BoxDecoration(
//           color: isDark ? const Color(0xFF2A2D3E) : Colors.white,
//           borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
//         ),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               'Add New Asset',
//               style: TextStyle(
//                 fontSize: 20,
//                 fontWeight: FontWeight.bold,
//                 color: isDark ? Colors.white : const Color(0xFF1A1A2E),
//               ),
//             ),
//             const SizedBox(height: 20),
//             ListTile(
//               leading: Container(
//                 padding: const EdgeInsets.all(10),
//                 decoration: BoxDecoration(
//                   color: const Color(0xFF2979FF).withOpacity(0.1),
//                   shape: BoxShape.circle,
//                 ),
//                 child: const Icon(Icons.pie_chart, color: Color(0xFF2979FF)),
//               ),
//               title: const Text('Add to Portfolio', style: TextStyle(fontWeight: FontWeight.w600)),
//               subtitle: const Text('Track stocks you currently own', style: TextStyle(fontSize: 12)),
//               onTap: () {
//                 Navigator.pop(context);
//                 // TODO: Open your Stock Picker Modal here, then call ApiService.addToPortfolio
//               },
//             ),
//             const Divider(),
//             ListTile(
//               leading: Container(
//                 padding: const EdgeInsets.all(10),
//                 decoration: BoxDecoration(
//                   color: Colors.orange.withOpacity(0.1),
//                   shape: BoxShape.circle,
//                 ),
//                 child: const Icon(Icons.visibility, color: Colors.orange),
//               ),
//               title: const Text('Add to Watchlist', style: TextStyle(fontWeight: FontWeight.w600)),
//               subtitle: const Text('Monitor stocks without buying', style: TextStyle(fontSize: 12)),
//               onTap: () {
//                 Navigator.pop(context);
//                 // TODO: Open your Stock Picker Modal here, then call ApiService.addToWatchlist
//               },
//             ),
//             const SizedBox(height: 20),
//           ],
//         ),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final isDark = Theme.of(context).brightness == Brightness.dark;
//     final bgColor = isDark ? const Color(0xFF1A1A2E) : const Color(0xFFF2F4F7);
//     final cardColor = isDark ? const Color(0xFF2A2D3E) : Colors.white;
//     final textColor = isDark ? Colors.white : const Color(0xFF1A1A2E);

//     return Scaffold(
//       backgroundColor: bgColor,
//       bottomNavigationBar: const BottomNavBar(currentIndex: 2),
//       body: SafeArea(
//         child: _isLoading
//         ? const Center(child: CircularProgressIndicator(color: Color(0xFF2979FF)))
//         : CustomScrollView(
//           slivers: [
//             // ── Header ──
//             SliverToBoxAdapter(
//               child: Padding(
//                 padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
//                 child: Row(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(
//                           'Portfolio',
//                           style: TextStyle(
//                             fontSize: 26,
//                             fontWeight: FontWeight.bold,
//                             color: textColor,
//                           ),
//                         ),
//                         const Text(
//                           'HybStockAdvisor',
//                           style: TextStyle(
//                             fontSize: 13,
//                             color: Color(0xFF2979FF),
//                             fontWeight: FontWeight.w500,
//                           ),
//                         ),
//                       ],
//                     ),
//                     const Spacer(),
//                     GestureDetector(
//                       onTap: () => _showAddActionSheet(isDark),
//                       child: Container(
//                         width: 40,
//                         height: 40,
//                         decoration: BoxDecoration(
//                           color: cardColor,
//                           shape: BoxShape.circle,
//                           boxShadow: [
//                             BoxShadow(
//                               color: Colors.black.withOpacity(0.07),
//                               blurRadius: 6,
//                               offset: const Offset(0, 2),
//                             ),
//                           ],
//                         ),
//                         child: const Icon(
//                           Icons.add,
//                           color: Color(0xFF2979FF),
//                           size: 22,
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),

//             // ── Search Bar ──
//             SliverToBoxAdapter(
//               child: Padding(
//                 padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
//                 child: Container(
//                   padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//                   decoration: BoxDecoration(
//                     color: cardColor,
//                     borderRadius: BorderRadius.circular(14),
//                     boxShadow: [
//                       BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6, offset: const Offset(0, 2)),
//                     ],
//                   ),
//                   child: Row(
//                     children: [
//                       Icon(Icons.search, color: Colors.grey[400], size: 20),
//                       const SizedBox(width: 10),
//                       Text(
//                         'Search symbol, company...',
//                         style: TextStyle(color: Colors.grey[400], fontSize: 14),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ),

//             const SliverToBoxAdapter(child: SizedBox(height: 12)),

//             // ── Your Stocks Header ──
//             SliverToBoxAdapter(
//               child: Padding(
//                 padding: const EdgeInsets.symmetric(horizontal: 20),
//                 child: Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     Text('Your Stocks', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
//                     const Text('Sort by', style: TextStyle(fontSize: 13, color: Color(0xFF2979FF), fontWeight: FontWeight.w500)),
//                   ],
//                 ),
//               ),
//             ),

//             const SliverToBoxAdapter(child: SizedBox(height: 12)),

//             // ── Stock List (Portfolio) ──
//             if (_portfolioStocks.isEmpty)
//                SliverToBoxAdapter(
//                 child: Padding(
//                   padding: const EdgeInsets.all(20.0),
//                   child: Center(
//                     child: Text("No stocks in portfolio.", style: TextStyle(color: Colors.grey[500])),
//                   ),
//                 ),
//               )
//             else
//               SliverList(
//                 delegate: SliverChildBuilderDelegate((context, index) {
//                   final stock = _portfolioStocks[index];
//                   return Padding(
//                     padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
//                     child: _StockCard(stock: stock, isDark: isDark, cardColor: cardColor, textColor: textColor),
//                   );
//                 }, childCount: _portfolioStocks.length),
//               ),

//             const SliverToBoxAdapter(child: SizedBox(height: 24)),

//             // ── Your Watchlist Header ──
//             SliverToBoxAdapter(
//               child: Padding(
//                 padding: const EdgeInsets.symmetric(horizontal: 20),
//                 child: Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     Text('Your Watchlist', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
//                     const Text('Sort by', style: TextStyle(fontSize: 13, color: Color(0xFF2979FF), fontWeight: FontWeight.w500)),
//                   ],
//                 ),
//               ),
//             ),

//             const SliverToBoxAdapter(child: SizedBox(height: 12)),

//             // ── Watch List ──
//             if (_watchlistStocks.isEmpty)
//                SliverToBoxAdapter(
//                 child: Padding(
//                   padding: const EdgeInsets.all(20.0),
//                   child: Center(
//                     child: Text("Watchlist is empty.", style: TextStyle(color: Colors.grey[500])),
//                   ),
//                 ),
//               )
//             else
//               SliverList(
//                 delegate: SliverChildBuilderDelegate((context, index) {
//                   final stock = _watchlistStocks[index];
//                   return Padding(
//                     padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
//                     child: _StockCard(stock: stock, isDark: isDark, cardColor: cardColor, textColor: textColor),
//                   );
//                 }, childCount: _watchlistStocks.length),
//               ),

//             const SliverToBoxAdapter(child: SizedBox(height: 12)),
//           ],
//         ),
//       ),
//     );
//   }
// }

// // ─────────────────────────────────────────────
// // Stock Card
// // ─────────────────────────────────────────────
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

//     // Dynamic chart scaling
//     double maxPrice = stock.sparkData.isNotEmpty ? stock.sparkData.reduce((curr, next) => curr > next ? curr : next) : 100;
//     double minPrice = stock.sparkData.isNotEmpty ? stock.sparkData.reduce((curr, next) => curr < next ? curr : next) : 0;
//     if (maxPrice == minPrice) {
//       maxPrice = maxPrice * 1.05;
//       minPrice = minPrice * 0.95;
//     }
//     double padding = (maxPrice - minPrice) * 0.2;

//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
//       decoration: BoxDecoration(
//         color: cardColor,
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: [
//           BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6, offset: const Offset(0, 2)),
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
//             child: stock.iconWidget != null
//                 ? Center(child: stock.iconWidget)
//                 : Center(
//                     child: Text(
//                       stock.iconLabel,
//                       style: TextStyle(
//                         fontWeight: FontWeight.bold,
//                         fontSize: stock.iconLabel.length > 1 ? 13 : 16,
//                         color: Colors.white,
//                       ),
//                     ),
//                   ),
//           ),

//           const SizedBox(width: 12),

//           // Symbol + Name + dot
//           Expanded( // Added Expanded so long company names don't overflow
//             flex: 2,
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Row(
//                   children: [
//                     Text(
//                       stock.symbol,
//                       style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: textColor),
//                     ),
//                     const SizedBox(width: 6),
//                     Container(width: 7, height: 7, decoration: BoxDecoration(color: stock.dotColor, shape: BoxShape.circle)),
//                   ],
//                 ),
//                 const SizedBox(height: 2),
//                 Text(stock.name, style: TextStyle(fontSize: 12, color: Colors.grey[500]), overflow: TextOverflow.ellipsis),
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
//                   maxX: 6,
//                   minY: minPrice - padding,
//                   maxY: maxPrice + padding,
//                   gridData: FlGridData(show: false),
//                   borderData: FlBorderData(show: false),
//                   titlesData: FlTitlesData(
//                     leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
//                     rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
//                     topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
//                     bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
//                   ),
//                   lineTouchData: LineTouchData(enabled: false),
//                   lineBarsData: [
//                     LineChartBarData(
//                       spots: stock.sparkData.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList(),
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
//                 style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textColor),
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

// // ─────────────────────────────────────────────
// // Data model
// // ─────────────────────────────────────────────
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
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:hive/hive.dart';
import 'package:hybstockadvisor/widgets/ai_chat_sheet.dart';
import 'package:provider/provider.dart';
import 'package:text_scroll/text_scroll.dart';
import 'package:hybstockadvisor/widgets/bottomNavBar.dart';
import 'package:hybstockadvisor/services/api_service.dart';
import 'dart:math';

import 'package:hybstockadvisor/models/app_notification.dart';
import 'package:hybstockadvisor/providers/notification_provider.dart';
// We import Dashboard to access NigerianStock model and default lists
import 'package:hybstockadvisor/screens/dashboard.dart';

class Portfolio extends StatefulWidget {
  const Portfolio({super.key});

  @override
  State<Portfolio> createState() => _PortfolioState();
}

class _PortfolioState extends State<Portfolio> {
  bool _isLoading = true;
  List<_StockItem> _portfolioStocks = [];
  List<_StockItem> _watchlistStocks = [];
  List<NigerianStock> _availableMarketStocks = [];
  // int? _lastLoadedUserId;
  @override
  void initState() {
    super.initState();
    _fetchInitialData();
  }

  Future<void> _fetchInitialData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    // 1. Fetch Market Summary for the Search Modal
    final summaryRes = await ApiService.getMarketSummary();
    if (!mounted) return;
    if (summaryRes != null && summaryRes['status'] == 'success') {
      List<dynamic> rawList = summaryRes['data'];
      _availableMarketStocks = rawList.map((item) {
        String sym = item['symbol'];
        return NigerianStock(
          symbol: sym,
          name: '$sym Plc', // Fallback name
          marketCap: '--',
          price: (item['price'] as num).toDouble(),
          change:
              ((item['change_pct'] as num).toDouble() >= 0 ? '+' : '') +
              (item['change_pct'] as num).toDouble().toStringAsFixed(2) +
              '%',
        );
      }).toList();
    } else {
      _availableMarketStocks = [];
    }

    // 2. Fetch User's actual Portfolio & Watchlist from DB
    await _refreshUserAssets();
  }

  Future<void> _refreshUserAssets() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    final data = await ApiService.getUserAssets();

    if (!mounted) return;
    if (data != null) {
      final portfolioItems = (data['portfolio'] as List)
          .map((item) => _buildUIStockItem(item, isPortfolio: true))
          .toList();
      final watchlistItems = (data['watchlist'] as List)
          .map((item) => _buildUIStockItem(item, isPortfolio: false))
          .toList();

      setState(() {
        _portfolioStocks = portfolioItems;
        _watchlistStocks = watchlistItems;
        _isLoading = false;
      });

      // Fire price movement notifications for portfolio stocks with ≥3% change
      if (mounted) {
        _firePortfolioNotifications(portfolioItems, data['portfolio'] as List);
      }
    } else {
      if (mounted) setState(() => _isLoading = false);
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
        );
      }
    }
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
    List<String> alreadySelected = isPortfolio
        ? _portfolioStocks.map((e) => e.symbol).toList()
        : _watchlistStocks.map((e) => e.symbol).toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _StockPickerModal(
        isDark: isDark,
        stocksList: _availableMarketStocks,
        alreadySelected: alreadySelected,
        onSelected: (stock) async {
          Navigator.pop(context); // Close picker

          if (isPortfolio) {
            _showQuantityDialog(stock, isDark);
          } else {
            // Add to Watchlist Directly
            setState(() => _isLoading = true);
            final res = await ApiService.addToWatchlist(ticker: stock.symbol);
            if (res['status'] == 'success') {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${stock.symbol} added to Watchlist!'),
                  backgroundColor: Colors.green,
                ),
              );
              _refreshUserAssets();
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(res['detail'] ?? 'Error'),
                  backgroundColor: Colors.red,
                ),
              );
              setState(() => _isLoading = false);
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
              setState(() => _isLoading = true);

              final res = await ApiService.addToPortfolio(
                ticker: stock.symbol,
                quantity: qty,
                avgBuyPrice: price,
              );

              if (res['status'] == 'success') {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${stock.symbol} added to Portfolio!'),
                    backgroundColor: Colors.green,
                  ),
                );
                _refreshUserAssets();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(res['detail'] ?? 'Error'),
                    backgroundColor: Colors.red,
                  ),
                );
                setState(() => _isLoading = false);
              }
            },
            child: const Text('Add', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1A1A2E) : const Color(0xFFF2F4F7);
    final cardColor = isDark ? const Color(0xFF2A2D3E) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A2E);

    return Scaffold(
      backgroundColor: bgColor,
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF0A3D62),
        child: const Icon(Icons.auto_awesome, color: Colors.white),
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => AiChatSheet(isDark: isDark),
          );
        },
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 2),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF0A3D62)),
              )
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
                          const Text(
                            'Sort by',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF0A3D62),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 12)),

                  // ── Stock List (Portfolio) ──
                  if (_portfolioStocks.isEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Center(
                          child: Text(
                            "No stocks in portfolio.",
                            style: TextStyle(color: Colors.grey[500]),
                          ),
                        ),
                      ),
                    )
                  else
                    SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final stock = _portfolioStocks[index];
                        return Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                          child: _StockCard(
                            stock: stock,
                            isDark: isDark,
                            cardColor: cardColor,
                            textColor: textColor,
                          ),
                        );
                      }, childCount: _portfolioStocks.length),
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
                          const Text(
                            'Sort by',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF0A3D62),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 12)),

                  // ── Watch List ──
                  if (_watchlistStocks.isEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Center(
                          child: Text(
                            "Watchlist is empty.",
                            style: TextStyle(color: Colors.grey[500]),
                          ),
                        ),
                      ),
                    )
                  else
                    SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final stock = _watchlistStocks[index];
                        return Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                          child: _StockCard(
                            stock: stock,
                            isDark: isDark,
                            cardColor: cardColor,
                            textColor: textColor,
                          ),
                        );
                      }, childCount: _watchlistStocks.length),
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
// Stock Card (With Auto-Scrolling Text)
// ─────────────────────────────────────────────
class _StockCard extends StatelessWidget {
  final _StockItem stock;
  final bool isDark;
  final Color cardColor;
  final Color textColor;

  const _StockCard({
    required this.stock,
    required this.isDark,
    required this.cardColor,
    required this.textColor,
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
          // Icon
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: stock.iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                stock.iconLabel,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.white,
                ),
              ),
            ),
          ),
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
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: const Color(0xFF2979FF).withOpacity(0.1),
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
                                    color: Color(0xFF0A3D62),
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
  });
}
