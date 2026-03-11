import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hybstockadvisor/screens/dashboard.dart';
import 'package:hybstockadvisor/services/api_service.dart';
import 'package:hybstockadvisor/widgets/custom_page_route.dart';
import 'dart:math';

class FirstLogin extends StatefulWidget {
  const FirstLogin({super.key});

  @override
  State<FirstLogin> createState() => _FirstLoginState();
}

class _FirstLoginState extends State<FirstLogin> {
  final List<_PortfolioEntry> _selectedStocks = [];
  bool _isSubmitting = false;
  bool _isFetchingStocks = true; // ✅ Loading state for market fetch

  // ✅ Start empty — will be filled from live API
  List<NigerianStock> _availableStocks = [];

  @override
  void initState() {
    super.initState();
    _fetchLiveStocks(); // ✅ Fetch live stocks on screen load
  }

  // ✅ Fetch the full live market list (same as dashboard)
  Future<void> _fetchLiveStocks() async {
    setState(() => _isFetchingStocks = true);

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
        _availableStocks = liveList;
        _isFetchingStocks = false;
      });
    } else {
      // Fallback to defaultNigerianStocks if API fails
      setState(() {
        _availableStocks = List.from(defaultNigerianStocks);
        _isFetchingStocks = false;
      });
    }
  }

  void _openStockPicker(bool isDark) {
    if (_isFetchingStocks) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Still loading stocks, please wait...'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _StockPickerModal(
        isDark: isDark,
        stocksList: _availableStocks, // ✅ Pass the LIVE list
        alreadySelected: _selectedStocks.map((e) => e.stock.symbol).toList(),
        onSelected: (stock) {
          Navigator.pop(context);
          _showQuantityDialog(stock, isDark);
        },
      ),
    );
  }

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
            Text(
              stock.name,
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
            const SizedBox(height: 16),
            _buildDialogField(
              controller: qtyController,
              label: 'Quantity (units)',
              hint: 'e.g. 100',
              isDark: isDark,
            ),
            const SizedBox(height: 12),
            _buildDialogField(
              controller: priceController,
              label: 'Average Buy Price (₦)',
              hint: 'e.g. ${stock.price.toStringAsFixed(2)}',
              isDark: isDark,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: Colors.grey[500])),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0A3D62),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              // ✅ tryParse already handles decimals like "1.1"
              final qty = double.tryParse(qtyController.text.trim());
              final price = double.tryParse(priceController.text.trim());

              if (qty == null || qty <= 0 || price == null || price <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter valid quantity and price'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              Navigator.pop(ctx);
              setState(() {
                _selectedStocks.add(
                  _PortfolioEntry(
                    stock: stock,
                    quantity: qty, // ✅ stored as full double e.g. 1.1
                    avgBuyPrice: price,
                  ),
                );
              });
            },
            child: const Text('Add', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildDialogField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool isDark,
  }) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: TextStyle(color: isDark ? Colors.white : const Color(0xFF1A1A2E)),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: TextStyle(color: Colors.grey[500], fontSize: 13),
        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
        filled: true,
        fillColor: isDark ? const Color(0xFF1A1A2E) : const Color(0xFFF2F4F7),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  // ✅ Helper: shows "1" for 1.0, "1.1" for 1.1, "1.15" for 1.15
  String _removeTrailingZero(double value) {
    if (value == value.truncate()) {
      return value.toInt().toString(); // whole number → no decimal
    }
    // Remove unnecessary trailing zeros e.g. 1.10 → "1.1"
    return value.toString().replaceAll(RegExp(r'0+$'), '');
  }

  Future<void> _submitPortfolio() async {
    if (_selectedStocks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one stock to continue'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Submit each stock to the API
      for (final entry in _selectedStocks) {
        await ApiService.addToPortfolio(
          ticker: entry.stock.symbol,
          quantity: entry.quantity,
          avgBuyPrice: entry.avgBuyPrice,
        );
      }

      // Mark first login as done in Hive
      final box = await Hive.openBox('user');
      await box.put('has_setup_portfolio', true);

      if (mounted) {
        context.pushFade(const Dashboard());
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving portfolio: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1A1A2E) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A2E);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              const SizedBox(height: 20),
              Text(
                '👋 Welcome!',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Add the Nigerian stocks you currently own to set up your portfolio.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 28),

              // Add Stock Button
              GestureDetector(
                onTap: () => _openStockPicker(isDark),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A3D62).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xFF0A3D62).withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      // ✅ Show spinner while loading, icon when ready
                      _isFetchingStocks
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFF0A3D62),
                              ),
                            )
                          : const Icon(
                              Icons.add_circle,
                              color: Color(0xFF0A3D62),
                            ),
                      const SizedBox(width: 10),
                      Text(
                        _isFetchingStocks
                            ? 'Loading stocks...'
                            : 'Add a stock to your portfolio',
                        style: const TextStyle(
                          color: Color(0xFF0A3D62),
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Selected Stocks List
              if (_selectedStocks.isNotEmpty) ...[
                Text(
                  '${_selectedStocks.length} stock(s) added',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[500],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: ListView.separated(
                    itemCount: _selectedStocks.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final entry = _selectedStocks[i];
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF2A2D3E)
                              : const Color(0xFFF2F4F7),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            // Symbol badge
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: const Color(0xFF0A3D62).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Center(
                                child: Text(
                                  entry.stock.symbol.substring(
                                    0,
                                    min(3, entry.stock.symbol.length),
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
                                    entry.stock.symbol,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: textColor,
                                    ),
                                  ),
                                  Text(
                                    // ✅ Show decimals only if needed (1.0 → "1", 1.1 → "1.1")
                                    '${_removeTrailingZero(entry.quantity)} units  •  Avg ₦${entry.avgBuyPrice.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Remove button
                            GestureDetector(
                              onTap: () =>
                                  setState(() => _selectedStocks.removeAt(i)),
                              child: const Icon(
                                Icons.remove_circle_outline,
                                color: Colors.red,
                                size: 20,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ] else
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.bar_chart_rounded,
                          size: 64,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No stocks added yet',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 16),

              // Skip + Continue buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        final box = await Hive.openBox('user');
                        await box.put('has_setup_portfolio', true);
                        if (mounted) context.pushFade(const Dashboard());
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: Colors.grey[300]!),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Skip for now',
                        style: TextStyle(color: Colors.grey[500]),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitPortfolio,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0A3D62),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Save & Continue',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Portfolio Entry Model
// ─────────────────────────────────────────────
class _PortfolioEntry {
  final NigerianStock stock;
  final double quantity;
  final double avgBuyPrice;

  _PortfolioEntry({
    required this.stock,
    required this.quantity,
    required this.avgBuyPrice,
  });
}

// ─────────────────────────────────────────────
// Stock Picker Modal (same style as dashboard)
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
                // Handle
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                // Title
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
                // Search Field
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
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
                        hintText: 'Search symbol or company...',
                        hintStyle: TextStyle(color: Colors.grey[400]),
                        prefixIcon: const Icon(
                          Icons.search,
                          color: Color(0xFF0A3D62),
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 14,
                        ),
                      ),
                    ),
                  ),
                ),
                // Count
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 4,
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '${_filtered.length} stocks',
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                  ),
                ),
                // Stock List
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
                        onTap: alreadyAdded
                            ? null
                            : () => widget.onSelected(stock),
                        child: Opacity(
                          opacity: alreadyAdded ? 0.4 : 1.0,
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
                                        color: Color(0xFF0A3D62),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                      fontSize: 13,
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
          );
        },
      ),
    );
  }
}
