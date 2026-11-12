// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'package:hybstockadvisor/models/market_stock.dart';
import 'package:hybstockadvisor/screens/dashboard.dart';
import 'package:hybstockadvisor/services/api_service.dart';
import 'package:hybstockadvisor/theme/format.dart';
import 'package:hybstockadvisor/theme/tokens.dart';
import 'package:hybstockadvisor/widgets/custom_page_route.dart';
import 'package:hybstockadvisor/widgets/stock_logo.dart';
import 'package:hybstockadvisor/widgets/stock_picker_sheet.dart';
import 'package:hybstockadvisor/widgets/ui.dart';

/// First-time setup: add the stocks you already own.
class FirstLogin extends StatefulWidget {
  const FirstLogin({super.key});

  @override
  State<FirstLogin> createState() => _FirstLoginState();
}

class _FirstLoginState extends State<FirstLogin> {
  final List<_PortfolioEntry> _selected = [];
  bool _isSubmitting = false;
  bool _isFetchingStocks = true;
  List<MarketStock> _available = [];

  @override
  void initState() {
    super.initState();
    _fetchLiveStocks();
  }

  Future<void> _fetchLiveStocks() async {
    setState(() => _isFetchingStocks = true);
    final summary = await ApiService.getMarketSummary();
    if (!mounted) return;
    setState(() {
      _available = MarketStock.listFromSummary(summary);
      _isFetchingStocks = false;
    });
  }

  Future<void> _openStockPicker() async {
    if (_isFetchingStocks) {
      showNotice(context, 'The stock list is still loading.');
      return;
    }
    if (_available.isEmpty) {
      showNotice(context, "The stock list isn't available right now. Skip and add holdings later.");
      return;
    }
    final stock = await showStockPicker(
      context,
      stocks: _available,
      disabled: _selected.map((e) => e.stock.symbol).toList(),
      title: 'Add a holding',
    );
    if (stock != null && mounted) _showQuantityDialog(stock);
  }

  void _showQuantityDialog(MarketStock stock) {
    final qtyController = TextEditingController();
    final priceController = TextEditingController(text: stock.price.toStringAsFixed(2));
    final numbers = [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))];

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Add ${stock.symbol}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(stock.name, style: context.text.bodySmall),
            const SizedBox(height: Gap.lg),
            TextField(
              controller: qtyController,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: numbers,
              decoration: const InputDecoration(labelText: 'Shares', hintText: 'e.g. 100'),
            ),
            const SizedBox(height: Gap.md),
            TextField(
              controller: priceController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: numbers,
              decoration: InputDecoration(
                labelText: 'Average buy price (₦)',
                helperText: 'Last close ${Fmt.money(stock.price, currency: stock.currency)}',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: context.pal.inkMuted)),
          ),
          TextButton(
            onPressed: () {
              final qty = double.tryParse(qtyController.text.trim());
              final price = double.tryParse(priceController.text.trim());
              if (qty == null || qty <= 0 || price == null || price <= 0) {
                showNotice(context, 'Enter a number of shares and a price above zero.');
                return;
              }
              Navigator.pop(ctx);
              setState(() {
                _selected.add(_PortfolioEntry(stock: stock, quantity: qty, avgBuyPrice: price));
              });
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _finish() async {
    final box = await Hive.openBox('user');
    await box.put('has_setup_portfolio', true);
    if (mounted) context.pushFade(const Dashboard());
  }

  Future<void> _submitPortfolio() async {
    if (_selected.isEmpty) {
      showNotice(context, 'Add at least one holding, or skip for now.');
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      // Stop at the first failure so nothing is silently dropped.
      for (final entry in _selected) {
        final res = await ApiService.addToPortfolio(
          ticker: entry.stock.symbol,
          quantity: entry.quantity,
          avgBuyPrice: entry.avgBuyPrice,
        );
        if (res['status'] != 'success') {
          if (!mounted) return;
          setState(() => _isSubmitting = false);
          showNotice(
            context,
            res['detail']?.toString() ?? "Couldn't save ${entry.stock.symbol}. Try again.",
          );
          return;
        }
      }
      await _finish();
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      showNotice(context, "Couldn't save your holdings. Try again.");
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final t = context.text;
    final total = _selected.fold<double>(0, (sum, e) => sum + e.quantity * e.avgBuyPrice);

    return Scaffold(
      backgroundColor: p.paper,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(Gap.page, Gap.xl, Gap.page, Gap.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Kicker('First-time setup'),
              const SizedBox(height: Gap.sm),
              Text('Add what you own', style: t.headlineMedium),
              const SizedBox(height: Gap.sm),
              Text(
                'Add the NGX stocks you hold, with your number of shares and average buy price. '
                'You can change them later on the Portfolio tab.',
                style: t.bodyMedium?.copyWith(color: p.inkMuted),
              ),
              const SizedBox(height: Gap.lg),
              const HeavyRule(),
              const SizedBox(height: Gap.md),
              QuietButton(
                _isFetchingStocks ? 'Loading the stock list…' : 'Add a holding',
                icon: Icons.add,
                onPressed: _isFetchingStocks ? null : _openStockPicker,
              ),
              if (!_isFetchingStocks && _available.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: Gap.sm),
                  child: Text(
                    "The stock list isn't available right now. Skip and add holdings later.",
                    style: t.bodySmall?.copyWith(color: p.warn),
                  ),
                ),
              const SizedBox(height: Gap.md),
              if (_selected.isNotEmpty) ...[
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _selected.length == 1 ? '1 holding' : '${_selected.length} holdings',
                        style: t.labelMedium,
                      ),
                    ),
                    Text('Cost ${Fmt.money(total)}', style: t.labelMedium),
                  ],
                ),
                const SizedBox(height: Gap.xs),
                const Hairline(),
                Expanded(
                  child: ListView.separated(
                    itemCount: _selected.length,
                    separatorBuilder: (_, _) => const Hairline(),
                    itemBuilder: (context, i) {
                      final e = _selected[i];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Row(
                          children: [
                            StockLogo(symbol: e.stock.symbol, size: 32),
                            const SizedBox(width: Gap.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(e.stock.symbol, style: t.titleSmall),
                                  Text(
                                    '${Fmt.quantity(e.quantity)} shares · avg ${Fmt.money(e.avgBuyPrice)}',
                                    style: t.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              Fmt.money(e.quantity * e.avgBuyPrice),
                              style: t.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                            ),
                            IconButton(
                              tooltip: 'Remove ${e.stock.symbol}',
                              onPressed: () => setState(() => _selected.removeAt(i)),
                              icon: Icon(Icons.close, size: 18, color: p.inkFaint),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ] else
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: Gap.md),
                    child: Text(
                      'No holdings added yet.',
                      style: t.bodyMedium?.copyWith(color: p.inkFaint),
                    ),
                  ),
                ),
              const SizedBox(height: Gap.md),
              Row(
                children: [
                  TextButton(
                    onPressed: _isSubmitting ? null : _finish,
                    child: Text('Skip for now', style: TextStyle(color: p.inkMuted)),
                  ),
                  const SizedBox(width: Gap.md),
                  Expanded(
                    child: PrimaryButton(
                      'Save and continue',
                      onPressed: _submitPortfolio,
                      loading: _isSubmitting,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PortfolioEntry {
  final MarketStock stock;
  final double quantity;
  final double avgBuyPrice;

  _PortfolioEntry({required this.stock, required this.quantity, required this.avgBuyPrice});
}
