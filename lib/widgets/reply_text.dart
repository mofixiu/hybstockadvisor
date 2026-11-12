import 'package:flutter/material.dart';
import 'package:hybstockadvisor/theme/format.dart';
import 'package:hybstockadvisor/theme/tokens.dart';

/// Renders an assistant reply written in light Markdown: paragraphs,
/// headings, bullet and numbered lists, **bold**, *italic* and `code`.
///
/// Prices and dates are rewritten into the app's own formats first, so a reply
/// that says "NGN 24.0000 on 2026-11-11" reads "₦24.00 on 11 Nov 2026", the same
/// as the Portfolio screen.
class ReplyText extends StatelessWidget {
  final String text;
  const ReplyText(this.text, {super.key});

  /// Applies the app's money and date formats to free text.
  static String normalise(String input) {
    var s = input.replaceAll('\r\n', '\n');
    final money = RegExp(r'(?:\bNGN\s?|₦\s?)(\d[\d,]*(?:\.\d+)?)');
    s = s.replaceAllMapped(money, (m) {
      final n = double.tryParse(m.group(1)!.replaceAll(',', ''));
      return n == null ? m.group(0)! : Fmt.money(n);
    });
    final iso = RegExp(r'\b(\d{4})-(\d{2})-(\d{2})(?:T[\d:.]+(?:Z|[+-]\d{2}:?\d{2})?)?\b');
    s = s.replaceAllMapped(iso, (m) {
      final d = DateTime.tryParse('${m.group(1)}-${m.group(2)}-${m.group(3)}');
      return d == null ? m.group(0)! : Fmt.date(d);
    });
    // Signed percentages use a true minus, as elsewhere in the app.
    s = s.replaceAllMapped(
      RegExp(r'(^|[\s(*_])-(\d[\d,]*(?:\.\d+)?%)'),
      (m) => '${m.group(1)}${Fmt.minus}${m.group(2)}',
    );
    return s;
  }

  @override
  Widget build(BuildContext context) {
    final t = context.text;
    final p = context.pal;
    final body = t.bodyLarge!.copyWith(height: 1.55);
    final lines = normalise(text).split('\n');
    final blocks = <Widget>[];
    final para = <String>[];

    void flush() {
      if (para.isEmpty) return;
      blocks.add(_rich(para.join(' '), body, p));
      para.clear();
    }

    final bullet = RegExp(r'^\s*[-*•]\s+(.*)$');
    final numbered = RegExp(r'^\s*(\d+)[.)]\s+(.*)$');
    final heading = RegExp(r'^\s*#{1,6}\s+(.*)$');

    for (final raw in lines) {
      final line = raw.trimRight();
      if (line.trim().isEmpty) {
        flush();
        continue;
      }
      final h = heading.firstMatch(line);
      final b = bullet.firstMatch(line);
      final n = numbered.firstMatch(line);
      if (h != null) {
        flush();
        blocks.add(Padding(
          padding: const EdgeInsets.only(top: 4),
          child: _rich(h.group(1)!, t.titleLarge!.copyWith(fontSize: 17), p),
        ));
      } else if (b != null) {
        flush();
        blocks.add(_listItem('•', b.group(1)!, body, p));
      } else if (n != null) {
        flush();
        blocks.add(_listItem('${n.group(1)}.', n.group(2)!, body, p));
      } else {
        para.add(line.trim());
      }
    }
    flush();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < blocks.length; i++) ...[
          if (i > 0) const SizedBox(height: 8),
          blocks[i],
        ],
      ],
    );
  }

  Widget _listItem(String marker, String text, TextStyle style, Palette p) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SizedBox(
        width: 22,
        child: Text(marker, style: style.copyWith(color: p.inkMuted)),
      ),
      Expanded(child: _rich(text, style, p)),
    ],
  );

  Widget _rich(String text, TextStyle style, Palette p) =>
      Text.rich(TextSpan(children: _inline(text, style, p)), style: style);

  static List<InlineSpan> _inline(String text, TextStyle style, Palette p) {
    final spans = <InlineSpan>[];
    final pattern = RegExp(r'(\*\*[^*]+\*\*|__[^_]+__|`[^`]+`|\*[^*\s][^*]*\*|_[^_\s][^_]*_)');
    var last = 0;
    for (final m in pattern.allMatches(text)) {
      if (m.start > last) spans.add(TextSpan(text: text.substring(last, m.start)));
      final token = m.group(0)!;
      if (token.startsWith('**') || token.startsWith('__')) {
        spans.add(TextSpan(
          text: token.substring(2, token.length - 2),
          style: const TextStyle(fontWeight: FontWeight.w600),
        ));
      } else if (token.startsWith('`')) {
        spans.add(TextSpan(
          text: token.substring(1, token.length - 1),
          style: TextStyle(backgroundColor: p.accentWash),
        ));
      } else {
        spans.add(TextSpan(
          text: token.substring(1, token.length - 1),
          style: const TextStyle(fontStyle: FontStyle.italic),
        ));
      }
      last = m.end;
    }
    if (last < text.length) spans.add(TextSpan(text: text.substring(last)));
    return spans;
  }
}
