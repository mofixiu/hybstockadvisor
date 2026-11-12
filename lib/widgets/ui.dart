import 'package:flutter/material.dart';
import 'package:hybstockadvisor/theme/format.dart';
import 'package:hybstockadvisor/theme/tokens.dart';

/// Shared building blocks. Screens compose these instead of styling inline.

/// A hairline rule between rows.
class Hairline extends StatelessWidget {
  final double indent;
  final double endIndent;
  const Hairline({super.key, this.indent = 0, this.endIndent = 0});

  @override
  Widget build(BuildContext context) => Container(
    margin: EdgeInsets.only(left: indent, right: endIndent),
    height: Stroke.hairline,
    color: context.pal.rule,
  );
}

/// A heavy ink rule that opens a section, like a newspaper column head.
class HeavyRule extends StatelessWidget {
  const HeavyRule({super.key});

  @override
  Widget build(BuildContext context) =>
      Container(height: Stroke.heavy, color: context.pal.ruleStrong);
}

/// Small uppercase label above a heading or value.
class Kicker extends StatelessWidget {
  final String text;
  final Color? color;
  const Kicker(this.text, {super.key, this.color});

  @override
  Widget build(BuildContext context) => Text(
    text.toUpperCase(),
    style: context.text.labelSmall?.copyWith(color: color),
  );
}

/// Section head: heavy rule, then a serif title with optional trailing action.
class SectionHead extends StatelessWidget {
  final String title;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;
  const SectionHead(
    this.title, {
    super.key,
    this.trailing,
    this.padding = const EdgeInsets.only(top: Gap.xl, bottom: Gap.sm),
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: padding,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const HeavyRule(),
        const SizedBox(height: Gap.sm),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(child: Text(title, style: context.text.titleLarge)),
            ?trailing,
          ],
        ),
      ],
    ),
  );
}

/// Page title used at the top of each tab instead of an app bar.
class PageTitle extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget> actions;
  const PageTitle(this.title, {super.key, this.subtitle, this.actions = const []});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(Gap.page, Gap.md, Gap.page - 8, Gap.md),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: context.text.headlineMedium),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(subtitle!, style: context.text.bodySmall),
              ],
            ],
          ),
        ),
        ...actions,
      ],
    ),
  );
}

/// Label on the left, value on the right, hairline below.
class LabelValueRow extends StatelessWidget {
  final String label;
  final String? value;
  final Widget? valueWidget;
  final String? note;
  final bool showRule;
  final bool strong;
  const LabelValueRow(
    this.label, {
    super.key,
    this.value,
    this.valueWidget,
    this.note,
    this.showRule = true,
    this.strong = false,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.text;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 11),
          child: LayoutBuilder(
            builder: (context, c) => Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label, style: t.bodyMedium?.copyWith(color: context.pal.inkMuted)),
                      if (note != null) ...[
                        const SizedBox(height: 2),
                        Text(note!, style: t.bodySmall),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: Gap.md),
                // Short values take only the room they need; long ones wrap at 55%.
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: c.maxWidth * 0.55),
                  child:
                      valueWidget ??
                      Text(
                        value ?? Fmt.missing,
                        textAlign: TextAlign.right,
                        style: (strong ? t.titleMedium : t.bodyMedium)?.copyWith(
                          fontWeight: strong ? FontWeight.w600 : FontWeight.w500,
                        ),
                      ),
                ),
              ],
            ),
          ),
        ),
        if (showRule) const Hairline(),
      ],
    );
  }
}

/// A signed change with ▲/▼, sign and colour, e.g. "▲ +₦1.30 (+1.02%)".
/// Zero reads "0.00%" in plain ink; unknown reads "—".
class ChangeText extends StatelessWidget {
  final double? pct;
  final double? amount;
  final String? currency;
  final TextStyle? style;
  final bool arrow;
  final bool compactAmount;
  const ChangeText({
    super.key,
    required this.pct,
    this.amount,
    this.currency,
    this.style,
    this.arrow = true,
    this.compactAmount = false,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final base = style ?? context.text.bodyMedium!;
    final ref = pct ?? amount;
    final glyph = arrow ? Fmt.arrow(ref) : '';
    final parts = <String>[];
    if (amount != null) {
      parts.add(
        compactAmount
            ? Fmt.compactMoney(amount, currency: currency, signed: true)
            : Fmt.money(amount, currency: currency, signed: true),
      );
    }
    if (pct != null || amount == null) {
      final pctText = Fmt.pct(pct);
      parts.add(amount != null ? '($pctText)' : pctText);
    }
    return Text(
      [if (glyph.isNotEmpty) glyph, ...parts].join(' '),
      maxLines: 1,
      softWrap: false,
      overflow: TextOverflow.fade,
      style: base.copyWith(
        color: p.signed(ref),
        fontWeight: base.fontWeight ?? FontWeight.w500,
      ),
    );
  }
}

/// "Stale" in the caution colour, for data older than the backend allows.
class StaleTag extends StatelessWidget {
  final String label;
  const StaleTag({super.key, this.label = 'Stale'});

  @override
  Widget build(BuildContext context) => Text(
    label,
    style: context.text.labelMedium?.copyWith(color: context.pal.warn),
  );
}

/// How fresh a price is: "Close of Wed 11 Nov 2026 · Investo · 16:42 WAT",
/// with a stale warning when the backend flags it.
class FreshnessLine extends StatelessWidget {
  /// Trading date of the close, if known (date-only string or DateTime).
  final Object? tradeDate;

  /// Source timestamp (`as_of`).
  final Object? asOf;
  final String? source;
  final bool stale;
  final TextAlign align;
  const FreshnessLine({
    super.key,
    this.tradeDate,
    this.asOf,
    this.source,
    this.stale = false,
    this.align = TextAlign.left,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.text;
    final p = context.pal;
    final dateText = tradeDate != null
        ? 'Close of ${Fmt.dateWeekday(tradeDate)}'
        : asOf != null
        ? 'Data as of ${Fmt.date(asOf)}'
        : 'Date not reported';
    final bits = <String>[
      dateText,
      if (source != null && source!.isNotEmpty) source!,
      if (asOf != null && Fmt.timeWat(asOf) != Fmt.missing) 'updated ${Fmt.timeWat(asOf)}',
    ];
    return Text.rich(
      TextSpan(
        children: [
          if (stale)
            TextSpan(
              text: 'Stale · ',
              style: TextStyle(color: p.warn, fontWeight: FontWeight.w600),
            ),
          TextSpan(text: bits.join(' · ')),
        ],
      ),
      textAlign: align,
      style: t.bodySmall,
    );
  }
}

/// Primary action: navy fill, square-ish corners.
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final bool expand;
  const PrimaryButton(
    this.label, {
    super.key,
    this.onPressed,
    this.loading = false,
    this.expand = true,
  });

  @override
  Widget build(BuildContext context) {
    final button = ElevatedButton(
      onPressed: loading ? null : onPressed,
      child: loading
          ? SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: context.pal.inkFaint,
              ),
            )
          : Text(label),
    );
    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}

/// Secondary action: ink outline.
class QuietButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool expand;
  const QuietButton(
    this.label, {
    super.key,
    this.onPressed,
    this.icon,
    this.expand = true,
  });

  @override
  Widget build(BuildContext context) {
    final button = icon == null
        ? OutlinedButton(onPressed: onPressed, child: Text(label))
        : OutlinedButton.icon(
            onPressed: onPressed,
            icon: Icon(icon, size: 18),
            label: Text(label),
          );
    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}

/// Inline navy link with a trailing arrow, e.g. "Read the note →".
class LinkText extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool arrow;
  final TextStyle? style;
  const LinkText(this.label, {super.key, this.onTap, this.arrow = true, this.style});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Radii.xs),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          arrow ? '$label  →' : label,
          style: (style ?? context.text.labelLarge)?.copyWith(color: p.accent),
        ),
      ),
    );
  }
}

/// Bottom sheet frame: drag handle, optional title row with close, content.
class SheetFrame extends StatelessWidget {
  final String? title;
  final Widget? subtitle;
  final Widget child;
  final List<Widget> actions;
  final double? heightFactor;
  final EdgeInsetsGeometry padding;
  const SheetFrame({
    super.key,
    this.title,
    this.subtitle,
    required this.child,
    this.actions = const [],
    this.heightFactor,
    this.padding = const EdgeInsets.fromLTRB(Gap.page, 0, Gap.page, Gap.lg),
  });

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final media = MediaQuery.of(context);
    final content = Column(
      mainAxisSize: heightFactor == null ? MainAxisSize.min : MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            margin: const EdgeInsets.only(top: 10, bottom: 6),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: p.rule,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        if (title != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(Gap.page, Gap.sm, 8, Gap.sm),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title!, style: context.text.headlineSmall),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        subtitle!,
                      ],
                    ],
                  ),
                ),
                ...actions,
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  tooltip: 'Close',
                  icon: Icon(Icons.close, color: p.inkMuted),
                ),
              ],
            ),
          ),
        if (title != null) const Hairline(),
        if (heightFactor == null)
          Flexible(child: Padding(padding: padding, child: child))
        else
          Expanded(child: Padding(padding: padding, child: child)),
      ],
    );
    return Container(
      height: heightFactor == null ? null : media.size.height * heightFactor!,
      constraints: BoxConstraints(maxHeight: media.size.height * 0.92),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(Radii.sheet)),
        border: Border(top: BorderSide(color: p.rule)),
      ),
      child: SafeArea(top: false, child: content),
    );
  }
}

/// Opens a [SheetFrame]-style modal sheet with the app's surface colours.
Future<T?> showAppSheet<T>(
  BuildContext context,
  WidgetBuilder builder, {
  bool scrollControlled = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: scrollControlled,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.35),
    builder: builder,
  );
}

/// Plain message for empty, error and unavailable states.
class MessageBlock extends StatelessWidget {
  final String title;
  final String? body;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool center;
  const MessageBlock({
    super.key,
    required this.title,
    this.body,
    this.actionLabel,
    this.onAction,
    this.center = false,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.text;
    final align = center ? CrossAxisAlignment.center : CrossAxisAlignment.start;
    final textAlign = center ? TextAlign.center : TextAlign.left;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Gap.xl),
      child: Column(
        crossAxisAlignment: align,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title, style: t.titleLarge, textAlign: textAlign),
          if (body != null) ...[
            const SizedBox(height: Gap.sm),
            Text(
              body!,
              style: t.bodyMedium?.copyWith(color: context.pal.inkMuted),
              textAlign: textAlign,
            ),
          ],
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: Gap.lg),
            QuietButton(actionLabel!, onPressed: onAction, expand: false),
          ],
        ],
      ),
    );
  }
}

/// Snack bar with the app's styling. Errors get a "Couldn't …" tone from the caller.
void showNotice(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

/// Confirmation dialog with a cancel and a destructive or plain action.
Future<bool> confirmAction(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  bool destructive = false,
}) async {
  final p = context.pal;
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text('Cancel', style: TextStyle(color: p.inkMuted)),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(
            confirmLabel,
            style: TextStyle(color: destructive ? p.down : p.accent),
          ),
        ),
      ],
    ),
  );
  return result ?? false;
}

// ── Skeleton loaders ─────────────────────────────────────

/// Drives a slow sweep for every [SkeletonBox] below it.
class Skeleton extends StatefulWidget {
  final Widget child;
  const Skeleton({super.key, required this.child});

  @override
  State<Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<Skeleton> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      _SkeletonScope(animation: _c, child: widget.child);
}

class _SkeletonScope extends InheritedWidget {
  final Animation<double> animation;
  const _SkeletonScope({required this.animation, required super.child});

  @override
  bool updateShouldNotify(_SkeletonScope old) => old.animation != animation;
}

/// A flat placeholder block. Sweeps when inside a [Skeleton].
class SkeletonBox extends StatelessWidget {
  final double? width;
  final double height;
  final double radius;
  const SkeletonBox({super.key, this.width, required this.height, this.radius = Radii.xs});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final anim = context.dependOnInheritedWidgetOfExactType<_SkeletonScope>()?.animation;
    Widget box(double v) => Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: LinearGradient(
          colors: [p.skeleton, p.skeletonHighlight, p.skeleton],
          stops: [
            (v - 0.3).clamp(0.0, 1.0),
            v.clamp(0.0, 1.0),
            (v + 0.3).clamp(0.0, 1.0),
          ],
        ),
      ),
    );
    if (anim == null) return box(0);
    return AnimatedBuilder(animation: anim, builder: (_, _) => box(anim.value * 1.6 - 0.3));
  }
}
