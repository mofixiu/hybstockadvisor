import 'package:flutter/material.dart';
import 'dart:math';
import 'package:hybstockadvisor/screens/dashboard.dart';

/// Shared stock picker bottom-sheet modal.
///
/// Used by Dashboard (stock search), Portfolio (add stock), and FirstLogin (initial setup).
/// Supports an optional [alreadySelected] list to grey-out already-added stocks,
/// and an optional [showChange] flag to display price-change info (dashboard mode).
class StockPickerModal extends StatefulWidget {
  final bool isDark;
  final List<NigerianStock> stocksList;
  final List<String> alreadySelected;
  final bool showChange;
  final ValueChanged<NigerianStock> onSelected;

  const StockPickerModal({
    super.key,
    required this.isDark,
    required this.stocksList,
    this.alreadySelected = const [],
    this.showChange = false,
    required this.onSelected,
  });

  @override
  State<StockPickerModal> createState() => _StockPickerModalState();
}

class _StockPickerModalState extends State<StockPickerModal> {
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
    final cardColor =
        widget.isDark ? const Color(0xFF2A2D3E) : Colors.white;
    final bgColor =
        widget.isDark ? const Color(0xFF1A1A2E) : const Color(0xFFF2F4F7);
    final textColor =
        widget.isDark ? Colors.white : const Color(0xFF1A1A2E);

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
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
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
                // Title row
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
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
                // Search field
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
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
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ),
                // Count
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '${_filtered.length} stocks',
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                  ),
                ),
                // Stock list
                Expanded(
                  child: ListView.separated(
                    controller: scrollController,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    itemCount: _filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final stock = _filtered[i];
                      final alreadyAdded =
                          widget.alreadySelected.contains(stock.symbol);

                      return GestureDetector(
                        onTap: alreadyAdded
                            ? null
                            : () => widget.onSelected(stock),
                        child: Opacity(
                          opacity: alreadyAdded ? 0.4 : 1.0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: cardColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                // Symbol badge
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF2979FF)
                                        .withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Center(
                                    child: Text(
                                      stock.symbol.substring(
                                          0, min(3, stock.symbol.length)),
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF0A3D62),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                // Name
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
                                // Right side
                                if (alreadyAdded)
                                  const Icon(
                                    Icons.check_circle,
                                    color: Color(0xFF0A3D62),
                                    size: 18,
                                  )
                                else if (widget.showChange) ...[
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.end,
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
                                        stock.change == '-'
                                            ? stock.marketCap
                                            : stock.change,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: stock.change == '-'
                                              ? Colors.grey[500]
                                              : stock.change.startsWith('+')
                                                  ? Colors.green
                                                  : Colors.red,
                                        ),
                                      ),
                                    ],
                                  ),
                                ] else
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
