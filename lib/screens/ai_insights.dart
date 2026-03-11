// import 'package:flutter/material.dart';
// import 'package:fl_chart/fl_chart.dart';
// import 'package:hybstockadvisor/widgets/bottomNavBar.dart';

// class AiInsights extends StatelessWidget {
//   const AiInsights({super.key});

//   @override
//   Widget build(BuildContext context) {
//     final isDark = Theme.of(context).brightness == Brightness.dark;
//     final bgColor = isDark ? const Color(0xFF1A1A2E) : const Color(0xFFF2F4F7);
//     final cardColor = isDark ? const Color(0xFF2A2D3E) : Colors.white;
//     final textColor = isDark ? Colors.white : const Color(0xFF1A1A2E);

//     return Scaffold(
//       backgroundColor: bgColor,
//       bottomNavigationBar: const BottomNavBar(currentIndex: 1),
//       appBar: AppBar(
//         backgroundColor: bgColor,
//         elevation: 0,
//         automaticallyImplyLeading: false,
//         title: Text(
//           'Why This Recommendation?',
//           style: TextStyle(
//             color: textColor,
//             fontSize: 22,
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//         centerTitle: true,
//       ),
//       body: SafeArea(
//         child: Column(
//           children: [
//             Expanded(
//               child: SingleChildScrollView(
//                 padding: const EdgeInsets.symmetric(
//                   horizontal: 20,
//                   vertical: 8,
//                 ),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     // ── AI Analysis Header ──
//                     Row(
//                       children: [
//                         Container(
//                           width: 40,
//                           height: 40,
//                           decoration: BoxDecoration(
//                             color: const Color(0xFFF5E6A3),
//                             borderRadius: BorderRadius.circular(10),
//                           ),
//                           child: const Icon(
//                             Icons.pause_circle_filled,
//                             color: Color(0xFF7A5C00),
//                             size: 24,
//                           ),
//                         ),
//                         const SizedBox(width: 12),
//                         Text(
//                           'AI Analysis: (GTCO) :Hold',
//                           style: TextStyle(
//                             fontSize: 22,
//                             fontWeight: FontWeight.bold,
//                             color: textColor,
//                           ),
//                         ),
//                       ],
//                     ),

//                     const SizedBox(height: 14),

//                     // ── Description ──
//                     Text(
//                       'The stock is currently trading within a tight range. While momentum indicators are neutral, the price remains above the 50-day moving average, suggesting stability but no immediate breakout.',
//                       style: TextStyle(
//                         fontSize: 14,
//                         height: 1.6,
//                         color: isDark ? Colors.grey[300] : Colors.grey[700],
//                       ),
//                     ),

//                     const SizedBox(height: 24),

//                     // ── Metric Cards ──
//                     _MetricCard(
//                       isDark: isDark,
//                       cardColor: cardColor,
//                       icon: Icons.psychology,
//                       iconBgColor: const Color(0xFFDCEAFF),
//                       iconColor: const Color(0xFF2979FF),
//                       label: 'AI Confidence',
//                       value: '57.5%',
//                       percent: 0.575,
//                       gaugeColor: const Color(0xFF2979FF),
//                     ),

//                     const SizedBox(height: 12),

//                     _MetricCard(
//                       isDark: isDark,
//                       cardColor: cardColor,
//                       icon: Icons.bar_chart,
//                       iconBgColor: const Color(0xFFD6F5E3),
//                       iconColor: const Color(0xFF2DBD6E),
//                       label: 'Market Stability',
//                       value: '76.4%',
//                       percent: 0.764,
//                       gaugeColor: const Color(0xFF2DBD6E),
//                     ),

//                     const SizedBox(height: 12),

//                     _MetricCard(
//                       isDark: isDark,
//                       cardColor: cardColor,
//                       icon: Icons.chat_bubble,
//                       iconBgColor: const Color(0xFFFFDCDC),
//                       iconColor: const Color(0xFFE53935),
//                       label: 'Public Sentiment',
//                       value: '27.9%',
//                       percent: 0.279,
//                       gaugeColor: const Color(0xFFE53935),
//                     ),

//                     const SizedBox(height: 28),

//                     // ── Key Market Drivers ──
//                     Text(
//                       'Key Market Drivers',
//                       style: TextStyle(
//                         fontSize: 18,
//                         fontWeight: FontWeight.bold,
//                         color: textColor,
//                       ),
//                     ),

//                     const SizedBox(height: 16),

//                     Container(
//                       padding: const EdgeInsets.all(20),
//                       decoration: BoxDecoration(
//                         color: cardColor,
//                         borderRadius: BorderRadius.circular(16),
//                         boxShadow: [
//                           BoxShadow(
//                             color: Colors.black.withOpacity(0.05),
//                             blurRadius: 8,
//                             offset: const Offset(0, 2),
//                           ),
//                         ],
//                       ),
//                       child: Column(
//                         children: [
//                           _ImpactBar(
//                             isDark: isDark,
//                             label: 'RSI Index',
//                             impact: '+12.4% Impact',
//                             impactColor: const Color(0xFF2DBD6E),
//                             // positive: bar goes right of center
//                             value: 0.35,
//                             isPositive: true,
//                           ),
//                           const SizedBox(height: 24),
//                           _ImpactBar(
//                             isDark: isDark,
//                             label: 'EMA 50 Day',
//                             impact: '-8.2% Impact',
//                             impactColor: const Color(0xFFE53935),
//                             // negative: bar goes left of center
//                             value: 0.28,
//                             isPositive: false,
//                           ),
//                           const SizedBox(height: 12),
//                           // ── X-axis labels ──
//                           Row(
//                             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                             children: [
//                               Text(
//                                 'Negative',
//                                 style: TextStyle(
//                                   fontSize: 11,
//                                   color: Colors.grey[500],
//                                 ),
//                               ),
//                               Text(
//                                 'Neutral',
//                                 style: TextStyle(
//                                   fontSize: 11,
//                                   color: Colors.grey[500],
//                                 ),
//                               ),
//                               Text(
//                                 'Positive',
//                                 style: TextStyle(
//                                   fontSize: 11,
//                                   color: Colors.grey[500],
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ],
//                       ),
//                     ),

//                     const SizedBox(height: 20),

//                     // ── Investment Safety Index Banner ──
//                     Container(
//                       width: double.infinity,
//                       padding: const EdgeInsets.all(24),
//                       decoration: BoxDecoration(
//                         gradient: const LinearGradient(
//                           colors: [Color(0xFF0A3D62), Color(0xFF0A3D62)],
//                           begin: Alignment.topLeft,
//                           end: Alignment.bottomRight,
//                         ),
//                         borderRadius: BorderRadius.circular(20),
//                       ),
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Row(
//                             children: const [
//                               Icon(
//                                 Icons.shield,
//                                 color: Colors.white70,
//                                 size: 16,
//                               ),
//                               SizedBox(width: 6),
//                               Text(
//                                 'INVESTMENT SAFETY INDEX',
//                                 style: TextStyle(
//                                   color: Colors.white70,
//                                   fontSize: 11,
//                                   letterSpacing: 1.2,
//                                   fontWeight: FontWeight.w600,
//                                 ),
//                               ),
//                             ],
//                           ),
//                           const SizedBox(height: 12),
//                           RichText(
//                             text: const TextSpan(
//                               children: [
//                                 TextSpan(
//                                   text: '84',
//                                   style: TextStyle(
//                                     color: Colors.white,
//                                     fontSize: 48,
//                                     fontWeight: FontWeight.bold,
//                                   ),
//                                 ),
//                                 TextSpan(
//                                   text: ' /100',
//                                   style: TextStyle(
//                                     color: Colors.white70,
//                                     fontSize: 22,
//                                     fontWeight: FontWeight.w500,
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                           const SizedBox(height: 8),
//                           const Text(
//                             'High safety rating based on current volatility and historical resilience.',
//                             style: TextStyle(
//                               color: Colors.white70,
//                               fontSize: 13,
//                               height: 1.5,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),

//                     const SizedBox(height: 20),
//                   ],
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// // ─────────────────────────────────────────────
// // Metric Card with arc gauge
// // ─────────────────────────────────────────────
// class _MetricCard extends StatelessWidget {
//   final bool isDark;
//   final Color cardColor;
//   final IconData icon;
//   final Color iconBgColor;
//   final Color iconColor;
//   final String label;
//   final String value;
//   final double percent;
//   final Color gaugeColor;

//   const _MetricCard({
//     required this.isDark,
//     required this.cardColor,
//     required this.icon,
//     required this.iconBgColor,
//     required this.iconColor,
//     required this.label,
//     required this.value,
//     required this.percent,
//     required this.gaugeColor,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final textColor = isDark ? Colors.white : const Color(0xFF1A1A2E);

//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
//       decoration: BoxDecoration(
//         color: cardColor,
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.05),
//             blurRadius: 8,
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
//               color: iconBgColor,
//               borderRadius: BorderRadius.circular(12),
//             ),
//             child: Icon(icon, color: iconColor, size: 22),
//           ),
//           const SizedBox(width: 14),
//           // Label + Value
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   label,
//                   style: TextStyle(fontSize: 13, color: Colors.grey[500]),
//                 ),
//                 const SizedBox(height: 4),
//                 Text(
//                   value,
//                   style: TextStyle(
//                     fontSize: 20,
//                     fontWeight: FontWeight.bold,
//                     color: textColor,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           // Arc Gauge
//           SizedBox(
//             width: 48,
//             height: 48,
//             child: PieChart(
//               PieChartData(
//                 startDegreeOffset: -210,
//                 sectionsSpace: 0,
//                 centerSpaceRadius: 16,
//                 sections: [
//                   PieChartSectionData(
//                     value: percent * 100,
//                     color: gaugeColor,
//                     radius: 8,
//                     showTitle: false,
//                   ),
//                   PieChartSectionData(
//                     value: (1 - percent) * 100,
//                     color: isDark
//                         ? Colors.white12
//                         : Colors.grey.withOpacity(0.15),
//                     radius: 8,
//                     showTitle: false,
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// // ─────────────────────────────────────────────
// // Key Market Driver Row
// // ─────────────────────────────────────────────
// // ignore: unused_element
// class _DriverRow extends StatelessWidget {
//   final bool isDark;
//   final String label;
//   final String status;
//   final double percent;
//   final Color barColor;

//   const _DriverRow({
//     required this.isDark,
//     required this.label,
//     required this.status,
//     required this.percent,
//     required this.barColor,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final textColor = isDark ? Colors.white : const Color(0xFF1A1A2E);

//     return Column(
//       children: [
//         Row(
//           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//           children: [
//             Text(
//               label,
//               style: TextStyle(
//                 fontSize: 13,
//                 color: isDark ? Colors.grey[300] : Colors.grey[600],
//               ),
//             ),
//             Text(
//               status,
//               style: TextStyle(
//                 fontSize: 13,
//                 fontWeight: FontWeight.bold,
//                 color: textColor,
//               ),
//             ),
//           ],
//         ),
//         const SizedBox(height: 8),
//         ClipRRect(
//           borderRadius: BorderRadius.circular(6),
//           child: LinearProgressIndicator(
//             value: percent,
//             minHeight: 7,
//             backgroundColor: isDark
//                 ? Colors.white12
//                 : Colors.grey.withOpacity(0.15),
//             valueColor: AlwaysStoppedAnimation<Color>(barColor),
//           ),
//         ),
//       ],
//     );
//   }
// }

// // ─────────────────────────────────────────────
// // Impact Bar (diverging / bidirectional bar)
// // ─────────────────────────────────────────────
// class _ImpactBar extends StatelessWidget {
//   final bool isDark;
//   final String label;
//   final String impact;
//   final Color impactColor;
//   final double value; // 0.0 to 1.0 — how far from center
//   final bool isPositive;

//   const _ImpactBar({
//     required this.isDark,
//     required this.label,
//     required this.impact,
//     required this.impactColor,
//     required this.value,
//     required this.isPositive,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final trackColor = isDark
//         ? Colors.white.withOpacity(0.08)
//         : Colors.grey.withOpacity(0.15);

//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         // Label row
//         Row(
//           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//           children: [
//             Text(
//               label,
//               style: TextStyle(
//                 fontSize: 14,
//                 fontWeight: FontWeight.w600,
//                 color: isDark ? Colors.white : const Color(0xFF1A1A2E),
//               ),
//             ),
//             Text(
//               impact,
//               style: TextStyle(
//                 fontSize: 13,
//                 fontWeight: FontWeight.bold,
//                 color: impactColor,
//               ),
//             ),
//           ],
//         ),
//         const SizedBox(height: 10),

//         // Diverging bar
//         LayoutBuilder(
//           builder: (context, constraints) {
//             final totalWidth = constraints.maxWidth;
//             final halfWidth = totalWidth / 2;
//             final barWidth = halfWidth * value;

//             return SizedBox(
//               height: 28,
//               child: Stack(
//                 children: [
//                   // Full background track
//                   Positioned.fill(
//                     child: Container(
//                       decoration: BoxDecoration(
//                         color: trackColor,
//                         borderRadius: BorderRadius.circular(6),
//                       ),
//                     ),
//                   ),

//                   // Colored bar — right of center if positive, left if negative
//                   Positioned(
//                     top: 0,
//                     bottom: 0,
//                     left: isPositive ? halfWidth : halfWidth - barWidth,
//                     width: barWidth,
//                     child: Container(
//                       decoration: BoxDecoration(
//                         color: impactColor.withOpacity(0.75),
//                         borderRadius: BorderRadius.circular(4),
//                       ),
//                     ),
//                   ),

//                   // Center divider line
//                   Positioned(
//                     top: 0,
//                     bottom: 0,
//                     left: halfWidth - 1,
//                     width: 2,
//                     child: Container(
//                       color: isDark ? Colors.white38 : Colors.grey[400],
//                     ),
//                   ),
//                 ],
//               ),
//             );
//           },
//         ),
//       ],
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:hybstockadvisor/widgets/ai_chat_sheet.dart';
import 'package:hybstockadvisor/widgets/bottomNavBar.dart';
import 'package:hybstockadvisor/services/api_service.dart';

class AiInsights extends StatefulWidget {
  const AiInsights({super.key});

  @override
  State<AiInsights> createState() => _AiInsightsState();
}

class _AiInsightsState extends State<AiInsights> {
  bool _isLoading = true;

  // Default fallback states
  String _ticker = "";
  String _recommendation = "LOADING...";
  String _explanation = "Analyzing market data...";

  double _aiConfidence = 0.0;
  double _marketStability = 0.0;
  double _publicSentiment = 0.0;
  double _safetyIndex = 0.0;

  double _rsiImpact = 0.0;
  double _emaImpact = 0.0;

  @override
  void initState() {
    super.initState();
    // Grab whatever stock was selected on the Dashboard!
    _ticker = ApiService.currentTicker;
    _fetchInsights();
  }

  Future<void> _fetchInsights() async {
    final response = await ApiService.getInsights(_ticker);

    if (response != null && response['status'] == 'success') {
      final data = response['data'];
      setState(() {
        _recommendation = data['recommendation']
            .toString()
            .replaceAll(RegExp(r'[^\w\s]'), '')
            .trim();
        _explanation = data['explanation'];
        _aiConfidence = (data['ai_confidence'] as num).toDouble();
        _marketStability = (data['market_stability'] as num).toDouble();
        _publicSentiment = (data['public_sentiment'] as num).toDouble();
        _safetyIndex = (data['safety_index'] as num).toDouble();
        _rsiImpact = (data['rsi_impact'] as num).toDouble();
        _emaImpact = (data['ema_impact'] as num).toDouble();
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
        _explanation = "Error connecting to the AI Engine.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // 👇 ADD THIS "WAKE UP" CHECK 👇
    // If the global ticker changed while we were on the Dashboard, fetch the new data!
    if (_ticker != ApiService.currentTicker && !_isLoading) {
      _ticker = ApiService.currentTicker;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _fetchInsights();
      });
    }
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
            builder: (context) => AiChatSheet(isDark: isDark, currentTicker: _ticker),
          );
        },
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 1),
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          'Why This Recommendation?',
          style: TextStyle(
            color: textColor,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF2979FF)),
              )
            : Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── AI Analysis Header ──
                          Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF5E6A3),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons
                                      .psychology, // Swapped icon for a smarter look
                                  color: Color(0xFF7A5C00),
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'AI Analysis: ($_ticker) : $_recommendation',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: textColor,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 14),

                          // ── Dynamic Explanation ──
                          Text(
                            _explanation,
                            style: TextStyle(
                              fontSize: 14,
                              height: 1.6,
                              color: isDark
                                  ? Colors.grey[300]
                                  : Colors.grey[700],
                            ),
                          ),

                          const SizedBox(height: 24),

                          // ── Metric Cards ──
                          _MetricCard(
                            isDark: isDark,
                            cardColor: cardColor,
                            icon: Icons.psychology,
                            iconBgColor: const Color(0xFFDCEAFF),
                            iconColor: const Color(0xFF2979FF),
                            label: 'AI Confidence',
                            value: '${_aiConfidence.toStringAsFixed(1)}%',
                            percent: _aiConfidence / 100,
                            gaugeColor: const Color(0xFF2979FF),
                          ),

                          const SizedBox(height: 12),

                          _MetricCard(
                            isDark: isDark,
                            cardColor: cardColor,
                            icon: Icons.bar_chart,
                            iconBgColor: const Color(0xFFD6F5E3),
                            iconColor: const Color(0xFF2DBD6E),
                            label: 'Market Stability',
                            value: '${_marketStability.toStringAsFixed(1)}%',
                            percent: _marketStability / 100,
                            gaugeColor: const Color(0xFF2DBD6E),
                          ),

                          const SizedBox(height: 12),

                          _MetricCard(
                            isDark: isDark,
                            cardColor: cardColor,
                            icon: Icons.chat_bubble,
                            iconBgColor: const Color(0xFFFFDCDC),
                            iconColor: const Color(0xFFE53935),
                            label: 'Public Sentiment',
                            value: '${_publicSentiment.toStringAsFixed(1)}%',
                            percent: _publicSentiment / 100,
                            gaugeColor: const Color(0xFFE53935),
                          ),

                          const SizedBox(height: 28),

                          // ── Key Market Drivers ──
                          Text(
                            'Key Market Drivers',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),

                          const SizedBox(height: 16),

                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: cardColor,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                _ImpactBar(
                                  isDark: isDark,
                                  label: 'RSI Momentum',
                                  impact: _rsiImpact >= 0
                                      ? '+${(_rsiImpact * 100).toStringAsFixed(1)}% Impact'
                                      : '${(_rsiImpact * 100).toStringAsFixed(1)}% Impact',
                                  impactColor: _rsiImpact >= 0
                                      ? const Color(0xFF2DBD6E)
                                      : const Color(0xFFE53935),
                                  value: _rsiImpact.abs(),
                                  isPositive: _rsiImpact >= 0,
                                ),
                                const SizedBox(height: 24),
                                _ImpactBar(
                                  isDark: isDark,
                                  label: 'EMA 50 Trend',
                                  impact: _emaImpact >= 0
                                      ? '+${(_emaImpact * 100).toStringAsFixed(1)}% Impact'
                                      : '${(_emaImpact * 100).toStringAsFixed(1)}% Impact',
                                  impactColor: _emaImpact >= 0
                                      ? const Color(0xFF2DBD6E)
                                      : const Color(0xFFE53935),
                                  value: _emaImpact.abs(),
                                  isPositive: _emaImpact >= 0,
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Negative',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey[500],
                                      ),
                                    ),
                                    Text(
                                      'Neutral',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey[500],
                                      ),
                                    ),
                                    Text(
                                      'Positive',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey[500],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),

                          // ── Investment Safety Index Banner ──
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF0A3D62), Color(0xFF0A3D62)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: const [
                                    Icon(
                                      Icons.shield,
                                      color: Colors.white70,
                                      size: 16,
                                    ),
                                    SizedBox(width: 6),
                                    Text(
                                      'INVESTMENT SAFETY INDEX',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 11,
                                        letterSpacing: 1.2,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                RichText(
                                  text: TextSpan(
                                    children: [
                                      TextSpan(
                                        text: _safetyIndex.toStringAsFixed(0),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 48,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const TextSpan(
                                        text: ' /100',
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 22,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _safetyIndex >= 60
                                      ? 'High safety rating based on current volatility and historical resilience.'
                                      : 'Caution advised. Asset is currently experiencing turbulence or negative sentiment.',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13,
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Metric Card with arc gauge
// ─────────────────────────────────────────────
class _MetricCard extends StatelessWidget {
  final bool isDark;
  final Color cardColor;
  final IconData icon;
  final Color iconBgColor;
  final Color iconColor;
  final String label;
  final String value;
  final double percent;
  final Color gaugeColor;

  const _MetricCard({
    required this.isDark,
    required this.cardColor,
    required this.icon,
    required this.iconBgColor,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.percent,
    required this.gaugeColor,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A2E);
    // Safety check to ensure pie chart doesn't break if percentage is out of bounds
    final safePercent = percent.clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
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
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 48,
            height: 48,
            child: PieChart(
              PieChartData(
                startDegreeOffset: -210,
                sectionsSpace: 0,
                centerSpaceRadius: 16,
                sections: [
                  PieChartSectionData(
                    value: safePercent * 100,
                    color: gaugeColor,
                    radius: 8,
                    showTitle: false,
                  ),
                  PieChartSectionData(
                    value: (1 - safePercent) * 100,
                    color: isDark
                        ? Colors.white12
                        : Colors.grey.withOpacity(0.15),
                    radius: 8,
                    showTitle: false,
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
// Impact Bar
// ─────────────────────────────────────────────
class _ImpactBar extends StatelessWidget {
  final bool isDark;
  final String label;
  final String impact;
  final Color impactColor;
  final double value;
  final bool isPositive;

  const _ImpactBar({
    required this.isDark,
    required this.label,
    required this.impact,
    required this.impactColor,
    required this.value,
    required this.isPositive,
  });

  @override
  Widget build(BuildContext context) {
    final trackColor = isDark
        ? Colors.white.withOpacity(0.08)
        : Colors.grey.withOpacity(0.15);
    final safeValue = value.clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF1A1A2E),
              ),
            ),
            Text(
              impact,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: impactColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, constraints) {
            final totalWidth = constraints.maxWidth;
            final halfWidth = totalWidth / 2;
            final barWidth = halfWidth * safeValue;

            return SizedBox(
              height: 28,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: trackColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 0,
                    bottom: 0,
                    left: isPositive ? halfWidth : halfWidth - barWidth,
                    width: barWidth,
                    child: Container(
                      decoration: BoxDecoration(
                        color: impactColor.withOpacity(0.75),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 0,
                    bottom: 0,
                    left: halfWidth - 1,
                    width: 2,
                    child: Container(
                      color: isDark ? Colors.white38 : Colors.grey[400],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
