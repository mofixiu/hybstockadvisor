import 'package:flutter/material.dart';
import 'package:hybstockadvisor/models/market_stock.dart';
import 'package:hybstockadvisor/theme/format.dart';
import 'package:hybstockadvisor/theme/tokens.dart';
import 'package:hybstockadvisor/widgets/stock_logo.dart';
import 'package:hybstockadvisor/widgets/ui.dart';

/// Opens the stock list with a search field. Returns the chosen stock.
///
/// [disabled] symbols are listed but not selectable (already added).
Future<MarketStock?> showStockPicker(
  BuildContext context, {
  required List<MarketStock> stocks,
  List<String> disabled = const [],
  String title = 'Choose a stock',
  String? selected,
}) {
  return showAppSheet<MarketStock>(
    context,
    (_) => _StockPickerSheet(
      stocks: stocks,
      disabled: disabled,
      title: title,
      selected: selected,
    ),
  );
}

class _StockPickerSheet extends StatefulWidget {
  final List<MarketStock> stocks;
  final List<String> disabled;
  final String title;
  final String? selected;
  const _StockPickerSheet({
    required this.stocks,
    required this.disabled,
    required this.title,
    this.selected,
  });

  @override
  State<_StockPickerSheet> createState() => _StockPickerSheetState();
}

class _StockPickerSheetState extends State<_StockPickerSheet> {
  final _query = TextEditingController();
  late List<MarketStock> _filtered = widget.stocks;

  void _filter(String q) {
    final s = q.trim().toLowerCase();
    setState(() {
      _filtered = s.isEmpty
          ? widget.stocks
          : widget.stocks
                .where((x) =>
                    x.symbol.toLowerCase().contains(s) ||
                    x.name.toLowerCase().contains(s))
                .toList();
    });
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final t = context.text;
    final latest = widget.stocks
        .map((s) => s.asOf)
        .whereType<DateTime>()
        .fold<DateTime?>(null, (a, b) => a == null || b.isAfter(a) ? b : a);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SheetFrame(
        title: widget.title,
        subtitle: Text(
          '${widget.stocks.length} NGX stocks${latest != null ? ' · data as of ${Fmt.date(latest)}' : ''}',
          style: t.bodySmall,
        ),
        heightFactor: 0.88,
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(Gap.page, Gap.md, Gap.page, Gap.sm),
              child: TextField(
                controller: _query,
                onChanged: _filter,
                autofocus: false,
                textInputAction: TextInputAction.search,
                decoration: const InputDecoration(
                  hintText: 'Search symbol or company',
                  prefixIcon: Icon(Icons.search, size: 20),
                ),
              ),
            ),
            Expanded(
              child: _filtered.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(horizontal: Gap.page),
                      child: MessageBlock(
                        title: 'No match',
                        body: 'No NGX stock matches "${_query.text.trim()}".',
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.only(bottom: Gap.xl),
                      itemCount: _filtered.length,
                      separatorBuilder: (_, _) => const Hairline(indent: Gap.page),
                      itemBuilder: (context, i) {
                        final s = _filtered[i];
                        final added = widget.disabled.contains(s.symbol);
                        final isSelected = s.symbol == widget.selected;
                        return InkWell(
                          onTap: added ? null : () => Navigator.pop(context, s),
                          child: Container(
                            color: isSelected ? p.accentWash : null,
                            padding: const EdgeInsets.symmetric(
                              horizontal: Gap.page,
                              vertical: 10,
                            ),
                            child: Opacity(
                              opacity: added ? 0.45 : 1,
                              child: Row(
                                children: [
                                  StockLogo(symbol: s.symbol, size: 32),
                                  const SizedBox(width: Gap.md),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(s.symbol, style: t.titleSmall),
                                        Text(
                                          s.name,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: t.bodySmall,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: Gap.sm),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        Fmt.money(s.price, currency: s.currency),
                                        style: t.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                                      ),
                                      if (added)
                                        Text('Added', style: t.bodySmall)
                                      else if (s.stale)
                                        const StaleTag()
                                      else
                                        ChangeText(
                                          pct: s.changePct,
                                          style: t.bodySmall,
                                        ),
                                    ],
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
