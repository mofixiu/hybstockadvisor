import 'package:intl/intl.dart';

/// The one place numbers, money and dates are turned into text.
///
/// Rules: money is "₦189,297.00" (₦ for NGN, never "NGN 189297.00"); large
/// values are "₦578.06B"; changes are signed ("+0.97%", "−4.25%") and zero is
/// "0.00%", never a dash. A missing value is an em dash.
class Fmt {
  Fmt._();

  /// Typographic minus, the same width as the plus sign in tabular figures.
  static const String minus = '−';
  static const String missing = '—';
  static const String up = '▲';
  static const String down = '▼';

  /// Lagos is UTC+1 all year. NGX dates and times are shown in WAT.
  static const Duration _wat = Duration(hours: 1);

  static final Map<int, NumberFormat> _fixed = {};
  static final NumberFormat _qty = NumberFormat('#,##0.####', 'en_US');

  static NumberFormat _digits(int decimals) => _fixed.putIfAbsent(
    decimals,
    () => NumberFormat.decimalPatternDigits(
      locale: 'en_US',
      decimalDigits: decimals,
    ),
  );

  /// "₦" for NGN (and when unknown); otherwise the ISO code and a space.
  static String symbol(String? currency) {
    final code = (currency ?? 'NGN').trim().toUpperCase();
    return code.isEmpty || code == 'NGN' ? '₦' : '$code ';
  }

  static String _sign(num v, {bool signed = false}) {
    if (v < 0) return minus;
    if (signed && v > 0) return '+';
    return '';
  }

  /// Rounds so that values that would print as zero count as zero.
  static num _rounded(num v, int decimals) =>
      num.parse(v.toStringAsFixed(decimals));

  /// "₦189,297.00". With [signed], positive values get a "+".
  static String money(
    num? value, {
    String? currency,
    int decimals = 2,
    bool signed = false,
  }) {
    if (value == null || value.isNaN || value.isInfinite) return missing;
    final v = _rounded(value, decimals);
    return '${_sign(v, signed: signed)}${symbol(currency)}${_digits(decimals).format(v.abs())}';
  }

  /// "₦578.06B", "₦3.82T". Below a thousand it falls back to [money].
  static String compactMoney(num? value, {String? currency, bool signed = false}) {
    if (value == null || value.isNaN || value.isInfinite) return missing;
    final abs = value.abs();
    const steps = [(1e12, 'T'), (1e9, 'B'), (1e6, 'M'), (1e3, 'K')];
    for (final (size, suffix) in steps) {
      if (abs >= size) {
        return '${_sign(value, signed: signed)}${symbol(currency)}${_digits(2).format(abs / size)}$suffix';
      }
    }
    return money(value, currency: currency, signed: signed);
  }

  /// Signed percentage: "+0.97%", "−4.25%", "0.00%".
  static String pct(num? value, {int decimals = 2, bool signed = true}) {
    if (value == null || value.isNaN || value.isInfinite) return missing;
    final v = _rounded(value, decimals);
    return '${_sign(v, signed: signed)}${_digits(decimals).format(v.abs())}%';
  }

  /// A probability (0 to 1) as a whole percentage: 0.583 -> "58%".
  static String probability(num? p, {int decimals = 0}) {
    if (p == null || p.isNaN) return missing;
    return '${_digits(decimals).format(p * 100)}%';
  }

  /// Percentage points between two probabilities: +5 pts, −2 pts.
  static String points(num? delta, {int decimals = 1}) {
    if (delta == null || delta.isNaN) return missing;
    final v = _rounded(delta * 100, decimals);
    return '${_sign(v, signed: true)}${_digits(decimals).format(v.abs())} pts';
  }

  /// Plain number with grouping, e.g. a Brier score or a count.
  static String number(num? value, {int decimals = 0}) {
    if (value == null || value.isNaN) return missing;
    final v = _rounded(value, decimals);
    return '${_sign(v)}${_digits(decimals).format(v.abs())}';
  }

  /// Share quantity: "4,200", "1.5".
  static String quantity(num? value) =>
      value == null ? missing : _qty.format(value);

  /// ▲ for up, ▼ for down, nothing for zero or unknown.
  static String arrow(num? value) {
    if (value == null || value == 0) return '';
    return value > 0 ? up : down;
  }

  // ── Dates ──────────────────────────────────────────────

  /// Parses an API timestamp or date. Returns null when absent or invalid.
  static DateTime? parse(Object? raw) {
    if (raw == null) return null;
    if (raw is DateTime) return raw;
    return DateTime.tryParse(raw.toString());
  }

  /// A timestamp moved to Lagos time (as a plain wall-clock value).
  static DateTime toWat(DateTime t) =>
      t.isUtc || t.timeZoneOffset != Duration.zero
      ? t.toUtc().add(_wat)
      : t;

  static final DateFormat _day = DateFormat('d MMM y', 'en_US');
  static final DateFormat _dayShort = DateFormat('d MMM', 'en_US');
  static final DateFormat _dayLong = DateFormat('EEEE d MMMM y', 'en_US');
  static final DateFormat _weekdayDay = DateFormat('EEE d MMM y', 'en_US');
  static final DateFormat _time = DateFormat('HH:mm', 'en_US');

  /// "11 Nov 2026". A date-only string is shown as that date.
  static String date(Object? raw) {
    final t = parse(raw);
    if (t == null) return missing;
    return _day.format(_isDateOnly(raw) ? t : toWat(t));
  }

  /// "11 Nov".
  static String dateShort(Object? raw) {
    final t = parse(raw);
    if (t == null) return missing;
    return _dayShort.format(_isDateOnly(raw) ? t : toWat(t));
  }

  /// "Wed 11 Nov 2026".
  static String dateWeekday(Object? raw) {
    final t = parse(raw);
    if (t == null) return missing;
    return _weekdayDay.format(_isDateOnly(raw) ? t : toWat(t));
  }

  /// "Wednesday 11 November 2026" for a local date (the masthead dateline).
  static String dateline(DateTime local) => _dayLong.format(local);

  /// "16:42 WAT".
  static String timeWat(Object? raw) {
    final t = parse(raw);
    if (t == null || _isDateOnly(raw)) return missing;
    return '${_time.format(toWat(t))} WAT';
  }

  static bool _isDateOnly(Object? raw) =>
      raw is String && raw.length == 10 && !raw.contains('T');

  /// Parses a market cap sent as "578060000000.0", "3.82T" or "--".
  static double? parseCompact(Object? raw) {
    if (raw == null) return null;
    if (raw is num) return raw.toDouble();
    final s = raw.toString().trim().replaceAll(',', '');
    if (s.isEmpty) return null;
    const mult = {'K': 1e3, 'M': 1e6, 'B': 1e9, 'T': 1e12};
    final last = s[s.length - 1].toUpperCase();
    final m = mult[last];
    final n = double.tryParse(m == null ? s : s.substring(0, s.length - 1));
    if (n == null) return null;
    return m == null ? n : n * m;
  }
}
