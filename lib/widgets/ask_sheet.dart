import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:hybstockadvisor/models/market_stock.dart';
import 'package:hybstockadvisor/services/api_service.dart';
import 'package:hybstockadvisor/theme/format.dart';
import 'package:hybstockadvisor/theme/tokens.dart';
import 'package:hybstockadvisor/widgets/reply_text.dart';
import 'package:hybstockadvisor/widgets/ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Opens "Ask", the research assistant, about the stock being viewed.
///
/// [about] carries the price and date the user just saw, so the sheet can
/// show them and the answers can be checked against them.
Future<void> showAskSheet(
  BuildContext context, {
  AskContext? about,
  String? initialMessage,
}) {
  return showAppSheet<void>(
    context,
    (_) => AskSheet(about: about, initialMessage: initialMessage),
  );
}

class _Entry {
  final String role; // 'user' | 'ai'
  final String text;
  final bool isError;
  const _Entry(this.role, this.text, {this.isError = false});

  Map<String, String> toJson() => {'role': role, 'text': text};

  static _Entry? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final role = raw['role'];
    final text = raw['text'];
    if (role is! String || text is! String) return null;
    return _Entry(role == 'user' ? 'user' : 'ai', text);
  }
}

class AskSheet extends StatefulWidget {
  final AskContext? about;
  final String? initialMessage;
  const AskSheet({super.key, this.about, this.initialMessage});

  @override
  State<AskSheet> createState() => _AskSheetState();
}

class _AskSheetState extends State<AskSheet> {
  static const _historyKey = 'messages';
  static const _maxHistory = 10;

  final _input = TextEditingController();
  final _scroll = ScrollController();
  final List<_Entry> _entries = [];
  bool _sending = false;
  String? _lastQuestion;

  @override
  void initState() {
    super.initState();
    _loadHistory().whenComplete(() {
      final first = widget.initialMessage?.trim();
      if (first != null && first.isNotEmpty) _send(first);
    });
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_historyKey);
      if (raw == null || raw.isEmpty) return;
      final decoded = jsonDecode(raw);
      if (decoded is! List) return;
      final loaded = decoded.map(_Entry.fromJson).whereType<_Entry>().toList();
      if (!mounted) return;
      setState(() => _entries.addAll(loaded));
      _toBottom(jump: true);
    } catch (_) {}
  }

  Future<void> _persist() async {
    final saved = _entries.where((e) => !e.isError).toList();
    final capped = saved.length > _maxHistory
        ? saved.sublist(saved.length - _maxHistory)
        : saved;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _historyKey,
      jsonEncode(capped.map((e) => e.toJson()).toList()),
    );
  }

  Future<void> _clear() async {
    setState(_entries.clear);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_historyKey);
  }

  Future<void> _send([String? preset]) async {
    final text = (preset ?? _input.text).trim();
    if (text.isEmpty || _sending) return;
    setState(() {
      _entries.add(_Entry('user', text));
      _sending = true;
      _lastQuestion = text;
      if (preset == null) _input.clear();
    });
    _toBottom();
    _persist();

    final result = await ApiService.sendChatMessage(
      text,
      currentTicker: widget.about?.ticker,
    );
    if (!mounted) return;
    setState(() {
      _sending = false;
      _entries.add(
        result.ok
            ? _Entry('ai', result.reply!)
            : _Entry('ai', result.error!, isError: true),
      );
    });
    _toBottom();
    _persist();
  }

  void _retry() {
    final q = _lastQuestion;
    if (q == null) return;
    setState(() {
      // Drop the failed exchange and ask again.
      if (_entries.isNotEmpty && _entries.last.isError) _entries.removeLast();
      if (_entries.isNotEmpty && _entries.last.role == 'user') _entries.removeLast();
    });
    _send(q);
  }

  void _toBottom({bool jump = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) return;
      final end = _scroll.position.maxScrollExtent;
      if (jump) {
        _scroll.jumpTo(end);
      } else {
        _scroll.animateTo(
          end,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _contextLine() {
    final a = widget.about;
    if (a == null) return 'About your holdings and watchlist';
    final bits = <String>['About ${a.ticker}'];
    if (a.price != null) {
      final date = a.asOf == null ? '' : ' on ${Fmt.date(a.asOf)}';
      bits.add('last close ${Fmt.money(a.price, currency: a.currency)}$date');
    }
    return bits.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final t = context.text;
    final about = widget.about;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SheetFrame(
        title: 'Ask',
        subtitle: Text.rich(
          TextSpan(
            children: [
              if (about?.stale == true)
                TextSpan(
                  text: 'Stale · ',
                  style: TextStyle(color: p.warn, fontWeight: FontWeight.w600),
                ),
              TextSpan(text: _contextLine()),
            ],
          ),
          style: t.bodySmall,
        ),
        actions: [
          if (_entries.isNotEmpty)
            TextButton(onPressed: _sending ? null : _clear, child: const Text('Clear')),
        ],
        heightFactor: 0.9,
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            Expanded(
              child: _entries.isEmpty && !_sending
                  ? ListView(
                      padding: const EdgeInsets.fromLTRB(Gap.page, Gap.lg, Gap.page, Gap.lg),
                      children: [
                        Text(
                          about == null
                              ? 'Ask about your holdings, a stock you watch, or how the research signals work.'
                              : 'Ask about ${about.ticker}: recent prices, the research note, or how it sits in your portfolio.',
                          style: t.bodyLarge?.copyWith(color: p.inkMuted),
                        ),
                        const SizedBox(height: Gap.sm),
                        Text(
                          'Answers use verified daily closes only and give the date of any price they quote.',
                          style: t.bodySmall,
                        ),
                      ],
                    )
                  : ListView.separated(
                      controller: _scroll,
                      padding: const EdgeInsets.fromLTRB(Gap.page, Gap.sm, Gap.page, Gap.lg),
                      itemCount: _entries.length + (_sending ? 1 : 0),
                      separatorBuilder: (_, _) => const Hairline(),
                      itemBuilder: (context, i) {
                        if (i == _entries.length) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Kicker('Ask'),
                                const SizedBox(height: 8),
                                Text('Looking up the data…', style: t.bodyMedium?.copyWith(color: p.inkFaint)),
                                const SizedBox(height: 10),
                                const SizedBox(width: 120, child: LinearProgressIndicator(minHeight: 1.5)),
                              ],
                            ),
                          );
                        }
                        return _entryView(context, _entries[i], i == _entries.length - 1);
                      },
                    ),
            ),
            const Hairline(),
            Padding(
              padding: const EdgeInsets.fromLTRB(Gap.page, Gap.sm, Gap.page, 0),
              child: Text(
                'Research only, not financial advice. Answers can be wrong; check figures on the stock’s page.',
                style: t.bodySmall,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(Gap.page, Gap.sm, Gap.page - 4, Gap.sm),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _input,
                      minLines: 1,
                      maxLines: 4,
                      maxLength: 2000,
                      buildCounter: (_, {required currentLength, required isFocused, maxLength}) => null,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      decoration: InputDecoration(
                        hintText: about == null ? 'Ask a question' : 'Ask about ${about.ticker}',
                      ),
                    ),
                  ),
                  const SizedBox(width: Gap.sm),
                  TextButton(
                    onPressed: _sending ? null : _send,
                    style: TextButton.styleFrom(minimumSize: const Size(56, 46)),
                    child: const Text('Send'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _entryView(BuildContext context, _Entry e, bool isLast) {
    final p = context.pal;
    final t = context.text;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Kicker(e.role == 'user' ? 'You' : 'Ask', color: e.role == 'user' ? p.inkFaint : p.accent),
          const SizedBox(height: 6),
          if (e.role == 'user')
            Text(e.text, style: t.bodyLarge?.copyWith(fontWeight: FontWeight.w500))
          else if (e.isError) ...[
            Text(e.text, style: t.bodyLarge?.copyWith(color: p.down)),
            if (isLast && _lastQuestion != null)
              LinkText('Try again', arrow: false, onTap: _sending ? null : _retry),
          ] else
            ReplyText(e.text),
        ],
      ),
    );
  }
}
